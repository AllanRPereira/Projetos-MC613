module sdram_controller (
	input wire clk,
	input wire rstn,				// Verificar bordas de subida (rstn)
	input wire wEn,					// Write Enable
	input wire rEn,					// Read Enable
	input wire [25:0] address,		// {BA[25:24], ROW[23:11], COL[10:0]}
	input wire [15:0] write_data,
	output wire [15:0] read_data,
	output wire ready,


	// SDRAM
	output reg        CSn, RASn, CASn, WEn,
	output reg [1:0]  BA,
	output reg [12:0] addr,
	inout      [15:0] DQ,
	output     [1:0]  DQM // for setting byte selection (mask)
);

// Parâmetros de Temporização (baseados em 50 MHz, T = 20 ns)
// Corrigidos para estarem em conformidade com as especificações físicas da SDRAM
// e com as temporizações pretendidas nos submódulos (init, read, write, autorefresh)
parameter integer T_200US   = 10000; // 200 us delay de inicialização
parameter integer T_RP_INI  = 2;     // tRP para inicialização (conforme init.v: TRP = 4)
parameter integer T_RC_INI  = 4;    // tRC para inicialização (conforme init.v: TRC = 10)
parameter integer T_MRD     = 1;     // tMRD para inicialização (conforme init.v: TMRD = 3)
parameter integer T_REF_NUM = 4;    // Número de auto-refreshes na inicialização (conforme init.v: 10)

parameter integer T_RCD     = 1;     // Active to Read/Write delay (conforme read.v/write.v: TRCD = 3)
parameter integer T_CAS     = 1;     // CAS Latency (conforme read.v: TCAS_CYCLES = 3)
parameter integer T_RP_RD   = 2;     // Delay de Precharge após Leitura (conforme read.v: TRP_CYCLES = 4)

parameter integer T_WR      = 2;     // Write Recovery Time (conforme write.v: TWR = 4)
parameter integer T_RP_WR   = 1;     // Delay de Precharge após Escrita (conforme write.v: TRP = 3)

parameter integer T_RFC     = 4;    // Refresh cycle time (conforme autorefresh.v: TRFC_CYCLES = 10)
parameter integer T_REFI    = 390;   // Intervalo de Refresh (390 ciclos ~ 7.8 us, correto para 50 MHz)

// Registro de Modo (Mode Register)
// Valor parametrizado em init.v: 13'h0230 (CL=3, Burst Length=1, Sequential)
localparam [12:0] MODE_REG = 13'h0230;

// Estados da FSM
localparam [4:0] S_INIT_WAIT = 5'd0,
                 S_INIT_PALL = 5'd1,
                 S_INIT_TRP  = 5'd2,
                 S_INIT_REF  = 5'd3,
                 S_INIT_TRC  = 5'd4,
                 S_INIT_MRS  = 5'd5,
                 S_INIT_TMRD = 5'd6,
                 S_HALT      = 5'd7,
                 S_ACT       = 5'd8,
                 S_TRCD      = 5'd9,
                 S_READ      = 5'd10,
                 S_CAS       = 5'd11,
                 S_RP_RD     = 5'd12,
                 S_WRITE     = 5'd13,
                 S_WR_RP     = 5'd14,
                 S_REF       = 5'd15,
                 S_TRFC      = 5'd16;

reg [4:0] state, next_state;

// Registrador de propósito geral para temporizações internas
reg [14:0] timer;

// Contador de refreshes durante a inicialização
reg [3:0] init_ref_cnt;

// Contador de intervalo de refresh periódico
reg [8:0] ref_cnt;

// Flag para indicar se a operação ativa é Escrita (1) ou Leitura (0)
reg op_write;

// Lógica de atualização do contador de refresh periódico (ref_cnt)
always @(posedge clk or negedge rstn) begin
	if (!rstn)
		ref_cnt <= 9'd0;
	else if (state == S_REF)
		ref_cnt <= 9'd0;
	else
		ref_cnt <= ref_cnt + 1'b1;
end

