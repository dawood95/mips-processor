/*
  Everett Berry
  epberry@purdue.edu

  datapath contains register file, control, hazard,
  muxes, and glue logic for processor
*/

// data path interface
`include "datapath_cache_if.vh"

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

  // initialize all the interfaces
  register_file_if rfif ();
  control_unit_if cuif ();
  request_unit_if ruif ();
  alu_if aluif ();
  // pc_if pcif ();

  // hook the modules together
  register_file register(CLK, nRST, rfif);
  control_unit control(cuif);
  request_unit request(CLK, nRST, dpif, ruif);
  alu alu(aluif);
  // pc pc(CLK, nRST, pcif);

  // local vars
  r_t rtype;
  i_t itype;
  j_t jtype;
  word_t extender, pcplus, jumpaddr, branchaddr, jraddr;
  word_t pca, pcb, pcnext;
  regbits_t rt_or_31;

  always_comb
  begin


  end


endmodule
