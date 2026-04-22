`timescale 1ns/1ps
module rom_palette_tb;
    reg [2:0] id_palette;
    wire [23:0] color;

    rom_palette dut (
        .id_palette(id_palette),
        .color(color)
    );

    integer i;

    initial begin
        $dumpfile("rom_palette_tb.vcd");
        $dumpvars(0, rom_palette_tb);

        id_palette = 3'd0;
        #5;
        for (i = 0; i < 8; i = i + 1) begin
            id_palette = i[2:0];
            #5;
            $display("palette=%0d color=%h", id_palette, color);
        end

        $finish;
    end
endmodule
