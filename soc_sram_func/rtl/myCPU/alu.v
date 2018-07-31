`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
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
module alu(
	input wire[31:0] a,b,cp0_i,
	input wire[7:0] op,
	input wire[4:0] sa,
	output reg[31:0] y,
	input wire[63:0] hilo_i,
	output reg[63:0] hilo_o,
	// output reg overflow,
	output wire hilo_write,cp0_write,overflow,
	input wire[63:0] div_result,
	input wire div_ready,
	output reg start_div,signed_div,stall_div
    );

	wire[31:0] s,bout,mult_a,mult_b;
	wire[63:0] hilo_temp;
	wire a_lt_b;
	
	assign bout = ((op == `EXE_SUB_OP)|
					(op == `EXE_SUBU_OP)|
					(op == `EXE_SLT_OP)) ? (~b + 1) : b;
	assign s = a + bout;
	assign a_lt_b = (op == `EXE_SLT_OP) ? (
		(a[31] && !b[31]) || (!a[31] && !b[31] && s[31]) ||
		(a[31] && b[31] && s[31])) : (a < b);
	assign mult_a = ((op == `EXE_MULT_OP) && (a[31] == 1'b1)) ? (~a + 1) : a;
	assign mult_b = ((op == `EXE_MULT_OP) && (b[31] == 1'b1)) ? (~b + 1) : b;
	assign hilo_temp = ((op == `EXE_MULT_OP) && (a[31] ^ b[31] == 1'b1)) ?
						~(mult_a * mult_b) + 1 : mult_a * mult_b; 
	assign overflow = ((op == `EXE_ADD_OP) || (op == `EXE_ADDI_OP) || (op == `EXE_SUB_OP))
						&& ((!a[31] && !bout[31] && s[31]) || (a[31] && bout[31] && !s[31]));
	always @(*) begin
		case (op)
			//memory inst
			`EXE_LB_OP,`EXE_LBU_OP,`EXE_LH_OP,`EXE_LHU_OP,`EXE_LW_OP,`EXE_SB_OP,`EXE_SH_OP,`EXE_SW_OP:y <= s;
			//logic inst
			`EXE_AND_OP: y <= a & b;
			`EXE_OR_OP: y <= a | b;
			`EXE_XOR_OP: y <= a ^ b;
			`EXE_NOR_OP: y <= ~(a | b);
			`EXE_LUI_OP: y <= {b[15:0],b[31:16]};
			//shift inst
			`EXE_SLL_OP: y <= b << sa;
			`EXE_SRL_OP: y <= b >> sa;
			`EXE_SRA_OP: y <= ({32{b[31]}} << (6'd32-{1'b0,sa})) | b >> sa;
			`EXE_SLLV_OP: y <= b << a[4:0];
			`EXE_SRLV_OP: y <= b >> a[4:0];
			`EXE_SRAV_OP: y <= ({32{b[31]}} << (6'd32-{1'b0,a[4:0]})) | b >> a[4:0];
			//move inst
			`EXE_MTHI_OP:hilo_o <= {a,hilo_i[31:0]};
			`EXE_MTLO_OP:hilo_o <= {hilo_i[63:32],a};
			`EXE_MFHI_OP: y <= hilo_i[63:32];
			`EXE_MFLO_OP: y <= hilo_i[31:0];
			//arithmetic inst
			`EXE_ADD_OP,`EXE_ADDU_OP,`EXE_ADDI_OP,`EXE_ADDIU_OP,`EXE_SUB_OP,`EXE_SUBU_OP: y <= s;
			`EXE_SLT_OP,`EXE_SLTU_OP: y <= a_lt_b;
			`EXE_MULT_OP,`EXE_MULTU_OP: hilo_o <= hilo_temp;
			`EXE_DIV_OP,`EXE_DIVU_OP: hilo_o <= div_result;

			`EXE_MTC0_OP: y <= b;
			`EXE_MFC0_OP: y <= cp0_i;
			// 2'b00: y <= a & bout;
			// 2'b01: y <= a | bout;
			// 2'b10: y <= s;
			// 2'b11: y <= s[31];
			default : y <= `ZeroWord;
		endcase	
	end
	always @* begin
		start_div <= 1'b0;
		signed_div <= 1'b0;
		stall_div <= 1'b0;
		case (op)
			`EXE_DIV_OP:begin 
				if(div_ready == 1'b0) begin
					/* code */
					start_div <= 1'b1;
					signed_div <= 1'b1;
					stall_div <= 1'b1;
				end else if(div_ready == 1'b1) begin
					/* code */
					start_div <= 1'b0;
					signed_div <= 1'b1;
					stall_div <= 1'b0;
				end else begin 
					start_div <= 1'b0;
					signed_div <= 1'b1;
					stall_div <= 1'b0;
				end
			end
			`EXE_DIVU_OP:begin 
				if(div_ready == 1'b0) begin
					/* code */
					start_div <= 1'b1;
					signed_div <= 1'b0;
					stall_div <= 1'b1;
				end else if(div_ready == 1'b1) begin
					/* code */
					start_div <= 1'b0;
					signed_div <= 1'b0;
					stall_div <= 1'b0;
				end else begin 
					start_div <= 1'b0;
					signed_div <= 1'b0;
					stall_div <= 1'b0;
				end
			end
			default : /* default */;
		endcase	end
	assign hilo_write = (op == `EXE_MTHI_OP) | (op == `EXE_MTLO_OP)
						|(op == `EXE_MULT_OP) | (op == `EXE_MULTU_OP)
						|(((op == `EXE_DIV_OP) | (op == `EXE_DIVU_OP)) & (div_ready == 1'b1));
	assign cp0_write = (op == `EXE_MTC0_OP);
	assign zero = (y == `ZeroWord);

	// always @(*) begin
	// 	case (op[2:1])
	// 		2'b01:overflow <= a[31] & b[31] & ~s[31] |
	// 						~a[31] & ~b[31] & s[31];
	// 		2'b11:overflow <= ~a[31] & b[31] & s[31] |
	// 						a[31] & ~b[31] & ~s[31];
	// 		default : overflow <= 1'b0;
	// 	endcase	
	// end
endmodule
