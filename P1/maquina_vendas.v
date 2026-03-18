module maquina_vendas (
	input wire [6:0] SW,
	input wire [1:0] KEY,
	input wire CLOCK_50,
	
	output wire [6:0] HEX5
);

reg EXIBIR_DISPLAY = 1'b1;
reg [6:0] DISPLAY_HEX5_SAVE;
reg [10:0] VALOR_PRODUTO_SELECIONADO;
wire [10:0] w_VALOR_PRODUTO_SELECIONADO;
wire [6:0] DISPLAY_HEX5;

escolher_produto SeletorProdutos(
	.SW(SW[3:0]),
	.HEX_DISPLAY(DISPLAY_HEX5[6:0]),
	.VALOR_PRODUTO(w_VALOR_PRODUTO_SELECIONADO)

);

registrador Registrador(
	.CLK(CLOCK_50),
	.RESET(KEY[1]),
	.SIG_SALVAR(KEY[0]),
	.VAL_SALVAR(w_VALOR_PRODUTO_SELECIONADO)

);

assign HEX5 = DISPLAY_HEX5_SAVE;

always @(posedge CLOCK_50) begin
	if (EXIBIR_DISPLAY)
		DISPLAY_HEX5_SAVE <= DISPLAY_HEX5;

	if (KEY[0] && EXIBIR_DISPLAY == 1)
		EXIBIR_DISPLAY <= 0;
	else
		if (KEY[1])
			EXIBIR_DISPLAY <= 1;
end

endmodule
