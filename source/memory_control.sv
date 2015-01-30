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
  parameter CPUS = 2;

  always_comb
  begin
    // an instruction is being fetched
    if (ccif.iREN[CPUID] && ccif.ramstate == ACCESS) ccif.iwait = 0;
    else ccif.iwait = 1;

    // data is being fetched
    if ((ccif.dREN[CPUID] || ccif.dWEN[CPUID]) && ccif.ramstate == ACCESS)
      ccif.dwait = 0;
    else ccif.dwait = 1;

    // find the address being read or written
    if (ccif.dREN[CPUID] || ccif.dWEN[CPUID])
      ccif.ramaddr = ccif.daddr[CPUID];
    else ccif.ramaddr = ccif.iaddr[CPUID];

    // is the ram being read or written?
    if (ccif.dREN[CPUID] || ccif.iREN[CPUID]) ccif.ramREN = 1;
    else ccif.ramREN = 0;

  end

  // simply output these signals from the interface
  assign ccif.ramstore = ccif.dstore[CPUID];
  assign ccif.iload = ccif.ramload;
  assign ccif.dload = ccif.ramload;
  assign ccif.ramWEN = ccif.dWEN[CPUID];

endmodule