// Lógica de transição de estados e controle do timer/contadores
always @(posedge clk or negedge rstn) begin
	if (!rstn) begin
		state        <= S_INIT_WAIT;
		timer        <= 15'd0;
		init_ref_cnt <= 4'd0;
		op_write     <= 1'b0;
	end else begin
		state <= next_state;
		
		case (state)
			S_INIT_WAIT: begin
				if (timer >= T_200US - 1) begin
					timer <= 15'd0;
				end else begin
					timer <= timer + 1'b1;
				end
			end
			
			S_INIT_PALL: begin
				timer <= 15'd0;
			end
			
			S_INIT_TRP: begin
				if (timer >= T_RP_INI - 1) begin
					timer        <= 15'd0;
					init_ref_cnt <= 4'd0;
				end else begin
					timer <= timer + 1'b1;
				end
			end
			
			S_INIT_REF: begin
				timer <= 15'd0;
			end
			
			S_INIT_TRC: begin
				if (timer >= T_RC_INI - 1) begin
					timer <= 15'd0;
					if (init_ref_cnt >= T_REF_NUM - 1) begin
						init_ref_cnt <= 4'd0;
					end else begin
						init_ref_cnt <= init_ref_cnt + 1'b1;
					end
				end else begin
					timer <= timer + 1'b1;
				end
			end
			
			S_INIT_MRS: begin
				timer <= 15'd0;
			end
			
			S_INIT_TMRD: begin
				if (timer >= T_MRD - 1) begin
					timer <= 15'd0;
				end else begin
					timer <= timer + 1'b1;
				end
			end
			
			S_HALT: begin
				timer <= 15'd0;
				if (ref_cnt >= T_REFI) begin
					op_write <= 1'b0;
				end else if (wEn && !rEn) begin
					op_write <= 1'b1;
				end else if (rEn && !wEn) begin
					op_write <= 1'b0;
				end
			end
			
			S_ACT: begin
				timer <= 15'd0;
			end
			
			S_TRCD: begin
				if (timer >= T_RCD - 2) begin
					timer <= 15'd0;
				end else begin
					timer <= timer + 1'b1;
				end
			end
			
			S_READ: begin
				timer <= 15'd0;
			end
			
			S_CAS: begin
				if (timer >= T_CAS - 2) begin
					timer <= 15'd0;
				end else begin
					timer <= timer + 1'b1;
				end
			end
			
			S_RP_RD: begin
				if (timer >= T_RP_RD - 1) begin
					timer <= 15'd0;
				end else begin
					timer <= timer + 1'b1;
				end
			end
			
			S_WRITE: begin
				timer <= 15'd0;
			end
			
			S_WR_RP: begin
				if (timer >= (T_WR + T_RP_WR - 3)) begin
					timer <= 15'd0;
				end else begin
					timer <= timer + 1'b1;
				end
			end
			
			S_REF: begin
				timer <= 15'd0;
			end
			
			S_TRFC: begin
				if (timer >= T_RFC - 3) begin
					timer <= 15'd0;
				end else begin
					timer <= timer + 1'b1;
				end
			end
			
			default: begin
				timer <= 15'd0;
			end
		endcase
	end
end

// Lógica de Próximo Estado da FSM
always @(*) begin
	case (state)
		S_INIT_WAIT: begin
			if (timer >= T_200US - 1)
				next_state <= S_INIT_PALL;
			else
				next_state <= S_INIT_WAIT;
		end
		
		S_INIT_PALL: begin
			next_state <= S_INIT_TRP;
		end
		
		S_INIT_TRP: begin
			if (timer >= T_RP_INI - 1)
				next_state <= S_INIT_REF;
			else
				next_state <= S_INIT_TRP;
		end
		
		S_INIT_REF: begin
			next_state <= S_INIT_TRC;
		end
		
		S_INIT_TRC: begin
			if (timer >= T_RC_INI - 1) begin
				if (init_ref_cnt >= T_REF_NUM - 1)
					next_state <= S_INIT_MRS;
				else
					next_state <= S_INIT_REF;
			end else begin
				next_state <= S_INIT_TRC;
			end
		end
		
		S_INIT_MRS: begin
			next_state <= S_INIT_TMRD;
		end
		
		S_INIT_TMRD: begin
			if (timer >= T_MRD - 1)
				next_state <= S_HALT;
			else
				next_state <= S_INIT_TMRD;
		end
		
		S_HALT: begin
			if (ref_cnt >= T_REFI)
				next_state <= S_REF;
			else if (wEn && !rEn)
				next_state <= S_ACT;
			else if (rEn && !wEn)
				next_state <= S_ACT;
			else
				next_state <= S_HALT;
		end
		
		S_ACT: begin
			next_state <= S_TRCD;
		end
		
		S_TRCD: begin
			if (timer >= T_RCD - 2) begin
				if (op_write)
					next_state <= S_WRITE;
				else
					next_state <= S_READ;
			end else begin
				next_state <= S_TRCD;
			end
		end
		
		S_READ: begin
			next_state <= S_CAS;
		end
		
		S_CAS: begin
			if (timer >= T_CAS - 2)
				next_state <= S_RP_RD;
			else
				next_state <= S_CAS;
		end
		
		S_RP_RD: begin
			if (timer >= T_RP_RD - 1)
				next_state <= S_HALT;
			else
				next_state <= S_RP_RD;
		end
		
		S_WRITE: begin
			next_state <= S_WR_RP;
		end
		
		S_WR_RP: begin
			if (timer >= (T_WR + T_RP_WR - 3))
				next_state <= S_HALT;
			else
				next_state <= S_WR_RP;
		end
		
		S_REF: begin
			next_state <= S_TRFC;
		end
		
		S_TRFC: begin
			if (timer >= T_RFC - 3)
				next_state <= S_HALT;
			else
				next_state <= S_TRFC;
		end
		
		default: begin
			next_state <= S_HALT;
		end
	endcase
