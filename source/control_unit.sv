/*
  Everett Berry
  epberry@purdue.edu

  control unit for the datapath
*/

`include "cpu_types_pkg.vh"

module control_unit
  import cpu_types_pkg::*;
  (
    input word_t instr,
    input logic zf, of,
    output logic reg_wr_sel, reg_dst, busA_sel, imm_ext_sel,
    output logic memREN, memWEN, regWEN, halt,
    output aluop_t aluOp,
    output logic [1:0] busB_sel
  );

  i_t iinstr;
  r_t rinstr;

  // instruction cast
  always_comb
    begin
      iinstr = i_t'(instr);
      rinstr = r_t'(instr);
    end

  always_comb
    begin
      if(iinstr.opcode == HALT ||
       (rinstr.opcode == RTYPE &&
        (rinstr.funct == ADD ||
         rinstr.funct == SUB) && of) ||
       (iinstr.opcode == ADDI && of))
        halt = 1'b1;
      else
        halt = 1'b0;

      // sign extension
      case(iinstr.opcode)
        ADDIU, ADDI, LW, SLTI, SLTIU, SW: imm_ext_sel = 1'b1;
        default: imm_ext_sel = 1'b0;
      endcase

      // bus B
      if (iinstr.opcode == RTYPE)
        begin
          if (rinstr.funct == SLL || rinstr.funct == SRL)
            busB_sel = 2'b01;
          else
            busB_sel = 2'b00;
        end
      else
        begin
          if (iinstr.opcode == LUI)
            busB_sel = 2'b11;
          else
            busB_sel = 2'b10;
        end

      busA_sel = (iinstr.opcode == LUI) ? 1'b1 : 1'b0;
      reg_wr_sel = (iinstr.opcode == LW) ? 1'b1 : 1'b0;
      reg_dst = (iinstr.opcode == RTYPE) ? 1'b0 : 1'b1;
      memREN = (iinstr.opcode == LW) ? 1'b1 : 1'b0;
      memWEN = (iinstr.opcode == SW) ? 1'b1 : 1'b0;
      regWEN = ((rinstr.opcode == RTYPE && rinstr.funct == JR) ||
        (iinstr.opcode == SW)) ? 0 : 1;
  end

  always_comb
  begin
    if(rinstr.opcode == RTYPE)
    begin
      case(rinstr.funct)
        SLL: aluOp = ALU_SLL;
        SRL: aluOp = ALU_SRL;
        AND : aluOp = ALU_AND;
        OR : aluOp = ALU_OR;
        XOR : aluOp = ALU_XOR;
        NOR : aluOp = ALU_NOR;
        ADD, ADDU : aluOp = ALU_ADD;
        SUB, SUBU : aluOp = ALU_SUB;
        SLT : aluOp = ALU_SLT;
        SLTU : aluOp = ALU_SLTU;
        default : aluOp = '{default:'x};
      endcase
    end else
    begin
      case(iinstr.opcode)
        ADDI, ADDIU, SW, LW: aluOp = ALU_ADD;
        ORI : aluOp = ALU_OR;
        LUI: aluOp = ALU_SLL;
        ANDI : aluOp = ALU_AND;
        XORI : aluOp = ALU_XOR;
        SLTI: aluOp = ALU_SLT;
        SLTIU: aluOp = ALU_SLTU;
        default : aluOp = '{default:'x};
      endcase
    end
  end

endmodule
