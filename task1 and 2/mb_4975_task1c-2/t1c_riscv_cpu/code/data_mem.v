// data_mem_comb_fixed.v - corrected: moved declarations out of procedural block
`timescale 1ns/1ns
module data_mem #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_SIZE   = 64   // keep as in your design
)(
    input                       clk,        // used only for synchronous writes
    input                       wr_en,      // write enable (from CPU)
    input         [2:0]         funct3,     // indicates sb/sh/sw or load type
    input  [ADDR_WIDTH-1:0]     wr_addr,    // byte address used for both load/store
    input  [DATA_WIDTH-1:0]     wr_data,    // write data
    output reg [DATA_WIDTH-1:0] rd_data_mem // combinational read output (zero-cycle)
);

    // address math
    localparam AW = (MEM_SIZE <= 1) ? 1 : $clog2(MEM_SIZE);
    wire [AW-1:0] word_addr = wr_addr[AW+1:2]; // word index (wr_addr bits [AW+1:2])
    wire [1:0] byte_sel = wr_addr[1:0];
    wire       half_sel = wr_addr[0];

    // memory array - behavioral (will synthesize to LEs for combinational read)
    reg [DATA_WIDTH-1:0] data_ram [0:MEM_SIZE-1];

    integer idx;
    initial begin
        // optional deterministic init for simulation (comment out if not wanted)
        for (idx = 0; idx < MEM_SIZE; idx = idx + 1) data_ram[idx] = {DATA_WIDTH{1'b0}};
    end

    // synchronous writes only (writes happen on posedge clk)
    always @(posedge clk) begin
        if (wr_en) begin
            case (funct3)
                3'b000: begin // sb - store byte (little-endian)
                    case (byte_sel)
                        2'b00: data_ram[word_addr][7:0]   <= wr_data[7:0];
                        2'b01: data_ram[word_addr][15:8]  <= wr_data[7:0];
                        2'b10: data_ram[word_addr][23:16] <= wr_data[7:0];
                        2'b11: data_ram[word_addr][31:24] <= wr_data[7:0];
                    endcase
                end
                3'b001: begin // sh - store halfword (16-bit)
                    if (half_sel == 1'b0)
                        data_ram[word_addr][15:0]  <= wr_data[15:0];
                    else
                        data_ram[word_addr][31:16] <= wr_data[15:0];
                end
                3'b010: begin // sw - store word
                    data_ram[word_addr] <= wr_data;
                end
                default: begin
                    // no store for other funct3 values
                end
            endcase
        end
    end

    // ---- helper functions to extract lanes ----
    // get a byte from a word (little-endian)
    function automatic [7:0] get_byte;
        input [31:0] w;
        input [1:0]  sel;
        begin
            case (sel)
                2'b00: get_byte = w[7:0];
                2'b01: get_byte = w[15:8];
                2'b10: get_byte = w[23:16];
                2'b11: get_byte = w[31:24];
                default: get_byte = 8'hxx;
            endcase
        end
    endfunction

    // get halfword from a word
    function automatic [15:0] get_half;
        input [31:0] w;
        input        sel; // 0 -> low half, 1 -> high half
        begin
            get_half = sel ? w[31:16] : w[15:0];
        end
    endfunction

    // compose a candidate word if a write happens this cycle to same word
    // takes current_word (from mem) and wr_en/funct3/wr_data/addr to produce new word
    function automatic [31:0] compose_after_write;
        input [31:0] current_word;
        input        wr_en_f;
        input [2:0]  f3;
        input [1:0]  bsel;
        input        hsel;
        input [31:0] wdata;
        reg   [31:0] tmp;
        begin
            tmp = current_word; // default
            if (wr_en_f) begin
                case (f3)
                    3'b010: tmp = wdata; // sw
                    3'b001: tmp = (hsel ? {wdata[15:0], current_word[15:0]} : {current_word[31:16], wdata[15:0]}); // sh
                    3'b000: begin // sb
                        case (bsel)
                            2'b00: tmp = {current_word[31:8],  wdata[7:0]};
                            2'b01: tmp = {current_word[31:16], wdata[7:0], current_word[7:0]};
                            2'b10: tmp = {current_word[31:24], wdata[7:0], current_word[15:0]};
                            2'b11: tmp = {wdata[7:0], current_word[23:0]};
                            default: tmp = current_word;
                        endcase
                    end
                    default: tmp = current_word;
                endcase
            end
            compose_after_write = tmp;
        end
    endfunction

    // -------- combinational read logic (zero-cycle) --------
    // Declared at module scope (required by Verilog)
    reg [31:0] curr_word;
    reg [31:0] candidate;

    always @(*) begin
        curr_word = data_ram[word_addr]; // combinational read of memory
        candidate = compose_after_write(curr_word, wr_en, funct3, byte_sel, half_sel, wr_data);

        case (funct3)
            3'b000: begin // LB - sign-extend byte
                case (byte_sel)
                    2'b00: rd_data_mem = {{24{candidate[7]}},  candidate[7:0]};
                    2'b01: rd_data_mem = {{24{candidate[15]}}, candidate[15:8]};
                    2'b10: rd_data_mem = {{24{candidate[23]}}, candidate[23:16]};
                    2'b11: rd_data_mem = {{24{candidate[31]}}, candidate[31:24]};
                    default: rd_data_mem = 32'hxxxxxxxx;
                endcase
            end
            3'b100: begin // LBU - zero-extend byte
                case (byte_sel)
                    2'b00: rd_data_mem = {24'b0, candidate[7:0]};
                    2'b01: rd_data_mem = {24'b0, candidate[15:8]};
                    2'b10: rd_data_mem = {24'b0, candidate[23:16]};
                    2'b11: rd_data_mem = {24'b0, candidate[31:24]};
                    default: rd_data_mem = 32'hxxxxxxxx;
                endcase
            end
            3'b001: begin // LH - sign-extend halfword
                if (half_sel == 1'b0) rd_data_mem = {{16{candidate[15]}}, candidate[15:0]};
                else                  rd_data_mem = {{16{candidate[31]}}, candidate[31:16]};
            end
            3'b101: begin // LHU - zero-extend halfword
                if (half_sel == 1'b0) rd_data_mem = {16'b0, candidate[15:0]};
                else                  rd_data_mem = {16'b0, candidate[31:16]};
            end
            3'b010: begin // LW - word
                rd_data_mem = candidate;
            end
            default: begin
                rd_data_mem = 32'hxxxxxxxx; // preserve simulation sentinel
            end
        endcase
    end

endmodule
