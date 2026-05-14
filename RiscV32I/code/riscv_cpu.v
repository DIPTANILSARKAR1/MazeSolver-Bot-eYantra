
// riscv_cpu.v - single-cycle RISC-V CPU Processor

module riscv_cpu (
    input         clk, reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result
);

wire        ALUSrc, RegWrite, Jump, Zero;
wire [1:0]  ResultSrc, ImmSrc,PCChoose;
wire [3:0]  ALUControl;
wire Op5;

controller  c   (Instr[6:0], Instr[14:12], Instr[30], Zero, Overflow, Mem_WrAddr[31],
                ResultSrc, MemWrite, PCSrc, ALUSrc, RegWrite,
                ImmSrc,PCChoose, ALUControl, Op5);

datapath    dp  (clk, reset, ResultSrc, PCSrc,
                ALUSrc, RegWrite, ImmSrc,PCChoose, ALUControl, Op5,
                Zero,Overflow, PC, Instr, Mem_WrAddr, Mem_WrData, ReadData, Result);

endmodule

