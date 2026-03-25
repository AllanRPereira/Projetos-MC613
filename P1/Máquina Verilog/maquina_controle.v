module maquina_controle(
    input wire clk,
    input wire reset,

    input wire sinal_cancelamento,
    input wire sinal_liberacao,
    input wire sinal_troco,
    input wire sinal_led_apagado,

    output reg led_liberado,
    output reg led_cancelado_troco
    
);

always @(posedge clk) begin
    if (sinal_led_apagado) begin
        led_liberado <= 0;
        led_cancelado_troco <= 0;
    end

    if (reset) begin
        led_liberado <= 0;
        led_cancelado_troco <= 0;
    end
    else begin
        if (sinal_liberacao) 
            led_liberado <= 1;
        if (sinal_troco || sinal_cancelamento)
            led_cancelado_troco <= 1;
    end
    
end

endmodule