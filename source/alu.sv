`include "alu_if.vh"
`include "cpu_types_pkg.vh"

module alu
import cpu_types_pkg::*;
(
  alu_if.alu aluif
);

  word_t tempOut;

always_comb
begin
  case (aluif.opcode)
    // shift left logic
    ALU_SLL : tempOut = aluif.portA << aluif.portB;
    // shift right logic
    ALU_SRL : tempOut = aluif.portA >> aluif.portB;
    ALU_ADD :
    begin
      tempOut = $signed(aluif.portA) + $signed(aluif.portB);
      /* addition overflow detection method:
       * pos + pos = neg is overflow
       * neg + neg = pos is overflow
       * so check signs of operands AND result
       */
       if (aluif.portA[31] ~^ aluif.portB[31])
       begin
         if (aluif.portB[31] ^ aluif.outPort[31]) aluif.overflow = 1;
       end else aluif.overflow = 0;
    end
    ALU_SUB :
    begin
      tempOut = $signed(aluif.portA) - $signed(aluif.portB);
      /* subtraction overflow detection method:
       * neg - pos = pos is overflow
       * pos - neg = neg is overflow
       * so check signs of operands AND result
       */
      if (aluif.portA[31] ^ aluif.portB[31])
      begin
        if (aluif.portB[31] ~^ aluif.outPort[31]) aluif.overflow = 1;
      end else aluif.overflow = 0;
    end
    ALU_AND : tempOut = aluif.portB & aluif.portA;
    ALU_OR : tempOut = aluif.portA | aluif.portB;
    ALU_XOR : tempOut = aluif.portA ^ aluif.portB;
    ALU_NOR : tempOut = !(aluif.portA | aluif.portB);
    // set less than signed (a<b -> 1, inverse -> 0)
    ALU_SLT : tempOut = $signed(aluif.portA) < $signed(aluif.portB);
    // set less than unsigned
    ALU_SLTU : tempOut = (aluif.portA < aluif.portB);
  endcase
end

  assign aluif.outPort = tempOut;
  assign aluif.negative = tempOut[31];
  assign aluif.zero = (tempOut == 0);

endmodule

