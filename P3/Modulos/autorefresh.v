module autorefresh #(
	parameter integer TREFI_CYCLES = 1116,
	parameter integer TRFC_CYCLES = 10
) (
	input  wire        clk,
	input  wire        rst,
	input  wire        enable,
	input  wire        grant,

	output reg         cke,
	output reg         cs_n,
	output reg         ras_n,
	output reg         cas_n,
	output reg         we_n,
	output reg  [1:0]  ba,
	output reg  [12:0] a,

	output reg         refresh_req,
	output reg         busy,
	output reg         done
);

	localparam [3:0] CMD_NOP  = 4'b0111;
	localparam [3:0] CMD_AREF = 4'b0001;

	localparam [1:0] S_IDLE  = 2'd0;
	localparam [1:0] S_REQ   = 2'd1;
	localparam [1:0] S_WAIT  = 2'd2;

	reg [1:0]  state;
	reg [15:0] ref_timer;
	reg [15:0] rfc_timer;

	always @(posedge clk) begin
		if (rst) begin
			state <= S_IDLE;
			ref_timer <= 16'd0;
			rfc_timer <= 16'd0;
			refresh_req <= 1'b0;
			busy <= 1'b0;
			done <= 1'b0;

			cke <= 1'b1;
			{cs_n, ras_n, cas_n, we_n} <= CMD_NOP;
			ba <= 2'b00;
			a <= 13'b0;
		end else begin
			done <= 1'b0;
			cke <= 1'b1;
			{cs_n, ras_n, cas_n, we_n} <= CMD_NOP;
			ba <= 2'b00;
			a <= 13'b0;

			case (state)
				S_IDLE: begin
					busy <= 1'b0;
					refresh_req <= 1'b0;

					if (!enable) begin
						ref_timer <= 16'd0;
					end else if (ref_timer >= TREFI_CYCLES - 1) begin
						refresh_req <= 1'b1;
						state <= S_REQ;
					end else begin
						ref_timer <= ref_timer + 1'b1;
					end
				end

				S_REQ: begin
					busy <= 1'b0;
					refresh_req <= 1'b1;

					if (!enable) begin
						refresh_req <= 1'b0;
						ref_timer <= 16'd0;
						state <= S_IDLE;
					end else if (grant) begin
						{cs_n, ras_n, cas_n, we_n} <= CMD_AREF;
						rfc_timer <= 16'd0;
						refresh_req <= 1'b0;
						busy <= 1'b1;
						state <= S_WAIT;
					end
				end

				S_WAIT: begin
					busy <= 1'b1;

					if (rfc_timer >= TRFC_CYCLES - 1) begin
						rfc_timer <= 16'd0;
						ref_timer <= 16'd0;
						busy <= 1'b0;
						done <= 1'b1;
						state <= S_IDLE;
					end else begin
						rfc_timer <= rfc_timer + 1'b1;
					end
				end

				default: begin
					state <= S_IDLE;
					ref_timer <= 16'd0;
					rfc_timer <= 16'd0;
					refresh_req <= 1'b0;
					busy <= 1'b0;
					end
			endcase
		end
	end

endmodule
