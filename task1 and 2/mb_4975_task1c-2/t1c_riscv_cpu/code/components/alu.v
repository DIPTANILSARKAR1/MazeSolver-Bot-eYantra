// alu_area_opt.v - area-optimized ALU (preserves inputs/outputs & behaviour)
module alu #(parameter WIDTH = 32) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [3:0]       alu_ctrl,
    output reg [WIDTH-1:0] alu_out,
    output             zero
);

    // ALU operation codes (must match decoder)
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLT  = 4'b0101;
    localparam ALU_SLTU = 4'b0110;
    localparam ALU_SLL  = 4'b0111;
    localparam ALU_SRL  = 4'b1000;
    localparam ALU_SRA  = 4'b1001;

    // For a 32-bit ALU the shift amount width is 5 bits.
    // Using a fixed width avoids extra logic for $clog2 on some toolchains.
    localparam integer SHAMT_WIDTH = 5;
    wire [SHAMT_WIDTH-1:0] shamt = b[SHAMT_WIDTH-1:0];

    // Determine if current operation needs subtraction-style adder (sub/slti/sltu)
    wire op_is_sub_like = (alu_ctrl == ALU_SUB) || (alu_ctrl == ALU_SLT) || (alu_ctrl == ALU_SLTU);

    // Configure operand B and carry_in to make single adder handle add and sub:
    // For add: op_b = b, carry_in = 0  => a + b
    // For sub-like: op_b = ~b, carry_in = 1 => a - b
    wire [WIDTH-1:0] op_b = op_is_sub_like ? ~b : b;
    wire carry_in = op_is_sub_like ? 1'b1 : 1'b0;

    // Perform one WIDTH+1-bit addition so we can obtain carry_out for unsigned compare.
    // Using an extra MSB gives us carry_out (add_res[WIDTH]) and sum (add_res[WIDTH-1:0]).
    wire [WIDTH:0] add_res = {1'b0, a} + {1'b0, op_b} + { {WIDTH{1'b0}}, carry_in };

    wire [WIDTH-1:0] sum_sub_result = add_res[WIDTH-1:0]; // this is a+b or a-b depending on op_is_sub_like
    wire carry_out = add_res[WIDTH];                     // carry_out of the addition (useful for SLTU)

    // Overflow detection for signed subtraction (a - b): overflow = carry_into_msb ^ carry_out
    // We'll compute overflow using MSB sign bits and result sign bit (standard expression)
    wire a_msb = a[WIDTH-1];
    wire b_msb = b[WIDTH-1];
    wire res_msb = sum_sub_result[WIDTH-1];
    // For subtraction case (op_is_sub_like), add_res already corresponds to a-b.
    // Overflow formula (for subtraction): overflow = (a_msb & ~b_msb & ~res_msb) | (~a_msb & b_msb & res_msb)
    wire overflow = (a_msb & ~b_msb & ~res_msb) | (~a_msb & b_msb & res_msb);

    // Signed less-than result: for a-b, signed_lt = res_msb ^ overflow  (two's complement rule)
    wire signed_lt = res_msb ^ overflow;

    // Unsigned less-than result: for a-b, unsigned_lt = ~carry_out (borrow)
    wire unsigned_lt = ~carry_out;

    // Simple combinational logic for other ops (shifts, bitwise)
    wire [WIDTH-1:0] and_r = a & b;
    wire [WIDTH-1:0] or_r  = a | b;
    wire [WIDTH-1:0] xor_r = a ^ b;
    wire [WIDTH-1:0] sll_r = a << shamt;
    wire [WIDTH-1:0] srl_r = a >> shamt;
    wire [WIDTH-1:0] sra_r = $signed(a) >>> shamt;

    // Final output selection: use the single adder's result for ADD/SUB and derive SLT/SLTU
    always @(*) begin
        case (alu_ctrl)
            ALU_ADD:  alu_out = sum_sub_result;         // op_is_sub_like==0 gives a+b
            ALU_SUB:  alu_out = sum_sub_result;         // op_is_sub_like==1 gives a-b
            ALU_AND:  alu_out = and_r;
            ALU_OR:   alu_out = or_r;
            ALU_XOR:  alu_out = xor_r;
            ALU_SLT:  alu_out = {{(WIDTH-1){1'b0}}, signed_lt};  // sign-extended 1/0
            ALU_SLTU: alu_out = {{(WIDTH-1){1'b0}}, unsigned_lt};
            ALU_SLL:  alu_out = sll_r;
            ALU_SRL:  alu_out = srl_r;
            ALU_SRA:  alu_out = sra_r;
            default:  alu_out = {WIDTH{1'bx}}; // keep simulation sentinel
        endcase
    end

    assign zero = (alu_out == {WIDTH{1'b0}});

endmodule
