`timescale 1ns/1ps
module rom_palette_tb;

    reg [2:0] id_palette;        // ID da cor desejada
    wire [23:0] color;             // 24 bits de cor  
    
    rom_palette dut (
        .id_palette(id_palette),
        .color(color)
    );
    
    integer i;
    
    initial begin
        $dumpfile("rom_palette_tb.vcd");
        $dumpvars(0, rom_palette_tb);

        $monitor ("Time: %0t | ID: %0d | Color: %h", $time, id_palette, color);
        // Testando todas as cores
        for (i = 0; i < 8; i = i + 1) begin
            id_palette = i;
            #1; // Espera 1 ciclo para atualizar o display
            $display("ID: %0d, Color: %h", id_palette, color);
            #9;
        end
        
        $finish;
    end
endmodule