`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/08/10 18:45:47
// Design Name: 
// Module Name: LLbit
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

`include "defines.vh"
module LLbit(
	input wire clk,
	input wire rst,
	input wire flush,
	input wire LLbit_i,
	input wire we,
	output reg LLbit_o
    );
	
	always @(posedge clk) begin
		if(rst == `RstEnable) begin
			 LLbit_o <= 1'b0;
		end else if(flush == 1'b1) begin
			/* code */
			LLbit_o <= 1'b0;
		end else if(we == `WriteEnable) begin
			LLbit_o <= LLbit_i;
		end
	end
endmodule
