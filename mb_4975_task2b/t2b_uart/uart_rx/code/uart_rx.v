module uart_rx(
    input clk_3125,
    input rx,
    output reg [7:0] rx_msg,
    output reg rx_parity,
    output reg rx_complete
);

initial begin
    rx_msg = 8'b0;
    rx_parity = 1'b0;
    rx_complete = 1'b0;
end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE//////////////////

localparam ST_IDLE   = 3'd0;
localparam ST_START  = 3'd1;
localparam ST_DATA   = 3'd2;
localparam ST_PARITY = 3'd3;
localparam ST_STOP   = 3'd4;

localparam integer TICKS_FULL = 27;
localparam integer TICKS_HALF = 13;

reg [2:0] state = ST_IDLE;
reg [5:0] clk_count = 0;      // no reset needed in IDLE
reg [2:0] bit_idx = 7;        // set only on start
reg [7:0] data_buf = 8'd0;    // fully overwritten in ST_DATA
reg parity_bit = 1'b0;        // overwritten in ST_PARITY
reg [1:0] rx_sync = 2'b11;

reg first_packet_done = 0;

always @(posedge clk_3125)
    rx_sync <= {rx_sync[0], rx};

always @(posedge clk_3125) begin
    rx_complete <= 1'b0;

    case (state)

        // ---------------------------------------------------------
        ST_IDLE: begin
            if (rx_sync == 2'b10) begin
                bit_idx   <= 7;
                clk_count <= TICKS_HALF + 11;
                state     <= ST_START;
            end
        end

        // ---------------------------------------------------------
        ST_START:
            if (clk_count != 0)
                clk_count <= clk_count - 1;
            else begin
                clk_count <= TICKS_FULL - 1;
                state <= ST_DATA;
            end

        // ---------------------------------------------------------
        ST_DATA: begin
            if (clk_count == TICKS_HALF)
                data_buf[bit_idx] <= rx_sync[1];

            if (clk_count != 0)
                clk_count <= clk_count - 1;
            else begin
                clk_count <= TICKS_FULL - 1;

                if (bit_idx == 0)
                    state <= ST_PARITY;
                else
                    bit_idx <= bit_idx - 1;
            end
        end

        // ---------------------------------------------------------
        ST_PARITY: begin
            if (clk_count == TICKS_HALF)
                parity_bit <= rx_sync[1];

            if (clk_count != 0)
                clk_count <= clk_count - 1;
            else begin
                clk_count <= first_packet_done ? (TICKS_FULL - 1) : TICKS_FULL;
                state <= ST_STOP;
            end
        end

        // ---------------------------------------------------------
        ST_STOP: begin
            if (clk_count != 0)
                clk_count <= clk_count - 1;
            else begin
                rx_msg      <= (parity_bit == (^data_buf)) ? data_buf : 8'h3F;
                rx_parity   <= parity_bit;
                rx_complete <= 1'b1;

                first_packet_done <= 1'b1;

                state <= ST_IDLE;
            end
        end

        default: state <= ST_IDLE;

    endcase
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE//////////////////

endmodule
