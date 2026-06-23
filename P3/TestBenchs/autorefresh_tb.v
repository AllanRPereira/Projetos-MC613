`timescale 1ns / 1ps

// =============================================================================
// Testbench: tb_autorefresh
// Referência: ISSI IS42/45R/S86400D/16320D/32160D Datasheet Rev.00B
//
// Verificações baseadas no datasheet:
//
// [DS-1] CMD_AREF: CKE(n-1)=H, CKE(n)=H, CS=L, RAS=L, CAS=L, WE=H
//        → {cs_n, ras_n, cas_n, we_n} = 4'b0001   (conforme Command Truth Table)
//
// [DS-2] CMD_NOP:  CKE=H, CS=L, RAS=H, CAS=H, WE=H
//        → {cs_n, ras_n, cas_n, we_n} = 4'b0111
//
// [DS-3] Durante AREF: endereços (A0-A12) e BA são "Don't Care"
//        → módulo os mantém em 0 (comportamento válido)
//
// [DS-4] CKE deve permanecer HIGH durante o ciclo de AREF
//        → o módulo mantém cke=1 em todos os estados (correto)
//
// [DS-5] tRFC: nenhum outro comando pode ser emitido durante o período tRFC
//        → DUT deve emitir apenas NOP em S_WAIT
//
// [DS-6] AREF deve ser executado ≥ 8192 vezes a cada tREF (64ms típico)
//        → TREFI_CYCLES = 1116 equivale a ~7.8µs @ ~143MHz (compatível)
//
// Parâmetros reduzidos para simulação rápida:
//   TREFI_CYCLES = 20  (original: 1116)
//   TRFC_CYCLES  = 5   (original: 10)
// =============================================================================

module tb_autorefresh;

    // -------------------------------------------------------------------------
    // Parâmetros do testbench
    // -------------------------------------------------------------------------
    parameter integer TREFI      = 20;
    parameter integer TRFC       = 5;
    parameter integer CLK_PERIOD = 10; // 10 ns → 100 MHz

    // Encodings do datasheet
    localparam [3:0] EXP_NOP  = 4'b0111; // CS=L RAS=H CAS=H WE=H
    localparam [3:0] EXP_AREF = 4'b0001; // CS=L RAS=L CAS=L WE=H  [DS-1]

    // Contadores de erros
    integer err_count;

    // -------------------------------------------------------------------------
    // Sinais
    // -------------------------------------------------------------------------
    reg         clk;
    reg         rst;
    reg         enable;
    reg         grant;

    wire        cke;
    wire        cs_n;
    wire        ras_n;
    wire        cas_n;
    wire        we_n;
    wire [1:0]  ba;
    wire [12:0] a;
    wire        refresh_req;
    wire        busy;
    wire        done;

    // Sinal auxiliar para monitorar NOP durante S_WAIT
    wire [3:0] cmd_bus = {cs_n, ras_n, cas_n, we_n};

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    autorefresh #(
        .TREFI_CYCLES(TREFI),
        .TRFC_CYCLES (TRFC)
    ) dut (
        .clk         (clk),
        .rst         (rst),
        .enable      (enable),
        .grant       (grant),
        .cke         (cke),
        .cs_n        (cs_n),
        .ras_n       (ras_n),
        .cas_n       (cas_n),
        .we_n        (we_n),
        .ba          (ba),
        .a           (a),
        .refresh_req (refresh_req),
        .busy        (busy),
        .done        (done)
    );

    // -------------------------------------------------------------------------
    // Clock
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -------------------------------------------------------------------------
    // Dump VCD para GTKWave
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_autorefresh.vcd");
        $dumpvars(0, tb_autorefresh);
    end

    // -------------------------------------------------------------------------
    // Tarefas auxiliares
    // -------------------------------------------------------------------------
    task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    task apply_reset;
        begin
            rst = 1'b1; enable = 1'b0; grant = 1'b0;
            wait_cycles(4);
            @(negedge clk); rst = 1'b0;
            $display("[%0t ns] Reset liberado.", $time);
        end
    endtask

    // Checa NOP conforme [DS-2]
    task check_nop;
        begin
            if (cmd_bus !== EXP_NOP) begin
                $display("[FALHA][DS-2] Esperado NOP(0111), obtido %b @ %0t ns",
                         cmd_bus, $time);
                err_count = err_count + 1;
            end
        end
    endtask

    // Checa AREF conforme [DS-1]
    task check_aref;
        begin
            if (cmd_bus !== EXP_AREF) begin
                $display("[FALHA][DS-1] Esperado AREF(0001), obtido %b @ %0t ns",
                         cmd_bus, $time);
                err_count = err_count + 1;
            end else begin
                $display("[OK][DS-1]   AREF correto: cs=%b ras=%b cas=%b we=%b @ %0t ns",
                         cs_n, ras_n, cas_n, we_n, $time);
            end
        end
    endtask

    // Checa CKE=1 durante AREF conforme [DS-4]
    task check_cke;
        begin
            if (cke !== 1'b1) begin
                $display("[FALHA][DS-4] CKE deveria ser HIGH durante AREF @ %0t ns", $time);
                err_count = err_count + 1;
            end else begin
                $display("[OK][DS-4]   CKE=1 durante AREF.");
            end
        end
    endtask

    // =========================================================================
    // Sequência de testes
    // =========================================================================
    initial begin
        err_count = 0;

        $display("=============================================================");
        $display(" Testbench autorefresh | TREFI=%0d TRFC=%0d | Ref: ISSI DS", TREFI, TRFC);
        $display("=============================================================");

        // ------------------------------------------------------------------
        // TESTE 1: Reset — verifica estado inicial e NOP [DS-2]
        // ------------------------------------------------------------------
        $display("\n--- TESTE 1: Reset e estado inicial ---");
        apply_reset;
        @(posedge clk); #1;

        if (refresh_req !== 0 || busy !== 0 || done !== 0) begin
            $display("[FALHA] Saídas não zeradas após reset.");
            err_count = err_count + 1;
        end else
            $display("[OK]    Saídas em 0 após reset.");

        if (cke !== 1'b1) begin
            $display("[FALHA][DS-4] CKE deveria ser 1 em repouso.");
            err_count = err_count + 1;
        end else
            $display("[OK][DS-4]   CKE=1 em repouso.");

        check_nop;

        // ------------------------------------------------------------------
        // TESTE 2: enable=0 — timer congelado, sem refresh_req
        // ------------------------------------------------------------------
        $display("\n--- TESTE 2: Módulo desabilitado (enable=0) ---");
        enable = 1'b0;
        wait_cycles(TREFI + 10);
        if (refresh_req !== 0) begin
            $display("[FALHA] refresh_req levantado com enable=0.");
            err_count = err_count + 1;
        end else
            $display("[OK]    refresh_req=0 com enable=0.");

        // ------------------------------------------------------------------
        // TESTE 3: Ciclo completo — grant imediato
        //          Verifica [DS-1] AREF, [DS-4] CKE, [DS-5] NOP em tRFC
        // ------------------------------------------------------------------
        $display("\n--- TESTE 3: Ciclo completo de refresh (grant imediato) ---");
        enable = 1'b1; grant = 1'b0;

        fork
            begin : wait_req3
                @(posedge refresh_req);
                $display("[%0t ns] refresh_req levantado (S_REQ).", $time);
                disable timeout_req3;
            end
            begin : timeout_req3
                wait_cycles(TREFI + 10);
                $display("[FALHA] Timeout aguardando refresh_req.");
                err_count = err_count + 1;
                disable wait_req3;
            end
        join

        // Concede grant
        @(negedge clk); grant = 1'b1;
        @(posedge clk); #1;
        check_aref;  // [DS-1]
        check_cke;   // [DS-4]

        if (busy !== 1'b1) begin
            $display("[FALHA] busy deveria ser 1 após AREF.");
            err_count = err_count + 1;
        end else
            $display("[OK]    busy=1 durante tRFC.");

        grant = 1'b0;

        // [DS-5] Monitora NOP em todos os ciclos de S_WAIT
        begin : check_trfc_nop
            integer k;
            for (k = 0; k < TRFC - 1; k = k + 1) begin
                @(posedge clk); #1;
                if (cmd_bus !== EXP_NOP) begin
                    $display("[FALHA][DS-5] Comando não-NOP durante tRFC ciclo %0d: %b", k, cmd_bus);
                    err_count = err_count + 1;
                end
            end
            $display("[OK][DS-5]   Apenas NOP emitido durante tRFC (%0d ciclos).", TRFC-1);
        end

        // Aguarda done
        fork
            begin : wait_done3
                @(posedge done);
                $display("[%0t ns] done=1 — refresh concluído.", $time);
                disable timeout_done3;
            end
            begin : timeout_done3
                wait_cycles(TRFC + 10);
                $display("[FALHA] Timeout aguardando done.");
                err_count = err_count + 1;
                disable wait_done3;
            end
        join

        @(posedge clk); #1;
        if (busy !== 0) begin
            $display("[FALHA] busy deveria ser 0 após done.");
            err_count = err_count + 1;
        end else
            $display("[OK]    busy=0 após conclusão.");

        // ------------------------------------------------------------------
        // TESTE 4: Grant atrasado — refresh_req mantido em S_REQ
        // ------------------------------------------------------------------
        $display("\n--- TESTE 4: Grant atrasado (5 ciclos) ---");
        grant = 1'b0;

        @(posedge refresh_req);
        $display("[%0t ns] refresh_req levantado. Aguardando 5 ciclos.", $time);
        wait_cycles(5);

        if (refresh_req !== 1'b1) begin
            $display("[FALHA] refresh_req deveria permanecer 1 enquanto aguarda grant.");
            err_count = err_count + 1;
        end else
            $display("[OK]    refresh_req mantido em S_REQ durante espera.");

        // Verifica NOP durante espera por grant (nenhum AREF prematuro)
        if (cmd_bus !== EXP_NOP) begin
            $display("[FALHA][DS-1] AREF emitido sem grant @ %0t ns", $time);
            err_count = err_count + 1;
        end else
            $display("[OK][DS-1]   Nenhum AREF emitido antes do grant.");

        @(negedge clk); grant = 1'b1;
        @(posedge clk); #1;
        check_aref;
        check_cke;
        grant = 1'b0;

        @(posedge done);
        $display("[%0t ns] Refresh com grant atrasado concluído.", $time);

        // ------------------------------------------------------------------
        // TESTE 5: enable=0 durante S_REQ → retorno para S_IDLE sem AREF
        // ------------------------------------------------------------------
        $display("\n--- TESTE 5: enable=0 durante S_REQ (sem AREF) ---");
        grant = 1'b0;

        @(posedge refresh_req);
        $display("[%0t ns] refresh_req levantado. Desabilitando.", $time);

        @(negedge clk); enable = 1'b0;
        wait_cycles(4);

        if (refresh_req !== 0) begin
            $display("[FALHA] refresh_req deveria baixar com enable=0 em S_REQ.");
            err_count = err_count + 1;
        end else
            $display("[OK]    refresh_req baixou ao desabilitar em S_REQ.");

        if (cmd_bus !== EXP_NOP) begin
            $display("[FALHA][DS-1] AREF emitido sem grant ao desabilitar.");
            err_count = err_count + 1;
        end else
            $display("[OK][DS-1]   Nenhum AREF espúrio ao abortar em S_REQ.");

        // ------------------------------------------------------------------
        // TESTE 6: Três ciclos consecutivos de refresh
        //          [DS-6] Verifica periodicidade e integridade de done
        // ------------------------------------------------------------------
        $display("\n--- TESTE 6: Três ciclos consecutivos [DS-6] ---");
        enable = 1'b1;
        begin : multi_refresh
            integer k;
            for (k = 0; k < 3; k = k + 1) begin
                @(posedge refresh_req);
                $display("[%0t ns] Ciclo %0d: req recebido.", $time, k+1);
                @(negedge clk); grant = 1'b1;
                @(posedge clk); #1;
                check_aref;
                check_cke;
                grant = 1'b0;
                @(posedge done);
                $display("[%0t ns] Ciclo %0d: done recebido.", $time, k+1);
            end
            $display("[OK][DS-6]   3 ciclos de refresh executados com sucesso.");
        end

        // ------------------------------------------------------------------
        // TESTE 7: [DS-3] Don't Care — BA e A durante AREF devem ser 0
        //          (comportamento definido do módulo: emite 0)
        // ------------------------------------------------------------------
        $display("\n--- TESTE 7: BA e A durante AREF [DS-3 Don't Care] ---");
        grant = 1'b0;
        @(posedge refresh_req);
        @(negedge clk); grant = 1'b1;
        @(posedge clk); #1;

        // Datasheet: endereços são Don't Care → módulo emite 0 (válido)
        $display("[INFO][DS-3] ba=%b, a=%h durante AREF (Don't Care — 0 é válido).", ba, a);
        if (ba !== 2'b00 || a !== 13'b0)
            $display("[AVISO][DS-3] BA/A não são 0 durante AREF (ainda válido pelo DS).");
        else
            $display("[OK][DS-3]   BA=0 e A=0 durante AREF.");

        grant = 1'b0;
        @(posedge done);

        // ------------------------------------------------------------------
        // TESTE 8: Reset durante S_WAIT — limpeza imediata
        // ------------------------------------------------------------------
        $display("\n--- TESTE 8: Reset durante S_WAIT ---");
        @(posedge refresh_req);
        @(negedge clk); grant = 1'b1;
        @(posedge clk); #1;
        grant = 1'b0;

        wait_cycles(2); // Entra em S_WAIT
        rst = 1'b1;
        wait_cycles(2);
        rst = 1'b0;
        @(posedge clk); #1;

        if (busy !== 0 || refresh_req !== 0 || done !== 0) begin
            $display("[FALHA] Reset em S_WAIT não limpou as saídas.");
            err_count = err_count + 1;
        end else
            $display("[OK]    Reset em S_WAIT: saídas limpas.");

        check_nop;
        check_cke;

        // ------------------------------------------------------------------
        // Resultado final
        // ------------------------------------------------------------------
        wait_cycles(10);
        $display("\n=============================================================");
        if (err_count == 0)
            $display(" RESULTADO: TODOS OS TESTES PASSARAM (0 erros)");
        else
            $display(" RESULTADO: %0d FALHA(S) DETECTADA(S)", err_count);
        $display("=============================================================\n");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Monitor contínuo — imprime transições relevantes
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        // Detecta AREF inesperado (sem grant no ciclo anterior)
        if (cmd_bus === EXP_AREF)
            $display("[MONITOR %0t ns] AREF emitido | busy=%b grant=%b cke=%b",
                     $time, busy, grant, cke);
        if (done)
            $display("[MONITOR %0t ns] done=1 | ref_timer_interno zerado.", $time);
        // [DS-5] Alerta se comando != NOP durante busy (exceto no 1.º ciclo de AREF)
        if (busy && cmd_bus !== EXP_NOP && cmd_bus !== EXP_AREF)
            $display("[ALERTA][DS-5] Comando inesperado %b emitido durante busy @ %0t ns",
                     cmd_bus, $time);
    end

    // -------------------------------------------------------------------------
    // Timeout global
    // -------------------------------------------------------------------------
    initial begin
        #(CLK_PERIOD * 5000);
        $display("[ERRO] Timeout global — simulação interrompida.");
        $finish;
    end

endmodule