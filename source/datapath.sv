/*
 Sheik Dawood 
 dawood0@purdue.edu
 

 datapath contains register file, control, hazard,
 muxes, and glue logic for processor
 */

`include "datapath_cache_if.vh"
`include "register_file_if.vh"
`include "alu_if.vh"
`include "cpu_types_pkg.vh"
`include "pipeline_if.vh"

module datapath (
		 input logic CLK, nRST,
		 datapath_cache_if.dp dpif
		 );
   // import types\
   import cpu_types_pkg::*;
   import pipeline_if::*;

   // pc init
   parameter PC_INIT = 0;

   //Interfaces 
   alu_if alif();
   register_file_if rfif();
   ifetch_t ifetch;
   decode_t decode;
   exec_t exec;
   mem_t mem;
   regw_t regw;

   //Local signals
   
   word_t npc, npc_ff, immExt;
   logic 		     pcEn_ifde, pcEn_deex, pcEn_exmem, pcEn_memregw, ifde_en, deex_en, exmem_en, immExt_sel, halt, btb_correct, btb_wrongtype;
   logic [1:0] 		     regW_sel;
   
   i_t iinstr;
   j_t jinstr;
   r_t rinstr;
   
   /***********************************************************************
    *                       Instruction and Fetch                         *
    ***********************************************************************/
   always_comb
     begin
	case(decode.pc_sel)
	  3'b000: ifetch.imemAddr = npc_ff; 
	  3'b001: ifetch.imemAddr = exec.jraddr;//decode.regData1;
	  3'b010: ifetch.imemAddr = decode.jAddr;
	  3'b011: ifetch.imemAddr = decode.btb_target;
	  3'b100: ifetch.imemAddr = mem.brTarget;
	  3'b101: ifetch.imemAddr = mem.pc;
	  default: ifetch.imemAddr = npc_ff;
	endcase // case (decode.pc_sel)
	ifetch.instr = dpif.imemload;
	dpif.imemaddr = ifetch.imemAddr;
	npc = ifetch.imemAddr + 4;
	ifetch.pc = npc;
     end // always_comb
   
   always_ff @(posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  npc_ff <= PC_INIT;
	else if(pcEn_ifde & ifde_en)
	  npc_ff <= npc;
     end

   br_predict BTB(
		  .CLK(CLK),
		  .nRST(nRST),
		  .instr(ifetch.imemAddr),
		  .pr_correct(btb_correct),
		  .update_br_target(mem.brTarget),
		  .w_index(mem.btb_index),
		  .r_index(ifetch.imemAddr[3:2]),
		  .br_target(ifetch.btb_target),
		  .take_br(ifetch.btb_taken),
		  .out_index(ifetch.btb_index)
		  );
     
   /***********************************************************************
    ***********************************************************************/
     
   always_ff @(posedge CLK, negedge nRST)
     begin : RequestDecodeFF
	if(!nRST)
	  begin
	     decode.instr <= 0;
	     decode.pc <= PC_INIT;
	     decode.btb_taken <= 0;
	  end
	else if(pcEn_ifde)
	  begin
	     if(ifde_en) //Inst Decode ff en
	       begin
		  decode.instr <= ifetch.instr;
		  decode.btb_taken <= ifetch.btb_taken;
	       end
	     else
	       begin
		  decode.instr <= 0;
		  decode.btb_taken <= 0;
	       end
	     decode.pc <= ifetch.pc;
	     decode.btb_target <= ifetch.btb_target;
	     decode.btb_index <= ifetch.btb_index;
	  end // if (pcEn_ifde)
     end // block: RequestDecodeFF
   
   /***********************************************************************
    *                               Decode                                *
    ***********************************************************************/

   control_unit control_unit(.instr(decode.instr),
	       		     .aluOp(decode.aluOp), 
			     .porta_sel(decode.porta_sel),  
			     .portb_sel(decode.portb_sel),
       			     .immExt_sel(immExt_sel), 
       			     .pc_sel(decode.pc_sel), 
       			     .regW_sel(regW_sel),
       			     .wMemReg_sel(decode.regDataSel), 
       			     .memREN(decode.memRen), 
       			     .memWEN(decode.memWen), 
       			     .regWEN(decode.regWen),
       			     .beq(decode.beq),
			     .bne(decode.bne),
			     .jal(decode.jal),
			     .jr(decode.jr),
			     .jrTake(exec.jr),
			     .brTake(decode.btb_taken),
			     .btb_correct(btb_correct),
			     .btb_wrongtype(btb_wrongtype),
			     .halt(decode.halt)
			     );

   register_file reg_file( CLK, nRST, rfif);

   always_comb
     begin
	// Instruction type cast
	iinstr = i_t'(decode.instr);
	jinstr = j_t'(decode.instr);
	rinstr = r_t'(decode.instr);
     end
   
   always_comb
     begin
	immExt = (immExt_sel) ? {{16{iinstr.imm[15]}},iinstr.imm} : {16'b0,iinstr.imm} ;
	//ALU
	decode.porta = (decode.porta_sel) ? immExt : rfif.rdat1;
	case(decode.portb_sel)
	  2'b00: decode.portb = rfif.rdat2;
	  2'b01: decode.portb = rinstr.shamt;
	  2'b10: decode.portb = immExt;
	  2'b11: decode.portb = 32'd16;
	endcase // case (decode.portb_sel)
	//Register File
	rfif.rsel1 = rinstr.rs;
	rfif.rsel2 = rinstr.rt;
	rfif.wsel = regw.regDest;
	rfif.wdat = regw.regData;
	rfif.WEN = regw.regWen;
	case(regW_sel)
	  2'b00, 2'b11: decode.regDest = rinstr.rd;
	  2'b01: decode.regDest = rinstr.rt;
	  2'b10: decode.regDest = 5'd31;
	endcase // case (regW_sel)
	decode.jAddr = {decode.pc[31:28],jinstr.addr,2'b00};
	decode.regData1 = rfif.rdat1;
	decode.regData2 = rfif.rdat2;
     end // always_comb

   /***********************************************************************
    ***********************************************************************/

   always_ff @(posedge CLK, negedge nRST)
     begin : DecodeExecuteFF
	if(!nRST)
	  begin
	     exec.memRen <= 0;
	     exec.memWen <= 0;
	     exec.regWen <= 0;
	     exec.beq <= 0;
	     exec.bne <= 0;
	     exec.jr <= 0;
	     exec.jal <= 0;
	     exec.pc <= 0;
	     exec.dHalt <= 0;
	     exec.btb_taken <= 0;
	  end // if (!nRST)
	else if(pcEn_deex)
	  begin
	     if(deex_en)
	       begin
		  exec.memRen <= decode.memRen;
		  exec.memWen <= decode.memWen;
		  exec.regWen <= decode.regWen;
		  exec.jr <= decode.jr;
		  exec.jal <= decode.jal;
		  exec.dHalt <= decode.halt;
		  exec.rs <= rinstr.rs;
		  exec.rt <= rinstr.rt;
		  exec.beq <= decode.beq;
		  exec.bne <= decode.bne;
		  exec.btb_taken <= decode.btb_taken;
	       end // if (deex_en)
	     else
	       begin
		  exec.memRen <= 0;
		  exec.memWen <= 0;
		  exec.regWen <= 0;
		  exec.jr <= 0;
		  exec.jal <= 0;
		  exec.dHalt <= 0;
		  exec.rs <= 0;
		  exec.rt <= 0;
		  exec.beq <= 0;
		  exec.bne <= 0;
		  exec.btb_taken <= 0;
	       end // else: !if(deex_en)
	     exec.immExt <= immExt << 2;
	     exec.porta_sel <= decode.porta_sel;
	     exec.portb_sel <= decode.portb_sel;
	     exec.pc <= decode.pc;
	     exec.porta <= decode.porta;
	     exec.portb <= decode.portb;
	     exec.aluOp <= decode.aluOp;
	     exec.regDataSel <= decode.regDataSel;
	     exec.regDest <= decode.regDest;
	     exec.regData1 <= decode.regData1;
	     exec.regData2 <= decode.regData2;	
	     exec.btb_index <= decode.btb_index;
	     exec.btb_target <= decode.btb_target;
	  end // if (pcEn_deex)
     end // block: DecodeExecuteFF

   /***********************************************************************
    *                               Execute                               *
    ***********************************************************************/

   alu alu(alif);

   always_comb
     begin
	exec.aluOut = alif.out;
	exec.eHalt = exec.dHalt || ((exec.aluOp == ALU_ADD || exec.aluOp == ALU_SUB) && alif.of);
	alif.op = exec.aluOp;
	exec.brAddr = exec.pc + exec.immExt;
	//brTake = (exec.beq & alif.zf) | (exec.bne & !alif.zf) ;
     end
   
   //Forwarding Unit

   always_comb
     begin
	if((exec.rs == mem.regDest) & !exec.porta_sel & mem.regWen & !mem.memRen)
	  alif.porta = (mem.jal) ? mem.pc : mem.aluOut;
	else if((exec.rs == regw.regDest) & !exec.porta_sel & regw.regWen)
	  alif.porta = regw.regData;
	else
	  alif.porta = exec.porta;

	if((exec.rt == mem.regDest) & !exec.portb_sel & mem.regWen & !mem.memRen)
	  alif.portb = (mem.jal) ? mem.pc : mem.aluOut;
	else if((exec.rt == regw.regDest) & !exec.portb_sel & regw.regWen)
	  alif.portb = regw.regData;
	else
	  alif.portb = exec.portb;

	if((exec.rt == mem.regDest) & mem.regWen & !mem.memRen)
	  exec.storeData = (mem.jal) ? mem.pc : mem.aluOut;
	else if((exec.rt == regw.regDest) & mem.regWen)
	  exec.storeData = regw.regData;
	else
	  exec.storeData = exec.regData2;

	if((exec.rs == mem.regDest) & mem.regWen & !mem.memRen)
	  exec.jraddr = (mem.jal) ? mem.pc : mem.aluOut;
	else if((exec.rs == regw.regDest) & mem.regWen)
	  exec.jraddr = regw.regData;
	else
	  exec.jraddr = exec.regData1;
	
     end // always_comb
   
   /***********************************************************************
    ***********************************************************************/
   
   always_ff @(posedge CLK, negedge nRST)
     begin : ExecuteMemoryFF
	if(!nRST)
	  begin
	     mem.memRen <= 0;
	     mem.memWen <= 0;
	     mem.regWen <= 0;
	     mem.aluOut <= 0;
	     mem.regData2 <= 0;
	     mem.halt <= 0;
	     mem.pc <= PC_INIT;
	     mem.regDataSel <= 0;
	     mem.regDest <= 0;
	     mem.jal <= 0;
	     mem.zf <= 0;
	     mem.beq <= 0;
	     mem.bne <= 0;
	     mem.btb_taken <= 0;
	  end // if (!nRST)
	else if(pcEn_exmem)
	  begin
	     if(exmem_en)
	       begin
		  mem.memRen <= exec.memRen;
		  mem.memWen <= exec.memWen;
		  mem.regWen <= exec.regWen;
		  mem.halt <= exec.eHalt;
		  mem.jal <= exec.jal;
		  mem.zf <= alif.zf;
		  mem.beq <= exec.beq;
		  mem.bne <= exec.bne;
		  mem.btb_taken <= exec.btb_taken;
	       end
	     else
	       begin
		  mem.memRen <= 0;
		  mem.memWen <= 0;
		  mem.regWen <= 0;
		  mem.halt <= 0;
		  mem.jal <= 0;
		  mem.zf <= 0;
		  mem.beq <= 0;
		  mem.bne <= 0;
		  mem.btb_taken <= 0;
	       end // else: !if(exmem_en)
	     mem.aluOut <= exec.aluOut;
	     mem.pc <= exec.pc;
	     mem.regDataSel <= exec.regDataSel;
	     mem.regDest <= exec.regDest;
	     mem.regData2 <= exec.storeData;
	     mem.brAddr = exec.brAddr;
	     mem.btb_target <= exec.btb_target;
	     mem.btb_index <= exec.btb_index;
	  end // if (pcEn_exmem)

     end // block: ExecuteMemoryFF

   
   /***********************************************************************
    *                                Memory                               *
    ***********************************************************************/

   always_comb
     begin
	mem.memData = dpif.dmemload;
      	dpif.dmemaddr = mem.aluOut;
	dpif.dmemstore = mem.regData2;
	mem.brTake = (mem.beq & mem.zf) | (mem.bne & !mem.zf) ;
	mem.brTarget = mem.brAddr;
	if(mem.brTake & !mem.btb_taken)
	  begin
	     //Not correct
	     btb_correct = 0;
	     btb_wrongtype = 1'b0;
	  end
	else if(!mem.brTake & mem.btb_taken & (mem.bne | mem.beq))
	  begin
	     //Not correct
	     btb_correct = 0;
	     btb_wrongtype = 1'b1;
	  end
	else if((mem.brAddr != mem.btb_target) & mem.brTake)
	  begin
	     //Not correct
	     btb_correct = 0;
	     btb_wrongtype = 1'b0; 
	  end
	else
	  begin
	     //Correct
	     btb_correct = 1'b1;
	     btb_wrongtype = 1'b0; 
	  end
     end

   /***********************************************************************
    ***********************************************************************/

   always_ff @(posedge CLK, negedge nRST)
     begin : MemoryRegisterwFF
	if(!nRST)
	  begin
	     regw.regWen <= 0;
	     regw.memData <= 0;
	     regw.aluData <= 0;
	     regw.regDataSel <= 0;
	     regw.regDest <= 0;
	     regw.pc <= PC_INIT; //Check this
	  end
	else if(pcEn_memregw)
	  begin
	     regw.regWen <= mem.regWen;
	     regw.regDataSel <= mem.regDataSel;
	     regw.aluData <= mem.aluOut;
	     regw.regDest <= mem.regDest;
	     regw.pc <= mem.pc; //Check this
	     regw.memData <= mem.memData;
	  end
     end // block: MemoryRegisterwFF
   
   /***********************************************************************
    *                            Register Write                           *
    ***********************************************************************/
   //RegisterW

   always_comb
     begin
	case(regw.regDataSel)
	  2'b00,2'b11 : regw.regData = regw.aluData;
	  2'b01: regw.regData = regw.memData;
	  2'b10: regw.regData = regw.pc;
	endcase // case (regw.regDataSel)
     end
   /***********************************************************************
    ***********************************************************************/

   always_ff @(posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  dpif.halt <= 1'b0;
	else if(mem.halt)
	  dpif.halt <= 1'b1;
     end

   always_comb
     begin
	dpif.imemREN = ~mem.halt;
	dpif.dmemWEN = mem.memWen;
	dpif.dmemREN = mem.memRen;

	pcEn_ifde = (dpif.ihit | dpif.dhit) & !dpif.halt & !mem.memRen & !mem.memWen;
	pcEn_deex = (dpif.ihit | dpif.dhit) & !dpif.halt &
		    !(((exec.rs == mem.regDest) | (exec.rt == mem.regDest)) & mem.memRen);
	//!((mem.memRen | mem.memWen) & brTake);
	
	pcEn_exmem = (dpif.ihit | dpif.dhit) & !dpif.halt;
	pcEn_memregw = (dpif.ihit | dpif.dhit) & !dpif.halt;

	ifde_en = 1'b1;//btb_correct;
	deex_en = !mem.memRen & !mem.memWen & btb_correct & !exec.jr;
	exmem_en = !(((exec.rs == mem.regDest) | (exec.rt == mem.regDest)) & mem.memRen) & btb_correct;
	//memwb
	  
	//pcEn = (dpif.ihit | dpif.dhit) & !dpif.halt & 
	//       !(((exec.rs == mem.regDest) | (exec.rt == mem.regDest)) & mem.memRen);
	//pcEn_exMemRegw = (dpif.ihit | dpif.dhit) & !dpif.halt;
	//exmem_en = !(((exec.rs == mem.regDest) | (exec.rt == mem.regDest)) & mem.memRen);
	//ifde_en = !mem.memRen & !mem.memWen; // <-
	//deex_en = !brTake; // For branch
     end // always_comb
endmodule // datapath
