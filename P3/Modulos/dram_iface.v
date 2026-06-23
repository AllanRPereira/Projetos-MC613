module dram_iface (
    input wire clk,
    input wire rst,
    input wire [9:0] SW,
    input wire KEY,
    input wire ready,
    inout wire [7:0] data,

    output wire [3:0] HEX0, HEX1, HEX4, HEX5,       // 4 Bits para converter para 7 segmentos

    output reg [25:0] address,
    output reg req,
    output reg wEn,
    // Leds para Estados
    output reg [4:0] leds
);

    localparam READY = 3'd0;
    localparam REQ_WRITE = 3'd1;
    localparam REQ_READ = 3'd2;
    localparam WAIT_WRITE = 3'd3;
    localparam WAIT_READ = 3'd4;


    reg [2:0] estado = 3'b000;
    reg [5:0] endereco_ultima_leitura = 6'b000000;
    reg [25:0] address_latched = 26'b0;
    reg [7:0] data_latched = 8'b0;
    reg key_prev = 1'b0;
    wire key_pulse = KEY & ~key_prev;

    reg [3:0] dado_exibir = 4'b0000;
    reg [3:0] dado_escrito = 4'b0000;
    reg [7:0] data_out = 8'b00000000;

    function [25:0] build_address;
        input [9:0] sw_value;
        begin
            build_address = 26'b0;
            build_address[25] = sw_value[9];
            build_address[23:21] = sw_value[8:6];
            build_address[1:0] = sw_value[5:4];
        end
    endfunction

    // Controle de direção DATA BUS
    assign data = (wEn) ? data_out : 8'bzzzzzzzz;

    assign HEX1 = dado_exibir;
    assign HEX0 = dado_escrito;

    assign HEX4 = SW[7:4];                  // Parte baixa da área endereçável
    assign HEX5 = {2'b00, SW[9:8]};         // Parte alta da área endereçável

    always @(posedge clk) begin 
        if (rst) begin
            estado <= READY;
            dado_escrito <= 4'b0000;
            dado_exibir <= 4'b0000;
            key_prev <= 1'b0;
            address_latched <= 26'b0;
            data_latched <= 8'b0;
            leds <= 5'b00000;
        end else begin 
            key_prev <= KEY;

            case (estado)
                READY: begin
                    leds <= 5'b00001;
                    if (ready) begin
                        if (key_pulse) begin
                            address_latched <= build_address(SW);
                            data_latched <= {4'b0000, SW[3:0]};
                            estado <= REQ_WRITE;
                        end else if (SW[9:4] != endereco_ultima_leitura) begin
                            address_latched <= build_address(SW);
                            estado <= REQ_READ;
                        end
                    end

                end

                REQ_READ: begin
                    leds <= 5'b00010;
                    if (!ready) begin
                        estado <= WAIT_READ;
                    end
                end

                WAIT_READ: begin
                    leds <= 5'b00100;
                    if (ready) begin
                        dado_exibir <= data[3:0];
                        estado <= READY;
                    end
                end

                REQ_WRITE: begin
                    leds <= 5'b01000;
                    if (!ready) begin
                        estado <= WAIT_WRITE;
                        dado_escrito <= data_latched[3:0];
                    end
                end

                WAIT_WRITE: begin
                    leds <= 5'b10000;
                    if (ready) begin 
                        estado <= REQ_READ;
                    end
                end

                default: begin 
                    estado <= estado;
                    dado_escrito <= 4'b0000;
                    dado_exibir <= 4'b0000;
                    leds <= 5'b00000;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            address <= 26'b00000000000000000000000000;
            endereco_ultima_leitura <= 6'b000000;
            data_out <= 8'b00000000;
            wEn <= 1'b0;
            req <= 1'b0;
        end else begin 
            case (estado)
                READY: begin
                    data_out <= 8'b00000000;
                    wEn <= 1'b0;
                    req <= 1'b0;
                end

                REQ_READ: begin
                    address <= address_latched;
                    endereco_ultima_leitura <= address_latched[25:20];
                    data_out <= 8'b00000000;
                    wEn <= 1'b0;
                    req <= 1'b1;
                end

                WAIT_READ: begin
                    wEn <= 1'b0;
                    req <= 1'b0;
                end
                // Quando saiu de REQ_WRITE significa que recebeu as informações
                // Já é possível liberar a bus de dados.
                REQ_WRITE: begin
                    address <= address_latched;
                    data_out <= data_latched;
                    wEn <= 1'b1;
                    req <= 1'b1;

                end

                WAIT_WRITE: begin
                    wEn <= 1'b0;    // Libera o BUS de dados.
                    req <= 1'b0;
                end

                default: begin
                    address <= 26'b00000000000000000000000000;
                    data_out <= 8'b00000000;
                    wEn <= 1'b0;
                    req <= 1'b0;
                end

            endcase
        end
    end 

endmodule