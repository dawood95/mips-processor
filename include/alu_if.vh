/*
  Everett Berry
  epberry@purdue.edu

  alu interface
*/
`ifndef ALU_IF_VH
`define ALU_IF_VH

// all types
`include "cpu_types_pkg.vh"

interface alu_if;
  // import types
  import cpu_types_pkg::*;

  aluop_t opcode;
  word_t portA, portB, outPort;
  logic negative, overflow, zero;

  // alu ports
  modport alu (
    input opcode, portA, portB,
    output outPort, negative, overflow, zero
  );

  // alu tb ports
  modport tb (
    input opcode, portA, portB,
    output outPort, negative, overflow, zero
  );
endinterface

`endif // ALU_IF_VH
