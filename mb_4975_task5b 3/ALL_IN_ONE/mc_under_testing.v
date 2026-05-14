module motor_controller (
    input  wire        clk,
    input  wire        reset,
	 input  wire        enable,

    input  wire [15:0] dis_l,
    input  wire [15:0] dis_f,
    input  wire [15:0] dis_r,

	 input  wire [31:0] count_A,
	 input  wire [31:0] count_B,

    input  wire        ir_l,
    input  wire        ir_f,
    input  wire        ir_r,
	 
	 input wire         servo_stop,

    output wire        ENA,
    output wire        ENB,
    output reg         IN1,
    output reg         IN2,
    output reg         IN3,
    output reg         IN4,
	 output reg         End,
	 output reg      	  servo_req,
	 output reg   [3:0]     mpi_count,
	 output reg    [1:0] turn_done ,
	 
	 output reg led1,led2,led3,led4,led5
);

////////////////////////////////////////parameters///////////////////////////////////
parameter  FORWARD = 4'd0;
parameter  LEFT 	 = 4'd1;
parameter  RIGHT	 = 4'd2;
parameter  UTURN	 = 4'd3;
parameter  SERVO	 = 4'd4;
parameter  STOP	 = 4'd5;
parameter  BFD     = 4'd6;
parameter  AFD     = 4'd7;
parameter  SBT     = 4'd8;
parameter  SAT     = 4'd9;

parameter BASE_SPEED_L = 45;
parameter BASE_SPEED_R = 45;
parameter TURN_SPEED_L = 25;
parameter TURN_SPEED_R = 25;
parameter L_MAX_SPEED  = 45;
parameter R_MAX_SPEED  = 45;
parameter L_MIN_SPEED  = 15;
parameter R_MIN_SPEED  = 15;

//turn 
parameter S = 3'd0 ,F = 3'd1 , L = 3'd2 , R = 3'd3 , U = 3'd4;


//counts 
parameter C_BFD_L 	    = 1800;
parameter C_BFD_R 	    = 1800;
parameter C_AFD_L 	    = 1800;
parameter C_AFD_R 	    = 1800;
parameter C_LEFT_L 	    = 1400;//count left turn l wheel
parameter C_LEFT_R 	    = 1400;
parameter C_RIGHT_L 	= 1400;
parameter C_RIGHT_R 	= 1400;
parameter C_UTURN_L 	= 2800;
parameter C_UTURN_R 	= 2800;

parameter KP=15 ,KD = 10;

//delays 
parameter SBT_DELAY  = 18_000_000; //same delay for bot after stop and before stop

////////////////////////////////////////Asignments/////////////////////////////////
reg [5:0] duty_A,duty_B;
pwm_generator pwmA(clk,duty_A,ENA);
pwm_generator pwmB(clk,duty_B,ENB);

reg [3:0] state;
reg [31:0] delay_counter;
reg [2:0] turn ;
reg signed [31:0] count_l , count_r ;

//pid _ controllers 
reg signed [4:0] error,prev_error;
wire signed [5:0] derivative;
wire signed [7:0] pid_out;
assign derivative=error-prev_error;
assign pid_out=(KP*error)+(KD*derivative);

//encoders some logic + assignments ................................................
wire signed [31:0] diff_A;
wire signed [31:0] diff_B;
assign diff_A = count_A - count_l;
assign diff_B = count_B - count_r;
//making absolute distance .........................................................
wire [31:0] dist_A = (diff_A >= 0) ? diff_A : -diff_A;
wire [31:0] dist_B = (diff_B >= 0) ? diff_B : -diff_B;


////////////////////////////////////////signals & handshaking////////////
//-------------------------------------objects detection-----------------
reg ob_ll,ob_ff,ob_rr;
always @(posedge clk) begin
    ob_ll <= (dis_l < 160);
    ob_ff <= (dis_f < 130); 
    ob_rr <= (dis_r < 160);
end


//-------------------------------------------servo request---------------
always @(posedge clk or negedge reset) begin
    if (!reset)					servo_req <= 1'b0;
	 else if(!enable)			servo_req <= 1'b0;
    else if (state == SERVO)	servo_req <= 1'b1;      // request servo ONCE
    else 						servo_req <= 1'b0;
end


