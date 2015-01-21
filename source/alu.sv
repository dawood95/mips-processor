`include "alu_if.vh"
// `include "cpu_types_pkg.vh"

module alu (
  input logic CLK, nRST, alu_if.alu aluf
);

  case (aluf.opcode)
    ALU_SLL :
    ALU_SRL :
    ALU_ADD :
    ALU_SUB :
    ALU_AND :
    ALU_OR :
    ALU_XOR :
    ALU_NOR :
    ALU_SLT :
    ALU_SLTU :
  endcase


endmodule

