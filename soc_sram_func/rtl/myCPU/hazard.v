`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/22 10:23:13
// Design Name: 
// Module Name: hazard
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


module hazard(
	//decode stage
	input wire[4:0] rsD,rtD,
	output reg[1:0] forwardaD,forwardbD,

	//execute stage
	input wire[4:0] rsE,rtE,
	input wire stall_divE,
	output reg[1:0] forwardaE,forwardbE,forwardHiLoE,

	input wire[4:0] writeregE,
	input wire regwriteE,
	//mem stage
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire hilo_writeM,
	
	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW,
	input wire hilo_writeW,

	output wire stallF,stallD,stallE,stallM,stallW
	
    );

	//forwarding sources to D stage (branch equality)

	always @(*) begin
		forwardaD = 2'b00;
		forwardbD = 2'b00;

		if(rsD != 0) begin
			/* code */
			if(rsD == writeregE & regwriteE) begin
				/* code */
				forwardaD = 2'b10;
			end else if(rsD == writeregM & regwriteM & rsD != writeregE) begin
				/* code */
				forwardaD = 2'b01;
			end
		end
		if(rtD != 0) begin
			/* code */
			if(rtD == writeregE & regwriteE) begin
				/* code */
				forwardbD = 2'b10;
			end else if(rtD == writeregM & regwriteM & rtD != writeregE) begin
				/* code */
				forwardbD = 2'b01;
			end
		end

	end
	
	//forwarding sources to E stage (ALU)
	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
		forwardHiLoE = 2'b00;

		if(rsE != 0) begin
			/* code */
			if(rsE == writeregM & regwriteM) begin
				/* code */
				forwardaE = 2'b10;
			end else if(rsE == writeregW & regwriteW) begin
				/* code */
				forwardaE = 2'b01;
			end
		end
		if(rtE != 0) begin
			/* code */
			if(rtE == writeregM & regwriteM) begin
				/* code */
				forwardbE = 2'b10;
			end else if(rtE == writeregW & regwriteW) begin
				/* code */
				forwardbE = 2'b01;
			end
		end

		if(hilo_writeM) begin
			/* code */
			forwardHiLoE = 2'b10;
		end else if(hilo_writeW) begin
			/* code */
			forwardHiLoE = 2'b01;
		end
	end


	assign stallF = stall_divE;
	assign stallD = stall_divE;
	assign stallE = stall_divE;
	assign stallM = 1'b0;
	assign stallW = 1'b0;
endmodule
