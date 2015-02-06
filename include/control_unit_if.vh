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

  logic extOp, ALUsrc, lui, shift; // ALU related instructions
  logic memwr, memread, memtoreg, regwr, regdst; // move data around
  logic beq, bne, jumpi, jumpreg, jumpal; // jump and branch
  logic [2:0] PCsrc; // several options for next addr
  logic halt;

  modport control (
    input instr,
    output extOp, ALUsrc, lui, shift,
    memwr, memread, memtoreg, regwr, regdst,
    beq, bne, jumpi, jumpreg, jumpal, halt,
    output PCsrc
  );

  modport tb (
    output instr,
    input extOp, ALUsrc, lui, shift,
    memwr, memread, memtoreg, regwr, regdst,
    beq, bne, jumpi, jumpreg, jumpal, halt,
    input PCsrc
  );

endinterface

`endif // DATAPATH_IF_VH
