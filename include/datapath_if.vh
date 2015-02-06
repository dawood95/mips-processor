/*
  Everett Berry
  epberry@purdue.edu

  datapath interface
*/

`ifndef DATAPATH_IF_VH
`define DATAPATH_IF_VH

`include "cpu_types_pkg.vh"
`include "register_file_if.vh"
`include "alu_if.vh"
`include "control_unit_if.vh"
`include "request_unit_if.vh"
// `include "pc_if.vh"

module datapath (
  input logic CLK, nRST,
  datapath_cache_if.dp dpif
);

  import cpu_types_pkg::*;

  parameter PC_INIT = 0;



endmodule
