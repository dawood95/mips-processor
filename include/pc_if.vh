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

  word_t addr, next_addr;
  logic pc_pause;

  modport prog (
    input next_addr, pc_pause,
    output addr
  );


endinterface

`endif // PC_IF_VH
