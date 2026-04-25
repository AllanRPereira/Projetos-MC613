`timescale 1ns/1ps

module VGA_tb;

reg pixel_clk;
reg reset;
reg [7:0] r_in, g_in, b_in;

wire [9:0] pixel_x, pixel_y;
wire video_active;
wire [7:0] VGA_R, VGA_G, VGA_B;
wire VGA_HS, VGA_VS;
wire VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;

integer cycle_count;
localparam TOTAL_CYCLES = 800*524*3; // simular 3 Frames

VGA uut (
    .pixel_clk(pixel_clk),
    .reset(reset),
    .r_in(r_in),
    .g_in(g_in),
    .b_in(b_in),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y),
    .video_active(video_active),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_BLANK_N(VGA_BLANK_N),
    .VGA_SYNC_N(VGA_SYNC_N),
    .VGA_CLK(VGA_CLK)
);

initial begin
  $dumpfile("VGA_tb.vcd");
  $dumpvars(0, VGA_tb);

  pixel_clk = 0;
  reset = 1;
  r_in = 0; g_in = 0; b_in = 0;
  cycle_count = 0;

  #100;
  reset = 0;
end

// 20ns period (50 MHz) - ajustável se desejar outra frequência
always #10 pixel_clk = ~pixel_clk;

// Gerar barras de cor simples durante `video_active`
always @(posedge pixel_clk) begin
  if (reset) begin
    r_in <= 0; g_in <= 0; b_in <= 0;
  end else begin
    if (video_active) begin
      if (pixel_x < 213) begin
        r_in <= 8'hFF; g_in <= 8'h00; b_in <= 8'h00; // vermelho
      end else if (pixel_x < 426) begin
        r_in <= 8'h00; g_in <= 8'hFF; b_in <= 8'h00; // verde
      end else begin
        r_in <= 8'h00; g_in <= 8'h00; b_in <= 8'hFF; // azul
      end
    end else begin
      r_in <= 0; g_in <= 0; b_in <= 0;
    end
  end

  // contador de ciclos e parada quando atingir TOTAL_CYCLES
  if (!reset) begin
    cycle_count = cycle_count + 1;
    if (cycle_count >= TOTAL_CYCLES) begin
      $display("Simulacao completa: %0d ciclos, tempo=%0t", cycle_count, $time);
      $finish;
    end
  end
end

// Mensagens para detectar pulsos de sincronismo
always @(posedge pixel_clk) begin
  if (VGA_HS == 0)
    $display("[HS] time=%0t x=%0d y=%0d", $time, pixel_x, pixel_y);
  if (VGA_VS == 0)
    $display("[VS] time=%0t x=%0d y=%0d", $time, pixel_x, pixel_y);
end

endmodule
