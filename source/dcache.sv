/*
 Sheik Dawood
 dawood0@purdue.edu
 
 Everett Berry
 epberry@purdue.edu
 
 Data Cache
*/

`include "datapath_cache_if.vh"
`include "cache_control_if.vh"
`include "cpu_types_pkg.vh"

module dcache (
	       input logic CLK, nRST,
	       datapath_cache_if dcif,
	       cache_control_if ccif
	       );
   
   // Import types
   import cpu_types_pkg::*;

   parameter CPUID = 0;
   
   // Module specific types
   typedef struct 	   {
      logic [DTAG_W-1:0]   tag;
      logic 		   modified;
      logic 		   valid;
      word_t               data[1:0];
   } block_t;

   typedef struct 	   {
      logic                leastrecent;		   
      block_t              block[1:0];
   } frame_t;

   // Declarations
   typedef enum 	   logic[3:0]	   
			   { idle,
			     ccwrite1,
			     ccwrite2,
			     memwrite1,
			     memwrite2,
			     memload1,
			     memload2,
			     flush1,
			     flush2,
			     halt, //count writeback
			     halt1
			     } dstate_t;
   
   dstate_t 		   currentState, nextState;		   
   frame_t                 frame[7:0];
   dcachef_t               addr, snoopaddr;

   logic 		   wen;
   logic 		   membsel;
   logic 		   bsel;
   // Flush signals
   logic [2:0] 		   flush_frame;
   logic [2:0] 		   next_flush_frame;
   logic  		   flush_block;
   logic  		   next_flush_block;		   
   // Count
   logic 		   count_en;
   word_t                  count;
   // Coherence store
   dstate_t                state_store;
   logic                   bsel_store;		   

   always_ff @(posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  count <= 0;
	else if(count_en)
	  count <= count +  1;
     end

     always_ff @ (posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  begin
	     currentState <= idle;
	     state_store <= idle;
	     frame <= '{default:'0};
	     membsel <= 0;
	     bsel_store <= 0;
	     flush_frame <= 0;
	     flush_block <= 0;
	  end
	else
	  begin
	     currentState <= nextState;
	     membsel <= bsel;
	     flush_frame <= next_flush_frame;
	     flush_block <= next_flush_block;
	     
	     case(currentState)
	       idle:
		 begin
		    if(wen)
		      begin
			 frame[addr.idx].block[bsel].data[addr.blkoff] <= dcif.dmemstore;
			 frame[addr.idx].block[bsel].modified <= 1'b1;
		      end
		 end
	       memload1:
		 begin
		    frame[addr.idx].block[bsel].data[~addr.blkoff] <= ccif.dload[CPUID];
		    frame[addr.idx].block[bsel].tag <= addr.tag;
		    frame[addr.idx].block[bsel].modified <= 1'b0;
		    frame[addr.idx].block[bsel].valid <= 1'b1;
		 end
	       memload2:
		 begin
		    if(dcif.dmemREN)
		      begin
			 frame[addr.idx].block[bsel].data[addr.blkoff] <= ccif.dload[CPUID];
			 frame[addr.idx].block[bsel].tag <= addr.tag;
			 frame[addr.idx].block[bsel].modified <= 1'b0;
			 frame[addr.idx].block[bsel].valid <= 1'b1;
		      end
		    else
		      begin
			 frame[addr.idx].block[bsel].data[addr.blkoff] <= dcif.dmemstore;
			 frame[addr.idx].block[bsel].tag <= addr.tag;
			 frame[addr.idx].block[bsel].modified <= 1'b1;
			 frame[addr.idx].block[bsel].valid <= 1'b1;
		      end
		 end // case: memload2
	       flush2:
		 begin
		    if(nextState == flush1)
		      begin
			 frame[flush_frame].block[flush_block].valid <= 1'b0;
		      end
		 end
	       ccwrite2:
		 begin
		    if(ccif.ccinv[CPUID])
		      begin
			 frame[snoopaddr.idx].block[membsel].valid <= 1'b0;
		      end
		 end
	     endcase
	     if(dcif.dhit & (dcif.dmemREN | dcif.dmemWEN)) frame[addr.idx].leastrecent <= ~bsel;

	     if(nextState == ccwrite1)
	       begin
		  state_store <= currentState;
		  bsel_store <= membsel;
	       end
	  end 
     end // always_ff @
   
   always_comb
     begin
	addr = dcif.dmemaddr;
	snoopaddr = ccif.ccsnoopaddr[CPUID];
     end
   
   // Next State Logic
   always_comb
     begin

	nextState = idle;
	bsel = membsel;
	next_flush_frame = flush_frame;
	next_flush_block = flush_block;

	case(currentState)
	  idle: 
	    begin
	       if(ccif.ccwait[CPUID])
		 begin
		    if(!(frame[snoopaddr.idx].block[0].tag ^ snoopaddr.tag) & 
		       frame[snoopaddr.idx].block[0].valid &
		       frame[snoopaddr.idx].block[0].modified)
		      begin
			 nextState = ccwrite1;
			 bsel = 1'b0;
		      end
		    else if(!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) & 
			    frame[snoopaddr.idx].block[1].valid &
			    frame[snoopaddr.idx].block[1].modified)
		      begin
			 nextState = ccwrite1;
			 bsel = 1'b1;
		      end
		    else
		      begin
			 nextState = idle;
			 bsel = membsel;
		      end // else: !if(!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) &...
		 end // if (ccif.ccwait[CPUID])
	       else if(dcif.halt)
		 begin
		    nextState = flush1;
		    next_flush_frame = 0;
		    next_flush_block = 0;
		 end
	       else if(dcif.dmemWEN)
		 begin
		    if(!(frame[addr.idx].block[0].tag ^ addr.tag) & 
		       (frame[addr.idx].block[0].valid))
		      begin
			 nextState = idle;
			 bsel = 1'b0;
		      end
		    else if(!(frame[addr.idx].block[1].tag ^ addr.tag) &
			    (frame[addr.idx].block[1].valid))
		      begin
			 nextState = idle;
			 bsel = 1'b1;
		      end
		    else
		      begin
			 if(!frame[addr.idx].block[0].valid)
			   begin
			      nextState = memload1;
			      bsel = 1'b0;
			   end
			 else if(!frame[addr.idx].block[1].valid)
			   begin
			      nextState = memload1;
			      bsel = 1'b1;
			   end
			 else
			   begin
			      if(frame[addr.idx].block[frame[addr.idx].leastrecent].modified)
				begin
				   nextState = memwrite1;
				   bsel = frame[addr.idx].leastrecent;
				end
			      else
				begin
				   nextState = memload1;
				   bsel = frame[addr.idx].leastrecent;
				end 
			   end // else: !if(!frame[addr.idx].block[1].valid)
		      end // else: !if(~(frame[addr.idx].block[1].tag ^ addr.tag))
		 end // if (dcif.dmemWEN)
	       else if(dcif.dmemREN)
		 begin
	  	    if(!(frame[addr.idx].block[0].tag ^ addr.tag) & 
		       (frame[addr.idx].block[0].valid))
		      begin
			 nextState = idle;
			 bsel = 1'b0;
		      end
		    else if(!(frame[addr.idx].block[1].tag ^ addr.tag) &
			    (frame[addr.idx].block[1].valid))
		      begin
			 nextState = idle;
			 bsel = 1'b1;
		      end
		    else
		      begin
			 if(!frame[addr.idx].block[0].valid)
			   begin
			      nextState = memload1;
			      bsel = 1'b0;
			   end
			 else if(!frame[addr.idx].block[1].valid)
			   begin
			      nextState = memload1;
			      bsel = 1'b1;
			   end
			 else
			   begin
			      if(frame[addr.idx].block[frame[addr.idx].leastrecent].modified)
				begin
				   nextState = memwrite1;
				   bsel = frame[addr.idx].leastrecent;
				end
			      else
				begin
				   nextState = memload1;
				   bsel = frame[addr.idx].leastrecent;
				end
			   end // else: !if(!frame[addr.idx].block[1].valid)
		      end // else: !if(!(frame[addr.idx].block[1].tag ^ addr.tag) &...
		 end // if (dcif.dmemREN)
	       else
		 begin
		    nextState = idle;
		    bsel = memsel;
		 end
	    end // case: idle
	  memwrite1:
	    begin
	       if(ccif.ccwait[CPUID])
		 begin
		    if(!(frame[snoopaddr.idx].block[0].tag ^ snoopaddr.tag) & 
		       frame[snoopaddr.idx].block[0].valid &
		       frame[snoopaddr.idx].block[0].modified)
		      begin
			 nextState = ccwrite1;
			 bsel = 1'b0;
		      end
		    else if(!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) & 
			    frame[snoopaddr.idx].block[1].valid &
			    frame[snoopaddr.idx].block[1].modified)
		      begin
			 nextState = ccwrite1;
			 bsel = 1'b1;
		      end
		    else
		      nextState = memwrite1;
		 end
	       else if(ccif.dwait[CPUID])
		 nextState = memwrite1;
	       else
		 nextState = memwrite2;
	    end
	  memwrite2:
	    begin
	       if(ccif.dwait[CPUID]) 
		 nextState = memwrite2; 
	       else 
		 nextState = memload1;
	    end
	  memload1:
	    begin	    
	       if(ccif.ccwait[CPUID])
		 begin
		    if(!(frame[snoopaddr.idx].block[0].tag ^ snoopaddr.tag) & 
		       frame[snoopaddr.idx].block[0].valid &
		       frame[snoopaddr.idx].block[0].modified)
		      begin
			 nextState = ccwrite1;
			 bsel = 1'b0;
		      end
		    else if(!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) & 
			    frame[snoopaddr.idx].block[1].valid &
			    frame[snoopaddr.idx].block[1].modified)
		      begin
			 nextState = ccwrite1;
			 bsel = 1'b1;
		      end
		    else
		      nextState = memload1;
		 end
	       else if(ccif.dwait[CPUID])
		 nextState = memload1;
	       else
		 nextState = memload2;
	    end
	  memload2:
	    begin
	       if(ccif.dwait[CPUID]) 
		 nextState = memload2; 
	       else 
		 nextState = idle;
	    end // case: memload2
	  flush1:
	    begin
	       // If write going on, stay in current state
	       if(ccif.ccwait[CPUID])
		 begin
		    if(!(frame[snoopaddr.idx].block[0].tag ^ snoopaddr.tag) & 
		       frame[snoopaddr.idx].block[0].valid &
		       frame[snoopaddr.idx].block[0].modified)
		      begin
			 nextState = ccwrite1;
			 bsel = 1'b0;
		      end
		    else if(!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) & 
			    frame[snoopaddr.idx].block[1].valid &
			    frame[snoopaddr.idx].block[1].modified)
		      begin
			 nextState = ccwrite1;
			 bsel = 1'b1;
		      end
		    else
		      nextState = flush1;
		 end
	       else if(frame[flush_frame].block[flush_block].valid &&
		       frame[flush_frame].block[flush_block].modified)
		 begin
		    if(ccif.dwait[CPUID])
		      nextState = flush1;
		    else
		      nextState = flush2;
		 end // if (frame[flush_frame].block[flush_block].valid &&...
	       else
		 begin
		    if(!(flush_frame ^ 3'b111) & !(flush_block ^ 1'b1))
		      nextState = halt;
		    else
		      nextState = flush1;
		    next_flush_frame = (flush_block) ? flush_frame + 3'd1 : flush_frame;
		    next_flush_block = flush_block ^ 1'b1;
		 end // else: !if(frame[flush_frame].block[flush_block].valid &&...
	    end // case: flush1
	  flush2:
	    begin
	       if(ccif.dwait[CPUID]) // Wait for write to be done
		 begin
		    nextState = flush2;
		    next_flush_frame = flush_frame;
		    next_flush_block = flush_block;
		 end
	       else if(!(flush_frame ^ 3'b111) & !(flush_block ^ 1'b1)) // All flushed. Go to halt.
		 begin
		    nextState = halt;
		    next_flush_frame = flush_frame;
		    next_flush_block = flush_block;
		 end
	       else // Move onto next flush
		 begin
		    nextState = flush1;
		    next_flush_frame = (flush_block) ? flush_frame + 3'd1 : flush_frame;
		    next_flush_block = flush_block ^ 1'b1;
		 end
	    end // case: flush2
	  ccwrite1:
	    begin
	       if(ccif.dwait[CPUID])
		 nextState = ccwrite1;
	       else
		 nextState = ccwrite2;
	    end
	  ccwrite2:
	    begin
	       if(ccif.dwait[CPUID])
		 nextState = ccwrite2;
	       else
		 begin
		    nextState = state_store;
		    bsel = bsel_store;
		 end
	    end
	  halt:
	    begin
	       if(ccif.dwait[CPUID])
		 nextState = halt;
	       else
		 nextState = halt1;
	    end // case: halt
	  halt1:
	    begin
	       nextState = halt1;
	    end
	endcase // case (currentState)
     end // always_comb

   //Output logic
   always_comb
     begin
	wen = 1'b0;
	count_en = 1'b0;

	ccif.dREN[CPUID] = 1'b0;
	ccif.dWEN[CPUID] = 1'b0;
	ccif.cctrans[CPUID] = 1'b0;
	ccif.ccwrite[CPUID] = dcif.dmemWEN ? 1'b1 : 1'b0;
	ccif.dstore[CPUID] = 32'hbad1bad1;
	ccif.daddr[CPUID] = 32'h0;

	dcif.flushed = 1'b0;
	dcif.dmemload = 32'hbad1bad1;

	case(currentState)
	  idle: 
	    begin
	       if(ccif.ccwait[CPUID])
		 begin
		    dcif.dhit = 1'b0;
		    if( !(frame[snoopaddr.idx].block[0].tag ^ snoopaddr.tag) & frame[snoopaddr.idx].block[0].valid & frame[snoopaddr.idx].block[0].modified )
		      ccif.cctrans[CPUID] = 1'b1;
		    else if( !(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) & frame[snoopaddr.idx].block[1].valid & frame[snoopaddr.idx].block[1].modified)
		      ccif.cctrans[CPUID] = 1'b1;
		    else
		      ccif.cctrans[CPUID] = 1'b0;
		 end // if (ccif.ccwait[CPUID])
	       else if(dcif.halt)
		 dcif.dhit = 1'b0;
	       else if(dcif.dmemWEN)
		 begin
		    
		    if(!(frame[addr.idx].block[0].tag ^ addr.tag) & 
		       (frame[addr.idx].block[0].valid))
		      begin
			 wen = 1'b1;
			 count_en = 1'b1;
			 dcif.dhit = 1'b1;		    
		      end
		    else if(!(frame[addr.idx].block[1].tag ^ addr.tag) &
			    (frame[addr.idx].block[1].valid))
		      begin
			 wen = 1'b1;
			 count_en = 1'b1;
		      	 dcif.dhit = 1'b1;
		      end
		    else
		      dcif.dhit = 1'b0;
		 end // if (dcif.dmemWEN)
	       else if(dcif.dmemREN)
		 begin
	  	    if(!(frame[addr.idx].block[0].tag ^ addr.tag) & 
		       (frame[addr.idx].block[0].valid))
		      begin
			 dcif.dhit = 1'b1;
			 count_en = 1'b1;
			 dcif.dmemload = frame[addr.idx].block[0].data[addr.blkoff];
		      end
		    else if(!(frame[addr.idx].block[1].tag ^ addr.tag) &
			    (frame[addr.idx].block[1].valid))
		      begin
			 dcif.dhit = 1'b1;
		 	 count_en = 1'b1;
			 dcif.dmemload = frame[addr.idx].block[1].data[addr.blkoff];
		      end
		    else
		      dcif.dhit = 1'b0;
		 end // if (dcif.dmemREN)
	       else
		 dcif.dhit = 1'b1;
	    end // case: idle
	  memwrite1:
	    begin
	       if(ccif.ccwait[CPUID])
		 begin
		    // If frame's tag and snoop tag matches and it is modified and valid, then go to ccwrite1 and assert cctrans
		    if(!(frame[snoopaddr.idx].block[0].tag ^ snoopaddr.tag) & frame[snoopaddr.idx].block[0].valid & frame[snoopaddr.idx].block[0].modified)
		      ccif.cctrans[CPUID] = 1'b1;
		    else if(!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) & frame[snoopaddr.idx].block[1].valid & frame[snoopaddr.idx].block[1].modified)
		      ccif.cctrans[CPUID] = 1'b1;
		    else
		      ccif.cctrans[CPUID] = 1'b0;
		 end
	       else
		 ccif.cctrans[CPUID] = 1'b0;

	       ccif.dWEN[CPUID] = 1'b1;
	       ccif.dstore[CPUID] = frame[addr.idx].block[membsel].data[0];
	       ccif.daddr[CPUID] = {frame[addr.idx].block[membsel].tag,addr.idx,1'b0,addr.bytoff};
	       dcif.dhit = 1'b0;
	    end
	  memwrite2:
	    begin
	       ccif.dWEN[CPUID] = 1'b1;
	       ccif.dstore[CPUID] = frame[addr.idx].block[membsel].data[1];
	       ccif.daddr[CPUID] = {frame[addr.idx].block[membsel].tag,addr.idx,1'b1,addr.bytoff};
	       dcif.dhit = 1'b0;
	    end
	  memload1:
	    begin	    
	       if(ccif.ccwait[CPUID])
		 begin
		    if(!(frame[snoopaddr.idx].block[0].tag ^ snoopaddr.tag) & frame[snoopaddr.idx].block[0].valid & frame[snoopaddr.idx].block[0].modified)
		      ccif.cctrans[CPUID] = 1'b1;
		    else if(!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) & frame[snoopaddr.idx].block[1].valid & frame[snoopaddr.idx].block[1].modified)
		      ccif.cctrans[CPUID] = 1'b1;
		    else
		      ccif.cctrans[CPUID] = 1'b0;
		 end
	       else
		 ccif.cctrans[CPUID] = 1'b0;

	       wen = ~ccif.dwait[CPUID];
	       ccif.dREN[CPUID] = 1'b1;
	       ccif.daddr[CPUID] = {addr.tag,addr.idx,~addr.blkoff,addr.bytoff};
	       dcif.dhit = 1'b0;
	    end
	  memload2:
	    begin
	       wen = 1'b1;
	       ccif.dREN[CPUID] = 1'b1;
	       ccif.daddr[CPUID] = {addr.tag,addr.idx,addr.blkoff,addr.bytoff};
	       dcif.dmemload = ccif.dload;
	       dcif.dhit = ~(ccif.dwait[CPUID]);	       
	    end // case: memload2
	  flush1:
	    begin
	       if(ccif.ccwait[CPUID])
		 begin
		    if(!(frame[snoopaddr.idx].block[0].tag ^ snoopaddr.tag) & frame[snoopaddr.idx].block[0].valid & frame[snoopaddr.idx].block[0].modified)
		      ccif.cctrans[CPUID] = 1'b1;
		    else if(!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) & frame[snoopaddr.idx].block[1].valid & frame[snoopaddr.idx].block[1].modified)
		      ccif.cctrans[CPUID] = 1'b1;
		    else
		      ccif.cctrans[CPUID] = 1'b0;
		 end
	       else
		 ccif.cctrans[CPUID] = 1'b0;
	       
	       if(frame[flush_frame].block[flush_block].valid &&
		  frame[flush_frame].block[flush_block].modified)
		 begin
		    ccif.dWEN[CPUID] = 1'b1;
		    ccif.dstore[CPUID] = frame[flush_frame].block[flush_block].data[0];
		    ccif.daddr[CPUID] = {frame[flush_frame].block[flush_block].tag,flush_frame,3'b000};
		 end // if (frame[flush_frame].block[flush_block].valid &&...
	       dcif.dhit = 1'b0;
	    end // case: flush1
	  flush2:
	    begin
	       ccif.dWEN[CPUID] = 1'b1;
	       ccif.dstore[CPUID] = frame[flush_frame].block[flush_block].data[1];
	       ccif.daddr[CPUID] = {frame[flush_frame].block[flush_block].tag,flush_frame,3'b100};
	       dcif.dhit = 1'b0;
	    end // case: flush2
	  ccwrite1:
	    begin
	       ccif.dWEN[CPUID] = 1'b1;
	       ccif.dstore[CPUID] = frame[snoopaddr.idx].block[membsel].data[~snoopaddr.blkoff];
	       ccif.daddr[CPUID] = {snoopaddr.tag,snoopaddr.idx,~snoopaddr.blkoff,snoopaddr.bytoff};
	       dcif.dhit = 1'b0;
	    end
	  ccwrite2:
	    begin
	       ccif.dWEN[CPUID] = 1'b1;
	       ccif.dstore[CPUID] = frame[snoopaddr.idx].block[membsel].data[snoopaddr.blkoff];
	       ccif.daddr[CPUID] = {snoopaddr.tag,snoopaddr.idx,snoopaddr.blkoff,snoopaddr.bytoff};
	       dcif.dhit = 1'b0;
	    end
	  halt:
	    begin
	       ccif.dWEN[CPUID] = 1;
	       ccif.dstore[CPUID] = count;
	       ccif.daddr[CPUID] = 32'h3100;
	       dcif.dhit = 1'b0;
	    end // case: halt
	  halt1:
	    begin
	       dcif.dhit = 1'b1;
	       dcif.flushed = 1'b1;
	    end
	endcase // case (currentState)
     end // always_comb
   
endmodule // dcache

   
   
