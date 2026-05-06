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

	// Modelo simples de memória/DRAM (retorna nibble no data bus)
	reg [7:0] mem [0:63];
	reg [7:0] data_drv;
	reg data_drv_en;

	// DUT
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

	// Controle do barramento bidirecional
	assign data = data_drv_en ? data_drv : 8'bzzzzzzzz;

	// Clock
	initial clk = 1'b0;
	always #5 clk = ~clk;

	// Inicialização da memória
	integer i;
	initial begin
		for (i = 0; i < 64; i = i + 1) begin
			mem[i] = {4'hA, i[3:0]};
		end
	end

	// Helpers
	function [5:0] sw_addr;
		input [9:0] sw;
		begin
			sw_addr = sw[9:4];
		end
	endfunction

	task wait_cycles;
		input integer n;
		integer k;
		begin
			for (k = 0; k < n; k = k + 1) begin
				@(posedge clk);
			end
		end
	endtask

	task do_read;
		input [9:0] sw_addr_sel;
		input [7:0] mem_data;
		begin
			SW = sw_addr_sel;
			KEY = 4'b0000;

			// Sinaliza DRAM pronta; DUT deve solicitar leitura
			ready = 1'b1;
			data_drv_en = 1'b0;

			// Aguarda DUT levantar req para leitura
			wait(req == 1'b1);
			@(posedge clk);

			// DRAM responde ocupada
			ready = 1'b0;
			// Aguarda DUT entrar em WAIT_READ
			wait(wEn == 1'b0);
			wait(req == 1'b0);

			// DRAM volta pronta e dirige o barramento
			data_drv = mem_data;
			data_drv_en = 1'b1;
			ready = 1'b1;
			@(posedge clk);

			// Libera barramento
			data_drv_en = 1'b0;
			@(posedge clk);
		end
	endtask

	task do_write;
		input [9:0] sw_addr_sel;
		input [3:0] data_low_nibble;
		begin
			SW = {sw_addr_sel[9:4], data_low_nibble};
			KEY = 4'b1000; // KEY[3] ativo

			ready = 1'b1;
			data_drv_en = 1'b0;

			// DUT solicita escrita
			wait(req == 1'b1);
			@(posedge clk);
			ready = 1'b0;

			// Captura escrita
			if (wEn) begin
				mem[sw_addr(sw_addr_sel)] = data;
			end

			// Finaliza escrita
			@(posedge clk);
			ready = 1'b1;
			KEY = 4'b0000;
			@(posedge clk);
		end
	endtask

	// Monitoramento
	initial begin
		$display("Time  clk rst ready req wEn  SW      KEY  addr              data  HEX5 HEX4 HEX1 HEX0");
		$monitor("%4t  %b   %b   %b     %b   %b  %10b %4b %026b %8b  %4b  %4b  %4b  %4b",
				 $time, clk, rst, ready, req, wEn, SW, KEY, address, data, HEX5, HEX4, HEX1, HEX0);
	end

	// Sequência de testes
	initial begin
		// Defaults
		rst = 1'b1;
		SW = 10'b0;
		KEY = 4'b0;
		ready = 1'b0;
		data_drv = 8'b0;
		data_drv_en = 1'b0;

		wait_cycles(2);
		rst = 1'b0;
		ready = 1'b1;

		// Leitura inicial endereço 0
		do_read(10'b0000000000, mem[0]);

		// Leitura endereço diferente (gatilho por mudança de SW[9:4])
		do_read(10'b0101010000, mem[sw_addr(10'b0101010000)]);

		// Escrita e leitura do mesmo endereço
		do_write(10'b1111000000, 4'h3);
		do_read(10'b1111000000, mem[sw_addr(10'b1111000000)]);

		// Escrita em outro endereço
		do_write(10'b0010110000, 4'hE);
		do_read(10'b0010110000, mem[sw_addr(10'b0010110000)]);

		// Teste de reset assíncrono no meio de operação
		do_read(10'b0001110000, mem[sw_addr(10'b0001110000)]);
		rst = 1'b1;
		wait_cycles(1);
		rst = 1'b0;
		ready = 1'b1;
		do_read(10'b0001110000, mem[sw_addr(10'b0001110000)]);

		wait_cycles(5);
		$finish;
	end

endmodule
