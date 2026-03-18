module registrador(
	input wire CLK,
	input wire RESET,
	input wire SALVAR,
	input wire [10:0] VAL_SALVAR,
	
	output reg [10:0] VALOR
);

always @(posedge clk) begin
	if (RESET)
		VALOR <= 11'b00000000000;
	else
		if (SAVE)
			VALOR <= VAL_SALVAR;
end

endmodule 