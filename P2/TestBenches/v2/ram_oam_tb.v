`timescale 1ns/1ps
module ram_oam_tb;
    reg clk;
    reg [4:0] x_tile;
    reg [4:0] y_tile;
    reg [8:0] probe_addr;
    reg sig_write_ram;
    reg [8:0] ram_addr;
    reg [4:0] sprite_in;
    wire [4:0] id_sprite;
    wire [4:0] probe_id_sprite;

    ram_oam dut (
        .clk(clk),
        .x_tile(x_tile),
        .y_tile(y_tile),
        .probe_addr(probe_addr),
        .sig_write_ram(sig_write_ram),
        .ram_addr(ram_addr),
        .sprite_in(sprite_in),
        .id_sprite(id_sprite),
        .probe_id_sprite(probe_id_sprite)
    );

    always #5 clk = ~clk;

    task write_addr;
        input [8:0] addr;
        input [4:0] data;
        begin
            ram_addr = addr;
            sprite_in = data;
            sig_write_ram = 1'b1;
            @(posedge clk);
            sig_write_ram = 1'b0;
            @(posedge clk);
            $display("write addr=%0d data=%0d", addr, data);
        end
    endtask

    task read_tile;
        input [4:0] x;
        input [4:0] y;
        begin
            x_tile = x;
            y_tile = y;
            #1;
            $display("tile=(%0d,%0d) sprite=%0d", x, y, id_sprite);
        end
    endtask

    initial begin
        $dumpfile("ram_oam_tb.vcd");
        $dumpvars(0, ram_oam_tb);

        clk = 0;
        x_tile = 0;
        y_tile = 0;
        probe_addr = 0;
        sig_write_ram = 0;
        ram_addr = 0;
        sprite_in = 0;

        #12;
        write_addr(9'd0, 5'd3);
        write_addr(9'd20, 5'd2);
        probe_addr = 9'd20;
        #1;
        $display("probe[20]=%0d", probe_id_sprite);

        read_tile(5'd0, 5'd0);
        read_tile(5'd0, 5'd1);

        $finish;
    end
endmodule
