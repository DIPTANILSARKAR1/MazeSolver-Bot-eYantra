// module declaration
module uart_tx(
    input clk_3125,
    input parity_type,tx_start,
    input [7:0] data,
    output reg tx, tx_done
);

initial begin
    tx = 1'b1;
    tx_done = 1'b0;
end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE//////////////////

  /* Add your logic here */

  // Calculate the number of clock cycles per bit
  // 3,125,000 Hz / 115,200 bps = 27.126
  // We round to the nearest integer.
  localparam CLKS_PER_BIT = 27;

  // FSM States
  localparam S_IDLE       = 4'b0000;
  localparam S_START      = 4'b0001; // Send Start Bit (0)
  localparam S_DATA       = 4'b0010; // Send 8 Data Bits
  localparam S_PARITY     = 4'b0011; // Send Parity Bit
  localparam S_STOP       = 4'b0100; // Send Stop Bit (1)
  localparam S_DONE       = 4'b0101; // Pulse tx_done high

  // Internal registers for the FSM
  // State register size increased to 4 bits for new state
  reg [3:0] state_reg = S_IDLE;
 
  // Register to count clock ticks for one bit-time
  // Needs to count up to 26 (for CLKS_PER_BIT-1), so 5 bits (0-31)
  reg [4:0] clk_counter = 0;

  // Register to count which data bit we are sending (7 down to 0)
  reg [2:0] bit_index = 0;

  // Registers to store the data and parity at the start of transmission
  reg [7:0] data_reg;
  reg       parity_bit_reg;

 
  // Main FSM logic
  always @(posedge clk_3125)
  begin
      case (state_reg)
         
         S_IDLE:
begin
    tx_done <= 1'b0;

    if (tx_start == 1'b1) begin
        // Start signal is high, begin transmission
        tx <= 1'b0; // Send Start Bit immediately

        // Latch the data and calculate the parity bit
        data_reg <= data;
        parity_bit_reg <= (^data) ^ parity_type;

        clk_counter <= 1; // <-- FIX #1: Start counter at 1, not 0
        bit_index   <= 7;
        state_reg   <= S_START;
    end
    else begin
        tx <= 1'b1; // Idle high
        state_reg <= S_IDLE;
    end
end

          S_START: // Hold the Start Bit for one bit-time
          begin
              if (clk_counter < (CLKS_PER_BIT - 1)) begin
                  clk_counter <= clk_counter + 1;
                  state_reg   <= S_START;
              end
              else begin
                  clk_counter <= 0;
                  state_reg   <= S_DATA; // Move to sending data
              end
          end
         
          S_DATA: // Send the 8 data bits, MSB first
          begin
              tx <= data_reg[bit_index]; // Send current bit (starts at 7)
             
              if (clk_counter < (CLKS_PER_BIT - 1)) begin
                  // Hold this bit for the full bit-time
                  clk_counter <= clk_counter + 1;
                  state_reg   <= S_DATA;
              end
              else begin
                  // Finished with this bit
                  clk_counter <= 0;
                 
                  if (bit_index > 0) begin // <-- FIX #2: Check if bit_index is greater than 0
                      // Move to the next bit
                      bit_index <= bit_index - 1; // <-- FIX #2: Count down
                      state_reg <= S_DATA;
                  end
                  else begin
                      // All 8 data bits sent, move to parity
                      bit_index <= 0; // Reset for next time
                      state_reg <= S_PARITY;
                  end
              end
          end
         
          S_PARITY: // Send the calculated parity bit
          begin
              tx <= parity_bit_reg;
             
              if (clk_counter < (CLKS_PER_BIT - 1)) begin
                  // Hold this bit for the full bit-time
                  clk_counter <= clk_counter + 1;
                  state_reg   <= S_PARITY;
              end
              else begin
                  // Finished with parity bit
                  clk_counter <= 0;
                  state_reg   <= S_STOP; // Move to send stop bit
              end
          end

         S_STOP: // Send the Stop Bit
begin
    tx <= 1'b1; // Stop bit is high

    if (clk_counter < (CLKS_PER_BIT - 1)) begin
        clk_counter <= clk_counter + 1;
        state_reg   <= S_STOP;
    end
    else begin
        // Finished with stop bit, assert tx_done immediately
        clk_counter <= 0;
        tx_done     <= 1'b1;   // <-- FIX: Assert done right here
        state_reg   <= S_IDLE; // <-- Go directly to IDLE
    end
end

         
          // New state to create a one-cycle done pulse
          S_DONE:
          begin
              tx_done   <= 1'b1; // Assert tx_done
              state_reg <= S_IDLE; // Go back to IDLE on the next clock
          end
         
          default:
          begin
              tx        <= 1'b1;
              tx_done   <= 1'b0;
              state_reg <= S_IDLE;
          end
         
      endcase
  end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE//////////////////

endmodule