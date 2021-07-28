`include "src/rtl/common.sv"
`include "src/rtl/fetch.sv"
`include "src/rtl/decode.sv"
`include "src/rtl/regfile.sv"
`include "src/rtl/execute.sv"
`include "src/rtl/memory.sv"
`include "src/rtl/writeback.sv"

module top(
  input logic clk,
  input logic rst,
  output logic error
);

logic [31:0] fetch_inst;
logic fetch_error, decode_error;

DecodeInfo decode_info, decode_info_ff, execute_info_ff, memory_info_ff;

logic [31:0] regfile_r1_data, regfile_r2_data, regfile_w_data;
logic [4:0] regfile_w_addr;
logic regfile_w_enable;

logic [31:0] execute_out, execute_out_ff;

fetch fetch(
  .clk(clk),
  .rst(rst),
  .inst(fetch_inst),
  .error(fetch_error)
);

decode decode(
  .clk(clk),
  .rst(rst),
  .inst(fetch_inst),
  .error(decode_error),
  .info(decode_info),
  .info_ff(decode_info_ff)
);

regfile regfile(
  .clk(clk),
  .rst(rst),
  .r1_addr(decode_info.rs1),
  .r1_data(regfile_r1_data),
  .r2_addr(decode_info.rs2),
  .r2_data(regfile_r2_data),
  .w_enable(regfile_w_enable),
  .w_addr(regfile_w_addr),
  .w_data(regfile_w_data)
);

execute execute(
  .clk(clk),
  .rst(rst),
  .info(decode_info_ff),
  .rs1_data(regfile_r1_data),
  .rs2_data(regfile_r2_data),
  .alu_out(execute_out),
  .alu_out_ff(execute_out_ff),
  .info_ff(execute_info_ff)
);

memory memory(
  .clk(clk),
  .rst(rst),
  .info(execute_info_ff),
  .info_ff(memory_info_ff)
);

writeback writeback(
  .clk(clk),
  .rst(rst),
  .info(memory_info_ff),
  .alu_in(execute_out_ff),
  .w_enable(regfile_w_enable),
  .w_addr(regfile_w_addr),
  .w_data(regfile_w_data)
);

assign error = fetch_error || decode_error;

endmodule
