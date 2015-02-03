/*
  Everett Berry
  epberry@purdue.edu

  interface for the internal peices of the datapath, including

  alu, register_file, request_unit, control_unit, and pc
*/

`ifndef CONTROL_UNIT_IF_VH
`define CONTROL_UNIT_IF_VH

`include "cpu_types_pkg.vh"

interface control_unit_if;

  import cpu_types_pkg::*;

  // ports to alu

endinterface

`endif // DATAPATH_IF_VH
