`ifndef RV5STAGE_FETCH
`define RV5STAGE_FETCH

`include "src/rtl/common.sv"
`include "src/rtl/icache.sv"

module fetch(
  input logic clk,
  input logic rst,
  output PipeRequest req,
  input PipeControl pc_pipe,
  input PipeControl if_id_pipe,

  input logic pc_w_enable,
  input logic [31:0] pc_data,

  output FetchInfo info,
  output logic error
);

assign req.stall_req = 1'b0;
assign req.flush_req = 4'b0000;

logic [31:0] pc, inst, last_pc;
logic ic_error;

icache icache(.clk(clk), .rst(rst), .pipe(if_id_pipe), .addr(pc), .inst(inst), .error(ic_error));

assign error = ic_error;

assign info = '{last_pc, inst};

always_ff @(posedge clk) begin
  if (rst) begin
    pc <= 32'h00000000;
  end else if (pc_pipe.stall) begin
    pc <= pc;
  end else if (pc_pipe.flush) begin
    pc <= 32'h00000000;
  end else if (pc_w_enable) begin
    pc <= pc_data;
  end else begin
    pc <= pc + 32'h4;
  end
end

always_ff @(posedge clk) begin
  if (rst) begin
    last_pc <= 32'h00000000;
  end else begin
    last_pc <= pc;
  end
end

endmodule

`endif
