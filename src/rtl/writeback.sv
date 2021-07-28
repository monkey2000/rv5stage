`ifndef RV5STAGE_WRITEBACK
`define RV5STAGE_WRITEBACK

`include "src/rtl/common.sv"

module writeback(
  input logic clk,
  input logic rst,
  input DecodeInfo info,
  input logic [31:0] alu_in,

  output logic w_enable,
  output logic [4:0] w_addr,
  output logic [31:0] w_data
);

always_comb begin
  w_enable = info.reg_write;
  w_addr = info.rd;
  w_data = alu_in;
end

endmodule

`endif
