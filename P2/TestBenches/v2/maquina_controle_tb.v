`timescale 1ns/1ps
module maquina_controle_tb;
    reg clk;
    reg reset;
    reg clk_5ms;
    reg clk_100ms;
    reg clk_2s;
    reg botao_confirmar;
    reg botao_1;
    reg botao_2;
    reg [3:0] estado_atual;
    reg comeu_fruta;
    reg bateu_corpo;
    reg bateu_parede;
    reg cobra_cheia;

    wire sig_fruta;
    wire sig_mordida;
    wire sig_5ms;
    wire sig_2s;
    wire sig_batida;
    wire sig_confirmar;
    wire sig_vel;
    wire sig_dir;
    wire sig_vit;
    wire [1:0] direcao_atual;
    wire [7:0] frutas_comidas;
    wire [2:0] nivel_velocidade;
    wire [9:0] pontos;

    maquina_controle dut (
        .clk(clk),
        .reset(reset),
        .clk_5ms(clk_5ms),
        .clk_100ms(clk_100ms),
        .clk_2s(clk_2s),
        .botao_confirmar(botao_confirmar),
        .botao_1(botao_1),
        .botao_2(botao_2),
        .estado_atual(estado_atual),
        .comeu_fruta(comeu_fruta),
        .bateu_corpo(bateu_corpo),
        .bateu_parede(bateu_parede),
        .cobra_cheia(cobra_cheia),
        .sig_fruta(sig_fruta),
        .sig_mordida(sig_mordida),
        .sig_5ms(sig_5ms),
        .sig_2s(sig_2s),
        .sig_batida(sig_batida),
        .sig_confirmar(sig_confirmar),
        .sig_vel(sig_vel),
        .sig_dir(sig_dir),
        .sig_vit(sig_vit),
        .direcao_atual(direcao_atual),
        .frutas_comidas(frutas_comidas),
        .nivel_velocidade(nivel_velocidade),
        .pontos(pontos)
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
        $dumpfile("maquina_controle_tb.vcd");
        $dumpvars(0, maquina_controle_tb);

        clk = 0;
        reset = 1;
        clk_5ms = 0;
        clk_100ms = 0;
        clk_2s = 0;
        botao_confirmar = 0;
        botao_1 = 0;
        botao_2 = 0;
        estado_atual = 4'd0;
        comeu_fruta = 0;
        bateu_corpo = 0;
        bateu_parede = 0;
        cobra_cheia = 0;

        tick();
        reset = 0;

        estado_atual = 4'd1;
        clk_100ms = 1;
        botao_1 = 1;
        tick();
        clk_100ms = 0;
        botao_1 = 0;
        $display("dir=%0d", direcao_atual);

        comeu_fruta = 1;
        tick();
        comeu_fruta = 0;
        $display("frutas=%0d pontos=%0d vel=%0d", frutas_comidas, pontos, nivel_velocidade);

        repeat (4) begin
            comeu_fruta = 1;
            tick();
            comeu_fruta = 0;
            tick();
        end
        $display("apos 5 frutas vel=%0d sig_vel=%b", nivel_velocidade, sig_vel);

        $finish;
    end
endmodule
