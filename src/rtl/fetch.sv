`ifndef RV5STAGE_FETCH
`define RV5STAGE_FETCH

`include "common.sv"

module fetch(
  input logic clk,
  input logic rst,
  output PipeRequest req,
  input PipeControl pc_pipe,
  input PipeControl if_id_pipe,

  input logic pc_w_enable,
  input logic [31:0] pc_data,
  output FetchInfo info,
  output logic error,

  SystemBus.user bus
);

logic [31:0] next_pc, pc, inst, last_pc;
logic ic_error;

icache icache(.clk(clk), .rst(rst), .req(req), .pipe(if_id_pipe), .addr(next_pc), .addr_ff(pc), .bus(bus), .inst(inst), .error(ic_error));

assign info = '{last_pc, inst};

always_comb begin
  if (rst) begin
    next_pc = 32'h80000000;
  end else if (pc_pipe.flush) begin
    next_pc = 32'h80000000;
  end else if (pc_pipe.stall) begin
    next_pc = pc;
  end else if (pc_w_enable) begin
    next_pc = pc_data;
  end else begin
    next_pc = pc + 32'h4;
  end
end

always_ff @(posedge clk) begin
  pc <= next_pc;
end

always_ff @(posedge clk) begin
  if (rst) begin
    last_pc <= 32'h80000000;
  end else begin
    last_pc <= pc;
  end
end

endmodule

`endif
