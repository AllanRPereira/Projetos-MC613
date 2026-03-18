module maquina_vendas (
	input wire [6:0] SW,
	input wire [1:0] KEY,
	input wire CLOCK_50,
	
	output wire [6:0] HEX5
);

reg EXIBIR_DISPLAY = 1;
reg [6:0] DISPLAY_HEX5;
reg [6:0] DISPLAY_HEX5_SAVE;

escolher_produto SeletorProdutos(
	.SW(SW[3:0]),
	.HEX_DISPLAY(DISPLAY_HEX5)

);

assign HEX5 = DISPLAY_HEX5_SAVE;

always @(posedge CLK) begin
	if (EXIBIR_DISPLAY)
		DISPLAY_HEX5_SAVE <= DISPLAY_HEX5;
		EXIBIR_DISPLAY <= 0;

	if (KEY[0] && REG_SALVAR == 1)
		REG_SALVAR <= 0;
	else
		if (RESET)
			REG_SALVAR <= 1;
end
