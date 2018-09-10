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
`include "defines.h"

module controller(
	input wire clk,rst,

	//decode stage
	input wire[31:0] instrD,
	input wire equalD,stallD,
	output wire pcsrcD,branchD,jumpD,
	output wire jalD,jrD,balD,jalrD,
	output wire[4:0] alucontrolD,
	output wire [1:0] hilo_weD,
	output wire invalidD,

	//execute stage
	input wire flushE,stallE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,

	//mem stage
	output wire memtoregM,memwriteM,memenM,regwriteM,cp0weM,
	input wire stallM,flushM,

	//write back stage
	output wire memtoregW,regwriteW,
	input wire flushW
    );
	
	//decode stage
	wire[3:0] aluopD;
	wire [5:0] funcD;
	wire [4:0] rsD;
	wire memtoregD,memwriteD,memenD,alusrcD,regdstD,regwriteD,cp0weD;
	assign funcD = instrD[5:0];
	assign rsD = instrD[25:21];

	//execute stage
	wire memwriteE,memenE,cp0weE;

	maindec md(
		stallD,
		instrD,
		memtoregD,memwriteD,memenD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,
		aluopD,
		jalD,
		jrD,
		balD,
		jalrD,
		hilo_weD,
		cp0weD,
		invalidD
		);
	aludec ad(stallD,funcD,aluopD,rsD,alucontrolD);

	//judge branch instrs whther should execute
	assign pcsrcD = branchD & equalD;


	//pipeline registers 
	//
	//use the pipeline spread the signal
	//
	//stall and flush in Fetch and Decode stages only used in datapath to stall and flush  
	flopenrc #(7) regE(
		clk,
		rst,~stallE,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,cp0weD,memenD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,cp0weE,memenE}
		);
	flopenrc #(5) regM(
		clk,rst,~stallM,flushM,
		{memtoregE,memwriteE,regwriteE,cp0weE,memenE},
		{memtoregM,memwriteM,regwriteM,cp0weM,memenM}
		);
	flopenrc #(2) regW(
		clk,rst,1'b1,flushW,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
		);
endmodule
