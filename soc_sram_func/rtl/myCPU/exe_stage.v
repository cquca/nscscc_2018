`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/08/02 18:17:35
// Design Name: 
// Module Name: exe_stage
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
module exe_stage(
    input wire clk,resetn,
    input wire[31:0] pc,srca,srcb,extend_imm,
    input wire[12:0] controls,
    input wire[4:0] alucontrol,
    input wire[4:0] rs,rt,rd,
    output reg[31:0] aluout,
    output wire[4:0] writereg,
    output wire[31:0] pc_next

    );
    reg[31:0] pcE,srcaE,srcbE,extend_immE;
    reg[4:0] rsE,rtE,rdE,alucontrolE;
    reg[12:0] controlsE;

    wire[31:0] alu_srca,alu_srcb;
    always @(posedge clk) begin
        if (~resetn) begin
            pcE <= 32'hbfc00000;
            srcaE <= 32'b0;
            srcbE <= 32'b0;
            extend_immE <= 32'b0;
            rsE <= 5'b0;
            rtE <= 5'b0;
            rdE <= 5'b0;
            controlsE <= 13'b0;
            alucontrolE <= 5'b11111;
          
        end else begin
            pcE <= pc;
            srcaE <= srca;
            srcbE <= srcb;
            extend_immE <= extend_imm;
            rsE <= rs;
            rtE <= rt;
            rdE <= rd;
            controlsE <= controls;
            alucontrolE <= alucontrol;
        end
      
    end

    assign pc_next = pcE;
    assign writereg = controlsE[11] ? rdE : rtE;
    assign alu_srca = srcaE;
    assign alu_srcb = controlsE[10] ? extend_immE : srcbE;

    always @(*) begin
		case (alucontrolE)
			`OR_CONTROL: aluout <= alu_srca | alu_srcb;
			
			default : aluout <= 32'b0;
		endcase	
	end

endmodule
