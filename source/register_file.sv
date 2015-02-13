/* Sheik Dawood 
 - mg258 
 - dawood0@purdue.edu
 
 Register File
 */

`include "register_file_if.vh"
`include "cpu_types_pkg.vh"

module register_file
  import cpu_types_pkg::*;
    (
     input logic CLK, nRST,
     register_file_if.rf rf
     );
   
   word_t register_f[31:0];
   
   always_ff @(negedge CLK or negedge nRST)
     begin
	if(!nRST)
	  begin
	     register_f <= '{default:'0};
	  end
	else if(rf.WEN && rf.wsel)
	  begin
	     register_f[rf.wsel] <= rf.wdat;
	  end
     end // always_ff @

   always_comb
     begin
	rf.rdat1 = register_f[rf.rsel1];
	rf.rdat2 = register_f[rf.rsel2];
     end
   
endmodule // test
