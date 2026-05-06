module dram_top_level (
    input wire CLOCK_50,
    input wire [4:0] KEY,       // Normal Ativo
    input wire [9:0] SW,
    output wire [7:0] HEX0, HEX1, HEX4, HEX5,       // 4 Bits para converter para 7 segmentos
    output wire LEDR0, LEDR1                        // Usar para exibir os sinais de req e wEn
);

// Utilize uma das KEY para representar o sinal de ready do Controlador