`timescale 1ns/1ps

module write_tb;

    // ------------------------------------------------------------
    // Sinais do testbench
    // ------------------------------------------------------------

    reg         clk;
    reg         rst;

    reg         start;
    reg [25:0]  address;
    reg [7:0]   data_in;

    wire        cs_n;
    wire        ras_n;
    wire        cas_n;
    wire        we_n;

    wire [1:0]  ba;
    wire [12:0] a;

    wire [7:0]  dq;

    wire        busy;
    wire        done;

    // ------------------------------------------------------------
    // Instância do DUT
    // ------------------------------------------------------------

    dram_write dut (
        .clk(clk),
        .rst(rst),

        .start(start),
        .address(address),
        .data_in(data_in),

        .cs_n(cs_n),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),

        .ba(ba),
        .a(a),
        .dq(dq),

        .busy(busy),
        .done(done)
    );

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        clk = 0;

        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Monitor automático
    // ------------------------------------------------------------

    initial begin
        $monitor(
            "t=%0t state=%0d timer=%0d cs=%b ras=%b cas=%b we=%b dq=%h busy=%b done=%b",
            $time,
            dut.state,
            dut.timer,
            cs_n,
            ras_n,
            cas_n,
            we_n,
            dq,
            busy,
            done
        );
    end

    // ------------------------------------------------------------
    // Dump para GTKWave
    // ------------------------------------------------------------

    initial begin
        $dumpfile("write_tb.vcd");
        $dumpvars(0, write_tb);
    end

    // ------------------------------------------------------------
    // TESTE 3 — Escrita
    // ------------------------------------------------------------

    initial begin

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        rst     = 1'b1;
        start   = 1'b0;
        address = 26'b0;
        data_in = 8'b0;

        #20;

        rst = 1'b0;

        @(posedge clk);

        // --------------------------------------------------------
        // Início da escrita
        // --------------------------------------------------------

        start   <= 1'b1;
        address <= 26'h0123456;
        data_in <= 8'h0A;

        #1;

        $display("========================================");
        $display("TESTE 3 - ESCRITA");
        $display("Requisição enviada");
        $display("address = 0x%h", address);
        $display("data    = 0x%h", data_in);

        @(posedge clk);

        start <= 1'b0;

        // --------------------------------------------------------
        // Espera ACTIVATE
        // --------------------------------------------------------

        wait(cs_n==0 && ras_n==0 && cas_n==1 && we_n==1);

        #1;

        $display("----------------------------------------");
        $display("COMANDO: ACTIVATE");
        $display("cs_n=%b ras_n=%b cas_n=%b we_n=%b",
                  cs_n, ras_n, cas_n, we_n);

        // --------------------------------------------------------
        // Espera WRITE
        // --------------------------------------------------------

        wait(cs_n==0 && ras_n==1 && cas_n==0 && we_n==0);

        #1;

        $display("----------------------------------------");
        $display("COMANDO: WRITE");
        $display("dq = 0x%h", dq);
        $display("cs_n=%b ras_n=%b cas_n=%b we_n=%b",
                  cs_n, ras_n, cas_n, we_n);

        // --------------------------------------------------------
        // Espera PRECHARGE
        // --------------------------------------------------------

        wait(cs_n==0 && ras_n==0 && cas_n==1 && we_n==0);

        #1;

        $display("----------------------------------------");
        $display("COMANDO: PRECHARGE");
        $display("cs_n=%b ras_n=%b cas_n=%b we_n=%b",
                  cs_n, ras_n, cas_n, we_n);

        // --------------------------------------------------------
        // Espera término
        // --------------------------------------------------------

        wait(done == 1'b1);

        #1;

        $display("----------------------------------------");
        $display("FINAL");
        $display("busy = %b", busy);
        $display("done = %b", done);

        if (done && !busy)
            $display("RESULTADO: ESCRITA CONCLUIDA COM SUCESSO");
        else
            $display("RESULTADO: FALHA");

        $display("========================================");

        #20;

        $finish;
    end

endmodule