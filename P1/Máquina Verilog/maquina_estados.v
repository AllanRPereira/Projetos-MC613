module maquina_estados(
    input wire clk,                     // Clock normal da máquina
    input wire clk_1s,                  // Contador para clock de 1s
    input wire reset,
    input wire chave_cancelado,
    input wire chave_avancar,
    input wire [5:0] switch_valor,
    input wire signed [11:0] valor,     // Um bit a mais para o sinal (Negativo/Positivo)

    // MÓDULO: selecao_produto.v
    output reg travar_selecao,          // Trava a mudança do produto no display Hex5

    // MÓDULO: conversao_valor.v
    output reg travar_valor,

    // MÓDULO: caixa_registradora.v
    output reg salvar_valor,            // Sinal para indicar que o valor definido pela seleção das chaves deve ser salvo no registrador
    output reg diminuir_valor,          // Sinal para subtrair o valor das chaves do valor salva no registrador

    // MÓDULO: maquina_controle.v
    output reg sinal_liberacao,         // Sinal para liberar o produto
    output reg sinal_troco,             // Sinal para apresentar o troco
    output reg sinal_cancelamento       // Sinal de cancelamento
);

reg valor_removido = 0;
reg [2:0] estado = 3'b000;

always @(posedge clk) begin
    if (reset) 
        estado <= 2'b00;
    else begin
        case (estado)
            2'b00: begin                    // Estado: escolha do produto
                if (chave_avancar)
                    estado <= 2'b01;        // Escolha -> Selecao
                
            end

            2'b01: begin                    // Estado: produto selecionado
                if (chave_cancelado)
                    estado <= 2'b00;        // Selecao -> Escolha
                else if (|switch_valor)     // Qualquer bit igual a 1 (Valor inserido)
                    estado <= 2'b10;        // Selecao -> Dinheiro inserido
            end

            2'b10: begin                    // Estado: dinheiro inserido
                if (chave_cancelado)        // Volta para o estado de escolha do produto
                    estado <= 2'b00;        // Dinheiro -> Escolha
                else if (chave_avancar) begin
                    if (valor <= 0)          // Valor restante
                        estado <= 2'b11;    // Dinheiro -> Comprado
                    else
                        estado <= 2'b01;    // Dinheiro inserido -> Produto selecionado
                end 
                
            end

            2'b11: begin                    // Estado: produto comprado
                if (clk_1s) 
                    estado <= 2'b00;        // Produto comprado -> Escolha do produto
            end

            3'b100: begin                   // Estado: Produto cancelado
                if (clk_1s)
                    estado <= 2'b00;
            end
        endcase
    end
end

always @(posedge clk) begin
    // Situação dos sinais para cada um dos estados da máquina
    case (estado)
        2'b00: begin
            travar_selecao <= 0;
            salvar_valor <= 0;
            sinal_troco <= 0;
            sinal_liberacao <= 0;
            diminuir_valor <= 0;
            sinal_cancelamento <= 0;
        end

        2'b01: begin
            travar_selecao <= 1;
            salvar_valor <= 1;
            
            sinal_troco <= 0;
            sinal_liberacao <= 0;
            diminuir_valor <= 0;
            sinal_cancelamento <= 0;
        end

        2'b10: begin
            travar_selecao <= 1;
            diminuir_valor <= 1;

            salvar_valor <= 0;
            sinal_troco <= 0;
            sinal_liberacao <= 0;
            sinal_cancelamento <= 0;
        end

        2'b11: begin
            sinal_troco <= 1;
            sinal_liberacao <= 1;

            travar_selecao <= 0;
            diminuir_valor <= 0;
            salvar_valor <= 0;
            sinal_cancelamento <= 0;
        end

        3'b100: begin
            sinal_cancelamento <= 1;

            sinal_troco <= 0;
            sinal_liberacao <= 0;
            travar_selecao <= 0;
            diminuir_valor <= 0;
            salvar_valor <= 0;
        end

        default: begin
            travar_selecao <= 0;
            salvar_valor <= 0;
            sinal_troco <= 0;
            sinal_liberacao <= 0;
            diminuir_valor <= 0;
            sinal_cancelamento <= 0;
        end
    endcase

end 

endmodule