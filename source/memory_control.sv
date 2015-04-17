/*
 Sheik Dawood
 dawood0@purdue.edu

 Everett Berry
 epberry@purdue.edu
 
 this block is the coherence protocol
 and artibtration for ram
 */

`include "cache_control_if.vh"
`include "cpu_types_pkg.vh"

module memory_control (
		       input logic CLK, nRST,
		       cache_control_if.cc ccif
		       );

   import cpu_types_pkg::*;

   typedef enum 		   logic [2:0] {
						IDLE,
						SNOOP,
						IMEMR,
						DMEMW1,
						DMEMW2,
						MEMR1,
						MEMR2
						} ccstate_t;

   ccstate_t currentState, nextState;

   logic 			   reqCache, snoopCache, nextReqCache;
   word_t                          snoopAddr, nextSnoopAddr;
   
   always_comb
     snoopCache = ~reqCache;
   

   always_ff @ (posedge CLK, negedge nRST)
     begin
	if (!nRST)
	  begin
	     currentState <= IDLE;
	     reqCache <= 0;
	     snoopAddr <= 32'd0;
	  end
	else
	  begin
	     currentState <= nextState;
	     reqCache <= nextReqCache;
	     snoopAddr <= nextSnoopAddr;
	  end
     end
   

   always_comb
     begin // nextStateLogic
	case (currentState)
	  IDLE:
	    begin
	       if (ccif.dWEN[snoopCache])
		 begin
		    nextState = DMEMW1;
		    nextReqCache = snoopCache;
		    nextSnoopAddr = 32'd0;
		 end
	       else if (ccif.dWEN[reqCache])
		 begin
		    nextState = DMEMW1;
		    nextReqCache = reqCache;
		    nextSnoopAddr = 32'd0;
		 end
	       else if (ccif.dREN[snoopCache])
		 begin
		    nextState = SNOOP;
		    nextReqCache = snoopCache;
		    nextSnoopAddr = ccif.daddr[snoopCache];
		 end
	       else if (ccif.dREN[reqCache])
		 begin
		    nextState = SNOOP;
		    nextReqCache = reqCache;
		    nextSnoopAddr = ccif.daddr[snoopCache];
		 end
	       else if (ccif.iREN[snoopCache])
		 begin
		    nextState = IMEMR;
		    nextReqCache = snoopCache;
		    nextSnoopAddr = 32'd0;
		 end
	       else if (ccif.iREN[reqCache])
		 begin
		    nextState = IMEMR;
		    nextReqCache = reqCache;
		    nextSnoopAddr = 32'd0;
		 end
	       else
		 begin
		    nextState = IDLE;
		    nextReqCache = reqCache;
		    nextSnoopAddr = 32'd0;
		 end
	    end
	  SNOOP:
	    begin
	       if (ccif.cctrans[snoopCache])
		 nextState = SNOOP;
	       else if (ccif.dWEN[snoopCache] & ccif.ccwrite[snoopCache])
		 nextState = IDLE;
	       else
		 nextState = MEMR1;
	       nextReqCache = reqCache;
	       nextSnoopAddr = snoopAddr;
	    end
	  IMEMR:
	    begin
	       if (ccif.ramstate == ACCESS)
		 nextState = IDLE;
	       else 
		 nextState = IMEMR;
	       nextReqCache = reqCache;
	       nextSnoopAddr = 32'd0;
	    end
	  DMEMW1:
	    begin
	       if (ccif.ramstate == ACCESS  )
		 nextState = DMEMW2;
	       else 
		 nextState = DMEMW1;
	       nextReqCache = reqCache;
	       nextSnoopAddr = 32'd0;
	    end
	  DMEMW2:
	    begin
	       if (ccif.ramstate == ACCESS  )
		 nextState = IDLE;
	       else 
		 nextState = DMEMW2;
	       nextReqCache = reqCache;
	       nextSnoopAddr = 32'd0;
	    end
	  MEMR1:
	    begin
	       if (ccif.ramstate == ACCESS  )
		 nextState = MEMR2;
	       else 
		 nextState = MEMR1;
	       nextReqCache = reqCache;
	       nextSnoopAddr = 32'd0;
	    end
	  MEMR2:
	    begin
	       if (ccif.ramstate == ACCESS  )
		 nextState = IDLE;
	       else 
		 nextState = MEMR2;
	       nextReqCache = reqCache;
	       nextSnoopAddr = 32'd0;
	    end
	  default:
	    begin
	       nextState = IDLE;
	       nextReqCache = reqCache;
	       nextSnoopAddr = 32'd0;
	    end
	endcase // case (currentState)
     end // always_comb
   
   //Output logic [Req Cache]
   always @ (*)
     begin

	ccif.iwait = 2'b11;
	ccif.dwait = 2'b11;
	ccif.ccwait = 2'b00;
	ccif.ccinv = 2'b00;
	ccif.dload = {32'hbad1bad1, 32'hbad1bad1};
	ccif.iload = {32'hbaad1bad, 32'hbaad1bad};
	ccif.ccsnoopaddr = {32'd0, 32'd0};
	
	case (currentState)
	  IDLE:
	    begin
	       ccif.iwait[reqCache] = 1'b1;
	       ccif.dwait[reqCache] = 1'b1;
	       ccif.iload[reqCache] = 32'd0;
	       ccif.dload[reqCache] = 32'hbad1bad1;
	       
	       ccif.ccwait[reqCache] = 1'b0;
	       ccif.ccinv[reqCache] = 1'b0;
	       ccif.ccsnoopaddr[reqCache] = 32'd0;
	    end // case: IDLE
	  SNOOP:
	    begin
	       ccif.iwait[reqCache] = 1'b1;
	       if (ccif.ramstate == ACCESS  )
		 ccif.dwait[reqCache] = ~(ccif.ccwrite[snoopCache] & ccif.dWEN[snoopCache]);
	       else
		 ccif.dwait[reqCache] = 1'b1;
	       
	       ccif.iload[reqCache] = 32'd0;
	       ccif.dload[reqCache] = ccif.dWEN[snoopCache] ? ccif.dstore[snoopCache] : 32'hbad1bad1;
	       
	       ccif.ccwait[reqCache] = 1'b0;
	       ccif.ccinv[reqCache] = 1'b0;
	       ccif.ccsnoopaddr[reqCache] = 32'd0;
	    end
	  IMEMR:
	    begin
	       if (ccif.ramstate == ACCESS )
		 ccif.iwait[reqCache] = 1'b0;
	       else
		 ccif.iwait[reqCache] = 1'b1;
	       
	       ccif.dwait[reqCache] = 1'b1;
	       ccif.iload[reqCache] = ccif.ramload;
	       ccif.dload[reqCache] = 32'hbad1bad1;
	       
	       ccif.ccwait[reqCache] = 1'b0;
	       ccif.ccinv[reqCache] = 1'b0;
	       ccif.ccsnoopaddr[reqCache] = 32'd0;
	    end
	  DMEMW1, DMEMW2:
	    begin
	       ccif.iwait[reqCache] = 1'b1;
	       if (ccif.ramstate == ACCESS  )
		 ccif.dwait[reqCache] = 1'b0;
	       else
		 ccif.dwait[reqCache] = 1'b1;
	       
	       ccif.iload[reqCache] = 32'd0;
	       ccif.dload[reqCache] = 32'hbad1bad1;
	       
	       ccif.ccwait[reqCache] = 1'b0;
	       ccif.ccinv[reqCache] = 1'b0;
	       ccif.ccsnoopaddr[reqCache] = 32'd0;
	    end
   	  MEMR1, MEMR2:
	    begin
	       ccif.iwait[reqCache] = 1'b1;
	       if (ccif.ramstate == ACCESS  )
		 ccif.dwait[reqCache] = 1'b0;
	       else
		 ccif.dwait[reqCache] = 1'b1
					;
	       ccif.iload[reqCache] = 32'd0;
	       ccif.dload[reqCache] = ccif.ramload;
	       
	       ccif.ccwait[reqCache] = 1'b0;
	       ccif.ccinv[reqCache] = 1'b0;
	       ccif.ccsnoopaddr[reqCache] = 32'd0;
	    end
	  default:
	    begin
	       ccif.iwait[reqCache] = 1'b1;
	       ccif.dwait[reqCache] = 1'b1;
	       ccif.iload[reqCache] = 32'd0;
	       ccif.dload[reqCache] = 32'hbad1bad1;
	       
	       ccif.ccwait[reqCache] = 1'b0;
	       ccif.ccinv[reqCache] = 1'b0;
	       ccif.ccsnoopaddr[reqCache] = 32'd0;
	    end
	endcase // case (currentState)
	
	// Output logic snoopCache
	case (currentState)
	  SNOOP:
	    begin
	       ccif.iwait[snoopCache] = 1'b1;
	       if (ccif.ramstate == ACCESS & ccif.ccwrite[snoopCache])
		 ccif.dwait[snoopCache] = ~ccif.dWEN[snoopCache];
	       else
		 ccif.dwait[snoopCache] = 1'b1;
	       
	       ccif.iload[snoopCache] = 32'd0;
	       ccif.dload[snoopCache] = 32'hbad1bad1;
	       
	       ccif.ccwait[snoopCache] = 1'b1;
	       ccif.ccinv[snoopCache] = ccif.ccwrite[reqCache];
	       ccif.ccsnoopaddr[snoopCache] = snoopAddr;
	    end // case: SNOOP
	  default:
	    begin
	       ccif.iwait[snoopCache] = 1'b1;
	       ccif.dwait[snoopCache] = 1'b1;
	       ccif.iload[snoopCache] = 32'd0;
	       ccif.dload[snoopCache] = 32'hbad1bad1;
	       
	       ccif.ccwait[snoopCache] = 1'b0;
	       ccif.ccinv[snoopCache] = 1'b0;
	       ccif.ccsnoopaddr[snoopCache] = 32'd0;
	    end
	endcase // case (currentState)
     end // always_comb

   always_comb
     begin
	case(currentState)
	  SNOOP:
	    begin
	       ccif.ramstore = ccif.dstore[snoopCache];
	       ccif.ramaddr = ccif.daddr[snoopCache];
	       ccif.ramWEN = ccif.dWEN[snoopCache] & ccif.ccwrite[snoopCache];
	       ccif.ramREN = 1'b0;
	    end
	  IMEMR:
	    begin
	       ccif.ramstore = 32'hbad1bad1;
	       ccif.ramaddr = ccif.iaddr[reqCache];
	       ccif.ramWEN = 1'b0;
	       ccif.ramREN = 1'b1;
	    end
	  MEMR1, MEMR2:
	    begin
	       ccif.ramstore = 32'hbad1bad1;
	       ccif.ramaddr = ccif.daddr[reqCache];
	       ccif.ramWEN = 1'b0;
	       ccif.ramREN = 1'b1;
	    end
	  DMEMW1, DMEMW2:
	    begin
	       ccif.ramstore = ccif.dstore[reqCache];
	       ccif.ramaddr = ccif.daddr[reqCache];
	       ccif.ramWEN = 1'b1;
	       ccif.ramREN = 1'b0;
	    end
	  default:
	    begin
	       ccif.ramstore = 32'hbad1bad1;
	       ccif.ramaddr = 32'd0;
	       ccif.ramWEN = 1'b0;
	       ccif.ramREN = 1'b0;
	    end
	endcase // case (currentState)
     end
   
endmodule // memory_control