//-----------------------------------------------END signal--------------
always @(posedge clk or negedge reset) begin
    if (!reset)
        End <= 1'b0;
    else
        End <= (state == STOP);
end
///////////////////////////////////////signals end here ////////////////////

///////////////////////////////////////PID /////////////////////////////////
always @(posedge clk or negedge reset) begin
    if(!reset ) begin 
        error<=0; 
        prev_error<=0; 
    end
	else if(!enable)begin
	    error<=0; 
        prev_error<=0;
	 end
    else if(state==FORWARD) begin
        prev_error<=error;

		if(ob_ll && ob_rr)begin
			if(ir_l&&!ir_r)         error<=  2;
			else if(!ir_l&&ir_r)    error<= -2;
			else                    error<=  0;
		end

		else if (ob_ll && !ob_rr && !ob_ff)begin//
			if(ir_l)                error<=  2;
			else                    error<= -2;
		end

    end
    else begin 
        error<=0; 
        prev_error<=0; 
    end
end

///////////////////////////////////////PID ENDS HERE ////////////////////////


///////////////////////////////////////MAIN FSM//////////////////////////////

always @(posedge clk or negedge reset)begin
	if(!reset)begin
		state <= FORWARD ;
		delay_counter <= 0 ;
		count_l <= 0;
		count_r <= 0;
		duty_A <= 0;
		duty_B <= 0;
		turn_done <= 0;
		IN1 <= 0; IN2 <= 0;
		IN3 <= 0; IN4 <= 0;
		led1 <= 0; led2 <= 0; led3 <= 0; led4 <= 0 ; led5 <= 0;
	end
	else if (!enable)begin
		state <= FORWARD ;
		delay_counter <= 0 ;
		count_l <= 0;
		count_r <= 0;
		duty_A <= 0;
		duty_B <= 0;
		turn_done <= 0;
		IN1 <= 0; IN2 <= 0;
		IN3 <= 0; IN4 <= 0;
		led1 <= 0; led2 <= 0; led3 <= 0; led4 <= 0 ; led5 <= 0;
	end
	else begin
		led1 <= 0; led2 <= 0; led3 <= 0; led4 <= 0 ; led5 <= 0;
		case(state)
			FORWARD: begin
                led1 <= 1;
                turn_done <= 0;

                //pid
                if(BASE_SPEED_L + pid_out > L_MAX_SPEED )begin
                    duty_A<=L_MAX_SPEED;
                end
                else if(BASE_SPEED_L + pid_out< L_MIN_SPEED)begin
                    duty_A<=L_MIN_SPEED;
                end 
                else begin
                    duty_A<=BASE_SPEED_L + pid_out;
                end

                if(BASE_SPEED_R + pid_out > R_MAX_SPEED )begin
                    duty_B<=R_MAX_SPEED;
                end
                else if(BASE_SPEED_R + pid_out< R_MIN_SPEED)begin
                    duty_B<=R_MIN_SPEED;
                end 
                else begin
                    duty_B=BASE_SPEED_R - pid_out;
                end
                //end


                IN1 <= 1; IN2 <= 0;
                IN3 <= 1; IN4 <= 0;

                if(!ob_ll) begin
                    turn <= L;

                    count_l <= count_A;
                    count_r <= count_B;

                    state <= BFD;
                end
                else if(ob_ll && !ob_ff) begin
                    turn <= F;
                    
                    count_l <= count_A;
                    count_r <= count_B;

                    state <= FORWARD;
                end
                else if(ob_ll && ob_ff && !ob_rr) begin
                    turn <= R;

                    count_l <= count_A;
                    count_r <= count_B;

                    state <= BFD;
                end
                else begin
                    turn <= U;

                    count_l <= count_A;
                    count_r <= count_B;

                    state <= BFD;
                end 
		   end

			
			BFD: begin
					led2 <= 1;
					turn_done <= 0;

					IN1 <= 1; IN2 <= 0;
					IN3 <= 1; IN4 <= 0;

					if(dist_A >= C_BFD_L)
						duty_A <= 0;
					else
						duty_A <= BASE_SPEED_L;

					if(dist_B >= C_BFD_R)
						duty_B <= 0;
					else
						duty_B <= BASE_SPEED_R;

					if((dist_A >= C_BFD_L && dist_B >= C_BFD_R) || ir_f)begin// ir_f
						count_l <= count_A;
						count_r <= count_B;
						state <= SBT ; 
						delay_counter <= 0;
					end
					
		   end
			
			//testing for finest ...
			SBT: begin
					led2 <= 5;
					turn_done <= 0;

					IN1 <= 0; IN2 <= 0;
					IN3 <= 0; IN4 <= 0;
					duty_A <= 0;
					duty_B <= 0; 

					delay_counter <= delay_counter + 1'b1;
					
					case(turn)
						L: begin
							if (ir_l) begin
								state<=FORWARD;
							end
						end
						R: begin
							if (ir_r) begin
								state<=FORWARD;
							end
						end
						default : state <= SBT;
					endcase
 
					if(delay_counter >= SBT_DELAY) begin
						count_l <= count_A;
						count_r <= count_B;
						delay_counter <= 0;
						case(turn)
							L: state <= LEFT ;
							R: state <= RIGHT;
							U: state <= UTURN;
							default : state <= FORWARD;
						endcase	
					end
		   end


			LEFT: begin
					led3 <= 3;

					IN1 <= 0; IN2 <= 1;   // left wheel reverse
					IN3 <= 1; IN4 <= 0;   // right wheel forward

					if(dist_A >= C_LEFT_L)
						duty_A <= 0;
					else
						duty_A <= TURN_SPEED_L;

					if(dist_B >= C_LEFT_R)
						duty_B <= 0;
					else
						duty_B <= TURN_SPEED_R;

					if((dist_A >= C_LEFT_L) && (dist_B >= C_LEFT_R)) begin
						count_l <= count_A;
						count_r <= count_B;
						
						turn_done <= 1;
						state <= SAT;
