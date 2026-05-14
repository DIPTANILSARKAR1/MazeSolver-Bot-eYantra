module bot_position(
    input clk,
    input reset,

    input [31:0] count_L,
    input [31:0] count_R,

    input [2:0] turn, // 000 forward, 001-L, 010-R , 011-U ,100-STOP 

    output reg [3:0] x,
    output reg [3:0] y,
    output reg [1:0] dir,
    output reg reached_exit
);

parameter NORTH = 2'b00;
parameter EAST  = 2'b01;
parameter SOUTH = 2'b10;
parameter WEST  = 2'b11;

parameter F=3'b000, L=3'b001 ,R=3'b010, U=3'b011 , S=3'b100;


endmodule
