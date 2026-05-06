`timescale 1ns/1ps

module dram_iface_tb;
	reg clk;
	reg rst;
	reg [9:0] SW;
	reg [3:0] KEY;
	reg ready;
	wire [7:0] data;

	wire [3:0] HEX0, HEX1, HEX4, HEX5;
	wire [25:0] address;
	wire req;
	wire wEn;

	// Barramento de dados controlado pelo TB
	reg [7:0] tb_data;
	reg tb_drive;

	dram_iface dut (
		.clk(clk),
		.rst(rst),
		.SW(SW),
		.KEY(KEY),
		.ready(ready),
		.data(data),
		.HEX0(HEX0),
		.HEX1(HEX1),
		.HEX4(HEX4),
		.HEX5(HEX5),
		.address(address),
		.req(req),
		.wEn(wEn)
	);

    // Alta impedância para controlar corretamente o IO 
	assign data = tb_drive ? tb_data : 8'bzzzzzzzz;

	// Clock
	initial clk = 1'b0;
	always #5 clk = ~clk;

	// Monitoramento
	initial begin
		$display("Time  clk rst ready req wEn  SW      KEY  addr              data");
		$monitor("%4t  %b   %b   %b     %b   %b  %10b %4b %026b %8b",
				 $time, clk, rst, ready, req, wEn, SW, KEY, address, data);
	end

	// Estímulos com controle variável a variável, a cada ciclo
	initial begin
		// ciclo 0: define tudo explicitamente
		rst = 1'b1;
		SW = 10'b0000000000;
		KEY = 4'b0000;
		ready = 1'b0;
		tb_data = 8'h00;
		tb_drive = 1'b0;

		@(posedge clk);
		// ciclo 1: libera reset
		rst = 1'b0;
		SW = 10'b0000000000;
		KEY = 4'b0000;
		ready = 1'b1;
		tb_data = 8'h00;
		tb_drive = 1'b0;

		@(posedge clk);
		// ciclo 2: muda endereço para forçar leitura
		rst = 1'b0;
		SW = 10'b0000010000;
		KEY = 4'b0000;
		ready = 1'b1;
		tb_data = 8'h00;
		tb_drive = 1'b0;

		@(posedge clk);
		// ciclo 3: simula controller ocupado
		rst = 1'b0;
		SW = 10'b0000010000;
		KEY = 4'b0000;
		ready = 1'b0;
		tb_data = 8'h00;
		tb_drive = 1'b0;

		@(posedge clk);
		// ciclo 4: controller pronto e fornece dado de leitura
		rst = 1'b0;
		SW = 10'b0000010000;
		KEY = 4'b0000;
		ready = 1'b1;
		tb_data = 8'h3C;
		tb_drive = 1'b1;

		@(posedge clk);
		// ciclo 5: libera barramento
		rst = 1'b0;
		SW = 10'b0000010000;
		KEY = 4'b0000;
		ready = 1'b1;
		tb_data = 8'h00;
		tb_drive = 1'b0;

		@(posedge clk);
		// ciclo 6: prepara escrita (KEY[3]=1) com dado em SW[3:0]
		rst = 1'b0;
		SW = 10'b0000010101; // endereço + dado 0x5
		KEY = 4'b1000;
		ready = 1'b1;
		tb_data = 8'h00;
		tb_drive = 1'b0;

		@(posedge clk);
		// ciclo 7: controller ocupado na escrita
		rst = 1'b0;
		SW = 10'b0000010101;
		KEY = 4'b0000;
		ready = 1'b0;
		tb_data = 8'h00;
		tb_drive = 1'b0;

		@(posedge clk);
		// ciclo 8: controller pronto novamente
		rst = 1'b0;
		SW = 10'b0000010101;
		KEY = 4'b0000;
		ready = 1'b1;
		tb_data = 8'h00;
		tb_drive = 1'b0;

		@(posedge clk);
		$finish;
	end

endmodule
