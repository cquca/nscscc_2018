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

`include "defines.h"
module maindec(
	input wire stallD,
	input wire[31:0] instr,
	output wire memtoreg,memwrite,memen,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,
	output wire[3:0] aluop,
	output wire jal,jr,bal,jalr,
	output wire [1:0] hilo_we,//first for highreg second for lowreg
	output wire cp0we,//cp0writeEnable
	output reg invalid// invalid instr
    );
	wire [4:0]rt,rs,rd;
	wire [5:0]op,func;
	reg[17:0] controls;
	// wire memen;//useless
	assign op=instr[31:26];
	assign rs=instr[25:21];
	assign rt=instr[20:16];
	assign rd=instr[15:11];
	assign func=instr[5:0];
	assign cp0we=((op==`SPECIAL3_INST)&(rs==`MTC0))?1:0;

	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,jal,jr,bal,jalr,aluop,memen,hilo_we} = controls;
	always @(*) begin
		invalid = 0;
		controls <= {11'b0_0_0_0_0_0_0_0_0_0_0,4'b0000, 3'b000};
		if (~stallD) begin
			case (op)
			`R_TYPE:case (func)

				//JR and JALR instrs
				`JR:  controls<=    {11'b0_0_0_0_0_0_0_0_1_0_0,`USELESS_OP,3'b000};
				`JALR:controls<=    {11'b1_1_0_0_0_0_0_0_0_0_1,`USELESS_OP,3'b000};

				// data_move instrs
				`MFHI:controls <=   {11'b1_1_0_0_0_0_0_0_0_0_0,`R_TYPE_OP, 3'b000};
				`MFLO:controls <=   {11'b1_1_0_0_0_0_0_0_0_0_0,`R_TYPE_OP, 3'b000};
				`MTHI:controls <=   {11'b0_0_0_0_0_0_0_0_0_0_0,`R_TYPE_OP, 3'b010};
				`MTLO:controls <=   {11'b0_0_0_0_0_0_0_0_0_0_0,`R_TYPE_OP, 3'b001};	

				// mul and div instrs
				`MULTU:controls <=  {11'b0_0_0_0_0_0_0_0_0_0_0, `R_TYPE_OP, 3'b011};
				`MULT:controls <=   {11'b0_0_0_0_0_0_0_0_0_0_0, `R_TYPE_OP, 3'b011};
				`DIVU:controls <=   {11'b0_0_0_0_0_0_0_0_0_0_0, `R_TYPE_OP, 3'b011};
				`DIV:controls <=    {11'b0_0_0_0_0_0_0_0_0_0_0, `R_TYPE_OP, 3'b011};

				// R_TYPE Logic operation instrs
				`AND,`OR,`XOR,`NOR,`ADD,`ADDU,`SUB,`SUBU,`SLT,`SLTU,`SLL,
				`SRL,`SRA,`SLLV,`SRLV,`SRAV:
					 	controls <= {11'b1_1_0_0_0_0_0_0_0_0_0, `R_TYPE_OP, 3'b000};

				// Privileged instrs
				`BREAK,`SYSCALL:controls <= {11'b0_0_0_0_0_0_0_0_0_0_0,`USELESS_OP, 3'b000};

				default:invalid = 1;//illegal instr
				endcase

			`J:controls <=  {11'b0_0_0_0_0_0_1_0_0_0_0,`USELESS_OP,3'b000};
			`JAL:controls<= {11'b1_0_0_0_0_0_0_1_0_0_0,`USELESS_OP,3'b000};

			// branch instr
			`BEQ:controls<= {11'b0_0_0_1_0_0_0_0_0_0_0,`USELESS_OP,3'b000};
			`BNE:controls<= {11'b0_0_0_1_0_0_0_0_0_0_0,`USELESS_OP,3'b000};
			`BGTZ:controls<={11'b0_0_0_1_0_0_0_0_0_0_0,`USELESS_OP,3'b000};
			`BLEZ:controls<={11'b0_0_0_1_0_0_0_0_0_0_0,`USELESS_OP,3'b000};			
			`REGIMM_INST:case(rt)
				`BLTZ:controls<=  {11'b0_0_0_1_0_0_0_0_0_0_0,`USELESS_OP,3'b000};
				`BLTZAL:controls<={11'b1_0_0_1_0_0_0_0_0_1_0,`USELESS_OP,3'b000};
				`BGEZ:controls<=  {11'b0_0_0_1_0_0_0_0_0_0_0,`USELESS_OP,3'b000};
				`BGEZAL:controls<={11'b1_0_0_1_0_0_0_0_0_1_0,`USELESS_OP,3'b000};
				default:invalid = 1;//illegal op
				endcase

			//logic instr			
			`ANDI: controls <= {11'b1_0_1_0_0_0_0_0_0_0_0,`ANDI_OP,   3'b000};
			`XORI: controls <= {11'b1_0_1_0_0_0_0_0_0_0_0,`XORI_OP,   3'b000};
			`LUI:  controls <= {11'b1_0_1_0_0_0_0_0_0_0_0, `LUI_OP,   3'b000};
			`ORI:  controls <= {11'b1_0_1_0_0_0_0_0_0_0_0, `ORI_OP,   3'b000};
			`ADDI: controls <= {11'b1_0_1_0_0_0_0_0_0_0_0,`ADDI_OP,   3'b000};
			`ADDIU:controls <= {11'b1_0_1_0_0_0_0_0_0_0_0, `ADDIU_OP, 3'b000};
			`SLTI: controls <= {11'b1_0_1_0_0_0_0_0_0_0_0, `SLTI_OP,  3'b000};
			`SLTIU:controls <= {11'b1_0_1_0_0_0_0_0_0_0_0, `SLTIU_OP, 3'b000};

			// memory instr
			`LW: controls <= {11'b1_0_1_0_0_1_0_0_0_0_0,`MEM_OP,3'b100};
			`SW: controls <= {11'b0_0_1_0_1_0_0_0_0_0_0,`MEM_OP,3'b100};
			`LB:controls <=  {11'b1_0_1_0_0_1_0_0_0_0_0,`MEM_OP,3'b100};
			`LBU:controls <= {11'b1_0_1_0_0_1_0_0_0_0_0,`MEM_OP,3'b100};
			`LH:controls <=  {11'b1_0_1_0_0_1_0_0_0_0_0,`MEM_OP,3'b100};
			`LHU:controls <= {11'b1_0_1_0_0_1_0_0_0_0_0,`MEM_OP,3'b100};
			`SH:controls <=  {11'b0_0_1_0_1_0_0_0_0_0_0,`MEM_OP,3'b100};
			`SB:controls <=  {11'b0_0_1_0_1_0_0_0_0_0_0,`MEM_OP,3'b100};
			
			//mfc0 and mtc0
			`SPECIAL3_INST:case(rs)
				`MTC0:controls <= {11'b0_0_0_0_0_0_0_0_0_0_0,`MTC0_OP,    3'b000};
				`MFC0:controls <= {11'b1_0_0_0_0_0_0_0_0_0_0,`MFC0_OP,    3'b000};
				`ERET:controls <= {11'b1_0_0_0_0_0_0_0_0_0_0,`USELESS_OP, 3'b000};
				default: invalid=1;//illegal instrs
				endcase
			default: invalid=1;
			endcase
		end
		
	end
endmodule