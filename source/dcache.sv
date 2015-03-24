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
	       datapath_cache_if.dcache dcif,
	       cache_control_if.dcache ccif
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
   typedef enum 	   logic[2:0]	   
			   { idle,
			     memwrite1,
			     memwrite2,
			     memload1,
			     memload2
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
   logic [2:0] 		   flush_block;
   logic [2:0] 		   next_flush_block;		   
   

   always_ff @ (posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  begin
	     currentState <= idle;
	     frame <= '{default:'0};
	     membsel <= 0;
	     flush_frame = 0;
	     next_flush_frame = 0;
	  end
	else if(dcif.halt)
	  begin
	     if
	     currentState <= ;
	     /*
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
	     frame[7].block[1].valid <= 1'b0;*/
	  end
	else
	  begin
	     currentState <= nextState;
	     membsel <= bsel;

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
		 end
	     endcase

	     if(dcif.dhit) frame[addr.idx].leastrecent = ~bsel;
	  end // else: !if(dcif.halt)
     end

   always_comb
     begin
	addr = dcif.dmemaddr;	

	case(currentState)
	  idle: begin
	     if(dcif.halt)
	       begin
		  nextState = flush;
		  next_flush_frame = 0;
		  next_flush_block = 0;
		  bsel = 1'b0;
		  wen = 1'b1;
		  
		  ccif.dREN = 1'b0;
		  ccif.dWEN = 1'b0;
		  ccif.dstore = 32'hbad1bad1;
		  ccif.daddr = 32'b0;
		  
		  dcif.dmemload = 32'hbad1bad1;
		  dcif.dhit = 1'b1;
	       end
	     if(dcif.dmemWEN)
	       begin
		  if(!(frame[addr.idx].block[0].tag ^ addr.tag) & 
		     (frame[addr.idx].block[0].valid))
		    begin
		       nextState = idle;
		       bsel = 1'b0;
		       wen = 1'b1;

		       ccif.dREN = 1'b0;
		       ccif.dWEN = 1'b0;
		       ccif.dstore = 32'hbad1bad1;
		       ccif.daddr = 32'b0;

		       dcif.dmemload = 32'hbad1bad1;
		       dcif.dhit = 1'b1;
		      end
		    else if(!(frame[addr.idx].block[1].tag ^ addr.tag) &
			    (frame[addr.idx].block[1].valid))
		      begin
			 nextState = idle;
			 bsel = 1'b1;
			 wen = 1'b1;
			 
			 ccif.dREN = 1'b0;
			 ccif.dWEN = 1'b0;
			 ccif.dstore = 32'hbad1bad1;
			 ccif.daddr = 32'b0;
			 
			 dcif.dmemload = 32'hbad1bad1;
			 dcif.dhit = 1'b1;
		      end
		    else
		      begin
			 if(!frame[addr.idx].block[0].valid)
			   begin
			      nextState = memload1;
			      bsel = 1'b0;
			      wen = 1'b0;
			      
			      ccif.dREN = 1'b0;
			      ccif.dWEN = 1'b0;
			      ccif.dstore = 32'hbad1bad1;
			      ccif.daddr = 32'b0;
			      
			      dcif.dmemload = 32'hbad1bad1;
			      dcif.dhit = 1'b0;
			   end
			 else if(!frame[addr.idx].block[1].valid)
			   begin
			      nextState = memload1;
			      bsel = 1'b1;
			      wen = 1'b0;
			      
			      ccif.dREN = 1'b0;
			      ccif.dWEN = 1'b0;
			      ccif.dstore = 32'hbad1bad1;
			      ccif.daddr = 32'b0;
			      
			      dcif.dmemload = 32'hbad1bad1;
			      dcif.dhit = 1'b0;
			   end
			 else
			   begin
			      if(frame[addr.idx].block[frame[addr.idx].leastrecent].modified)
				begin
				   nextState = memwrite1;
				   bsel = frame[addr.idx].leastrecent;
				   wen = 1'b0;
				   
				   ccif.dREN = 1'b0;
				   ccif.dWEN = 1'b0;
				   ccif.dstore = 32'hbad1bad1;
				   ccif.daddr = 32'b0;
				   
				   dcif.dmemload = 32'hbad1bad1;
				   dcif.dhit = 1'b0;
				end
			      else
				begin
				   nextState = memload1;
				   bsel = frame[addr.idx].leastrecent;
				   wen = 1'b0;
				   
				   ccif.dREN = 1'b0;
				   ccif.dWEN = 1'b0;
				   ccif.dstore = 32'hbad1bad1;
				   ccif.daddr = 32'b0;
				   
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
			 bsel = 1'b0;
			 wen = 1'b0;
			 
			 ccif.dREN = 1'b0;
			 ccif.dWEN = 1'b0;
			 ccif.dstore = 32'hbad1bad1;
			 ccif.daddr = 32'b0;
			 
			 dcif.dmemload = frame[addr.idx].block[0].data[addr.blkoff];
			 dcif.dhit = 1'b1;
		      end
		    else if(!(frame[addr.idx].block[1].tag ^ addr.tag) &
			    (frame[addr.idx].block[1].valid))
		      begin
			 nextState = idle;
			 bsel = 1'b0;
			 wen = 1'b0;
			 
			 ccif.dREN = 1'b0;
			 ccif.dWEN = 1'b0;
			 ccif.dstore = 32'hbad1bad1;
			 ccif.daddr = 32'b0;
			 
			 dcif.dmemload = frame[addr.idx].block[1].data[addr.blkoff];
			 dcif.dhit = 1'b1;
		      end
		    else
		      begin
			 if(!frame[addr.idx].block[0].valid)
			   begin
			      nextState = memload1;
			      bsel = 1'b0;
			      wen = 1'b0;
			      
			      ccif.dREN = 1'b0;
			      ccif.dWEN = 1'b0;
			      ccif.dstore = 32'hbad1bad1;
			      ccif.daddr = 32'b0;
			      
			      dcif.dmemload = 32'hbad1bad1;
			      dcif.dhit = 1'b0;
			   end
			 else if(!frame[addr.idx].block[1].valid)
			   begin
			      nextState = memload1;
			      bsel = 1'b1;
			      wen = 1'b0;
			      
			      ccif.dREN = 1'b0;
			      ccif.dWEN = 1'b0;
			      ccif.dstore = 32'hbad1bad1;
			      ccif.daddr = 32'b0;
			      
			      dcif.dmemload = 32'hbad1bad1;
			      dcif.dhit = 1'b0;
			   end
			 else
			   begin
			      if(frame[addr.idx].block[frame[addr.idx].leastrecent].modified)
				begin
				   nextState = memwrite1;
				   bsel = frame[addr.idx].leastrecent;
				   wen = 1'b0;
				   
				   ccif.dREN = 1'b0;
				   ccif.dWEN = 1'b0;
				   ccif.dstore = 32'hbad1bad1;
				   ccif.daddr = 32'b0;
				   
				   dcif.dmemload = 32'hbad1bad1;
				   dcif.dhit = 1'b0;
				end
			      else
				begin
				   nextState = memload1;
				   bsel = frame[addr.idx].leastrecent;
				   wen = 1'b0;
				   
				   ccif.dREN = 1'b0;
				   ccif.dWEN = 1'b0;
				   ccif.dstore = 32'hbad1bad1;
				   ccif.daddr = 32'b0;
				   
				   dcif.dmemload = 32'hbad1bad1;
				   dcif.dhit = 1'b0;
				end
			   end
		      end // else: !if(!(frame[addr.idx].block[1].tag ^ addr.tag) &...
		 end // if (dcif.dmemREN)
	       else
		 begin
		    nextState = idle;
		    bsel = 1'b0;
		    wen = 1'b0;
		    
		    ccif.dREN = 1'b0;
		    ccif.dWEN = 1'b0;
		    ccif.dstore = 32'hbad1bad1;
		    ccif.daddr = 32'b0;
		    
		    dcif.dmemload = 32'hbad1bad1;
		    dcif.dhit = 1'b0;
		 end
	    end // case: idle
	  memwrite1:
	    begin
	       if(ccif.dwait) 
		 nextState = memwrite1;
	       else 
		 nextState = memwrite2;

	       bsel = membsel;
	       wen = 1'b0;
	       
	       ccif.dREN = 1'b0;
	       ccif.dWEN = 1'b1;
	       ccif.dstore = frame[addr.idx].block[membsel].data[0];
	       ccif.daddr = {frame[addr.idx].block[membsel].tag,addr.idx,1'b0,addr.bytoff};
	       
	       dcif.dmemload = 32'hbad1bad1;
	       dcif.dhit = 1'b0;
	    end
	  memwrite2:
	    begin
	       if(ccif.dwait) 
		 nextState = memwrite2; 
	       else 
		 nextState = memload1;

	       bsel = membsel;
	       wen = 1'b0;
	       
	       ccif.dREN = 1'b0;
	       ccif.dWEN = 1'b1;
	       ccif.dstore = frame[addr.idx].block[membsel].data[1];
	       ccif.daddr = {frame[addr.idx].block[membsel].tag,addr.idx,1'b1,addr.bytoff};
	       
	       dcif.dmemload = 32'hbad1bad1;
	       dcif.dhit = 1'b0;
	    end
	  memload1:
	    begin
	       if(ccif.dwait) 
		 nextState = memload1; 
	       else 
		 nextState = memload2;
	       
	       bsel = membsel;
	       wen = 1'b1;
	       
	       ccif.dREN = 1'b1;
	       ccif.dWEN = 1'b0;
	       ccif.dstore = 32'hbad1bad1;
	       ccif.daddr = {addr.tag,addr.idx,~addr.blkoff,addr.bytoff};
	       
	       dcif.dmemload = 32'hbad1bad1;
	       dcif.dhit = 1'b0;
	    end
	  memload2:
	    begin
	       if(ccif.dwait) 
		 nextState = memload2; 
	       else 
		 nextState = idle;

	       bsel = membsel;
	       wen = 1'b1;
	       
	       ccif.dREN = 1'b1;
	       ccif.dWEN = 1'b0;
	       ccif.dstore = 32'hbad1bad1;
	       ccif.daddr = {addr.tag,addr.idx,addr.blkoff,addr.bytoff};
	       
	       dcif.dmemload = ccif.dload;
	       dcif.dhit = ~(ccif.dwait);	       
	    end
	endcase // case (currentState)
	
	  
     end
   
   
endmodule // dcache
