module motor_controller (
    input  wire        clk,
    input  wire        reset,
	 input  wire        enable,

    input  wire [15:0] dis_l,
    input  wire [15:0] dis_f,
    input  wire [15:0] dis_r,

//    input  wire [31:0] count_A,
//    input  wire [31:0] count_B,

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
	 output wire       servo_start,
//	 output wire  [3:0]      turn,
	 output reg   [3:0]     mpi_count
);

parameter STOP=4'b0000,FORWARD=4'b0001,LEFT=4'b0010,RIGHT=4'b0011,
          FALSE_LEFT=4'b0100,UTURN=4'b0101,FALSE_RIGHT=4'b0110,
			 FALSE_FORWARD=4'b1001, SERVO=4'b0111,COPY_RIGHT=4'b1010,AFTER_NINE = 4'b1111;

parameter BASE_SPEED=45,TURN_SPEED=25,SLOW_SPEED=25;
parameter L_MAX_SPEED=60,L_MIN_SPEED=15,R_MAX_SPEED=60,R_MIN_SPEED=13;

parameter BEFORE_DELAY_L=15_000_000;//left
parameter TURN_DELAY_L=20_000_000;
parameter AFTER_DELAY_L=17_000_000;
parameter BEFORE_DELAY_R=15_000_000;//right
parameter TURN_DELAY_R=18_000_000;
parameter AFTER_DELAY_R=18_000_000;
parameter UTURN_DELAY=33_000_000;//uturn
parameter SERVO_DELAY=830_000_000;
//for false states-------------- 
parameter FALSE_L_DELAY=80_000_000;
parameter FALSE_R_DELAY=38_000_000;
parameter FALSE_F_DELAY=45_000_000;
parameter FALSE_TWO_DELAY=7_000_000;
parameter COPY_R_DELAY= 8_000_000;
parameter AFTER_EIGHT_DELAY = 10_000_000;

parameter KP=15,KD=10; // PID 

reg [5:0] duty_A,duty_B;
pwm_generator pwmA(clk,duty_A,ENA);
pwm_generator pwmB(clk,duty_B,ENB);

reg [3:0] state;
assign turn = state;
reg servo_req;
reg [31:0] delay_counter;


reg [2:0] false_count;

//-------------------------------------pid controllers ------------------
reg signed [4:0] error,prev_error;
wire signed [5:0] derivative;
wire signed [7:0] pid_out;
assign derivative=error-prev_error;
assign pid_out=(KP*error)+(KD*derivative);


//-------------------------------------objects detection-----------------
reg ob_ll,ob_ff,ob_rr;
reg [2:0] ir_value;
//reg [3:0] count_mpi;// mpi count
always @(posedge clk) begin
    ob_ll <= (dis_l < 160);
    ob_ff <= ( ir_f); // remove us in next run
    ob_rr <= (dis_r < 160);
    ir_value <= {ir_l,ir_f,ir_r};
end


//-------------------------------------------servo request---------------
always @(posedge clk or negedge reset) begin
    if (!reset)
        servo_req <= 1'b0;
		else if(!enable) 
		 servo_req <= 1'b0;
    else if (state == SERVO)
        servo_req <= 1'b1;      // request servo ONCE
    else 
		  servo_req <= 0;
end

assign servo_start = servo_req;


//--------------------------------------------pid error calculation -----
always @(posedge clk or negedge reset) begin
    if(!reset ) begin error<=0; prev_error<=0; end
	 else if(!enable)begin
	 error<=0; prev_error<=0;
	 end
    else if(state==FORWARD) begin
        prev_error<=error;
		  if(ob_ll && ob_rr)begin//test
			  if(ir_l&&!ir_r) error<=2;
			  else if(!ir_l&&ir_r) error<=-2;
			  else error<=0;
		  end//test
		  else if (ob_ll && !ob_rr && !ob_ff)begin//
				if(ir_l)error<=2;//
				else error<=-2;//
		  end//test end
    end
	 else if (state == FALSE_LEFT || state == FALSE_RIGHT)begin //
		  if(ir_r)error<=-2;//
		  else error<=2;
	 end
	 else if (state == FALSE_FORWARD) begin
			if(ir_l&&!ir_r) error<=2;
			  else if(!ir_l&&ir_r) error<=-2;
			  else error<=0;
	 end
    
    else begin error<=0; prev_error<=0; end
