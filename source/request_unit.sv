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
   logic 			 iRen_next, 
				 dRen_next, 
				 dWen_next;
   
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
	     iRen <= iRen_next;
	     dRen <= dRen_next;
	     dWen <= dWen_next;
	  end // else: !if(!nRst)
     end // always_ff @

   always_comb
     begin
	dRen_next = r_req & ~dHit;
	dWen_next = w_req & ~dHit;
	iRen_next = ~halt & ~dRen_next & ~dWen_next;
     end
   
endmodule // request_unit

