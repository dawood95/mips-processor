/*
  Everett Berry
  epberry@purdue.edu

  request unit which interfaces with the memory controller
  to get instructions and data
*/

`include "cpu_types_pkg.vh"
`include "request_unit_if.vh"

module request_unit (
  input logic CLK, nRST,
  request_unit_if.request ruif
);

  // latch signals for safety
  always_ff @(posedge CLK, negedge nRST)
  begin
    if (nRST == 1'b0)
    begin
      ruif.dREN <= 1'b0;
      ruif.dWEN <= 1'b0;
      ruif.iREN <= 1'b0;
    end else
    begin
      // set low if dhit, otherwise, if theres an instruction available,
      // look for the appropriate control signal
      ruif.dWEN <= ruif.dhit ? 1'b0 : (ruif.ihit ? ruif.memwr : 1'b0);
      ruif.dREN <= ruif.dhit ? 1'b0 : (ruif.ihit ? ruif.memread : 1'b0);

      // instr reads should always be happening
      // in memory controller, data ops take priority over instrs
      ruif.iREN <= 1'b1;
    end
  end

endmodule
