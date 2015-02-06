/*
  Everett Berry
  epberry@purdue.edu

  control unit interface - takes in instruction and spits out control signals
*/

`ifndef CONTROL_UNIT_IF_VH
`define CONTROL_UNIT_IF_VH

`include "cpu_types_pkg.vh"

interface control_unit_if;

  import cpu_types_pkg::*;

  word_t instr;
  aluop_t ALUop;

  logic ext, alusrc, lui, shift; // ALU related instructions
  logic memwr, memread, memtoreg, regwr, regdst; // move data around
  logic branch, jumpi, jumpreg, jumpal; // jump and branch
  logic [2:0] PCsrc; // several options for next addr
  logic halt;

  modport control (
    input instr,
    output ext, alusrc, lui, shift,
    memwr, memread, memtoreg, regwr, regdst,
    beq, bne, jumpi, jumpreg, jumpal, halt,
    output PCsrc
  );

endinterface

`endif // DATAPATH_IF_VH

/*

 assign cuif.regdest = (opcode == RTYPE);
assign cuif.halt = (opcode == HALT);
assign cuif.memread = (opcode == LW);
assign cuif.memwrite = (opcode == SW);
assign cuif.jal = (opcode == JAL);
assign cuif.regwrite = ~((func == JR) | (opcode == BEQ) | (opcode == BNE) |
(opcode == SW) | (opcode == J) | (opcode == HALT));
assign cuif.lui = (opcode == LUI);
assign cuif.alusrc = (opcode == ADDIU) | (opcode == ANDI) | (opcode == LUI) |
(opcode == LW) | (opcode == ORI) | (opcode == SLTI) | (opcode == SLTIU) |
(opcode == SW) | (opcode == LL) | (opcode == SC) | (opcode == XORI);
assign cuif.bne = (opcode == BNE);
assign cuif.memtoreg = (opcode == LW);
assign cuif.branch = (opcode == BEQ) | (opcode == BNE);
assign cuif.jump = (opcode == J) | (opcode == JAL);
assign cuif.jr = (opcode == RTYPE) & (func == JR);
assign cuif.extendtype = ~((opcode == ANDI) | (opcode == LUI) | (opcode == ORI) |
(opcode == XORI));
assign cuif.shift = (opcode == RTYPE) & ((func == SLL) | (func == SRL));

// alu op development
aluop_t opfromfunct;
always_comb begin
casez (func)
SLL: opfromfunct = ALU_SLL;
SRL: opfromfunct = ALU_SRL;
ADD, ADDU: opfromfunct = ALU_ADD;
SUB, SUBU: opfromfunct = ALU_SUB;
AND: opfromfunct = ALU_AND;
OR: opfromfunct = ALU_OR;
XOR: opfromfunct = ALU_XOR;
NOR: opfromfunct = ALU_NOR;
SLT: opfromfunct = ALU_SLT;
SLTU: opfromfunct = ALU_SLTU;
default: opfromfunct = aluop_t'('1);
endcase

casez (opcode)
RTYPE: cuif.aluop = opfromfunct;
ADDIU, LW, SW, LL, SC: cuif.aluop = ALU_ADD;
ANDI: cuif.aluop = ALU_AND;
ORI, LUI: cuif.aluop = ALU_OR;
BEQ, BNE: cuif.aluop = ALU_SUB;
SLTI: cuif.aluop = ALU_SLT;
SLTIU: cuif.aluop = ALU_SLTU;
XOR: cuif.aluop = ALU_XOR;
default: cuif.aluop = aluop_t'('1);
endcase
end

/*
