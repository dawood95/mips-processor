`include "register_file_if.vh"
`include "cpu_types_pkg.vh"

module register_file
import cpu_types_pkg::word_t;
(
  input logic CLK, nRST, register_file_if.rf rfif
);

  word_t [31:0] register;

  // next state
  always_ff @(posedge CLK or negedge nRST)
  begin
    if (!nRST)
    begin
      register <= '{default:0};
    end
    else if (rfif.WEN)
    begin
      register[rfif.wsel] <= rfif.wdat;
      register[0] <= 0; // register[0] must be constant 0
    end
  end

  // output -- set register[0] to constant 0x00000000
  // assign rfif.rdat1 = !rfif.rsel1 ? '{default:0} : register[rfif.rsel1];
  // assign rfif.rdat2 = !rfif.rsel2 ? '{default:0} : register[rfif.rsel2];
  assign rfif.rdat1 = register[rfif.rsel1];
  assign rfif.rdat2 = register[rfif.rsel2];

endmodule
