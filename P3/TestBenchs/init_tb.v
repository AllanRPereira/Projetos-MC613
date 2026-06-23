`timescale 1ns/1ps

module init_tb;

    // ------------------------------------------------------------
    // Estados e comandos esperados
    // ------------------------------------------------------------

    localparam S_WAIT  = 3'd0;
    localparam S_PRECH = 3'd1;
    localparam S_REF1  = 3'd2;
    localparam S_REF2  = 3'd3;
    localparam S_MRS   = 3'd4;
    localparam S_DONE  = 3'd5;

    localparam CMD_NOP  = 4'b0111;
    localparam CMD_PALL = 4'b0010;
    localparam CMD_AREF = 4'b0001;
    localparam CMD_MRS  = 4'b0000;

    // ------------------------------------------------------------
    // Sinais
    // ------------------------------------------------------------

    reg clk;
    reg rst;

    wire cke;
    wire cs_n;
    wire ras_n;
    wire cas_n;
    wire we_n;
    wire [1:0] ba;
    wire [12:0] a;
    wire ready;

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
    // Funcoes de nome
    // ------------------------------------------------------------

    function [8*12-1:0] state_name;
        input [2:0] state;
        begin
            case (state)
                S_WAIT:  state_name = "S_WAIT";
                S_PRECH: state_name = "S_PRECH";
                S_REF1:  state_name = "S_REF1";
                S_REF2:  state_name = "S_REF2";
                S_MRS:   state_name = "S_MRS";
                S_DONE:  state_name = "S_DONE";
                default: state_name = "UNKNOWN";
            endcase
        end
    endfunction

    function [8*12-1:0] cmd_name;
        input [3:0] cmd;
        begin
            case (cmd)
                CMD_NOP:  cmd_name = "CMD_NOP";
                CMD_PALL: cmd_name = "CMD_PALL";
                CMD_AREF: cmd_name = "CMD_AREF";
                CMD_MRS:  cmd_name = "CMD_MRS";
                default:   cmd_name = "CMD_INV";
            endcase
        end
    endfunction

    // ------------------------------------------------------------
    // Cobertura visual
    // ------------------------------------------------------------

    integer errors;
    reg seen_wait;
    reg seen_prech;
    reg seen_ref1;
    reg seen_ref2;
    reg seen_mrs;
    reg seen_done;
    reg seen_nop;
    reg seen_pall;
    reg seen_aref;
    reg seen_mrs_cmd;

    reg [2:0] last_state;
    reg [3:0] last_cmd;

    always #5 clk = ~clk;

    always @(posedge clk) begin
        #1;

        if (rst === 1'b0) begin
            if (dut.state !== last_state || {cs_n, ras_n, cas_n, we_n} !== last_cmd) begin
                $display("t=%0t estado=%s comando=%s timer=%0d ready=%b ba=%b a=0x%h",
                         $time,
                         state_name(dut.state),
                         cmd_name({cs_n, ras_n, cas_n, we_n}),
                         dut.timer,
                         ready,
                         ba,
                         a);

                last_state = dut.state;
                last_cmd = {cs_n, ras_n, cas_n, we_n};
            end

            case (dut.state)
                S_WAIT:  seen_wait = 1'b1;
                S_PRECH: seen_prech = 1'b1;
                S_REF1:  seen_ref1 = 1'b1;
                S_REF2:  seen_ref2 = 1'b1;
                S_MRS:   seen_mrs = 1'b1;
                S_DONE:   seen_done = 1'b1;
            endcase

            case ({cs_n, ras_n, cas_n, we_n})
                CMD_NOP:  seen_nop = 1'b1;
                CMD_PALL: seen_pall = 1'b1;
                CMD_AREF: seen_aref = 1'b1;
                CMD_MRS:  seen_mrs_cmd = 1'b1;
            endcase
        end
    end

    // ------------------------------------------------------------
    // Estimulo principal
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;
        rst = 1'b1;

        errors = 0;
        seen_wait = 1'b0;
        seen_prech = 1'b0;
        seen_ref1 = 1'b0;
        seen_ref2 = 1'b0;
        seen_mrs = 1'b0;
        seen_done = 1'b0;
        seen_nop = 1'b0;
        seen_pall = 1'b0;
        seen_aref = 1'b0;
        seen_mrs_cmd = 1'b0;
        last_state = 3'bxxx;
        last_cmd = 4'bxxxx;

        $dumpfile("init_tb.vcd");
        $dumpvars(0, init_tb);

        $display("========================================");
        $display("TB INIT - VISUALIZACAO DE ESTADOS E COMANDOS");

        repeat (2) @(posedge clk);
        #1;

        if (dut.state !== S_WAIT) begin
            $display("[ERRO] Estado inicial esperado S_WAIT, mas foi %0d", dut.state);
            errors = errors + 1;
        end

        rst = 1'b0;
        $display("Reset liberado. Aguardando sequencia completa da inicializacao.");

        wait (ready === 1'b1);
        #1;

        if (!seen_wait) begin
            $display("[ERRO] S_WAIT nao foi observado");
            errors = errors + 1;
        end

        if (!seen_prech) begin
            $display("[ERRO] S_PRECH nao foi observado");
            errors = errors + 1;
        end

        if (!seen_ref1) begin
            $display("[ERRO] S_REF1 nao foi observado");
            errors = errors + 1;
        end

        if (!seen_ref2) begin
            $display("[ERRO] S_REF2 nao foi observado");
            errors = errors + 1;
        end

        if (!seen_mrs) begin
            $display("[ERRO] S_MRS nao foi observado");
            errors = errors + 1;
        end

        if (!seen_done) begin
            $display("[ERRO] S_DONE nao foi observado");
            errors = errors + 1;
        end

        if (!seen_nop) begin
            $display("[ERRO] CMD_NOP nao foi observado");
            errors = errors + 1;
        end

        if (!seen_pall) begin
            $display("[ERRO] CMD_PALL nao foi observado");
            errors = errors + 1;
        end

        if (!seen_aref) begin
            $display("[ERRO] CMD_AREF nao foi observado");
            errors = errors + 1;
        end

        if (!seen_mrs_cmd) begin
            $display("[ERRO] CMD_MRS nao foi observado");
            errors = errors + 1;
        end

        if (a !== 13'h0230) begin
            $display("[ERRO] MODE REGISTER incorreto: a=0x%h", a);
            errors = errors + 1;
        end

        $display("----------------------------------------");
        $display("Resumo da inicializacao:");
        $display("state=%s command=%s ready=%b", state_name(dut.state), cmd_name({cs_n, ras_n, cas_n, we_n}), ready);

        if (errors == 0)
            $display("RESULTADO: init validada com visualizacao completa dos estados e comandos");
        else
            $display("RESULTADO: %0d erro(s) encontrados", errors);

        $display("========================================");

        #20;
        $finish;
    end

endmodule