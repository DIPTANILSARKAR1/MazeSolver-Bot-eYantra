`timescale 1ns/1ps

module tb_robot_motor_top;

    // --------------------------------------------------
    // DUT inputs
    // --------------------------------------------------
    reg clk;
    reg reset;

    reg EN1_A;   // Encoder A channel A
    reg EN2_A;   // Encoder A channel B
    reg EN1_B;   // Encoder B channel A
    reg EN2_B;   // Encoder B channel B

    // --------------------------------------------------
    // DUT outputs
    // --------------------------------------------------
    wire ENA, ENB;
    wire IN1, IN2, IN3, IN4;

    // --------------------------------------------------
    // Instantiate DUT
    // --------------------------------------------------
    robot_motor_top dut (
        .clk   (clk),
        .reset (reset),

        .EN1_A (EN1_A),
        .EN2_A (EN2_A),
        .EN1_B (EN1_B),
        .EN2_B (EN2_B),

        .ENA (ENA),
        .ENB (ENB),
        .IN1 (IN1),
        .IN2 (IN2),
        .IN3 (IN3),
        .IN4 (IN4)
    );

    // --------------------------------------------------
    // Clock generation: 50 MHz (20 ns period)
    // --------------------------------------------------
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // --------------------------------------------------
    // Reset (ACTIVE HIGH)
    // --------------------------------------------------
    initial begin
        reset = 1;
        EN1_A = 0; EN2_A = 0;
        EN1_B = 0; EN2_B = 0;

        #100;
        reset = 0;
    end

    // --------------------------------------------------
    // TASK: Quadrature encoder CW (forward)
    // --------------------------------------------------
    task encoder_cw;
        output reg A;
        output reg B;
        begin
            A = 0; B = 0; #40;
            A = 1; B = 0; #40;
            A = 1; B = 1; #40;
            A = 0; B = 1; #40;
        end
    endtask

    // --------------------------------------------------
    // TASK: Quadrature encoder CCW (reverse)
    // --------------------------------------------------
    task encoder_ccw;
        output reg A;
        output reg B;
        begin
            A = 0; B = 0; #40;
            A = 0; B = 1; #40;
            A = 1; B = 1; #40;
            A = 1; B = 0; #40;
        end
    endtask

    // --------------------------------------------------
    // Encoder A stimulus (CW then CCW)
    // --------------------------------------------------
    initial begin
        #200;
        repeat (200) encoder_cw(EN1_A, EN2_A);
        repeat (100) encoder_ccw(EN1_A, EN2_A);
    end

    // --------------------------------------------------
    // Encoder B stimulus (CW only, delayed start)
    // --------------------------------------------------
    initial begin
        #600;
        repeat (300) encoder_cw(EN1_B, EN2_B);
    end

    // --------------------------------------------------
    // End simulation
    // --------------------------------------------------
    initial begin
        #200000;
        $finish;
    end

endmodule
