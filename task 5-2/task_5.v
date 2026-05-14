module task_5 (
    input  wire clk_50M,
    input  wire reset,
    inout  wire DHT_PIN,   // FPGA PIN connected to DHT11
	 
	 //soilmoisture
	input  dout,
    output adc_cs_n,din, 
    output adc_sck,
    
	 //tx && rx
    output  tx,
	 //input  rx,
	 
	 //servo
	output wire SERVO_1,
    output wire SERVO_2,
	 
	 
    //output reg tx_done
	 input  ir_l,
	 input  ir_f,
	 input  ir_r
); 
	 //soilmoiture
    wire [11:0] d_out_ch0;
	 
	 //dht11
	wire [7:0]  temp_int;
	wire [7:0]  hum_int;
	wire [7:0]  temp_dec;
    wire [7:0]  hum_dec;
	wire [7:0]  checksum;
    wire        data_valid;
	 
	 //tx
	 wire [7:0] tx_data;
	 wire tx_done;
	 wire tx_start;
	 wire parity_type;
	 reg uart_tick;
	 reg [31:0] uart_cnt;
	 
	 //clk 3125
	 wire clk_3125k;
	 
	 //rx
	 wire [7:0] rx_msg;
	 wire rx_complete;
	 
	 //mpi detection
	 wire mpi_detected;
	 
	 
	always @(posedge clk_50M) begin
        if (uart_cnt == 24'd50_000_000) begin
            uart_cnt  <= 0;
            uart_tick <= 1'b1;
        end else begin
            uart_cnt  <= uart_cnt + 1;
            uart_tick <= 1'b0;
        end
    end
	 
    //=================CLK DEVIDER==============
	 clk3125 u_clk_div (
        .clk_50M   (clk_50M),
        .reset     (reset),
        .clk_3125k (clk_3125k)
    );
	 
	 
	 //=================DHT 11==============
	 t2a_dht u_dht(
				.clk_50M    (clk_50M),
				.reset      (reset),
				.sensor     (DHT_PIN),
			   .T_integral (temp_int),
				.RH_integral(hum_int),
				.T_decimal  (temp_dec),
				.RH_decimal (hum_dec),
				.Checksum   (checksum),
				.data_valid (data_valid)
    );
   
	 //=================SOIL MOISTURE==============
	moisture_sensor   ms(
            .dout       (dout), 
            .clk50      (clk_50M),
            .adc_cs_n   (adc_cs_n), 
            .din        (din), 
            .adc_sck    (adc_sck),
            .d_out_ch0  (d_out_ch0)  
    );
	 
	 
	 
	 //=================FSM MSG====================
	  uart_msg_fsm msg_fsm (
        .clk_3125       (clk_3125k),
        .reset          (reset),
        .mpi_detected   (uart_tick),
        .T_integral     (temp_int),
        .T_decimal      (temp_dec),
        .RH_integral    (hum_int),
        .RH_decimal     (hum_dec),
        .d_out_ch0      (d_out_ch0),
        .tx_data        (tx_data),
        .tx_start       (tx_start),
        .tx_done        (tx_done)
    );


	 
	 //=================UART TX====================
	 uart_tx     uart(
			.clk_3125     (clk_3125k),
			.parity_type  (parity_type),
			.tx_start     (tx_start),
			//.reset        (reset),
			.data         (tx_data),
			.tx	        (tx),
			.tx_done      (tx_done)
     ); 
	 
	 //uart_rx uart_rx(clk_3125,rx,rx_msg,rx_complete );
	 
	 
	 //mpi_dtection
	 mpi_detection u_mpi_detection (
		  .clk_50M (clk_50M),
		  .reset   (reset),
		  .ir_l    (ir_l),
		  .ir_f    (ir_f),
		  .ir_r    (ir_r),
		  .mpi_detected (mpi_detected)
	 );
	 
	 
	 //servo
	 SERVO u_servo (
		 .clk_50M      (clk_50M),
		 .reset        (reset),
		 .SERVO_1      (SERVO_1),
		 .SERVO_2      (SERVO_2),
		 .mpi_detected (mpi_detected)
    );
	 

endmodule