`timescale 1ns/1ps

module clock_tb;

reg clk;
wire clk_1s;
wire clk_5ms;

integer erros;

clock uut (
    .clk(clk),
    .clk_1s(clk_1s),
    .clk_5ms(clk_5ms)
);

always #1 clk = ~clk;

initial begin
    $dumpfile("clock.vcd");
    $dumpvars(0, clock_tb);

    clk = 0;
    erros = 0;

    $display("=== Teste: clock ===");

    if (clk_1s !== 1'b0 || clk_5ms !== 1'b0) begin
        $display("[ERRO] Pulsos devem iniciar em zero.");
        erros = erros + 1;
    end else begin
        $display("[OK] Estado inicial dos pulsos");
    end

    // Forca contador_5ms para o limite e valida pulso de 1 ciclo.
    uut.contador_5ms = 18'd249_999;
    @(posedge clk);
    #1;
    if (clk_5ms !== 1'b1) begin
        $display("[ERRO] Pulso clk_5ms nao gerado no limite.");
        erros = erros + 1;
    end else begin
        $display("[OK] Pulso clk_5ms gerado");
    end

    @(posedge clk);
    #1;
    if (clk_5ms !== 1'b0) begin
        $display("[ERRO] clk_5ms deveria voltar para zero no ciclo seguinte.");
        erros = erros + 1;
    end else begin
        $display("[OK] clk_5ms com largura de 1 ciclo");
    end

    // Forca contador_1s para o limite e valida pulso de 1 ciclo.
    uut.contador_1s = 26'd49_999_999;
    @(posedge clk);
    #1;
    if (clk_1s !== 1'b1) begin
        $display("[ERRO] Pulso clk_1s nao gerado no limite.");
        erros = erros + 1;
    end else begin
        $display("[OK] Pulso clk_1s gerado");
    end

    @(posedge clk);
    #1;
    if (clk_1s !== 1'b0) begin
        $display("[ERRO] clk_1s deveria voltar para zero no ciclo seguinte.");
        erros = erros + 1;
    end else begin
        $display("[OK] clk_1s com largura de 1 ciclo");
    end

    if (erros == 0)
        $display("RESULTADO: TODOS OS TESTES PASSARAM");
    else
        $display("RESULTADO: %0d teste(s) falharam", erros);

    $finish;
end

endmodule
