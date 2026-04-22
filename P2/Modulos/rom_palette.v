module rom_palette (
    input wire [2:0] id_palette,        // ID da cor desejada (8 opções)
    output wire [23:0] color            // 24 bits de cor (RGB)
);

// 8 Possíveis cores na tabela de paletas
`ifndef SYNTHESIS
reg [23:0] storage [0:7];
`else
(* ram_init_file = "../Modulos/RawData/palette.mif" *)
reg [23:0] storage [0:7];
`endif

initial begin
    $readmemh("../Modulos/RawData/palette.mem", storage);
end

assign color = storage[id_palette];

endmodule
