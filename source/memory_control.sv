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
    // signals which are always constant
    ccif.ramstore = ccif.dstore;
    ccif.dload = ccif.ramload;
    ccif.iload = ccif.ramload;

    // signals with basic combo logic
    ccif.ramREN = (ccif.iREN || ccif.dREN) && !ccif.dWEN;
    ccif.ramWEN = ccif.dWEN && !(ccif.iREN || ccif.dREN);

    // referee ram addr based on which enables selected
    if (ccif.iREN && !(ccif.dREN || ccif.dWEN))
      ccif.ramaddr = ccif.iaddr;
    else ccif.ramaddr = ccif.daddr;

    // tell datapath to wait on instrs or data based on ramstate
    casez (ccif.ramstate)
      BUSY:
      begin
        ccif.iwait = 1;
        ccif.dwait = 1;
      end
      ACCESS:
      begin
        if (ccif.iREN && !(ccif.dREN || ccif.dWEN))
        begin
          ccif.dwait = 1;
          ccif.iwait = 0;
        end else
        begin
          ccif.dwait = 0;
          ccif.iwait = 1;
        end
      end
      default:
      begin
        // Both FREE and ERROR states are covered here
        ccif.iwait = 0;
        ccif.dwait = 0;
      end
    endcase

/*
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
*/
  end

endmodule
