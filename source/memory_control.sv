/*
 Sheik Dawood
 dawood0@purdue.edu

 Everett Berry
 epberry@purdue.edu
 
 this block is the coherence protocol
 and artibtration for ram
 */

// interface include
`include "cache_control_if.vh"

// memory types
`include "cpu_types_pkg.vh"

module memory_control (
		       input logic CLK, nRST,
		       cache_control_if.cc ccif
		       );

   import cpu_types_pkg::*;

   typedef enum logic [2:0] {
			     IDLE,
			     SNOOP,
			     MEM,
			     MEMR1,
			     MEMR2
			     }ccstate_t;

   ccstate_t currentState, nextState;

   word_t       snoopAddr, snoopAddr_next;
   logic 	inv, inv_next;	
   logic        memWrite, memWrite_next;	
   logic 	rCache, sCache;
   logic 	rCache_next;
   logic        memR;	

   always_comb
     sCache = ~rCache;

   always_ff @ (posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  begin
	     currentState <= IDLE;
	     rCache <= 0;
	     memWrite <= 0;
	     inv <= 0;
	     snoopAddr <= 0;
	  end
	else
	  begin
	     currentState <= nextState;
	     rCache <= rCache_next;
	     memWrite <= memWrite_next;
	     inv <= inv_next;
	     snoopAddr <= snoopAddr_next;
	  end
     end // always_ff @
   
   //Next State Logic
   always_comb
     begin
	case(currentState)
	  IDLE:
	    begin
	       //Check Cache 0 for data request
	       if(ccif.dREN[0])
		 begin
		    nextState = SNOOP;
		    rCache_next = 1'b0;
		    memWrite_next = memWrite;
		    inv_next = ccif.ccwrite[0];
		    snoopAddr_next = ccif.daddr[0];
		 end
	       //Check Cache 1 for data request
	       else if(ccif.dREN[1])
		 begin
		    nextState = SNOOP;
		    rCache_next = 1'b1;
		    memWrite_next = memWrite;
		    inv_next = ccif.ccwrite[1];
		    snoopAddr_next = ccif.daddr[1];
		 end
	       else if(ccif.dWEN[0] | ccif.iREN[0])
		 begin
		    nextState = MEM;
		    rCache_next = 0;
		    memWrite_next = ccif.dWEN[0];
		    inv_next = inv;
		    snoopAddr_next = snoopAddr;
		 end
	       else if(ccif.dWEN[1] | ccif.iREN[1])
		 begin
		    nextState = MEM;
		    rCache_next = 1;
		    memWrite_next = ccif.dWEN[1];
		    inv_next = inv;
		    snoopAddr_next = snoopAddr;
		 end
	       else
		 begin
		    nextState = IDLE;
	       	    rCache_next = rCache;
		    memWrite_next = memWrite;
		    inv_next = inv;
		    snoopAddr_next = snoopAddr;
		 end

	    end
	  SNOOP:
	    begin
	       if(ccif.cctrans[sCache])
		 nextState = SNOOP;
	       else if(memR)
		 nextState = MEMR1;
	       else
		 nextState = IDLE;
	       rCache_next = rCache;
	       memWrite_next = memWrite;
	       inv_next = inv;
	       snoopAddr_next = snoopAddr;
	    end
	  MEM:
	    begin
	       if(ccif.ramstate == ACCESS && ~memWrite)
		 nextState = IDLE;
	       else
		 nextState = MEM;
	       rCache_next = rCache;
	       memWrite_next = 1'b0;
	       inv_next = inv;
	       snoopAddr_next = snoopAddr;
	    end
	  MEMR1:
	    begin
	       if(ccif.ramstate == ACCESS || ccif.ramstate == FREE)
		 nextState = MEMR2;
	       else
		 nextState = MEMR1;
	       rCache_next = rCache;
	       memWrite_next = memWrite;
	       inv_next = inv;
	       snoopAddr_next = snoopAddr;
	    end
	  MEMR2:
	    begin
	       if(ccif.ramstate == ACCESS || ccif.ramstate == FREE)
		 nextState = IDLE;
	       else
		 nextState = MEMR2;
	       rCache_next = rCache;
	       memWrite_next = memWrite;
	       inv_next = inv;
	       snoopAddr_next = snoopAddr;
	    end // case: MEMR2
	  default:
	    begin
	       nextState = IDLE;
	       rCache_next = rCache;
	       memWrite_next = memWrite;
	       inv_next = inv;
	       snoopAddr_next = snoopAddr;
	    end
	endcase // case (currentState)
     end

   //Output Logic
   always_comb
     begin
	ccif.dwait = 2'b11;
	ccif.iwait = 2'b11;
	ccif.ccwait = 2'b00;
	ccif.ccinv = 2'b00;
	ccif.dload = {32'hbad1bad1,32'hbad1bad1};
	ccif.ccsnoopaddr = {snoopAddr, snoopAddr};
	
	case(currentState)
	  MEM:
	    begin
	       memR = 1'b0;
	       ccif.ramWEN = memWrite;
	       ccif.ramREN = ~memWrite;
	       
	       ccif.iload = {ccif.ramload, ccif.ramload};
	       ccif.dload = 0;
	       ccif.ramstore = ccif.dstore[rCache];

	       if(memWrite)
		 ccif.ramaddr = ccif.daddr[rCache];
	       else
		 ccif.ramaddr = ccif.iaddr[rCache];

	       ccif.dwait[sCache] = ccif.dREN[sCache] | ccif.dWEN[sCache];
	       ccif.iwait[sCache] = ccif.iREN[sCache];
	       
	       casez (ccif.ramstate)
		 FREE:
		   begin
		      if(memWrite)
			begin
			   ccif.dwait[rCache] = 1'b0;
			   ccif.iwait[rCache] = ccif.iREN[rCache];
			end
		      else
			begin
			   ccif.dwait[rCache] = ccif.dREN[rCache] | ccif.dWEN[rCache];
			   ccif.iwait[rCache] = 1'b0;
			end
		   end
		 ACCESS:
		   begin
		      if(memWrite)
			begin
			   ccif.dwait[rCache] = 1'b0;
			   ccif.iwait[rCache] = ccif.iREN[rCache];
			end
		      else
			begin
			   ccif.dwait[rCache] = ccif.dREN[rCache] | ccif.dWEN[rCache];
			   ccif.iwait[rCache] = 1'b0;
			end
		   end
		 default:
		   begin
		      if(memWrite)
			begin
			   ccif.dwait[rCache] = 1'b1;
			   ccif.iwait[rCache] = ccif.iREN[rCache];
			end
		      else
			begin
			   ccif.dwait[rCache] = ccif.dREN[rCache] | ccif.dWEN[rCache];
			   ccif.iwait[rCache] = 1'b1;
			end
		   end
	       endcase

	       ccif.ccwait = 0;
	       ccif.ccinv = 0;
	    end
	  MEMR1, MEMR2:
	    begin
	       memR = 1'b0;
	       ccif.ramWEN = 0;
	       ccif.ramREN = ccif.dREN[rCache];
	       
	       ccif.iload = {ccif.ramload, ccif.ramload};
	       ccif.dload = {ccif.ramload, ccif.ramload};
	       ccif.ramstore = 32'hbad1bad1;
	       
	       ccif.ramaddr = ccif.daddr[rCache];

	       ccif.dwait[sCache] = ccif.dREN[sCache] | ccif.dWEN[sCache];
	       ccif.iwait = ccif.iREN;
	       
	       if(ccif.ramstate == FREE || ccif.ramstate == ACCESS)
		 ccif.dwait[rCache] = 1'b0;
	       else
		 ccif.dwait[rCache] = 1'b1;
	       
	       ccif.ccwait = 0;
	       ccif.ccinv = 0;
	    end
	  SNOOP:
	    begin
	       memR = ~ccif.dWEN[sCache];
	       ccif.ramWEN = ccif.dWEN[sCache];
	       ccif.ramREN = 1'b0;

	       ccif.iload = {ccif.ramload, ccif.ramload};
	       ccif.dload[sCache] = ccif.ramload;
	       ccif.dload[rCache] = ccif.dWEN[sCache] ? ccif.dstore[sCache] : ccif.ramload;
	       ccif.ramstore = ccif.dstore[sCache];

	       ccif.ramaddr = ccif.daddr[sCache];

	       ccif.iwait = ccif.iREN;
	       
	       if(ccif.ramstate == ACCESS || ccif.ramstate == FREE)
		 begin
		    ccif.dwait[rCache] = ~ccif.dWEN[sCache];
		    ccif.dwait[sCache] = 1'b0;
		 end
	       else
		 ccif.dwait = 2'b11;

	       ccif.ccwait[sCache] = 1'b1;
	       ccif.ccwait[rCache] = 1'b0;
	       ccif.ccinv[rCache] = 1'b0;
	       ccif.ccinv[sCache] = inv;
	    end // case: SNOOP
	  default: // & IDLE
	    begin
	       memR = 0;
	       ccif.ramWEN = 0;
	       ccif.ramREN = 0;
	       
	       ccif.iload = {32'hbad1bad1,32'hbad1bad1};
	       ccif.dload = {32'hbad1bad1,32'hbad1bad1};
	       ccif.ramstore = 32'hbad1bad1;

	       ccif.ramaddr = 0;

	       ccif.dwait[0] = ccif.dREN[0] | ccif.dWEN[0];
	       ccif.iwait[0] = ccif.iREN[0];
	       ccif.dwait[1] = ccif.dREN[1] | ccif.dWEN[1];
	       ccif.iwait[1] = ccif.iREN[1];

	       ccif.ccwait = 0;
	       ccif.ccinv = 0;
	    end
	endcase // case (currentState)
     end

endmodule // memory_control
