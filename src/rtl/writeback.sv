`ifndef RV5STAGE_WRITEBACK
`define RV5STAGE_WRITEBACK

`include "common.sv"

module writeback(
  input logic clk,
  input logic rst,
  input DecodeInfo info,
  input logic [31:0] mem_in,

  output logic w_enable,
  output logic [4:0] w_addr,
  output logic [31:0] w_data
);

always_comb begin
  w_enable = info.enable && info.reg_write;
  w_addr = info.rd;
  w_data = mem_in;
end

endmodule

`endif
