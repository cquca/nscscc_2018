`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/08/02 16:06:17
// Design Name: 
// Module Name: mycpu
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


module mycpu(
	input wire clk,resetn,
	input wire[5:0] int,
	
	//cpu inst sram
	output wire        inst_sram_en,
	output wire [3 :0] inst_sram_wen,
	output wire [31:0] inst_sram_addr,
	output wire [31:0] inst_sram_wdata,
	input wire [31:0] inst_sram_rdata,
	//cpu data sram
	output wire        data_sram_en,
	output wire [3 :0] data_sram_wen,
	output wire [31:0] data_sram_addr,
	output wire [31:0] data_sram_wdata,
	input wire [31:0] data_sram_rdata,

	//debug signals
	output wire [31:0] debug_wb_pc,
	output wire [3 :0] debug_wb_rf_wen,
	output wire [4 :0] debug_wb_rf_wnum,
	output wire [31:0] debug_wb_rf_wdata

    );


	//fetch stage signal
	wire [31:0] pcF,pc_nextF;
	wire[12:0] controlsD;
	wire[4:0] rsD,rtD,rdD,alucontrolD;

	//decode stage signal
	wire[31:0] rf_outaD,rf_outbD;
	wire[31:0] srcaD,srcbD,extend_immD,pcD;

	//exe stage signal
	wire[31:0] pcE,aluoutE;
	wire[4:0] writeregE;

	
	//next PC logic (operates in fetch an decode)
	pc_next pc_next(
   		.pc(pcF), //from fetch stage
		.inst(inst_sram_rdata), //from decode stage
    	.signal(),//wait to finish
    	.pc_next(pc_nextF) // to fetch stage
    );

	//fetch stage logic
	fetch_stage fetch_stage(
		.clk(clk),
		.resetn(resetn),
		.stall(1'b0), //wait to finish
		.pc_next(pc_nextF),

		.inst_sram_addr(inst_sram_addr),//pc_next if not stall and flush
		.pc(pcF)
	);
		//iram control
	assign inst_sram_en = 1'b1;
	assign inst_sram_wen = 4'b0000;
	assign inst_sram_wdata = 32'b0;

	//decode stage logic

	decode_stage decode_stage(
    	.clk(clk),
		.resetn(resetn),
		.pc(pcF),
		.inst(inst_sram_rdata),
		.controls(controlsD),
		.alucontrol(alucontrolD),
		.rs(rsD),
		.rt(rtD),
		.rd(rdD),
		.pc_next(pcD),
		.rf_outa(rf_outaD),
		.rf_outb(rf_outbD),
		.srca(srcaD),
		.srcb(srcbD),
		.extend_imm(extend_immD)

    );

	// regfile
	regfile regfile(
		.clk(clk),
		.we3(), //regwrite
		.ra1(inst_sram_rdata[25:21]), // rs
		.ra2(inst_sram_rdata[20:16]), // rt
		.wa3(),	//
		.wd3(),	//
		.rd1(rf_outaD),	//
		.rd2(rf_outbD)	//
    );

	// exe stage
	exe_stage exe_stage(
    	.clk(clk),
		.resetn(resetn),
    	.pc(pcD),
		.srca(srcaD),
		.srcb(srcbD),
		.extend_imm(extend_immD),
		.controls(controlsD),
		.alucontrol(alucontrolD),
   		.rs(rsD),
		.rt(rtD),
		.rd(rdD),
    	.aluout(aluoutE),
    	.writereg(writeregE),
		.pc_next(pcE)

    );
	
	//mem stage
	mem_stage mem_stage(
		.clk(clk),
		.resetn(resetn),
		.pc(pcE),
    	.mem_read(),
		.aluout(aluoutE),
   		.writereg(writeregE),
    	.result(),
    	.writereg_next()
    );

	//writeback stage
	wb_stage wb_stage(
		
    );

	// hazard module


endmodule
