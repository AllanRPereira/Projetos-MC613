module maquina_vendas (
	input wire [6:0] SW,
	input wire [1:0] KEY,
	input wire CLOCK_50,
	
	output wire [6:0] HEX0
);

escolher_produto SeletorProdutos(
	.CLK(CLOCK_50),
	.KEY(KEY[0]),
	.RESET(KEY[1]),
	.SW(SW[3:0]),
	.DIG_7_PRODUTO(HEX0)

);

registrador RegistradorValor (
	.SALVAR(REG_SALVAR),
	.VAL_SALVAR(VALOR_PRODUTO)
);

always @(posedge CLK) begin
	if (REG_SALVAR)
		PRODUTO_SELECIONADO <= HEX_DISPLAY;

	if (KEY[0] && REG_SALVAR == 1)
		REG_SALVAR <= 0;
	else
		if (RESET)
			REG_SALVAR <= 1;
end
