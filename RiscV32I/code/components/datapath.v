
// datapath.v
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrc,
    input         PCSrc, ALUSrc,
    input         RegWrite,
    input [1:0]   ImmSrc,PCChoose,
    input [3:0]   ALUControl,
    input Op5,
    output        Zero, Overflow,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result
);

wire [31:0] PCNext, PCPlus4, PCTarget,PCPlusImm;
wire [31:0] ImmExt, AUI, UpperExtend, UTypeSel, SrcA, SrcB, WriteData, ALUResult;

// next PC logic
reset_ff #(32) pcreg(clk, reset, PCNext, PC);
adder          pcadd4(PC, 32'd4, PCPlus4);
adder          pcaddbranch(PC, ImmExt, PCPlusImm);
mux2 #(32)     pcmux(PCPlus4, PCTarget, PCSrc, PCNext);
mux3 #(32)     pcjalrandJump(PCPlusImm,ALUResult,ImmExt,PCChoose,PCTarget);

// register file logic
reg_file       rf (clk, RegWrite, Instr[19:15], Instr[24:20], Instr[11:7], Result, SrcA, WriteData);
imm_extend     ext (Instr[31:7], ImmSrc, ImmExt);

//upper imm logic
upper_extend   ext2(Instr[31:12],UpperExtend);
adder          auipc(PC, UpperExtend, AUI);
mux2 #(32)     sel_aui_lui(AUI,UpperExtend, Op5, UTypeSel);

// ALU logic
mux2 #(32)     srcbmux(WriteData, ImmExt, ALUSrc, SrcB);
alu            alu (SrcA, SrcB, ALUControl, ALUResult, Zero, Overflow);
mux4 #(32)     resultmux(ALUResult, ReadData, PCPlus4, UTypeSel, ResultSrc, Result);

assign Mem_WrData = WriteData;
assign Mem_WrAddr = ALUResult;

endmodule

