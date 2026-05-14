module t2a_dht(
    input clk_50M,
    input reset,
    inout sensor,
    output reg [7:0] T_integral,
    output reg [7:0] RH_integral,
    output reg [7:0] T_decimal,
    output reg [7:0] RH_decimal,
    output reg [7:0] Checksum,
    output reg data_valid
);

    initial begin
        T_integral = 0;
        RH_integral = 0;
        T_decimal = 0;
        RH_decimal = 0;
        Checksum = 0;
        data_valid = 0;
    end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////
 
    reg [2:0]  state;
    reg [20:0] counter;
    reg [5:0] bit_index;
    reg [39:0] data_shift;
    //reg [15:0] high_time;


    // Internal tri-state control
    reg sensor_out;
    reg sensor_out_enable;
    assign sensor = sensor_out_enable ? sensor_out : 1'bz;
    wire sensor_in = sensor;

    initial begin
        state = 3'b000;
        sensor_out_enable = 0;
        counter = 0;
        bit_index = 0;
        data_shift = 0;
        //high_time = 0;
    end

/*
Add your logic here
*/

always @(posedge clk_50M )begin
    if (!reset) begin
            state <= 3'b000;
            counter <= 0;
            bit_index <= 0;
            sensor_out_enable <= 0;
            sensor_out <= 0;
            data_valid <= 0;
            data_shift <= 0;
        end
    else begin
            case (state)
        
                3'b000 : begin //18ms // Master pulls down sensor for 18ms
                            counter <= counter + 1'b1;
                            sensor_out_enable <= 1;
                            sensor_out <= 0;
                            if(counter >= 900004)begin
                                state <= 3'b001;
                                counter <= 0;
										  sensor_out <= 1;
                            end
                        end
                
                3'b001 : begin //high // Master pulls up for 40us
                            counter <= counter + 1'b1;
                            if(counter >= 1999 )begin // 40us 
                                state <= 3'b010;
                                counter <= 0;
										  sensor_out_enable <= 0;
										  sensor_out <= 0;
                            end
                        end
                
                3'b010 : begin //80 us low ack // Sensor pulls down for 80us
                            counter <= counter + 1'b1;
                            if(sensor_in == 0)begin
                                if(counter >= 3999)begin
                                    counter <= 0;
                                    state <= 3'b011;
                                end
                                else if (counter >= 5000) begin
                                    counter <= 0;
                                    state <= 3'b000;
												sensor_out_enable <= 1;
                                end
                            end
                        end
                
                3'b011 : begin //80 us high ack // Sensor pulls up for 80us
                            counter <= counter + 1'b1;
                            if(sensor_in == 1)begin
                                if(counter >= 3999)begin
                                    counter <= 0;
                                    state <= 3'b100;
                                    bit_index <= 0;
                                end
                                else if (counter>=5000)begin
                                    counter <= 0;
                                    state <= 3'b000;
                                end
                            end
                        end

                //bit pata kr rha huin isme        
                3'b100 : begin
                            if (bit_index < 40) begin
									     
                                if (sensor_in == 1 && counter == 0)
                                     counter <= 1; // start counting
                                else if (sensor_in == 1)
                                     counter <= counter + 1'b1;

                                else if (sensor_in !== 1 && counter != 0) begin
                                    // Decode bit
                                    if (counter > 2600)begin // >50µs threshold
                                        data_shift <= {data_shift[38:0], 1'b1};
													 counter <= 0;
													 bit_index <= bit_index + 1'b1;
													 end
                                    else begin
                                        data_shift <= {data_shift[38:0], 1'b0};
													 counter <= 0;
                                        bit_index <= bit_index + 1'b1;
													 end											
                                end
                            end 
                            
                            else begin
                                state <= 3'b101;
                            end
                        end
                        //validate 
                3'b101 : begin
					     counter <= counter + 1'b1;
						  if(counter>=2)begin
						         state <= 3'b000;
									counter<=0;
									data_valid <= 1'b0;
                        end
							else if (counter>=1) begin
									RH_integral = data_shift[39:32];
                           RH_decimal  = data_shift[31:24];
                           T_integral  = data_shift[23:16];
                           T_decimal   = data_shift[15:8];
                           Checksum    = data_shift[7:0];

                           if ((RH_integral + RH_decimal + T_integral + T_decimal) == Checksum)
                                data_valid <= 1'b1;
                           else
                                data_valid <= 1'b0;
							end
                end

                default: state <= 3'b000;
            endcase
        end
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////
  
endmodule