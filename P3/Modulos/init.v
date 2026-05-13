module init (
    input  wire        clk,
    input  wire        rst,
    
    // Sinais de controle da SDRAM
    output reg         cke,
    output reg         cs_n,
    output reg         ras_n,
    output reg         cas_n,
    output reg         we_n,
    output reg  [1:0]  ba,
    output reg  [12:0] a,
    
    output reg         ready
);

    // MODOS REGISTRO CORRETO!

    // Parâmetros do Mode Register
    // M9 = 1 (Single Location Access)
    // M8:7 = 00 (Standard Operation)
    // M6:4 = 011 (CAS Latency = 3)
    // M3 = 0 (Sequential)
    // M2:0 = 000 (Burst Length = 1)
    // Valor final: 13'b0_0010_0011_0000 = 13'h0230
    localparam MODE_REG = 13'h0230;


    // TEMPOS VALIDADOS (TUDO BEM SER UM POUCO MAIOR!)
    // NÃO PODE SER MAIOR NA LEITURA E ESCRITA (MÁQUINA DE ESTADOS INTERNA)

    // Tempos baseados em 143 MHz (T ~ 7 ns)
    // Espera inicial de 200 us ~ 30000 ciclos (Margem superior)
    localparam TRP  = 4;   // tRP  (20ns)  -> ~3 ciclos, margem 4
    localparam TRC  = 10;  // tRC  (60ns)  -> ~9 ciclos, margem 10
    localparam TMRD = 3;   // tMRD (2 clk) -> margem 3

    // COMANDOS CORRETOS!

    // Comandos SDRAM {cs_n, ras_n, cas_n, we_n}
    localparam CMD_NOP     = 4'b0111;
    localparam CMD_PALL    = 4'b0010;
    localparam CMD_AREF    = 4'b0001;       // Auto Refresh
    localparam CMD_MRS     = 4'b0000;

    // Estados de Inicialização
    localparam S_WAIT     = 3'd0;
    localparam S_PRECH    = 3'd1;
    localparam S_REF1     = 3'd2;
    localparam S_REF2     = 3'd3;
    localparam S_MRS      = 3'd4;
    localparam S_DONE     = 3'd5;

    reg [2:0]  state;
    reg [14:0] timer;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_WAIT;
            timer <= 15'd0;
            ready <= 1'b0;
            
            cke   <= 1'b1;
            {cs_n, ras_n, cas_n, we_n} <= CMD_NOP;
            ba    <= 2'b00;
            a     <= 13'b0;
        end else begin
            // Decodificação padrão (NOP) se não for enviar comando
            {cs_n, ras_n, cas_n, we_n} <= CMD_NOP;
            
            case (state)
                S_WAIT: begin
                    timer <= timer + 1'b1;
                    if (timer == 15'd30000) begin
                        state <= S_PRECH;
                        timer <= 15'd0;
                        
                        // Precharge ALL command
                        {cs_n, ras_n, cas_n, we_n} <= CMD_PALL;
                        a[10] <= 1'b1;
                    end
                end
                
                S_PRECH: begin
                    timer <= timer + 1'b1;
                    if (timer == TRP) begin
                        state <= S_REF1;
                        timer <= 15'd0;
                        
                        // Auto Refresh 1 command
                        {cs_n, ras_n, cas_n, we_n} <= CMD_AREF;
                    end
                end
                
                // ADICIONAR MAIS AUTO-REFRESHS

                S_REF1: begin
                    timer <= timer + 1'b1;
                    if (timer == TRC) begin
                        state <= S_REF2;
                        timer <= 15'd0;
                        
                        // Auto Refresh 2 command
                        {cs_n, ras_n, cas_n, we_n} <= CMD_AREF;
                    end
                end
                
                S_REF2: begin
                    timer <= timer + 1'b1;
                    if (timer == TRC) begin
                        state <= S_MRS;
                        timer <= 15'd0;
                        
                        // Load Mode Register command
                        {cs_n, ras_n, cas_n, we_n} <= CMD_MRS;
                        a <= MODE_REG;
                        ba <= 2'b00;
                    end
                end
                
                S_MRS: begin
                    timer <= timer + 1'b1;
                    if (timer == TMRD) begin
                        state <= S_DONE;
                        ready <= 1'b1;
                    end
                end
                
                S_DONE: begin
                    ready <= 1'b1;
                    // NOP command
                    {cs_n, ras_n, cas_n, we_n} <= CMD_NOP;
                end
                
                // REAVALIAR COMANDO ACTIVE NO FINAL!!

                default: begin
                    state <= S_WAIT;
                    timer <= 15'd0;
                end
            endcase
        end
    end

endmodule
