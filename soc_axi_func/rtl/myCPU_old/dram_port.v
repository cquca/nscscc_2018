`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/12/21 22:55:40
// Design Name: 
// Module Name: dram_port
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


module dram_port(
	//to core side
	input wire[31:0] aluoutM,writedataM,
	output wire[31:0] readdataM,
	input wire[3:0] selM,
	input wire memwriteM,memenM,
	//to bus side
	input wire mem_addr_ok,mem_data_ok,
    input wire[31:0] mem_rdata,
    output wire[31:0] mem_addr,mem_wdata,
    output wire mem_wr,
    output wire[3:0] mem_ben
    );
	
	assign readdataM = mem_rdata;
	assign mem_addr = (aluoutM[31:28] == 4'hB) ? {4'h1,aluoutM[27:0]} :
						(aluoutM[31:28] == 4'h8) ? {4'h0,aluoutM[27:0]} : 32'b0;
	assign mem_wdata = writedataM;
	assign mem_wr = memenM ? memwriteM : 1'b0;
	assign mem_ben = memenM ? selM : 4'b0000;
endmodule
