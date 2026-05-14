
// alu.v - ALU module

module alu #(parameter WIDTH = 32) (
    input       [WIDTH-1:0] a, b,       // operands
    input       [3:0] alu_ctrl,         // ALU control
    output reg  [WIDTH-1:0] alu_out,    // ALU output
    output      zero,Overflow                    // zero flag
);


always @(a, b, alu_ctrl) begin
    case (alu_ctrl)
        4'b0000:  alu_out <= a + b;       // ADD
        4'b0001:  alu_out <= a + ~b + 1;  // SUB
        4'b0010:  alu_out <= a & b;       // AND
        4'b0011:  alu_out <= a | b;       // OR
        4'b0100:  alu_out <= a << b[4:0]; // added slli 
        4'b0101:  begin                   // added SLTi
                  if (a[31] != b[31]) alu_out <= a[31] ? 1 : 0;
                  else alu_out <= a < b ? 1 : 0;
        end
        4'b0110:  alu_out <= a < b ? 1 : 0; //added sltiu
        4'b0111:  alu_out <= a ^ b ; //added xor
        4'b1000:  alu_out <= a >> b[4:0]; // added srli
        4'b1001: begin //adaded srai
                  alu_out <= (a >> b[4:0]) | ({32{a[31]}} << (32 - b[4:0]));
        end
        default: alu_out = 0;
    endcase
end

assign zero = (alu_out == 0) ? 1'b1 : 1'b0;
assign Overflow =
    (alu_ctrl == 4'b0000) ? // if add
    ((a[WIDTH-1] == b[WIDTH-1]) &&
     (alu_out[WIDTH-1] != a[WIDTH-1])) :

    (alu_ctrl == 4'b0001) ? //
    ((a[WIDTH-1] != b[WIDTH-1]) &&
     (alu_out[WIDTH-1] != a[WIDTH-1])) :

    1'b0;


endmodule

