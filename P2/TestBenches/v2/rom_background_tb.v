`timescale 1ns/1ps
module rom_background_tb;
    reg [4:0] x_tile;
    reg [4:0] y_tile;
    wire [2:0] bg_color_palette;

    rom_background dut (
        .x_tile(x_tile),
        .y_tile(y_tile),
        .bg_color_palette(bg_color_palette)
    );

    task test_case;
        input [4:0] x;
        input [4:0] y;
        begin
            x_tile = x;
            y_tile = y;
            #2;
            $display("x=%0d y=%0d bg=%0d", x, y, bg_color_palette);
        end
    endtask

    initial begin
        $dumpfile("rom_background_tb.vcd");
        $dumpvars(0, rom_background_tb);

        test_case(5'd0, 5'd0);
        test_case(5'd1, 5'd0);
        test_case(5'd0, 5'd1);
        test_case(5'd10, 5'd7);
        test_case(5'd19, 5'd14);
        $finish;
    end
endmodule
