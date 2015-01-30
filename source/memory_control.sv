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
   parameter CPUS = 1;

   always_comb
     begin
	ccif.iwait = (ccif.iREN == 1'b1 && (ccif.dWEN != 1'b1 && ccif.dREN != 1'b1) && ccif.ramstate == BUSY) ? 1'b1 : 1'b0;
	ccif.dwait = ((ccif.dWEN == 1'b1 || ccif.dREN == 1'b1) && ccif.ramstate == BUSY) ? 1'b1 : 1'b0;
	ccif.ramstore = ccif.dstore;
	ccif.ramaddr = (ccif.dREN == 1'b1 || ccif.dWEN == 1'b1) ? ccif.daddr : ccif.iaddr;
	ccif.iload = (ccif.iREN == 1'b1 && ccif.dREN != 1'b1) ? ccif.ramload : 0;
	ccif.dload = (ccif.dREN == 1'b1) ? ccif.ramload : 0;
	ccif.ramWEN = ccif.dWEN;
	ccif.ramREN = (ccif.dREN | ccif.iREN);
     end
   
endmodule
