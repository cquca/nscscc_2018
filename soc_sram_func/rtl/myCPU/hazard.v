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
	//execute stage
	input wire[4:0] rsE,rtE,
	input wire stall_divE,
	output reg[1:0] forwardaE,forwardbE,forwardHiLoE,
	//mem stage
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire hilo_writeM,
	
	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW,
	input wire hilo_writeW,

	output wire stallF,stallD,stallE
	
    );


	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
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
	
endmodule
