module ram1_rom1_top_tb;

reg clk = 0;
always #5 clk = ~clk;

// Screen coordinates
reg [9:0] x;
reg [8:0] y;

wire [7:0] pixel;

// Instantiate top module
ram1_rom1_top uut (
    .clk(clk),
    .x(x),
    .y(y),
    .pixel(pixel)
);

integer file;

// Simple color mapping (no palette, just for image)
function [23:0] map_color;
    input [7:0] val;
    begin
        case (val)
            8'h00: map_color = 24'h000000; // black
            8'h01: map_color = 24'hFF0000; // red
            8'h02: map_color = 24'h00FF00; // green
            default: map_color = 24'hFFFFFF; // white
        endcase
    end
endfunction

integer r, g, b;
reg [23:0] rgb;

initial begin
    file = $fopen("frame.ppm", "w");

    // PPM header
    $fwrite(file, "P3\n");
    $fwrite(file, "640 480\n");
    $fwrite(file, "255\n");

    for (y = 0; y < 480; y = y + 1) begin
        for (x = 0; x < 640; x = x + 1) begin
            #10;

            rgb = map_color(pixel);

            r = (rgb >> 16) & 8'hFF;
            g = (rgb >> 8)  & 8'hFF;
            b = (rgb)       & 8'hFF;

            $fwrite(file, "%0d %0d %0d\n", r, g, b);
        end
    end

    $fclose(file);
    $finish;
end

endmodule