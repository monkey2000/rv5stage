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
logic current_pc_drop;
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
  end else if (shadow_pc_pending && !current_pc_drop && !pc_pipe.stall) begin
    shadow_pc_pending <= 0;
  end else begin
    shadow_pc_pending <= shadow_pc_pending;
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    current_pc_drop <= 0;
  end else if (pc_w_enable && pc_pipe.stall) begin
    current_pc_drop <= 1;
  end else if (current_pc_drop && !pc_pipe.stall) begin
    current_pc_drop <= 0;
  end else begin
    current_pc_drop <= current_pc_drop;
  end
end

always_comb begin
  if (rst) begin
    to_icache_pc = 32'h80000000;
  end else if (pc_w_enable) begin
    to_icache_pc = pc_data;
  end else if (shadow_pc_pending && !current_pc_drop) begin
    to_icache_pc = shadow_pc;
  end else if (if_id_pipe.stall) begin
    to_icache_pc = pc;
  end else begin
    to_icache_pc = pc + 32'h4;
  end
end

always_ff @(posedge clk) begin
  if (rst) begin
    pc <= 32'h80000000 - 32'h4;
  // end else if (pc_pipe.flush) begin
  //   pc <= 32'h80000000;
  end else if (pc_pipe.stall) begin
    pc <= pc;
  end else begin
    pc <= to_icache_pc;
  end
end

always_ff @(posedge clk) begin
  if (rst) begin
    enable <= 0;
  end else if (pc_pipe.flush && (!pc_w_enable)) begin
    enable <= 0;
  end else if (pc_pipe.stall) begin
    enable <= enable;
  end else if (req.stall_req) begin
    enable <= 0;
  end else begin
    enable <= 1;
  end
end

always_ff @(posedge clk) begin
  if (rst) begin
    last_pc <= 32'h80000000;
  end else if (if_id_pipe.flush) begin
    last_pc <= 32'h80000000;
  end else if (if_id_pipe.stall) begin
    last_pc <= last_pc;
  // end else if (req.stall_req) begin
  //   last_pc <= 32'h80000000;
  end else begin
    last_pc <= pc;
  end
end

always_ff @(posedge clk) begin
  if (rst) begin
    last_enable <= 0;
  end else if (if_id_pipe.flush) begin
    last_enable <= 0;
  end else if (if_id_pipe.stall) begin
    last_enable <= last_enable;
  // end else if (req.stall_req) begin
  //   last_enable <= 0;
  end else begin
    last_enable <= enable && (!shadow_pc_pending);
  end
end

endmodule

`endif
