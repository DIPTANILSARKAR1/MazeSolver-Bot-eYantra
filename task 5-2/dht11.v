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

    reg [2:0]  state;
    reg [20:0] counter;
    reg [5:0]  bit_index;
    reg [39:0] data_shift;
    reg [15:0] high_time;

    reg sensor_out;
    reg sensor_out_enable;
    reg prev_sensor;

    assign sensor = sensor_out_enable ? sensor_out : 1'bz;
    wire sensor_in = sensor;
	 
	 reg sensor_d;

		always @(posedge clk_50M or negedge reset) begin
			 if (!reset)
				  sensor_d <= 1'b1;
			 else
				  sensor_d <= sensor_in;
		end

		wire rising_edge  = ( sensor_in && !sensor_d );
		wire falling_edge = (!sensor_in &&  sensor_d );


    always @(posedge clk_50M or negedge reset) begin
        if (!reset) begin
            state <= 3'b000;
            counter <= 0;
            bit_index <= 0;
            data_shift <= 0;
            high_time <= 0;
            sensor_out_enable <= 0;
            sensor_out <= 1;
            prev_sensor <= 1;
            data_valid <= 0;
        end else begin
            prev_sensor <= sensor_in;

            case (state)

                3'b000: begin
                    sensor_out_enable <= 1;
                    sensor_out <= 0;
                    counter <= counter + 1;
                    data_valid <= 0;
                    if (counter >= 900_000) begin
                        counter <= 0;
                        sensor_out_enable <= 0;
                        state <= 3'b001;
                    end
                end

                3'b001: begin
                    counter <= counter + 1;
                    if (counter >= 2000) begin
                        counter <= 0;
                        state <= 3'b010;
                    end
                end

                3'b010: begin
                    if (sensor_in == 0)
                        counter <= counter + 1;
                    else
                        counter <= 0;

                    if (counter >= 4000) begin
                        counter <= 0;
                        state <= 3'b011;
                    end
                end

                3'b011: begin
                    if (sensor_in == 1)
                        counter <= counter + 1;
                    else
                        counter <= 0;

                    if (counter >= 4000) begin
                        counter <= 0;
                        bit_index <= 0;
                        data_shift <= 0;
                        state <= 3'b100;
                    end
                end

                3'b100: begin
						 if (bit_index < 40) begin
							  if (rising_edge)
									high_time <= 0;
							  else if (sensor_in)
									high_time <= high_time + 1;
							  else if (falling_edge) begin
									data_shift <= {data_shift[38:0], (high_time > 2000)};
									bit_index  <= bit_index + 1;
									high_time  <= 0;
							  end
						 end else begin
							  state <= 3'b101;
						 end
					end


                3'b101: begin
                    RH_integral <= data_shift[39:32];
                    RH_decimal  <= data_shift[31:24];
                    T_integral  <= data_shift[23:16];
                    T_decimal   <= data_shift[15:8];
                    Checksum    <= data_shift[7:0];

                    if ((data_shift[39:32] + data_shift[31:24] +
                         data_shift[23:16] + data_shift[15:8]) == data_shift[7:0])
                        data_valid <= 1;
                    else
                        data_valid <= 0;

                    state <= 3'b000;
                    counter <= 0;
                end

                default: state <= 3'b000;

            endcase
        end
    end
endmodule
