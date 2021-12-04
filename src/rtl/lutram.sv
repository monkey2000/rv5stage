`ifndef LUTRAM_SV
`define LUTRAM_SV

module lutram #(
  parameter WIDTH = 128,                // 32 Bytes
  parameter DEPTH = 128,
  parameter ADDRW = $clog2(DEPTH),
  parameter string INIT_FILE = ""
) (
  input logic clk,
  input logic we,
  input logic [ADDRW-1:0] a,
  input logic [ADDRW-1:0] dpra,
  input logic [WIDTH-1:0] di,
  output logic [WIDTH-1:0] spo,
  output logic [WIDTH-1:0] dpo
);

(* ram_style = "distributed" *) logic [WIDTH-1:0] mem [DEPTH-1:0];

always_ff @ (posedge clk) begin
  if (we) begin
    mem[a] <= di;
  end
end

assign spo = mem[a];
assign dpo = mem[dpra];

endmodule

`endif // LUTRAM_SV
