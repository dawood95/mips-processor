/*
 Sheik Dawood
 dawood0@purdue.edu
 
 Everett Berry
 epberry@purdue.edu
 
 Data Cache
 
 TODO :
 S -> M
*/

`include "datapath_cache_if.vh"
`include "cache_control_if.vh"
`include "cpu_types_pkg.vh"

module dcache (
	       input logic CLK, nRST,
	       datapath_cache_if.dcache dcif,
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
			     halt
			     } dstate_t;
   
   dstate_t 		   currentState, nextState;		   
   frame_t                 frame[7:0];
   dcachef_t               addr, snoopaddr;

   logic 		   frameWEN;
   logic 		   block, nextBlock;
   logic [2:0] 		   flushFrame, nextFlushFrame;
   
   dstate_t                snoopReturnState, nextSnoopReturnState;
   logic 		   snoopReturnBlock, nextSnoopReturnBlock;
   
   // State Machine for DCache
   always_ff @ (posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  begin
	     currentState <= idle;
	     block <= 1'b0;
	     flushFrame <= 1'b0;
	     snoopReturnState <= idle;
	     snoopReturnBlock <= 1'b0;
	  end
	else
	  begin
	     currentState <= nextState;
	     block <= nextBlock;
	     flushFrame <= nextFlushFrame;
	     snoopReturnState <= nextSnoopReturnState;
	     snoopReturnBlock <= nextSnoopReturnBlock;
	  end
     end

   // Dcache State Machine Next State Logic
   always_comb
     begin
	// Default Next State 
	nextState = idle;
	nextBlock = block;
	nextFlushFrame = flushFrame;
	nextSnoopReturnState = snoopReturnState;
	nextSnoopReturnBlock = snoopReturnBlock;
	
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
			 nextBlock = 1'b0;
		      end
		    else if(!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) &
			    frame[snoopaddr.idx].block[1].valid &
			    frame[snoopaddr.idx].block[1].modified)
		      begin
			 nextState = ccwrite1;
			 nextBlock = 1'b1;
		      end
		    else
		      begin
			 nextState = idle;
		      end
		 end // if (ccif.ccwait[CPUID])
	       else if(dcif.halt)
		 begin
		    nextState = flush1;
		    nextFlushFrame = 1'b0;
		    nextBlock = 1'b0;
		 end
	       else if(dcif.dmemWEN)
		 begin
		    if(!(frame[addr.idx].block[0].tag ^ addr.tag))
		      begin
			 if(frame[addr.idx].block[0].valid &
			    frame[addr.idx].block[0].modified)
			   begin
			      nextState = idle;
			   end
			 else
			   begin
			      nextState = memload1;
			   end
			 nextBlock = 1'b0;
		      end // if (!(frame[addr.idx].block[0].tag ^ addr.tag))
		    else if(!(frame[addr.idx].block[1].tag ^ addr.tag))
		      begin
			 if(frame[addr.idx].block[1].valid &
			    frame[addr.idx].block[1].modified)
			   begin
			      nextState = idle;
			   end
			 else
			   begin
			      nextState = memload1;
			   end
			 nextBlock = 1'b1;
		      end // if (!(frame[addr.idx].block[1].tag ^ addr.tag))
		    else if(!frame[addr.idx].block[~frame[addr.idx].leastrecent].valid)
		      begin
			 nextState = memload1;
			 nextBlock = ~frame[addr.idx].leastrecent;
		      end
		    else
		      begin
			 nextBlock = frame[addr.idx].leastrecent;
			 if(frame[addr.idx].block[frame[addr.idx].leastrecent].modified)
			   begin
			      nextState = memwrite1;
			   end
			 else
			   begin
			      nextState = memload1;
			   end
		      end // else: !if(!frame[addr.idx].block[~frame[addr.idx].leastrecent].valid)
		 end // if (dcif.dmemWEN)
	       else if(dcif.dmemREN)
		 begin
		    if(!(frame[addr.idx].block[0].tag ^ addr.tag))
		      begin
			 nextState = frame[addr.idx].block[0].valid ? idle : memload1;
			 nextBlock = 1'b0;
		      end // if (!(frame[addr.idx].block[0].tag ^ addr.tag))
		    else if(!(frame[addr.idx].block[1].tag ^ addr.tag))
		      begin
			 nextState = frame[addr.idx].block[1].valid ? idle : memload1;
			 nextBlock = 1'b1;
		      end // if (!(frame[addr.idx].block[1].tag ^ addr.tag))
		    else if(!frame[addr.idx].block[~frame[addr.idx].leastrecent].valid)
		      begin
			 nextState = memload1;
			 nextBlock = ~frame[addr.idx].leastrecent;
		      end
		    else
		      begin
			 nextBlock = frame[addr.idx].leastrecent;
			 nextState = frame[addr.idx].block[frame[addr.idx].leastrecent].modified ? 
				     memwrite1 : memload1;
		      end // else: !if(!frame[addr.idx].block[~frame[addr.idx].leastrecent].valid)
		 end // if (dcif.dmemREN)
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
			 nextBlock = 1'b0;
		      end
		    else if(!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) &
			    frame[snoopaddr.idx].block[1].valid &
			    frame[snoopaddr.idx].block[1].modified)
		      begin
			 nextState = ccwrite1;
			 nextBlock = 1'b1;
		      end
		    else
		      begin
			 nextState = memwrite1;
		      end
		 end // if (ccif.ccwait[CPUID])
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
			 nextBlock = 1'b0;
		      end
		    else if(!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) &
			    frame[snoopaddr.idx].block[1].valid &
			    frame[snoopaddr.idx].block[1].modified)
		      begin
			 nextState = ccwrite1;
			 nextBlock = 1'b1;
		      end
		    else
		      begin
			 nextState = memload1;
		      end
		 end // if (ccif.ccwait[CPUID])
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
	    end

	  flush1:
	    begin
	       if(ccif.ccwait[CPUID])
		 begin
		    if(!(frame[snoopaddr.idx].block[0].tag ^ snoopaddr.tag) &
		       frame[snoopaddr.idx].block[0].valid &
		       frame[snoopaddr.idx].block[0].modified)
		      begin
			 nextState = ccwrite1;
			 nextBlock = 1'b0;
		      end
		    else if(!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) &
			    frame[snoopaddr.idx].block[1].valid &
			    frame[snoopaddr.idx].block[1].modified)
		      begin
			 nextState = ccwrite1;
			 nextBlock = 1'b1;
		      end
		    else
		      begin
			 nextState = flush1;
		      end
		 end // if (ccif.ccwait[CPUID])
	       else if(frame[flushFrame].block[block].valid & frame[flushFrame].block[block].modified)
		 begin
		    if(ccif.dwait[CPUID])
		      nextState = flush1;
		    else
		      nextState = flush2;
		 end
	       else
		 begin
		    if(!(flushFrame ^ 3'b111) & !(block ^ 1'b1))
		      nextState = halt;
		    else
		      nextState = flush1;
		    nextFlushFrame = (block) ? flushFrame + 3'd1 : flushFrame;
		    nextBlock = block ^ 1'b1;
		 end
	    end

	  flush2:
	    begin
	       if(ccif.dwait[CPUID])
		 nextState = flush2;
	       else if(!(flushFrame ^ 3'b111) & !(block ^ 1'b1))
		 nextState = halt;
	       else
		 begin
		    nextState = flush1;
		    nextFlushFrame = (block) ? flushFrame + 3'd1 : flushFrame;
		    nextBlock = block ^ 1'b1;    
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
		    nextState = snoopReturnState;
		    nextBlock = snoopReturnBlock;
		 end
	    end

	  halt:
	    begin
	       nextState = halt;
	    end

	endcase // case (currentState)

	if(nextState == ccwrite1)
	  begin
	     nextSnoopReturnState = currentState;
	     nextSnoopReturnBlock = block;
	  end

     end // always_comb
   
   
   // Dcache State Machine Output Logic

   always_comb
     begin

	addr = dcif.dmemaddr;
	snoopaddr = ccif.ccsnoopaddr[CPUID];
	
	frameWEN = 1'b0;

	ccif.dREN[CPUID] = 1'b0;
	ccif.dWEN[CPUID] = 1'b0;
	ccif.daddr[CPUID] = 32'd0;
	ccif.dstore[CPUID] = 32'hbad1bad1;
	ccif.ccwrite[CPUID] = 1'b0;
	ccif.cctrans[CPUID] = 1'b0;

	dcif.dhit = 1'b0;
	dcif.dmemload = 1'b0;
	dcif.flushed = 1'b0;

	case(currentState)

	  idle:
	    begin
	       if(ccif.ccwait[CPUID])
		 begin
		    if((!(frame[snoopaddr.idx].block[0].tag ^ snoopaddr.tag) &
		       frame[snoopaddr.idx].block[0].valid &
		       frame[snoopaddr.idx].block[0].modified) |
		       (!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) &
			frame[snoopaddr.idx].block[1].valid &
			frame[snoopaddr.idx].block[1].modified))
		      ccif.cctrans[CPUID] = 1'b1;
		 end // if (ccif.ccwait[CPUID])
	       else if(dcif.dmemWEN)
		 begin
		    if((!(frame[addr.idx].block[0].tag ^ addr.tag) &
			frame[addr.idx].block[0].valid &
			frame[addr.idx].block[0].modified) |
		       (!(frame[addr.idx].block[1].tag ^ addr.tag) &
			frame[addr.idx].block[1].valid &
			frame[addr.idx].block[1].modified))
		      begin
			 frameWEN = 1'b1;
			 dcif.dhit = 1'b1;
		      end
		 end
	       else if(dcif.dmemREN)
		 begin
		    if(!(frame[addr.idx].block[0].tag ^ addr.tag) & 
		       (frame[addr.idx].block[0].valid))
		      begin
			 dcif.dmemload = frame[addr.idx].block[0].data[addr.blkoff];
			 dcif.dhit = 1'b1;
		      end
		    else if(!(frame[addr.idx].block[1].tag ^ addr.tag) & 
			    (frame[addr.idx].block[1].valid))
		      begin
			 dcif.dmemload = frame[addr.idx].block[1].data[addr.blkoff];
			 dcif.dhit = 1'b1;
		      end
		 end // if (dcif.dmemREN)
	       else
		 dcif.dhit = 1'b1;
	    end // case: idle

	  memwrite1:
	    begin
	       if(ccif.ccwait[CPUID])
		 begin
		    if((!(frame[snoopaddr.idx].block[0].tag ^ snoopaddr.tag) &
			frame[snoopaddr.idx].block[0].valid &
			frame[snoopaddr.idx].block[0].modified) |
		       (!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) &
			frame[snoopaddr.idx].block[1].valid &
			frame[snoopaddr.idx].block[1].modified))
		      ccif.cctrans[CPUID] = 1'b1;
		 end // if (ccif.ccwait[CPUID])

	       ccif.dWEN[CPUID] = 1'b1;
	       ccif.dstore[CPUID] = frame[addr.idx].block[block].data[0];
	       ccif.daddr[CPUID] = {frame[addr.idx].block[block].tag, addr.idx, 1'b0, addr.bytoff};
	    end // case: memwrite1
	  
	  memwrite2:
	    begin
	       ccif.dWEN[CPUID] = 1'b1;
	       ccif.dstore[CPUID] = frame[addr.idx].block[block].data[1];
	       ccif.daddr[CPUID] = {frame[addr.idx].block[block].tag, addr.idx, 1'b1, addr.bytoff};
	    end
	  
	  memload1:
	    begin       
	       if(ccif.ccwait[CPUID])
		 begin
		    if((!(frame[snoopaddr.idx].block[0].tag ^ snoopaddr.tag) &
			frame[snoopaddr.idx].block[0].valid &
			frame[snoopaddr.idx].block[0].modified) |
		       (!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) &
			frame[snoopaddr.idx].block[1].valid &
			frame[snoopaddr.idx].block[1].modified))
		      ccif.cctrans[CPUID] = 1'b1;
		 end // if (ccif.ccwait[CPUID])

	       ccif.ccwrite[CPUID] = dcif.dmemWEN;
	       ccif.dREN[CPUID] = 1'b1;
	       ccif.daddr[CPUID] = {addr.tag, addr.idx, ~addr.blkoff, addr.bytoff};
	    end

	  memload2:
	    begin
	       ccif.ccwrite[CPUID] = dcif.dmemWEN;
	       ccif.dREN[CPUID] = 1'b1;
	       ccif.daddr[CPUID] = {addr.tag, addr.idx, addr.blkoff, addr.bytoff};
	       dcif.dmemload = ccif.dload[CPUID];
	       dcif.dhit = ~(ccif.dwait[CPUID]);
	    end

	  flush1:
	    begin       
	       if(ccif.ccwait[CPUID])
		 begin
		    if((!(frame[snoopaddr.idx].block[0].tag ^ snoopaddr.tag) &
			frame[snoopaddr.idx].block[0].valid &
			frame[snoopaddr.idx].block[0].modified) |
		       (!(frame[snoopaddr.idx].block[1].tag ^ snoopaddr.tag) &
			frame[snoopaddr.idx].block[1].valid &
			frame[snoopaddr.idx].block[1].modified))
		      ccif.cctrans[CPUID] = 1'b1;
		 end // if (ccif.ccwait[CPUID])
	       
	       if(frame[flushFrame].block[block].valid &&
		  frame[flushFrame].block[block].modified)
		 begin
		    ccif.dWEN[CPUID] = 1'b1;
		    ccif.dstore[CPUID] = frame[flushFrame].block[block].data[0];
		    ccif.daddr[CPUID] = {frame[flushFrame].block[block].tag, flushFrame, 3'd0};
		 end
	    end

	  flush2:
	    begin
	       ccif.dWEN[CPUID] = 1'b1;
	       ccif.dstore[CPUID] = frame[flushFrame].block[block].data[1];
	       ccif.daddr[CPUID] = {frame[flushFrame].block[block].tag, flushFrame, 3'd4};
	    end
	  
	  ccwrite1:
	    begin
	       ccif.ccwrite[CPUID] = 1'b1;
	       ccif.dWEN[CPUID] = 1'b1;
	       ccif.cctrans[CPUID] = 1'b1;
	       ccif.dstore[CPUID] = frame[snoopaddr.idx].block[block].data[snoopaddr.blkoff];
	       ccif.daddr[CPUID] = {snoopaddr.tag, snoopaddr.idx, snoopaddr.blkoff, snoopaddr.bytoff};
	    end
	  ccwrite2:
	    begin
	       ccif.ccwrite[CPUID] = 1'b1;
	       ccif.dWEN[CPUID] = 1'b1;//ccif.dwait[CPUID];
	       ccif.cctrans[CPUID] = ccif.dwait[CPUID];//1'b1;
	       ccif.dstore[CPUID] = frame[snoopaddr.idx].block[block].data[~snoopaddr.blkoff];
	       ccif.daddr[CPUID] = {snoopaddr.tag, snoopaddr.idx, ~snoopaddr.blkoff, snoopaddr.bytoff};
	    end
	  halt:
	    begin
	       dcif.dhit = 1'b1;
	       dcif.flushed = 1'b1;
	    end
	endcase // case (currentState)
	
     end

   // Frame Register
   always_ff @ (posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  frame <= '{default:'0};
	else
	  begin
	     case(currentState)
	       
	       idle:
		 begin
		    if(frameWEN)
		      begin
			 frame[addr.idx].block[nextBlock].data[addr.blkoff] <= dcif.dmemstore;
			 frame[addr.idx].block[nextBlock].modified <= 1'b1;
		      end
		    if(ccif.ccwait[CPUID] & ccif.ccinv[CPUID])
		      frame[snoopaddr.idx].block[nextBlock].valid <= 1'b0;
		 end
	       
	       memload1:
		 begin
		    frame[addr.idx].block[block].data[~addr.blkoff] <= ccif.dload[CPUID];
		    frame[addr.idx].block[block].tag <= addr.tag;
		    frame[addr.idx].block[block].modified <= 1'b0;
		    frame[addr.idx].block[block].valid <= 1'b1;
		    if(ccif.ccwait[CPUID] & ccif.ccinv[CPUID] &
		       !(frame[snoopaddr.idx].block[nextBlock].tag ^ snoopaddr.tag))
		      frame[snoopaddr.idx].block[nextBlock].valid <= 1'b0;
		 end
	       
	       memload2:
		 begin
		    if(dcif.dmemREN)
		      begin
			 frame[addr.idx].block[block].data[addr.blkoff] <= ccif.dload[CPUID];
			 frame[addr.idx].block[block].tag <= addr.tag;
			 frame[addr.idx].block[block].modified <= 1'b0;
			 frame[addr.idx].block[block].valid <= 1'b1;
		      end
		    else
		      begin
			 frame[addr.idx].block[block].data[addr.blkoff] <= dcif.dmemstore;
			 frame[addr.idx].block[block].tag <= addr.tag;
			 frame[addr.idx].block[block].modified <= 1'b1;
			 frame[addr.idx].block[block].valid <= 1'b1;
		      end
		 end // case: memload2

	       memwrite1:
		 begin
		    if(ccif.ccwait[CPUID] & ccif.ccinv[CPUID] &
		       !(frame[snoopaddr.idx].block[nextBlock].tag ^ snoopaddr.tag))
		      frame[snoopaddr.idx].block[nextBlock].valid <= 1'b0;
		 end
	       
	       flush1:
		 begin
		    if(!(frame[flushFrame].block[block].valid &
			 frame[flushFrame].block[block].modified))
		      frame[flushFrame].block[block].valid <= 1'b0;
		    
		    if(ccif.ccwait[CPUID] & ccif.ccinv[CPUID] &
		       !(frame[snoopaddr.idx].block[nextBlock].tag ^ snoopaddr.tag))
		      frame[snoopaddr.idx].block[nextBlock].valid <= 1'b0;
		 end
	       
	       flush2:
		 begin
		    if(!ccif.dwait[CPUID])
		      frame[flushFrame].block[block].valid <= 1'b0;
		 end
	
	       ccwrite2:
		 begin
		    frame[snoopaddr.idx].block[block].modified <= 1'b0;
		    if(ccif.ccinv[CPUID])
		      frame[snoopaddr.idx].block[block].valid <= 1'b0;
		 end

	     endcase

	     if(dcif.dhit & (dcif.dmemREN | dcif.dmemWEN)) frame[addr.idx].leastrecent <= ~nextBlock;

	  end // else: !if(!nRST)
     end // always_ff @
   
endmodule // dcache

   
   
