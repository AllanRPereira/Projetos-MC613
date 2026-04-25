`timescale 1ns/1ps
module color_selector_tb;
    reg [2:0] sprite_color_idx;
    reg [2:0] bg_color_idx;
    wire [7:0] red;
    wire [7:0] green;
    wire [7:0] blue;

    color_selector dut (
        .sprite_color_idx(sprite_color_idx),
        .bg_color_idx(bg_color_idx),
        .red(red),
        .green(green),
        .blue(blue)
    );

    initial begin
        $dumpfile("color_selector_tb.vcd");
        $dumpvars(0, color_selector_tb);

        sprite_color_idx = 3'd0; bg_color_idx = 3'd1; #5;
        $display("bg only RGB=%h_%h_%h", red, green, blue);

        sprite_color_idx = 3'd2; bg_color_idx = 3'd1; #5;
        $display("sprite priority RGB=%h_%h_%h", red, green, blue);

        sprite_color_idx = 3'd0; bg_color_idx = 3'd7; #5;
        $display("bg high RGB=%h_%h_%h", red, green, blue);

        $finish;
    end
endmodule
