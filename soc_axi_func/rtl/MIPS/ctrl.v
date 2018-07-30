`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/08/09 15:38:58
// Design Name: 
// Module Name: ctrl
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
module ctrl(
	input wire rst,
	input wire stallreq_from_id,
	input wire stallreq_from_ex,
	input wire stallreq_from_if,
	input wire stallreq_from_mem,

	input wire[`RegBus] excepttype_i,
	input wire[`RegBus] cp0_epc_i,

	output reg[`RegBus] new_pc,
	output reg flush,

	output reg[5:0] stall
    );

	always @(*) begin
		if(rst == `RstEnable) begin
			/* code */
			stall <= 6'b000000;
			flush <= 1'b0;
			new_pc <= `ZeroWord;
		end else if(excepttype_i != `ZeroWord) begin
			/* code */
			flush <= 1'b1;
			stall <= 6'b000000;
			case (excepttype_i)
				32'h00000001:begin 
					new_pc <= 32'hBFC00380;
				end
				32'h00000004:begin 
					new_pc <= 32'hBFC00380;

				end
				32'h00000005:begin 
					new_pc <= 32'hBFC00380;

				end
				32'h00000008:begin 
					new_pc <= 32'hBFC00380;
					// new_pc <= 32'h00000040;
				end
				32'h00000009:begin 
					new_pc <= 32'hBFC00380;

				end
				32'h0000000a:begin 
					new_pc <= 32'hBFC00380;

				end
				32'h0000000c:begin 
					new_pc <= 32'hBFC00380;

				end
				32'h0000000d:begin 
					new_pc <= 32'hBFC00380;

				end
				32'h0000000e:begin 
					new_pc <= cp0_epc_i;

				end
				default : /* default */;
			endcase
		end else if(stallreq_from_mem == `Stop) begin
			/* code */
			stall <= 6'b011111;
			flush <= 1'b0;
		end else if(stallreq_from_ex == `Stop) begin
			/* code */
			stall <= 6'b001111;
			flush <= 1'b0;
		end else if(stallreq_from_id == `Stop) begin
			/* code */
			stall <= 6'b000111;
			flush <= 1'b0;
		end else if(stallreq_from_if == `Stop) begin
			/* code */
			stall <= 6'b000111;
			flush <= 1'b0;
		end else begin 
			stall <= 6'b000000;
			flush <= 1'b0;
			new_pc <= `ZeroWord;
		end
	
	end
endmodule
