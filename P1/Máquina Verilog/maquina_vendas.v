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
    .clk_1(CLOCK_1),
    .reset(KEY[2]),
    .chave_cancelado(KEY[1]),
    .chave_avancar(KEY[0]),
    .switch_valor(SW[9:4])
);

endmodule