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

    // MÓDULO: caixa_registradora.v
    output reg salvar_valor,            // Sinal para indicar que o valor definido pela seleção das chaves deve ser salvo no registrador
    output reg diminuir_valor,          // Sinal para subtrair o valor das chaves do valor salva no registrador

    // MÓDULO: maquina_controle.v
    output reg sinal_liberacao,         // Sinal para liberar o produto
    output reg sinal_troco,             // Sinal para apresentar o troco
    output reg sinal_cancelamento,       // Sinal de cancelamento
    output reg sinal_led_apagado        // Apagar os leds 
);

reg [2:0] estado = 3'b000;
reg [2:0] prev_estado = 3'b000;

always @(posedge clk) begin
    if (reset) begin
        estado <= 3'b000;
        prev_estado <= 3'b000;
    end else begin
        prev_estado <= estado;
        case (estado)
            3'b000: begin                   // Estado: escolha do produto
                if (chave_avancar)
                    estado <= 3'b001;       // Escolha -> Selecao
                
            end

            3'b001: begin                   // Estado: produto selecionado
                if (chave_cancelado)
                    estado <= 3'b100;       // Selecao -> Cancelado
                else if (|switch_valor && chave_avancar)     // Qualquer bit igual a 1 (Valor inserido)
                    estado <= 3'b101;       // Selecao -> Wait Confirmar Release
            end

            3'b010: begin                   // Estado: dinheiro inserido
                if (chave_cancelado)        // Volta para o estado de escolha do produto
                    estado <= 3'b000;       // Dinheiro -> Escolha
                else
                    if (valor[11] == 1'b1 || valor == 12'd0)
                        estado <= 3'b011;
                    else
                        estado <= 3'b001;
            end

            3'b011: begin                   // Estado: produto comprado
                if (clk_1s) 
                    estado <= 3'b000;       // Produto comprado -> Escolha do produto
            end

            3'b100: begin                   // Estado: Produto cancelado
                if (clk_1s)
                    estado <= 3'b000;
            end
				
            3'b101: begin						// Estado: Wait Confirmar Release
                if (!chave_avancar)
                    estado <= 3'b010;			// Wait -> Dinheiro Inserido
            end
				
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        travar_selecao <= 0;
        salvar_valor <= 0;
        diminuir_valor <= 0;
        sinal_troco <= 0;
        sinal_liberacao <= 0;
        sinal_cancelamento <= 0;
        sinal_led_apagado <= 0;
    end else begin
        case (estado)
            3'b000: begin           // Seleção produto
                sinal_led_apagado <= 1;
                travar_selecao <= 0;
                salvar_valor <= 1;
                sinal_troco <= 0;
                sinal_liberacao <= 0;
                diminuir_valor <= 0;
                sinal_cancelamento <= 0;
            end

            3'b001: begin           // Produto escolhido
                travar_selecao <= 1;
                salvar_valor <= 0;
                sinal_led_apagado <= 1;
                sinal_troco <= 0;
                sinal_liberacao <= 0;
                diminuir_valor <= 0;
                sinal_cancelamento <= 0;
            end

            3'b010: begin           // Dinheiro inserido
                travar_selecao <= 1;
                diminuir_valor <= 1;
                sinal_led_apagado <= 1;
                salvar_valor <= 0;
                sinal_troco <= 0;
                sinal_liberacao <= 0;
                sinal_cancelamento <= 0;
            end

            3'b011: begin           // Produto comprado
                sinal_troco <= 1;
                sinal_liberacao <= 1;
                travar_selecao <= 1;
                sinal_led_apagado <= 0;
                diminuir_valor <= 0;
                salvar_valor <= 0;
                sinal_cancelamento <= 0;
            end

            3'b100: begin           // Compra cancelada
                sinal_cancelamento <= 1;
                sinal_troco <= 0;
                sinal_liberacao <= 0;
                travar_selecao <= 0;
                diminuir_valor <= 0;
                salvar_valor <= 0;
                sinal_led_apagado <= 0;
            end
				
			3'b101: begin           // Estado Wait Avançar
			    travar_selecao <= 1;
                salvar_valor <= 0;
                sinal_led_apagado <= 1;
                sinal_troco <= 0;
                sinal_liberacao <= 0;
                diminuir_valor <= 0;
                sinal_cancelamento <= 0;
				end

            default: begin
                travar_selecao <= 0;
                salvar_valor <= 0;
                sinal_troco <= 0;
                sinal_liberacao <= 0;
                diminuir_valor <= 0;
                sinal_cancelamento <= 0;
                sinal_led_apagado <= 0;
            end
        endcase
    end
end 

endmodule