end


//-----------------------------------------------END signal--------------
 always @(posedge clk or negedge reset) begin
    if (!reset)
        End <= 1'b0;
    else
        End <= (state == STOP);
    end
	 
//---------------------------------------------main always block---------	 
always @(posedge clk or negedge reset) begin
    if(!reset ) begin
        state<=FORWARD; delay_counter<=0;
        duty_A<=0; duty_B<=0;
        IN1<=0;IN2<=0;IN3<=0;IN4<=0;
		  mpi_count <= 0;//count mpi
		  false_count <= 0;
    end
    else if(!enable)	begin
        state<=FORWARD; delay_counter<=0;
        duty_A<=0; duty_B<=0;
        IN1<=0;IN2<=0;IN3<=0;IN4<=0;
		  //servo_start<=0;
		  mpi_count <= 0;//count mpi
		  false_count <= 0;
    end

	else begin
        case(state)

        FORWARD: begin
            IN1<=1;IN2<=0;IN3<=1;IN4<=0;
				//servo_start<=0;
				
				
				//turn speed decider ----------------------------------------------
				if (ob_ll && ob_rr)begin
					if(BASE_SPEED+pid_out>L_MAX_SPEED) duty_A<=L_MAX_SPEED;
					else if(BASE_SPEED+pid_out<L_MIN_SPEED) duty_A<=L_MIN_SPEED;
					else duty_A<=BASE_SPEED+pid_out;

					if(BASE_SPEED-pid_out>R_MAX_SPEED) duty_B<=R_MAX_SPEED;
					else if(BASE_SPEED-pid_out<R_MIN_SPEED) duty_B<=R_MIN_SPEED;
					else duty_B<=BASE_SPEED-pid_out;
				end
				//test code 9feb
				else if (ob_ll && !ob_rr && !ob_ff)begin
					if(BASE_SPEED+pid_out>L_MAX_SPEED) duty_A<=L_MAX_SPEED;
					else if(BASE_SPEED+pid_out<L_MIN_SPEED) duty_A<=L_MIN_SPEED;
					else duty_A<=BASE_SPEED+pid_out;

					if(BASE_SPEED-pid_out>R_MAX_SPEED) duty_B<=R_MAX_SPEED;
					else if(BASE_SPEED-pid_out<R_MIN_SPEED) duty_B<=R_MIN_SPEED;
					else duty_B<=BASE_SPEED-pid_out;
				end 
				//end of test code 9feb
				else begin
					duty_A<=BASE_SPEED; 
					duty_B<=BASE_SPEED;
				end
				
				
				
				
				////--------------------------turn condition starts here -------------
//				if (dis_l>800 && dis_f>800)begin //ir_l && ob_ll && !ir_r && !ir_f && 
//					state<=STOP;
//					delay_counter <= 0;
//				end
				
				
//				//trying right hands deadends ---------------------------------------------
//				else if (mpi_count == 5 && !ob_ll && !ir_l && false_count==0)begin
//					state<=FALSE_LEFT;
//					delay_counter <= 0;
//					false_count <= 1;
//				end
				if (mpi_count == 7 && dis_r>=400 && dis_f>=400 && dis_l<=200 && !ir_r && false_count==1 )begin
					state<=FALSE_RIGHT;
					delay_counter <= 0;
					false_count <= 2;
				end 
