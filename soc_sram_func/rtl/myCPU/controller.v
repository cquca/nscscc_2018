`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: controller
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


module controller(
	input wire clk,rst,
	//decode stage
	input wire[31:0] instrD,
	output wire[1:0] pcsrcD,
	output wire branchD,jumpD,jrD,regwriteD,balD,invalidD,
	input wire equalD,
	//execute stage
	input wire stallE,flushE,overflowE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,jalE,
	output wire[7:0] alucontrolE,

	//mem stage
	output wire memtoregM,memenM,memwriteM,
				regwriteM,
	input wire flushM,adelM,
	//write back stage
	output wire memtoregW,regwriteW,jrW,is_in_slotW,
	input wire flushW

    );
	

	//decode stage
	wire memtoregD,memenD,memwriteD,alusrcD,
		regdstD,jalD,next_is_in_slotD;//,regwriteD
	wire[7:0] alucontrolD;

	//execute stage
	wire memenE,jrE,memwriteE,next_is_in_slotE,is_in_slotE;

	//mem stage
	wire jrM,is_in_slotM;

	maindec md(
		instrD,
		memtoregD,memenD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,jalD,jrD,balD,next_is_in_slotD,invalidD
		);
	aludec ad(instrD,alucontrolD);

	assign pcsrcD = {jumpD | jalD,branchD&equalD};

	//pipeline registers
	flopenrc #(19) regE(
		clk,
		rst,~stallE,
		flushE,
		{memtoregD,memenD,alusrcD,regdstD,regwriteD,jalD,jrD,memwriteD,next_is_in_slotD,next_is_in_slotE,alucontrolD},
		{memtoregE,memenE,alusrcE,regdstE,regwriteE,jalE,jrE,memwriteE,next_is_in_slotE,is_in_slotE,alucontrolE}
		);
	floprc #(6) regM(
		clk,rst,flushM,
		{memtoregE,memenE,regwriteE^overflowE,jrE,memwriteE,is_in_slotE},
		{memtoregM,memenM,regwriteM,jrM,memwriteM,is_in_slotM}
		);
	floprc #(4) regW(
		clk,rst,flushW,
		{memtoregM,regwriteM^adelM,jrM,is_in_slotM},
		{memtoregW,regwriteW,jrW,is_in_slotW}
		);
endmodule
