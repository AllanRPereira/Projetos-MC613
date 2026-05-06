module dram_top_level (
    input wire CLOCK_50,
    input wire [4:0] KEY,       // Normal Ativo
    input wire [9:0] SW,
    output wire [6:0] HEX0, HEX1, HEX4, HEX5,       // 4 Bits para converter para 7 segmentos
    output wire LEDR0, LEDR1                        // Usar para exibir os sinais de req e wEn
);

    // KEY[0] -> reset
    // KEY[1] -> ready do controller
    // Clock reduzido para facilitar a visualização

    reg [25:0] div_cnt = 26'd0;
    reg clk_slow = 1'b0;

    always @(posedge CLOCK_50) begin
        div_cnt <= div_cnt + 1'b1;
        if (div_cnt == 26'd25_000_000) begin
            div_cnt <= 26'd0;
            clk_slow <= ~clk_slow;
        end
    end

    // Normal ativo
    wire rst = ~KEY[0];
    wire ready = ~KEY[1];

    // Barramento de dados
    wire [7:0] data;
    reg [7:0] ctrl_data = 8'h00;
    reg ctrl_drive = 1'b0;

    assign data = ctrl_drive ? ctrl_data : 8'bzzzzzzzz;

    // Saídas do dram_iface (hexadecimal)
    wire [3:0] hex0_n;
    wire [3:0] hex1_n;
    wire [3:0] hex4_n;
    wire [3:0] hex5_n;

    wire [25:0] address;
    wire req;
    wire wEn;

    dram_iface u_dram_iface (
        .clk(clk_slow),
        .rst(rst),
        .SW(SW),
        .KEY(~KEY[3]),          // Normal Ativo
        .ready(ready),
        .data(data),
        .HEX0(hex0_n),
        .HEX1(hex1_n),
        .HEX4(hex4_n),
        .HEX5(hex5_n),
        .address(address),
        .req(req),
        .wEn(wEn)
    );

    // Modelo simples de controller
    always @(posedge clk_slow) begin
        if (rst) begin
            ctrl_data <= 8'h00;
            ctrl_drive <= 1'b0;
        end else begin
            ctrl_drive <= 1'b0;
            if (ready && req) begin
                if (wEn) begin
                    ctrl_data <= data;
                end else begin
                    ctrl_drive <= 1'b1;
                end
            end
        end
    end

    // Conversores para 7 segmentos
    bin2hex u_hex0 (.clk(clk_slow), .lock(1'b0), .reset(rst), .bin(hex0_n), .hex(HEX0[6:0]));
    bin2hex u_hex1 (.clk(clk_slow), .lock(1'b0), .reset(rst), .bin(hex1_n), .hex(HEX1[6:0]));
    bin2hex u_hex4 (.clk(clk_slow), .lock(1'b0), .reset(rst), .bin(hex4_n), .hex(HEX4[6:0]));
    bin2hex u_hex5 (.clk(clk_slow), .lock(1'b0), .reset(rst), .bin(hex5_n), .hex(HEX5[6:0]));

    assign LEDR0 = req;
    assign LEDR1 = wEn;

endmodule