module selecao_produto(
    input wire clk,
    input wire reset,
	input wire [3:0] sw,
    input wire travar_selecao,	

	output wire [6:0] hex_display_5,
	output wire [10:0] valor_produto

);

assign valor_produto = (sw == 4'b0000) ? 11'b0001111101 : // 
             (sw == 4'b0001) ? 11'b0100101100 : // 
             (sw == 4'b0010) ? 11'b0010101111 : // 
             (sw == 4'b0011) ? 11'b0111000010 : // 
             (sw == 4'b0100) ? 11'b0011100001 : // 
             (sw == 4'b0101) ? 11'b0101011110 : // 
             (sw == 4'b0110) ? 11'b0011111010 : // 
             (sw == 4'b0111) ? 11'b0110101001 : // 
             (sw == 4'b1000) ? 11'b0111110100 : // 
             (sw == 4'b1001) ? 11'b0111110100 : // 
             (sw == 4'b1010) ? 11'b1001011000 : // 
             (sw == 4'b1011) ? 11'b0100010011 : // 
             (sw == 4'b1100) ? 11'b1010111100 : // 
             (sw == 4'b1101) ? 11'b0111011011 : // 
             (sw == 4'b1110) ? 11'b0111011011 : // 
             (sw == 4'b1111) ? 11'b1100100000 : // 
                                11'b00000000000;  // Default: Valor 0
			  
bin2hex DisplayProduto (
    .clk(clk),
    .reset(reset),
    .lock(travar_selecao),
	.bin(sw),
	.hex(hex_display_5)
);


endmodule 	