//				else if (mpi_count == 9)begin
//					state<=AFTER_NINE;
//					delay_counter <= 0;
//				end
				else if (mpi_count == 8 && dis_f>=400 && ob_ll )begin
					state<=FALSE_FORWARD;
					delay_counter <= 0;
				end
				
				//ends here --------------------------------------------------------------------------	
				
				
				
				
				else if(ir_l && ir_f && !ob_rr)begin
					state<=RIGHT;
					delay_counter <= 0;
				end
				else if(ir_r && ir_f && !ob_ll)begin
               state<=LEFT;
					delay_counter <= 0;
				end
				else if (ir_r && ir_f && ir_r && dis_l>300 && dis_r>300 && dis_f<100)begin
					state<=COPY_RIGHT;
					delay_counter <= 0;
				end
				
				
				//main turn decision ---------------LHR------------------------------------------------
				else if (!ob_ll) begin
					state <= LEFT;
					delay_counter <= 0;
				end 
				else if(ob_ll  && !ob_ff) begin
					state <= FORWARD;
					delay_counter <= 0;
				end
				else if(ob_ll && ob_ff && !ob_rr) begin
					state <= RIGHT;
					delay_counter <= 0;
				end
				else begin
				   mpi_count <= mpi_count + 1'b1;//count mpi
					state <= SERVO;
					delay_counter <= 0;
				end
		  end
		  
        LEFT: begin
            delay_counter<=delay_counter+1;
            if((delay_counter<BEFORE_DELAY_L)&& !ir_l && !ir_f) begin // !ir_l because us can give a wrong dicision
                IN1<=1;IN2<=0;IN3<=1;IN4<=0;
                duty_A<=SLOW_SPEED; duty_B<=SLOW_SPEED;
            end
            else if((delay_counter<BEFORE_DELAY_L+TURN_DELAY_L)&& !ir_l) begin
                IN1<=0;IN2<=1;IN3<=1;IN4<=0;
                duty_A<=TURN_SPEED-4; duty_B<=TURN_SPEED;
            end
//            else if((delay_counter<BEFORE_DELAY_L+TURN_DELAY_L+AFTER_DELAY_L) && !ir_l && !ir_f) begin
//                IN1<=1;IN2<=0;IN3<=1;IN4<=0;
//                duty_A<=SLOW_SPEED; duty_B<=SLOW_SPEED;
//            end
            else begin 
					if(mpi_count==5)begin//test added
						state <= FALSE_FORWARD;
						delay_counter<=0;
					end
					else
						state<=FORWARD;
						delay_counter<=0;
					end
        end

        RIGHT: begin
            delay_counter<=delay_counter+1;
            if((delay_counter<TURN_DELAY_R) && !ir_r) begin
                IN1<=1;IN2<=0;IN3<=0;IN4<=1;
                duty_A<=TURN_SPEED; duty_B<=TURN_SPEED-4;
            end
            else if((delay_counter<TURN_DELAY_R+AFTER_DELAY_R) && !ir_r && !ir_f) begin // added && !ir_f
                IN1<=1;IN2<=0;IN3<=1;IN4<=0;
                duty_A<=SLOW_SPEED; duty_B<=SLOW_SPEED;
            end
            else begin state<=FORWARD; delay_counter<=0; end
        end


        SERVO: begin
            delay_counter<= delay_counter + 1'b1;
            if( mpi_count == 4 
					||mpi_count == 6 || mpi_count == 9 || mpi_count == 7 || mpi_count == 8)begin
					if(!servo_stop) begin //&& !servo_stop--------------------------
						 IN1<=0;IN2<=0;IN3<=0;IN4<=0;
						 duty_A<=0; duty_B<=0;
					end
					else begin state<=UTURN; delay_counter<=0;end
				end
				else begin
				    state<=UTURN; delay_counter<=0;
            end
        end

		  
        UTURN: begin
            delay_counter<=delay_counter+1;
            if((delay_counter<UTURN_DELAY)) begin
                IN1<=1;IN2<=0;IN3<=0;IN4<=1;
                duty_A<=TURN_SPEED; duty_B<=TURN_SPEED;
            end
            else begin 
					if(mpi_count >= 9 )begin
						state<=AFTER_NINE; delay_counter<=0;
					end
					else
						state<=FORWARD; delay_counter<=0; 
					end
        end

        STOP: begin
            IN1<=0;IN2<=0;IN3<=0;IN4<=0;
            duty_A<=0; duty_B<=0;
//           if(ob_ff||!ob_ll||ob_rr) state<=FORWARD;//............earliar commented
        end
		  
		  
		  
		  
		  //new state false forward AND false right------------------------------------------------
		  FALSE_LEFT: begin
