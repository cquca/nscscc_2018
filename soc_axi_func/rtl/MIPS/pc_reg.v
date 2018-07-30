`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/08/06 15:19:50
// Design Name: 
// Module Name: pc_reg
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

module pc_reg(
	input wire clk,
	input wire rst,
	input wire[5:0] stall,
	input wire flush,
	input wire[`RegBus] new_pc,
	//from id
	input wire branch_flag_i,
	input wire[`RegBus] branch_target_address_i,

	output reg[`InstAddrBus] pc,
	output reg ce
    );
	
	always @(posedge clk) begin
		if(rst == `RstEnable) begin
			 ce <= `ChipDisable;
		end else begin
			 ce <= `ChipEnable ;
		end
	end

	always @(posedge clk) begin
		if(ce == `ChipDisable) begin
			 pc <= 32'hBFC00000;
		end else begin 
			if(flush == 1'b1) begin
				/* code */
				pc <= new_pc;
			end else if(stall[0] == `NoStop)begin
				if(branch_flag_i == `Branch) begin
					/* code */
					pc <= branch_target_address_i;
				end else begin 
					pc <= pc + 4'h4;
				end
			end
		end
	end
endmodule
