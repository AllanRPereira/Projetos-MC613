module conversao_valor (
    input wire clk,
    input wire reset,
    input wire [10:0] bin, // Entrada 0 a 2047
    output wire [6:0] display_0, display_1, display_2, display_3
);

    integer i;
    reg [15:0] acc;
    reg [15:0] bcd, // Milhar [15:12] | Centena [11:8] | Dezena [7:4] | Unidade [3:0]

    bin2hex DisplayUnidade (
        .clk(clk),
        .reset(reset),
        .lock(1'b0),
        .bin(bcd[3:0]),
        .hex(display_0)
    );

    bin2hex DisplayDecimal (
        .clk(clk),
        .reset(reset),
        .lock(1'b0),
        .bin(bcd[7:4]),
        .hex(display_1)
    );

    bin2hex DisplayCentena (
        .clk(clk),
        .reset(reset),
        .lock(1'b0),
        .bin(bcd[11:8]),
        .hex(display_2)
    );

    bin2hex DisplayMilhar (
        .clk(clk),
        .reset(reset),
        .lock(1'b0),
        .bin(bcd[15:12]),
        .hex(display_3)
    );

    always @(*) begin
        acc = 16'b0; // Inicializa acumulador com zeros 
        
        for (i = 10; i >= 0; i = i - 1) begin // Loop de 11 iterações
            
            // Se qualquer dígito BCD for > 4, soma 3
            if (acc[3:0]   > 4) acc[3:0]   = acc[3:0]   + 3;
            if (acc[7:4]   > 4) acc[7:4]   = acc[7:4]   + 3;
            if (acc[11:8]  > 4) acc[11:8]  = acc[11:8]  + 3;
            if (acc[15:12] > 4) acc[15:12] = acc[15:12] + 3;

            // Deslocamento à esquerda (Shift) inserindo o bit atual de 'bin' 
            acc = {acc[14:0], bin[i]};
        end
        
        bcd = acc; // Atribui o resultado final à saída
    end

endmodule