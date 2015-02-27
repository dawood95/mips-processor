/*
 * Sheik Dawood
 * Everett Berry
 * 
 * Pipeline interface for the latches
 **/

`ifndef PIPELINE_IF_VH
 `define PIPELINE_IF_VH

 `include "cpu_types_pkg.vh"

package pipeline_if;

   import cpu_types_pkg::*;
   
   //Instruction fetch
   typedef struct {
      //Instruction & PC
      word_t      imemAddr;
      word_t      instr;
      word_t      pc;
      //Brach Prediction
      logic 	  btb_taken;
      word_t      btb_target;
      logic [1:0] btb_index;
   } ifetch_t;
   
   //Decode 
   typedef struct packed {
      //Instruction & PC
      word_t      instr;
      word_t      pc;
      logic       beq;
      logic 	  bne;
      logic 	  jal;
      logic       jr;	 
      word_t      jAddr;
      logic [2:0] pc_sel;
      logic 	  porta_sel;
      logic [1:0] portb_sel;
      //Branch
      logic 	  btb_taken;
      word_t      btb_target;
      logic [1:0] btb_index;
      //ALU
      word_t      porta;
      word_t      portb;
      aluop_t     aluOp;
      word_t      regData1;
      word_t      regData2;
      //Memory
      logic 	  memRen;
      logic 	  memWen;
      //Register
      logic [1:0] regDataSel; 
      regbits_t   regDest;
      logic 	  regWen;
      //Halt
      logic 	  halt;
   } decode_t;

   //Execute
   typedef struct packed {
      //Instruction
      logic       jr;	 
      logic       jal;	  
      logic       beq;
      logic       bne;	  
      word_t      brAddr;
      regbits_t   rs;
      regbits_t   rt;
      logic 	  porta_sel;
      logic [1:0] portb_sel;
      word_t      pc;
      word_t      immExt;
      word_t      jraddr;
      //Branch
      logic 	  btb_taken;
      word_t      btb_target;
      logic [1:0] btb_index;
      //ALU
      aluop_t     aluOp;
      word_t      porta;
      word_t      portb;
      word_t      aluOut;
      word_t      regData1;
      word_t      regData2;
      word_t      storeData;
      //Memory
      logic 	  memRen;
      logic 	  memWen;
      //Register
      logic [1:0] regDataSel; 
      regbits_t   regDest;
      logic 	  regWen;
      //Halt
      logic 	  dHalt;
      logic 	  eHalt;
   } exec_t;

   //Data Read Write 
   typedef struct packed {	
      //Instruction
      word_t      pc;
      logic 	  jal;
      logic       beq;
      logic 	  bne;
      logic       brTake;
      word_t      brAddr;
      word_t      brTarget;	  
      //Branch
      logic 	  btb_taken;
      word_t      btb_target;
      logic [1:0] btb_index;
      //ALU
      word_t      aluOut;
      word_t      regData2;
      logic 	  zf;	  
      //Memory
      logic 	  memRen;
      logic 	  memWen;
      //Register
      logic [1:0] regDataSel; 
      regbits_t   regDest;
      logic 	  regWen;
      word_t 	  memData;
      //halt
      logic 	  halt;
   } mem_t;

   //Register Read Write
   typedef struct packed {
      //Instruction
      word_t pc;
      //Register
      logic [1:0] regDataSel; 
      regbits_t regDest;
      logic 	  regWen;
      word_t 	  memData;
      word_t      aluData;
      word_t 	  regData;
      } regw_t;
   
endpackage // pipeline_if
`endif //  `ifndef PIPELINE_IF_VH
   
