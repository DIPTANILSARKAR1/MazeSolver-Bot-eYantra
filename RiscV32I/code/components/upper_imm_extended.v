module upper_extend(
    input [19:0] InstrUpperImm,
    output reg [31:0] UpperExt
);

always @(*)begin
    UpperExt = {InstrUpperImm,12'b0};
end

endmodule 