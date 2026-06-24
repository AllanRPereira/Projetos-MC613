module dram_top_level (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [9:0]  SW,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,
    output wire [9:0]  LEDR,

    // SDRAM interface (DE1-SoC)
    output wire        DRAM_CKE,
    output wire        DRAM_CS_N,
    output wire        DRAM_RAS_N,
    output wire        DRAM_CAS_N,
    output wire        DRAM_WE_N,
    output wire [1:0]  DRAM_BA,
    output wire [12:0] DRAM_ADDR,
    inout  wire [15:0] DRAM_DQ,
    output wire        DRAM_CLK,
    output wire        DRAM_LDQM,
    output wire        DRAM_UDQM
);

    // Resets: KEY[0] é 0 quando pressionado (ativo-baixo)
    wire rstn = KEY[0]; 
    wire rst  = ~KEY[0];

    // Debounce para a tecla KEY[3] usada como comando de escrita/leitura.
    localparam integer KEY_DEBOUNCE_MAX = 500000; // ~10 ms @ 50 MHz

    reg key3_meta;
    reg key3_sync;
    reg key3_stable;
    reg [18:0] key3_counter;
    
    wire key3_raw = ~KEY[3];
    wire key3_debounced;

    // Fios de interconexão entre dram_iface e sdram_controller
    wire [15:0] w_read_data;
    wire [15:0] w_write_data;
    wire [25:0] w_address;
    wire w_rEn;
    wire w_wEn;
    wire w_ready;
    wire [1:0] w_dqm;

    // Fios para os displays de 7 segmentos
    wire [3:0] hex0_n;
    wire [3:0] hex1_n;
    wire [3:0] hex4_n;
    wire [3:0] hex5_n;

    assign key3_debounced = key3_stable;

    // Lógica de Debounce
    always @(posedge CLOCK_50) begin
        if (!rstn) begin
            key3_meta <= 1'b0;
            key3_sync <= 1'b0;
            key3_stable <= 1'b0;
            key3_counter <= 19'd0;
        end else begin
            key3_meta <= key3_raw;
            key3_sync <= key3_meta;

            if (key3_sync == key3_stable) begin
                key3_counter <= 19'd0;
            end else if (key3_counter >= KEY_DEBOUNCE_MAX - 1) begin
                key3_stable <= key3_sync;
                key3_counter <= 19'd0;
            end else begin
                key3_counter <= key3_counter + 1'b1;
            end
        end
    end

    // Instância da Interface de Controle Lógico
    dram_iface u_dram_iface (
        .clk(CLOCK_50),
        .rstn(rstn),
        .SW(SW),
        .KEY(key3_debounced),
        .ready(w_ready),
        .read_data(w_read_data),
        .write_data(w_write_data),
        .HEX0(hex0_n),
        .HEX1(hex1_n),
        .HEX4(hex4_n),
        .HEX5(hex5_n),
        .address(w_address),
        .rEn(w_rEn),
        .wEn(w_wEn),
        .leds(LEDR[9:5])
    );

    // Instância do Controlador da SDRAM
    sdram_controller u_dram_controller (
        .clk(CLOCK_50),
        .rstn(rstn),
        .wEn(w_wEn),
        .rEn(w_rEn),
        .address(w_address),
        .write_data(w_write_data),
        .read_data(w_read_data),
        .ready(w_ready),
        .CSn(DRAM_CS_N),
        .RASn(DRAM_RAS_N),
        .CASn(DRAM_CAS_N),
        .WEn(DRAM_WE_N),
        .BA(DRAM_BA),
        .addr(DRAM_ADDR),
        .DQ(DRAM_DQ),
        .DQM(w_dqm)
    );

    // Conversores Binário para 7 Segmentos
    bin2hex u_hex0 (.clk(CLOCK_50), .lock(1'b0), .reset(rst), .bin(hex0_n), .hex(HEX0));
    bin2hex u_hex1 (.clk(CLOCK_50), .lock(1'b0), .reset(rst), .bin(hex1_n), .hex(HEX1));
    bin2hex u_hex4 (.clk(CLOCK_50), .lock(1'b0), .reset(rst), .bin(hex4_n), .hex(HEX4));
    bin2hex u_hex5 (.clk(CLOCK_50), .lock(1'b0), .reset(rst), .bin(hex5_n), .hex(HEX5));

    // Desliga os displays não utilizados
    assign HEX2 = 7'b1111111;
    assign HEX3 = 7'b1111111;

    // Leds de Debug
    assign LEDR[0] = w_rEn;
    assign LEDR[1] = w_wEn;
    assign LEDR[2] = w_ready;
    assign LEDR[3] = 1'b0; // Livre
    assign LEDR[4] = 1'b0; // Livre

    // Sinais Fixos da SDRAM
    assign DRAM_CKE = 1'b1;         // Clock Enable sempre ativo
    assign DRAM_CLK = CLOCK_50;     // Idealmente, deve vir de uma PLL com phase-shift
    assign DRAM_UDQM = w_dqm[1];    // Conectado ao pino gerado no controlador (1)
    assign DRAM_LDQM = w_dqm[0];    // Conectado ao pino gerado no controlador (0)

endmodule