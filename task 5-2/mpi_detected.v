module mpi_detection(
		input clk_50M,
		input reset,
		input ir_l,
		input ir_f,
		input ir_r,
		output mpi_detected
);

    wire ob_l, ob_r, ob_f;

    ir_sensor ir_left (
        .ir_in   (ir_l),
        .clk     (clk_50M),
        .reset   (reset),
        .obstacle(ob_l)
    );

    ir_sensor ir_right (
        .ir_in   (ir_r),
        .clk     (clk_50M),
        .reset   (reset),
        .obstacle(ob_r)
    );

    ir_sensor ir_front(
        .ir_in   (ir_f),
        .clk     (clk_50M),
        .reset   (reset),
        .obstacle(ob_f)
    );
	 
	 assign mpi_detected = (ob_l && ob_r && ob_f);

endmodule 