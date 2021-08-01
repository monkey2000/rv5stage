`ifndef RV5STAGE_FETCH
`define RV5STAGE_FETCH

`include "src/rtl/common.sv"
`include "src/rtl/icache.sv"

module fetch(
  input logic clk,
  input logic rst,
  output FetchInfo info,
  output logic error
);

logic [31:0] pc, inst;
logic ic_error;

icache icache(.clk(clk), .rst(rst), .addr(pc), .inst(inst), .error(ic_error));

assign error = ic_error;

assign info = '{pc, inst};

always_ff @(posedge clk) begin
  if (rst) begin
    pc <= 32'h00000000;    
  end else begin
    pc <= pc + 32'h4;
  end
end

endmodule

`endif
