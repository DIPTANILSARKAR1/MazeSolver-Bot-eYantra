// alu_decoder_area_opt.v - area-optimized (same I/O & behaviour)
module alu_decoder (
    input        opb5,
    input  [2:0] funct3,
    input        funct7b5,
    input  [1:0] ALUOp,
    output [3:0] ALUControl
);

    // ALU opcodes (must match decoder)
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

    // precompute small signals so synthesis won't replicate them
    wire sub_flag = funct7b5 & opb5;    // used only for funct3==000
    wire sr_a    = funct7b5;            // used for funct3==101

    // combinational decode: ALUOp priority first, then funct3 decode
    // using nested ternaries / small mux tree lets synthesis minimize logic
    // Default returns ALU_ADD for synthesis-friendly behaviour (see note).
    assign ALUControl =
        (ALUOp == 2'b00) ? ALU_ADD :                 // lw/sw
        (ALUOp == 2'b01) ? ALU_SUB :                 // branch compare
        // ALUOp == 2'b10 (or default decode path)
        (funct3 == 3'b000) ? (sub_flag ? ALU_SUB : ALU_ADD) :
        (funct3 == 3'b001) ? ALU_SLL :
        (funct3 == 3'b010) ? ALU_SLT :
        (funct3 == 3'b011) ? ALU_SLTU :
        (funct3 == 3'b100) ? ALU_XOR :
        (funct3 == 3'b101) ? (sr_a ? ALU_SRA : ALU_SRL) :
        (funct3 == 3'b110) ? ALU_OR :
        (funct3 == 3'b111) ? ALU_AND :
        ALU_ADD; // deterministic default for synthesis

    // If you *must* preserve 'x' as simulation sentinel, use the following
    // (keeps deterministic default for synthesis):
    //
    // synthesis translate_off
    // wire [3:0] ALUControl_sim;
    // assign ALUControl_sim =
    //   (ALUOp == 2'b00) ? ALU_ADD :
    //   (ALUOp == 2'b01) ? ALU_SUB :
    //   (funct3 == 3'b000) ? (sub_flag ? ALU_SUB : ALU_ADD) :
    //   ... // same as above ...
    //   4'bxxxx;
    // assign ALUControl = ALUControl_sim;
    // synthesis translate_on

endmodule
