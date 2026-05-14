module t2c_maze_explorer (
    input clk,
    input rst_n,          // active-low reset
    input left, mid, right,  // 0 - no wall, 1 - wall
    output reg [2:0] move
);

/*
| cmd | move  | meaning   |
|-----|-------|-----------|
| 000 | 0     | STOP      |
| 001 | 1     | FORWARD   |
| 010 | 2     | LEFT      |
| 011 | 3     | RIGHT     |
| 100 | 4     | U_TURN    |

START POS   : 4,0
EXIT POS    : 4,8
DEADENDS    : 9
*/

////////////////// DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

parameter START = 2'b00, MOVE=2'b01 ,AT_END=2'b10 ,RIGHT_HAND_RULE=2'b11; //state parameter
parameter STOP = 3'b000, FORWARD = 3'b001 , LEFT = 3'b010, RIGHT = 3'b011, U_TURN = 3'b100 ; //move parameter
parameter START_X = 5'd4, START_Y = 5'd0;
parameter END_X = 5'd4, END_Y = 5'd8;
parameter N = 2'b00 ,  E = 2'b01 , S = 2'b10 , W = 2'b11;
parameter DEAD_COUNTS = 4'd9;
parameter SUR_DEAD_COUNTS = 4'd10;
parameter SUR_END_X = 5'd4, SUR_END_Y = 5'd8;

reg [1:0] state;
reg surprize;//for surprize maze ;
reg [4:0] pos_x , pos_y; // store current position 
reg [3:0] dead_counts; 
reg [3:0] dead_ends;// dead ends counts
reg [1:0] facing;
reg [3:0] move_cntr;

reg [1:0] hold_first_five[0:4];

