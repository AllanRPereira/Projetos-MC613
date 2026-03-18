module escolher_produto(

	input wire [3:0] SW,	
	output wire [6:0] HEX_DISPLAY,
	output wire [10:0] VALOR_PRODUTO

);

assign VALOR_PRODUTO = (SW == 4'b0000) ? 11'b0001111101 : // 
             (SW == 4'b0001) ? 11'b0100101100 : // 
             (SW == 4'b0010) ? 11'b0010101111 : // 
             (SW == 4'b0011) ? 11'b0111000010 : // 
             (SW == 4'b0100) ? 11'b0011100001 : // 
             (SW == 4'b0101) ? 11'b0101011110 : // 
             (SW == 4'b0110) ? 11'b0011111010 : // 
             (SW == 4'b0111) ? 11'b0110101001 : // 
             (SW == 4'b1000) ? 11'b0111110100 : // 
             (SW == 4'b1001) ? 11'b0111110100 : // 
             (SW == 4'b1010) ? 11'b1001011000 : // 
             (SW == 4'b1011) ? 11'b0100010011 : // 
             (SW == 4'b1100) ? 11'b1010111100 : // 
             (SW == 4'b1101) ? 11'b0111011011 : // 
             (SW == 4'b1110) ? 11'b0111011011 : // 
             (SW == 4'b1111) ? 11'b1100100000 : // 
                                11'b00000000000;  // Default: Valor 0
			  
bin2hex DisplayProduto (
	.BIN(SW),
	.HEX(HEX_DISPLAY)
);

endmodule 	