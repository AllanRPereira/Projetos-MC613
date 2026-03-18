module registrador(
	input wire CLK,
	input wire RESET,
	input wire SIG_SALVAR,
	input wire [10:0] VAL_SALVAR,
	output reg [10:0] VALOR
);

always @(posedge CLK) begin
	if (RESET)
		VALOR <= 11'b00000000000;
	else
		if (SALVAR)
			VALOR <= VAL_SALVAR;
end

endmodule 