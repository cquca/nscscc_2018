`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/08/02 18:32:25
// Design Name: 
// Module Name: mem_stage
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
module mem_stage(
    input wire clk,resetn,
    input wire stall,
    input wire[5:0] op,
    input wire[31:0] pc,mem_read,aluout,
    input wire[4:0] writereg,
    input wire[1:0] controls,
    output wire[31:0] pc_next,result,
    output reg[4:0] writereg_next,
    output wire controls_next,

    input wire hilo_write,
    input wire[63:0] hilo,
    output reg hilo_write_next,
    output reg[63:0] hilo_next
    );

    reg[31:0] pcM,aluoutM,mem_readM;
    reg[1:0] controlsM;
	reg[5:0] opM;

    always @(posedge clk) begin
        if (~resetn) begin
            pcM <= 32'hbfc00000;
            aluoutM <= 32'b0;
            writereg_next <= 5'b0;
            controlsM <= 2'b0;
            hilo_next <= 64'b0;
            hilo_write_next <= 1'b0;
			opM <= 5'b0;
        end else if(~stall) begin
            pcM <= pc;
            aluoutM <= aluout;
            writereg_next <= writereg;
            controlsM <= controls;
            hilo_next <= hilo;
            hilo_write_next <= hilo_write;
			opM <= op;
        end
      
    end
    
    assign result = controlsM[0] ? mem_readM : aluoutM;
    assign controls_next = controlsM[1];
    assign pc_next = pcM;


    always @(*) begin
		case (opM)
			`LW:begin 
				if(aluoutM[1:0] == 2'b00) begin
					/* code */
					mem_readM <= mem_read;
				end
			end
			`LB:begin 
				case (aluoutM[1:0])
					2'b11: mem_readM <= {{24{mem_read[31]}},mem_read[31:24]};
					2'b10: mem_readM <= {{24{mem_read[23]}},mem_read[23:16]};
					2'b01: mem_readM <= {{24{mem_read[15]}},mem_read[15:8]};
					2'b00: mem_readM <= {{24{mem_read[7]}},mem_read[7:0]};
					default : /* default */;
				endcase
			end
			`LBU:begin 
				case (aluoutM[1:0])
					2'b11: mem_readM <= {{24{1'b0}},mem_read[31:24]};
					2'b10: mem_readM <= {{24{1'b0}},mem_read[23:16]};
					2'b01: mem_readM <= {{24{1'b0}},mem_read[15:8]};
					2'b00: mem_readM <= {{24{1'b0}},mem_read[7:0]};
					default : /* default */;
				endcase
			end
			`LH:begin 
				case (aluoutM[1:0])
					2'b10: mem_readM <= {{16{mem_read[31]}},mem_read[31:16]};
					2'b00: mem_readM <= {{16{mem_read[15]}},mem_read[15:0]};
					default : ;
				endcase
			end
			`LHU:begin 
				case (aluoutM[1:0])
					2'b10: mem_readM <= {{16{1'b0}},mem_read[31:16]};
					2'b00: mem_readM <= {{16{1'b0}},mem_read[15:0]};
					default : ;
				endcase
			end
			default : mem_readM <= 32'b0;
		endcase
	end

    

endmodule
