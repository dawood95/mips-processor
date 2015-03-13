/*
 Sheik Dawood
 dawood0@purdue.edu
 
 Everett Berry
 epberry@purdue.edu
 
 Instruction cache
 */

`include "datapath_cache_if.vh"
`include "cache_control_if.vh"

module icache (
	       input logic CLK, nRST,
	       datapath_cache_if.dp dcif,
	       cache_control_if.cc ccif
	       );

   import cpu_types_pkg::*;

   parameter CPUID = 0;

   
   typedef struct packed {
      logic 	  valid;
      logic [IIDX_W-1:0] tag;
      word_t data;
   } iblock_t;

   iblock_t [15:0] frames;
   icachef_t icache_addr;
   iblock_t blk; // local

   always_ff @(posedge CLK, negedge nRST)
     begin
	if (!nRST)
	  begin
	     frames <= '{default:'0};
	  end
	else if (dcif.imemREN & dcif.ihit & ~ccif.iwait[CPUID])
	  begin
	     frames[icache_addr.idx].data = ccif.imemload;
	     frames[icache_addr.idx].tag = icache_addr.tag;
	     frames[icache_addr.idx].valid = 1;
	  end	
     end
   
   always_comb
     begin
	// cast incoming address
	icache_addr = icachef_t'(dcif.imemaddr);

	blk = frames[icache_addr.idx];
	
	if (blk.valid & (blk.tag == icache_addr.tag))
	  // hit
	  begin
	     dcif.ihit = ~ccif.iwait[CPUID]; // if there are bugs... look here
	     dcif.imemload = blk.data;
	     ccif.iREN[CPUID] = 0;
	  end
	else
	  // miss
	  begin
	     dcif.ihit = 0;
	     ccif.iREN[CPUID] = 1;
	     dcif.imemload = ccif.iload[CPUID];
 	  end

	// constant output
	ccif.iaddr[CPUID] = dcif.imemaddr;
     end

endmodule // icache
