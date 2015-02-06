/* 
 Sheik Dawood
 dawood0@purdue.edu
 
 Request Unit for single cycle processor
*/

module request_unit(
		    input logic CLK, nRST,
		    input logic  halt, r_req, w_req, iHit, dHit,
		    output logic iRen, dRen, dWen
		    );

   always_ff @(posedge CLK or negedge nRST)
     begin
	if(!nRST)
	  begin
	     iRen <= 1'b1;
	     dRen <= 1'b0;
	     dWen <= 1'b0;
	  end
	else
	  begin
	     if(halt)
	       begin
		  iRen <= 1'b0;
		  dRen <= 1'b0;
		  dWen <= 1'b0;
	       end
	     else if(dHit)
	       begin
		  dRen <= 1'b0;
		  dWen <= 1'b0;
	       end
	     else
	       begin
		  dRen <= r_req;
		  dWen <= w_req;
	       end
	  end // else: !if(!nRst)
     end // always_ff @

endmodule // request_unit

