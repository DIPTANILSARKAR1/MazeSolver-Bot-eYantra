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
	 output wire       servo_start,
	 output reg   [3:0]     mpi_count
);

parameter STOP=3'b000,FORWARD=3'b001,LEFT=3'b010,RIGHT=3'b011,
          ALIGN=3'b100,UTURN=3'b101,IR_FORWARD=3'b110,SERVO=3'b111;

parameter BASE_SPEED=25,TURN_SPEED=25,SLOW_SPEED=25;
//parameter L_MAX_SPEED=40,L_MIN_SPEED=15,R_MAX_SPEED=35,R_MIN_SPEED=10;
parameter L_MAX_SPEED=35,L_MIN_SPEED=15,R_MAX_SPEED=35,R_MIN_SPEED=15;

parameter BEFORE_DELAY_L=18_000_000;
parameter TURN_DELAY_L=22_000_000;
parameter AFTER_DELAY_L=17_000_000;
parameter TURN_DELAY_R=18_000_000;
parameter AFTER_DELAY_R=18_000_000;
parameter UTURN_DELAY=38_000_000;
parameter SERVO_DELAY=830_000_000;

parameter KP=8,KD=6; // PID 

reg [5:0] duty_A,duty_B;
pwm_generator pwmA(clk,duty_A,ENA);
pwm_generator pwmB(clk,duty_B,ENB);

reg [2:0] state;
reg servo_req;
reg [31:0] delay_counter;
reg signed [4:0] error,prev_error;
wire signed [5:0] derivative;
wire signed [7:0] pid_out;

assign derivative=error-prev_error;
assign pid_out=(KP*error)+(KD*derivative);

reg ob_ll,ob_ff,ob_rr;
reg [2:0] ir_value;
//reg [3:0] count_mpi;// mpi count

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

always @(posedge clk) begin
    ob_ll <= (dis_l < 160);
    ob_ff <= ( ir_f); // remove us in next run
    ob_rr <= (dis_r < 160);
    ir_value <= {ir_l,ir_f,ir_r};
end


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
    
    else begin error<=0; prev_error<=0; end
end
 always @(posedge clk or negedge reset) begin
    if (!reset)
        End <= 1'b0;
    else
        End <= (state == STOP);
    end
always @(posedge clk or negedge reset) begin
    if(!reset ) begin
        state<=FORWARD; delay_counter<=0;
        duty_A<=0; duty_B<=0;
        IN1<=0;IN2<=0;IN3<=0;IN4<=0;
		  //servo_start<=0;
		  mpi_count <= 0;//count mpi
    end
    else if(!enable)	begin
        state<=FORWARD; delay_counter<=0;
        duty_A<=0; duty_B<=0;
        IN1<=0;IN2<=0;IN3<=0;IN4<=0;
		  //servo_start<=0;
		  mpi_count <= 0;//count mpi
    end

	else begin
        case(state)

        FORWARD: begin
            IN1<=1;IN2<=0;IN3<=1;IN4<=0;
				//servo_start<=0;
				
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
				
				if (ir_l && ob_ll && !ir_r && !ir_f && dis_r>800 && dis_f>800)begin
					state<=STOP;
					delay_counter <= 0;
				end
				else if(ir_l && ir_f && !ob_rr)begin
//					IN1<=0;IN2<=0;IN3<=0;IN4<=1;
//             duty_B<=TURN_SPEED;
//					duty_A <= 0;
					state<=RIGHT;
					delay_counter <= 0;
				end
				else if(ir_r && ir_f && !ob_ll)begin
//					IN1<=0;IN2<=1;IN3<=0;IN4<=0;
//               duty_A<=TURN_SPEED;
//					duty_B<=0;
               state<=LEFT;
					delay_counter <= 0;
				end
				else if (ir_r && ir_f && ir_r && dis_l>300 && dis_r>300 && dis_f<50)begin
					state<=UTURN;
					delay_counter <= 0;
				end
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
//            else if((delay_counter<BEFORE_DELAY_L+TURN_DELAY_L+AFTER_DELAY_L) && !ir_l) begin
//                IN1<=1;IN2<=0;IN3<=1;IN4<=0;
//                duty_A<=SLOW_SPEED; duty_B<=SLOW_SPEED;
//            end
            else begin state<=FORWARD; delay_counter<=0; end
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
//				if(ir_l&&!ir_r) begin
//                IN1<=0;IN2<=0;IN3<=0;IN4<=1;
//                duty_A<=0; duty_B<=15;
//            end
//				else if(!ir_l&&ir_r) begin
//                IN1<=1;IN2<=0;IN3<=0;IN4<=0;
//                duty_A<=15; duty_B<=0;
//            end
            if(mpi_count == 1 || mpi_count == 3 || mpi_count == 4)begin
					if(!servo_stop) begin //&& !servo_stop
						 IN1<=0;IN2<=0;IN3<=0;IN4<=0;
						 duty_A<=0; duty_B<=0;
						 //servo_start<=1;
					end
					else begin state<=UTURN; delay_counter<=0;end
				end
				else begin
				    state<=UTURN; delay_counter<=0;
            end
        end

        UTURN: begin
		      //servo_start<=0;
            delay_counter<=delay_counter+1;
            if((delay_counter<UTURN_DELAY)) begin
                IN1<=1;IN2<=0;IN3<=0;IN4<=1;
                duty_A<=TURN_SPEED; duty_B<=TURN_SPEED;
            end
            else begin state<=FORWARD; delay_counter<=0; end
        end

        STOP: begin
            IN1<=0;IN2<=0;IN3<=0;IN4<=0;
            duty_A<=0; duty_B<=0;
           // if(ob_ff||ob_ll||ob_rr) state<=FORWARD;
        end

        default: state<=FORWARD;

        endcase
    end
end



endmodule