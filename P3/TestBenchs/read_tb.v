`timescale 1ns/1ps

module read_tb;

    // ------------------------------------------------------------
    // Parâmetros
    // ------------------------------------------------------------

    localparam DATA_WIDTH = 8;
    localparam BANK_BITS  = 2;
    localparam ROW_BITS   = 13;
    localparam COL_BITS   = 11;

    localparam ADDR_WIDTH = BANK_BITS + ROW_BITS + COL_BITS;

    // ------------------------------------------------------------
    // Sinais
    // ------------------------------------------------------------

    reg                         clk;
    reg                         rst;
    reg                         start;

    reg  [ADDR_WIDTH-1:0]       addr;
    reg  [DATA_WIDTH-1:0]       dq_in;

    wire                        cke;
    wire                        cs_n;
    wire                        ras_n;
    wire                        cas_n;
    wire                        we_n;

    wire [1:0]                  ba;
    wire [12:0]                 a;

    wire [DATA_WIDTH-1:0]       data_out;
    wire                        data_valid;
    wire                        ready;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    read dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .addr(addr),
        .dq_in(dq_in),

        .cke(cke),
        .cs_n(cs_n),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),

        .ba(ba),
        .a(a),

        .data_out(data_out),
        .data_valid(data_valid),
        .ready(ready)
    );

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Dump GTKWave
    // ------------------------------------------------------------

    initial begin
        $dumpfile("read_tb.vcd");
        $dumpvars(0, read_tb);
    end

    // ------------------------------------------------------------
    // Monitor
    // ------------------------------------------------------------

    initial begin
        $monitor(
            "t=%0t state=%0d timer=%0d cs=%b ras=%b cas=%b we=%b dq_in=%h data_out=%h valid=%b ready=%b",
            $time,
            dut.state,
            dut.timer,
            cs_n,
            ras_n,
            cas_n,
            we_n,
            dq_in,
            data_out,
            data_valid,
            ready
        );
    end

    // ------------------------------------------------------------
    // Teste de leitura
    // ------------------------------------------------------------

    initial begin

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        rst   = 1'b1;
        start = 1'b0;
        addr  = 26'b0;
        dq_in = 8'h00;

        #20;

        rst = 1'b0;

        @(posedge clk);

        // --------------------------------------------------------
        // TESTE 2 — LEITURA
        // --------------------------------------------------------

        start <= 1'b1;
        addr  <= 26'h0123456;
        dq_in <= 8'h0A;

        #1;

        $display("========================================");
        $display("TESTE 2 - LEITURA");
        $display("Requisicao de leitura enviada");
        $display("addr = 0x%h", addr);

        @(posedge clk);

        start <= 1'b0;

        // --------------------------------------------------------
        // ACTIVATE
        // --------------------------------------------------------

        wait(cs_n==0 && ras_n==0 && cas_n==1 && we_n==1);

        #1;

        $display("----------------------------------------");
        $display("Ciclo 2 -> ACTIVATE");
        $display("cs_n=%b ras_n=%b cas_n=%b we_n=%b",
                  cs_n, ras_n, cas_n, we_n);

        // --------------------------------------------------------
        // Espera READ
        // --------------------------------------------------------

        wait(cs_n==0 && ras_n==1 && cas_n==0 && we_n==1);

        #1;

        $display("----------------------------------------");
        $display("Ciclo 4 -> READ");
        $display("cs_n=%b ras_n=%b cas_n=%b we_n=%b",
                  cs_n, ras_n, cas_n, we_n);

        // --------------------------------------------------------
        // Espera CAS latency
        // --------------------------------------------------------

        $display("----------------------------------------");
        $display("Ciclo 5 -> WAIT CAS LATENCY");

        // --------------------------------------------------------
        // Simula dado vindo da SDRAM
        // --------------------------------------------------------

        wait(dut.state == dut.S_CAPTURE);

        dq_in <= 8'h0B;

        #1;

        $display("----------------------------------------");
        $display("Ciclo 6 -> CAPTURE");
        $display("dq_in     = 0x%h", dq_in);
        $display("data_out  = 0x%h", data_out);
        $display("valid     = %b", data_valid);

        // --------------------------------------------------------
        // Espera PRECHARGE
        // --------------------------------------------------------

        wait(cs_n==0 && ras_n==0 && cas_n==1 && we_n==0);

        #1;

        $display("----------------------------------------");
        $display("Ciclo 7 -> PRECHARGE");
        $display("cs_n=%b ras_n=%b cas_n=%b we_n=%b",
                  cs_n, ras_n, cas_n, we_n);

        // --------------------------------------------------------
        // Espera retorno ao IDLE
        // --------------------------------------------------------

        wait(ready == 1'b1);

        #1;

        $display("----------------------------------------");
        $display("Ciclo final");
        $display("ready      = %b", ready);
        $display("data_out   = 0x%h", data_out);
        $display("data_valid = %b", data_valid);

        if (ready && data_out == 8'h0B)
            $display("RESULTADO: LEITURA CONCLUIDA COM SUCESSO");
        else
            $display("RESULTADO: FALHA");

        $display("========================================");

        #20;

        $finish;
    end

endmodule