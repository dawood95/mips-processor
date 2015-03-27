/*
 Sheik Dawood
 dawood0@purdue.edu
 
 Data Cache
 
 TO DO:
 Flush
 Counter
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
			     memwrite1,
			     memwrite2,
			     memload1,
			     memload2,
			     flush1,
			     flush2,
			     halt,
			     halt1
			     } dstate_t;
   
   dstate_t 		   currentState, nextState;		   
   frame_t                 frame[7:0];
   dcachef_t               addr;

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

   always_ff @(posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  count <= 0;
	else if(count_en)
	  count <= count + 1;
     end
   
   always_ff @ (posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  begin
	     currentState <= idle;
	     frame <= '{default:'0};
	     membsel <= 0;
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
		    frame[addr.idx].block[bsel].data[~addr.blkoff] <= ccif.dload;
		    frame[addr.idx].block[bsel].tag <= addr.tag;
		    frame[addr.idx].block[bsel].modified <= 1'b0;
		    frame[addr.idx].block[bsel].valid <= 1'b1;
		 end
	       memload2:
		 begin
		    if(dcif.dmemREN)
		      begin
			 frame[addr.idx].block[bsel].data[addr.blkoff] <= ccif.dload;
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
		    if(nextState == halt)
		      begin
			 frame[0].block[1].valid <= 1'b0;
			 frame[1].block[0].valid <= 1'b0;
			 frame[1].block[1].valid <= 1'b0;
			 frame[2].block[0].valid <= 1'b0;
			 frame[2].block[1].valid <= 1'b0;
			 frame[3].block[0].valid <= 1'b0;
			 frame[3].block[1].valid <= 1'b0;
			 frame[4].block[0].valid <= 1'b0;
			 frame[4].block[1].valid <= 1'b0;
			 frame[5].block[0].valid <= 1'b0;
			 frame[5].block[1].valid <= 1'b0;
			 frame[6].block[0].valid <= 1'b0;
			 frame[6].block[1].valid <= 1'b0;
			 frame[7].block[0].valid <= 1'b0;
			 frame[7].block[1].valid <= 1'b0;
		      end
		 end
	     endcase
	     if(dcif.dhit & (dcif.dmemREN | dcif.dmemWEN)) frame[addr.idx].leastrecent <= ~bsel;
	  end 
     end

   always_comb
     begin
	addr = dcif.dmemaddr;	

	case(currentState)
	  idle: begin
	     if(dcif.halt)
	       begin
		  nextState = flush1;
		  next_flush_frame = 0;
		  next_flush_block = 0;
		  bsel = 1'b0;
		  wen = 1'b0;
		  count_en = 1'b0;
		  ccif.dREN = 1'b0;
		  ccif.dWEN = 1'b0;
		  ccif.dstore = 32'hbad1bad1;
		  ccif.daddr = 32'b0;
		  dcif.flushed = 1'b0;
		  dcif.dmemload = 32'hbad1bad1;
		  dcif.dhit = 1'b0;
	       end
	     else if(dcif.dmemWEN)
	       begin
		  if(!(frame[addr.idx].block[0].tag ^ addr.tag) & 
		     (frame[addr.idx].block[0].valid))
		    begin
		       nextState = idle;
		       next_flush_frame = 0;
		       next_flush_block = 0;
		       bsel = 1'b0;
		       wen = 1'b1;
		       count_en = 1'b1;
		       ccif.dREN = 1'b0;
		       ccif.dWEN = 1'b0;
		       ccif.dstore = 32'hbad1bad1;
		       ccif.daddr = 32'b0;
		       dcif.flushed = 1'b0;
		       dcif.dmemload = 32'hbad1bad1;
		       dcif.dhit = 1'b1;
		      end
		    else if(!(frame[addr.idx].block[1].tag ^ addr.tag) &
			    (frame[addr.idx].block[1].valid))
		      begin
			 nextState = idle;
			 next_flush_frame = 0;
			 next_flush_block = 0;
			 bsel = 1'b1;
			 wen = 1'b1;
			 count_en = 1'b1;
			 ccif.dREN = 1'b0;
			 ccif.dWEN = 1'b0;
			 ccif.dstore = 32'hbad1bad1;
			 ccif.daddr = 32'b0;
			 dcif.flushed = 1'b0;
			 dcif.dmemload = 32'hbad1bad1;
			 dcif.dhit = 1'b1;
		      end
		    else
		      begin
			 if(!frame[addr.idx].block[0].valid)
			   begin
			      nextState = memload1;
			      next_flush_frame = 0;
			      next_flush_block = 0;
			      bsel = 1'b0;
			      wen = 1'b0;
			      count_en = 1'b0;
			      ccif.dREN = 1'b0;
			      ccif.dWEN = 1'b0;
			      ccif.dstore = 32'hbad1bad1;
			      ccif.daddr = 32'b0;
			      dcif.flushed = 1'b0;
			      dcif.dmemload = 32'hbad1bad1;
			      dcif.dhit = 1'b0;
			   end
			 else if(!frame[addr.idx].block[1].valid)
			   begin
			      nextState = memload1;
			      next_flush_frame = 0;
			      next_flush_block = 0;
			      bsel = 1'b1;
			      wen = 1'b0;
			      count_en = 1'b0;
			      ccif.dREN = 1'b0;
			      ccif.dWEN = 1'b0;
			      ccif.dstore = 32'hbad1bad1;
			      ccif.daddr = 32'b0;
			      dcif.flushed = 1'b0;
			      dcif.dmemload = 32'hbad1bad1;
			      dcif.dhit = 1'b0;
			   end
			 else
			   begin
			      if(frame[addr.idx].block[frame[addr.idx].leastrecent].modified)
				begin
				   nextState = memwrite1;
				   next_flush_frame = 0;
				   next_flush_block = 0;
				   bsel = frame[addr.idx].leastrecent;
				   wen = 1'b0;
				   count_en = 1'b0;
				   ccif.dREN = 1'b0;
				   ccif.dWEN = 1'b0;
				   ccif.dstore = 32'hbad1bad1;
				   ccif.daddr = 32'b0;
				   dcif.flushed = 1'b0;
				   dcif.dmemload = 32'hbad1bad1;
				   dcif.dhit = 1'b0;
				end
			      else
				begin
				   nextState = memload1;
				   next_flush_frame = 0;
				   next_flush_block = 0;
				   bsel = frame[addr.idx].leastrecent;
				   wen = 1'b0;
				   count_en = 1'b0;
				   ccif.dREN = 1'b0;
				   ccif.dWEN = 1'b0;
				   ccif.dstore = 32'hbad1bad1;
				   ccif.daddr = 32'b0;
				   dcif.flushed = 1'b0;
				   dcif.dmemload = 32'hbad1bad1;
				   dcif.dhit = 1'b0;
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
			 next_flush_frame = 0;
			 next_flush_block = 0;
			 bsel = 1'b0;
			 wen = 1'b0;
			 count_en = 1'b1;
			 ccif.dREN = 1'b0;
			 ccif.dWEN = 1'b0;
			 ccif.dstore = 32'hbad1bad1;
			 ccif.daddr = 32'b0;
			 dcif.flushed = 1'b0;
			 dcif.dmemload = frame[addr.idx].block[0].data[addr.blkoff];
			 dcif.dhit = 1'b1;
		      end
		    else if(!(frame[addr.idx].block[1].tag ^ addr.tag) &
			    (frame[addr.idx].block[1].valid))
		      begin
			 nextState = idle;
			 next_flush_frame = 0;
			 next_flush_block = 0;
			 bsel = 1'b1;
			 wen = 1'b0;
		 	 count_en = 1'b1;
			 ccif.dREN = 1'b0;
			 ccif.dWEN = 1'b0;
			 ccif.dstore = 32'hbad1bad1;
			 ccif.daddr = 32'b0;
			 dcif.flushed = 1'b0;
			 dcif.dmemload = frame[addr.idx].block[1].data[addr.blkoff];
			 dcif.dhit = 1'b1;
		      end
		    else
		      begin
			 if(!frame[addr.idx].block[0].valid)
			   begin
			      nextState = memload1;
			      next_flush_frame = 0;
			      next_flush_block = 0;
			      bsel = 1'b0;
			      wen = 1'b0;
			      count_en = 1'b0;
			      ccif.dREN = 1'b0;
			      ccif.dWEN = 1'b0;
			      ccif.dstore = 32'hbad1bad1;
			      ccif.daddr = 32'b0;
			      dcif.flushed = 1'b0;
			      dcif.dmemload = 32'hbad1bad1;
			      dcif.dhit = 1'b0;
			   end
			 else if(!frame[addr.idx].block[1].valid)
			   begin
			      nextState = memload1;
			      next_flush_frame = 0;
			      next_flush_block = 0;			      
			      bsel = 1'b1;
			      wen = 1'b0;
			      count_en = 1'b0;
			      ccif.dREN = 1'b0;
			      ccif.dWEN = 1'b0;
			      ccif.dstore = 32'hbad1bad1;
			      ccif.daddr = 32'b0;
			      		  dcif.flushed = 1'b0;
			      dcif.dmemload = 32'hbad1bad1;
			      dcif.dhit = 1'b0;
			   end
			 else
			   begin
			      if(frame[addr.idx].block[frame[addr.idx].leastrecent].modified)
				begin
				   nextState = memwrite1;
				   next_flush_frame = 0;
				   next_flush_block = 0;
				   bsel = frame[addr.idx].leastrecent;
				   wen = 1'b0;
				   count_en = 1'b0;
				   ccif.dREN = 1'b0;
				   ccif.dWEN = 1'b0;
				   ccif.dstore = 32'hbad1bad1;
				   ccif.daddr = 32'b0;
				   dcif.flushed = 1'b0;
				   dcif.dmemload = 32'hbad1bad1;
				   dcif.dhit = 1'b0;
				end
			      else
				begin
				   nextState = memload1;
				   next_flush_frame = 0;
				   next_flush_block = 0;
				   bsel = frame[addr.idx].leastrecent;
				   wen = 1'b0;
				   count_en = 1'b0;
				   ccif.dREN = 1'b0;
				   ccif.dWEN = 1'b0;
				   ccif.dstore = 32'hbad1bad1;
				   ccif.daddr = 32'b0;
				   dcif.flushed = 1'b0;
				   dcif.dmemload = 32'hbad1bad1;
				   dcif.dhit = 1'b0;
				end
			   end
		      end // else: !if(!(frame[addr.idx].block[1].tag ^ addr.tag) &...
		 end // if (dcif.dmemREN)
	       else
		 begin
		    nextState = idle;
		    next_flush_frame = 0;
		    next_flush_block = 0;
		    bsel = 1'b0;
		    wen = 1'b0;
		    count_en = 1'b0;
		    ccif.dREN = 1'b0;
		    ccif.dWEN = 1'b0;
		    ccif.dstore = 32'hbad1bad1;
		    ccif.daddr = 32'b0;
		    dcif.flushed = 1'b0;
		    dcif.dmemload = 32'hbad1bad1;
		    dcif.dhit = 1'b1;
		 end
	    end // case: idle
	  memwrite1:
	    begin
	       if(ccif.dwait) 
		 nextState = memwrite1;
	       else 
		 nextState = memwrite2;
	       next_flush_frame = 0;
	       next_flush_block = 0;
	       bsel = membsel;
	       wen = 1'b0;
	       count_en = 1'b0;
	       ccif.dREN = 1'b0;
	       ccif.dWEN = 1'b1;
	       ccif.dstore = frame[addr.idx].block[membsel].data[0];
	       ccif.daddr = {frame[addr.idx].block[membsel].tag,addr.idx,1'b0,addr.bytoff};
	       dcif.flushed = 1'b0;
	       dcif.dmemload = 32'hbad1bad1;
	       dcif.dhit = 1'b0;
	    end
	  memwrite2:
	    begin
	       if(ccif.dwait) 
		 nextState = memwrite2; 
	       else 
		 nextState = memload1;
	       next_flush_frame = 0;
	       next_flush_block = 0;
	       bsel = membsel;
	       wen = 1'b0;
	       count_en = 1'b0;
	       ccif.dREN = 1'b0;
	       ccif.dWEN = 1'b1;
	       ccif.dstore = frame[addr.idx].block[membsel].data[1];
	       ccif.daddr = {frame[addr.idx].block[membsel].tag,addr.idx,1'b1,addr.bytoff};
	       dcif.flushed = 1'b0;
	       dcif.dmemload = 32'hbad1bad1;
	       dcif.dhit = 1'b0;
	    end
	  memload1:
	    begin
	       if(ccif.dwait) 
		 nextState = memload1; 
	       else 
		 nextState = memload2;
	       next_flush_frame = 0;
	       next_flush_block = 0;
	       bsel = membsel;
	       wen = 1'b1;
	       count_en = 1'b0;
	       ccif.dREN = 1'b1;
	       ccif.dWEN = 1'b0;
	       ccif.dstore = 32'hbad1bad1;
	       ccif.daddr = {addr.tag,addr.idx,~addr.blkoff,addr.bytoff};
	       dcif.flushed = 1'b0;
	       dcif.dmemload = 32'hbad1bad1;
	       dcif.dhit = 1'b0;
	    end
	  memload2:
	    begin
	       if(ccif.dwait) 
		 nextState = memload2; 
	       else 
		 nextState = idle;
	       next_flush_frame = 0;
	       next_flush_block = 0;
	       bsel = membsel;
	       wen = 1'b1;
	       count_en = 1'b0;
	       ccif.dREN = 1'b1;
	       ccif.dWEN = 1'b0;
	       ccif.dstore = 32'hbad1bad1;
	       ccif.daddr = {addr.tag,addr.idx,addr.blkoff,addr.bytoff};
	       dcif.flushed = 1'b0;
	       dcif.dmemload = ccif.dload;
	       dcif.dhit = ~(ccif.dwait);	       
	    end // case: memload2
	  flush1:
	    begin
	       // If write going on, stay in current state
	       if(frame[flush_frame].block[flush_block].valid &&
		  frame[flush_frame].block[flush_block].modified)
		 begin
		    if(ccif.dwait)
		      nextState = flush1;
		    else
		      nextState = flush2;
		    
		    next_flush_frame = flush_frame;
		    next_flush_block = flush_block;
		    bsel = 1'b0;
		    wen = 1'b0;
		    count_en = 1'b0;
		    ccif.dREN = 1'b0;
		    ccif.dWEN = 1'b1;
		    ccif.dstore = frame[flush_frame].block[flush_block].data[0];
		    ccif.daddr = {frame[flush_frame].block[flush_block].tag,flush_frame,3'b000};
		    dcif.flushed = 1'b0;
		    dcif.dmemload = 32'hbad1bad1;
		    dcif.dhit = 1'b0;
		 end // if (frame[flush_frame].block[flush_block].valid &&...
	       else
		 begin
		    if(!(flush_frame ^ 3'b111) & !(flush_block ^ 1'b1))
		      nextState = halt;
		    else
		      nextState = flush1;
		    next_flush_frame = (flush_block) ? flush_frame + 3'd1 : flush_frame;
		    next_flush_block = flush_block ^ 1'b1;
		    bsel = 1'b0;
		    wen = 1'b0;
		    count_en = 1'b0;
		    ccif.dREN = 1'b0;
		    ccif.dWEN = 1'b0;
		    ccif.dstore = 32'hbad1bad1;
		    ccif.daddr = 0;
		    dcif.flushed = 1'b0;
		    dcif.dmemload = 32'hbad1bad1;
		    dcif.dhit = 1'b0;
		 end
	    end // case: flush1
	  flush2:
	    begin
	       if(ccif.dwait) // Wait for write to be done
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

	       bsel = 1'b0;
	       wen = 1'b0;
	       count_en = 1'b0;
	       ccif.dREN = 1'b0;
	       ccif.dWEN = 1'b1;
	       ccif.dstore = frame[flush_frame].block[flush_block].data[1];
	       ccif.daddr = {frame[flush_frame].block[flush_block].tag,flush_frame,3'b100};
	       dcif.flushed = 1'b0;
	       dcif.dmemload = 32'hbad1bad1;
	       dcif.dhit = 1'b0;
	    end // case: flush2
	  halt:
	    begin
	       if(ccif.dwait)
		 nextState = halt;
	       else
		 nextState = halt1;
	       next_flush_frame = 0;
	       next_flush_block = 0;
	       bsel = 1'b0;
	       wen = 1'b0;
	       count_en = 1'b0;
	       ccif.dREN = 0;
	       ccif.dWEN = 1;
	       ccif.dstore = count;
	       ccif.daddr = 32'h3100;
	       dcif.flushed = 1'b0;
	       dcif.dmemload = 32'hdeadbeef;
	       dcif.dhit = 1'b0;
	    end // case: halt
	  halt1:
	    begin
	       nextState = halt1;
	       next_flush_frame = 0;
	       next_flush_block = 0;
	       bsel = 1'b0;
	       wen = 1'b0;
	       count_en = 1'b0;
	       ccif.dREN = 0;
	       ccif.dWEN = 0;
	       ccif.dstore = 32'hdeadbeef;
	       ccif.daddr = 0;
	       dcif.flushed = 1'b1;
	       dcif.dmemload = 32'hdeadbeef;
	       dcif.dhit = 1'b1;
	    end
	endcase // case (currentState)
     end // always_comb
   
   
endmodule // dcache
