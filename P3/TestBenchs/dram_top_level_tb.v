`timescale 1ns/1ps

module dram_top_level_tb;

reg CLOCK_50;
reg [3:0] KEY;
reg [9:0] SW;

wire [6:0] HEX0;
wire [6:0] HEX1;
wire [6:0] HEX2;
wire [6:0] HEX3;
wire [6:0] HEX4;
wire [6:0] HEX5;
wire [3:0] LEDR;

wire DRAM_CKE;
wire DRAM_CS_N;
wire DRAM_RAS_N;
wire DRAM_CAS_N;
wire DRAM_WE_N;
wire [1:0] DRAM_BA;
wire [12:0] DRAM_ADDR;
wire [15:0] DRAM_DQ;
wire DRAM_CLK;
wire DRAM_LDQM;
wire DRAM_UDQM;

reg dq_drive_en;
reg [7:0] dq_drive_value;
reg [7:0] latched_write_value;
integer errors;

assign DRAM_DQ[7:0] = dq_drive_en ? dq_drive_value : 8'hzz;
assign DRAM_DQ[15:8] = 8'hzz;

dram_top_level dut (
    .CLOCK_50(CLOCK_50),
    .KEY(KEY),
    .SW(SW),
    .HEX0(HEX0),
    .HEX1(HEX1),
    .HEX2(HEX2),
    .HEX3(HEX3),
    .HEX4(HEX4),
    .HEX5(HEX5),
    .LEDR(LEDR),
    .DRAM_CKE(DRAM_CKE),
    .DRAM_CS_N(DRAM_CS_N),
    .DRAM_RAS_N(DRAM_RAS_N),
    .DRAM_CAS_N(DRAM_CAS_N),
    .DRAM_WE_N(DRAM_WE_N),
    .DRAM_BA(DRAM_BA),
    .DRAM_ADDR(DRAM_ADDR),
    .DRAM_DQ(DRAM_DQ),
    .DRAM_CLK(DRAM_CLK),
    .DRAM_LDQM(DRAM_LDQM),
    .DRAM_UDQM(DRAM_UDQM)
);

always #5 CLOCK_50 = ~CLOCK_50;

function [6:0] expected_hex;
    input [3:0] value;
    begin
        case (value)
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
    CLOCK_50 = 1'b0;
    KEY = 4'b0000;
    SW = 10'b0000000000;
    dq_drive_en = 1'b0;
    dq_drive_value = 8'h00;
    latched_write_value = 8'h00;
    errors = 0;

    $dumpfile("dram_top_level_tb.vcd");
    $dumpvars(0, dram_top_level_tb);

    force dut.u_dram_controller.init_ready = 1'b1;

    repeat (2) @(posedge CLOCK_50);
    KEY[0] = 1'b1;

    wait (LEDR[2] === 1'b1);
    #1;

    if (DRAM_CLK !== CLOCK_50) begin
        $display("[ERRO] DRAM_CLK nao acompanha CLOCK_50");
        errors = errors + 1;
    end

    // Escreve o valor 5 no endereco base.
    SW = 10'b0000000101;
    KEY[3] = 1'b0;

    wait (LEDR[1] === 1'b1);
    #1;

    if (HEX0 !== expected_hex(4'h5)) begin
        $display("[ERRO] HEX0 nao mostrou o dado escrito");
        errors = errors + 1;
    end

    wait ({DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N} == 4'b0100);
    latched_write_value = DRAM_DQ[7:0];

    if (latched_write_value[3:0] !== 4'h5) begin
        $display("[ERRO] Barramento de escrita com valor inesperado: %h", latched_write_value);
        errors = errors + 1;
    end

    wait (LEDR[2] === 1'b1);

    // O mesmo endereco agora deve ser lido de volta.
    wait ({DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N} == 4'b0101);
    dq_drive_en = 1'b1;
    dq_drive_value = latched_write_value;

    wait (LEDR[3] === 1'b1);
    #1;
    dq_drive_en = 1'b0;

    wait (LEDR[2] === 1'b1);
    #1;

    if (HEX1 !== expected_hex(latched_write_value[3:0])) begin
        $display("[ERRO] HEX1 nao exibiu o dado lido de volta");
        errors = errors + 1;
    end

    if (errors == 0)
        $display("RESULTADO: dram_top_level validado com sucesso");
    else
        $display("RESULTADO: %0d erro(s) encontrado(s)", errors);

    $finish;
end

endmodule