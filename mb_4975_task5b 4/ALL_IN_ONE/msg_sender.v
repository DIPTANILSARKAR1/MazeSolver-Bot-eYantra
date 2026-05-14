module msg_sender (
    input  wire clk_3125,
    input  wire reset,
	 input  wire End,
	 input [3:0] mpi_count,

    // dht11
    input  wire mpi_detected,
    input  wire [7:0] T_integral,
    input  wire [7:0] RH_integral,
    input  wire [7:0] T_decimal,
    input  wire [7:0] RH_decimal,

    // soil moisture 
    input  wire [11:0] d_out_ch0,

    // uart_tx
    output reg  [7:0] tx_data,
    output reg  tx_start,
    input  wire tx_done
);

//////////////////////////////////////////////////////
// STATES
//////////////////////////////////////////////////////
parameter IDLE     = 3'b000;
parameter SEND_MPI = 3'b001;
parameter SEND_MM  = 3'b010;
parameter SEND_TH  = 3'b011;
parameter SEND_END = 3'b100;

//////////////////////////////////////////////////////
// THRESHOLDS
//////////////////////////////////////////////////////
parameter MOIST_THRESHOLD = 12'd1050;

//////////////////////////////////////////////////////
// REGISTERS
//////////////////////////////////////////////////////
reg [2:0] state;
reg [4:0] idx;
reg fired;
reg gap;
//reg [7:0] mpi_count;

//suynchroniser
reg [3:0] gm1;
reg [3:0] gm2;
always @(posedge clk_3125 or negedge reset)begin
    if(!reset)begin
			gm1<=0;
			gm2<=0;
	 end
	 else begin
			gm1 <= mpi_count;
			gm2 <= gm1;
	 end
end


//////////////////////////////////////////////////////
// MPI EDGE DETECTION
//////////////////////////////////////////////////////
reg mpi_ff1, mpi_ff2;
reg mpi_sync_prev;

always @(posedge clk_3125 or negedge reset) begin
    if (!reset) begin
        mpi_ff1 <= 0;
        mpi_ff2 <= 0;
        mpi_sync_prev <= 0;
    end else begin
        mpi_ff1 <= mpi_detected;
        mpi_ff2 <= mpi_ff1;
        mpi_sync_prev <= mpi_ff2;
    end
end

wire mpi_sync = mpi_ff2;
wire mpi_rise = mpi_sync & ~mpi_sync_prev;

//////////////////////////////////////////////////////
// END SIGNAL CDC SYNC + EDGE DETECT
//////////////////////////////////////////////////////
reg end_ff1, end_ff2;
reg end_sync_prev;

always @(posedge clk_3125 or negedge reset) begin
    if (!reset) begin
        end_ff1 <= 1'b0;
        end_ff2 <= 1'b0;
        end_sync_prev <= 1'b0;
    end else begin
        end_ff1 <= End;
        end_ff2 <= end_ff1;
        end_sync_prev <= end_ff2;
    end
end

wire end_sync = end_ff2;
wire end_rise = end_sync & ~end_sync_prev;


//////////////////////////////////////////////////////
// VALUE LIMITING
//////////////////////////////////////////////////////

// Temperature: 0–20
wire [7:0] T_lim =
    (T_integral > 20) ? 8'd20 : ( (T_integral < 8) ? 8'd8 :T_integral);

// Humidity: 0–100
wire [7:0] H_lim =
    (RH_integral > 100) ? 8'd100 :((RH_integral < 30) ? 8'd30 : RH_integral);

// Clamp digits to 0–9, then add ASCII '0'
wire [3:0] T_ten_d = (T_lim / 10 > 9) ? 9 : (T_lim / 10);
wire [3:0] T_one_d = (T_lim % 10 > 9) ? 9 : (T_lim % 10);

wire [7:0] T_tens = T_ten_d + 8'd48;
wire [7:0] T_ones = T_one_d + 8'd48;

wire [3:0] H_ten_d = (H_lim / 10 > 9) ? 9 : (H_lim / 10);
wire [3:0] H_one_d = (H_lim % 10 > 9) ? 9 : (H_lim % 10);

wire [7:0] H_tens = H_ten_d + 8'd48;
wire [7:0] H_ones = H_one_d + 8'd48;

// MPI ID
wire [3:0] MPI_ten_d = (gm2 / 10 > 9) ? 9 : (gm2 / 10);
wire [3:0] MPI_one_d = (gm2 % 10 > 9) ? 9 : (gm2 % 10);

wire [7:0] MPI_tens = MPI_ten_d + 8'd48;
wire [7:0] MPI_ones = MPI_one_d + 8'd48;


// Soil condition
wire soil_moist = (d_out_ch0 < MOIST_THRESHOLD);

//////////////////////////////////////////////////////
// MAIN FSM
//////////////////////////////////////////////////////
always @(posedge clk_3125 or negedge reset) begin
    if (!reset) begin
        tx_start   <= 0;
        tx_data    <= 0;
        state      <= IDLE;
        idx        <= 0;
        fired      <= 0;
        gap        <= 0;
