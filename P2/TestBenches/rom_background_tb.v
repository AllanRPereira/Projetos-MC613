`timescale 1ns / 1ps

module rom_background_tb;

// Inputs
reg [4:0] x_tile;
reg [4:0] y_tile;

// Outputs
wire [2:0] bg_color_palette;

// Instantiate the Unit Under Test (UUT)
rom_background uut (
    .x_tile(x_tile),
    .y_tile(y_tile),
    .bg_color_palette(bg_color_palette)
);

// Test procedure
initial begin
    // Initialize inputs
    x_tile = 0;
    y_tile = 0;

    // Wait for ROM to load
    #10;

    // Test various tile positions
    $display("Testing ROM Background Module");
    $display("x_tile | y_tile | bg_color_palette");

    // Test corner cases and some middle values
    test_case(5'd0, 5'd0);
    test_case(5'd1, 5'd0);
    test_case(5'd0, 5'd1);
    test_case(5'd19, 5'd14);  // Max possible (20*15 + 19 = 319, but storage 0-299)
    test_case(5'd10, 5'd7);
    test_case(5'd5, 5'd5);

    // Test a few more
    test_case(5'd15, 5'd10);
    test_case(5'd20, 5'd0);  // x_tile=20, but addr might overflow

    $display("Test completed");
    $finish;
end

task test_case(input [4:0] x, y);
begin
    x_tile = x;
    y_tile = y;
    #1;  // Small delay for combinational logic
    $display("%d     | %d     | %b", x, y, bg_color_palette);
end
endtask

endmodule