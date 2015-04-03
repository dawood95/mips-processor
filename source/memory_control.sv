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

   typedef enum logic [1:0] {
			     IDLE,
			     MEM,
			     SNOOP
			     }ccstate_t;

   ccstate_t currentState, nextState;

   word_t       snoopAddr, snoopAddr_next;
   logic 	inv, inv_next;	
   logic        memWrite, memWrite_next;	
   logic 	rCache, sCache;
   logic 	rCache_next;
   
   always_comb
     sCache = ~rCache;

   always_ff @ (posedge CLK, negedge nRST)
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
		    rCache_next = 0;
		    memWrite_next = memWrite;
		    inv_next = ccif.ccwrite[0];
		    snoopAddr_next = ccif.daddr[0];
		 end
	       //Check Cache 1 for data request
	       else if(ccif.dREN[1])
		 begin
		    nextState = SNOOP;
		    rCache_next = 0;
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
	       else
		 nextState = IDLE;
	       rCache_next = rCache;
	       memWrite_next = memWrite;
	       inv_next = inv;
	       if(ccif.ramstate == ACCESS)
		 snoopAddr_next = {snoopAddr[31:3],~snoopAddr[2],snoopAddr[1:0]};
	       else
		 snoopAddr_next = snoopAddr;
	    end
	  MEM:
	    begin
	       if(ccif.ramstate == ACCESS)
		 nextState = IDLE;
	       else
		 nextState = MEM;
	       rCache_next = rCache;
	       memWrite_next = memWrite;
	       inv_next = inv;
	       snoopAddr_next = snoopAddr;
	    end
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
	case(currentState)

	  MEM:
	    begin
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
	       ccif.ccsnoopaddr = 32'hbad1bad1;
	    end
	  SNOOP:
	    begin
	       //dREN = 1'b1 only if M->S. Write to mem only if going from M->S
	       ccif.ramWEN = ccif.dREN[sCache] & ccif.dWEN[sCache];
	       ccif.ramREN = ~ccif.dWEN[sCache];
	       
	       ccif.iload = {32'hbad1bad1,32'hbad1bad1};
	       ccif.dload[sCache] = 32'hbad1bad1;
	       ccif.dload[rCache] = ccif.dWEN[sCache] ? ccif.dstore[sCache] : ccif.ramload;
	       ccif.ramstore = ccif.dstore[sCache];

	       ccif.ramaddr = ccif.dWEN[sCache] ? ccif.daddr[sCache] : snoopAddr;

	       ccif.iwait = ccif.iREN;

	       if(ccif.dWEN[sCache] & ~ccif.dREN[sCache]) // S
		 ccif.dwait = 2'b00;
	       else if(ccif.ramstate == ACCESS ||
		       ccif.ramstate == FREE)
		 ccif.dwait = 2'b00;
	       else
		 ccif.dwait = 2'b11;

	       ccif.ccwait[sCache] = 1'b1;
	       ccif.ccwait[rCache] = 1'b0;
	       ccif.ccinv[sCache] = inv;
	       ccif.ccsnoopaddr[rCache] = 32'hbad1bad1;
	       ccif.ccsnoopaddr[sCache] = snoopAddr;
	    end
	  default: // & IDLE
	    begin
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
	       ccif.ccsnoopaddr = 0;
	    end
	endcase // case (currentState)
     end

endmodule // memory_control
