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

parameter START = 2'b00, MOVE = 2'b01, AT_END = 2'b10, RIGHT_HAND_RULE = 2'b11;
parameter STOP = 3'b000, FORWARD = 3'b001, LEFT = 3'b010, RIGHT = 3'b011, U_TURN = 3'b100;
parameter START_X = 5'd4, START_Y = 5'd0;
parameter END_X = 5'd4, END_Y = 5'd8;
parameter N = 2'b00, E = 2'b01, S = 2'b10, W = 2'b11;

reg [1:0] state;
reg [4:0] pos_x, pos_y;
reg [1:0] facing;
reg path_mem [0:8][0:8];
reg [6:0] cell_visited_count;
integer i, j;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= START;
        move <= STOP;
        pos_x <= START_X;
        pos_y <= START_Y;
        facing <= N;
        cell_visited_count <= 7'b0;
        for (i = 0; i <= 8; i = i + 1)
            for (j = 0; j <= 8; j = j + 1)
                path_mem[i][j] = 1'b0;
    end
    else begin
        case (state)
            START: begin
                if (path_mem[pos_x][pos_y] == 1'b0 && pos_x <= 8 && pos_y <= 8) begin
                    path_mem[pos_x][pos_y] <= 1'b1;
                    cell_visited_count <= cell_visited_count + 1'b1;
                end
                if (cell_visited_count !== 81 && pos_x == END_X && pos_y == END_Y)
                    state <= AT_END;
                else if (cell_visited_count == 81)
                    state <= MOVE;
                else
                    state <= RIGHT_HAND_RULE;
            end

            MOVE: begin
                if (!left) begin
                    move <= LEFT;
                    state <= START;
                    case (facing)
                        N: begin facing <= W; pos_x <= pos_x - 1'b1; end
                        E: begin facing <= N; pos_y <= pos_y + 1'b1; end
                        S: begin facing <= E; pos_x <= pos_x + 1'b1; end
                        W: begin facing <= S; pos_y <= pos_y - 1'b1; end
                    endcase
                end
                else if (left && !mid) begin
                    move <= FORWARD;
                    state <= START;
                    case (facing)
                        N: begin pos_y <= pos_y + 1'b1; end
                        E: begin pos_x <= pos_x + 1'b1; end
                        S: begin pos_y <= pos_y - 1'b1; end
                        W: begin pos_x <= pos_x - 1'b1; end
                    endcase
                end
                else if (left && mid && !right) begin
                    move <= RIGHT;
                    state <= START;
                    case (facing)
                        N: begin facing <= E; pos_x <= pos_x + 1'b1; end
                        E: begin facing <= S; pos_y <= pos_y - 1'b1; end
                        S: begin facing <= W; pos_x <= pos_x - 1'b1; end
                        W: begin facing <= N; pos_y <= pos_y + 1'b1; end
                    endcase
                end
                else if (left && mid && right) begin
                    move <= U_TURN;
                    state <= START;
                    case (facing)
                        N: begin facing <= S; pos_y <= pos_y - 1'b1; end
                        E: begin facing <= W; pos_x <= pos_x - 1'b1; end
                        S: begin facing <= N; pos_y <= pos_y + 1'b1; end
                        W: begin facing <= E; pos_x <= pos_x + 1'b1; end
                    endcase
                end
            end

            AT_END: begin
                case (facing)
                    N: begin
                        // if (!left) begin
                        //     move <= LEFT; state <= START;
                        //     facing <= W; pos_x <= pos_x - 1'b1;
                        // end
                        // else if (left && !right) begin
                        //     move <= RIGHT; state <= START;
                        //     facing <= E; pos_x <= pos_x + 1'b1;
                        // end
                        // else if (left && right) begin
                        //     move <= U_TURN; state <= START;
                        //     facing <= S; pos_y <= pos_y - 1'b1;
                        // end

                        if(!right)begin
                            move <= RIGHT; state <= START;
                            facing <= E; pos_x <= pos_x + 1'b1;
                        end
                        else if (!left)begin
                            move <= LEFT; state <= START;
                            facing <= W; pos_x <= pos_x - 1'b1;
                        end
                        else begin
                            move <= U_TURN; state <= START;
                            facing <= S; pos_y <= pos_y - 1'b1;
                        end
                    end

                    E: begin
                        // if (!mid) begin
                        //     move <= FORWARD; state <= START; 
                        //     facing <= E;
                        //     pos_x <= pos_x + 1'b1;
                        // end
                        // else if (mid && !right) begin
                        //     move <= RIGHT; state <= START;
                        //     facing <= S; pos_y <= pos_y - 1'b1;
                        // end
                        // else if(mid && right)begin
                        //     move <= U_TURN; state <= START;
                        //     facing <= W; pos_x <= pos_x - 1'b1;
                        // end
                        if(!right)begin
                            move <= RIGHT; state <= START;
                            facing <= S; pos_y <= pos_y - 1'b1;
                        end
                        else if(!mid)begin
                            move <= FORWARD; state <= START; 
                            facing <= E; pos_x <= pos_x + 1'b1;
                        end
                        else begin
                            move <= U_TURN; state <= START;
                            facing <= W; pos_x <= pos_x - 1'b1;
                        end
                    end
                    S: begin
                        if (!left) begin
                            move <= LEFT; state <= START;
                            facing <= E; pos_x <= pos_x + 1'b1;
                        end
                        else if (left && !mid) begin
                            move <= FORWARD; state <= START;
                            facing <= S; pos_y <= pos_y - 1'b1;
                        end
                        else if (left && mid && !right) begin
                            move <= RIGHT; state <= START;
                            facing <= W; pos_x <= pos_x - 1'b1;
                        end
                    end
                    W: begin
                        // if (!left) begin
                        //     move <= LEFT; state <= START;
                        //     facing <= S; pos_y <= pos_y - 1'b1;
                        // end
                        // else if(left && !mid)begin
                        //     move <= FORWARD; state <= START;
                        //     facing <= W; pos_x <= pos_x - 1'b1;
                        // end
                        // else if (left && mid)begin
                        //     move <= U_TURN ; state<= START;
                        //     facing <= E; pos_x <= pos_x + 1'b1;
                        // end
                        if(!mid)begin
                            move <= FORWARD; state <= START;
                            facing <= W; pos_x <= pos_x - 1'b1;
                        end
                        else if (!left)begin
                            move <= LEFT; state <= START;
                            facing <= S; pos_y <= pos_y - 1'b1;
                        end
                        else begin
                            move <= U_TURN ; state<= START;
                            facing <= E; pos_x <= pos_x + 1'b1;
                        end
                    end
                endcase
            end

            RIGHT_HAND_RULE: begin
                if (!right) begin
                    move <= RIGHT; state <= START;
                    case (facing)
                        N: begin facing <= E; pos_x <= pos_x + 1'b1; end
                        E: begin facing <= S; pos_y <= pos_y - 1'b1; end
                        S: begin facing <= W; pos_x <= pos_x - 1'b1; end
                        W: begin facing <= N; pos_y <= pos_y + 1'b1; end
                    endcase
                end
                else if (right && !mid) begin
                    move <= FORWARD; state <= START;
                    case (facing)
                        N: begin pos_y <= pos_y + 1'b1; end
                        E: begin pos_x <= pos_x + 1'b1; end
                        S: begin pos_y <= pos_y - 1'b1; end
                        W: begin pos_x <= pos_x - 1'b1; end
                    endcase
                end
                else if (right && mid && !left) begin
                    move <= LEFT; state <= START;
                    case (facing)
                        N: begin facing <= W; pos_x <= pos_x - 1'b1; end
                        E: begin facing <= N; pos_y <= pos_y + 1'b1; end
                        S: begin facing <= E; pos_x <= pos_x + 1'b1; end
                        W: begin facing <= S; pos_y <= pos_y - 1'b1; end
                    endcase
                end
                else if (left && mid && right) begin
                    move <= U_TURN; state <= START;
                    case (facing)
                        N: begin facing <= S; pos_y <= pos_y - 1'b1; end
                        E: begin facing <= W; pos_x <= pos_x - 1'b1; end
                        S: begin facing <= N; pos_y <= pos_y + 1'b1; end
                        W: begin facing <= E; pos_x <= pos_x + 1'b1; end
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