//            delay_counter<=delay_counter+1;
//            if((delay_counter<BEFORE_DELAY_L) && !ir_f) begin 
//                IN1<=1;IN2<=0;IN3<=1;IN4<=0;
//                duty_A<=SLOW_SPEED; duty_B<=SLOW_SPEED;
//            end
//            else if((delay_counter<BEFORE_DELAY_L+TURN_DELAY_L)&& !ir_l) begin
//                IN1<=0;IN2<=1;IN3<=1;IN4<=0;
//                duty_A<=TURN_SPEED-4; duty_B<=TURN_SPEED;
//            end
//            else if((delay_counter<BEFORE_DELAY_L+TURN_DELAY_L+ FALSE_L_DELAY) && !ir_f) begin
//                IN1<=1;IN2<=0;IN3<=1;IN4<=0;
//					   //false pid -----------------------------------------
//                  if(BASE_SPEED+pid_out>L_MAX_SPEED) duty_A<=L_MAX_SPEED;
//						else if(BASE_SPEED+pid_out<L_MIN_SPEED) duty_A<=L_MIN_SPEED;
//						else duty_A<=BASE_SPEED+pid_out;
//
//						if(BASE_SPEED-pid_out>R_MAX_SPEED) duty_B<=R_MAX_SPEED;
//						else if(BASE_SPEED-pid_out<R_MIN_SPEED) duty_B<=R_MIN_SPEED;
//						else duty_B<=BASE_SPEED-pid_out;
//            end
//            else begin state<=FORWARD; delay_counter<=0; end
					delay_counter<=delay_counter+1;
            if((delay_counter<TURN_DELAY_R) && !ir_r) begin
                IN1<=1;IN2<=0;IN3<=0;IN4<=1;
                duty_A<=TURN_SPEED; duty_B<=TURN_SPEED-4;
            end
            else if((delay_counter<TURN_DELAY_R+AFTER_DELAY_R) && !ir_r && !ir_f) begin // added && !ir_f
                IN1<=1;IN2<=0;IN3<=1;IN4<=0;
                duty_A<=SLOW_SPEED; duty_B<=SLOW_SPEED;
            end
            else begin state<=FORWARD; delay_counter<=0; end
        end
		  
		  FALSE_RIGHT : begin
					delay_counter<=delay_counter+1;
				if(delay_counter<12_000_000)begin
				  IN1<=1;IN2<=0;IN3<=1;IN4<=0;
				  duty_A<=SLOW_SPEED; duty_B<=SLOW_SPEED;
				end
            else if((delay_counter<TURN_DELAY_R+12_000_000) && !ir_r) begin
                IN1<=1;IN2<=0;IN3<=0;IN4<=1;
                duty_A<=TURN_SPEED; duty_B<=TURN_SPEED-4;
            end
            else if((delay_counter<12_000_000+TURN_DELAY_R+AFTER_DELAY_R+FALSE_R_DELAY) && !ir_f) begin // added && !ir_f
                IN1<=1;IN2<=0;IN3<=1;IN4<=0;
                //false pid -----------------------------------------
                  if(BASE_SPEED+pid_out>L_MAX_SPEED) duty_A<=L_MAX_SPEED;
						else if(BASE_SPEED+pid_out<L_MIN_SPEED) duty_A<=L_MIN_SPEED;
						else duty_A<=BASE_SPEED+pid_out;

						if(BASE_SPEED-pid_out>R_MAX_SPEED) duty_B<=R_MAX_SPEED;
						else if(BASE_SPEED-pid_out<R_MIN_SPEED) duty_B<=R_MIN_SPEED;
						else duty_B<=BASE_SPEED-pid_out;
            end
            else begin state<=FORWARD; delay_counter<=0; end
        end
		  
		  FALSE_FORWARD :begin
		      delay_counter<=delay_counter+1;
				if((delay_counter<FALSE_F_DELAY) && !ir_f) begin // added && !ir_f
                IN1<=1;IN2<=0;IN3<=1;IN4<=0;
