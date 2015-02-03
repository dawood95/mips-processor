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
    *
    * Local signals
    * 
    ***********************************/

   // Instruction
   word_t                    instr;
   j_t                      jinstr;
   i_t                      iinstr;
   r_t                      rinstr;
   
   // PC Signals
   logic 		     pc_en;
   word_t                    pc;
   word_t                    pc_offset;

   always_comb
     begin
	pc_offset = 32'd4;
	jinstr = instr;
	iinstr = instr;
	rinstr = instr;
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
	alif.porta = rfif.rdat1;
	rfif.wdat = alif.out;
	if(op == RTYPE)
	  begin
	     alif.portb = rfif.rdat2; // Modify later
	     casez(rinstr.funct)
	       SLL:
		 begin
		    alif.op = ALU_SLL;
		    alif.portb = rinstr.shamt; // Modify later
		 end
	       SRL:
		 begin
		    alif.op = ALU_SRL;
		    alif.portb = rinstr.shamt; // Modify later
		 end
	       ADD:
		 alif.op = ALU_ADD;
	       ADDU:
		 alif.op = ALU_ADD;
	       SUB:
		 alif.op = ALU_SUB;
	       SUBU:
		 alif.op = ALU_SUB;
	       AND:
		 alif.op = ALU_AND;
	       OR:
		 alif.op = ALU_OR;
	       XOR:
		 alif.op = ALU_XOR;
	       NOR:
		 alif.op = ALU_NOR;
	       SLT:
		 alif.op = ALU_SLT;
	       SLTU:
		 alif.op = ALU_SLTU;
	       default:
		 alif.op = ALU_SLL;
	     endcase // case (instr[5:0])
	  end // if (op == RTYPE)
	else
	  begin
	     alif.portb = rfif.data1;
	     alif.op = ALU_AND;
	  end // else: !if(op == RTYPE)
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


