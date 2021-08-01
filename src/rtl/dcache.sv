`ifndef RV5STAGE_DCACHE
`define RV5STAGE_DCACHE

module dcache(
  input logic clk,
  input logic rst,

  input r_enable,
  input logic [31:0] r_addr,
  output logic [31:0] r_data,

  input w_enable,
  input logic [31:0] w_addr,
  input logic [31:0] w_data
);

logic [31:0] data_mem [0:1023]; // 4 Byte per line

assign r_data = data_mem[r_addr[11:2]];

always_ff @ (posedge clk) begin
  if (w_enable) begin
    data_mem[w_addr[11:2]] <= w_data;
  end else begin
    data_mem[w_addr[11:2]] <= data_mem[w_addr[11:2]];
  end
end

endmodule

`endif
