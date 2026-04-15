module VGA(
    input wire pixel_clk,
    input wire reset,
    input wire [7:0] r_in,
    input wire [7:0] g_in,
    input wire [7:0] b_in,

    output wire [9:0] pixel_x, 
    output wire [9:0] pixel_y,
    output reg video_active,

    output reg [7:0] VGA_R,
    output reg [7:0] VGA_G,
    output reg [7:0] VGA_B,
    output reg VGA_HS,
    output reg VGA_VS,
    output wire VGA_BLANK_N,
    output wire VGA_SYNC_N,
    output wire VGA_CLK
);

assign VGA_CLK = pixel_clk;

// Configurações do Datasheet
assign VGA_BLANK_N = 1;
assign VGA_SYNC_N = 0;

reg [9:0] h_count = 0;  // Active: 640 Front: 16 Sync: 96 Back: 48 // 800 no total
reg [9:0] v_count = 0;  // Active: 480 Front: 11 Sync:  2 Back: 31 // 524 no total

assign pixel_x = (h_count < 640) ? h_count : 10'd0;
assign pixel_y = (v_count < 480) ? v_count : 10'd0;

always @(posedge pixel_clk) begin
    if (reset) begin
        VGA_HS <= 1;
        VGA_VS <= 1;
        VGA_R <= 8'b00000000;
        VGA_G <= 8'b00000000;
        VGA_B <= 8'b00000000;
        h_count <= 0;
        v_count <= 0;
        video_active <= 0;

    end else begin

        if (h_count < 10'd640 && v_count < 10'd480) begin
            VGA_R <= r_in;
            VGA_G <= g_in;
            VGA_B <= b_in;
            video_active <= 1;
        end else begin
            VGA_R <= 8'b00000000;
            VGA_G <= 8'b00000000;
            VGA_B <= 8'b00000000;
            video_active <= 0;
        end

        if (h_count >= 10'd799) begin
            h_count <= 10'd0;
            if (v_count >= 523) begin
                v_count <= 10'd0;
            end else begin
                v_count <= v_count + 1'b1;
            end
        end else begin
            h_count <= h_count + 1'b1;
        end

        // Porção SyncPulse
        if (h_count >= 10'd656 && h_count < 10'd752)
            VGA_HS <= 0;
        else 
            VGA_HS <= 1;

        // Porção SyncPulse
        if (v_count >= 10'd491 && v_count < 10'd493)
            VGA_VS <= 0;
        else
            VGA_VS <= 1;
    end
end

endmodule