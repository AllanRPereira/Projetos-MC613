`timescale 1ns/1ps

module init_tb;

    // ------------------------------------------------------------
    // Sinais
    // ------------------------------------------------------------

    reg clk;
    reg rst;

    wire        cke;
    wire        cs_n;
    wire        ras_n;
    wire        cas_n;
    wire        we_n;

    wire [1:0]  ba;
    wire [12:0] a;

    wire        ready;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    init dut (
        .clk(clk),
        .rst(rst),

        .cke(cke),
        .cs_n(cs_n),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),

        .ba(ba),
        .a(a),

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
    // GTKWave
    // ------------------------------------------------------------

    initial begin
        $dumpfile("init_tb.vcd");
        $dumpvars(0, init_tb);
    end

    // ------------------------------------------------------------
    // Monitor
    // ------------------------------------------------------------

    initial begin
        $monitor(
            "t=%0t state=%0d timer=%0d cs=%b ras=%b cas=%b we=%b ready=%b",
            $time,
            dut.state,
            dut.timer,
            cs_n,
            ras_n,
            cas_n,
            we_n,
            ready
        );
    end

    // ------------------------------------------------------------
    // TESTE 1 — RESET E INIT
    // ------------------------------------------------------------

    initial begin

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        rst = 1'b1;

        #20;

        $display("========================================");
        $display("TESTE 1 - RESET E INICIALIZACAO");
        $display("Reset ativado");

        // --------------------------------------------------------
        // Libera reset
        // --------------------------------------------------------

        rst = 1'b0;

        // --------------------------------------------------------
        // Espera PRECHARGE
        // --------------------------------------------------------

        wait(cs_n==0 && ras_n==0 && cas_n==1 && we_n==0);

        #1;

        $display("----------------------------------------");
        $display("Ciclo INIT -> PRECHARGE");
        $display("cs_n=%b ras_n=%b cas_n=%b we_n=%b ready=%b",
                  cs_n, ras_n, cas_n, we_n, ready);

        // --------------------------------------------------------
        // Espera AUTO REFRESH 1
        // --------------------------------------------------------

        wait(cs_n==0 && ras_n==0 && cas_n==0 && we_n==1);

        #1;

        $display("----------------------------------------");
        $display("Ciclo INIT -> AUTO REFRESH 1");
        $display("cs_n=%b ras_n=%b cas_n=%b we_n=%b ready=%b",
                  cs_n, ras_n, cas_n, we_n, ready);

        // --------------------------------------------------------
        // Espera AUTO REFRESH 2
        // --------------------------------------------------------

        @(posedge clk);

        wait(cs_n==0 && ras_n==0 && cas_n==0 && we_n==1);

        #1;

        $display("----------------------------------------");
        $display("Ciclo INIT -> AUTO REFRESH 2");
        $display("cs_n=%b ras_n=%b cas_n=%b we_n=%b ready=%b",
                  cs_n, ras_n, cas_n, we_n, ready);

        // --------------------------------------------------------
        // Espera LOAD MODE REGISTER
        // --------------------------------------------------------

        wait(cs_n==0 && ras_n==0 && cas_n==0 && we_n==0);

        #1;

        $display("----------------------------------------");
        $display("Ciclo INIT -> LOAD MODE REGISTER");
        $display("cs_n=%b ras_n=%b cas_n=%b we_n=%b",
                  cs_n, ras_n, cas_n, we_n);

        $display("MODE REGISTER = 0x%h", a);

        // --------------------------------------------------------
        // Espera READY
        // --------------------------------------------------------

        wait(ready == 1'b1);

        #1;

        $display("----------------------------------------");
        $display("Ciclo final");
        $display("ready = %b", ready);

        if (ready)
            $display("RESULTADO: INIT CONCLUIDA COM SUCESSO");
        else
            $display("RESULTADO: FALHA");

        $display("========================================");

        #20;

        $finish;
    end

endmodule