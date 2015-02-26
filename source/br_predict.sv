/*
 Branch predicting module

 Has 2 tables, a branch target buffer table and the prediction table.

 Called in instruction fetch stage of pipeline.
 */

`include "cpu_types_pkg.vh"

module br_predict
  import cpu_types_pkg::*;
   (
    input logic        CLK,
    input logic        nRST,
    input word_t       instr,
    input logic        pr_correct,
    input word_t update_br_target,
    input logic [1:0]  w_index,
    input logic [1:0]  r_index,
    output word_t      br_target,
    output logic       take_br,
    output logic [1:0] out_index
    );

   // local vars
   typedef enum        bit [1:0] {
				  TAKE1,
				  TAKE2,
				  NTAKE1,
				  NTAKE2
				  } stateType;

   // 4 entries in branch prediction table
   stateType twoBitSat[3:0];
   stateType twoBitSat_next[3:0];

   // 4 entries in branch target table
   // logic [:0] index[1:0];
   word_t target[3:0];

   // temp for outputting index
   logic [1:0] 	       out_idx;


   // flip flop
   always_ff @(posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  twoBitSat[w_index] <= NTAKE1;
	else
	  begin
	     twoBitSat[w_index] <= twoBitSat_next[w_index];
	  end
     end

   // next state
   always_comb
     begin
	case(twoBitSat[w_index])
	  TAKE1:
            begin
               if(pr_correct) twoBitSat_next[w_index] = TAKE1;
               else twoBitSat_next[w_index] = TAKE2;
            end
	  TAKE2:
            begin
               if(pr_correct) twoBitSat_next[w_index] = TAKE1;
               else twoBitSat_next[w_index] = NTAKE1;
            end
	  NTAKE1:
            begin
               if(pr_correct) twoBitSat_next[w_index] = TAKE1;
               else twoBitSat_next[w_index] = NTAKE2;
            end
	  NTAKE2:
            begin
               if(pr_correct) twoBitSat_next[w_index] = NTAKE1;
               else twoBitSat_next[w_index] = NTAKE2;
            end
	endcase
     end

   // output
   always_comb
     begin
	br_target = target[r_index];
	// update branch target
	target[w_index] = update_br_target;

	// check the id against the pc
	if (instr[31:4] == target[r_index][31:4])
	  begin
	     // look at the result of the state machine
	     if (twoBitSat[r_index] == TAKE1 || twoBitSat[r_index] == TAKE2)
               take_br = 1;
	     else
               take_br = 0;
	  end else
	    begin
	       take_br = 0;
	    end

	// send index to ifde latch
	out_idx = instr[3:2]; // 4 entry table so 2 bits
	out_index = out_idx;

     end


endmodule

