`include "common.sv"

module top(
  input logic clk,
  input logic rst,
  output logic error
);

logic [31:0] fetch_inst;
logic fetch_error, decode_error;

FetchInfo fetch_info;
DecodeInfo decode_info, decode_info_ff, execute_info_ff, memory_info_ff;

logic [31:0] regfile_r1_data, regfile_r2_data, regfile_w_data, regfile_r2_data_ff;
logic [4:0] regfile_w_addr;
logic regfile_w_enable;

logic [31:0] execute_out, execute_out_ff;

logic pc_w_enable;
logic [31:0] new_pc;

logic [31:0] mem_out;

PipeRequest if_req, id_req, ex_req, ma_req;
PipeControl pc_ctrl, if_id_ctrl, id_ex_ctrl, ex_ma_ctrl;

always @ (posedge clk) begin
  if (rst) begin
    regfile_r2_data_ff <= 32'h00000000;
  end else begin
    regfile_r2_data_ff <= regfile_r2_data;
  end
end

control control(
  .if_req(if_req),
  .id_req(id_req),
  .ex_req(ex_req),
  .ma_req(ma_req),
  .pc_ctrl(pc_ctrl),
  .if_id_ctrl(if_id_ctrl),
  .id_ex_ctrl(id_ex_ctrl),
  .ex_ma_ctrl(ex_ma_ctrl)
);

fetch fetch(
  .clk(clk),
  .rst(rst),
  .req(if_req),
  .pc_pipe(pc_ctrl),
  .if_id_pipe(if_id_ctrl),
  .pc_w_enable(pc_w_enable),
  .pc_data(new_pc),
  .info(fetch_info),
  .error(fetch_error)
);

decode decode(
  .clk(clk),
  .rst(rst),
  .req(id_req),
  .pipe(id_ex_ctrl),
  .fetch_info(fetch_info),
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
  .req(ex_req),
  .pipe(ex_ma_ctrl),
  .info(decode_info_ff),
  .rs1_data(regfile_r1_data),
  .rs2_data(regfile_r2_data),
  .mem_info(memory_info_ff),
  .mem_out(mem_out),
  .alu_out(execute_out),
  .pc_w_enable(pc_w_enable),
  .new_pc(new_pc),
  .info_ff(execute_info_ff)
);

memory memory(
  .clk(clk),
  .rst(rst),
  .req(ma_req),
  .info(execute_info_ff),
  .addr(execute_out),
  .data(regfile_r2_data_ff),
  .mem_out(mem_out),
  .info_ff(memory_info_ff)
);

writeback writeback(
  .clk(clk),
  .rst(rst),
  .info(memory_info_ff),
  .mem_in(mem_out),
  .w_enable(regfile_w_enable),
  .w_addr(regfile_w_addr),
  .w_data(regfile_w_data)
);

assign error = fetch_error || decode_error;

endmodule
