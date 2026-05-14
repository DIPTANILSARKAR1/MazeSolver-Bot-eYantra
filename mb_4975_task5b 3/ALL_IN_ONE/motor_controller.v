module motor_controller (
    input  wire        clk,
    input  wire        reset,
	//input  wire        enable,

    input  wire [15:0] dis_l,
    input  wire [15:0] dis_f,
    input  wire [15:0] dis_r,

   input  wire [31:0] count_A,
   input  wire [31:0] count_B,

    input  wire        ir_l,
    input  wire        ir_f,
    input  wire        ir_r,
	 
	//  input wire         servo_stop,

    output wire        ENA,
    output wire        ENB,
    output reg         IN1,
    output reg         IN2,
    output reg         IN3,
    output reg         IN4,
	//  output reg         End,
	//  output wire       servo_start,
//	 output wire  [3:0]      turn,
	//  output reg   [3:0]     mpi_count
);

parameter STOP 	  		  	= 4'd0;
parameter FORWARD 		   	= 4'd1;
parameter BEFORE_TURN_FWD	= 4'd3;
parameter BEFORE_TURN_STOP 	= 4'd4;
parameter LEFT 	  		   	= 4'd5;
parameter RIGHT 		   	= 4'd6;
parameter UTURN 		   	= 4'd7;
parameter AFTER_TURN_STOP  	= 4'd8;
parameter AFTER_TURN_FWD 	= 4'd9;

parameter BEFORE_FWD_DC_L	= 1400; // before turn forward delay count left 
parameter BEFORE_FWD_DC_R	= 1400; // before turn forward delay count right
parameter AFTER_FWD_DC_L	= 1400; // before turn forward delay count left 
parameter AFTER_FWD_DC_R	= 1400; // before turn forward delay count right
parameter LEFT_WHC_L 		= 1400; // left turn wheel count left
parameter LEFT_WHC_R 		= 1400; // left turn wheel count left
parameter RIGHT_WHC_L 		= 1400; // right turn wheel count left
parameter RIGHT_WHC_R 		= 1400; // right turn wheel count left
parameter UTURN_WHC_L 		= 2800; // uturn turn wheel count left
parameter UTURN_WHC_R 		= 2800; // uturn turn wheel count left

parameter BF_TURN_DELAY 	= 18_000_000; // before turn stop delay 
parameter AF_TURN_DELAY 	= 18_000_000; // after turn stop delay 

parameter F=0, L=1, R=2, U=3;

reg [3:0] state ;
reg [1:0] turn ;
reg [31:0] delay_counter;
reg ob_l, ob_r, ob_f;
reg [5:0] duty_left , duty_right ;
reg [31:0] store_l_count , store_r_count;
pwm_generator pwm_left 	(clk,	duty_left,	ENA);
pwm_generator pwm_right	(clk,	duty_right,	ENB);
always @(posedge clk or negedge reset)begin
	if(!reset)begin
		ob_f <= 0;
		ob_l <= 0;
		ob_r <= 0;
	end
	else begin
		ob_f <= (dis_f < 180);
		ob_r <= (dis_r < 180);
		ob_l <= (dis_l < 180);
	end
end

wire [31:0] dis_l_count = (count_A >= store_l_count) ? 
                          (count_A - store_l_count) : 
                          (store_l_count - count_A);

wire [31:0] dis_r_count = (count_B >= store_r_count) ? 
                          (count_B - store_r_count) : 
                          (store_r_count - count_B);

