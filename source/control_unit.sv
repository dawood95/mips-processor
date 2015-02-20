/*
 Sheik Dawood
 dawood0@purdue.edu
 
 Control unit for single Cycle Processor
 */

`include "cpu_types_pkg.vh"

module control_unit
  import cpu_types_pkg::*;
   (
    input 	       word_t instr,
    input logic        brTake, 
    output 	       aluop_t aluOp,
    output logic [1:0] portb_sel, pc_sel, regW_sel, wMemReg_sel,
    output logic       porta_sel, immExt_sel, memREN, memWEN, regWEN, beq, bne, jal, halt
    );

   i_t iinstr;
   j_t jinstr;
   r_t rinstr;

   always_comb
     begin
	// Instruction type cast
	iinstr = i_t'(instr);
	jinstr = j_t'(instr);
	rinstr = r_t'(instr);
     end

   always_comb
     begin
	//JAL
	if(jinstr.opcode == JAL)
	  jal = 1'b1;
	else
	  jal = 1'b0;
	//Halt
	if(iinstr.opcode == HALT)
	  halt = 1'b1;
	else
	  halt = 1'b0;
	
	//Immediate Extension Select
	// 0 -> zero
	// 1 -> sign
	case(iinstr.opcode)
	  ADDIU, ADDI, LW, SLTI, SLTIU, SW, BNE, BEQ: immExt_sel = 1'b1;
	  default: immExt_sel = 1'b0;
	endcase // case (iinstr.opcode)
	//PortB Select
	// 00 -> Rt
	// 01 -> shamt
	// 10 -> immExt
	// 11 -> 32'd16
	if (iinstr.opcode == RTYPE)
	  begin
	     case(rinstr.funct)
	       SLL, SRL: portb_sel = 2'b01;
	       default: portb_sel = 2'b00;
	     endcase // case (rinstr.funct)
	  end
	else
	  begin
	     case(iinstr.opcode)
	       BNE, BEQ: portb_sel = 2'b00;
	       LUI: portb_sel = 2'b11;
	       default: portb_sel = 2'b10;
	     endcase // case (iinstr.opcode)
	  end // else: !if(iinstr.opcode == RTYPE)
	//PortA Select
	// 0 -> rs
	// 1 -> imm
	porta_sel = (iinstr.opcode == LUI) ? 1 : 0;
	//select for reg write
	// 00 -> alu
	// 01 -> Memory
	// 10 -> Pc
	if(iinstr.opcode == LW)
	  wMemReg_sel = 2'b01;
	else if(iinstr.opcode == JAL)
	  wMemReg_sel = 2'b10;
	else
	  wMemReg_sel = 2'b00;
	//Reg wsel Select
	//00 -> rd
	//01 -> rt
	//10 -> r[31]
	if(iinstr.opcode == JAL)
	  regW_sel = 2'b10;
	else if(iinstr.opcode == RTYPE)
	  regW_sel = 2'b00;
	else
	  regW_sel = 2'b01;
	//PC Select
	// 00 -> PC+4 
	// 01 -> Register
	// 10 -> Jump
	// 11 -> branch
	if(iinstr.opcode == JAL || iinstr.opcode == J)
	  pc_sel = 2'b10;
	else if(rinstr.opcode == RTYPE && rinstr.funct == JR)
	  pc_sel = 2'b01;
	else if(brTake)
	  pc_sel = 2'b11;
	else
	  pc_sel = 2'b00;
	//Memory Read Enable
	memREN = (iinstr.opcode == LW) ? 1 : 0;
	//Memory Write Enable
	memWEN = (iinstr.opcode == SW) ? 1 : 0;
	//Register Write Enable
	regWEN = ((rinstr.opcode == RTYPE && rinstr.funct == JR) || 
		  (iinstr.opcode == BEQ) ||
		  (iinstr.opcode == BNE) || 
		  (iinstr.opcode == SW)  ||
		  (iinstr.opcode == J)) ? 0 : 1;
	//Branch Enable
	if(iinstr.opcode == BEQ)
	  beq = 1'b1;
	else
	  beq = 1'b0;
	if(iinstr.opcode == BNE)
	  bne = 1'b1;
	else
	  bne = 1'b0;
	
     end
   
   always_comb
     begin
	// ALUOP
	if(rinstr.opcode == RTYPE)
	  begin
	     case(rinstr.funct)
	       SLL: aluOp = ALU_SLL;
	       SRL: aluOp = ALU_SRL;
	       ADD, ADDU : aluOp = ALU_ADD;
	       SUB, SUBU : aluOp = ALU_SUB;
	       AND : aluOp = ALU_AND;
	       OR : aluOp = ALU_OR;
	       XOR : aluOp = ALU_XOR;
	       NOR : aluOp = ALU_NOR;
	       SLT : aluOp = ALU_SLT;
	       SLTU : aluOp = ALU_SLTU;
	       default : aluOp = '{default:'x}; //Find out how to make it x
	     endcase // case (r_instr.funct)
	  end
	else
	  begin
	     case(iinstr.opcode)
	       ADDI, ADDIU, SW, LW: aluOp = ALU_ADD;
	       LUI: aluOp = ALU_SLL;
	       ANDI : aluOp = ALU_AND;
	       ORI : aluOp = ALU_OR;
	       XORI : aluOp = ALU_XOR;
	       BEQ, BNE: aluOp = ALU_SUB;
	       SLTI: aluOp = ALU_SLT;
	       SLTIU: aluOp = ALU_SLTU;
	       default : aluOp = '{default:'x}; //Find out how to make it x
	     endcase // case (iinstr.opcode)
	  end // else: !if(rinstr.opcode == RTYPE)
     end
   
endmodule // control_unit
