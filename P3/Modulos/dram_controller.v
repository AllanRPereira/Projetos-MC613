module dram_controller #(
	parameter integer DATA_WIDTH = 8,
	parameter integer ADDR_WIDTH = 26,
	parameter integer BANK_BITS = 2,
	parameter integer ROW_BITS = 13,
	parameter integer COL_BITS = 11,
	parameter integer TREFI_CYCLES = 1116,
	parameter integer TRFC_CYCLES = 10
) (
	input  wire                     clk,
	input  wire                     rst,

	input  wire                     req,
	input  wire                     wEn,
	input  wire [ADDR_WIDTH-1:0]    address,
	inout  wire [DATA_WIDTH-1:0]    data,

	output reg                      ready,
	output reg  [DATA_WIDTH-1:0]    data_out,
	output reg                      data_valid,

	// Interface SDRAM
	output reg                      cke,
	output reg                      cs_n,
	output reg                      ras_n,
	output reg                      cas_n,
	output reg                      we_n,
	output reg  [1:0]               ba,
	output reg  [12:0]              a,
	inout  wire [DATA_WIDTH-1:0]    dq
);

	localparam [3:0] CMD_NOP = 4'b0111;

	localparam [2:0] S_INIT          = 3'd0;
	localparam [2:0] S_IDLE          = 3'd1;
	localparam [2:0] S_READ_START    = 3'd2;
	localparam [2:0] S_READ_WAIT     = 3'd3;
	localparam [2:0] S_WRITE_START   = 3'd4;
	localparam [2:0] S_WRITE_WAIT    = 3'd5;
	localparam [2:0] S_REFRESH_GRANT = 3'd6;
	localparam [2:0] S_REFRESH_WAIT  = 3'd7;

	reg [2:0] state;
	reg [ADDR_WIDTH-1:0] addr_reg;
	reg [DATA_WIDTH-1:0] write_data_reg;
	reg [DATA_WIDTH-1:0] read_data_reg;
	reg read_data_hold_valid;

    // Conexões para liberar e obter o barramento para envio de dados.
	wire [DATA_WIDTH-1:0] host_data_in = data;
	wire host_data_oe = (state == S_IDLE) && read_data_hold_valid && !req && !wEn;

	assign data = host_data_oe ? read_data_reg : {DATA_WIDTH{1'bz}};

	// INIT
	wire init_ready;
	wire init_cs_n;
	wire init_ras_n;
	wire init_cas_n;
	wire init_we_n;
	wire [1:0] init_ba;
	wire [12:0] init_a;

	init u_init (
		.clk(clk),
		.rst(rst),
		.cke(),
		.cs_n(init_cs_n),
		.ras_n(init_ras_n),
		.cas_n(init_cas_n),
		.we_n(init_we_n),
		.ba(init_ba),
		.a(init_a),
		.ready(init_ready)
	);

	// READ
	wire read_ready;
	wire [DATA_WIDTH-1:0] read_data;
	wire read_data_valid;
	wire read_cs_n;
	wire read_ras_n;
	wire read_cas_n;
	wire read_we_n;
	wire [1:0] read_ba;
	wire [12:0] read_a;

	read #(
		.DATA_WIDTH(DATA_WIDTH),
		.BANK_BITS(BANK_BITS),
		.ROW_BITS(ROW_BITS),
		.COL_BITS(COL_BITS)
	) u_read (
		.clk(clk),
		.rst(rst),
		.start(state == S_READ_START),
		.addr(addr_reg),
		.dq_in(dq),
		.cke(),
		.cs_n(read_cs_n),
		.ras_n(read_ras_n),
		.cas_n(read_cas_n),
		.we_n(read_we_n),
		.ba(read_ba),
		.a(read_a),
		.data_out(read_data),
		.data_valid(read_data_valid),
		.ready(read_ready)
	);

	// WRITE
	wire write_cs_n;
	wire write_ras_n;
	wire write_cas_n;
	wire write_we_n;
	wire [1:0] write_ba;
	wire [12:0] write_a;
	wire write_done;
	wire write_busy;

	write u_write (
		.clk(clk),
		.rst(rst),
		.start(state == S_WRITE_START),
		.address(addr_reg),
		.data_in(write_data_reg),
		.cs_n(write_cs_n),
		.ras_n(write_ras_n),
		.cas_n(write_cas_n),
		.we_n(write_we_n),
		.ba(write_ba),
		.a(write_a),
		.dq(dq),
		.busy(write_busy),
		.done(write_done)
	);

	// AUTO REFRESH
	wire refresh_req;
	wire refresh_done;
	wire refresh_cs_n;
	wire refresh_ras_n;
	wire refresh_cas_n;
	wire refresh_we_n;
	wire [1:0] refresh_ba;
	wire [12:0] refresh_a;

	autorefresh #(
		.TREFI_CYCLES(TREFI_CYCLES),
		.TRFC_CYCLES(TRFC_CYCLES)
	) u_refresh (
		.clk(clk),
		.rst(rst),
		.enable(init_ready),
		.grant(state == S_REFRESH_GRANT),
		.cke(),
		.cs_n(refresh_cs_n),
		.ras_n(refresh_ras_n),
		.cas_n(refresh_cas_n),
		.we_n(refresh_we_n),
		.ba(refresh_ba),
		.a(refresh_a),
		.refresh_req(refresh_req),
		.busy(),
		.done(refresh_done)
	);

	// FSM principal
	always @(posedge clk) begin
		if (rst) begin
			state <= S_INIT;
			addr_reg <= {ADDR_WIDTH{1'b0}};
			write_data_reg <= {DATA_WIDTH{1'b0}};
			read_data_reg <= {DATA_WIDTH{1'b0}};
			read_data_hold_valid <= 1'b0;
			data_out <= {DATA_WIDTH{1'b0}};
			data_valid <= 1'b0;
			ready <= 1'b0;
		end else begin
			data_valid <= 1'b0;
			ready <= (state == S_IDLE);

			if (state == S_IDLE && req) begin
				addr_reg <= address;
				if (wEn) begin
					write_data_reg <= host_data_in;
				end
			end

			if (read_data_valid) begin
				read_data_reg <= read_data;
				read_data_hold_valid <= 1'b1;
				data_out <= read_data;
				data_valid <= 1'b1;
			end

			case (state)
				S_INIT: begin
					if (init_ready) begin
						state <= S_IDLE;
					end
				end

				S_IDLE: begin
					if (req) begin
						if (wEn) begin
							state <= S_WRITE_START;
						end else begin
							state <= S_READ_START;
						end
					end else if (refresh_req) begin
						state <= S_REFRESH_GRANT;
					end
				end

				S_READ_START: begin
					state <= S_READ_WAIT;
				end

				S_READ_WAIT: begin
					if (read_ready) begin
						state <= S_IDLE;
					end
				end

				S_WRITE_START: begin
					state <= S_WRITE_WAIT;
				end

				S_WRITE_WAIT: begin
					if (write_done) begin
						state <= S_IDLE;
					end
				end

				S_REFRESH_GRANT: begin
					state <= S_REFRESH_WAIT;
				end

				S_REFRESH_WAIT: begin
					if (refresh_done) begin
						state <= S_IDLE;
					end
				end

				default: begin
					state <= S_INIT;
				end
			endcase
		end
	end

	// Mux de sinais SDRAM
	always @(*) begin
        // Estado default
		cke = 1'b1;
		{cs_n, ras_n, cas_n, we_n} = CMD_NOP;
		ba = 2'b00;
		a = 13'b0;

		case (state)
			S_INIT: begin
				cs_n = init_cs_n;
				ras_n = init_ras_n;
				cas_n = init_cas_n;
				we_n = init_we_n;
				ba = init_ba;
				a = init_a;
			end
			S_READ_START, S_READ_WAIT: begin
				cs_n = read_cs_n;
				ras_n = read_ras_n;
				cas_n = read_cas_n;
				we_n = read_we_n;
				ba = read_ba;
				a = read_a;
			end
			S_WRITE_START, S_WRITE_WAIT: begin
				cs_n = write_cs_n;
				ras_n = write_ras_n;
				cas_n = write_cas_n;
				we_n = write_we_n;
				ba = write_ba;
				a = write_a;
			end
			S_REFRESH_GRANT, S_REFRESH_WAIT: begin
				cs_n = refresh_cs_n;
				ras_n = refresh_ras_n;
				cas_n = refresh_cas_n;
				we_n = refresh_we_n;
				ba = refresh_ba;
				a = refresh_a;
			end
			default: begin
				{cs_n, ras_n, cas_n, we_n} = CMD_NOP;
				ba = 2'b00;
				a = 13'b0;
			end
		endcase
	end

endmodule
