`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 13:50:53
// Design Name: 
// Module Name: top
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


module top(
	input wire clk,rst,
	output wire[31:0] writedata,dataadr,
	output wire memen
    );

	wire[31:0] pc,instr,readdata;
	wire[3:0] sel;
	wire memwrite;

	// mips mips(clk,rst,pc,instr,memen,memwrite,dataadr,writedata,readdata,sel);
	// inst_mem imem(~clk,pc[8:2],instr);
	// data_mem dmem(~clk,memen,sel,dataadr,writedata,readdata);
	// data_ram dmem(~clk,memen,memwrite,dataadr,sel,writedata,readdata);
endmodule