//                //false pid -----------------------------------------
//                  if(BASE_SPEED+pid_out>L_MAX_SPEED) duty_A<=L_MAX_SPEED;
//						else if(BASE_SPEED+pid_out<L_MIN_SPEED) duty_A<=L_MIN_SPEED;
//						else duty_A<=BASE_SPEED+pid_out;
//
//						if(BASE_SPEED-pid_out>R_MAX_SPEED) duty_B<=R_MAX_SPEED;
//						else if(BASE_SPEED-pid_out<R_MIN_SPEED) duty_B<=R_MIN_SPEED;
//						else duty_B<=BASE_SPEED-pid_out;
						if(mpi_count==5)begin
							if (ob_ll && ob_rr)begin
								if(BASE_SPEED+pid_out>L_MAX_SPEED) duty_A<=L_MAX_SPEED;
								else if(BASE_SPEED+pid_out<L_MIN_SPEED) duty_A<=L_MIN_SPEED;
								else duty_A<=BASE_SPEED+pid_out;

								if(BASE_SPEED-pid_out>R_MAX_SPEED) duty_B<=R_MAX_SPEED;
								else if(BASE_SPEED-pid_out<R_MIN_SPEED) duty_B<=R_MIN_SPEED;
								else duty_B<=BASE_SPEED-pid_out;
							end
							else begin
								duty_A<=24; 
								duty_B<=20;
							end
//							else if(ir_l && ir_r)begin
//								duty_A <= 24;
//								duty_B <= 22;
//							end
//							else begin
//								duty_A <= 24;
//								duty_B <= 20;
//							end
						end
						else if(mpi_count==8)begin
							if (ob_ll && ob_rr)begin
								if(BASE_SPEED+pid_out>L_MAX_SPEED) duty_A<=L_MAX_SPEED;
								else if(BASE_SPEED+pid_out<L_MIN_SPEED) duty_A<=L_MIN_SPEED;
								else duty_A<=BASE_SPEED+pid_out;

								if(BASE_SPEED-pid_out>R_MAX_SPEED) duty_B<=R_MAX_SPEED;
								else if(BASE_SPEED-pid_out<R_MIN_SPEED) duty_B<=R_MIN_SPEED;
								else duty_B<=BASE_SPEED-pid_out;
							end
							else begin
								duty_A<=BASE_SPEED; 
								duty_B<=BASE_SPEED;
							end
							if((delay_counter > FALSE_TWO_DELAY) || ir_r )begin
							   if (ir_f && !ir_l)begin
								    state<=LEFT;//left;
									delay_counter <= 0;
								end 
								else if (!ob_rr || !ir_r)begin
									state<=FALSE_RIGHT;//FALSE_RIGHT;
									delay_counter <= 0;
								end
							end
						end 
            end
				else begin
						state<=FORWARD;
					   delay_counter <= 0;
						false_count <= 1;
				end
		  end

        AFTER_NINE : begin
                    delay_counter<=delay_counter+1;
						  if((delay_counter<BEFORE_DELAY_R) && !ir_f) begin // added && !ir_f
                        IN1<=1;IN2<=0;IN3<=1;IN4<=0;
                        duty_A<=SLOW_SPEED; duty_B<=SLOW_SPEED;
                    end
                    else if((delay_counter<TURN_DELAY_R+BEFORE_DELAY_R) ) begin
                        IN1<=1;IN2<=0;IN3<=0;IN4<=1;
                        duty_A<=TURN_SPEED; duty_B<=TURN_SPEED-4;
                    end
                    else if(delay_counter<TURN_DELAY_R+35_000_000+BEFORE_DELAY_R) begin // added && !ir_f
                        IN1<=1;IN2<=0;IN3<=1;IN4<=0;
                        duty_A<=SLOW_SPEED; duty_B<=SLOW_SPEED;
                    end
                    else begin state<=STOP; delay_counter<=0; end
                end
        
		  
		  COPY_RIGHT: begin// all ir becoming 1 its added since an error 
            delay_counter<=delay_counter+1;
            if(delay_counter<COPY_R_DELAY) begin // added && !ir_f //&& dis_f<= 200
						 IN1<=1;IN2<=0;IN3<=0;IN4<=1;
						 duty_A<=TURN_SPEED; duty_B<=TURN_SPEED;
					end
            else begin state<=FORWARD; delay_counter<=0; end
        end
		  //----------------------------------------------end of false states ---------------------

		  
		  
		  
        default: state<=FORWARD;

        endcase
    end
end



endmodule