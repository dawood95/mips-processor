/*
  Everett Berry
  epberry@purdue.edu

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
  parameter CPUID = 0;

  always_comb
  begin
    // signals which are always constant
    ccif.ramstore = ccif.dstore[CPUID];
    ccif.dload[CPUID] = ccif.ramload;
    ccif.iload[CPUID] = ccif.ramload;

    // signals with basic combo logic
    ccif.ramREN = (ccif.iREN[CPUID] || ccif.dREN[CPUID]) && !ccif.dWEN[CPUID];
    ccif.ramWEN = ccif.dWEN[CPUID] && !(ccif.iREN[CPUID] || ccif.dREN[CPUID]);

    // referee ram addr based on which enables selected
    if (ccif.iREN[CPUID] && !(ccif.dREN[CPUID] || ccif.dWEN[CPUID]))
      ccif.ramaddr = ccif.iaddr[CPUID];
    else ccif.ramaddr = ccif.daddr[CPUID];

    // tell datapath to wait on instrs or data based on ramstate
    casez (ccif.ramstate)
      BUSY:
      begin
        ccif.iwait[CPUID] = 1;
        ccif.dwait[CPUID] = 1;
      end
      ACCESS:
      begin
        if (ccif.iREN[CPUID] && !(ccif.dREN[CPUID] || ccif.dWEN[CPUID]))
        begin
          ccif.dwait[CPUID] = 1;
          ccif.iwait[CPUID] = 0;
        end else
        begin
          ccif.dwait[CPUID] = 0;
          ccif.iwait[CPUID] = 1;
        end
      end
      default:
      begin
        // Both FREE and ERROR states are covered here
        // What do to on ERROR state?
        ccif.iwait[CPUID] = 0;
        ccif.dwait[CPUID] = 0;
      end
    endcase
  end

endmodule
