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
	//fetch stage
	input wire stall_by_iram,
	output wire stallF,flushF,
	//decode stage
	input wire[4:0] rsD,rtD,
	input wire branchD,jumpD,
	output wire forwardaD,forwardbD,forward2aD,forward2bD,forwarda2D,forwardb2D,
	output wire stallD,flushD,
	//execute stage
	input wire[4:0] rsE,rtE,rdE,
	input wire[4:0] writeregE,
	input wire regwriteE,
	input wire memtoregE,
	output reg[1:0] forwardaE,forwardbE,forwardHiLoE,forwardCP0E,
	output wire stallE,flushE,
	input wire stall_divE,
	//mem stage
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire memtoregM,
	input wire hilo_writeM,cp0_writeM,
	output wire stallM,flushM,
	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW,
	input wire hilo_writeW,cp0_writeW,
	input wire[31:0] excepttypeW,cp0_epcW,
	output reg[31:0] newpcW,
	output wire flushW
    );

	wire lwstallD,branchstallE,flush_except;
	//forwarding sources to D stage (branch equality)
	assign forwardaD = (rsD != 0 & rsD == writeregE & regwriteE);
	assign forwardbD = (rtD != 0 & rtD == writeregE & regwriteE);
	
	assign forward2aD = (rsD != 0 & rsD == writeregM & rsD != writeregE & regwriteM);
	assign forward2bD = (rtD != 0 & rtD == writeregM & rtD != writeregE & regwriteM);

	assign forwarda2D = (rsD != 0 & rsD == writeregM & memtoregM);
	assign forwardb2D = (rtD != 0 & rtD == writeregM & memtoregM);
	//forwarding sources to E stage (ALU)

	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
		forwardHiLoE = 2'b00;
		forwardCP0E = 2'b00;
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
		if(rdE == writeregM & cp0_writeM) begin
			/* code */
			forwardCP0E = 2'b10;
		end else if(rdE == writeregW & cp0_writeW) begin
			/* code */
			forwardCP0E = 2'b01;
		end
	end
	assign flush_except = (excepttypeW != 32'b0);
	//exception
	always @(*) begin
		if(excepttypeW != 32'b0) begin
			/* code */
			case (excepttypeW)
				32'h00000001:begin 
					newpcW <= 32'hBFC00380;
				end
				32'h00000004:begin 
					newpcW <= 32'hBFC00380;

				end
				32'h00000005:begin 
					newpcW <= 32'hBFC00380;

				end
				32'h00000008:begin 
					newpcW <= 32'hBFC00380;
					// new_pc <= 32'h00000040;
				end
				32'h00000009:begin 
					newpcW <= 32'hBFC00380;

				end
				32'h0000000a:begin 
					newpcW <= 32'hBFC00380;

				end
				32'h0000000c:begin 
					newpcW <= 32'hBFC00380;

				end
				32'h0000000d:begin 
					newpcW <= 32'hBFC00380;

				end
				32'h0000000e:begin 
					newpcW <= cp0_epcW;
				end
				default : /* default */;
			endcase
		end
	
	end

	//stalls
	assign #1 flushF = flush_except;
	assign #1 lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
	// assign #1 branchstallD = branchD &
	// 			(regwriteE & 
	// 			(writeregE == rsD | writeregE == rtD) |
	// 			memtoregM &
	// 			(writeregM == rsD | writeregM == rtD));
	assign #1 flushD = flush_except;
	assign #1 stallD = lwstallD | stall_divE | stall_by_iram;//| branchstallD
	assign #1 stallF = (stall_by_iram & !flushF) | stallD ;
		//stalling D stalls all previous stages
	assign #1 flushE = flush_except;//jumpD | branchD | | branchstallD
	assign #1 stallE = lwstallD | stall_divE | stall_by_iram;
	assign #1 flushM = flush_except;
	assign #1 stallM = stall_divE;
	assign #1 flushW = flush_except;
		//stalling D flushes next stage
	// Note: not necessary to stall D stage on store
  	//       if source comes from load;
  	//       instead, another bypass network could
  	//       be added from W to M
endmodule
