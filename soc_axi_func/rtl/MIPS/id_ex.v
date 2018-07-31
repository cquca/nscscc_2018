`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/08/06 15:19:50
// Design Name: 
// Module Name: id_ex
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
module id_ex(
	input wire clk,
	input wire rst,
	input wire[5:0] stall,
	input wire flush,
	//from i-decode
	input wire[`AluOpBus] id_aluop,
	input wire[`AluSelBus] id_alusel,
	input wire[`RegBus] id_reg1,
	input wire[`RegBus] id_reg2,
	input wire[`RegAddrBus] id_wd,

	input wire id_wreg,
	input wire[`RegBus] id_inst,
	input wire[`RegBus] id_excepttype,
	input wire[`RegBus] id_current_inst_address,
	//to execution
	output reg[`AluOpBus] ex_aluop,
	output reg[`AluSelBus] ex_alusel,
	output reg[`RegBus] ex_reg1,
	output reg[`RegBus] ex_reg2,
	output reg[`RegAddrBus] ex_wd,
	output reg ex_wreg,
	output reg[`RegBus] ex_inst,
	output reg[`RegBus] ex_current_inst_address,
	output reg[`RegBus] ex_excepttype,
	//for branch inst
	input wire[`RegBus] id_link_address,
	input wire id_is_in_delayslot,
	input wire next_inst_in_delayslot_i,

	output reg[`RegBus] ex_link_address,
	output reg ex_is_in_delayslot,
	output reg is_in_delayslot_o,
	input wire[`InstAddrBus] id_pc,
	output reg[`InstAddrBus] ex_pc
    );
	
	always @(posedge clk) begin
		ex_pc <= id_pc;

		if(rst == `RstEnable) begin
			// ex_pc <= `ZeroWord;

			 ex_aluop <= `EXE_NOP_OP; 
			 ex_alusel <= `EXE_RES_NOP;
			 ex_reg1 <= `ZeroWord;
			 ex_reg2 <= `ZeroWord;
			 ex_wd <= `NOPRegAddr;
			 ex_wreg <= `WriteDisable;
			 ex_link_address <= `ZeroWord;
			 ex_is_in_delayslot <= `NotInDelaySlot;
			 is_in_delayslot_o <= `NotInDelaySlot;
			 ex_inst <= `ZeroWord;
			 ex_excepttype <= `ZeroWord;
			 ex_current_inst_address <= `ZeroWord;
		end else if(flush == 1'b1) begin
			/* code */
			// ex_pc <= `ZeroWord;

			ex_aluop <= `EXE_NOP_OP; 
			 ex_alusel <= `EXE_RES_NOP;
			 ex_reg1 <= `ZeroWord;
			 ex_reg2 <= `ZeroWord;
			 ex_wd <= `NOPRegAddr;
			 ex_wreg <= `WriteDisable;
			 ex_link_address <= `ZeroWord;
			 ex_is_in_delayslot <= `NotInDelaySlot;
			 is_in_delayslot_o <= `NotInDelaySlot;
			 ex_inst <= `ZeroWord;
			 ex_excepttype <= `ZeroWord;
			 ex_current_inst_address <= `ZeroWord;
		end else if(stall[2] == `Stop && stall[3] == `NoStop) begin
			/* code */
			// ex_pc <= `ZeroWord;
			 ex_aluop <= `EXE_NOP_OP; 
			 ex_alusel <= `EXE_RES_NOP;
			 ex_reg1 <= `ZeroWord;
			 ex_reg2 <= `ZeroWord;
			 ex_wd <= `NOPRegAddr;
			 ex_wreg <= `WriteDisable;
			 ex_link_address <= `ZeroWord;
			 ex_is_in_delayslot <= `NotInDelaySlot;
			 ex_inst <= `ZeroWord;
			 ex_excepttype <= `ZeroWord;
			 ex_current_inst_address <= `ZeroWord;
		end else if(stall[2] == `NoStop) begin
			// ex_pc <= id_pc;
			 ex_aluop <= id_aluop;
			 ex_alusel <= id_alusel;
			 ex_reg1 <= id_reg1;
			 ex_reg2 <= id_reg2;
			 ex_wd <= id_wd;
			 ex_wreg <= id_wreg;
			 ex_link_address <= id_link_address;
			 ex_is_in_delayslot <= id_is_in_delayslot;
			 is_in_delayslot_o <= next_inst_in_delayslot_i;
			 ex_inst <= id_inst;
			 ex_excepttype <= id_excepttype;
			 ex_current_inst_address <= id_current_inst_address;
		end
	end
endmodule
