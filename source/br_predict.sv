/*
Branch predicting module
*/

`include "cpu_types_pkg.vh"

module br_predict
  import cpu_types_pkg::*;
  (
    input logic CLK,
    input logic nRST,
    input word_t instr,
    input logic pr_correct,
    input word_t update_br_target,
    input [1:0] w_index,
    input [1:0] r_index,
    output word_t br_target,
    output logic take_br
  );

  // local vars
  typedef enum bit [1:0] {
    TAKE1,
    TAKE2,
    NTAKE1,
    NTAKE2
  } stateType;

  // 4 entries in branch prediction table
  stateType twoBitSat[1:0];
  stateType twoBitSat_next[1:0];

  // 4 entries in branch target table
  logic [1:0] id[1:0];
  word_t target[1:0];


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

    // update branch target
    target[w_index] = update_br_target;

    // check the id against the pc
      // take/don't take prediction
      if (twoBitSat[r_index] == TAKE1 || twoBitSat[r_index] == TAKE2)
        take_br = 1;
      else
        take_br = 0;
  end

endmodule

