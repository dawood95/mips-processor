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
		       input CLK, nRST,
		       cache_control_if.cc ccif
		       );
   // type import
   import cpu_types_pkg::*;
   // number of cpus for cc
   parameter CPUS = 2;

   always_ff @(posedge CLK or negedge nRST)
     begin
	if(!nRST)
	  begin
	     iwait <= 1'b0;
	     dwait <= 1'b0;
	     iload <= 1'b0;
	     dload <= 1'b0;
	     
	  end
	else
     end
   

endmodule
