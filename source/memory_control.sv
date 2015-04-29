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
		       input logic CLK, nRST,
		       cache_control_if.cc ccif
		       );
   // type import
   import cpu_types_pkg::*;
   // number of cpus for cc
   parameter CPUS = 2;
   parameter CPUID = 0;

   always_comb
     begin

	ccif.ramWEN = ccif.dWEN[CPUID];
	ccif.ramREN = (ccif.dREN[CPUID] | ccif.iREN[CPUID]) & (!ccif.dWEN[CPUID]);

	ccif.iload[CPUID] = ccif.ramload;
	ccif.dload[CPUID] = ccif.ramload;
	ccif.ramstore = ccif.dstore[CPUID];

	ccif.ramaddr = (ccif.dREN[CPUID] | ccif.dWEN[CPUID]) ? ccif.daddr[CPUID] : ccif.iaddr[CPUID];

	casez (ccif.ramstate)
	  FREE:
	    begin
	       ccif.dwait[CPUID] = 1'b0;
	       ccif.iwait[CPUID] = 1'b0;
	    end
	  ACCESS:
	    begin
	       if(ccif.dREN[CPUID] || ccif.dWEN[CPUID])
		 begin
		    ccif.dwait[CPUID] = 1'b0;
		    ccif.iwait[CPUID] = 1'b1;
		 end
	       else
		 begin
		    ccif.iwait[CPUID] = 1'b0;
		    ccif.dwait[CPUID] = 1'b1;
		 end
	    end
	  BUSY:
	    begin
	       ccif.dwait[CPUID] = 1'b1;
	       ccif.iwait[CPUID] = 1'b1;
	    end
	  ERROR:
	    begin
	       ccif.dwait[CPUID] = 1'b1;
	       ccif.iwait[CPUID] = 1'b1;
	    end
	endcase
     end // always_comb

endmodule

/*
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
    if (ccif.dREN[CPUID] || ccif.dWEN[CPUID])
      ccif.ramaddr = ccif.daddr[CPUID];
    else ccif.ramaddr = ccif.iaddr[CPUID];

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
*/
