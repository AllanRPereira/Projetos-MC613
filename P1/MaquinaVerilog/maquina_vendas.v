module maquina_vendas(
	input wire [9:0] SW,
	input wire [2:0] KEY,
	input wire CLOCK_50,
	
	output wire [6:0] HEX5, HEX3, HEX2, HEX1, HEX0,
    output wire [1:0] LEDR

);

wire sinal_cancelamento;
wire sinal_liberacao;
wire sinal_troco;
wire travar_selecao;
wire salvar_valor;
wire diminuir_valor;
wire signed [11:0] valor_produto;
wire signed [11:0] valor_pos_sub;
wire [10:0] valor_display = valor_produto[11] ? (-valor_produto) : valor_produto;
wire [10:0] preco_produto;
wire sinal_led_apagado;

reg [2:0] keys = 0;
reg [9:0] switchs = 0;

// São "ticks" a cada 1s e 5ms respectivamente!
wire clk_1s;
wire clk_5ms;

reg [2:0] key_sync_0 = 0;
reg [2:0] key_sync_1 = 0;
reg [9:0] sw_sync_0 = 0;
reg [9:0] sw_sync_1 = 0;

reg [2:0] key_prev_sample = 0;
reg [9:0] sw_prev_sample = 0;


clock Clock(
    .clk(CLOCK_50),
    .clk_1s(clk_1s),
    .clk_5ms(clk_5ms)
);

maquina_controle MaquinaControle(
    .clk(CLOCK_50),
    .reset(~keys[2]),
    .sinal_cancelamento(sinal_cancelamento),
    .sinal_liberacao(sinal_liberacao),
    .sinal_troco(sinal_troco),
    .sinal_led_apagado(sinal_led_apagado),
    .led_liberado(LEDR[0]),
    .led_cancelado_troco(LEDR[1])
);

maquina_estados MaquinaEstados(
    .clk(CLOCK_50),
    .clk_1s(clk_1s),
    .reset(~keys[2]),
    .chave_cancelado(~keys[1]),
    .chave_avancar(~keys[0]),
    .switch_valor(switchs[9:4]),
    .valor(valor_pos_sub),
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
    .reset(~keys[2]),
    .sw(switchs[3:0]),
    .travar_selecao(travar_selecao),
    .hex_display_5(HEX5),
    .valor_produto(preco_produto)
);

caixa_registradora CaixaRegistradora(
    .clk(CLOCK_50),
    .reset(~keys[2]),
    .salvar_valor(salvar_valor),
    .valor_produto(preco_produto),
    .diminuir_valor(diminuir_valor),
    .valores(switchs[9:4]),
    .valor(valor_produto),
    .valor_pos_sub(valor_pos_sub),
    .sinal_troco(sinal_troco)
);

conversao_valor ConversaoValor(
    .clk(CLOCK_50),
    .reset(~keys[2]),
    .bin(valor_display),
    .display_0(HEX0),
    .display_1(HEX1),
    .display_2(HEX2),
    .display_3(HEX3)
);

always @(posedge CLOCK_50) begin
    // Estados para sincronização - Fila de valores salvos

    // Chaves
    key_sync_0 <= KEY;
    key_sync_1 <= key_sync_0;

    // Switches
    sw_sync_0 <= SW;
    sw_sync_1 <= sw_sync_0;

    // Debounce simples: aceita novo valor apenas se repetido em 2 amostras de 5ms.
    if (clk_5ms) begin
        if (key_sync_1 == key_prev_sample)
            keys <= key_sync_1;
        key_prev_sample <= key_sync_1;

        if (sw_sync_1 == sw_prev_sample)
            switchs <= sw_sync_1;
        sw_prev_sample <= sw_sync_1;
    end
end

endmodule