`timescale 1ns/1ps

module maquina_vendas_tb;

reg [9:0] SW;
reg [2:0] KEY;
reg CLOCK_50;

wire [6:0] HEX5;
wire [6:0] HEX3;
wire [6:0] HEX2;
wire [6:0] HEX1;
wire [6:0] HEX0;
wire [1:0] LEDR;

integer erros;

maquina_vendas uut (
    .SW(SW),
    .KEY(KEY),
    .CLOCK_50(CLOCK_50),
    .HEX5(HEX5),
    .HEX3(HEX3),
    .HEX2(HEX2),
    .HEX1(HEX1),
    .HEX0(HEX0),
    .LEDR(LEDR)
);

always #5 CLOCK_50 = ~CLOCK_50;

task pulse_5ms_sample;
    begin
        force uut.Clock.clk_5ms = 1'b1;
        @(posedge CLOCK_50);
        #1;
        release uut.Clock.clk_5ms;
    end
endtask

task debounce_commit;
    begin
        repeat (3) @(posedge CLOCK_50);
        pulse_5ms_sample();
        repeat (2) @(posedge CLOCK_50);
        pulse_5ms_sample();
        repeat (2) @(posedge CLOCK_50);
    end
endtask

initial begin
    CLOCK_50 = 0;
    SW = 10'b0;
    KEY = 3'b111;
    erros = 0;

    $display("=== Teste: maquina_vendas ===");

    // Debounce de KEY: aplica reset em KEY[2] e verifica entrada sincronizada.
    KEY = 3'b011;
    debounce_commit();
    if (uut.keys !== 3'b011) begin
        $display("[ERRO] Debounce/sincronizacao de KEY falhou. keys=%b", uut.keys);
        erros = erros + 1;
    end else begin
        $display("[OK] Debounce de KEY");
    end

    // Solta reset e confirma captura.
    KEY = 3'b111;
    debounce_commit();
    if (uut.keys !== 3'b111) begin
        $display("[ERRO] Liberacao de KEY falhou. keys=%b", uut.keys);
        erros = erros + 1;
    end else begin
        $display("[OK] Atualizacao de KEY apos debounce");
    end

    // Debounce de SW e validacao do registrador interno.
    SW = 10'b0000000011;
    debounce_commit();
    if (uut.switchs !== 10'b0000000011) begin
        $display("[ERRO] Debounce/sincronizacao de SW falhou. switchs=%b", uut.switchs);
        erros = erros + 1;
    end else begin
        $display("[OK] Debounce de SW");
    end

    // Estado inicial deve manter LEDs apagados.
    @(posedge CLOCK_50);
    #1;
    if (LEDR[0] !== 1'b0 || LEDR[1] !== 1'b0) begin
        $display("[ERRO] LEDs deveriam iniciar apagados. LEDR[0]=%b LEDR[1]=%b", LEDR[0], LEDR[1]);
        erros = erros + 1;
    end else begin
        $display("[OK] LEDs iniciais apagados");
    end

    // HEX5 deve refletir o produto selecionado.
    #1;
    if (HEX5 !== 7'b0110000) begin
        $display("[ERRO] HEX5 inesperado para produto 3. HEX5=%b", HEX5);
        erros = erros + 1;
    end else begin
        $display("[OK] HEX5 reflete selecao de produto 3");
    end

    // Caso extra: produto 0.
    SW = 10'b0000000000;
    debounce_commit();
    if (uut.switchs !== 10'b0000000000) begin
        $display("[ERRO] SW=0 nao foi sincronizado corretamente. switchs=%b", uut.switchs);
        erros = erros + 1;
    end else begin
        $display("[OK] Debounce de SW=0");
    end

    #1;
    if (HEX5 !== 7'b1000000) begin
        $display("[ERRO] HEX5 inesperado para produto 0. HEX5=%b", HEX5);
        erros = erros + 1;
    end else begin
        $display("[OK] HEX5 reflete selecao de produto 0");
    end

    // Caso extra: produto 1.
    SW = 10'b0000000001;
    debounce_commit();
    if (uut.switchs !== 10'b0000000001) begin
        $display("[ERRO] SW=1 nao foi sincronizado corretamente. switchs=%b", uut.switchs);
        erros = erros + 1;
    end else begin
        $display("[OK] Debounce de SW=1");
    end

    #1;
    if (HEX5 !== 7'b1111001) begin
        $display("[ERRO] HEX5 inesperado para produto 1. HEX5=%b", HEX5);
        erros = erros + 1;
    end else begin
        $display("[OK] HEX5 reflete selecao de produto 1");
    end

    // Caso extra: produto 8.
    SW = 10'b0000001000;
    debounce_commit();
    if (uut.switchs !== 10'b0000001000) begin
        $display("[ERRO] SW=8 nao foi sincronizado corretamente. switchs=%b", uut.switchs);
        erros = erros + 1;
    end else begin
        $display("[OK] Debounce de SW=8");
    end

    #1;
    if (HEX5 !== 7'b0000000) begin
        $display("[ERRO] HEX5 inesperado para produto 8. HEX5=%b", HEX5);
        erros = erros + 1;
    end else begin
        $display("[OK] HEX5 reflete selecao de produto 8");
    end

    // Caso extra: produto 9.
    SW = 10'b0000001001;
    debounce_commit();
    if (uut.switchs !== 10'b0000001001) begin
        $display("[ERRO] SW=9 nao foi sincronizado corretamente. switchs=%b", uut.switchs);
        erros = erros + 1;
    end else begin
        $display("[OK] Debounce de SW=9");
    end

    #1;
    if (HEX5 !== 7'b0010000) begin
        $display("[ERRO] HEX5 inesperado para produto 9. HEX5=%b", HEX5);
        erros = erros + 1;
    end else begin
        $display("[OK] HEX5 reflete selecao de produto 9");
    end

    // Reaplica reset para validar retorno ao estado sincronizado.
    KEY = 3'b011;
    debounce_commit();
    if (uut.keys !== 3'b011) begin
        $display("[ERRO] Segundo reset falhou. keys=%b", uut.keys);
        erros = erros + 1;
    end else begin
        $display("[OK] Segundo reset sincronizado");
    end

    if (erros == 0)
        $display("RESULTADO: TODOS OS TESTES PASSARAM");
    else
        $display("RESULTADO: %0d teste(s) falharam", erros);

    $finish;
end

endmodule