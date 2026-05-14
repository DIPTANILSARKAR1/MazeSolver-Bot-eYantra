module uart_tx(
    input clk_3125,
    input parity_type, tx_start,
    input [7:0] data,
    output reg tx, tx_done
);

initial begin
    tx = 1'b1;
    tx_done = 1'b0;
end

localparam CLKS_PER_BIT = 27;

localparam S_IDLE   = 3'd0;
localparam S_START  = 3'd1;
localparam S_DATA   = 3'd2;
localparam S_PARITY = 3'd3;
localparam S_STOP   = 3'd4;

reg [3:0] state_reg = S_IDLE;
reg [4:0] clk_counter = 0;
reg [2:0] bit_index = 0;
//reg [7:0] data_reg;
//reg parity_bit_reg;

always @(posedge clk_3125) begin
    case (state_reg)

        S_IDLE: begin
            tx_done <= 1'b0;
            if (tx_start) begin
                tx <= 1'b0;             // start bit
               // data_reg <= data;
                //parity_bit_reg <= (^data) ^ parity_type;
                clk_counter <= 1;
                bit_index <= 7;
                state_reg <= S_START;
            end else begin
                tx <= 1'b1;
            end
        end

        S_START: begin
            if (clk_counter < (CLKS_PER_BIT - 1))
                clk_counter <= clk_counter + 1;
            else begin
                clk_counter <= 0;
                state_reg <= S_DATA;
            end
        end

        S_DATA: begin
            tx <= data[bit_index];

            if (clk_counter < (CLKS_PER_BIT - 1))
                clk_counter <= clk_counter + 1;
            else begin
                clk_counter <= 0;
                if (bit_index > 0)
                    bit_index <= bit_index - 1;
                else
                    state_reg <= S_PARITY;
            end
        end

        S_PARITY: begin
            tx <= (^data) ^ parity_type;

            if (clk_counter < (CLKS_PER_BIT - 1))
                clk_counter <= clk_counter + 1;
            else begin
                clk_counter <= 0;
                state_reg <= S_STOP;
            end
        end

        S_STOP: begin
            tx <= 1'b1;
            if (clk_counter < (CLKS_PER_BIT - 1))
                clk_counter <= clk_counter + 1;
            else begin
                clk_counter <= 0;
                tx_done <= 1'b1;       // one cycle pulse
                state_reg <= S_IDLE;   // DONE state removed
            end
        end
    endcase
end

endmodule
