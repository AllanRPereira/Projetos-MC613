`timescale 1ns/1ps

module caixa_registradora_tb;

reg clk;
reg reset;
reg salvar_valor;
reg [10:0] valor_produto;
reg diminuir_valor;
reg [5:0] valores;
reg sinal_troco;

wire signed [11:0] valor;

integer erros;

caixa_registradora uut (
    .clk(clk),
    .reset(reset),
    .salvar_valor(salvar_valor),
    .valor_produto(valor_produto),
    .diminuir_valor(diminuir_valor),
    .valores(valores),
    .sinal_troco(sinal_troco),
    .valor(valor)
);

always #5 clk = ~clk;

initial begin
    $dumpfile("caixa_registradora.vcd");
    $dumpvars(0, caixa_registradora_tb);

    clk = 0;
    reset = 1;
    salvar_valor = 0;
    valor_produto = 11'd0;
    diminuir_valor = 0;
    valores = 6'b000000;
    sinal_troco = 0;
    erros = 0;

    $display("=== Inicio do teste: caixa_registradora ===");

    // Libera reset
    @(posedge clk);
    reset = 0;

    // Teste 1: salva valor do produto
    valor_produto = 11'd150;
    salvar_valor = 1;
    @(posedge clk);
    #1;
    if (valor !== 12'sd150) begin
        $display("[ERRO] Teste 1 falhou. Esperado=150, obtido=%0d", valor);
        erros = erros + 1;
    end else begin
        $display("[OK] Teste 1: salvar valor");
    end
    salvar_valor = 0;

    // Teste 2: subtrai uma vez com uma unica chave (50)
    valores = 6'b001000;
    diminuir_valor = 1;
    @(posedge clk);
    #1;
    if (valor !== 12'sd100) begin
        $display("[ERRO] Teste 2 falhou. Esperado=100, obtido=%0d", valor);
        erros = erros + 1;
    end else begin
        $display("[OK] Teste 2: subtracao unica");
    end

    // Teste 3: com diminuir_valor ainda ativo, nao deve subtrair de novo
    @(posedge clk);
    #1;
    if (valor !== 12'sd100) begin
        $display("[ERRO] Teste 3 falhou. Esperado=100, obtido=%0d", valor);
        erros = erros + 1;
    end else begin
        $display("[OK] Teste 3: trava de subtracao funcionou");
    end

    // Rearma a logica de subtracao
    diminuir_valor = 0;
    @(posedge clk);
    valores = 6'b000000;
    @(posedge clk);

    // Teste 4: nova subtracao apos rearmar (5)
    valores = 6'b000001;
    diminuir_valor = 1;
    @(posedge clk);
    #1;
    if (valor !== 12'sd95) begin
        $display("[ERRO] Teste 4 falhou. Esperado=95, obtido=%0d", valor);
        erros = erros + 1;
    end else begin
        $display("[OK] Teste 4: nova subtracao apos rearmar");
    end

    diminuir_valor = 0;
    valores = 6'b000000;
    @(posedge clk);

    // Teste 5: mais de uma chave ativa bloqueia subtracao
    valores = 6'b000011;
    diminuir_valor = 1;
    @(posedge clk);
    #1;
    if (valor !== 12'sd95) begin
        $display("[ERRO] Teste 5 falhou. Esperado=95, obtido=%0d", valor);
        erros = erros + 1;
    end else begin
        $display("[OK] Teste 5: bloqueio por multiplas chaves");
    end

    diminuir_valor = 0;
    valores = 6'b000000;
    @(posedge clk);

    // Teste 6: gera valor negativo e aplica troco
    valor_produto = 11'd20;
    salvar_valor = 1;
    @(posedge clk);
    #1;
    salvar_valor = 0;

    valores = 6'b001000;
    diminuir_valor = 1;
    @(posedge clk);
    #1;
    if (valor !== -12'sd30) begin
        $display("[ERRO] Teste 6 falhou (negativo). Esperado=-30, obtido=%0d", valor);
        erros = erros + 1;
    end else begin
        $display("[OK] Teste 6: valor negativo gerado");
    end

    diminuir_valor = 0;
    valores = 6'b000000;
    @(posedge clk);

    // Teste 7: aplica troco (valor absoluto) apenas uma vez por acionamento
    sinal_troco = 1;
    @(posedge clk);
    #1;
    if (valor !== 12'sd30) begin
        $display("[ERRO] Teste 7 falhou (troco). Esperado=30, obtido=%0d", valor);
        erros = erros + 1;
    end else begin
        $display("[OK] Teste 7: troco aplicado");
    end

    @(posedge clk);
    #1;
    if (valor !== 12'sd30) begin
        $display("[ERRO] Teste 8 falhou. Esperado=30, obtido=%0d", valor);
        erros = erros + 1;
    end else begin
        $display("[OK] Teste 8: troco nao reaplicado indevidamente");
    end

    sinal_troco = 0;
    @(posedge clk);

    // Teste 9: reset limpa saida
    reset = 1;
    @(posedge clk);
    #1;
    if (valor !== 12'sd0) begin
        $display("[ERRO] Teste 9 falhou (reset). Esperado=0, obtido=%0d", valor);
        erros = erros + 1;
    end else begin
        $display("[OK] Teste 9: reset");
    end

    $display("=== Fim do teste ===");
    if (erros == 0)
        $display("RESULTADO: TODOS OS TESTES PASSARAM");
    else
        $display("RESULTADO: %0d teste(s) falharam", erros);

    $finish;
end

endmodule
