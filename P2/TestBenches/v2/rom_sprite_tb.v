`timescale 1ns/1ps
module rom_sprite_tb;
    reg [4:0] id_sprite;
    wire [11:0] bitmap_sprite_palette;

    rom_sprite dut (
        .id_sprite(id_sprite),
        .bitmap_sprite_palette(bitmap_sprite_palette)
    );

    integer i;

    initial begin
        $dumpfile("rom_sprite_tb.vcd");
        $dumpvars(0, rom_sprite_tb);

        for (i = 0; i < 6; i = i + 1) begin
            id_sprite = i[4:0];
            #2;
            $display("sprite=%0d bitmap=%h", id_sprite, bitmap_sprite_palette);
        end

        id_sprite = 5'd31;
        #2;
        $display("sprite=%0d bitmap=%h", id_sprite, bitmap_sprite_palette);

        $finish;
    end
endmodule
