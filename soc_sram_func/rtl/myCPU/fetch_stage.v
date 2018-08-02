`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/08/02 16:14:02
// Design Name: 
// Module Name: fetch_stage
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


module fetch_stage(
    input wire clk,
    input wire resetn,            //low active
	input wire stall,
	input wire [31:0] pc_next,

	output wire [31:0] inst_sram_addr,
    output reg  [31:0] pc
    );

    always @(posedge clk) begin
        pc <= inst_sram_addr;
    end

    assign inst_sram_addr = ~resetn ? 32'hbfc00000 :
                            ~stall ? pc_next :
                            pc;

    
endmodule
