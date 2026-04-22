module rom_palette (
    input wire [2:0] id_palette,        // ID da cor desejada (8 opções)
    output wire [23:0] color            // 24 bits de cor (RGB)
);

// 8 Possíveis cores na tabela de paletas
reg [23:0] storage [0:7];

initial begin
    $readmemh("RawData/palette.mem", storage);
end

assign color = storage[id_palette];

endmodule
