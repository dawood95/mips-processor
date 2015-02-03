/*
  Everett Berry
  epberry@purdue.edu

  request unit which interfaces with the memory controller
  to get instructions and data
*/

`include "datapath_cache_if.vh"
`include "cpu_types_pkg.vh"

module request_unit (
  input logic CLK, nRST, dREN, dWEN, iREN, ihit, dhit
);

  // one bit state machine
  always_ff @(posedge CLK, negedge nRST)
  begin
    if (nRST == 1'b0)

  end

  // always comb output logic

endmodule
