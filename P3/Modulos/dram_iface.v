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
    output reg wEn
);

    localparam READY = 3'd0;
    localparam REQ_WRITE = 3'd1;
    localparam REQ_READ = 3'd2;
    localparam WAIT_WRITE = 3'd3;
    localparam WAIT_READ = 3'd4;


    reg [2:0] estado = 3'b000;
    reg [5:0] endereco_ultima_leitura = 6'b000000;

    reg [3:0] dado_exibir = 4'b0000;
    reg [3:0] dado_escrito = 4'b0000;
    reg [7:0] data_out = 8'b00000000;

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
        end else begin 
            case (estado)
                READY: begin
                    if (ready) begin
                        if (SW[9:4] != endereco_ultima_leitura)
                            estado <= REQ_READ;
                        else if (KEY)
                            estado <= REQ_WRITE;
                    end

                end

                REQ_READ: begin
                    if (!ready) 
                        estado <= WAIT_READ;
                end

                WAIT_READ: begin
                    if (ready) begin
                        dado_exibir <= data[3:0];
                        estado <= READY;
                    end
                end

                REQ_WRITE: begin
                    if (!ready) begin
                        estado <= WAIT_WRITE;
                        dado_escrito <= SW[3:0];
                    end
                end

                WAIT_WRITE: begin
                    if (ready) 
                        estado <= REQ_READ;
                end

                default: begin 
                    estado <= estado;
                    dado_escrito <= 4'b0000;
                    dado_exibir <= 4'b0000;
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
                    address <= 26'b00000000000000000000000000;
                    address[25] <= SW[9];
                    address[23:21] <= SW[8:6];
                    address[1:0] <= SW[5:4];
                    endereco_ultima_leitura <= SW[9:4];
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
                    address <= 26'b00000000000000000000000000;
                    address[25] <= SW[9];
                    address[23:21] <= SW[8:6];
                    address[1:0] <= SW[5:4];
                    data_out <= {4'b0000, SW[3:0]};
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