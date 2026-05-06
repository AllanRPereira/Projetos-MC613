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

	// Modelo simples de DRAM Controller
	reg [7:0] mem [0:63];
	reg [7:0] data_drv;
	reg data_drv_en;

	reg busy;
	reg [1:0] busy_cnt;

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

	assign data = data_drv_en ? data_drv : 8'bzzzzzzzz;

	// Clock
	initial clk = 1'b0;
	always #5 clk = ~clk;

	integer i;
	initial begin
		for (i = 0; i < 64; i = i + 1) begin
			mem[i] = {4'hB, i[3:0]};
		end
	end

	function [5:0] addr_index;
		input [25:0] addr;
		begin
			addr_index = {addr[25], addr[23:21], addr[1:0]};
		end
	endfunction

	// Modelo de resposta do controller:
	// - ready=1 quando o controller está livre
	// - quando req sobe: ready vai a 0 por 2 ciclos
	// - em escrita: captura data
	// - em leitura: devolve data no barramento quando ready volta a 1
	always @(posedge clk) begin
		if (rst) begin
			ready <= 1'b1;
			busy <= 1'b0;
			busy_cnt <= 2'b00;
			data_drv_en <= 1'b0;
			data_drv <= 8'h00;
		end else begin
			data_drv_en <= 1'b0;

			if (!busy && req) begin
				busy <= 1'b1;
				busy_cnt <= 2'b10;
				ready <= 1'b0;

				if (wEn) begin
					mem[addr_index(address)] <= data;
				end else begin
					data_drv <= mem[addr_index(address)];
				end
			end else if (busy) begin
				if (busy_cnt == 0) begin
					busy <= 1'b0;
					ready <= 1'b1;
					if (!wEn) begin
						data_drv_en <= 1'b1;
					end
				end else begin
					busy_cnt <= busy_cnt - 1'b1;
					ready <= 1'b0;
				end
			end else begin
				ready <= 1'b1;
			end
		end
	end

	// Monitoramento
	initial begin
		$display("Time  clk rst ready req wEn  SW      KEY  addr              data  HEX5 HEX4 HEX1 HEX0");
		$monitor("%4t  %b   %b   %b     %b   %b  %10b %4b %026b %8b  %4b  %4b  %4b  %4b",
				 $time, clk, rst, ready, req, wEn, SW, KEY, address, data, HEX5, HEX4, HEX1, HEX0);
	end

	// Sequência de estímulos simples
	initial begin
		rst = 1'b1;
		SW = 10'b0;
		KEY = 4'b0;
		data_drv = 8'b0;
		data_drv_en = 1'b0;
		busy = 1'b0;
		busy_cnt = 2'b00;

		@(posedge clk);
		rst = 1'b0;

		// Leitura por mudança de endereço
		SW = 10'b0000010000;
		@(posedge clk);
		@(posedge clk);

		// Escrita no mesmo endereço (KEY[3])
		SW = 10'b0000010011;
		KEY = 4'b1000;
		@(posedge clk);
		KEY = 4'b0000;
		@(posedge clk);

		// Força nova leitura
		SW = 10'b0100000000;
		@(posedge clk);
		@(posedge clk);

		SW = 10'b0100001110;
		KEY = 4'b1000;
		@(posedge clk);
		KEY = 4'b0000;
		@(posedge clk);

		SW = 10'b0100000000;
		@(posedge clk);
		@(posedge clk);

		$finish;
	end

endmodule
