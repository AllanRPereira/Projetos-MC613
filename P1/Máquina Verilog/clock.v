module clock(
    input wire clk,
    output reg clk_1s = 1'b0,
    output reg clk_5ms = 1'b0
);

reg [25:0] contador_1s = 0;
reg [17:0] contador_5ms = 0;

always @(posedge clk) begin
    // Pulses de 1 ciclo no dominio de 50 MHz.
    clk_1s <= 1'b0;
    clk_5ms <= 1'b0;

    if (contador_1s == 26'd49_999_999) begin
        contador_1s <= 26'd0;
        clk_1s <= 1'b1;
    end else begin
        contador_1s <= contador_1s + 1'b1;
    end

    if (contador_5ms == 18'd249_999) begin
        contador_5ms <= 18'd0;
        clk_5ms <= 1'b1;
    end else begin
        contador_5ms <= contador_5ms + 1'b1;
    end

end

endmodule