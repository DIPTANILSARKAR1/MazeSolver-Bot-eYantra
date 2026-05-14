module uart_clk_div (
    input  wire clk_50M,
    output reg  clk_3125
);

    reg [3:0] cnt;

    always @(posedge clk_50M) begin
        cnt <= cnt + 1;
        if (cnt == 4'd7) begin
            cnt <= 0;
            clk_3125 <= ~clk_3125;
        end
    end

endmodule
