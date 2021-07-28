`ifndef RV5STAGE_MEMORY
`define RV5STAGE_MEMORY

module memory(
  input logic clk,
  input logic rst,
  input DecodeInfo info,
  output DecodeInfo info_ff
);

always_ff @ (posedge clk) begin
  if (rst) begin
    info_ff <= 0;
  end else begin
    info_ff <= info;
  end
end

endmodule

`endif
