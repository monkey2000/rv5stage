`include "common.sv"

module top(
  input logic clk,
  input logic uart_clk8,
  input logic uart_clk,
  input logic rst,
  output logic error,
  output logic uart_tx
);

logic [31:0] fetch_inst;
logic fetch_error, decode_error;

FetchInfo fetch_info;
DecodeInfo decode_info, decode_info_ff, execute_info_ff, memory_info_ff;

logic [31:0] regfile_r1_data, regfile_r2_data, regfile_w_data, regfile_r2_data_ff;
logic [4:0] regfile_w_addr;
logic regfile_w_enable;

logic [31:0] addr_gen;
logic [31:0] execute_out, execute_out_ff;

logic pc_w_enable;
logic [31:0] new_pc;

logic [31:0] mem_out;

logic uart_ready, uart_valid;
logic [7:0] uart_data;

PipeRequest if_req, id_req, ex_req, ma_req;
PipeControl pc_ctrl, if_id_ctrl, id_ex_ctrl, ex_ma_ctrl;

SystemBus bus [1:0] ();

l2cache #(
  .INIT_FILE("data/icache.dat")
) l2cache (
  .clk(clk),
  .rst(rst),
  .bus(bus)
);

uart_ctrl uart (
  .clk(clk),
  .uart_clk8(uart_clk8),
  .uart_clk(uart_clk),
  .rst(rst),
  .valid(uart_valid),
  .ready(uart_ready),
  .data(uart_data),
  .uart_tx(uart_tx)
);

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
  .error(fetch_error),
  .bus(bus[0])
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
  .pipe(id_ex_ctrl),
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
  .addr_gen(addr_gen),
  .alu_out(execute_out),
  .r2_out(regfile_r2_data_ff),
  .pc_w_enable(pc_w_enable),
  .new_pc(new_pc),
  .info_ff(execute_info_ff)
);

memory memory(
  .clk(clk),
  .rst(rst),
  .req(ma_req),
  .info(execute_info_ff),
  .speculate_addr(addr_gen),
  .addr(execute_out),
  .data(regfile_r2_data_ff),

  .uart_valid(uart_valid),
  .uart_ready(uart_ready),
  .uart_data(uart_data),

  .mem_out(mem_out),
  .info_ff(memory_info_ff),
  .bus(bus[1])
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
