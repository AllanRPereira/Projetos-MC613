`timescale 1ns/1ps

// Testbench de integracao do sdram_controller (P3_v2/Modulos)
// Fluxos: INIT -> WRITE -> READ -> REFRESH periodico
//
// Interface do DUT (sdram_controller):
//   - reset ativo-baixo (rstn)
//   - requisicao por wEn / rEn (sem 'req')
//   - dados de 16 bits separados: write_data (in) / read_data (out)
//   - sinais SDRAM em maiusculas: CSn,RASn,CASn,WEn,BA,addr,DQ,DQM
//   - DQ e' entrada do controlador: o TB dirige DQ nas leituras

module sdram_controller_tb;

    // ------------------------------------------------------------------
    // Parametros de simulacao (sobrescrevem os do DUT para acelerar)
    // ------------------------------------------------------------------
    localparam integer CLK_PERIOD = 20;     // 50 MHz na simulacao
    localparam integer T200US     = 50;     // espera de init reduzida
    localparam integer TREFI      = 60;     // intervalo de refresh reduzido

    // ------------------------------------------------------------------
    // Encodings de comando {CSn, RASn, CASn, WEn}
    // ------------------------------------------------------------------
    localparam [3:0] M_NOP = 4'b1111;   // default/deselect do DUT
    localparam [3:0] M_ACT = 4'b0011;
    localparam [3:0] M_RD  = 4'b0101;
    localparam [3:0] M_WR  = 4'b0100;
    localparam [3:0] M_PRE = 4'b0010;
    localparam [3:0] M_REF = 4'b0001;
    localparam [3:0] M_MRS = 4'b0000;

    // ------------------------------------------------------------------
    // Estados da FSM do DUT (mesma codificacao do sdram_controller.v)
    // ------------------------------------------------------------------
    localparam [4:0] S_INIT_WAIT = 5'd0,
                     S_INIT_PALL = 5'd1,
                     S_INIT_TRP  = 5'd2,
                     S_INIT_REF  = 5'd3,
                     S_INIT_TRC  = 5'd4,
                     S_INIT_MRS  = 5'd5,
                     S_INIT_TMRD = 5'd6,
                     S_HALT      = 5'd7,
                     S_ACT       = 5'd8,
                     S_TRCD      = 5'd9,
                     S_READ      = 5'd10,
                     S_CAS       = 5'd11,
                     S_RP_RD     = 5'd12,
                     S_WRITE     = 5'd13,
                     S_WR_RP     = 5'd14,
                     S_REF       = 5'd15,
                     S_TRFC      = 5'd16;

    integer err_count;

    // ------------------------------------------------------------------
    // Sinais
    // ------------------------------------------------------------------
    reg          clk;
    reg          rstn;          // reset ativo-baixo

    reg          wEn;
    reg          rEn;
    reg  [25:0]  address;
    reg  [15:0]  write_data;

    wire [15:0]  read_data;
    wire         ready;

    // Interface SDRAM
    wire         CSn, RASn, CASn, WEn;
    wire [1:0]   BA;
    wire [12:0]  addr;
    wire [15:0]  DQ;
    wire [1:0]   DQM;

    wire [3:0]   cmd = {CSn, RASn, CASn, WEn};

    // ------------------------------------------------------------------
    // Nomes legiveis para a forma de onda (aparecem como ASCII no GTKWave)
    //   cmd_str   -> nome do comando SDRAM atual ({CSn,RASn,CASn,WEn})
    //   state_str -> nome do estado atual da FSM (dut.state)
    // ------------------------------------------------------------------
    reg [8*9-1:0]  cmd_str;     // ate 9 caracteres
    reg [8*12-1:0] state_str;   // ate 12 caracteres

    always @(*) begin
        case (cmd)
            M_ACT:   cmd_str = "ACTIVATE";
            M_RD:    cmd_str = "READ";
            M_WR:    cmd_str = "WRITE";
            M_PRE:   cmd_str = "PRECHARGE";
            M_REF:   cmd_str = "AUTOREF";
            M_MRS:   cmd_str = "LMR";
            M_NOP:   cmd_str = "NOP";
            default: cmd_str = "?";
        endcase
    end

    always @(*) begin
        case (dut.state)
            S_INIT_WAIT: state_str = "INIT_WAIT";
            S_INIT_PALL: state_str = "INIT_PALL";
            S_INIT_TRP:  state_str = "INIT_TRP";
            S_INIT_REF:  state_str = "INIT_REF";
            S_INIT_TRC:  state_str = "INIT_TRC";
            S_INIT_MRS:  state_str = "INIT_MRS";
            S_INIT_TMRD: state_str = "INIT_TMRD";
            S_HALT:      state_str = "HALT";
            S_ACT:       state_str = "ACT";
            S_TRCD:      state_str = "TRCD";
            S_READ:      state_str = "READ";
            S_CAS:       state_str = "CAS";
            S_RP_RD:     state_str = "RP_RD";
            S_WRITE:     state_str = "WRITE";
            S_WR_RP:     state_str = "WR_RP";
            S_REF:       state_str = "REF";
            S_TRFC:      state_str = "TRFC";
            default:     state_str = "?";
        endcase
    end

    // ------------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------------
    sdram_controller #(
        .T_200US (T200US),
        .T_REFI  (TREFI)
    ) dut (
        .clk        (clk),
        .rstn       (rstn),
        .wEn        (wEn),
        .rEn        (rEn),
        .address    (address),
        .write_data (write_data),
        .read_data  (read_data),
        .ready      (ready),
        .CSn        (CSn),
        .RASn       (RASn),
        .CASn       (CASn),
        .WEn        (WEn),
        .BA         (BA),
        .addr       (addr),
        .DQ         (DQ),
        .DQM        (DQM)
    );

    // ------------------------------------------------------------------
    // Modelo comportamental simplificado da SDRAM
    //  - WRITE: a dado escrito vem de write_data (dirigido pelo TB),
    //           entao nao dependemos do barramento DQ na escrita.
    //  - READ : o TB dirige DQ com o valor armazenado, respeitando a
    //           latencia de CAS (pipeline de 2 estagios).
    //  - O endereco e' reconstruido de BA + linha ativa + coluna, igual
    //    ao mapeamento feito pelo controlador.
    // ------------------------------------------------------------------

    // Armazenamento associativo enxuto (evita alocar 64M posicoes)
    localparam integer NSLOTS = 64;
    reg [25:0] sd_tag [0:NSLOTS-1];
    reg [15:0] sd_dat [0:NSLOTS-1];
    reg        sd_vld [0:NSLOTS-1];

    // Linha ativa por banco
    reg [12:0] act_row [0:3];

    // Coluna reconstruida do barramento (A11<-COL[10], A10=0 sem auto-precharge)
    wire [10:0] col_bus  = {addr[11], addr[9:0]};
    // Endereco completo {banco, linha ativa, coluna}
    wire [25:0] full_addr = {BA, act_row[BA], col_bus};

    // Pipeline de latencia de CAS para a saida de leitura
    reg        v0, v1, drv;
    reg [15:0] d0, d1, d_drv;

    assign DQ = drv ? d_drv : 16'hzzzz;

    // Ultimo dado de leitura observado no barramento
    reg [15:0] last_read;

    integer k;
    reg     found;

    integer mi;
    initial begin
        for (mi = 0; mi < NSLOTS; mi = mi + 1) begin
            sd_vld[mi] = 1'b0;
            sd_tag[mi] = 26'd0;
            sd_dat[mi] = 16'd0;
        end
        for (mi = 0; mi < 4; mi = mi + 1) act_row[mi] = 13'd0;
        v0 = 0; v1 = 0; drv = 0;
        d0 = 0; d1 = 0; d_drv = 0;
        last_read = 16'd0;
    end

    always @(posedge clk) begin
        v0 <= 1'b0;

        case (cmd)
            M_ACT: act_row[BA] <= addr;                 // abre a linha do banco

            M_WR : begin                                // armazena write_data
                found = 1'b0;
                for (k = 0; k < NSLOTS; k = k + 1)
                    if (sd_vld[k] && sd_tag[k] == full_addr) begin
                        sd_dat[k] <= write_data;
                        found = 1'b1;
                    end
                if (!found)
                    for (k = 0; k < NSLOTS; k = k + 1)
                        if (!sd_vld[k] && !found) begin
                            sd_vld[k] <= 1'b1;
                            sd_tag[k] <= full_addr;
                            sd_dat[k] <= write_data;
                            found = 1'b1;
                        end
            end

            M_RD : begin                                // agenda saida com CL
                v0 <= 1'b1;
                d0 <= 16'h0000;
                for (k = 0; k < NSLOTS; k = k + 1)
                    if (sd_vld[k] && sd_tag[k] == full_addr)
                        d0 <= sd_dat[k];
            end

            default: ; // NOP / PRECHARGE / AREF / MRS: nada a fazer
        endcase

        // pipeline CL: dado dirigido alguns ciclos apos o comando READ
        v1  <= v0;   d1    <= d0;
        drv <= v1;   d_drv <= d1;

        // captura o dado de leitura quando esta sendo dirigido
        if (drv)
            last_read <= read_data;
    end

    // ------------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ------------------------------------------------------------------
    // Dump
    // ------------------------------------------------------------------
    initial begin
        $dumpfile("sdram_controller_tb.vcd");
        $dumpvars(0, sdram_controller_tb);
    end

    // ------------------------------------------------------------------
    // Log de comandos
    // ------------------------------------------------------------------
    reg     log_en;
    integer aref_runtime;
    initial begin log_en = 1'b0; aref_runtime = 0; end

    always @(posedge clk) begin
        case (cmd)
            M_ACT: $display("[%0t] ACTIVATE | ba=%0d row=0x%0h", $time, BA, addr);
            M_RD : $display("[%0t] READ     | ba=%0d col=0x%0h", $time, BA, col_bus);
            M_WR : $display("[%0t] WRITE    | ba=%0d col=0x%0h data=0x%0h",
                            $time, BA, col_bus, write_data);
            M_PRE: $display("[%0t] PRECHARGE| ba=%0d a10=%b", $time, BA, addr[10]);
            M_REF: begin
                       $display("[%0t] AUTOREF  | %s", $time, log_en ? "runtime" : "init");
                       if (log_en) aref_runtime = aref_runtime + 1;
                   end
            M_MRS: $display("[%0t] LMR      | mode=0x%0h", $time, addr);
            default: ;
        endcase
    end

    // ------------------------------------------------------------------
    // Geracao de endereco a partir de SW[9:4] (igual ao demo do enunciado)
    // ------------------------------------------------------------------
    function [25:0] mk_addr;
        input [5:0] sw_hi;
        begin
            mk_addr        = 26'd0;
            mk_addr[25]    = sw_hi[5];
            mk_addr[23:21] = sw_hi[4:2];
            mk_addr[1:0]   = sw_hi[1:0];
        end
    endfunction

    // ------------------------------------------------------------------
    // Tarefas de estimulo
    //  Mantem wEn/rEn ativos ate o controlador aceitar (S_HALT -> S_ACT),
    //  robusto mesmo com o refresh disputando o S_HALT.
    // ------------------------------------------------------------------
    task do_write;
        input [5:0] sw_hi;
        input [3:0] val;
        reg [25:0] a;
        begin
            a = mk_addr(sw_hi);
            @(negedge clk);
            address    = a;
            write_data = {12'd0, val};
            wEn        = 1'b1;
            rEn        = 1'b0;
            wait (dut.state == S_ACT);     // aceito (op_write latcheado)
            @(negedge clk);
            wEn        = 1'b0;
            wait (dut.state == S_HALT);    // escrita concluida
            @(posedge clk);
            $display(">> WRITE  addr(SW)=0x%02h val=0x%0h  (addr26=0x%07h)",
                     sw_hi, val, a);
        end
    endtask

    task do_read;
        input [5:0] sw_hi;
        input [3:0] expect;
        reg [25:0] a;
        begin
            a = mk_addr(sw_hi);
            @(negedge clk);
            address = a;
            rEn     = 1'b1;
            wEn     = 1'b0;
            wait (dut.state == S_ACT);     // aceito (op_write = 0)
            @(negedge clk);
            rEn     = 1'b0;
            wait (dut.state == S_HALT);    // leitura concluida
            @(posedge clk);
            if (last_read[3:0] === expect)
                $display(">> READ   addr(SW)=0x%02h -> 0x%0h  [OK esperado 0x%0h]",
                         sw_hi, last_read[3:0], expect);
            else begin
                $display(">> READ   addr(SW)=0x%02h -> 0x%0h  [FALHA esperado 0x%0h]",
                         sw_hi, last_read[3:0], expect);
                err_count = err_count + 1;
            end
        end
    endtask

    // ------------------------------------------------------------------
    // Sequencia principal
    // ------------------------------------------------------------------
    initial begin
        err_count  = 0;
        wEn = 0; rEn = 0; address = 0; write_data = 0;

        $display("=============================================================");
        $display(" Testbench sdram_controller | T_200US=%0d T_REFI=%0d", T200US, TREFI);
        $display("=============================================================");

        // --- FLUXO INIT ---
        rstn = 1'b0;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rstn = 1'b1;

        $display("\n--- FLUXO INIT (aguardando ready) ---");
        wait (ready === 1'b1);
        $display("[%0t] INIT concluida: ready=1", $time);
        log_en = 1'b1;   // a partir daqui, refreshes contam como 'runtime'

        // --- FLUXO WRITE (sequencia do demo) ---
        $display("\n--- FLUXO WRITE (sequencia do demo) ---");
        do_write(6'h01, 4'h1);
        do_write(6'h02, 4'h2);
        do_write(6'h0A, 4'h3);
        do_write(6'h20, 4'h4);
        do_write(6'h0A, 4'h5);   // sobrescreve 0x0A
        do_write(6'h2A, 4'h6);

        // --- FLUXO READ (verificacao do demo) ---
        $display("\n--- FLUXO READ (verificacao do demo) ---");
        do_read(6'h01, 4'h1);
        do_read(6'h02, 4'h2);
        do_read(6'h0A, 4'h5);    // valor sobrescrito
        do_read(6'h20, 4'h4);
        do_read(6'h2A, 4'h6);

        // --- FLUXO REFRESH (observa refresh periodico em repouso) ---
        $display("\n--- FLUXO REFRESH (aguardando refresh periodico em repouso) ---");
        begin : wait_refresh
            integer guard;
            guard = 0;
            while (aref_runtime < 1 && guard < (TREFI + 50)) begin
                @(posedge clk);
                guard = guard + 1;
            end
        end
        if (aref_runtime >= 1)
            $display("[%0t] REFRESH em runtime observado (total=%0d), ready=%b",
                     $time, aref_runtime, ready);
        else begin
            $display("[FALHA] Nenhum AUTO REFRESH em runtime observado.");
            err_count = err_count + 1;
        end

        // --- Resultado ---
        repeat (5) @(posedge clk);
        $display("\n=============================================================");
        if (err_count == 0)
            $display(" RESULTADO: TODOS OS FLUXOS PASSARAM (0 erros)");
        else
            $display(" RESULTADO: %0d FALHA(S) DETECTADA(S)", err_count);
        $display("=============================================================\n");
        $finish;
    end

    // ------------------------------------------------------------------
    // Timeout global
    // ------------------------------------------------------------------
    initial begin
        #(CLK_PERIOD * 80000);
        $display("[ERRO] Timeout global - simulacao interrompida.");
        $display(" RESULTADO: FALHA (timeout)");
        $finish;
    end

endmodule