//						state <= AFD;
					end
			  end
			  
			  RIGHT: begin
					led3 <= 4;

					IN1 <= 1; IN2 <= 0;   // left wheel reverse
					IN3 <= 0; IN4 <= 1;   // right wheel forward

					if(dist_A >= C_RIGHT_L)
						duty_A <= 0;
					else
						duty_A <= TURN_SPEED_L;

					if(dist_B >= C_RIGHT_R)
						duty_B <= 0;
					else
						duty_B <= TURN_SPEED_R;

					if((dist_A >= C_RIGHT_L) && (dist_B >= C_RIGHT_R)) begin
						count_l <= count_A;
						count_r <= count_B;
						
						turn_done <= 2;
						state <= SAT;
//						state <= AFD;
					end
			  end
			  
			  UTURN : begin
					led3 <= 5;

					IN1 <= 0; IN2 <= 1;   // left wheel reverse
					IN3 <= 1; IN4 <= 0;   // right wheel forward

					if(dist_A >= C_UTURN_L)
						duty_A <= 0;
					else
						duty_A <= TURN_SPEED_L;

					if(dist_B >= C_UTURN_R)
						duty_B <= 0;
					else
						duty_B <= TURN_SPEED_R;

					if((dist_A >= C_UTURN_L) && (dist_B >= C_UTURN_R)) begin
						count_l <= count_A;
						count_r <= count_B;
						
						turn_done <= 3;
						state <= SAT;
//						state <= AFD;
					end
			  end 
			  
			  SAT: begin
					led2 <= 5;

					IN1 <= 0; IN2 <= 0;
					IN3 <= 0; IN4 <= 0;
					duty_A <= 0;
					duty_B <= 0; 

					delay_counter <= delay_counter + 1'b1;

					if(delay_counter >= SBT_DELAY) begin
						count_l <= count_A;
						count_r <= count_B;
						delay_counter <= 0;
						state <= AFD ;
					end
		   end
			  
			  AFD: begin
					led2 <= 1;

					IN1 <= 1; IN2 <= 0;
					IN3 <= 1; IN4 <= 0;

					if(dist_A >= C_AFD_L)
						duty_A <= 0;
					else
						duty_A <= BASE_SPEED_L;

					if(dist_B >= C_AFD_R)
						duty_B <= 0;
					else
						duty_B <= BASE_SPEED_R;

					if((dist_A >= C_BFD_L) && (dist_B >= C_BFD_R) || ir_f || ir_l) begin//ir_f // ir_l
						count_l <= count_A;
						count_r <= count_B;
						state   <= FORWARD;
//						turn_done <= 0;
						
					end
		   end
		endcase
	end
end

endmodule