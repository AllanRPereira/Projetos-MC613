`timescale 1ns/1ps

module dram_controller_tb;

localparam DATA_WIDTH = 8;
localparam ADDR_WIDTH = 26;

reg clk;
reg rst;
reg req;
reg wEn;
reg [ADDR_WIDTH-1:0] address;

reg drive_data;
reg [DATA_WIDTH-1:0] host_data;
wire [DATA_WIDTH-1:0] data;

reg drive_dq;
reg [DATA_WIDTH-1:0] sdram_data;
wire [DATA_WIDTH-1:0] dq;

wire ready;
wire [DATA_WIDTH-1:0] data_out;
wire data_valid;
wire cke;
wire cs_n;
wire ras_n;
wire cas_n;
wire we_n;
wire [1:0] ba;
wire [12:0] a;

integer errors;

assign data = drive_data ? host_data : {DATA_WIDTH{1'bz}};
assign dq = drive_dq ? sdram_data : {DATA_WIDTH{1'bz}};

dram_controller #(
    .TREFI_CYCLES(12),
    .TRFC_CYCLES(3)
) dut (
    .clk(clk),
    .rst(rst),
    .req(req),
    .wEn(wEn),
    .address(address),
    .data(data),
    .ready(ready),
    .data_out(data_out),
    .data_valid(data_valid),
    .cke(cke),
    .cs_n(cs_n),
    .ras_n(ras_n),
    .cas_n(cas_n),
    .we_n(we_n),
    .ba(ba),
    .a(a),
    .dq(dq)
);

always #5 clk = ~clk;

initial begin
    clk = 1'b0;
    rst = 1'b1;
    req = 1'b0;
    wEn = 1'b0;
    address = {ADDR_WIDTH{1'b0}};
    drive_data = 1'b0;
    host_data = {DATA_WIDTH{1'b0}};
    drive_dq = 1'b0;
    sdram_data = {DATA_WIDTH{1'b0}};
    errors = 0;

    force dut.init_ready = 1'b1;

    $dumpfile("dram_controller_tb.vcd");
    $dumpvars(0, dram_controller_tb);

    repeat (2) @(posedge clk);
    rst = 1'b0;

    wait (ready === 1'b1);
    #1;

    drive_data = 1'b1;
    host_data = 8'hA5;
    address = 26'h0123456;
    wEn = 1'b1;
    req = 1'b1;

    @(posedge clk);
    #1;

    req = 1'b0;
    wEn = 1'b0;
    drive_data = 1'b0;

    wait (ready === 1'b1);
    #1;

    repeat (14) @(posedge clk);

    wait (dut.refresh_req === 1'b1);
    #1;

    wait (dut.refresh_done === 1'b1);
    #1;

    if (ready !== 1'b1) begin
        $display("[ERRO] ready deveria voltar para 1 apos refresh");
        errors = errors + 1;
    end

    address = 26'h0234567;
    req = 1'b1;
    wEn = 1'b0;

    @(posedge clk);
    #1;
    req = 1'b0;

    wait ({cs_n, ras_n, cas_n, we_n} == 4'b0101);
    drive_dq = 1'b1;
    sdram_data = 8'h3C;

    repeat (4) @(posedge clk);
    drive_dq = 1'b0;

    wait (data_valid === 1'b1);
    #1;

    if (data_out !== 8'h3C) begin
        $display("[ERRO] Leitura retornou valor errado. Esperado=3C Obtido=%h", data_out);
        errors = errors + 1;
    end

    if (errors == 0)
        $display("RESULTADO: dram_controller validado com sucesso");
    else
        $display("RESULTADO: %0d erro(s) encontrado(s)", errors);

    $finish;
end

endmodule