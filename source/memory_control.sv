/*
 Sheik Dawood
 dawood0@purdue.edu

 this block is the coherence protocol
 and artibtration for ram
 */

// interface include
`include "cache_control_if.vh"

// memory types
`include "cpu_types_pkg.vh"

module memory_control (
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
