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
   // import types
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
   logic 		     pcEn, pcEn_memRegw, ifde_en, deex_en, immExt_sel, halt, brTake;
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
	  2'b00: ifetch.imemAddr = npc_ff;
	  2'b01: ifetch.imemAddr = decode.regData1;
	  2'b10: ifetch.imemAddr = decode.jAddr;
	  2'b11: ifetch.imemAddr = exec.brAddr;
	endcase // case (pc_sel)
	ifetch.instr = dpif.imemload;
	dpif.imemaddr = ifetch.imemAddr;
	npc = ifetch.imemAddr + 4;
	ifetch.pc = npc;
     end
   
   always_ff @(posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  npc_ff <= PC_INIT;
	else if(pcEn & ifde_en)
	  npc_ff <= npc;
     end
   
   /***********************************************************************
    ***********************************************************************/
   
   always_ff @(posedge CLK, negedge nRST)
     begin : RequestDecodeFF
       if(!nRST)
	 begin
	    decode.instr <= 0;
	    decode.pc <= PC_INIT;
	 end
       else if(pcEn)
	 begin
	    if(ifde_en) //Inst Decode ff en
	      decode.instr <= ifetch.instr;
	    else
	      decode.instr <= 0;
	    decode.pc <= ifetch.pc;	
	 end
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
			     .brTake(brTake),
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
	endcase // case (portb_sel)
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
     end

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
	     exec.jal <= 0;
	     exec.pc <= 0;
	     exec.dHalt <= 0;
	  end
	else if(pcEn)
	  begin
	     if(deex_en)
	       begin
		  exec.memRen <= decode.memRen;
		  exec.memWen <= decode.memWen;
		  exec.regWen <= decode.regWen;
		  exec.beq <= decode.beq;
		  exec.bne <= decode.bne;
		  exec.jal <= decode.jal;
		  exec.dHalt <= decode.halt;
	       end
	     else
	       begin
		  exec.memRen <= 0;
		  exec.memWen <= 0;
		  exec.regWen <= 0;
		  exec.beq <= 0;
		  exec.bne <= 0;
		  exec.jal <= 0;
		  exec.dHalt <= 0;
	       end // else: !if(deex_en)
	     exec.immExt <= immExt << 2;
	     exec.porta_sel <= decode.porta_sel;
	     exec.portb_sel <= decode.portb_sel;
	     exec.rs <= rinstr.rs;
	     exec.rt <= rinstr.rt;
	     exec.pc <= decode.pc;
	     exec.porta <= decode.porta;
	     exec.portb <= decode.portb;
	     exec.aluOp <= decode.aluOp;
	     exec.regDataSel <= decode.regDataSel;
	     exec.regDest <= decode.regDest;
	     exec.regData2 <= decode.regData2;

	  end // else: !if(!nRST)
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
	brTake = (exec.beq & alif.zf) | (exec.bne & !alif.zf) ;
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
     end
   
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
	  end
	else if(pcEn)
	  begin
	     mem.memRen <= exec.memRen;
	     mem.memWen <= exec.memWen;
	     mem.regWen <= exec.regWen;
	     mem.aluOut <= exec.aluOut;
	     mem.regData2 <= exec.storeData;
	     mem.halt <= exec.eHalt;
	     mem.pc <= exec.pc;
	     mem.regDataSel <= exec.regDataSel;
	     mem.regDest <= exec.regDest;
	     mem.jal <= exec.jal;
	  end // else: !if(!nRST)

     end // block: ExecuteMemoryFF

   
   /***********************************************************************
    *                                Memory                               *
    ***********************************************************************/

   always_comb
     begin
	mem.memData = dpif.dmemload;
      	dpif.dmemaddr = mem.aluOut;
	dpif.dmemstore = mem.regData2;
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
	else if(pcEn_memRegw)
	  begin
	     regw.regWen <= mem.regWen;
	     regw.regDataSel <= mem.regDataSel;
	     regw.aluData <= mem.aluOut;
	     regw.regDest <= mem.regDest;
	     regw.pc <= mem.pc; //Check this
	     regw.memData <= mem.memData;
	  end // else: !if(!nRST)
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
	endcase // case (regw.regDataSel_in)
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
	pcEn = (dpif.ihit | dpif.dhit) & !dpif.halt & 
	       !(((exec.rs == mem.regDest) | (exec.rt == mem.regDest)) & mem.memRen);
	pcEn_memRegw = (dpif.ihit | dpif.dhit) & !dpif.halt;
	ifde_en = !mem.memRen & !mem.memWen; // <-
	deex_en = !brTake; // For branch
     end
endmodule // datapath