//hold checkig
//reg [1:0] hold_check;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state <= START ; //00
        move  <= STOP ; //000
        pos_x <= START_X; //4
        pos_y <= START_Y; //0
        facing <= N ;//north facing initially
        dead_counts <= 0;
        move_cntr <= 0;
        dead_ends <= SUR_DEAD_COUNTS;

        surprize <= 1'b0;

        //initiallizing
        hold_first_five[0] <= 2'b00;
        hold_first_five[1] <= 2'b00;
        hold_first_five[2] <= 2'b00;
        hold_first_five[3] <= 2'b00;
        hold_first_five[4] <= 2'b00;
    end
    else begin
        case(state)
            START : begin
                    // left=00, 01 forward, 11uturn ,10 right 
                    // if(move_cntr<8)begin
                    //     move_cntr <= move_cntr + 1'b1;
                    // end
                    if(move_cntr >= 5 && 
                        hold_first_five[0]==2'b01 &&
                        hold_first_five[1]==2'b00 &&
                        hold_first_five[2]==2'b00 &&
                        hold_first_five[3]==2'b10 &&
                        hold_first_five[4]==2'b01 
                    )begin
                         dead_ends <= DEAD_COUNTS;
                    end
                    else if (move_cntr >= 5 && 
                        (hold_first_five[0]!=2'b01 ||
                        hold_first_five[1]!=2'b00 ||
                        hold_first_five[2]!=2'b00 ||
                        hold_first_five[3]!=2'b10 ||
                        hold_first_five[4]!=2'b01) 
                    )begin
                        surprize <= 1'b1;
                    end
                
                    if(surprize == 1'b0)begin
                        if(!(pos_x == END_X && pos_y == END_Y) && dead_counts != dead_ends)begin
                            state <= MOVE ; 
                        end

                        else if((pos_x == END_X && pos_y == END_Y) && dead_counts != dead_ends)  begin
                            state <= AT_END;
                        end 

                        else if((pos_x == END_X && pos_y == END_Y) && dead_counts == dead_ends)begin
                            move <= FORWARD ;
                            state <= START;
                        end

                        else if(dead_counts == dead_ends) begin
                            state <= RIGHT_HAND_RULE ; 
                        end
                    end
                    else if (surprize == 1'b1)begin
                        if(!(pos_x == END_X && pos_y == END_Y ) && dead_counts != dead_ends)begin
                            state <= RIGHT_HAND_RULE ; 
                        end
                        else if((pos_x == END_X && pos_y == END_Y) && dead_counts != dead_ends)  begin
                            state <= AT_END;
                        end 
                        else if(dead_counts == dead_ends) begin
                            state <= MOVE ; 
                        end
                    end

            end

            MOVE  : begin
                    //LEFT_TURN
                    if(!left)begin // left wall pelam
                        if (move_cntr<=4) begin
                            move_cntr <= move_cntr + 1'b1;
                            hold_first_five[move_cntr] <= 2'b00;
                            //hold_check <=2'b00;
                        end
                        move <= LEFT;
                        state <= START; 

                        // change in direction and position update
                        case(facing)
                            N:  begin facing <= W; pos_x <= pos_x -1'b1; end
                            E:  begin facing <= N; pos_y <= pos_y + 1'b1; end
                            S:  begin facing <= E; pos_x <= pos_x + 1'b1; end
                            W:  begin facing <= S; pos_y <= pos_y - 1'b1; end
                        endcase 
                    end

                    //FORWARD
                    else if (left && !mid)begin // forward_turn
                        if (move_cntr<=4) begin
                            move_cntr <= move_cntr + 1'b1;
                            hold_first_five[move_cntr] <= 2'b01;
                            //hold_check <=2'b01;
                        end
                        move <= FORWARD;
                        state <= START;

                        // change in direction and position update
                        case(facing)
                            N:  begin facing <= N; pos_y <= pos_y + 1'b1; end
                            E:  begin facing <= E; pos_x <= pos_x + 1'b1; end
                            S:  begin facing <= S; pos_y <= pos_y - 1'b1; end
                            W:  begin facing <= W; pos_x <= pos_x - 1'b1; end
                        endcase 
                    end

                    // right_turn
                    else if (left && mid && !right)begin 
                        if (move_cntr<=4) begin
                            move_cntr <= move_cntr + 1'b1;
                            hold_first_five[move_cntr] <= 2'b10;
                            //hold_check <=2'b10;
                        end
                        move <= RIGHT;
                        state <= START;

                        // change in direction and position update //right 
                        case(facing)
                            N:  begin facing <= E; pos_x <= pos_x + 1'b1; end
                            E:  begin facing <= S; pos_y <= pos_y - 1'b1; end
                            S:  begin facing <= W; pos_x <= pos_x - 1'b1; end
                            W:  begin facing <= N; pos_y <= pos_y + 1'b1; end
                        endcase 
                    end


                    else if (left && mid && right)begin // u_turn
                        if (move_cntr<=4) begin
                            move_cntr <= move_cntr + 1'b1;
                            hold_first_five[move_cntr ] <= 2'b11;
                            //hold_check <=2'b11;
                        end
                        move <= U_TURN;
                        state <= START;
                        if(surprize==0)begin
                            dead_counts <= dead_counts + 1'b1;
                        end

                        // change in direction and position update
                        case(facing)
                            N:  begin facing <= S; pos_y <= pos_y - 1'b1; end
                            E:  begin facing <= W; pos_x <= pos_x - 1'b1; end
                            S:  begin facing <= N; pos_y <= pos_y + 1'b1; end
                            W:  begin facing <= E; pos_x <= pos_x + 1'b1; end
                        endcase 
                    end


                    else begin
                        state <= START;
                        move <= STOP;
                        facing <= N;
                    end
            end 
            
            //not visited all dead ends then only 
            AT_END:begin

                    //right facing logic
                    if (surprize==0)begin
                        case(facing)
                            N:  begin 
                                    if (!mid && !right) begin
                                        move <= RIGHT; state <= START; facing <= E; pos_x <= pos_x + 1'b1;
                                    end
                                    else if(!mid) begin
                                        move <= U_TURN; state <= START; facing <= S; pos_y <= pos_y - 1'b1;
                                    end
                                end
                            E: begin
                                    if (!left && !mid) begin
                                        move <= FORWARD; state <= START; facing <= E; pos_x <= pos_x + 1'b1;
                                    end
                                    else if (!left && !right) begin
                                        move <= RIGHT; state <= START; facing <= S; pos_y <= pos_y - 1'b1;
                                    end
                                end
                            S: begin move <= FORWARD; state <= START; facing <= S; pos_y <= pos_y - 1'b1; end
                            W: begin
                                    if (!left && !mid) begin
                                        move <= LEFT; state <= START; facing <= S; pos_y <= pos_y - 1'b1;
                                    end
                                    else if (!left && !right)begin
                                        move <= LEFT; state <= START; facing <= S; pos_y <= pos_y - 1'b1;
                                    end
                                end
                        endcase
                    end
                    else if(surprize == 1)begin
                        case(facing)
                            N: begin
                                if(!right) begin
                                    move <= RIGHT; pos_x <= pos_x + 1'b1 ; facing <= E; state <= START;
                                end
                                else if(!left) begin
                                    move <= LEFT; state <= START; facing <= W; pos_x <= pos_x - 1'b1;
                                end
                                else begin 
                                    move <= U_TURN; state <= START; facing <= S; pos_y <= pos_y - 1'b1;
                                end
                            end
                            E: begin
                                if(!right) begin
                                    move <= RIGHT; state <= START; facing <= S; pos_y <= pos_y - 1'b1 ;
                                end
                                else if (!mid)begin
                                    move <= FORWARD; state <= START; facing <= E; pos_x <= pos_x + 1'b1;
                                end
                            end
                            W: begin
                                if(!mid)begin
                                    move <= FORWARD; state <= START; facing <= W; pos_x <= pos_x - 1'b1;
                                end
                                else if(!left)begin
                                    move <= LEFT; state <= START; facing <= S; pos_y <= pos_y - 1'b1;
                                end
                            end

                        endcase
                    end
                end
               
            //for backtracking the exit position
            RIGHT_HAND_RULE:begin
                if(!right)begin // left wall pelam
                        move <= RIGHT;
                        state <= START; 

                        // change in direction and position update
                        case(facing)
                            N:  begin   facing <= E; pos_x <= pos_x + 1'b1; end
                            E:  begin   facing <= S; pos_y <= pos_y - 1'b1; end
                            S:  begin   facing <= W; pos_x <= pos_x - 1'b1; end
                            W:  begin   facing <= N; pos_y <= pos_y + 1'b1; end
                        endcase 
                    end

                //rhl FORWARD
                else if (right && !mid)begin // forward_turn
                        move <= FORWARD;
                        state <= START;

                        // change in direction and position update
                        case(facing)
                            N:  begin   facing <= N; pos_y <= pos_y + 1'b1; end
                            E:  begin   facing <= E; pos_x <= pos_x + 1'b1; end
                            S:  begin   facing <= S; pos_y <= pos_y - 1'b1; end
                            W:  begin   facing <= W; pos_x <= pos_x - 1'b1; end
                        endcase 
                    end

                else if(right && mid && !left)begin // left wall pelam
                        move <= LEFT;
                        state <= START; 

                        // change in direction and position update
                        case(facing)
                            N:  begin   facing <= W; pos_x <= pos_x - 1'b1; end
                            E:  begin   facing <= N; pos_y <= pos_y + 1'b1; end
                            S:  begin   facing <= E; pos_x <= pos_x + 1'b1; end
                            W:  begin   facing <= S; pos_y <= pos_y - 1'b1; end
                        endcase 
                    end

                else if (left && mid && right)begin // u_turn
                        move <= U_TURN;
                        state <= START;
                        if (surprize == 1) begin
                            dead_counts <= dead_counts + 1'b1;
                        end

                        // change in direction and position update
                        case(facing)
                            N:  begin facing <= S; pos_y <= pos_y - 1'b1;   end
                            E:  begin facing <= W; pos_x <= pos_x - 1'b1;   end
                            S:  begin facing <= N; pos_y <= pos_y + 1'b1;   end
                            W:  begin facing <= E; pos_x <= pos_x + 1'b1;   end
                        endcase 
                    end
                
                else begin
                        state <= START;
                        move <= STOP;
                        facing <= N;
                    end

                
            end
        endcase
    end
end

    

////////////////// DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule
