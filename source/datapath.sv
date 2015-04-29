/*
  Everett Berry
  epberry@purdue.edu

  datapath contains register file, control, hazard,
  muxes, and glue logic for processor
*/

`include "datapath_cache_if.vh"
`include "register_file_if.vh"
`include "alu_if.vh"
`include "cpu_types_pkg.vh"

module datapath (
		 input logic CLK, nRST,
		 datapath_cache_if.dp dpif
		 );
   // import types
   import cpu_types_pkg::*;

   // pc init
   parameter PC_INIT = 0;

   // Local variables
   word_t instr;
   i_t iinstr;
   j_t jinstr;
   r_t rinstr;
   word_t immExt, pc, pc_next;
   logic 		     r_req, w_req, porta_sel, immExt_sel, brEn, pcEn, halt;
   logic [1:0] 		     portb_sel, pc_sel, wMemReg_sel, regW_sel;
   alu_if alif();
   register_file_if rfif();
   
   
   always_comb
     begin
	// Instruction type cast
	iinstr = i_t'(instr);
	jinstr = j_t'(instr);
	rinstr = r_t'(instr);
     end

   
   
   register_file reg_file( CLK, nRST, rfif);
   request_unit req_unit(.CLK(CLK), 
			 .nRST(nRST),
			 .halt(dpif.halt),
			 .r_req(r_req),
			 .w_req(w_req),
			 .iHit(dpif.ihit),
			 .dHit(dpif.dhit),
			 .iRen(dpif.imemREN),
			 .dRen(dpif.dmemREN),
			 .dWen(dpif.dmemWEN)
			  );
   control_unit control_unit(.instr(instr),
			     .zf(alif.zf),
		       	     .of(alif.of),
	       		     .aluOp(alif.op),
       			     .portb_sel(portb_sel),
       			     .porta_sel(porta_sel),
       			     .immExt_sel(immExt_sel), 
       			     .pc_sel(pc_sel), 
       			     .regW_sel(regW_sel),
       			     .wMemReg_sel(wMemReg_sel), 
       			     .memREN(r_req), 
       			     .memWEN(w_req), 
       			     .regWEN(rfif.WEN),
       			     .brEn(brEn),	
			     .halt(halt)
			     );
   
   alu alu(alif);

   always_comb
     begin
	instr = dpif.imemload;
	immExt = (immExt_sel) ? {{16{iinstr.imm[15]}},iinstr.imm} : {16'b0,iinstr.imm} ;
	alif.porta = (porta_sel) ? immExt : rfif.rdat1;
	case(portb_sel)
	  2'b00: alif.portb = rfif.rdat2;
	  2'b01: alif.portb = rinstr.shamt;
	  2'b10: alif.portb = immExt;
	  2'b11: alif.portb = 32'd16;
	endcase // case (portb_sel)
	case(regW_sel)
	  2'b00, 2'b11: rfif.wsel = rinstr.rd;
	  2'b01: rfif.wsel = rinstr.rt;
	  2'b10: rfif.wsel = 5'd31;
	endcase // case (regW_sel)
	rfif.rsel1 = rinstr.rs;
	rfif.rsel2 = rinstr.rt;
	case(wMemReg_sel)
	  2'b00,2'b11 : rfif.wdat = alif.out;
	  2'b01: rfif.wdat = dpif.dmemload;
	  2'b10: rfif.wdat = pc+4;
	endcase
	dpif.dmemaddr = alif.out;
	dpif.dmemstore = rfif.rdat2;
	dpif.imemaddr = pc;
	case(pc_sel)
	  2'b00, 2'b11: pc_next = pc + 4 + ((brEn) ? immExt<<2 : 32'd0);
	  2'b01: pc_next = rfif.rdat1;
	  2'b10: pc_next = {pc[31:28],jinstr.addr,2'b00};
	endcase
	pcEn = ~dpif.dmemREN & ~dpif.dmemWEN;
     end
   
   //PC  

   always_ff @(posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  pc <= PC_INIT;
	else if(pcEn & !dpif.halt)
	  pc <= pc_next;
     end

   always_ff @(posedge CLK, negedge nRST)
     begin
	if(!nRST)
	  dpif.halt <= 1'b0;
	else
	  dpif.halt <= halt;
     end
   
endmodule // datapath


// data path interface
`include "datapath_cache_if.vh"

`include "cpu_types_pkg.vh"
`include "register_file_if.vh"
`include "alu_if.vh"
`include "control_unit_if.vh"
`include "request_unit_if.vh"
`include "pc_if.vh"

module datapath (
  input logic CLK, nRST,
  datapath_cache_if.dp dpif
);

  import cpu_types_pkg::*;

  parameter PC_INIT = 0;

  // initialize all the interfaces
  register_file_if rfif ();
  control_unit_if cuif ();
  request_unit_if ruif ();
  alu_if aluif ();
  // pc_if pcif ();

  // hook the modules together
  // pc program_ctr(CLK, nRST, pcif);
  register_file register(CLK, nRST, rfif);
  control_unit control(CLK, nRST, cuif);
  request_unit request(CLK, nRST, ruif);
  alu alu(aluif);

  // local vars
  r_t rtype;
  i_t itype;
  j_t jtype;
  word_t extender, pcplus, jumpaddr, branchaddr, jraddr, luihelp;
  word_t pc, pcnext; // might also need pca and pcb
  logic halt, haltnext, pcEN; // latch halt
  regbits_t rt_or_31;
  // logic pcacontrol;

  // pc
  always_ff @(posedge CLK, negedge nRST)
  begin
    if (!nRST)
      pc <= PC_INIT;
    else if (pcEN) // if (!halt && !dpif.dhit) // PC = ihit & !dhit & !halt
      pc <= pcnext ;
  end

  // latched halt
  always_ff @(posedge CLK, negedge nRST)
  begin
    if (!nRST)
      halt <= 1'b0;
    else
      halt <= haltnext;
  end

  // glue logic
  always_comb
  begin
    // cast types
    rtype = r_t'(dpif.imemload);
    itype = i_t'(dpif.imemload);
    jtype = j_t'(dpif.imemload);

    // local computation
    extender = cuif.ext ? $signed(itype.imm) : $unsigned(itype.imm);
    luihelp = cuif.lui ? {extender[15:0], extender[31:16]} : extender;
    // pcplus = pcif.addr + 4;
    // jumpaddr = {pcif.addr[31:28], jtype.addr, 2'b00};
    branchaddr = ($signed(luihelp << 2)) + pcplus;
    jraddr = rfif.rdat1;

    // pc computation
    pcnext = pcEN ? pc + 4 : pc;


    pcEN = nRST & !cuif.halt & dpif.ihit & !dpif.dhit;
    // pcacontrol = (cuif.branch & (cuif.bne ^ aluif.zero));
    // pca = pcacontrol ? branchaddr : pca;
    // pcb = cuif.jump ? jumpaddr : pca;
    // pcnext = cuif.jumpreg ? jraddr : pcb;


    haltnext = cuif.halt;
  end

  // module connections
  always_comb
  begin
    // register
    rfif.WEN = cuif.regwr;
    rt_or_31 = cuif.jumpal ? 1'b1 : rtype.rt;
    rfif.wsel = cuif.regdst ? rtype.rd : rt_or_31;
    rfif.rsel1 = rtype.rs;
    rfif.rsel2 = rtype.rt;
    rfif.wdat = cuif.memtoreg ? dpif.dmemload : aluif.outPort;

    // request unit
    // ruif.halt = cuif.halt;
    ruif.memread = cuif.memread;
    ruif.memwr = cuif.memwr;
    ruif.ihit = dpif.ihit;
    ruif.dhit = dpif.dhit;
    // ruif.dmemstore = rfif.rdat2;
    // ruif.dmemaddr = aluif.out;
    dpif.imemREN = ruif.iREN;
    dpif.dmemREN = ruif.dREN;
    dpif.dmemWEN = ruif.dWEN;

    // pc
    // pcif.next_addr = pcnext;
    // pcif.pc_pause = ~dpif.ihit | cuif.halt;
    dpif.imemaddr = pc;
    dpif.dmemaddr = aluif.outPort;
    dpif.dmemstore = rfif.rdat2;

    // alu
    aluif.opcode = cuif.aluop;
    aluif.portA = rfif.rdat1;
    aluif.portB = cuif.shift ? ({27'b0, rtype.shamt}) : (cuif.alusrc ? luihelp : rfif.rdat2);

    // control unit
    cuif.instr = dpif.imemload;

    // cache
    dpif.halt = halt;

  end


endmodule
