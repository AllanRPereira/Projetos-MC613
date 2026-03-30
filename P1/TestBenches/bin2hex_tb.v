`timescale 1ns/1ps

module bin2hex_tb;

reg clk;
reg lock;
reg reset;
reg [3:0] bin;
wire [6:0] hex;

integer erros;
integer i;

bin2hex uut (
    .clk(clk),
    .lock(lock),
    .reset(reset),
    .bin(bin),
    .hex(hex)
);

always #5 clk = ~clk;

function [6:0] expected_hex;
    input [3:0] d;
    begin
        case (d)
            4'h0: expected_hex = 7'b1000000;
            4'h1: expected_hex = 7'b1111001;
            4'h2: expected_hex = 7'b0100100;
            4'h3: expected_hex = 7'b0110000;
            4'h4: expected_hex = 7'b0011001;
            4'h5: expected_hex = 7'b0010010;
            4'h6: expected_hex = 7'b0000010;
            4'h7: expected_hex = 7'b1111000;
            4'h8: expected_hex = 7'b0000000;
            4'h9: expected_hex = 7'b0010000;
            4'hA: expected_hex = 7'b0001000;
            4'hB: expected_hex = 7'b0000011;
            4'hC: expected_hex = 7'b1000110;
            4'hD: expected_hex = 7'b0100001;
            4'hE: expected_hex = 7'b0000110;
            4'hF: expected_hex = 7'b0001110;
            default: expected_hex = 7'b1111111;
        endcase
    end
endfunction

initial begin
    clk = 0;
    lock = 0;
    reset = 1;
    bin = 4'h0;
    erros = 0;

    $display("=== Teste: bin2hex ===");

    @(posedge clk);
    #1;
    if (hex !== 7'b1000000) begin
        $display("[ERRO] Reset falhou. Esperado=1000000, obtido=%b", hex);
        erros = erros + 1;
    end else begin
        $display("[OK] Reset");
    end

    reset = 0;

    for (i = 0; i < 16; i = i + 1) begin
        bin = i[3:0];
        @(posedge clk);
        #1;
        if (hex !== expected_hex(i[3:0])) begin
            $display("[ERRO] bin=%0d Esperado=%b Obtido=%b", i, expected_hex(i[3:0]), hex);
            erros = erros + 1;
        end
    end
    if (erros == 0)
        $display("[OK] Tabela completa 0..15");

    bin = 4'h5;
    @(posedge clk);
    #1;
    lock = 1;
    bin = 4'hA;
    @(posedge clk);
    #1;
    if (hex !== expected_hex(4'h5)) begin
        $display("[ERRO] lock falhou. Esperado hex de 5, obtido=%b", hex);
        erros = erros + 1;
    end else begin
        $display("[OK] lock trava atualizacao");
    end

    lock = 0;
    @(posedge clk);
    #1;
    if (hex !== expected_hex(4'hA)) begin
        $display("[ERRO] desbloqueio falhou. Esperado hex de A, obtido=%b", hex);
        erros = erros + 1;
    end else begin
        $display("[OK] desbloqueio");
    end

    if (erros == 0)
        $display("RESULTADO: TODOS OS TESTES PASSARAM");
    else
        $display("RESULTADO: %0d teste(s) falharam", erros);

    $finish;
end

endmodule
