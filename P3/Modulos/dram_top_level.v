module dram_top_level (
	input  wire        CLOCK_50,
	input  wire [3:0]  KEY,
	input  wire [9:0]  SW,
	output wire [6:0]  HEX0,
	output wire [6:0]  HEX1,
	output wire [6:0]  HEX2,
	output wire [6:0]  HEX3,
	output wire [6:0]  HEX4,
	output wire [6:0]  HEX5,
	output wire [9:0]  LEDR,

	// SDRAM interface (DE1-SoC)
	output wire        DRAM_CKE,
	output wire        DRAM_CS_N,
	output wire        DRAM_RAS_N,
	output wire        DRAM_CAS_N,
	output wire        DRAM_WE_N,
	output wire [1:0]  DRAM_BA,
	output wire [12:0] DRAM_ADDR,
	inout  wire [15:0] DRAM_DQ,
	output wire        DRAM_CLK,
	output wire        DRAM_LDQM,
	output wire        DRAM_UDQM
);

	wire rst = ~KEY[0];

	// Debounce para a tecla usada como comando de escrita/leitura.
	// KEY[3] na placa é ativa em nível baixo, então convertemos para ativo-alto
	// e exigimos estabilidade por um período antes de repassar ao dram_iface.
	localparam integer KEY_DEBOUNCE_MAX = 500000; // ~10 ms @ 50 MHz

	reg key3_meta;
	reg key3_sync;
	reg key3_stable;
	reg [18:0] key3_counter;
	wire key3_raw = ~KEY[3];
	wire key3_debounced;

	wire [7:0] user_data;
	wire [25:0] address;
	wire req;
	wire wEn;
	wire ready;

	wire [3:0] hex0_n;
	wire [3:0] hex1_n;
	wire [3:0] hex4_n;
	wire [3:0] hex5_n;

	wire [7:0] ctrl_data_out;
	wire ctrl_data_valid;
	wire ctrl_cke;
	wire ctrl_cs_n;
	wire ctrl_ras_n;
	wire ctrl_cas_n;
	wire ctrl_we_n;
	wire [1:0] ctrl_ba;
	wire [12:0] ctrl_a;

	assign key3_debounced = key3_stable;

	always @(posedge CLOCK_50) begin
		if (rst) begin
			key3_meta <= 1'b0;
			key3_sync <= 1'b0;
			key3_stable <= 1'b0;
			key3_counter <= 19'd0;
		end else begin
			key3_meta <= key3_raw;
			key3_sync <= key3_meta;

			if (key3_sync == key3_stable) begin
				key3_counter <= 19'd0;
			end else if (key3_counter >= KEY_DEBOUNCE_MAX - 1) begin
				key3_stable <= key3_sync;
				key3_counter <= 19'd0;
			end else begin
				key3_counter <= key3_counter + 1'b1;
			end
		end
	end

	dram_iface u_dram_iface (
		.clk(CLOCK_50),
		.rst(rst),
		.SW(SW),
		.KEY(key3_debounced),
		.ready(ready),
		.data(user_data),
		.HEX0(hex0_n),
		.HEX1(hex1_n),
		.HEX4(hex4_n),
		.HEX5(hex5_n),
		.address(address),
		.req(req),
		.wEn(wEn),
		.leds(LEDR[9:5])
	);

	dram_controller u_dram_controller (
		.clk(CLOCK_50),
		.rst(rst),
		.req(req),
		.wEn(wEn),
		.address(address),
		.data(user_data),
		.ready(ready),
		.data_out(ctrl_data_out),
		.data_valid(ctrl_data_valid),
		.leds(LEDR[9:5]),
		.cke(ctrl_cke),
		.cs_n(ctrl_cs_n),
		.ras_n(ctrl_ras_n),
		.cas_n(ctrl_cas_n),
		.we_n(ctrl_we_n),
		.ba(ctrl_ba),
		.a(ctrl_a),
		.dq(DRAM_DQ[7:0])
	);

	bin2hex u_hex0 (.clk(CLOCK_50), .lock(1'b0), .reset(rst), .bin(hex0_n), .hex(HEX0));
	bin2hex u_hex1 (.clk(CLOCK_50), .lock(1'b0), .reset(rst), .bin(hex1_n), .hex(HEX1));
	bin2hex u_hex4 (.clk(CLOCK_50), .lock(1'b0), .reset(rst), .bin(hex4_n), .hex(HEX4));
	bin2hex u_hex5 (.clk(CLOCK_50), .lock(1'b0), .reset(rst), .bin(hex5_n), .hex(HEX5));

	assign HEX2 = 7'b1111111;
	assign HEX3 = 7'b1111111;

	assign LEDR[0] = req;
	assign LEDR[1] = wEn;
	assign LEDR[2] = ready;
	assign LEDR[3] = ctrl_data_valid;

	assign DRAM_CKE = ctrl_cke;
	assign DRAM_CS_N = ctrl_cs_n;
	assign DRAM_RAS_N = ctrl_ras_n;
	assign DRAM_CAS_N = ctrl_cas_n;
	assign DRAM_WE_N = ctrl_we_n;
	assign DRAM_BA = ctrl_ba;
	assign DRAM_ADDR = ctrl_a;
	assign DRAM_CLK = CLOCK_50;
	assign DRAM_LDQM = 1'b0;
	assign DRAM_UDQM = 1'b1;

	assign DRAM_DQ[15:8] = 8'hzz;

endmodule
