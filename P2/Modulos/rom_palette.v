module rom_palette (
    input wire [4:0] id_palette,        // ID da cor desejada
    output wire [7:0] color             // 8 bits de cor
);

// 8 Possíveis cores na tabela de paletas
reg [7:0] storage [0:7];

initial begin
    $readmemh("pallete.mem", storage);
end

assign color = storage[id_palette];

endmodule
