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

logic [31:0] pc, shadow_pc, to_icache_pc, inst, last_pc;
logic shadow_pc_pending;
logic ic_error;
logic enable, last_enable;

icache icache(.clk(clk), .rst(rst), .req(req), .pipe(if_id_pipe), .addr(to_icache_pc), .addr_ff(pc), .bus(bus), .inst(inst), .error(ic_error));

assign info = '{last_enable, last_pc, inst};

always_ff @ (posedge clk) begin
  if (rst) begin
    shadow_pc <= 32'h80000000;
  end else if (pc_w_enable && pc_pipe.stall) begin
    shadow_pc <= pc_data;
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    shadow_pc_pending <= 0;
  end else if (pc_w_enable && pc_pipe.stall) begin
    shadow_pc_pending <= 1;
  end else if (shadow_pc_pending && !pc_pipe.stall) begin
    shadow_pc_pending <= 0;
  end else begin
    shadow_pc_pending <= 0;
  end
end

always_comb begin
  if (rst) begin
    to_icache_pc = 32'h80000000;
  end else if (pc_w_enable) begin
    to_icache_pc = pc_data;
  end else if (shadow_pc_pending) begin
    to_icache_pc = shadow_pc;
  end begin
    to_icache_pc = pc + 32'h4;
  end
end

always_ff @(posedge clk) begin
  if (rst) begin
    pc <= 32'h80000000 - 32'h4;
  end else if (pc_pipe.flush) begin
    pc <= 32'h80000000;
  end else if (pc_pipe.stall) begin
    pc <= pc;
  end else begin
    pc <= to_icache_pc;
  end
end

always_ff @(posedge clk) begin
  if (rst) begin
    enable <= 0;
  end else if (pc_pipe.flush) begin
    enable <= 1;
  end else if (pc_pipe.stall) begin
    enable <= 0;
  end else begin
    enable <= 1;
  end
end

always_ff @(posedge clk) begin
  if (rst) begin
    last_pc <= 32'h80000000;
  end else begin
    last_pc <= pc;
  end
end

always_ff @(posedge clk) begin
  if (rst) begin
    last_enable <= 0;
  end else begin
    last_enable <= enable;
  end
end

endmodule

`endif
