`include "alu_if.vh"
`include "cpu_types_pkg.vh"

module alu
import cpu_types_pkg::*;
(
  input logic CLK, nRST, alu_if.alu aluif
);

  word_t tempOut;

always_comb
begin
  case (aluif.opcode)
    ALU_SLL : // shift left logic
    begin end
    ALU_SRL : // shift right logic
    begin end
    ALU_ADD :
    begin
      tempOut = aluif.portA + aluif.portB;
      /* addition overflow detection method:
       * pos + pos = neg is overflow
       * neg + neg = pos is overflow
       * so check signs of operands AND result
       */
       if (aluif.portA[31] && aluif.portB[31])
       begin
         if (aluif.portB[31] && !aluif.outPort[31]) aluif.overflow = 1;
       end else aluif.overflow = 0;
    end
    ALU_SUB :
    begin
      tempOut = aluif.portA - aluif.portB;
      /* subtraction overflow detection method:
       * neg - pos = pos is overflow
       * pos - neg = neg is overflow
       * so check signs of operands AND result
       */
      if (!(aluif.portA[31] && aluif.portB[31]))
      begin
        if (aluif.portB[31] && aluif.outPort[31]) aluif.overflow = 1;
      end else aluif.overflow = 0;
    end
    ALU_AND :
    begin end
    ALU_OR :
    begin end
    ALU_XOR :
    begin end
    ALU_NOR :
    begin end
    ALU_SLT : // set less than signed (a<b -> 1, inverse -> 0)
    begin end
    ALU_SLTU : // set less than unsigned
    begin end
  endcase
end

  assign aluif.outPort = tempOut;
  assign aluif.negative = tempOut[31];
  assign aluif.zero = (tempOut == 0);

endmodule

