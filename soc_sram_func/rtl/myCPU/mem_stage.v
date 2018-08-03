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
    input wire[1:0] controls,
    output wire[31:0] pc_next,result,
    output reg[4:0] writereg_next,
    output wire controls_next,

    input wire hilo_write,
    input wire[63:0] hilo,
    output reg hilo_write_next,
    output reg[63:0] hilo_next
    );

    reg[31:0] pcM,aluoutM;
    reg[1:0] controlsM;

    always @(posedge clk) begin
        if (~resetn) begin
            pcM <= 32'hbfc00000;
            aluoutM <= 32'b0;
            writereg_next <= 5'b0;
            controlsM <= 2'b0;
            hilo_next <= 64'b0;
            hilo_write_next <= 1'b0;
        end else begin
            pcM <= pc;
            aluoutM <= aluout;
            writereg_next <= writereg;
            controlsM <= controls;
            hilo_next <= hilo;
            hilo_write_next <= hilo_write;
        end
      
    end
    
    assign result = controlsM[0] ? mem_read : aluoutM;
    assign controls_next = controlsM[1];
    assign pc_next = pcM;

    

endmodule
