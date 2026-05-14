module uart_msg_fsm (
    input  wire clk_3125,
    input  wire reset,
    //dht11
    input  wire mpi_detected,
    input  wire [7:0] T_integral,
    input  wire [7:0] RH_integral,
    input  wire [7:0] T_decimal,
    input  wire [7:0] RH_decimal,

    //soil moisture 
    input  wire [11:0] d_out_ch0,

    //uart_tx
    output reg  [7:0] tx_data,
    output reg  tx_start,
    input  wire tx_done
);

parameter IDLE = 2'b00 , SEND_MPI = 2'b01 , SEND_MM = 2'b10 , SEND_TH = 2'b11;

reg [1:0] state ;
reg [3:0] idx;

/* ---------- ASCII conversion ---------- */
wire [7:0] T_tens = (T_integral / 10) + "0";
wire [7:0] T_ones = (T_integral % 10) + "0";
wire [7:0] T_d1   = (T_decimal  / 10) + "0";
wire [7:0] T_d2   = (T_decimal  % 10) + "0";

wire [7:0] H_tens = (RH_integral / 10) + "0";
wire [7:0] H_ones = (RH_integral % 10) + "0";
wire [7:0] H_d1   = (RH_decimal  / 10) + "0";
wire [7:0] H_d2   = (RH_decimal  % 10) + "0";

/* Soil moisture (0–4095) */
wire [7:0] MM_th  = (d_out_ch0 / 1000) + "0";
wire [7:0] MM_hu  = ((d_out_ch0 / 100) % 10) + "0";
wire [7:0] MM_te  = ((d_out_ch0 / 10)  % 10) + "0";
wire [7:0] MM_on  = (d_out_ch0 % 10) + "0";

always @(posedge clk_3125 or negedge reset) begin
    if (!reset) begin
        tx_start <= 0;
        tx_data  <= 0;
        state    <= IDLE;
        idx      <= 0;
    end else begin
        tx_start <= 0;

        case(state)

            IDLE: begin
                if (mpi_detected) begin
                    state <= SEND_MPI;
                    idx   <= 1;
                end
            end

            /* -------- MPI -------- */
            SEND_MPI: begin
                case(idx)
                    1: begin tx_start <= 1; tx_data <= "M"; end
                    2: begin tx_start <= 1; tx_data <= "P"; end
                    3: begin tx_start <= 1; tx_data <= "I"; end
                    4: begin tx_start <= 1; tx_data <= "_"; end
                    5: begin tx_start <= 1; tx_data <= "_"; end
                    6: begin tx_start <= 1; tx_data <= "_"; end
                    7: begin
                        tx_start <= 1;
                        tx_data  <= "#";
                        state <= SEND_MM;
                        idx <= 1;
                    end
                endcase
                if (tx_done && idx <= 7) idx <= idx + 1;
            end

            /* -------- Soil Moisture -------- */
            SEND_MM: begin
                case(idx)
                    1: begin tx_start <= 1; tx_data <= "M"; end
                    2: begin tx_start <= 1; tx_data <= "M"; end
                    3: begin tx_start <= 1; tx_data <= MM_th; end
                    4: begin tx_start <= 1; tx_data <= MM_hu; end
                    5: begin tx_start <= 1; tx_data <= MM_te; end
                    6: begin tx_start <= 1; tx_data <= MM_on; end
                    7: begin
                        tx_start <= 1;
                        tx_data  <= "#";
                        state <= SEND_TH;
                        idx <= 1;
                    end
                endcase
                if (tx_done && idx <= 7) idx <= idx + 1;
            end

            /* -------- Temperature + Humidity -------- */
            SEND_TH: begin
                case(idx)
                    1:  begin tx_start <= 1; tx_data <= "T"; end
                    2:  begin tx_start <= 1; tx_data <= T_tens; end
                    3:  begin tx_start <= 1; tx_data <= T_ones; end
                    4:  begin tx_start <= 1; tx_data <= "."; end
                    5:  begin tx_start <= 1; tx_data <= T_d1; end
                    6:  begin tx_start <= 1; tx_data <= T_d2; end
                    7:  begin tx_start <= 1; tx_data <= "_"; end
                    8:  begin tx_start <= 1; tx_data <= "H"; end
                    9:  begin tx_start <= 1; tx_data <= H_tens; end
                    10: begin tx_start <= 1; tx_data <= H_ones; end
                    11: begin tx_start <= 1; tx_data <= "."; end
                    12: begin tx_start <= 1; tx_data <= H_d1; end
                    13: begin tx_start <= 1; tx_data <= H_d2; end
                    14: begin
                        tx_start <= 1;
                        tx_data  <= "#";
                        state <= IDLE;
                        idx <= 0;
                    end
                endcase
                if (tx_done && idx <= 14) idx <= idx + 1;
            end

        endcase
    end
end

endmodule