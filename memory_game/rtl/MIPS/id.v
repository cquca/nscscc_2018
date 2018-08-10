`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/08/06 15:19:50
// Design Name: 
// Module Name: id
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

module id(
	input wire rst,
	output wire stallreq,
	input wire[`InstAddrBus] pc_i,
	output wire[`InstAddrBus] pc_o,

	input wire[`InstBus] inst_i,


	//read regfile
	input wire[`RegBus] reg1_data_i,
	input wire[`RegBus] reg2_data_i,
	//out to regfile
	output reg reg1_read_o,
	output reg reg2_read_o,
	output reg[`RegAddrBus] reg1_addr_o,
	output reg[`RegAddrBus] reg2_addr_o,

	//to excution

	output reg[`AluOpBus] aluop_o,
	output reg[`AluSelBus] alusel_o,
	output reg[`RegBus] reg1_o,
	output reg[`RegBus] reg2_o,
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output wire[`RegBus] inst_o,
//data front push
	//the result of exe
	input wire ex_wreg_i,
	input wire[`RegBus] ex_wdata_i,
	input wire[`RegAddrBus] ex_wd_i,
	//the result of mem
	input wire mem_wreg_i,
	input wire[`RegBus] mem_wdata_i,
	input wire[`RegAddrBus] mem_wd_i,

	//for branch inst
	input wire is_in_delayslot_i,
	output reg next_inst_in_delayslot_o,
	output reg branch_flag_o,
	output reg[`RegBus] branch_target_address_o,
	output reg[`RegBus] link_addr_o,
	output reg is_in_delayslot_o,
	//fix load correlation
	input wire[`AluOpBus] ex_aluop_i,

	//for exceptions
	output wire[`RegBus] excepttype_o,
	output wire[`RegBus] current_inst_address_o
    );

	//get opcode
	wire[5:0] op = inst_i[31:26];
	wire[4:0] op2 = inst_i[10:6];
	wire[5:0] op3 = inst_i[5:0];
	wire[4:0] op4 = inst_i[20:16];
	//save the imm
	reg[`RegBus] imm;
	//
	reg instvalid;
	//for branch inst
	wire[`RegBus] pc_plus_8;
	wire[`RegBus] pc_plus_4;
	wire[`RegBus] imm_sll2_signedext;

	assign pc_plus_8 = pc_i + 8;
	assign pc_plus_4 = pc_i + 4;
	assign imm_sll2_signedext = {{14{inst_i[15]}},inst_i[15:0],2'b00};

	

	assign inst_o = inst_i;
	assign pc_o = pc_i;


	//load correlation
	reg stallreq_for_reg1_loadrelate;
	reg stallreq_for_reg2_loadrelate;
	wire pre_inst_is_load;

	assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) ||
								(ex_aluop_i == `EXE_LBU_OP)||
								(ex_aluop_i == `EXE_LH_OP)||
								(ex_aluop_i == `EXE_LHU_OP)||
								(ex_aluop_i == `EXE_LW_OP)||
								(ex_aluop_i == `EXE_LWR_OP)||
								(ex_aluop_i == `EXE_LWL_OP)||
								(ex_aluop_i == `EXE_LL_OP)||
								(ex_aluop_i == `EXE_SC_OP)) ? 1'b1 : 1'b0;

	//for exception
	reg excepttype_is_syscall;
	reg excepttype_is_break;
	reg excepttype_is_eret;

	assign excepttype_o = {18'b0,excepttype_is_eret,2'b0,instvalid,
				excepttype_is_break,excepttype_is_syscall,8'b0};
	assign current_inst_address_o = pc_i;

//-----------------------first segment----------------------
	always @(*) begin
		if(rst == `RstEnable) begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= 32'h0;
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
			excepttype_is_syscall <= `False_v;
			excepttype_is_break <= `False_v;
			excepttype_is_eret <= `False_v;
		end else begin 
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= inst_i[15:11];
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];
			reg2_addr_o <= inst_i[20:16];
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
			excepttype_is_syscall <= `False_v;
			excepttype_is_break <= `False_v;
			excepttype_is_eret <= `False_v;
			case (op)
				`EXE_SPECIAL_INST:begin 
					case (op2)
						5'b00000:begin 
							case (op3)

								`EXE_OR:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_OR_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_AND:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_AND_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_XOR:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_XOR_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_NOR:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_NOR_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_SLLV:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SLL_OP;
									alusel_o <= `EXE_RES_SHIFT;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_SRLV:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SRL_OP;
									alusel_o <= `EXE_RES_SHIFT;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_SRAV:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SRA_OP;
									alusel_o <= `EXE_RES_SHIFT;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_SYNC:begin 
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_NOP_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b0;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_MFHI:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_MFHI_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b0;
									reg2_read_o <= 1'b0;
									instvalid <= ((op2 == 5'b0) && (inst_i[25:16] == 10'b0)) ? `InstValid : `InstInvalid;
								end
								`EXE_MFLO:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_MFLO_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b0;
									reg2_read_o <= 1'b0;
									instvalid <= ((op2 == 5'b0) && (inst_i[25:16] == 10'b0)) ? `InstValid : `InstInvalid;
								end
								`EXE_MTHI:begin 
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MTHI_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									instvalid <= inst_i[20:6] == 15'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_MTLO:begin 
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MTLO_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									instvalid <= inst_i[20:6] == 15'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_MOVN:begin 
									aluop_o <= `EXE_MOVN_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
									if(reg2_o != `ZeroWord) begin
										/* code */
										wreg_o <= `WriteEnable;
									end else begin 
										wreg_o <= `WriteDisable;
									end
								end
								`EXE_MOVZ:begin 
									aluop_o <= `EXE_MOVZ_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
									if(reg2_o == `ZeroWord) begin
										/* code */
										wreg_o <= `WriteEnable;
									end else begin 
										wreg_o <= `WriteDisable;
									end
								end
								`EXE_SLT:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SLT_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_SLTU:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SLTU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_ADD:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_ADD_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_ADDU:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_ADDU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_SUB:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SUB_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_SUBU:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SUBU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_MULT:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_MULT_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= inst_i[15:6] == 10'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_MULTU:begin 
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_MULTU_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= inst_i[15:6] == 10'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_DIV:begin 
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_DIV_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= inst_i[15:6] == 10'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_DIVU:begin 
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_DIVU_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= inst_i[15:6] == 10'b0 ? `InstValid : `InstInvalid;
								end
								`EXE_JR:begin 
									aluop_o <= `EXE_JR_OP;
									alusel_o <= `EXE_RES_JUMP_BRANCH;
									wreg_o <= `WriteDisable;
									instvalid <= inst_i[20:6] == 15'b0 ? `InstValid : `InstInvalid;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									link_addr_o <= `ZeroWord;
									branch_target_address_o <= reg1_o;
									branch_flag_o <= `Branch;
									next_inst_in_delayslot_o <= `InDelaySlot;
								end
								`EXE_JALR:begin 
									aluop_o <= `EXE_JALR_OP;
									alusel_o <= `EXE_RES_JUMP_BRANCH;
									wreg_o <= `WriteEnable;
									instvalid <= ((inst_i[20:16] == 5'b0) && (inst_i[10:6] == 5'b0)) ? `InstValid : `InstInvalid;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									wd_o <= inst_i[15:11];
									link_addr_o <= pc_plus_8;
									branch_target_address_o <= reg1_o;
									branch_flag_o <= `Branch;
									next_inst_in_delayslot_o <= `InDelaySlot;
								end
								default : begin 
									instvalid <= `InstInvalid;
								end
							endcase
						end
					
						default : /* default */;
					endcase
					case (op3)
						`EXE_TEQ:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TEQ_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b1;
							instvalid <= `InstValid;
						end
						`EXE_TGE:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TGE_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b1;
							instvalid <= `InstValid;
						end
						`EXE_TGEU:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TGEU_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b1;
							instvalid <= `InstValid;
						end
						`EXE_TLT:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TLT_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b1;
							instvalid <= `InstValid;
						end
						`EXE_TLTU:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TLTU_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b1;
							instvalid <= `InstValid;		
						end
						`EXE_TNE:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TNE_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b1;
							instvalid <= `InstValid;
						end
						`EXE_SYSCALL:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_SYSCALL_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b0;
							reg2_read_o <= 1'b0;
							instvalid <= `InstValid;
							excepttype_is_syscall <= `True_v;
						end
						`EXE_BREAK:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_BREAK_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b0;
							reg2_read_o <= 1'b0;
							instvalid <= `InstValid;
							excepttype_is_break <= `True_v;
						end
						default : /* default */;
					endcase
				end
				`EXE_ORI:	begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_OR_OP;
					alusel_o <= `EXE_RES_LOGIC;

					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;

					imm <= {16'h0,inst_i[15:0]};
					wd_o <= inst_i[20:16];

					instvalid <= `InstValid;
				end
				`EXE_ANDI:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_AND_OP;
					alusel_o <= `EXE_RES_LOGIC;

					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;

					imm <= {16'h0,inst_i[15:0]};
					wd_o <= inst_i[20:16];

					instvalid <= `InstValid;
				end
				`EXE_XORI:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_XOR_OP;
					alusel_o <= `EXE_RES_LOGIC;

					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;

					imm <= {16'h0,inst_i[15:0]};
					wd_o <= inst_i[20:16];

					instvalid <= `InstValid;
				end
				`EXE_LUI:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_OR_OP;
					alusel_o <= `EXE_RES_LOGIC;

					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;

					imm <= {inst_i[15:0],16'h0};
					wd_o <= inst_i[20:16];

					instvalid <= inst_i[25:21] == 5'b0 ? `InstValid : `InstInvalid;
				end
				`EXE_SLTI:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SLT_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;

					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;

					imm <= {{16{inst_i[15]}},inst_i[15:0]};
					wd_o <= inst_i[20:16];

					instvalid <= `InstValid;
				end
				`EXE_SLTIU:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SLTU_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;

					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;

					imm <= {{16{inst_i[15]}},inst_i[15:0]};
					wd_o <= inst_i[20:16];

					instvalid <= `InstValid;
				end
				`EXE_ADDI:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_ADDI_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;

					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;

					imm <= {{16{inst_i[15]}},inst_i[15:0]};
					wd_o <= inst_i[20:16];

					instvalid <= `InstValid;
				end
				`EXE_ADDIU:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_ADDIU_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;

					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;

					imm <= {{16{inst_i[15]}},inst_i[15:0]};
					wd_o <= inst_i[20:16];

					instvalid <= `InstValid;
				end
				`EXE_SPECIAL2_INST:begin
					case (op3)
						`EXE_CLZ:begin 
							wreg_o <= `WriteEnable;
							aluop_o <= `EXE_CLZ_OP;
							alusel_o <= `EXE_RES_ARITHMETIC;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
						end
						`EXE_CLO:begin 
							wreg_o <= `WriteEnable;
							aluop_o <= `EXE_CLO_OP;
							alusel_o <= `EXE_RES_ARITHMETIC;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
						end
						`EXE_MUL:begin 
							wreg_o <= `WriteEnable;
							aluop_o <= `EXE_MUL_OP;
							alusel_o <= `EXE_RES_MUL;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b1;
							instvalid <= op2 == 5'b0 ? `InstValid : `InstInvalid;
						end
						`EXE_MADD:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_MADD_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b1;
							instvalid <= inst_i[15:6] == 10'b0 ? `InstValid : `InstInvalid;
						end
						`EXE_MADDU:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_MADDU_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b1;
							instvalid <= inst_i[15:6] == 10'b0 ? `InstValid : `InstInvalid;
						end
						`EXE_MSUB:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_MSUB_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b1;
							instvalid <= inst_i[15:6] == 10'b0 ? `InstValid : `InstInvalid;
						end
						`EXE_MSUBU:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_MSUBU_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b1;
							instvalid <= inst_i[15:6] == 10'b0 ? `InstValid : `InstInvalid;
						end
						default : /* default */;
					endcase
				end
				`EXE_PREF:begin 
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_NOP_OP;
					alusel_o <= `EXE_RES_NOP;

					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b0;
					instvalid <= `InstValid;
				end
				`EXE_J:begin 
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_J_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b0;
					link_addr_o <= `ZeroWord;
					branch_flag_o <= `Branch;
					next_inst_in_delayslot_o <= `InDelaySlot;
					branch_target_address_o <= {pc_plus_4[31:28],inst_i[25:0],2'b00};
					instvalid <= `InstValid;
					// 00001011111100000000000110100000

				end
				`EXE_JAL:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_JAL_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b0;
					wd_o <= 5'b11111;
					link_addr_o <= pc_plus_8;
					branch_flag_o <= `Branch;
					next_inst_in_delayslot_o <= `InDelaySlot;
					branch_target_address_o <= {pc_plus_4[31:28],inst_i[25:0],2'b00};
					instvalid <= `InstValid;
				end
				`EXE_BEQ:begin 
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BEQ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
					next_inst_in_delayslot_o <= `InDelaySlot;
					if(reg1_o == reg2_o) begin
						/* code */
						branch_flag_o <= `Branch;
						
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
					end
				end
				`EXE_BGTZ:begin 
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BGTZ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					instvalid <= op4 != 5'b0 ? `InstInvalid : `InstValid;
					next_inst_in_delayslot_o <= `InDelaySlot;
					if((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
						/* code */
						branch_flag_o <= `Branch;
						
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
					end
				end
				`EXE_BLEZ:begin 
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BLEZ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					instvalid <= op4 != 5'b0 ? `InstInvalid : `InstValid;
					next_inst_in_delayslot_o <= `InDelaySlot;
					if((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
						/* code */
						branch_flag_o <= `Branch;
						
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
					end
				end
				`EXE_BNE:begin 
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BNE_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
					next_inst_in_delayslot_o <= `InDelaySlot;
					if(reg1_o != reg2_o) begin
						/* code */
						branch_flag_o <= `Branch;
						
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
					end
				end
				`EXE_REGIMM_INST:begin 
					case (op4)
						`EXE_BGEZ:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_BGEZ_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							instvalid <= `InstValid;
							next_inst_in_delayslot_o <= `InDelaySlot;
							if(reg1_o[31] == 1'b0) begin
								/* code */
								branch_flag_o <= `Branch;
								
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
							end
						end
						`EXE_BGEZAL:begin 
							wreg_o <= `WriteEnable;
							aluop_o <= `EXE_BGEZAL_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							link_addr_o <= pc_plus_8;
							wd_o <= 5'b11111;
							instvalid <= `InstValid;
							next_inst_in_delayslot_o <= `InDelaySlot;
							if(reg1_o[31] == 1'b0) begin
								/* code */
								branch_flag_o <= `Branch;
								
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
							end
						end
						`EXE_BLTZ:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_BLTZ_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							instvalid <= `InstValid;
							next_inst_in_delayslot_o <= `InDelaySlot;
							if(reg1_o[31] == 1'b1) begin
								/* code */
								branch_flag_o <= `Branch;
								
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
							end
						end
						`EXE_BLTZAL:begin 
							wreg_o <= `WriteEnable;
							aluop_o <= `EXE_BLTZAL_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							link_addr_o <= pc_plus_8;
							wd_o <= 5'b11111;
							instvalid <= `InstValid;
							next_inst_in_delayslot_o <= `InDelaySlot;
							if(reg1_o[31] == 1'b1) begin
								/* code */
								branch_flag_o <= `Branch;
								
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
							end
						end
						`EXE_TEQI:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TEQI_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							imm <= {{16{inst_i[15]}},inst_i[15:0]};
							instvalid <= `InstValid;
						end
						`EXE_TGEI:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TGEI_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							imm <= {{16{inst_i[15]}},inst_i[15:0]};
							instvalid <= `InstValid;
						end
						`EXE_TGEIU:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TGEIU_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							imm <= {{16{inst_i[15]}},inst_i[15:0]};
							instvalid <= `InstValid;
						end
						`EXE_TLTI:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TLTI_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							imm <= {{16{inst_i[15]}},inst_i[15:0]};
							instvalid <= `InstValid;
						end
						`EXE_TLTIU:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TLTIU_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							imm <= {{16{inst_i[15]}},inst_i[15:0]};
							instvalid <= `InstValid;
						end
						`EXE_TNEI:begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TNEI_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							imm <= {{16{inst_i[15]}},inst_i[15:0]};
							instvalid <= `InstValid;
						end
						default : /* default */;
					endcase
				end
				`EXE_LB:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LB_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end 
				`EXE_LBU:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LBU_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_LH:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LH_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_LHU:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LHU_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_LW:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LW_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_LWL:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LWL_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_LWR:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LWR_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_SB:begin 
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SB_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
				end
				`EXE_SH:begin 
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SH_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
				end 
				`EXE_SW:begin 
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SW_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
				end
				`EXE_SWL:begin 
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SWL_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
				end
				`EXE_SWR:begin 
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SWR_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
				end
				`EXE_LL:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LL_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_SC:begin 
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SC_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				default : /* default */;
			endcase

			if(inst_i[31:21] == 11'b00000000000) begin
				/* code */
				if(op3 == `EXE_SLL) begin
					/* code */
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SLL_OP;
					alusel_o <= `EXE_RES_SHIFT;

					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b1;

					imm[4:0] <= inst_i[10:6];
					wd_o <= inst_i[15:11];

					instvalid <= inst_i[25:21] == 5'b0 ? `InstValid : `InstInvalid;
				end else if(op3 == `EXE_SRL) begin
					/* code */
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SRL_OP;
					alusel_o <= `EXE_RES_SHIFT;

					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b1;

					imm[4:0] <= inst_i[10:6];
					wd_o <= inst_i[15:11];

					instvalid <= inst_i[25:21] == 5'b0 ? `InstValid : `InstInvalid;
				end else if(op3 == `EXE_SRA) begin
					/* code */
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SRA_OP;
					alusel_o <= `EXE_RES_SHIFT;

					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b1;

					imm[4:0] <= inst_i[10:6];
					wd_o <= inst_i[15:11];

					instvalid <= inst_i[25:21] == 5'b0 ? `InstValid : `InstInvalid;
				end
			end
			if(inst_i[31:21] == 11'b01000000000 &&
				inst_i[10:0] == 11'b00000000000) begin
				/* code */
				aluop_o <= `EXE_MFC0_OP;
				alusel_o <= `EXE_RES_MOVE;
				wd_o <= inst_i[20:16];
				wreg_o <= `WriteEnable;
				instvalid <= `InstValid;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
			end else if(inst_i[31:21] == 11'b01000000100 &&
				inst_i[10:0] == 11'b00000000000) begin
				/* code */
				aluop_o <= `EXE_MTC0_OP;
				alusel_o <= `EXE_RES_MOVE;
				reg1_addr_o <= inst_i[20:16];
				wreg_o <= `WriteDisable;
				instvalid <= `InstValid;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b0;
			end
			if(inst_i == `EXE_ERET) begin
				/* code */
				wreg_o <= `WriteDisable;
				aluop_o <= `EXE_ERET_OP;
				alusel_o <= `EXE_RES_NOP;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
				instvalid <= `InstValid;
				excepttype_is_eret <= `True_v;
			end
		end
	end
	// for branch
	always @(*) begin
		if(rst == `RstEnable) begin
			/* code */
			is_in_delayslot_o <= `NotInDelaySlot;
		end else begin 
			is_in_delayslot_o <= is_in_delayslot_i;
		end
	
	end
//-----------------second segment-------------------------
	always @(*) begin
		stallreq_for_reg1_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o && reg1_read_o == 1'b1) begin
			/* code */
			stallreq_for_reg1_loadrelate <= `Stop;
		end else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o)) begin
			/* code */
			reg1_o <= ex_wdata_i;
		end else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o)) begin
			/* code */
			reg1_o <= mem_wdata_i;
		end else if(reg1_read_o == 1'b1) begin
			/* code */
			reg1_o <= reg1_data_i;
		end else if(reg1_read_o == 1'b0) begin
			/* code */
			reg1_o <= imm;
		end else begin 
			reg1_o <= `ZeroWord;
		end
	
	end
//---------------------third segment---------------------
	always @(*) begin
		stallreq_for_reg2_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o && reg2_read_o == 1'b1) begin
			/* code */
			stallreq_for_reg2_loadrelate <= `Stop;
		end else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o)) begin
			/* code */
			reg2_o <= ex_wdata_i;
		end else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o)) begin
			/* code */
			reg2_o <= mem_wdata_i;
		end else if(reg2_read_o == 1'b1) begin
			/* code */
			reg2_o <= reg2_data_i;
		end else if(reg2_read_o == 1'b0) begin
			/* code */
			reg2_o <= imm;
		end else begin 
			reg2_o <= `ZeroWord;
		end
	
	end

	assign stallreq = stallreq_for_reg2_loadrelate | stallreq_for_reg1_loadrelate;
	
endmodule
