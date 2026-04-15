`timescale 1ns / 1ps

module ppu1_tb;

    // Entradas do DUT (Device Under Test)
    reg clk;
    reg reset;
    reg [3:0] KEYS;
    reg [9:0] SW;
    reg [9:0] pixel_X;
    reg [9:0] pixel_Y;
    reg video_active;
    
    // Entradas da OAM
    reg oam_enable;
    reg [3:0] oam_address;
    reg [13:0] oam_id_posicao;

    // Saídas do DUT
    wire [7:0] vermelho;
    wire [7:0] verde;
    wire [7:0] azul;

    // Instância da PPU
    ppu1 #(
        .SPRITES_num(4)
    ) dut (
        .clk(clk),
        .reset(reset),
        .KEYS(KEYS),
        .SW(SW),
        .pixel_X(pixel_X),
        .pixel_Y(pixel_Y),
        .video_active(video_active),
        .oam_enable(oam_enable),
        .oam_address(oam_address),
        .oam_id_posicao(oam_id_posicao),
        .vermelho_saida(vermelho),
        .verde_saida(verde),
        .azul_saida(azul)
    );

    // Gerador de Clock (50MHz)
    always #10 clk = ~clk;

    initial begin
        // Configuração de log para o EDA Playground / GTKWave
        $dumpfile("ppu1_tb.vcd");
        $dumpvars(0, ppu1_tb);
        $monitor("Tempo=%0t | Pos(%0d,%0d) | Active=%b | RGB=(%h,%h,%h)", 
                 $time, pixel_X, pixel_Y, video_active, vermelho, verde, azul);

        // --- 1. SETUP INICIAL ---
        clk = 0;
        reset = 1;
        video_active = 0;
        pixel_X = 0; pixel_Y = 0;
        oam_enable = 0; oam_address = 0; oam_id_posicao = 0;

        // Injeta uma parede no fundo (Tile 0,0)
        dut.background_map[0] = 4'd1;

        #40 reset = 0;

        // --- 2. CARREGANDO A OAM (Simulando a Máquina de Controle) ---
        // Gravando o Sprite 0 (Antiga Cobra): ID = 1, X = 10, Y = 7
        // [13:10] = 1, [9:5] = 10, [4:0] = 7  => 14'b0001_01010_00111
        @(negedge clk);
        oam_enable = 1;
        oam_address = 0;
        oam_id_posicao = {4'd1, 5'd10, 5'd7}; // Sprite 0: Cobra
        
        @(negedge clk);
        oam_address = 1;
        oam_id_posicao = {4'd2, 5'd5, 5'd5};  // Sprite 1: Comida
        
        @(negedge clk);
        oam_enable = 0; // Desliga a gravação com segurança

        #40 video_active = 1; // Liga a tela

        // --- 3. TESTANDO A RENDERIZAÇÃO (VGA varrendo a tela) ---
        
        // Teste A: Parede do Fundo (Tile 0,0)
        pixel_X = 10; pixel_Y = 10; 
        #20; // Esperado: Cinza (44, 44, 44)

        // Teste B: Chão Vazio (Tile 1,1)
        pixel_X = 40; pixel_Y = 40; 
        #20; // Esperado: Preto (00, 00, 00)

        // Teste C: Lendo Sprite 1 - Comida (Tile 5,5 -> Pixel 160)
        pixel_X = 165; pixel_Y = 165; 
        #20; // Esperado: Vermelho (ff, 00, 00)

        // Teste D: Lendo Sprite 0 - Cobra (Tile 10,7 -> Pixel 320, 224)
        pixel_X = 330; pixel_Y = 230; 
        #20; // Esperado: Verde (00, ff, 00)

        // Teste E: Fora da tela
        video_active = 0;
        #20; // Esperado: Preto (00, 00, 00)

        $display("Simulação finalizada. PPU baseada em OAM validada com sucesso!");
        $finish;
    end

endmodule