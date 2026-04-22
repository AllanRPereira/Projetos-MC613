`timescale 1ns / 1ps

module rom_sprite_tb;

// Inputs
reg [4:0] id_sprite;

// Outputs
wire [11:0] bitmap_sprite_palette;

// Instantiate the Unit Under Test (UUT)
rom_sprite uut (
    .id_sprite(id_sprite),
    .bitmap_sprite_palette(bitmap_sprite_palette)
);

// Test procedure
initial begin
    // Initialize inputs
    id_sprite = 0;

    // Wait for ROM to load
    #10;

    // Test various sprite IDs
    $display("Testing ROM Sprite Module");
    $display("id_sprite | bitmap_sprite_palette");

    // Test first few sprites
    test_case(5'd0);
    test_case(5'd1);
    test_case(5'd2);
    test_case(5'd3);
    test_case(5'd4);
    test_case(5'd5);

    // Test some middle values
    test_case(5'd10);
    test_case(5'd15);
    test_case(5'd20);

    // Test last sprite
    test_case(5'd31);

    $display("Test completed");
    $finish;
end

task test_case(input [4:0] id);
begin
    id_sprite = id;
    #1;  // Small delay for combinational logic
    $display("%d        | %h", id, bitmap_sprite_palette);
end
endtask

endmodule