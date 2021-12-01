`ifndef BRAM_SV
`define BRAM_SV

module bram #(
  parameter WIDTH = 128,                // 16 Bytes
  parameter DEPTH = 128,
  parameter ADDRW = $clog2(DEPTH),
  parameter MASKW = $clog2(WIDTH / 8),
  parameter string INIT_FILE = ""
) (
  input logic clk,
  input logic ena,
  input logic enb,
  input logic [MASKW-1:0] wea,
  input logic [ADDRW-1:0] addra,
  input logic [ADDRW-1:0] addrb,
  input logic [WIDTH-1:0] dia,
  output logic [WIDTH-1:0] dob
);

(* ram_style = "block" *) logic [WIDTH-1:0] mem [DEPTH-1:0];

generate
  if (INIT_FILE != "") begin
    initial $readmemh(INIT_FILE, mem);
  end
endgenerate

always_ff @(posedge clk) begin
  if (ena) begin
    for (i = 0; i < MASKW; i = i + 1) begin
      if (wea[i]) begin
        mem[addra][i * 8 +: 8] <= dia[i * 8 +: 8];
      end
    end
  end
end

always_ff @(posedge clk) begin
  if (enb) begin
    dob <= mem[addrb];
  end
end

endmodule

`endif // BRAM_SV
