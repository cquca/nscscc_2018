`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/08/06 15:19:50
// Design Name: 
// Module Name: regfile
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

module regfile(
	input wire clk,
	input wire rst,
	//wirte port
	input wire we,
	input wire[`RegAddrBus] waddr,
	input wire[`RegBus]	wdata,
	//read port 1
	input wire re1,
	input wire[`RegAddrBus] raddr1,
	output reg[`RegBus] rdata1,
	//read port 2
	input wire re2,
	input wire[`RegAddrBus] raddr2,
	output reg[`RegBus] rdata2
    );
	
//define 32 regs

	reg[`RegBus] regs[0:`RegNum-1];

//write opreation
	always @(posedge clk) begin
		if(rst == `RstDisable) begin
			if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
				/* code */
				regs[waddr] <= wdata;
			end
		end
	end
//read port 1
	always @(*) begin
		if(rst == `RstEnable) begin
			rdata1 <= `ZeroWord;
		end else if (raddr1 == `RegNumLog2'h0) begin
			rdata1 <= `ZeroWord;
		end else if ((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable)) begin
			rdata1 <= wdata;
		end else if(re1 == `ReadEnable) begin
			rdata1 <= regs[raddr1];
		end else begin
			rdata1 <= `ZeroWord;
		end
	end
//read port 2
	always @(*) begin
		if(rst == `RstEnable) begin
			rdata2 <= `ZeroWord;
		end else if (raddr2 == `RegNumLog2'h0) begin
			rdata2 <= `ZeroWord;
		end else if ((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable)) begin
			rdata2 <= wdata;
		end else if(re2 == `ReadEnable) begin
			rdata2 <= regs[raddr2];
		end else begin
			rdata2 <= `ZeroWord;
		end
	end

endmodule
