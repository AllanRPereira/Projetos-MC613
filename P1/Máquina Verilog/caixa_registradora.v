module caixa_registradora(
	input wire clk,
	input wire reset,
	input wire salvar_valor,				// Sinal para salvar o valor no registrador de saída
	input wire [10:0] valor_produto,		// Valor do produto
	input wire diminuir_valor,				// Sinal para subtrair o valor correspondente das chaves
	input wire [5:0] valores,				// Sinal dos SW's
	input wire sinal_troco,					// Sinal para inverter os bits e exibir corretamente

	output reg signed [11:0] valor,
	output wire signed [11:0] valor_pos_sub		// Valor prévio que será armazenado no FF após a subtração
);

reg [7:0] auxiliar = 0;			// Armazenar o valor que irá ser subtraído
reg lock_num_chave = 0;			// Trava para caso haja mais de uma chave acionada
reg subtraido = 0;				// Verificador para que subtraía apenas uma vez
reg troco_aplicado = 0;			// Garante aplicacao unica do troco

// Lógica combinacional, ou seja, em qualquer mudança no sinais de entrada, haverá atualização de auxiliar
always @(*) begin 
	lock_num_chave = (valores & (valores - 1)) != 0;		// Conta o Nº de bits ativos
	auxiliar = 0;
	if (valores[5]) auxiliar = auxiliar + 8'd200;
	if (valores[4]) auxiliar = auxiliar + 7'd100;
	if (valores[3]) auxiliar = auxiliar + 6'd50;
	if (valores[2]) auxiliar = auxiliar + 5'd25;
	if (valores[1]) auxiliar = auxiliar + 4'd10;
	if (valores[0]) auxiliar = auxiliar + 3'd5;

end

assign valor_pos_sub = valor - auxiliar;

always @(posedge clk) begin
	// Lógica para evitar subtrair mais de uma vez, ele desmarca o 
	// subtraído apenas quando saí do estado de diminuir o valor
	if (!diminuir_valor)
		subtraido <= 0;

	// Lógica análoga para o troco
	if (!sinal_troco)
		troco_aplicado <= 0;

	if (reset)
		valor <= 12'b00000000000;
	else
		if (salvar_valor)
			valor <= valor_produto;
		else if ((diminuir_valor && !subtraido) && !lock_num_chave) begin
			valor <= valor - auxiliar;
			subtraido <= 1;
		end
		else if (sinal_troco && !troco_aplicado) begin
			if (valor < 0)
				valor <= -valor;		// Exibe valor positivo no troco
			troco_aplicado <= 1;
		end

end

endmodule 