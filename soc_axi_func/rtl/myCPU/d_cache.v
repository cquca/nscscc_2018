`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/07/27 17:32:52
// Design Name: 
// Module Name: d_cache
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module d_cache #(parameter A_WIDTH = 32,
    parameter C_INDEX = 6)(
        input wire[A_WIDTH-1:0] p_a,
        input wire[31:0] p_dout,
        output wire[31:0] p_din,
        input wire p_strobe,
        input wire[3:0] p_wen,
		input wire[1:0] p_size,
        input wire p_rw, //0: read, 1:write
        output wire p_ready,
        // output wire cache_miss,
        input wire clk,clrn,
        output wire[A_WIDTH-1:0] m_a,
        input wire[31:0] m_dout,
        output wire[31:0] m_din,
        output wire m_strobe,
        output wire[3:0] m_wen,
		output wire[1:0] m_size,
        output wire m_rw,
        input wire m_ready
    );


    localparam T_WIDTH = A_WIDTH - C_INDEX -2;
    reg d_valid [0:(1<<C_INDEX)-1];
    reg [T_WIDTH-1:0] d_tags [0:(1<<C_INDEX)-1];
    reg [31:0] d_data [0:(1<<C_INDEX)-1];
    wire [C_INDEX-1:0] index = p_a[C_INDEX+1:2];
    wire [T_WIDTH-1:0] tag = p_a[A_WIDTH-1:C_INDEX+2];


    // read from cache
    wire valid = d_valid[index];
    wire [T_WIDTH-1:0] tagout = d_tags[index];
    wire [31:0] c_dout = d_data[index];

    // cache control
    wire cache_hit = valid & (tagout == tag) & p_strobe & ~p_rw;//hit
    wire cache_miss = ~cache_hit & p_strobe;
    assign m_din = p_dout;
    assign m_a = p_a;
    assign m_wen = p_wen;
    assign m_size = p_size;
    assign m_rw = p_strobe & p_rw; //write through
    assign m_strobe = p_strobe & (p_rw | cache_miss);
    assign p_ready = ~p_rw & cache_hit | (cache_miss | p_rw) & m_ready;
    
    wire c_write = p_rw | cache_miss & m_ready;
    wire sel_in = p_rw;
    wire sel_out = cache_hit;
    wire[31:0] c_din = sel_in ? p_dout : m_dout;
    assign p_din = sel_out ? c_dout : m_dout;
    integer i;


    always @(posedge clk or negedge clrn) begin
        if (clrn == 1'b0) begin
            
            for (i = 0;i < (1<<C_INDEX) ;i=i+1 ) begin
                d_valid[i] <= 1'b0;
            end
        end else if (c_write) begin
            d_valid[index] <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if (c_write) begin
            d_tags[index] <= tag;
            
            case (p_wen)
                4'b1111:d_data[index] <= c_din;
                4'b1100:d_data[index] <= {c_din[31:16],d_data[index][15:0]};
                4'b0011:d_data[index] <= {d_data[index][31:16],c_din[15:0]};
                4'b1000:d_data[index] <= {c_din[31:24],d_data[index][23:0]};
                4'b0100:d_data[index] <= {d_data[index][31:24],c_din[23:16],d_data[index][15:0]};
                4'b0010:d_data[index] <= {d_data[index][31:16],c_din[15:8],d_data[index][7:0]};
                4'b0001:d_data[index] <= {d_data[index][31:8],c_din[7:0]};
                default:;
            endcase
        end
    end
    
endmodule
