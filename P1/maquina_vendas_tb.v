`timescale 1ns/1ps

module maquina_vendas_tb;

reg [3:0] test_sw;      // Entrada de chaves 
reg [1:0] test_key;     // Entrada de botões 
reg test_clk;           // Clock de 50MHz 
wire [6:0] test_hex5;   // Saída para o display de 7 segmentos 

// Instanciar o módulo que queremos testar (Unit Under Test)
maquina_vendas uut (
    .SW(test_sw),
    .KEY(test_key),
    .CLOCK_50(test_clk),
    .HEX5(test_hex5)
);

// Geração de Clock (Necessário pois o módulo usa always @(posedge CLK)) 
always #10 test_clk = ~test_clk;

// Bloco initial: executa uma vez no início da simulação
initial begin
    // Inicialização dos sinais
    test_clk = 0;
    test_sw = 4'b0000;
    test_key = 2'b11; // Chaves em repouso (1)
    
    // $display mostra texto no console do simulador
    $display("Iniciando teste da Maquina de Vendas");
    $display("Tempo | SW (Prod) | KEY | Saida HEX5");
    $display("------|-----------|-----|-----------");
    
    // Teste 1: Selecionar Produto 0 (Preço 125)
    test_sw = 4'b0000; #20;
    $display("%5t | %10b | %3b | %7b", $time, test_sw, test_key, test_hex5);
    
    // Teste 2: Selecionar Produto 1 (Preço 300) [cite: 6]
    test_sw = 4'b0001; #20;
    $display("%5t | %10b | %3b | %7b", $time, test_sw, test_key, test_hex5);
    
    // Teste 3: Pressionar KEY0 para Salvar/Travar o display 
    test_key = 2'b10; #20; 
    $display("%5t | %10b | %3b | %7b (Valor Salvo)", $time, test_sw, test_key, test_hex5);
    
    // Teste 4: Mudar SW enquanto está travado (HEX5 não deve mudar)
    test_sw = 4'b0010; #20;
    $display("%5t | %10b | %3b | %7b (Travado)", $time, test_sw, test_key, test_hex5);

    // Teste 5: Pressionar KEY1 (Reset/Liberar) 
    test_key = 2'b01; #20;
    test_key = 2'b11; #20;
    $display("%5t | %10b | %3b | %7b (Liberado)", $time, test_sw, test_key, test_hex5);
        
    // Finalizar simulação
    $display("---------------------------------------");
    $display("Teste concluído");
    $finish;  // Termina a simulação
end

endmodule