/*
  Everett Berry
  epberry@purdue.edu

  request unit interface - handles reading and writing to and from memory
*/

`ifndef REQUEST_UNIT_IF_VH
`define REQUEST_UNIT_IF_VH

`include "cpu_types_pkg.vh"

interface request_unit_if;

  import cpu_types_pkg::*;

  logic dREN, dWEN, iREN; // to cache
  logic ihit, dhit, memwr, memread; // from control unit

  modport request (
    input ihit, dhit, memwr, memread,
    output dREN, dWEN, iREN
  );

endinterface

`endif // REQUEST_UNIT_IF_VH
