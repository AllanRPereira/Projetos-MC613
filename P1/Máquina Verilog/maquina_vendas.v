module maquina_vendas(
	input wire [9:0] SW,
	input wire [2:0] KEY,
	input wire CLOCK_50,
    input wire CLOCK_1,
	
	output wire [6:0] HEX5, HEX3, HEX2, HEX1, HEX0,
    output wire LEDR0, LEDR1

);

wire sinal_cancelamento;
wire sinal_liberacao;
wire sinal_troco;
wire travar_selecao;
wire salvar_valor;
wire diminuir_valor;
wire [11:0] valor_produto;

maquina_controle MaquinaControle(
    .clk(CLOCK_50),
    .reset(KEY[2]),
    .sinal_cancelamento(sinal_cancelamento),
    .sinal_liberacao(sinal_liberacao),
    .sinal_troco(sinal_troco),
    .led_liberado(LEDR0),
    .led_cancelado_troco(LEDR1)
);

maquina_estados MaquinaEstados(
    .clk(CLOCK_50),
    .clk_1s(CLOCK_1),
    .reset(KEY[2]),
    .chave_cancelado(KEY[1]),
    .chave_avancar(KEY[0]),
    .switch_valor(SW[9:4]),
    .valor(valor_produto),
    .travar_selecao(travar_selecao),
    .salvar_valor(salvar_valor),
    .diminuir_valor(diminuir_valor),
    .sinal_liberacao(sinal_liberacao),
    .sinal_troco(sinal_troco),
    .sinal_cancelamento(sinal_cancelamento)
);

selecao_produto SelecaoProduto(
    .clk(CLOCK_50),
    .reset(KEY[2]),
    .sw(SW[3:0]),
    .travar_selecao(travar_selecao),
    .hex_display_5(HEX5),
    .valor_produto(valor_produto[10:0])
);

caixa_registradora CaixaRegistradora(
    .clk(CLOCK_50),
    .reset(KEY[2]),
    .salvar_valor(salvar_valor),
    .valor_produto(valor_produto),
    .diminuir_valor(diminuir_valor),
    .valores(SW[9:4]),
    .valor(valor_produto)
);

conversao_valor ConversaoValor(
    .clk(CLOCK_50),
    .reset(KEY[2]),
    .bin(valor_produto[10:0]),
    .display_0(HEX0),
    .display_1(HEX1),
    .display_2(HEX2),
    .display_3(HEX3)
);

endmodule