// main_decoder_area_opt.v - area-optimized (preserves I/O & behaviour)
module main_decoder(
    input  [6:0] op,
    input  [2:0] funct3,
    input        Zero,
    input        ALUR31,
    input        unsigned_lt,
    output [1:0] ResultSrc,
    output       MemWrite,
    output       Branch,
    output       ALUSrc,
    output       RegWrite,
    output       Jump,
    output       Jalr,
    output [1:0] ImmSrc,
    output [1:0] ALUOp
);

    // CONTROL BITFIELD LAYOUT:
    // [10] RegWrite
    // [9:8] ImmSrc[1:0]
    // [7] ALUSrc
    // [6] MemWrite
    // [5:4] ResultSrc[1:0]
    // [3:2] ALUOp[1:0]
    // [1] Jump
    // [0] Jalr

    // Small branch decision function (same mapping you had)
    function automatic branch_taken;
        input [2:0] f3;
        input       z;
        input       ar31;
        input       ult;
        begin
            case (f3)
                3'b000: branch_taken = z;
                3'b001: branch_taken = !z;
                3'b101: branch_taken = !ar31;
                3'b100: branch_taken = ar31;
                3'b110: branch_taken = ult;
                3'b111: branch_taken = !ar31;
                default: branch_taken = 1'b0;
            endcase
        end
    endfunction

    // Combinational decoder function (returns the 11-bit control vector).
    function automatic [10:0] decode_controls;
        input [6:0] opcode;
        begin
            casez (opcode)
                7'b0000011: decode_controls = 11'b1_00_1_0_01_00_0_0; // lw
                7'b0100011: decode_controls = 11'b0_01_1_1_00_00_0_0; // sw
                7'b0110011: decode_controls = 11'b1_xx_0_0_00_10_0_0; // R-type
                7'b1100011: decode_controls = 11'b0_10_0_0_00_01_0_0; // branch base
                7'b0010011: decode_controls = 11'b1_00_1_0_00_10_0_0; // I-type ALU
                7'b1101111: decode_controls = 11'b1_11_0_0_10_00_1_0; // jal
                7'b1100111: decode_controls = 11'b1_00_1_0_10_00_0_1; // jalr
                7'b0?10111: decode_controls = 11'b1_xx_x_0_11_xx_0_0; // lui or auipc
                default:    decode_controls = 11'b0_00_0_0_00_00_0_0; // deterministic default (synth-friendly)
            endcase
        end
    endfunction

    // decode once into a wire so synthesis can optimize boolean expressions
    wire [10:0] controls = decode_controls(op);

    // Branch is true only for branch-opcode and based on the branch conditions
    wire is_branch_op = (op == 7'b1100011);
    assign Branch = is_branch_op ? branch_taken(funct3, Zero, ALUR31, unsigned_lt) : 1'b0;

    // Slice control vector into outputs (these are simple wires)
    assign RegWrite  = controls[10];
    assign ImmSrc    = controls[9:8];
    assign ALUSrc    = controls[7];
    assign MemWrite  = controls[6];
    assign ResultSrc = controls[5:4];
    assign ALUOp     = controls[3:2];
    assign Jump      = controls[1];
    assign Jalr      = controls[0];

endmodule
