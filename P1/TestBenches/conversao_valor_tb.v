`timescale 1ns / 1ps

module conversao_valor_tb;

    reg clk;
    reg reset;
    reg [10:0] bin;

    wire [6:0] display_0;
    wire [6:0] display_1;
    wire [6:0] display_2;
    wire [6:0] display_3;

    reg [6:0] expected_hex [0:9];
    reg [10:0] test_values [0:11];
    integer j;
    integer errors;
    integer value;
    integer thousands;
    integer hundreds;
    integer tens;
    integer units;

    conversao_valor uut (
        .clk(clk),
        .reset(reset),
        .bin(bin),
        .display_0(display_0),
        .display_1(display_1),
        .display_2(display_2),
        .display_3(display_3)
    );

    initial begin
        expected_hex[0] = 7'b1000000;
        expected_hex[1] = 7'b1111001;
        expected_hex[2] = 7'b0100100;
        expected_hex[3] = 7'b0110000;
        expected_hex[4] = 7'b0011001;
        expected_hex[5] = 7'b0010010;
        expected_hex[6] = 7'b0000010;
        expected_hex[7] = 7'b1111000;
        expected_hex[8] = 7'b0000000;
        expected_hex[9] = 7'b0010000;

        test_values[ 0] = 11'd0;
        test_values[ 1] = 11'd1;
        test_values[ 2] = 11'd9;
        test_values[ 3] = 11'd10;
        test_values[ 4] = 11'd34;
        test_values[ 5] = 11'd99;
        test_values[ 6] = 11'd100;
        test_values[ 7] = 11'd123;
        test_values[ 8] = 11'd999;
        test_values[ 9] = 11'd1000;
        test_values[10] = 11'd1023;
        test_values[11] = 11'd2047;

        $dumpfile("conversao_valor_tb.vcd");
        $dumpvars(0, conversao_valor_tb);

        clk = 0;
        reset = 1;
        bin = 11'd0;
        errors = 0;

        #20;
        reset = 0;
        #20;

        $display("Starting conversao_valor verification...");

        for (j = 0; j < 12; j = j + 1) begin
            bin = test_values[j];
            @(posedge clk);
            #1;

            value = test_values[j];
            thousands = value / 1000;
            hundreds = (value / 100) % 10;
            tens = (value / 10) % 10;
            units = value % 10;

            if (display_3 !== expected_hex[thousands] ||
                display_2 !== expected_hex[hundreds] ||
                display_1 !== expected_hex[tens] ||
                display_0 !== expected_hex[units]) begin

                $display("ERROR: bin=%4d expected [%d%d%d%d] got [%b %b %b %b]", 
                         value,
                         thousands, hundreds, tens, units,
                         display_3, display_2, display_1, display_0);
                errors = errors + 1;
            end else begin
                $display("PASS : bin=%4d displays [%d%d%d%d] => [%b %b %b %b]",
                         value,
                         thousands, hundreds, tens, units,
                         display_3, display_2, display_1, display_0);
            end
        end

        $display("Testing reset behavior...");
        reset = 1;
        @(posedge clk);
        #1;
        if (display_3 !== expected_hex[0] || display_2 !== expected_hex[0] ||
            display_1 !== expected_hex[0] || display_0 !== expected_hex[0]) begin
            $display("ERROR: reset did not force digits to 0 pattern: %b %b %b %b",
                     display_3, display_2, display_1, display_0);
            errors = errors + 1;
        end else begin
            $display("PASS : reset sets all digits to 0 pattern");
        end

        if (errors == 0) begin
            $display("\nALL TESTS PASSED");
        end else begin
            $display("\nTESTS FAILED with %0d errors", errors);
        end

        $finish;
    end

    always #5 clk = ~clk;

endmodule
