/* Sheik Dawood 
 - mg258 
 - dawood0@purdue.edu
 ALU
 */

`include "cpu_types_pkg.vh"
`include "alu_if.vh"

module alu
  import cpu_types_pkg::*;
   (
    alu_if.sv sv
    );

  always_comb
    begin
       casez (sv.op)
	 ALU_SLL: 
	   begin
	      sv.out = sv.porta << sv.portb;
	      sv.of = 0;
	   end
	 ALU_SRL: 
	   begin
	      sv.out = sv.porta >> sv.portb;
	      sv.of = 0;
	   end
	 ALU_ADD: 
	   begin
	      sv.out = $signed(sv.porta) + $signed(sv.portb);
	      sv.of = ~(sv.porta[WORD_W-1] ^ sv.portb[WORD_W-1]) & (sv.porta[WORD_W-1] ^ sv.out[WORD_W-1]);
	   end
	 
	 ALU_SUB:
	   begin
	      sv.out = $signed(sv.porta) - $signed(sv.portb);
	      sv.of = (sv.porta[WORD_W-1] ^ sv.portb[WORD_W-1]) & (sv.porta[WORD_W-1] ^ sv.out[WORD_W-1]);
	   end
	 ALU_AND: 
	   begin
	      sv.out = sv.porta & sv.portb;
	      sv.of = 0;
	   end
	 ALU_OR:  
	   begin
	      sv.out = sv.porta | sv.portb;
	      sv.of = 0;
	   end
	 ALU_XOR:
	   begin
	      sv.out = sv.porta ^ sv.portb;
	      sv.of = 0;
	   end
	 ALU_NOR: 
	   begin
	      sv.out = ~(sv.porta | sv.portb);
	      sv.of = 0;
	   end
	 ALU_SLT: 
	   begin 
	      sv.out = ($signed(sv.porta) < $signed(sv.portb)) ? 1 : 0;
	      sv.of = 0;
	      
	   end
	 ALU_SLTU: 
	   begin
	      sv.out = ($unsigned(sv.porta) < $unsigned(sv.portb)) ? 1 : 0;
	      sv.of = 0;
	   end
	 default: 
	   begin
	      sv.out = 0;
	      sv.of = 0;
	   end
       endcase // case (sv.op)
       sv.zf = (sv.out == 0) ? 1'b1 : 1'b0;
       sv.nf = ($signed(sv.out) < 0) ? 1'b1 : 1'b0;
    end // always_comb
   

endmodule // alu

    
