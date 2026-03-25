module clock(
    input wire clk,
    output wire clk_1s,
    output wire clk_5ms
);

reg [22:0] contador = 0;

always @(posedge clk) begin
    if (contador == 23'b11111111111111111111111)
        contador <= 23'b00000000000000000000000;
    else
        contador <= contador + 1;

end

assign clk_1s = contador[22];
assign clk_5ms = contador[14];

endmodule