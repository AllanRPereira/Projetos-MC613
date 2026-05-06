module dram_iface (
    input wire clk,
    input wire rst,
    input wire [9:0] SW,
    input wire [3:0] KEY,
    input wire ready,

    output wire [6:0] HEX0, HEX1, HEX4, HEX5,

    output reg [25:0] address,
    output reg [7:0] data,
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

    assign HEX1 = dado_exibir;
    assign HEX0 = dado_escrito;

    assign HEX4 = {3'b000, address[22:21], address[1:0]};       // Parte baixa da área endereçável
    assign HEX5 = {5'b00000, address[25], address[23]};         // Parte alta da área endereçável

    always @(posedge clk) begin 
        if (rst) begin
            estado <= READY;
            address <= 26'b00000000000000000000000000;
            data <= 8'b00000000;
            dado_escrito <= 4'b0000;
            dado_exibir <= 4'b0000;
            wEn <= 1'b0;
            req <= 1'b0;
        end else begin 
            case (estado)
                READY: begin
                    if (ready) begin
                        if (SW[9:4] != endereco_ultima_leitura)
                            estado <= REQ_READ;
                        else if (KEY[3])
                            estado <= REQ_WRITE;
                    end

                end

                REQ_WRITE: begin
                    if (!ready) 
                        estado <= WAIT_WRITE;
                end

                REQ_READ: begin
                    if (!ready) 
                        estado <= WAIT_READ;
                end

                WAIT_WRITE: begin
                    if (ready) begin
                        estado <= REQ_READ;
                    end
                end

                WAIT_READ: begin
                    if (ready) begin
                        estado <= READY;
                    end
                end

                default: estado <= estado;
            endcase
        end
    end

    always @(*) begin
    
        case (estado_atual) begin
            READY: begin
                address <= 26'b00000000000000000000000000;
                data <= 8'b00000000;
                wEn <= 1'b0;
                req <= 1'b0;
            end

            REQ_READ: begin
                address <= 26'b00000000000000000000000000;
                address[25] <= SW[9];
                address[23:21] <= SW[8:6];
                address[1:0] <= SW[5:4];
                endereco_ultima_leitura <= SW[9:4];
                data <= 8'b00000000;
                req <= 1'b1;
            end

            WAIT_READ: begin
                dado_exibir <= data[3:0];
            end

            REQ_WRITE: begin
                address <= 26'b00000000000000000000000000;
                address[25] <= SW[9];
                address[23:21] <= SW[8:6];
                address[1:0] <= SW[5:4];
                data[7:4] <= 4'b0000;
                data[3:0] <= SW[3:0];
                wEn <= 1'b1;
                req <= 1'b1;

            end

            WAIT_WRITE: begin
                dado_escrito <= data[3:0];
            end

            default: begin
                address <= 26'b00000000000000000000000000;
                data <= 8'b00000000;
                dado_escrito <= 4'b0000;
                dado_exibir <= 4'b0000;
                wEn <= 1'b0;
                req <= 1'b0;
            end

        endcase

    end

endmodule