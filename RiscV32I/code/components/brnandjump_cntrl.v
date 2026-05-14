module brnandjump_cntrl(
    input [2:0] funct3,
    input Branch,
    input Jump,
    input Zero,
    input Overflow,
    input MsbResult,
    output wire PCSrc
);

reg PCX;

always @(*)begin
    case(funct3)
        3'b000: PCX = Branch && Zero;
        3'b001: PCX = Branch && (!Zero);
        // 3'b010:
        // 3'b011:
        3'b100: PCX = Branch && (MsbResult^Overflow);
        3'b101: PCX = Branch && (!(MsbResult^Overflow));
        3'b110: PCX = Branch && MsbResult;
        3'b111: PCX = Branch && !MsbResult; 
        default: PCX = 0;
    endcase
end

assign PCSrc = PCX | Jump;

endmodule