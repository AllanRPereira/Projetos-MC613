module rom_background_1_tb;

// Screen coordinates
reg [9:0] x;
reg [9:0] y;

wire [7:0] data_out;

// Instantiate top module
rom uut (
    .x(x),
    .y(y),
    .data_out(data_out)
);

integer file;

// Simple color mapping (no palette, just for image)
function [23:0] map_color;
    input [7:0] val;
    begin
        case (val)
            8'h00: map_color = 24'h000000; // black
            8'h0F: map_color = 24'h7F7F7F; // gray
            8'hFF: map_color = 24'hFFFFFF; // white
            default: map_color = 24'h000000; // default
        endcase
    end
endfunction

integer r, g, b;
reg [23:0] rgb;

initial begin
    file = $fopen("rom_background.ppm", "w");

    // PPM header
    $fwrite(file, "P3\n");
    $fwrite(file, "640 480\n");
    $fwrite(file, "255\n");

    for (y = 0; y < 480; y = y + 1) begin
        for (x = 0; x < 640; x = x + 1) begin
            #10;

            rgb = map_color(data_out);

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
