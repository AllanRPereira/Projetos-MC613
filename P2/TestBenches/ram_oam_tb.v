`timescale 1ns / 1ps

module ram_oam_tb;

// Inputs
reg clk;
reg [4:0] x_tile;
reg [4:0] y_tile;
reg sig_write_ram;
reg [8:0] ram_addr;
reg [4:0] sprite_in;

// Outputs
wire [4:0] id_sprite;

// Instantiate the Unit Under Test (UUT)
ram_oam uut (
    .clk(clk),
    .x_tile(x_tile),
    .y_tile(y_tile),
    .sig_write_ram(sig_write_ram),
    .ram_addr(ram_addr),
    .sprite_in(sprite_in),
    .id_sprite(id_sprite)
);

// Clock generation
always #5 clk = ~clk;  // 10ns period clock

// Test procedure
initial begin
    // Initialize inputs
    clk = 0;
    x_tile = 0;
    y_tile = 0;
    sig_write_ram = 0;
    ram_addr = 0;
    sprite_in = 0;

    // Wait for initialization
    #10;

    $display("Testing RAM OAM Module");
    $display("Time | Operation | x_tile | y_tile | ram_addr | sprite_in | id_sprite");

    // Test initial read (should be 0)
    test_read(5'd0, 5'd0);
    test_read(5'd1, 5'd1);

    // Write some data
    test_write(9'd0, 5'd10);  // Write sprite 10 to address 0
    test_write(9'd1, 5'd20);  // Write sprite 20 to address 1
    test_write(9'd50, 5'd5);  // Write sprite 5 to address 50

    // Read back the written data
    test_read(5'd0, 5'd0);   // Should read sprite 10 (address 0)
    test_read(5'd1, 5'd0);   // Should read sprite 20 (address 1)
    test_read(5'd10, 5'd2);  // Should read sprite 5 (address 50: 2*20 + 10 = 50)

    // Test another write and read
    test_write(9'd299, 5'd31); // Write to last address
    test_read(5'd19, 5'd14);   // Read from last address (14*20 + 19 = 299)

    $display("Test completed");
    $finish;
end

task test_read(input [4:0] x, y);
begin
    x_tile = x;
    y_tile = y;
    sig_write_ram = 0;
    #10;  // Wait one clock cycle
    $display("%t | READ      | %d     | %d     | -       | -        | %d", $time, x, y, id_sprite);
end
endtask

task test_write(input [8:0] addr, input [4:0] data);
begin
    ram_addr = addr;
    sprite_in = data;
    sig_write_ram = 1;
    #10;  // Wait one clock cycle for write
    sig_write_ram = 0;
    $display("%t | WRITE     | -     | -     | %d     | %d       | -", $time, addr, data);
end
endtask

endmodule