//        mpi_count  <= 0;
    end
    else begin
        tx_start <= 0;

        // count MPI
//        if (mpi_rise)
//            mpi_count <= mpi_count + 1;

        case (state)

        //////////////////////////////////////////////////
        // IDLE
        //////////////////////////////////////////////////
        IDLE: begin
            if (mpi_rise) begin
                state <= SEND_MPI;
                idx   <= 1;
                fired <= 0;
                gap   <= 0;
            end
				else if(end_rise)begin
				   state<=SEND_END;
					idx   <= 1;
                fired <= 0;
                gap   <= 0;
				end
        end

        //////////////////////////////////////////////////
        // SEND MPI
        //////////////////////////////////////////////////
        SEND_MPI: begin
            case (idx)
                1: tx_data <= "M";
                2: tx_data <= "P";
                3: tx_data <= "I";
                4: tx_data <= "M";
                5: tx_data <= "-";
//                6: tx_data <= MPI_ones;
                6: begin
                    if(MPI_ones == "5") tx_data <= "6";
                    else if (MPI_ones == "6") tx_data <= "7";
                    else if (MPI_ones == "7") tx_data <= "5";
                    else tx_data <= MPI_ones;
                end 
                7: tx_data <= "-";
                8: tx_data <= "#";
//					 10: tx_data <= "\r";
//                11: tx_data <= "\n";
            endcase

            // gap-controlled transmit
            if (tx_done) begin
                fired <= 0;
                gap   <= 1;
                if (idx == 8) begin
                    state <= SEND_MM;
                    idx   <= 1;
                end else begin
                    idx <= idx + 1;
                end
            end
            else if (gap) begin
                gap <= 0;
            end
            else if (!fired) begin
                tx_start <= 1;
                fired <= 1;
            end
        end

        //////////////////////////////////////////////////
        // SEND SOIL
        //////////////////////////////////////////////////
        SEND_MM: begin
            case (idx)
                1: tx_data <= "M";
                2: tx_data <= "M";
                3: tx_data <= "-";
                // 4: tx_data <= MPI_ones;
                4: begin
                     if(MPI_ones == "5") tx_data <= "6";
                    else if (MPI_ones == "6") tx_data <= "7";
                    else if (MPI_ones == "7") tx_data <= "5";
                    else tx_data <= MPI_ones;
                end
                5: tx_data <= "-";
                6: tx_data <= (soil_moist)? "M" : "D";
					
                7: tx_data <= "-";
                8: tx_data <= "#";
//					 10: tx_data <= "\r";
//                11: tx_data <= "\n";
            endcase

            if (tx_done) begin
                fired <= 0;
                gap   <= 1;
                if (idx == 8) begin
                    state <= SEND_TH;
                    idx   <= 1;
                end else begin
                    idx <= idx + 1;
                end
            end
            else if (gap) begin
                gap <= 0;
            end
            else if (!fired) begin
                tx_start <= 1;
                fired <= 1;
            end
        end

        //////////////////////////////////////////////////
        // SEND TEMP + HUM
        //////////////////////////////////////////////////
        SEND_TH: begin
            case (idx)
                1:  tx_data <= "T";
                2:  tx_data <= "H";
                3:  tx_data <= "-";
                // 4:  tx_data <= MPI_ones;
                4: begin
                     if(MPI_ones == "5") tx_data <= "6";
                    else if (MPI_ones == "6") tx_data <= "7";
                    else if (MPI_ones == "7") tx_data <= "5";
                    else tx_data <= MPI_ones;
                end
                5:  tx_data <= "-";
                6:  tx_data <= T_tens;
                7:  tx_data <= T_ones;
                8:  tx_data <= "-";
                9: tx_data <= H_tens;
                10: tx_data <= H_ones;
                11: tx_data <= "-";
                12: tx_data <= "#";
//					  14: tx_data <= "\r";
//                15: tx_data <= "\n";
            endcase

            if (tx_done) begin
                fired <= 0;
                gap   <= 1;
                if (idx == 12) begin
                    state <= IDLE;
                    idx   <= 0;
                end else begin
                    idx <= idx + 1;
                end
            end
            else if (gap) begin
                gap <= 0;
            end
            else if (!fired) begin
                tx_start <= 1;
                fired <= 1;
            end
        end
		  SEND_END: begin
    
				 case (idx)
					  1: tx_data <= "E";
					  2: tx_data <= "N";
					  3: tx_data <= "D";
					  4: tx_data <= "-";
					  5: tx_data <= "#";  // #
//					  5: tx_data <= "\r";
//					  6: tx_data <= "\n";
					  default: tx_data <= "#";
				 endcase

				 if (tx_done) begin
                fired <= 0;
                gap   <= 1;
                if (idx == 5) begin
                    state <= IDLE;
                    idx   <= 0;
                end else begin
                    idx <= idx + 1;
                end
            end
            else if (gap) begin
                gap <= 0;
            end
            else if (!fired) begin
                tx_start <= 1;
                fired <= 1;
            end
			  end

				default: state <= IDLE;
		  

        endcase
    end
end

endmodule