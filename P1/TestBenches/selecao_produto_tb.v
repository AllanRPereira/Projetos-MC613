`timescale 1ns / 1ps

module selecao_produto_tb;

    reg clk;
    reg reset;
    reg [3:0] sw;
    reg travar_selecao;

    wire [6:0] hex_display_5;
    wire [10:0] valor_produto;

    reg [10:0] expected_valor [0:15];
    integer i;
    integer errors;

    selecao_produto uut (
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .travar_selecao(travar_selecao),
        .hex_display_5(hex_display_5),
        .valor_produto(valor_produto)
    );

    initial begin
        // Expected values must match the combinational selection in selecao_produto.v
        expected_valor[ 0] = 11'b0001111101;
        expected_valor[ 1] = 11'b0100101100;
        expected_valor[ 2] = 11'b0010101111;
        expected_valor[ 3] = 11'b0111000010;
        expected_valor[ 4] = 11'b0011100001;
        expected_valor[ 5] = 11'b0101011110;
        expected_valor[ 6] = 11'b0011111010;
        expected_valor[ 7] = 11'b0110101001;
        expected_valor[ 8] = 11'b0111110100;
        expected_valor[ 9] = 11'b0111110100;
        expected_valor[10] = 11'b1001011000;
        expected_valor[11] = 11'b0100010011;
        expected_valor[12] = 11'b1010111100;
        expected_valor[13] = 11'b0111011011;
        expected_valor[14] = 11'b0111011011;
        expected_valor[15] = 11'b1100100000;

        $dumpfile("selecao_produto_tb.vcd");
        $dumpvars(0, selecao_produto_tb);

        clk = 0;
        reset = 1;
        sw = 4'b0000;
        travar_selecao = 0;
        errors = 0;

        #20;
        reset = 0;
        #20;

        $display("Starting functional verification for selecao_produto...");

        for (i = 0; i < 16; i = i + 1) begin
            sw = i;
            travar_selecao = 0;
            @(posedge clk);
            #1;
            if (valor_produto !== expected_valor[i]) begin
                $display("ERROR: SW=%02b expected valor_produto=%011b got=%011b", sw, expected_valor[i], valor_produto);
                errors = errors + 1;
            end else begin
                $display("PASS : SW=%02b valor_produto=%011b hex_display_5=%07b", sw, valor_produto, hex_display_5);
            end

            travar_selecao = 1;
            @(posedge clk);
            #1;
            if (valor_produto !== expected_valor[i]) begin
                $display("ERROR: lock asserted SW=%02b expected valor_produto=%011b got=%011b", sw, expected_valor[i], valor_produto);
                errors = errors + 1;
            end
        end

        // Check reset behavior on the hex display path
        $display("Testing reset behavior...");
        reset = 1;
        @(posedge clk);
        #1;
        $display(" After reset: SW=%02b valor_produto=%011b hex_display_5=%07b", sw, valor_produto, hex_display_5);
        reset = 0;
        @(posedge clk);

        if (errors == 0) begin
            $display("\nALL TESTS PASSED");
        end else begin
            $display("\nTESTS FAILED with %0d error(s)", errors);
        end
        $finish;
    end

    always #5 clk = ~clk;

endmodule
