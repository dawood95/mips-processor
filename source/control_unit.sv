/*
  Everett Berry
  epberry@purdue.edu

  control unit for the datapath
*/

`include "cpu_types_pkg.vh"

module control_unit
  import cpu_types_pkg::*;
   (
    input 	       word_t instr,
    input logic        zf, of,
    output 	       aluop_t aluOp,
    output logic [1:0] portb_sel, pc_sel, regW_sel, wMemReg_sel,
    output logic       porta_sel, immExt_sel, memREN, memWEN, regWEN, brEn, halt
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
	//Halt
	if(iinstr.opcode == HALT ||
	   (rinstr.opcode == RTYPE && 
	    (rinstr.funct == ADD || 
	     rinstr.funct == SUB) && 
	    of) ||
	   (iinstr.opcode == ADDI && of))
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
	// 00 -> PC+4 / PC+4+branch
	// 01 -> Register
	// 10 -> Jump
	if(iinstr.opcode == JAL || iinstr.opcode == J)
	  pc_sel = 2'b10;
	else if(rinstr.opcode == RTYPE && rinstr.funct == JR)
	  pc_sel = 2'b01;
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
		  (iinstr.opcode == SW)) ? 0 : 1;
	//Branch Enable
	if((iinstr.opcode == BEQ && zf == 1) || (iinstr.opcode == BNE && zf == 0))
	  brEn = 1'b1;
	else
	  brEn = 1'b0;
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

`include "cpu_types_pkg.vh"
`include "control_unit_if.vh"

module control_unit (
  input logic CLK, nRST,
  control_unit_if.control cuif
);

  import cpu_types_pkg::*;

  opcode_t opcode;
  funct_t func;

  always_comb
  begin
    // cast instruction to take advantage of cpu types
    opcode = opcode_t'(cuif.instr[31:26]);
    func = funct_t'(cuif.instr[5:0]);

    // Control signals which default to 0
    cuif.alusrc = 1'b0; cuif.lui = 1'b0; cuif.shift = 1'b0;
    cuif.memwr = 1'b0; cuif.memread = 1'b0; cuif.memtoreg = 1'b0;
    cuif.regdst = 1'b0; cuif.halt = 1'b0; cuif.jumpal = 1'b0;
    cuif.lui = 1'b0; cuif.bne = 1'b0; cuif.branch = 1'b0;
    cuif.jump = 1'b0; cuif.jumpreg = 1'b0;

    // Control signals which default to 1
    cuif.regwr = 1'b1; cuif.ext = 1'b1;

    // Other default
    cuif.aluop = aluop_t'('1);

    /*********** R-type ******************/
    if(opcode == RTYPE)
    begin
      cuif.regdst = 1'b1;
      casez(func)
        ADDU, ADD: cuif.aluop = ALU_ADD;
        AND: cuif.aluop = ALU_AND;
        JR: begin
          cuif.jumpreg = 1'b1;
          cuif.regwr = 1'b1;
        end
        NOR: cuif.aluop = ALU_NOR;
        OR: cuif.aluop = ALU_OR;
        SLT: cuif.aluop = ALU_SLT;
        SLTU: cuif.aluop = ALU_SLTU;
        SLL: begin
          cuif.shift = 1'b1;
          cuif.aluop = ALU_SLL;
        end
        SRL: begin
          cuif.shift = 1'b1;
          cuif.aluop = ALU_SRL;
        end
        SUB, SUBU: cuif.aluop = ALU_SUB;
        XOR: cuif.aluop = ALU_XOR;
      endcase
    end

    /********* I-type *************/
    else if (opcode == ADDIU)
    begin
      cuif.alusrc = 1'b1;
      cuif.aluop = ALU_ADD;
    end else if (opcode == ADDI)
    begin
      // ???
      cuif.alusrc = 1'b1;
      cuif.aluop = ALU_ADD;
      cuif.ext = 1'b0;
    end else if (opcode == ANDI)
    begin
      cuif.alusrc = 1'b1;
      cuif.ext = 1'b0;
      cuif.aluop = ALU_AND;
    end else if (opcode == BEQ)
    begin
      cuif.regwr = 1'b0;
      cuif.branch = 1'b1;
      cuif.aluop = ALU_SUB;
    end else if (opcode == BNE)
    begin
      cuif.regwr = 1'b0;
      cuif.bne = 1'b1;
      cuif.aluop = ALU_SUB;
    end else if (opcode == LUI)
    begin
      cuif.lui = 1'b1;
      cuif.alusrc = 1'b1;
      cuif.ext = 1'b0;
      cuif.aluop = ALU_OR;
    end else if (opcode == LW)
    begin
      cuif.memread = 1'b1;
      cuif.alusrc = 1'b1;
      cuif.memtoreg = 1'b1;
      cuif.aluop = ALU_ADD;
    end else if (opcode == ORI)
    begin
      cuif.alusrc = 1'b1;
      cuif.ext = 1'b0;
      cuif.aluop = ALU_OR;
    end else if (opcode == SLTI)
    begin
      cuif.alusrc = 1'b1;
      cuif.aluop = ALU_SLT;
    end else if (opcode == SLTIU)
    begin
      cuif.alusrc = 1'b1;
      cuif.aluop = ALU_SLTU;
    end else if (opcode == SW)
    begin
      cuif.memwr = 1'b1;
      cuif.regwr = 1'b0;
      cuif.alusrc = 1'b1;
      cuif.aluop = ALU_ADD;
    end else if (XORI == opcode)
    begin
      cuif.alusrc = 1'b1;
      cuif.ext = 1'b0;
    end

    /******** J-type ********/
    else if (J == opcode)
    begin
      cuif.regwr = 1'b0;
      cuif.jump = 1'b1;
    end else if (opcode == JAL)
    begin
      cuif.jumpal = 1'b1;
      cuif.jump = 1'b1;
    end

    /******** Other **********/
    else if (opcode == HALT)
    begin
      cuif.halt = 1'b1;
      cuif.regwr = 1'b0;
    end

  end

endmodule
