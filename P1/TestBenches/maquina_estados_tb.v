`timescale 1ns / 1ps

module maquina_estados_tb;

    reg clk;
    reg clk_1s;
    reg reset;
    reg chave_cancelado;
    reg chave_avancar;
    reg [5:0] switch_valor;
    reg [3:0] product_sel;

    wire signed [11:0] valor;
    wire [10:0] valor_produto;
    wire [6:0] hex_display_5;

    wire travar_selecao;
    wire salvar_valor;
    wire diminuir_valor;
    wire sinal_liberacao;
    wire sinal_troco;
    wire sinal_cancelamento;
    wire sinal_led_apagado;

    integer errors;

    maquina_estados uut (
        .clk(clk),
        .clk_1s(clk_1s),
        .reset(reset),
        .chave_cancelado(chave_cancelado),
        .chave_avancar(chave_avancar),
        .switch_valor(switch_valor),
        .valor(valor),
        .travar_selecao(travar_selecao),
        .salvar_valor(salvar_valor),
        .diminuir_valor(diminuir_valor),
        .sinal_liberacao(sinal_liberacao),
        .sinal_troco(sinal_troco),
        .sinal_cancelamento(sinal_cancelamento),
        .sinal_led_apagado(sinal_led_apagado)
    );

    selecao_produto selecao (
        .clk(clk),
        .reset(reset),
        .sw(product_sel),
        .travar_selecao(travar_selecao),
        .hex_display_5(hex_display_5),
        .valor_produto(valor_produto)
    );

    caixa_registradora caixa (
        .clk(clk),
        .reset(reset),
        .salvar_valor(salvar_valor),
        .valor_produto(valor_produto),
        .diminuir_valor(diminuir_valor),
        .valores(switch_valor),
        .sinal_troco(sinal_troco),
        .valor(valor)
    );

    initial begin
        $dumpfile("maquina_estados_tb.vcd");
        $dumpvars(0, maquina_estados_tb);

        clk = 0;
        clk_1s = 0;
        reset = 1;
        chave_cancelado = 0;
        chave_avancar = 0;
        switch_valor = 6'b0;
        product_sel = 4'b0000;
        errors = 0;

        #20;
        reset = 0;

        // Estado 000: escolha do produto
        @(posedge clk);
        #1;
        check_outputs("000 - escolha do produto", 0, 0, 0, 0, 0, 0, 1);

        // Avança para produto selecionado (estado 001)
        chave_avancar = 1;
        @(posedge clk);
        #1;
        chave_avancar = 0;
        @(posedge clk);
        #1;
        check_outputs("001 - produto selecionado", 1, 1, 0, 0, 0, 0, 1);

        // Inserir 100 centavos e ir para dinheiro inserido (010)
        switch_valor = 6'b010000; // 100
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        check_outputs("010 - dinheiro inserido após 100", 1, 0, 1, 0, 0, 0, 1);
        @(posedge clk);
        #1;
        switch_valor = 6'b000000;

        // Avançar enquanto ainda há saldo positivo (volta para 001)
        chave_avancar = 1;
        @(posedge clk);
        #1;
        chave_avancar = 0;
        @(posedge clk);
        #1;
        check_outputs("001 - retorno após inserir 100", 1, 0, 0, 0, 0, 0, 1);

        // Inserir 25 centavos e ir para dinheiro inserido novamente
        switch_valor = 6'b001000; // 25
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        check_outputs("010 - dinheiro inserido após 25", 1, 0, 1, 0, 0, 0, 1);
        @(posedge clk);
        #1;
        switch_valor = 6'b000000;
        @(posedge clk);
        #1;

        // Avançar com valor zerado para completar compra (011)
        chave_avancar = 1;
        @(posedge clk);
        #1;
        chave_avancar = 0;
        @(posedge clk);
        #1;
        check_outputs("011 - produto comprado", 1, 0, 0, 1, 1, 0, 0);

        // Aguarda 1s para retornar ao estado 000
        clk_1s = 1;
        @(posedge clk);
        #1;
        clk_1s = 0;
        @(posedge clk);
        #1;
        check_outputs("000 - volta após compra", 0, 0, 0, 0, 0, 0, 1);

        // Avança para selecionar outro produto e cancela
        produto_selecao(4'b0001);
        chave_avancar = 1;
        @(posedge clk);
        #1;
        chave_avancar = 0;
        @(posedge clk);
        #1;
        check_outputs("001 - seleciona produto para cancelar", 1, 1, 0, 0, 0, 0, 1);

        chave_cancelado = 1;
        @(posedge clk);
        #1;
        chave_cancelado = 0;
        @(posedge clk);
        #1;
        check_outputs("100 - compra cancelada", 0, 0, 0, 0, 0, 1, 0);

        clk_1s = 1;
        @(posedge clk);
        #1;
        clk_1s = 0;
        @(posedge clk);
        #1;
        check_outputs("000 - volta após cancelamento", 0, 0, 0, 0, 0, 0, 1);

        if (errors == 0) begin
            $display("\nALL TESTS PASSED");
        end else begin
            $display("\nTESTS FAILED with %0d errors", errors);
        end

        $finish;
    end

    always #5 clk = ~clk;

    task produto_selecao;
        input [3:0] value;
        begin
            product_sel = value;
        end
    endtask

    task check_outputs;
        input [256:0] message;
        input expected_travar;
        input expected_salvar;
        input expected_diminuir;
        input expected_troco;
        input expected_liberacao;
        input expected_cancelamento;
        input expected_led;
        begin
            if (travar_selecao !== expected_travar ||
                salvar_valor !== expected_salvar ||
                diminuir_valor !== expected_diminuir ||
                sinal_troco !== expected_troco ||
                sinal_liberacao !== expected_liberacao ||
                sinal_cancelamento !== expected_cancelamento ||
                sinal_led_apagado !== expected_led) begin
                $display("ERROR: %s - outputs mismatch", message);
                $display("  got travar=%b salvar=%b diminuir=%b troco=%b liberar=%b cancel=%b led=%b",
                         travar_selecao, salvar_valor, diminuir_valor,
                         sinal_troco, sinal_liberacao, sinal_cancelamento,
                         sinal_led_apagado);
                $display("  expected travar=%b salvar=%b diminuir=%b troco=%b liberar=%b cancel=%b led=%b",
                         expected_travar, expected_salvar, expected_diminuir,
                         expected_troco, expected_liberacao, expected_cancelamento,
                         expected_led);
                errors = errors + 1;
            end else begin
                $display("PASS : %s", message);
            end
        end
    endtask

endmodule
