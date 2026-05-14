module uart_tx(
    input clk_3125,
    input parity_type, tx_start,
    input [7:0] data,
    output reg tx, tx_done
);


parameter s0 = 3'b000 , s1 = 3'b001 , s2 = 3'b010 , s3 = 3'b011 , s4 = 3'b100;

reg [4:0] bit_cnt = 0;  
reg [2:0] bit_idx = 0;   
reg [2:0] state   = s0;

initial begin
    tx = 1'b1;
    tx_done = 1'b0;
end


always @(posedge clk_3125) begin
    tx_done <= 0; 
    case (state)
        s0: begin
            tx <= 1;
             
            bit_idx <= 0;
				bit_cnt <= 1;
            if (tx_start) begin
                tx <= 0;              
                state <= s1;
            end
        end

        s1, s2, s3, s4: begin
            bit_cnt <= bit_cnt + 1;
            if (bit_cnt == 26) begin
                bit_cnt <= 0;
                case (state)
                    s1:   begin state <= s2;   bit_idx <= 0;  end
                    s2:   if (bit_idx == 7) state <= s3;
                          else bit_idx <= bit_idx + 1;
                    s3:   state <= s4;
                    s4:   begin state <= s0; tx_done <= 1; end
                endcase
            end

            case (state)
                s1:   tx <= 0;
                s2:   tx <= data[ bit_idx]; 
                s3:   tx <= (^data ^ parity_type);
                s4:   tx <= 1;
            endcase
        end
    endcase
end

endmodule

