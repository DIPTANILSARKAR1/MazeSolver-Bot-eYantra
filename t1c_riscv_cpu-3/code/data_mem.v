
// data_mem.v - data memory

module data_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 64) (
    input                    clk, wr_en,
    input   [2:0]            Funct3,
    input   [ADDR_WIDTH-1:0] wr_addr, wr_data,
    output reg [DATA_WIDTH-1:0] rd_data_mem
);

// array of 64 32-bit words or data
reg [DATA_WIDTH-1:0] data_ram [0:MEM_SIZE-1];
wire [5:0] word_address = wr_addr[31:2];

// combinational read logic
// word-aligned memory access
// assign rd_data_mem = data_ram[wr_addr[DATA_WIDTH-1:2] % 64];
// Byte-aligned memory access
always @(*) begin
    case (Funct3)
        //lbsigned
        3'b000: case (wr_addr[1:0])
            2'b00:  rd_data_mem = {{24{data_ram[word_address][7]}} ,data_ram[word_address][7:0]};
            2'b01:  rd_data_mem = {{24{data_ram[word_address][15]}},data_ram[word_address][15:8]};
            2'b10:  rd_data_mem = {{24{data_ram[word_address][23]}},data_ram[word_address][23:16]};
            2'b11:  rd_data_mem = {{24{data_ram[word_address][31]}},data_ram[word_address][31:24]};
            default: rd_data_mem = 32'b0;
        endcase
        //lbunsigned
        3'b100: case (wr_addr[1:0])
            2'b00:  rd_data_mem = {24'b0,data_ram[word_address][7:0]};
            2'b01:  rd_data_mem = {24'b0,data_ram[word_address][15:8]};
            2'b10:  rd_data_mem = {24'b0,data_ram[word_address][23:16]};
            2'b11:  rd_data_mem = {24'b0,data_ram[word_address][31:24]};
            default: rd_data_mem = 32'b0;
        endcase

        //lh
        3'b001: case (wr_addr[1])
            1'b0:  rd_data_mem = {{16{data_ram[word_address][15]}},data_ram[word_address][15:0]};
            1'b1:  rd_data_mem = {{16{data_ram[word_address][31]}},data_ram[word_address][31:16]};
            default: rd_data_mem = 32'b0;
        endcase

        3'b101: case (wr_addr[1])
            1'b0:  rd_data_mem = {16'b0,data_ram[word_address][15:0]};
            1'b1:  rd_data_mem = {16'b0,data_ram[word_address][31:16]};
            default: rd_data_mem = 32'b0;
        endcase
        

        3'b010: rd_data_mem = data_ram[wr_addr[DATA_WIDTH-1:2] % 64] ;

        default: rd_data_mem = 32'b0;

    endcase
end

always @(posedge clk) begin
    if (wr_en) begin
        case(Funct3)
            // Store Byte (sb)
            3'b000: begin
                case(wr_addr[1:0])
                    2'b00: data_ram[word_address][7:0]   <= wr_data[7:0];
                    2'b01: data_ram[word_address][15:8]  <= wr_data[7:0];
                    2'b10: data_ram[word_address][23:16] <= wr_data[7:0];
                    2'b11: data_ram[word_address][31:24] <= wr_data[7:0];
                endcase
            end

            // Store Word (sw)
            3'b010: begin
                data_ram[word_address] <= wr_data;
            end

			3'b001:begin
                case(wr_addr[1])
				    1'b0: data_ram[word_address][15:0]<=wr_data[15:0];
                    1'b1: data_ram[word_address][31:16]<=wr_data[15:0];
                endcase
			end
        endcase
    end
end

endmodule

