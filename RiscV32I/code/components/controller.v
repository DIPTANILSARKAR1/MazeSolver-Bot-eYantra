
// controller.v - controller for RISC-V CPU

module controller (
    input [6:0]  op,
    input [2:0]  funct3,
    input        funct7b5,
    input        Zero,
    input        Overflow, MsbOfResult,
    output       [1:0] ResultSrc,
    output       MemWrite,
    output       PCSrc, ALUSrc,
    output       RegWrite, 
    output [1:0] ImmSrc,PCChoose,
    output [3:0] ALUControl,
    output Op5
);

wire [1:0] ALUOp;
wire       Branch;
wire jump;

main_decoder    md (op, ResultSrc, MemWrite, Branch,
                    ALUSrc, RegWrite, Jump, ImmSrc, ALUOp, Op5,PCChoose);

alu_decoder     ad (op[5], funct3, funct7b5, ALUOp, ALUControl);

brnandjump_cntrl bj(funct3,Branch,Jump,Zero,Overflow,MsbOfResult, PCSrc); 


endmodule

