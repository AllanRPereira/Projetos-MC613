`timescale 1ns/1ps
module fruta_controlador_tb;
    reg clk;
    reg reset;
    reg [3:0] estado_atual;
    reg nova_fruta;
    reg [4:0] probe_id_sprite;
    wire [8:0] probe_addr;
    wire [4:0] fruta_x_tile;
    wire [4:0] fruta_y_tile;
    wire fruta_ativa;
    wire sig_write_ram;
    wire [8:0] ram_addr;
    wire [4:0] sprite_in;

    fruta_controlador dut (
        .clk(clk),
        .reset(reset),
        .estado_atual(estado_atual),
        .nova_fruta(nova_fruta),
        .probe_id_sprite(probe_id_sprite),
        .probe_addr(probe_addr),
        .fruta_x_tile(fruta_x_tile),
        .fruta_y_tile(fruta_y_tile),
        .fruta_ativa(fruta_ativa),
        .sig_write_ram(sig_write_ram),
        .ram_addr(ram_addr),
        .sprite_in(sprite_in)
    );

    always #5 clk = ~clk;

    task tick;
        begin
            @(posedge clk);
            #1;
            @(negedge clk);
        end
    endtask

    initial begin
        $dumpfile("fruta_controlador_tb.vcd");
        $dumpvars(0, fruta_controlador_tb);

        clk = 0;
        reset = 1;
        estado_atual = 4'd0;
        nova_fruta = 0;
        probe_id_sprite = 5'd0;
        tick();
        reset = 0;

        estado_atual = 4'd1;
        probe_id_sprite = 5'd1;
        tick();
        $display("busca addr=%0d ativa=%b", probe_addr, fruta_ativa);

        probe_id_sprite = 5'd0;
        tick();
        $display("fruta=(%0d,%0d) ativa=%b write=%b addr=%0d sprite=%0d", fruta_x_tile, fruta_y_tile, fruta_ativa, sig_write_ram, ram_addr, sprite_in);

        nova_fruta = 1;
        tick();
        nova_fruta = 0;
        probe_id_sprite = 5'd0;
        tick();
        $display("nova fruta=(%0d,%0d) ativa=%b", fruta_x_tile, fruta_y_tile, fruta_ativa);

        $finish;
    end
endmodule
