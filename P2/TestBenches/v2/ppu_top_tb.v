`timescale 1ns/1ps
module pll(
    input wire refclk,
    input wire rst,
    output wire outclk_0,
    output wire locked
);
    assign outclk_0 = refclk;
    assign locked = ~rst;
endmodule

module ppu_top_tb;
    reg CLOCK_50;
    reg [3:0] KEY;
    reg [3:0] SW;
    wire [7:0] VGA_R;
    wire [7:0] VGA_G;
    wire [7:0] VGA_B;
    wire VGA_HS;
    wire VGA_VS;
    wire VGA_BLANK_N;
    wire VGA_SYNC_N;
    wire VGA_CLK;
    wire [1:0] LEDR;

    ppu_top dut (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(SW),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK),
        .LEDR(LEDR)
    );

    always #10 CLOCK_50 = ~CLOCK_50;

    initial begin
        $dumpfile("ppu_top_tb.vcd");
        $dumpvars(0, ppu_top_tb);

        CLOCK_50 = 0;
        KEY = 4'b1111;
        SW = 4'b0000;
        #50;

        KEY[0] = 0;
        #50;
        KEY[0] = 1;
        SW = 4'b0011;
        #200;

        KEY[1] = 0;
        #50;
        KEY[1] = 1;
        #500;

        $display("LEDR=%b VGA=(%h,%h,%h) HS=%b VS=%b", LEDR, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS);
        $finish;
    end
endmodule
