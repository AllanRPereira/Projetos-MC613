`timescale 1ns/1ps
module maquina_estados_tb;
    reg clk;
    reg reset;
    reg sig_fruta;
    reg sig_mordida;
    reg sig_5ms;
    reg sig_2s;
    reg sig_batida;
    reg sig_confirmar;
    reg sig_vel;
    reg sig_dir;
    reg sig_vit;
    wire [3:0] estado_atual;

    maquina_estados dut (
        .clk(clk),
        .reset(reset),
        .sig_fruta(sig_fruta),
        .sig_mordida(sig_mordida),
        .sig_5ms(sig_5ms),
        .sig_2s(sig_2s),
        .sig_batida(sig_batida),
        .sig_confirmar(sig_confirmar),
        .sig_vel(sig_vel),
        .sig_dir(sig_dir),
        .sig_vit(sig_vit),
        .estado_atual(estado_atual)
    );

    always #5 clk = ~clk;

    task pulse_1cycle;
        begin
            @(posedge clk);
            #1;
            @(negedge clk);
        end
    endtask

    initial begin
        $dumpfile("maquina_estados_tb.vcd");
        $dumpvars(0, maquina_estados_tb);

        clk = 0;
        reset = 1;
        sig_fruta = 0; sig_mordida = 0; sig_5ms = 0; sig_2s = 0;
        sig_batida = 0; sig_confirmar = 0; sig_vel = 0; sig_dir = 0; sig_vit = 0;

        pulse_1cycle();
        reset = 0;

        sig_confirmar = 1;
        pulse_1cycle();
        sig_confirmar = 0;
        $display("estado=%0d", estado_atual);

        sig_dir = 1;
        pulse_1cycle();
        sig_dir = 0;
        $display("estado=%0d", estado_atual);

        sig_5ms = 1;
        pulse_1cycle();
        sig_5ms = 0;
        $display("estado=%0d", estado_atual);

        sig_vit = 1;
        pulse_1cycle();
        sig_vit = 0;
        $display("estado=%0d", estado_atual);

        $finish;
    end
endmodule