end

// Geração de Sinais de Controle da SDRAM
always @(*) begin
	case (state)
		S_INIT_PALL: {CSn, RASn, CASn, WEn} <= 4'b0010; // Precharge All
		S_INIT_REF : {CSn, RASn, CASn, WEn} <= 4'b0001; // Auto Refresh (Init)
		S_INIT_MRS : {CSn, RASn, CASn, WEn} <= 4'b0000; // Mode Register Set (MRS)
		S_ACT      : {CSn, RASn, CASn, WEn} <= 4'b0011; // Active (ACT)
		S_READ     : {CSn, RASn, CASn, WEn} <= 4'b0101; // Read with Auto-Precharge
		S_WRITE    : {CSn, RASn, CASn, WEn} <= 4'b0100; // Write with Auto-Precharge
		S_REF      : {CSn, RASn, CASn, WEn} <= 4'b0001; // Periodic Auto Refresh
		default    : {CSn, RASn, CASn, WEn} <= 4'b1111; // NOP / Device Deselect
	endcase
end

// Sinais de Endereço (addr)
always @(*) begin
	case (state)
		S_INIT_MRS : addr[12:0] <= MODE_REG;
		S_INIT_PALL: addr[12:0] <= 13'b0100_0000_0000; // Precharge All (A10 = 1)
		S_ACT      : addr[12:0] <= address[23:11];      // Row Address
		S_READ     : addr[12:0] <= {1'b0, address[10], 1'b0, address[9:0]}; // Column Address (com Auto-Precharge)
		S_WRITE    : addr[12:0] <= {1'b0, address[10], 1'b0, address[9:0]}; // Column Address (com Auto-Precharge)
		default    : addr[12:0] <= 13'h000;
	endcase
end

// Sinais de Seleção de Banco (BA)
always @(*) begin
	case (state)
		S_INIT_MRS : BA[1:0] <= 2'b00;
		S_ACT      : BA[1:0] <= address[25:24]; // Bank Address
		S_READ     : BA[1:0] <= address[25:24]; // Bank Address
		S_WRITE    : BA[1:0] <= address[25:24]; // Bank Address
		default    : BA[1:0] <= 2'b00;
	endcase
end

// Controle do Barramento de Dados (DQ) e do Sinal Ready
// DQ deve ser tri-state para leitura e ativo para escrita
assign DQ[15:0] = (state == S_WRITE || (state == S_WR_RP && timer < T_WR - 1)) ? write_data[15:0] : 16'hzzzz;

// DQM habilitado (00) para permitir acesso de dados completo de 16 bits
assign DQM[1:0] = 2'b00;

// O dado de leitura é continuamente atribuído ao read_data
assign read_data[15:0] = DQ[15:0];

// O sinal ready indica se o controlador está ocioso (HALT) ou pronto para receber o próximo comando
// Ele também fica alto durante S_RP_RD para sinalizar que o dado lido está pronto para captura externa
assign ready = (state == S_HALT || state == S_RP_RD) ? 1'b1 : 1'b0;

endmodule
