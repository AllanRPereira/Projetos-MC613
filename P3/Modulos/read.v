module read #(
    // PARÂMETROS AVALIADOS!
	parameter integer DATA_WIDTH = 8,
	parameter integer BANK_BITS = 2,
	parameter integer ROW_BITS = 13,
	parameter integer COL_BITS = 11,
	parameter integer TRCD_CYCLES = 3,
	parameter integer TCAS_CYCLES = 3,
	parameter integer TRP_CYCLES = 4,
	parameter PRECHARGE_ALL = 1'b0
) (
	input  wire                     clk,
	input  wire                     rst,
	input  wire                     start,
	input  wire [BANK_BITS+ROW_BITS+COL_BITS-1:0] addr,
	input  wire [DATA_WIDTH-1:0]    dq_in,

	output reg                      cke,
	output reg                      cs_n,
	output reg                      ras_n,
	output reg                      cas_n,
	output reg                      we_n,
	output reg  [1:0]               ba,
	output reg  [12:0]              a,

	output reg  [DATA_WIDTH-1:0]    data_out,
	output reg                      data_valid,
	output reg                      ready
);

	localparam integer ADDR_WIDTH = BANK_BITS + ROW_BITS + COL_BITS;
    // COMANDOS VALIDADOS!!
    
    // COMANDOS PARA A LEITURA
	localparam [3:0] CMD_NOP       = 4'b0111;
	localparam [3:0] CMD_ACTIVE    = 4'b0011;
	localparam [3:0] CMD_READ      = 4'b0101;
	localparam [3:0] CMD_PRECHARGE = 4'b0010;

    // ESTADOS DA FSM DE LEITURA
	localparam [3:0] S_IDLE       = 4'd0;
	localparam [3:0] S_ACTIVATE   = 4'd1;
	localparam [3:0] S_WAIT_RCD   = 4'd2;
	localparam [3:0] S_READ       = 4'd3;
	localparam [3:0] S_WAIT_CAS   = 4'd4;
	localparam [3:0] S_CAPTURE    = 4'd5;
	localparam [3:0] S_PRECHARGE  = 4'd6;
	localparam [3:0] S_WAIT_RP    = 4'd7;

	reg [3:0] state;
	reg [7:0] timer;
	reg [ADDR_WIDTH-1:0] addr_reg;

	wire [BANK_BITS-1:0] addr_bank = addr_reg[ADDR_WIDTH - 1: ADDR_WIDTH - BANK_BITS];
	wire [ROW_BITS-1:0]  addr_row  = addr_reg[ROW_BITS - 1 + COL_BITS: COL_BITS];
	wire [COL_BITS-1:0]  addr_col  = addr_reg[COL_BITS - 1:0];

	always @(posedge clk) begin
		if (rst) begin
			state <= S_IDLE;
			timer <= 8'd0;
			addr_reg <= {ADDR_WIDTH{1'b0}};
			data_out <= {DATA_WIDTH{1'b0}};
			data_valid <= 1'b0;
			ready <= 1'b1;

			cke <= 1'b1;
			{cs_n, ras_n, cas_n, we_n} <= CMD_NOP;
			ba <= 2'b00;
			a <= 13'b0;
		end else begin
			data_valid <= 1'b0;
			ready <= 1'b0;
			cke <= 1'b1;
			{cs_n, ras_n, cas_n, we_n} <= CMD_NOP;

			case (state)
				S_IDLE: begin
					ready <= 1'b1;
					timer <= 8'd0;
					if (start) begin
						addr_reg <= addr;
						state <= S_ACTIVATE;
					end
				end

				S_ACTIVATE: begin
					{cs_n, ras_n, cas_n, we_n} <= CMD_ACTIVE;
					ba <= addr_bank;
					a <= addr_row;
					timer <= 8'd0;
					state <= S_WAIT_RCD;
				end

				S_WAIT_RCD: begin
					if (timer >= TRCD_CYCLES - 1) begin
						timer <= 8'd0;
						state <= S_READ;
					end else begin
						timer <= timer + 1'b1;
					end
				end

				S_READ: begin
					{cs_n, ras_n, cas_n, we_n} <= CMD_READ;
					ba <= addr_bank;
                    // Desabilita o Auto Pre Charger em A10
					a <= {1'b0, addr_col[10], 1'b0, addr_col[9:0]};
					timer <= 8'd0;
					state <= S_WAIT_CAS;
				end

				S_WAIT_CAS: begin
					if (timer >= TCAS_CYCLES - 1) begin
						timer <= 8'd0;
						state <= S_CAPTURE;
					end else begin
						timer <= timer + 1'b1;
					end
				end

				S_CAPTURE: begin
					data_out <= dq_in;
					data_valid <= 1'b1;
					state <= S_PRECHARGE;
				end

				S_PRECHARGE: begin
					{cs_n, ras_n, cas_n, we_n} <= CMD_PRECHARGE;
					ba <= addr_bank;
					a <= 13'b0;
					a[10] <= PRECHARGE_ALL;
					timer <= 8'd0;
					state <= S_WAIT_RP;
				end

				S_WAIT_RP: begin
					if (timer >= TRP_CYCLES - 1) begin
						timer <= 8'd0;
						state <= S_IDLE;
					end else begin
						timer <= timer + 1'b1;
					end
				end

				default: begin
					state <= S_IDLE;
					timer <= 8'd0;
				end
			endcase
		end
	end

endmodule
