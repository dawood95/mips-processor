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
	       datapath_cache_if.icache dcif,
	       cache_control_if.icache ccif
	       );

   import cpu_types_pkg::*;

   parameter CPUID = 0;

   
   typedef struct packed {
      logic 	  valid;
      logic [ITAG_W-1:0] tag;
      word_t data;
   } iblock_t;

   iblock_t [15:0] frames;
   icachef_t icache_addr;
   iblock_t blk; // local
   logic 		 blk_valid; // local
   logic 		 blk_matches;
   
    

   always_ff @(posedge CLK, negedge nRST)
     begin
	if (!nRST)
	  begin
	     frames <= '{default:'0};
	  end
	else if (dcif.imemREN & ~dcif.ihit & ~ccif.iwait)
	  begin
	     frames[icache_addr.idx].data = ccif.iload;
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
	     blk_valid = 1;
	     dcif.imemload = blk.data;
	     ccif.iREN[CPUID] = 0;
	     // dcif.ihit = ~ccif.iwait[CPUID];
	  end
	else
	  // miss
	  begin
	     blk_valid = 0;
	     ccif.iREN = 1;
	     dcif.imemload = ccif.iload[CPUID];
	     // dcif.ihit = 0;
	     
 	  end
	
	// allow for hits to eventually happen after a miss
	dcif.ihit = blk_valid & dcif.imemREN;
      
	// constant output

	ccif.iaddr = dcif.imemaddr;

	/*
	blk_matches = blk.valid & (blk.tag == icache_addr.tag);
	
	dcif.ihit = blk_matches | ~ccif.iwait[CPUID];
	dcif.imemload = (ccif.iREN[CPUID]) ? ccif.iload[CPUID] : blk.data;
	ccif.iREN[CPUID] = ~blk_matches;
	
	*/
     end

endmodule // icache
