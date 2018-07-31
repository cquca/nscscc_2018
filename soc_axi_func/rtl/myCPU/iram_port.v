`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/12/21 22:55:40
// Design Name: 
// Module Name: iram_port
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


module iram_port(
	// to core side
	input wire[31:0] pcF,
	output wire[31:0] instrF,
	output wire stall_by_iram,
	//to bus side
	input wire if_addr_ok,if_data_ok,
    input wire[31:0] if_rdata,
    output wire[31:0] if_addr,if_wdata,
    output wire if_wr,
    output wire[3:0] if_ben,
    input wire memen
    );

	assign instrF = if_data_ok ? if_rdata : 32'b0;

	assign if_addr = (pcF[31:28] == 4'hB) ? {4'h1,pcF[27:0]} :
					(pcF[31:28] == 4'h8) ? {4'h0,pcF[27:0]}: 32'b0;

	assign stall_by_iram = (if_addr_ok == 1'b0);

	assign if_wdata = 32'b0;
	assign if_wr = 1'b0;
	assign if_ben = (pcF[1:0] == 2'b00) ? 4'b1111 : 4'b0000;
endmodule
