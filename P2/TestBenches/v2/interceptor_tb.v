`timescale 1ns/1ps
module interceptor_tb;
    reg [9:0] x;
    reg [9:0] y;
    reg [11:0] bitmap_sprite_palette;
    wire [2:0] sprite_palette;

    interceptor dut (
        .x(x),
        .y(y),
        .bitmap_sprite_palette(bitmap_sprite_palette),
        .sprite_palette(sprite_palette)
    );

    task test_case;
        input [9:0] px;
        input [9:0] py;
        begin
            x = px;
            y = py;
            #1;
            $display("x=%0d y=%0d sprite_palette=%0d", px, py, sprite_palette);
        end
    endtask

    initial begin
        $dumpfile("interceptor_tb.vcd");
        $dumpvars(0, interceptor_tb);

        bitmap_sprite_palette = 12'b001_010_011_100;
        test_case(10'd0, 10'd0);
        test_case(10'd16, 10'd0);
        test_case(10'd0, 10'd16);
        test_case(10'd16, 10'd16);
        $finish;
    end
endmodule
