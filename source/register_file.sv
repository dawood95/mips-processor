`include "register_file_if.vh"
`include "cpu_types_pkg.vh"

module register_file
import cpu_types_pkg::word_t;
(
  input logic CLK, nRST
);

  word_t [31:0] register;

  always_ff @(posedge CLK or negedge nRST)
  begin
    if (!nRST)
    begin
      register <= '{default:0};
    end
    else if (rf.WEN) register[rf.wsel] <= rf.wdat;
  end

  assign rf.rdat1 = register[rf.rsel1];
  assign rf.rdat2 = register[rf.rsel2];

endmodule
