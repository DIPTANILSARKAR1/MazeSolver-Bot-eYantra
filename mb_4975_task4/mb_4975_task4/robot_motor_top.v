module robot_motor_top (
    input  wire clk,
    input  wire reset,     // ACTIVE HIGH

    // Encoder inputs
    input  wire EN1_A,
    input  wire EN2_A,
    input  wire EN1_B,
    input  wire EN2_B,
	 
	 //ir input
	   input  wire ir_l,
		input  wire ir_r,
		input  wire ir_f,
		
	input wire  ec_l,
	input wire  ec_r,
	input wire  ec_f,
	
	output wire trig_l,
	output wire trig_f,
	output wire trig_r,
	 

    // Motor driver outputs
    output wire ENA,
    output wire ENB,
    output wire IN1,
    output wire IN2,
    output wire IN3,
    output wire IN4
  
);

    wire signed [31:0] count_A, count_B;
	 wire [2:0] turn;
	 wire [15:0] dis_l, dis_f, dis_r;
	 wire irw_l, irw_f, irw_r;

    // ---------------- Encoder blocks ----------------
    encoder_decoder encA (
        .clk   (clk),
        .reset (reset),
        .enc_A (EN1_A),
        .enc_B (EN2_A),
        .count (count_A)
    );

    encoder_decoder encB (
        .clk   (clk),
        .reset (reset),
        .enc_A (EN1_B),
        .enc_B (EN2_B),
        .count (count_B)
    );

   
  

    // ---------------- Motor controller ----------------
    motor_controller motor_ctrl (
        .clk     (clk),
        .reset   (reset),
        .count_A (count_A),
        .count_B (count_B),
		  .dis_l   (dis_l),
		  .dis_r   (dis_r),
		  .dis_f   (dis_f),
		  .ir_l    (irw_l),
		  .ir_f    (irw_f),
		  .ir_r    (irw_r),
        .ENA     (ENA),
        .ENB     (ENB),
        .IN1     (IN1),
        .IN2     (IN2),
        .IN3     (IN3),
        .IN4     (IN4)
    );
	 
	 path_controller path_ctrl(
			.ir_in_left		(ir_l),
			.ir_in_front	(ir_f),
			.ir_in_right	(ir_r),
		   .echo_rx_l		(ec_l),
			.echo_rx_f		(ec_f),
			.echo_rx_r		(ec_r),
			.clk 				(clk),
			.reset			(reset),
			.trig_l			(trig_l),
			.trig_f			(trig_f),
			.trig_r			(trig_r), 
			.dis_l			(dis_l),
			.dis_f			(dis_f),
			.dis_r			(dis_r),
			.ir_l    (irw_l),
			.ir_f    (irw_f),
			.ir_r    (irw_r),      
			
		);

endmodule