always @(posedge clk or negedge reset)begin
	if(!reset)begin
		state 		<= FORWARD;
		delay_counter <= 0;
		turn <= 0;
		store_l_count <= 0;
		store_r_count <= 0;
	end
	else begin
		case(state)
			FORWARD :begin
				if(!ob_l) begin
					state <= BEFORE_TURN_FWD ;
					delay_counter <= 0;
					turn <= L;
					store_l_count <= count_A;
					store_r_count <= count_B;
				end
				else if (ob_l && !ob_f ) begin
					state <= FORWARD ;
					delay_counter <= 0;
					turn <= F;
					store_l_count <= count_A;
					store_r_count <= count_B;
				end
				else if (ob_l && ob_f && !ob_r) begin
					state <= BEFORE_TURN_FWD;
					delay_counter <= 0;
					turn <= R;
					store_l_count <= count_A;
					store_r_count <= count_B;
				end
				else begin
					state <= BEFORE_TURN_FWD;
					delay_counter <= 0;
					turn <= U;
					store_l_count <= count_A;
					store_r_count <= count_B;
				end
			end

			BEFORE_TURN_FWD : begin
				if(ob_f)begin
					state <= BEFORE_TURN_STOP ;
					store_l_count <= count_A;
					store_r_count <= count_B;
				end
				else if(dis_l_count >= BEFORE_FWD_DC_L && dis_r_count >= BEFORE_FWD_DC_R) begin
					state <= BEFORE_TURN_STOP ;
					store_l_count <= count_A;
					store_r_count <= count_B;
				end
				else begin
					state <= BEFORE_TURN_FWD  ;
				end
			end

			BEFORE_TURN_STOP : begin
				delay_counter <= delay_counter + 1'b1 ;
				if(delay_counter >= BF_TURN_DELAY ) begin
					delay_counter <= 0;
					case(turn) 
						L: begin
							state <= LEFT  ;
							store_l_count <= count_A;
							store_r_count <= count_B;
						end
						R: begin
							state <= RIGHT ;
							store_l_count <= count_A;
							store_r_count <= count_B;
						end
						U: begin
							state <= UTURN ;
							store_l_count <= count_A;
							store_r_count <= count_B;
						end
						default : begin
							state <= FORWARD ;
							store_l_count <= count_A;
							store_r_count <= count_B;
						end
					endcase
				end
				else begin
					state <= BEFORE_TURN_STOP  ;
				end
			end
 
			LEFT : begin
				if(ir_l) begin
					state <= AFTER_TURN_STOP ;
					delay_counter <= 0;
				end
				else if(dis_l_count >= LEFT_WHC_L && dis_r_count >= LEFT_WHC_R) begin
					state <= AFTER_TURN_STOP ;
					delay_counter <= 0;
				end
			end

			RIGHT : begin
				if(ir_r) begin
					state <= AFTER_TURN_STOP ;
					delay_counter <= 0;
				end
				else if(dis_l_count >= RIGHT_WHC_L && dis_r_count >= RIGHT_WHC_R) begin
					state <= AFTER_TURN_STOP ;
					delay_counter <= 0;
				end
			end
			
			UTURN : begin
				if(dis_l_count >= UTURN_WHC_L && dis_r_count >= UTURN_WHC_R) begin
					state <= AFTER_TURN_STOP ;
					delay_counter <= 0;
				end
			end

			AFTER_TURN_STOP :begin
				store_l_count <= 0;
				store_r_count <= 0;
				delay_counter <= delay_counter + 1'b1 ;
				if(delay_counter >= AF_TURN_DELAY ) begin
					delay_counter <= 0;
					state <= AFTER_TURN_FWD;
					store_l_count <= count_A;
					store_r_count <= count_B;
				end
			end

			AFTER_TURN_FWD : begin
				if(ob_f)begin
					state <= FORWARD ;
					store_l_count <= count_A;
					store_r_count <= count_B;
				end
				else if(dis_l_count >= AFTER_FWD_DC_L && dis_r_count >= AFTER_FWD_DC_R) begin
					state <= FORWARD ;
					store_l_count <= count_A;
					store_r_count <= count_B;
				end
			end
			default : begin
				state <= FORWARD ;
			end
		endcase 
	end
end

always @(*) begin
	case(state)
			FORWARD : begin
				duty_left 	<= 25 ;
				duty_right 	<= 25 ;
				IN1 <= 1 ; IN2 <= 0 ;
				IN3 <= 1 ; IN4 <= 0 ;
			end

			BEFORE_TURN_FWD : begin
				duty_left 	<= (dis_l_count <= BEFORE_FWD_DC_L)? 25 : 0; 
				duty_right 	<= (dis_r_count <= BEFORE_FWD_DC_R)? 25 : 0; 
				IN1 <= 1 ; IN2 <= 0 ;
				IN3 <= 1 ; IN4 <= 0 ;
			end

			BEFORE_TURN_STOP : begin
				duty_left 	<= 0 ;
				duty_right 	<= 0 ;
				IN1 <= 0 ; IN2 <= 0 ;
				IN3 <= 0 ; IN4 <= 0 ;
			end
			LEFT 	: begin
				duty_left 	<= (dis_l_count <= LEFT_WHC_L )? 25 : 0; 
				duty_right 	<= (dis_r_count <= LEFT_WHC_R )? 25 : 0; 
				IN1 <= 0 ; IN2 <= 1 ;
				IN3 <= 1 ; IN4 <= 0 ;
			end
			RIGHT 	: begin
				duty_left 	<= (dis_l_count <= RIGHT_WHC_L )? 25 : 0; 
				duty_right 	<= (dis_r_count <= RIGHT_WHC_R)? 25 : 0; 
				IN1 <= 1 ; IN2 <= 0 ;
				IN3 <= 0 ; IN4 <= 1 ;
			end
			UTURN	:begin
				duty_left 	<= (dis_l_count <= UTURN_WHC_L)? 25 : 0; 
				duty_right 	<= (dis_r_count <= UTURN_WHC_R)? 25 : 0; 
				IN1 <= 1 ; IN2 <= 0 ;
				IN3 <= 0 ; IN4 <= 1 ;
			end

			AFTER_TURN_STOP : begin
				duty_left 	<= 0 ;
				duty_right 	<= 0 ;
				IN1 <= 0 ; IN2 <= 0 ;
				IN3 <= 0 ; IN4 <= 0 ;
			end

			AFTER_TURN_FWD : begin
				duty_left 	<= (dis_l_count <= BEFORE_FWD_DC_L)? 25 : 0; 
				duty_right 	<= (dis_r_count <= BEFORE_FWD_DC_R)? 25 : 0; 
				IN1 <= 1 ; IN2 <= 0 ;
				IN3 <= 1 ; IN4 <= 0 ;
			end
			default : begin
				duty_left 	<= 25 ;
				duty_right 	<= 25 ;
				IN1 <= 1 ; IN2 <= 0 ;
				IN3 <= 1 ; IN4 <= 0 ;
			end
	endcase
end


endmodule

module pwm_generator(
    input clk,
    input [5:0] duty_cycle,
    output reg pwm_signal   
);

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////
reg [5:0] pwm_counter = 0;

always @(posedge clk) begin
    if (pwm_counter == 63)
        pwm_counter <= 0;
    else
        pwm_counter <= pwm_counter + 1'b1;

    // --- PWM signal ---
    pwm_signal <= (pwm_counter < duty_cycle);
end
//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule