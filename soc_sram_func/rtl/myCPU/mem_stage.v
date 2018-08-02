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


module mem_stage(
    input wire clk,resetn,
    input wire[31:0] pc,mem_read,aluout,
    input wire[4:0] writereg,
    output wire[31:0] result,
    output reg[4:0] writereg_next
    );

    reg[31:0] pcM,aluoutM;

    always @(posedge clk) begin
        if (~resetn) begin
            pcM <= 32'hbfc00000;
            aluoutM <= 32'b0;
            writereg_next <= 5'b0;
          
        end else begin
            pcM <= pc;
            aluoutM <= aluout;
            writereg_next <= writereg;
          
        end
      
    end


endmodule
