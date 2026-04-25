`timescale 1ns/1ps
module cobra_crescimento_tb;
    reg clk;
    reg reset;
    reg [3:0] estado_atual;
    reg passo_movimento;
    reg [1:0] direcao_atual;
    reg fruta_ativa;
    reg [4:0] fruta_x_tile;
    reg [4:0] fruta_y_tile;

    wire comeu_fruta;
    wire bateu_corpo;
    wire bateu_parede;
    wire cobra_cheia;
    wire sig_write_ram;
    wire [8:0] ram_addr;
    wire [4:0] sprite_in;
    wire [4:0] cabeca_x;
    wire [4:0] cabeca_y;
    wire [4:0] cauda_x;
    wire [4:0] cauda_y;
    wire [8:0] comprimento;

    cobra_crescimento dut (
        .clk(clk),
        .reset(reset),
        .estado_atual(estado_atual),
        .passo_movimento(passo_movimento),
        .direcao_atual(direcao_atual),
        .fruta_ativa(fruta_ativa),
        .fruta_x_tile(fruta_x_tile),
        .fruta_y_tile(fruta_y_tile),
        .comeu_fruta(comeu_fruta),
        .bateu_corpo(bateu_corpo),
        .bateu_parede(bateu_parede),
        .cobra_cheia(cobra_cheia),
        .sig_write_ram(sig_write_ram),
        .ram_addr(ram_addr),
        .sprite_in(sprite_in),
        .cabeca_x(cabeca_x),
        .cabeca_y(cabeca_y),
        .cauda_x(cauda_x),
        .cauda_y(cauda_y),
        .comprimento(comprimento)
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
        $dumpfile("cobra_crescimento_tb.vcd");
        $dumpvars(0, cobra_crescimento_tb);

        clk = 0;
        reset = 1;
        estado_atual = 4'd0;
        passo_movimento = 0;
        direcao_atual = 2'd1;
        fruta_ativa = 0;
        fruta_x_tile = 0;
        fruta_y_tile = 0;
        tick();
        reset = 0;

        estado_atual = 4'd1;
        passo_movimento = 1;
        tick();
        passo_movimento = 0;
        tick();
        $display("move1 head=(%0d,%0d) len=%0d write=%b addr=%0d sprite=%0d", cabeca_x, cabeca_y, comprimento, sig_write_ram, ram_addr, sprite_in);

        fruta_ativa = 1;
        fruta_x_tile = 5'd2;
        fruta_y_tile = 5'd0;
        direcao_atual = 2'd1;
        passo_movimento = 1;
        tick();
        passo_movimento = 0;
        tick();
        $display("grow head=(%0d,%0d) len=%0d comeu=%b write=%b addr=%0d sprite=%0d", cabeca_x, cabeca_y, comprimento, comeu_fruta, sig_write_ram, ram_addr, sprite_in);

        $finish;
    end
endmodule
