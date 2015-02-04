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

module datapath (
		 input logic CLK, nRST,
		 datapath_cache_if.dp dpif
		 );
   // import types
   import cpu_types_pkg::*;

   // pc init
   parameter PC_INIT = 0;

   register_file_if rfif();
   alu_if alif();
   
   /***********************************
    * Local signals
    ***********************************/

   // Instruction
   j_t                      jinstr;
   i_t                      iinstr;
   r_t                      rinstr;
   
   always_comb
     begin
	jinstr = dpif.imemload;
	iinstr = dpif.imemload;
	rinstr = dpif.imemload;
     end

   
   /*****************************************
    * REGISTER FILE
    *****************************************/
   
`ifndef MAPPED
   register_file rf(CLK,nRST,rfif);
`else
   register_file DUT(
		     .\rf.rdat2 (rfif.rdat2),
		     .\rf.rdat1 (rfif.rdat1),
		     .\rf.wdat (rfif.wdat),
		     .\rf.rsel2 (rfif.rsel2),
		     .\rf.rsel1 (rfif.rsel1),
		     .\rf.wsel (rfif.wsel),
		     .\rf.WEN (rfif.WEN),
		     .\nRST (nRST),
		     .\CLK (CLK)
		     );
`endif // !`ifndef MAPPED

   //RS = r1; RT = r2;
   always_comb
     begin
	rfif.rsel1 = rinstr.rs;
	rfif.rsel2 = rinstr.rt;
	if(rinstr.opcode == RTYPE)
	  rfif.wsel = rinstr.rd;
	else if(jinstr.opcode == JAL)
	  rfif.wsel = 5'd31;
	else
	  rfif.wsel = rinstr.rt;
     end


   /*****************************************
    * ALU
    *****************************************/

`ifndef MAPPED
   alu DUT(alif);
`else
   alu DUT(
	   .\sv.porta (alif.porta),
	   .\sv.portb (alif.portb),
	   .\sv.op (alif.op),
	   .\sv.out (alif.out),
	   .\sv.nf (alif.nf),
	   .\sv.zf (alif.zf),
	   .\sv.of (alif.of)
	   );
`endif // !`ifndef MAPPED


   always_comb
     begin
	if (iinstr.opcode == ADDIU || 
	    iinstr.opcode == ADDI ||
	    iinstr.opcode == LW ||
	    iinstr.opcode == SLTI || 
	    iinstr.opcode == SLTIU || 
	    iinstr.opcode == SW)
	  imm_ext = {{16{iinstr.imm[15]}},iinstr.imm};
	else if(iinstr.opcode == LUI)
	  imm_ext = {iinstr.imm,16'b0};
	else
	  imm_ext = {16'b0,iinstr.imm};

	alif.porta = rfif.rdat1;

	if (rinstr.opcode == RTYPE && ( rinstr.funct == ALU_SLL || rinstr.funct == ALU_SRL ))
	  alif.portb = rinstr.shamt;
	else if(rinstr.opcode == RTYPE)
	  alif.portb = rfif.rdat2;
	else if(iinstr.opcode == BEQ && iinstr.opcdoe == BNE)
	  alif.portb = rfif.rdat2;
	else
	  alif.portb = imm_ext;
	
     end

   
   
   
   /*****************************************
    * EXTERNAL WIRES
    *****************************************/
   always_comb
     begin
	imemaddr = pc;
	dmemaddr = pc;
     end
   
   
   /*****************************************
    * PROGRAM COUNTER
    *****************************************/
   always_ff @(posedge CLK or negedge nRST)
     begin
	if(!nRST)
	  begin
	     pc <= PC_INIT;
	  end
	else if(pc_en == 1'b1)
	  begin
	     pc <= pc + pc_offset;
	  end
     end // always_ff @
   
   
endmodule


