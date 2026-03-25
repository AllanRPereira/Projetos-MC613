module maquina_vendas(
	input wire [9:0] SW,
	input wire [2:0] KEY,
	input wire CLOCK_50,
	
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
wire [10:0] preco_produto;
wire sinal_led_apagado;

reg [2:0] keys = 0;
reg [9:0] switchs = 0;
reg clk_1s = 0;
reg clk_5ms = 0;


clock Clock(
    .clk(CLOCK_50),
    .clk_1s(clk_1s),
    .clk_5ms(clk_5ms)
);

maquina_controle MaquinaControle(
    .clk(CLOCK_50),
    .reset(key_2),
    .sinal_cancelamento(sinal_cancelamento),
    .sinal_liberacao(sinal_liberacao),
    .sinal_troco(sinal_troco),
    .sinal_led_apagado(sinal_led_apagado),
    .led_liberado(LEDR0),
    .led_cancelado_troco(LEDR1)
);

maquina_estados MaquinaEstados(
    .clk(CLOCK_50),
    .clk_1s(clk_1s),
    .reset(key_2),
    .chave_cancelado(key_1),
    .chave_avancar(key_0),
    .switch_valor(switchs[9:4]),
    .valor(valor_produto),
    .travar_selecao(travar_selecao),
    .salvar_valor(salvar_valor),
    .diminuir_valor(diminuir_valor),
    .sinal_liberacao(sinal_liberacao),
    .sinal_troco(sinal_troco),
    .sinal_cancelamento(sinal_cancelamento),
    .sinal_led_apagado(sinal_led_apagado)
);

selecao_produto SelecaoProduto(
    .clk(CLOCK_50),
    .reset(key_2),
    .sw(switchs[3:0]),
    .travar_selecao(travar_selecao),
    .hex_display_5(HEX5),
    .valor_produto(preco_produto)
);

caixa_registradora CaixaRegistradora(
    .clk(CLOCK_50),
    .reset(key_2),
    .salvar_valor(salvar_valor),
    .valor_produto(preco_produto),
    .diminuir_valor(diminuir_valor),
    .valores(switchs[9:4]),
    .valor(valor_produto),
    .sinal_troco(sinal_troco)
);

conversao_valor ConversaoValor(
    .clk(CLOCK_50),
    .reset(key_2),
    .bin(valor_produto[10:0]),
    .display_0(HEX0),
    .display_1(HEX1),
    .display_2(HEX2),
    .display_3(HEX3)
);

always @(posedge clk_5ms) begin
    keys <= KEY[2:0];
    switchs <= SW[9:0];
end

endmodule