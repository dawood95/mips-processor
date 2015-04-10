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
	       cache_control_if ccif
	       );

   import cpu_types_pkg::*;

   parameter CPUID = 0;

   typedef struct packed {
      logic 	  valid;
      logic [ITAG_W-1:0] tag;
      word_t data;
   } iblock_t;

   typedef enum 	 logic
			 {IDLE,
			  RAMWAIT } istate_t;

   istate_t state, nextState;
   
   iblock_t [15:0] frames;
   icachef_t icache_addr;
   iblock_t blk; // local
   
   // state machine
   always_ff @(posedge CLK, negedge nRST)
     begin
	if (!nRST)
	  begin
	     frames <= '{default:'0};
	     state <= IDLE;
	     
	  end
	// fill cache if 
	else
	  begin
	     state <= nextState;

	     // update cache on a miss
	     case(state)
	       IDLE: begin
	       end
	       RAMWAIT: begin
	     	  frames[icache_addr.idx].data <= ccif.iload[CPUID];
		  frames[icache_addr.idx].tag <= icache_addr.tag;
		  frames[icache_addr.idx].valid <= 1'b1;
	       end
	     endcase // case (state)
	  end
     end
   
   // output
   always_comb
     begin
	// cast incoming address
	icache_addr = icachef_t'(dcif.imemaddr);
	blk = frames[icache_addr.idx];
	ccif.iaddr[CPUID] = dcif.imemaddr;
	
	case(state)
	  IDLE: begin
	     if (blk.valid & (blk.tag == icache_addr.tag))
	       // hit
	       begin
		  dcif.ihit = 1'b1;
		  dcif.imemload = blk.data;
		  ccif.iREN[CPUID] = 0;
		  nextState = IDLE;
	       end
	     else
	       // miss
	       begin
		  dcif.ihit = 1'b0;
		  ccif.iREN[CPUID] = 1'b0;
		  dcif.imemload = 32'hbad1bad1;
		  nextState = RAMWAIT;
 	       end
	  end // case: IDLE
	  RAMWAIT: begin
	     ccif.iREN[CPUID] = 1'b1;
	     dcif.ihit = ~ccif.iwait[CPUID];
	     dcif.imemload = ccif.iload[CPUID];
	     if (ccif.iwait[CPUID])
		  nextState = RAMWAIT;
	     else
		  nextState = IDLE;
	  end
	endcase // case (state)
       


     end // always_comb
 
endmodule // icache
