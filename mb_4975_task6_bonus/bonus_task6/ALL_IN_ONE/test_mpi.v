module test_mpi(
	input clk,
	input ir_l,
	input ir_f,
	input ir_r,
//	output mpi_detected,
	output reg uart_tick
	);
	
	reg [31:0] uart_cnt;
	
	always @(posedge clk) begin
        if (uart_cnt == 24'd50_000_000) begin
            uart_cnt  <= 0;
            uart_tick <= 1'b1;
        end else begin
            uart_cnt  <= uart_cnt + 1;
            uart_tick <= 1'b0;
        end
    end
	 
	 
//	 assign mpi_dtected = ir_l && ir_f && ir_r;
	
	
endmodule