`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
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


module mips(
	input wire clk,resetn,
	input wire[5:0] int,
	
	//cpu inst sram
	output wire        inst_sram_en,
	output wire [3 :0] inst_sram_wen,
	output wire [31:0] inst_sram_addr,
	output wire [31:0] inst_sram_wdata,
	input wire [31:0] inst_sram_rdata,
	//cpu data sram
	output wire        data_sram_en,
	output wire [3 :0] data_sram_wen,
	output wire [31:0] data_sram_addr,
	output wire [31:0] data_sram_wdata,
	input wire [31:0] data_sram_rdata,

	//debug signals
	output wire [31:0] debug_wb_pc,
	output wire [3 :0] debug_wb_rf_wen,
	output wire [4 :0] debug_wb_rf_wnum,
	output wire [31:0] debug_wb_rf_wdata

    );

	assign inst_sram_en = 1'b1;
	assign inst_sram_wen = 4'b0000;
	assign inst_sram_wdata = 32'b0;
	
	wire [5:0] opD,functD,rtD;
	wire [1:0] pcsrcD;
	wire regdstE,alusrcE,memtoregE,memtoregM,memtoregW,
			regwriteE,regwriteM,memwriteM,dram_enM,
			regwriteW,jalW,
			jumpD,jrD,jrW,is_in_slotW,invalidD,stall_by_iram;
	wire [7:0] alucontrolE;
	wire stallE,flushE,flushM,flushW,overflowE,equalD,regwriteD;
	wire[31:0] instrD;	
	
	controller c(
		clk,~resetn,
		//decode stage
		instrD,
		pcsrcD,branchD,jumpD,jrD,regwriteD,balD,invalidD,
		equalD,
		
		//execute stage
		stallE,flushE,overflowE,
		memtoregE,alusrcE,
		regdstE,regwriteE,jalE,	
		alucontrolE,

		//mem stage
		memtoregM,data_sram_en,memwriteM,
		regwriteM,flushM,adelM,
		//write back stage
		memtoregW,regwriteW,jrW,is_in_slotW,flushW
		);
	
	datapath dp(
		clk,~resetn,
		//fetch stage
		inst_sram_addr,
		inst_sram_rdata,1'b0,
		//decode stage
		pcsrcD,branchD,
		jumpD,jrD,regwriteD,balD,invalidD,
		equalD,
		instrD,
		//execute stage
		memtoregE,
		alusrcE,regdstE,
		regwriteE,jalE,
		alucontrolE,
		stallE,flushE,
		overflowE,
		//mem stage
		memtoregM,
		regwriteM,
		data_sram_addr,data_sram_wdata,
		data_sram_rdata,data_sram_wen,adelM,adesM,flushM,
		//writeback stage
		int_i,
		memtoregW,
		regwriteW,jrW,is_in_slotW,flushW
	    );
	
  
endmodule
