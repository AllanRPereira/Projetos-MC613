`timescale 1ns/1ps

// Entradas
module caixa_registradora_tb;
reg test_clk = 0;
reg test_reset;
reg test_salvar_valor;
reg test_diminuir_valor;
reg [10:0] test_valor_produto;
reg [5:0] test_valores;
reg test_sinal_troco;

// Saida
wire signed [11:0] test_valor;

caixa_registradora uut(
    .clk (test_clk),
    .reset (test_reset),
    .salvar_valor (test_salvar_valor),
    .diminuir_valor (test_diminuir_valor),
    .valor_produto (test_valor_produto),
    .valores (test_valores),
    .sinal_troco (test_sinal_troco),
    .valor (test_valor)
);

always #10 test_clk = ~test_clk;

initial begin
    $dumpfile("caixa_registradora_tb.vcd");
    $dumpvars(0, caixa_registradora_tb);
    
    // Testar os valores iniciais
    test_salvar_valor = 0;
    test_reset = 0;
    test_diminuir_valor = 0;
    test_valores = 6'b000000;
    test_valor_produto = 11'b00000000000;
    test_sinal_troco = 0;

    // $display mostra texto no console do simulador
    $display("Iniciando teste da Caixa Registradora");
    $display("Tempo | Rst | Salva | Produto | Subtrai | Chaves | Troco |  VALOR (Saida) ");
    $display("------|-----|-------|---------|---------|--------|-------|----------------");


    // Teste 1, testando o modulo reset

    test_reset = 1; #20;
    $display("%5t |  %b  |   %b   |   %4d  |    %b    | %6b |   %b   | %4d (Reset)", 
        $time, test_reset, test_salvar_valor, test_valor_produto, test_diminuir_valor, test_valores, test_sinal_troco, test_valor);
    test_reset = 0; #20;

    // Teste 2: salvar valor inicial de 500
    test_valor_produto = 500; test_salvar_valor = 1; #20;
    $display("%5t |  %b  |   %b   |   %4d  |    %b    | %6b |   %b   | %4d (salvar valor de 500)", 
        $time, test_reset, test_salvar_valor, test_valor_produto, test_diminuir_valor, test_valores, test_sinal_troco, test_valor);
    test_salvar_valor = 0; #20;

    // Teste 3: diminuir valor de 5 centavos Sw[4]
    test_valores = 6'b000001; test_diminuir_valor = 1; #20;
    $display("%5t |  %b  |   %b   |   %4d  |    %b    | %6b |   %b   | %4d (diminuir valor de 5)", 
        $time, test_reset, test_salvar_valor, test_valor_produto, test_diminuir_valor, test_valores, test_sinal_troco, test_valor);
    test_valores = 6'b000000; test_diminuir_valor = 0; #20;

// Teste 4: diminuir valor de 10 centavos Sw[5]
    test_valores = 6'b000010; test_diminuir_valor = 1; #20;
    $display("%5t |  %b  |   %b   |   %4d  |    %b    | %6b |   %b   | %4d (diminuir valor de 10)", 
             $time, test_reset, test_salvar_valor, test_valor_produto, test_diminuir_valor, test_valores, test_sinal_troco, test_valor);
    test_diminuir_valor = 0;  test_valores = 6'b000000; #20;

    // Teste 5: bloquear as chaves, apertando mais de uma Sw[4] e Sw[5]
    test_valores = 6'b000011; test_diminuir_valor = 1; #20;
    $display("%5t |  %b  |   %b   |   %4d  |    %b    | %6b |   %b   | %4d (bloquea os valores)", 
             $time, test_reset, test_salvar_valor, test_valor_produto, test_diminuir_valor, test_valores, test_sinal_troco, test_valor);
    test_diminuir_valor = 0;  test_valores = 6'b000000; #20;

    // Teste 6: salva novo valor de 100
    test_valor_produto = 100; test_salvar_valor = 1; #20;
    $display("%5t |  %b  |   %b   |   %4d  |    %b    | %6b |   %b   | %4d (salva 100)", 
             $time, test_reset, test_salvar_valor, test_valor_produto, test_diminuir_valor, test_valores, test_sinal_troco, test_valor);
    test_salvar_valor = 0; #20;

    // Teste 7: subtrair 200 centavos
    test_valores = 6'b100000; test_diminuir_valor = 1; #20;
    $display("%5t |  %b  |   %b   |   %4d  |    %b    | %6b |   %b   | %4d (subtrai 200 pra fica negativo)", 
             $time, test_reset, test_salvar_valor, test_valor_produto, test_diminuir_valor, test_valores, test_sinal_troco, test_valor);
    test_diminuir_valor = 0;  test_valores = 6'b000000; #20;

    // Teste 8: inverte sinal do troco
    test_sinal_troco = 1; #20;

    $display("%5t |  %b  |   %b   |   %4d  |    %b    | %6b |   %b   | %4d (inverte troco)", 
             $time, test_reset, test_salvar_valor, test_valor_produto, test_diminuir_valor, test_valores, test_sinal_troco, test_valor);
    test_sinal_troco = 0; #20;


    $display("---------------------------------------");
    $display("Teste concluído");
    $finish;  // Termina a simulação
end


endmodule