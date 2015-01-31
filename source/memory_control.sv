/*
  Eric Villasenor
  evillase@gmail.com

  this block is the coherence protocol
  and artibtration for ram
*/

// interface include
`include "cache_control_if.vh"

// memory types
`include "cpu_types_pkg.vh"

module memory_control (
  input CLK, nRST,
  cache_control_if.cc ccif
);
  // type import
  import cpu_types_pkg::*;

  // number of cpus for cc
  parameter CPUS = 1;

  // intermediate states
  logic iwait, dwait, rWEN, rREN;

  always_comb
  begin
    iwait = (ccif.iREN[0] && ccif.ramstate == ACCESS) ? 0 : 1;
    dwait = (ccif.dREN[0] || ccif.dWEN[0]) && ccif.ramstate == ACCESS ? 0 : 1;
    ccif.iwait = iwait || !dwait;
    ccif.dwait = dwait;
    ccif.ramstore = ccif.dstore[0];
    ccif.iload = ccif.ramload;
    ccif.dload = ccif.ramload;
    ccif.ramWEN = ccif.dWEN[0];
    ccif.ramaddr = (ccif.dREN[0] || ccif.dWEN[0]) ? ccif.daddr[0] : ccif.iaddr[0];
    ccif.ramREN = (ccif.dREN[0] || ccif.iREN[0]) && !ccif.dWEN[0] ? 1 : 0;
  end

  // other assigns
/*
  assign ccif.iwait = (ccif.iREN[0] && ccif.ramstate == ACCESS) ? 0 : 1;
  assign ccif.dwait = ((ccif.dREN[0] || ccif.dWEN[0]) && ccif.ramstate) == ACCESS ? 0 : 1;
  assign ccif.ramaddr = (ccif.dREN[0] || ccif.dWEN[0]) ? ccif.daddr[0] : ccif.iaddr[0];
  assign ccif.ramREN = (ccif.dREN[0] || ccif.iREN[0]) ? 1 : 0;

  // simply output these signals from the interface
  assign ccif.ramstore = ccif.dstore[0];
  assign ccif.iload = ccif.ramload;
  assign ccif.dload = ccif.ramload;
  assign ccif.ramWEN = ccif.dWEN[0];
*/

endmodule
