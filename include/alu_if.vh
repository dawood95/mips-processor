/* Sheik Dawood
 - mg258
 - dawood0@purdue.edu
 ALU Interface
 */

`ifndef ALU_IF_VH
 `define ALU_IF_VH

 `include "cpu_types_pkg.vh"

interface alu_if;

   import cpu_types_pkg::*;

   logic nf, zf, of;
   word_t porta, portb, out;
   aluop_t op;

   modport sv (
	       input  porta, portb, op,
	       output out, nf, zf, of
	       );

   modport tb (
	       input  out, nf, zf, of,
	       output porta, portb, op
	       );

endinterface

`endif
