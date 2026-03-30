`timescale 1ns/1ps

module maquina_controle_tb;

reg clk;
reg reset;
reg sinal_cancelamento;
reg sinal_liberacao;
reg sinal_troco;
reg sinal_led_apagado;

wire led_liberado;
wire led_cancelado_troco;

integer erros;

maquina_controle uut (
    .clk(clk),
    .reset(reset),
    .sinal_cancelamento(sinal_cancelamento),
    .sinal_liberacao(sinal_liberacao),
    .sinal_troco(sinal_troco),
    .sinal_led_apagado(sinal_led_apagado),
    .led_liberado(led_liberado),
    .led_cancelado_troco(led_cancelado_troco)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    reset = 1;
    sinal_cancelamento = 0;
    sinal_liberacao = 0;
    sinal_troco = 0;
    sinal_led_apagado = 0;
    erros = 0;

    $display("=== Teste: maquina_controle ===");

    @(posedge clk);
    #1;
    if (led_liberado !== 0 || led_cancelado_troco !== 0) begin
        $display("[ERRO] Reset nao limpou LEDs.");
        erros = erros + 1;
    end else begin
        $display("[OK] Reset limpa LEDs");
    end

    reset = 0;
    sinal_liberacao = 1;
    @(posedge clk);
    #1;
    if (led_liberado !== 1) begin
        $display("[ERRO] LED liberado nao acendeu.");
        erros = erros + 1;
    end else begin
        $display("[OK] Liberacao acende LEDR0");
    end
    sinal_liberacao = 0;

    sinal_troco = 1;
    @(posedge clk);
    #1;
    if (led_cancelado_troco !== 1) begin
        $display("[ERRO] LED cancelado/troco nao acendeu com troco.");
        erros = erros + 1;
    end else begin
        $display("[OK] Troco acende LEDR1");
    end
    sinal_troco = 0;

    sinal_led_apagado = 1;
    @(posedge clk);
    #1;
    if (led_liberado !== 0 || led_cancelado_troco !== 0) begin
        $display("[ERRO] sinal_led_apagado nao limpou LEDs.");
        erros = erros + 1;
    end else begin
        $display("[OK] sinal_led_apagado limpa LEDs");
    end
    sinal_led_apagado = 0;

    sinal_cancelamento = 1;
    @(posedge clk);
    #1;
    if (led_cancelado_troco !== 1) begin
        $display("[ERRO] Cancelamento nao acendeu LEDR1.");
        erros = erros + 1;
    end else begin
        $display("[OK] Cancelamento acende LEDR1");
    end

    if (erros == 0)
        $display("RESULTADO: TODOS OS TESTES PASSARAM");
    else
        $display("RESULTADO: %0d teste(s) falharam", erros);

    $finish;
end

endmodule
