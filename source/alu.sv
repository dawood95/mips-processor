`include "alu_if.vh"

module alu (
  input logic CLK, nRST, alu_if.alu aluif
);

always_comb
begin
  case (aluif.opcode)
    aluif.ALU_SLL : // shift left logic
    begin end
    aluif.ALU_SRL : // shift right logic
    begin end
    aluif.ALU_ADD :
    begin end
    aluif.ALU_SUB :
    begin end
    aluif.ALU_AND :
    begin end
    aluif.ALU_OR :
    begin end
    aluif.ALU_XOR :
    begin end
    aluif.ALU_NOR :
    begin end
    aluif.ALU_SLT : // set less than signed
    begin end
    aluif.ALU_SLTU : // set less than unsigned
    begin end
  endcase
end

endmodule

