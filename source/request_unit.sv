/*
  Everett Berry
  epberry@purdue.edu

  request unit which interfaces with the memory controller
  to get instructions and data
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
	else if(halt)
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
     end // always_ff @

endmodule // request_unit

