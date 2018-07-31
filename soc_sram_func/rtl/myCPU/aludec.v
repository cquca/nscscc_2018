`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:27:24
// Design Name: 
// Module Name: aludec
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
module aludec(
	input wire[31:0] instr,
	output reg[7:0] alucontrol
    );

	wire[5:0] op,funct;
	wire [4:0] rs,rt,rd;
	assign op = instr[31:26];
	assign funct = instr[5:0];
	assign rs = instr[25:21];
	assign rt = instr[20:16];
	assign rd = instr[15:11];

	always @(*) begin
		case (op)
			//memory inst
			`EXE_LB:alucontrol <= `EXE_LB_OP;
			`EXE_LBU:alucontrol <= `EXE_LBU_OP;
			`EXE_LH:alucontrol <= `EXE_LH_OP;
			`EXE_LHU:alucontrol <= `EXE_LHU_OP;
			`EXE_LW:alucontrol <= `EXE_LW_OP;
			`EXE_SB:alucontrol <= `EXE_SB_OP;
			`EXE_SH:alucontrol <= `EXE_SH_OP;
			`EXE_SW:alucontrol <= `EXE_SW_OP;
			//logic inst imm
			`EXE_ORI: alucontrol <= `EXE_OR_OP;
			`EXE_ANDI: alucontrol <= `EXE_AND_OP;
			`EXE_XORI: alucontrol <= `EXE_XOR_OP;
			`EXE_LUI: alucontrol <= `EXE_LUI_OP;
			`EXE_ADDI:alucontrol <= `EXE_ADDI_OP;
			`EXE_ADDIU:alucontrol <= `EXE_ADDIU_OP;
			`EXE_SLTI:alucontrol <= `EXE_SLT_OP; //slt
			`EXE_SLTIU:alucontrol <= `EXE_SLTU_OP;
			// 2'b00: alucontrol <= 3'b010;//add (for lw/sw/addi)
			// 2'b01: alucontrol <= 3'b110;//sub (for beq)
			// 2'b10: alucontrol <= 3'b001;
			`EXE_SPECIAL_INST : case (funct)
				//arithmetic inst special
				`EXE_ADD:alucontrol <= `EXE_ADD_OP; //add
				`EXE_ADDU:alucontrol <= `EXE_ADDU_OP;
				`EXE_SUB:alucontrol <= `EXE_SUB_OP; //sub
				`EXE_SUBU:alucontrol <= `EXE_SUBU_OP;
				`EXE_SLT:alucontrol <= `EXE_SLT_OP; //slt
				`EXE_SLTU:alucontrol <= `EXE_SLTU_OP;
				`EXE_MULT:alucontrol <= `EXE_MULT_OP;
				`EXE_MULTU:alucontrol <= `EXE_MULTU_OP;
				`EXE_DIV:alucontrol <= `EXE_DIV_OP;
				`EXE_DIVU:alucontrol <= `EXE_DIVU_OP;
				//logic inst special
				`EXE_AND:alucontrol <= `EXE_AND_OP; //and
				`EXE_OR:alucontrol <= `EXE_OR_OP; //or
				`EXE_XOR:alucontrol <= `EXE_XOR_OP; //xor
				`EXE_NOR:alucontrol <= `EXE_NOR_OP; //nor
				//shift inst special
				`EXE_SLL:alucontrol <= `EXE_SLL_OP;
				`EXE_SRL:alucontrol <= `EXE_SRL_OP;
				`EXE_SRA:alucontrol <= `EXE_SRA_OP;
				`EXE_SLLV:alucontrol <= `EXE_SLLV_OP;
				`EXE_SRLV:alucontrol <= `EXE_SRLV_OP;
				`EXE_SRAV:alucontrol <= `EXE_SRAV_OP;
				//move inst special
				`EXE_MFHI:alucontrol <= `EXE_MFHI_OP;
				`EXE_MTHI:alucontrol <= `EXE_MTHI_OP;
				`EXE_MFLO:alucontrol <= `EXE_MFLO_OP;
				`EXE_MTLO:alucontrol <= `EXE_MTLO_OP;
				
				default:  alucontrol <= `EXE_NOP_OP;
			endcase
			default:  alucontrol <= `EXE_NOP_OP;
		endcase
		if(instr[31:21] == 11'b010000_00000 && instr[10:0] == 11'b00000_000000) begin
			/* code */
			alucontrol <= `EXE_MFC0_OP;
		end else if(instr[31:21] == 11'b010000_00100 && instr[10:0] == 11'b00000_000000) begin
			/* code */
			alucontrol <= `EXE_MTC0_OP;
		end
	end
endmodule
