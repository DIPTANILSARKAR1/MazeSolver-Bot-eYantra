module motor_controller (
    input  wire        clk,
    input  wire        reset,        // active-low

    input  wire [15:0] dis_l,
    input  wire [15:0] dis_f,
    input  wire [15:0] dis_r,

    input  wire [31:0] count_A,
    input  wire [31:0] count_B,

    input  wire        ir_l,
    input  wire        ir_f,
    input  wire        ir_r,

    output wire        ENA,
    output wire        ENB,
    output reg         IN1,
    output reg         IN2,
    output reg         IN3,
    output reg         IN4
);

    /* ================= STATES ================= */
    parameter STOP=3'b000, FORWARD=3'b001, LEFT=3'b010,
              RIGHT=3'b011, UTURN=3'b100, BACK = 3'b101;

    parameter BEFORE_DELAY_L  = 25_000_000,
			     TURN_DELAY_L    = 28_000_000,
			     AFTER_DELAY_L   = 10_000_000,
				  
			     
			    TURN_DELAY_R    = 22_000_000,
	
				  
			    BEFORE_DELAY_U  = 50_000_000, 
			    TURN_DELAY_U    = 120_000_000,
			    AFTER_DELAY_U   = 180_000_000,
				  
			    BACK_DELAY =25_000_000;


    reg [2:0] state;
    reg [31:0] delay_counter ;
	 


    wire signed [17:0] diff;


    /* ================= PWM ================= */
    reg [5:0] duty_A, duty_B;
    pwm_generator pwmA (clk, duty_A, ENA);
    pwm_generator pwmB (clk, duty_B, ENB);

    /* ================= PID ================= */
    reg signed [3:0] error, prev_error;
    reg signed [3:0] derivative;
    reg signed [5:0] pid_out;
    reg signed [3:0] next_error;

    

    parameter signed KP = 4;
    parameter signed KD = 3;

    parameter BASE_SPEED = 30;
    parameter MAX_SPEED   = 63;
    parameter SLOW_TURN_SPEED = 20;
    parameter TURN_SPEED_L = 20;
    parameter TURN_SPEED_R = 20;
    parameter TURN_SPEED_U = 20;
    parameter SAFE_DISTANCE = 60 ;





    wire [15:0] l = (dis_l > 150) ? 150 : dis_l;
    wire [15:0] r = (dis_r > 150) ? 150 : dis_r;
    assign diff = l - r;


    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            error       <= 0;
            prev_error  <= 0;
            derivative  <= 0;
            next_error  <= 0;
        end 
        else begin
            if (state == FORWARD) begin
                if (diff > 60)         next_error <= 3;
                else if (diff > 40)    next_error <= 2;
                else if (diff > 20)    next_error <= 1;
                else if (diff < -60)   next_error <= -3;
                else if (diff < -40)   next_error <= -2;
                else if (diff < -20)   next_error <= -1;
                else                   next_error <= 0;
                if ((next_error - prev_error) > 4)
                    derivative <= 8;
                else if ((next_error - prev_error) < -4)
                    derivative <= -8;
                else
                    derivative <= next_error - prev_error;

                prev_error <= next_error;
                error <= next_error;
            end
            else begin
                    error <= 0;
                    prev_error <= 0;
                    derivative <= 0;
                    next_error <= 0;
            end 
        end
    end

    wire signed [7:0] pid_raw;
    assign pid_raw = KP*error + KD*derivative;

    always @(*) begin
        if (pid_raw > 16)
            pid_out = 16 ;
        else if (pid_raw < -16)
            pid_out = -16;
        else
            pid_out = pid_raw;
        
    end


    /* ================= MOTOR CONTROL ================= */
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            IN1<=0; IN2<=0; IN3<=0; IN4<=0;
            duty_A<=0; duty_B<=0;
            delay_counter <= 0;
            state <= FORWARD ;
        end else begin

                case(state)

                    FORWARD: begin
                        IN1 <=1; IN2 <=0; 
                        IN3 <=1; IN4 <=0;
					         duty_A <= BASE_SPEED - pid_out;
                        duty_B <= BASE_SPEED + pid_out;
								
                        if (!ir_l ) begin
                            state <= LEFT ;
                            delay_counter <= 0;
                        end
								
                        else if ( ir_l && !ir_f)begin
                            state <= FORWARD ;
                            delay_counter <= 0;
                        end
								
                        else if ( ir_l && ir_f && !ir_r )begin
                            state <= RIGHT ;
                            delay_counter <= 0;
                        end
                        else begin
                            state <= UTURN ;
                            delay_counter <= 0;
								end
                    end

                    LEFT: begin
                        delay_counter <= delay_counter + 1'b1;
                        if ((delay_counter < BEFORE_DELAY_L ) && !ir_f )begin
                            IN1 <=1; IN2 <=0; 
                            IN3 <=1; IN4 <=0;
                            duty_A<= SLOW_TURN_SPEED ; duty_B <= SLOW_TURN_SPEED;
                        end
                        else if ((delay_counter < BEFORE_DELAY_L + TURN_DELAY_L) && !ir_l )begin
                            IN1 <= 0; IN2<= 1; 
                            IN3 <= 1; IN4<= 0;
                            duty_A <= TURN_SPEED_L-10 ; 
                            duty_B <= TURN_SPEED_L ;
                        end
								else if ((delay_counter < BEFORE_DELAY_L + TURN_DELAY_L+ AFTER_DELAY_L)  && !ir_f) begin
									 IN1 <=1; IN2 <=0; 
                            IN3 <=1; IN4 <=0;
                            duty_A<= SLOW_TURN_SPEED   ; duty_B <= SLOW_TURN_SPEED;
                        end
                        else begin
                            state <= FORWARD;
                            delay_counter <= 0;
                        end
                    end

                    RIGHT: begin
                        delay_counter <= delay_counter + 1'b1;
                        if (delay_counter < TURN_DELAY_R)begin
                            IN1 <= 1; IN2<= 0; 
                            IN3 <= 0; IN4<= 1;
                            duty_A <= TURN_SPEED_R ; 
                            duty_B <= TURN_SPEED_R - 5 ;
                        end
                        else begin
                            state <= FORWARD;
                            delay_counter <= 0;
									
									 
                        end
                    end

                    UTURN: begin 
						delay_counter <= delay_counter + 1'b1;
                        if (((delay_counter < TURN_DELAY_U) && ir_f ) || dis_l<SAFE_DISTANCE)begin
                            IN1 <= 1; IN2<= 0; 
                            IN3 <= 0; IN4<= 1;
                            duty_A <= TURN_SPEED_U  ; 
                            duty_B <= TURN_SPEED_U + 10 ;
                        end
          
                        else begin
                            state <= FORWARD;
                            delay_counter <= 0;
                        end
                    end

                    default: begin
                        IN1<=0; IN2<=0; IN3<=0; IN4<=0;
                        duty_A <=0; duty_B <= 0;
                    end
                endcase

            end
        end

endmodule