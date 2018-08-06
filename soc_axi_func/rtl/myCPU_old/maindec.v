`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: maindec
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
module maindec(
	input wire[31:0] instr,
	output wire memtoreg,memen,memwrite,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,jal,jr,bal,next_is_in_slot,invalid
	// output wire[1:0] aluop
    );

	wire[5:0] op,funct;
	wire [4:0] rs,rt,rd;
	assign op = instr[31:26];
	assign funct = instr[5:0];
	assign rs = instr[25:21];
	assign rt = instr[20:16];
	assign rd = instr[15:11];

	reg[12:0] controls;
	assign {regwrite,regdst,alusrc,branch,memen,memtoreg,jump,jal,jr,bal,memwrite,next_is_in_slot,invalid} = controls;
	always @(*) begin
		case (op)
			`EXE_SPECIAL_INST:case (funct)
				`EXE_JR:controls <= 13'b0_0_0_0_0_0_1_0_1_0_0_1_0;
				`EXE_JALR:controls <= 13'b1_1_0_0_0_0_0_0_1_0_0_1_0;
				`EXE_SYSCALL,`EXE_BREAK:controls <= 13'b00000000_0_0_0_0_0;
				default: controls <= 13'b1_1_0_0_0_0_0_0_0_0_0_0_0;//R-TYRE
			endcase
			`EXE_LW,`EXE_LB,`EXE_LBU,`EXE_LH,`EXE_LHU:controls <= 13'b1_0_1_0_1_1_0_0_0_0_0_0_0;//LW
			`EXE_SW,`EXE_SB,`EXE_SH:controls <= 13'b0_0_1_0_1_0_0_0_0_0_1_0_0;//SW
			//B-inst
			`EXE_BEQ:controls <= 13'b0_0_0_1_0_0_0_0_0_0_0_1_0;//BEQ
			`EXE_BNE:controls <= 13'b0_0_0_1_0_0_0_0_0_0_0_1_0;
			`EXE_BGTZ:begin 
				if(rt == 5'b00000) begin
					/* code */
					controls <= 13'b0_0_0_1_0_0_0_0_0_0_0_1_0;
				end else begin 
					controls <= 13'b00000000_0_0_0_0_1;
				end
			end
			`EXE_BLEZ:begin 
				if(rt == 5'b00000) begin
					/* code */
					controls <= 13'b0_0_0_1_0_0_0_0_0_0_0_1_0;
				end else begin 
					controls <= 13'b00000000_0_0_0_0_1;
				end
			end
			`EXE_REGIMM_INST:case (rt)
				`EXE_BLTZ:begin 
					if(rt == 5'b00000) begin
						/* code */
						controls <= 13'b0_0_0_1_0_0_0_0_0_0_0_1_0;
					end else begin 
						controls <= 13'b00000000_0_0_0_0_1;
					end
				end
				`EXE_BLTZAL:begin 
					if(rt == 5'b10000) begin
						/* code */
						controls <= 13'b1_0_0_1_0_0_0_0_0_1_0_1_0;
					end else begin 
						controls <= 13'b00000000_0_0_0_0_1;
					end
				end
				`EXE_BGEZ:begin 
					if(rt == 5'b00001) begin
						/* code */
						controls <= 13'b0_0_0_1_0_0_0_0_0_0_0_1_0;
					end else begin 
						controls <= 13'b00000000_0_0_0_0_1;
					end
				end
				`EXE_BGEZAL:begin 
					if(rt == 5'b10001) begin
						/* code */
						controls <= 13'b1_0_0_1_0_0_0_0_0_1_0_1_0;
					end else begin 
						controls <= 13'b00000000_0_0_0_0_1;
					end
				end
			
				default : /* default */controls <= 13'b00000000_0_0_0_0_1;
			endcase
			//I-TYPE
			`EXE_ORI:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;//ORI
			`EXE_ANDI:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
			`EXE_XORI:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
			`EXE_LUI:begin 
				if(rs == 5'b00000) begin
					/* code */
					controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
				end else begin 
					controls <= 13'b00000000_0_0_0_0_1;
				end
			end
			`EXE_ADDI:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
			`EXE_ADDIU:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
			`EXE_SLTI:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
			`EXE_SLTIU:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
			//J-TYPE
			`EXE_J:controls <= 13'b0_0_0_0_0_0_1_0_0_0_0_1_0;//J
			`EXE_JAL:controls <= 13'b1_0_0_0_0_0_0_1_0_0_0_1_0;

			default:  controls <= 13'b00000000_0_0_0_0_1;//illegal op
		endcase
		if(instr[31:21] == 13'b010000_00000 && instr[10:0] == 13'b00000_000000) begin
			/* code */
			controls <= 13'b1_0_0_0_0_0_0_0_0_0_0_0_0;
		end else if(instr[31:21] == 13'b010000_00100 && instr[10:0] == 13'b00000_000000) begin
			/* code */
			controls <= 13'b0_1_0_0_0_0_0_0_0_0_0_0_0;
		end

		if(instr == `EXE_ERET) begin
			/* code */
			controls <= 13'b00000000_0_0_0_0_0;
		end else if(instr == 32'b0) begin
			/* code */
			controls <= 13'b00000000_0_0_0_0_0;
		end
	end
endmodule
