`timescale 1ns/1ps

module autorefresh_tb;

reg clk;
reg rst;
reg enable;
reg grant;

wire cke;
wire cs_n;
wire ras_n;
wire cas_n;
wire we_n;
wire [1:0] ba;
wire [12:0] a;
wire refresh_req;
wire busy;
wire done;

integer errors;

autorefresh #(
    .TREFI_CYCLES(4),
    .TRFC_CYCLES(3)
) dut (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .grant(grant),
    .cke(cke),
    .cs_n(cs_n),
    .ras_n(ras_n),
    .cas_n(cas_n),
    .we_n(we_n),
    .ba(ba),
    .a(a),
    .refresh_req(refresh_req),
    .busy(busy),
    .done(done)
);

always #5 clk = ~clk;

initial begin
    clk = 1'b0;
    rst = 1'b1;
    enable = 1'b0;
    grant = 1'b0;
    errors = 0;

    $dumpfile("autorefresh_tb.vcd");
    $dumpvars(0, autorefresh_tb);

    repeat (2) @(posedge clk);
    #1;
    if (refresh_req !== 1'b0 || busy !== 1'b0) begin
        $display("[ERRO] Reset nao limpou os sinais de estado");
        errors = errors + 1;
    end

    rst = 1'b0;
    enable = 1'b1;

    wait (refresh_req === 1'b1);
    #1;

    if (busy !== 1'b0) begin
        $display("[ERRO] busy deveria permanecer 0 antes do grant");
        errors = errors + 1;
    end

    grant = 1'b1;
    @(posedge clk);
    #1;

    if ({cs_n, ras_n, cas_n, we_n} !== 4'b0001) begin
        $display("[ERRO] Comando de auto refresh incorreto: %b%b%b%b", cs_n, ras_n, cas_n, we_n);
        errors = errors + 1;
    end

    grant = 1'b0;

    wait (done === 1'b1);
    #1;

    if (busy !== 1'b0) begin
        $display("[ERRO] busy deveria voltar para 0 ao finalizar");
        errors = errors + 1;
    end

    if (errors == 0)
        $display("RESULTADO: autorefresh validado com sucesso");
    else
        $display("RESULTADO: %0d erro(s) encontrado(s)", errors);

    $finish;
end

endmodule