module top(
    input logic clk,
    input logic a,
    input logic b,
    output logic c
);

always @ (posedge clk) begin
    c <= a ^ b;
end

endmodule
