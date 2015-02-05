/*
  Everett Berry
  epberry@purdue.edu

  interface for the program counter
*/

`ifndef PC_IF_VH
`define PC_IF_VH

`include "cpu_types_pkg.vh"

interface pc_if;

  import cpu_types_pkg::*;

  word_t addr;

  logic [25:0] jumpi_addr;
  logic [15:0] branch_addr;
  logic halt;

  modport pc (
    input jumpi_addr, branch_addr, halt,
    output addr
  );

  modport tb (
    output jumpi_addr, branch_addr, halt,
    input addr
  );

endinterface

`endif // PC_IF_VH
