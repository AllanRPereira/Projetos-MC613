module dram_write (
    input  wire        clk,
    input  wire        rst,

    // Controle da operação
    input  wire        start,
    input  wire [25:0] address,
    input  wire [7:0]  data_in,

    // Interface SDRAM
    output reg         cs_n,
    output reg         ras_n,
    output reg         cas_n,
    output reg         we_n,
    output reg  [1:0]  ba,
    output reg  [12:0] a,
    inout  wire [7:0]  dq,

    // Status
    output reg         busy,
    output reg         done
);

    // ------------------------------------------------------------
    // Temporizações
    // ------------------------------------------------------------

    localparam TRCD = 3; // ACTIVATE -> WRITE
    localparam TWR  = 3; // WRITE -> PRECHARGE
    localparam TRP  = 3; // PRECHARGE -> próxima operação

    // ------------------------------------------------------------
    // Comandos SDRAM
    // {cs_n, ras_n, cas_n, we_n}
    // ------------------------------------------------------------

    localparam CMD_NOP   = 4'b0111;
    localparam CMD_ACT   = 4'b0011;
    localparam CMD_WRITE = 4'b0100;
    localparam CMD_PCH   = 4'b0010;

    // ------------------------------------------------------------
    // Estados
    // ------------------------------------------------------------

    localparam S_IDLE        = 3'd0;
    localparam S_ACTIVATE    = 3'd1;
    localparam S_WAIT_TRCD   = 3'd2;
    localparam S_WRITE       = 3'd3;
    localparam S_WAIT_TWR    = 3'd4;
    localparam S_PRECHARGE   = 3'd5;
    localparam S_WAIT_TRP    = 3'd6;
    localparam S_DONE        = 3'd7;

    reg [2:0] state;
    reg [3:0] timer;

    // ------------------------------------------------------------
    // Separação do endereço
    // ------------------------------------------------------------

    wire [1:0] bank;
    wire [12:0] row;
    wire [8:0] col;

    assign bank = address[25:24];
    assign row  = address[23:11];
    assign col  = address[10:2];

    // ------------------------------------------------------------
    // Controle do barramento de dados
    // ------------------------------------------------------------

    reg [7:0] dq_out;
    reg       dq_oe;

    assign dq = (dq_oe) ? dq_out : 8'bzzzzzzzz;

    // ------------------------------------------------------------
    // FSM principal
    // ------------------------------------------------------------

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            timer <= 4'd0;

            busy <= 1'b0;
            done <= 1'b0;

            dq_out <= 8'b00000000;
            dq_oe  <= 1'b0;

            ba <= 2'b00;
            a  <= 13'b0000000000000;

            {cs_n, ras_n, cas_n, we_n} = CMD_NOP;

        end else begin

            // Default
            {cs_n, ras_n, cas_n, we_n} = CMD_NOP;
            done <= 1'b0;

            case (state)

                // ------------------------------------------------
                // Espera nova operação
                // ------------------------------------------------

                S_IDLE: begin
                    busy  <= 1'b0;
                    dq_oe <= 1'b0;
                    timer <= 4'd0;

                    if (start) begin
                        busy  <= 1'b1;
                        state <= S_ACTIVATE;
                    end
                end

                // ------------------------------------------------
                // ACTIVATE
                // ------------------------------------------------

                S_ACTIVATE: begin
                    {cs_n, ras_n, cas_n, we_n} <= CMD_ACT;

                    ba <= bank;
                    a  <= row;

                    timer <= 4'd0;
                    state <= S_WAIT_TRCD;
                end

                // ------------------------------------------------
                // Espera tRCD
                // ------------------------------------------------

                S_WAIT_TRCD: begin
                    timer <= timer + 1'b1;

                    if (timer >= TRCD) begin
                        timer <= 4'd0;
                        state <= S_WRITE;
                    end
                end

                // ------------------------------------------------
                // WRITE
                // ------------------------------------------------

                S_WRITE: begin
                    {cs_n, ras_n, cas_n, we_n} <= CMD_WRITE;

                    ba <= bank;

                    // A10 = 0 -> sem auto-precharge
                    a <= {3'b000, 1'b0, col};

                    dq_out <= data_in;
                    dq_oe  <= 1'b1;

                    timer <= 4'd0;
                    state <= S_WAIT_TWR;
                end

                // ------------------------------------------------
                // Espera tWR
                // ------------------------------------------------

                S_WAIT_TWR: begin
                    timer <= timer + 1'b1;

                    if (timer >= TWR) begin
                        dq_oe <= 1'b0;
                        timer <= 4'd0;
                        state <= S_PRECHARGE;
                    end
                end

                // ------------------------------------------------
                // PRECHARGE
                // ------------------------------------------------

                S_PRECHARGE: begin
                    {cs_n, ras_n, cas_n, we_n} <= CMD_PCH;

                    // A10 = 1 -> precharge do banco ativo
                    a[10] <= 1'b1;

                    timer <= 4'd0;
                    state <= S_WAIT_TRP;
                end

                // ------------------------------------------------
                // Espera tRP
                // ------------------------------------------------

                S_WAIT_TRP: begin
                    timer <= timer + 1'b1;

                    if (timer >= TRP) begin
                        timer <= 4'd0;
                        state <= S_DONE;
                    end
                end

                // ------------------------------------------------
                // Finalização
                // ------------------------------------------------

                S_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end

            endcase
        end
    end

endmodule