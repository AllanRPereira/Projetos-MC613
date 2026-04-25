`timescale 1ns/1ps
module VGA_tb;
    reg pixel_clk;
    reg reset;
    reg [7:0] r_in;
    reg [7:0] g_in;
    reg [7:0] b_in;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire video_active;
    wire [7:0] VGA_R;
    wire [7:0] VGA_G;
    wire [7:0] VGA_B;
    wire VGA_HS;
    wire VGA_VS;
    wire VGA_BLANK_N;
    wire VGA_SYNC_N;
    wire VGA_CLK;

    VGA dut (
        .pixel_clk(pixel_clk),
        .reset(reset),
        .r_in(r_in),
        .g_in(g_in),
        .b_in(b_in),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_active(video_active),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

    always #10 pixel_clk = ~pixel_clk;

    initial begin
        $dumpfile("VGA_tb.vcd");
        $dumpvars(0, VGA_tb);

        pixel_clk = 0;
        reset = 1;
        r_in = 0;
        g_in = 0;
        b_in = 0;
        #50;
        reset = 0;
        repeat (20) begin
            @(posedge pixel_clk);
            r_in = 8'hAA;
            g_in = 8'h55;
            b_in = 8'h11;
        end
        $display("x=%0d y=%0d active=%b hs=%b vs=%b", pixel_x, pixel_y, video_active, VGA_HS, VGA_VS);
        $finish;
    end
endmodule
