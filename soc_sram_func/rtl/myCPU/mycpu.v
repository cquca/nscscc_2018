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
	wire stallF;
	

	//decode stage signal
	wire[12:0] controlsD;
	wire[4:0] rsD,rtD,rdD,saD,alucontrolD;
	wire[31:0] rf_outaD,rf_outbD;
	wire[31:0] srcaD,srcbD,extend_immD,pcD;
	wire stallD;

	//exe stage signal
	wire[31:0] pcE,aluoutE;
	wire[4:0] writeregE,rsE,rtE;
	wire [1:0] controlsE;
		//forward
	wire[1:0] forwardaE,forwardbE,forwardHiLoE;
	wire[63:0] hiloE;
	wire hilo_writeE;
		//div
	wire[63:0] div_resultE;
	wire div_readyE,start_divE,signed_divE,stall_divE;
    wire[31:0] div_srcaE,div_srcbE;
	wire stallE;

	//mem stage signal
	wire[31:0] pcM,resultM;
	wire[4:0] writeregM;
	wire controlsM;
	wire[63:0] hiloM;
	wire hilo_writeM;

	//wb stage signal
	wire[31:0] resultW;
	wire[4:0] writeregW;
	wire regwriteW;
	wire[63:0] hiloW;
	wire hilo_writeW;

	wire [63:0] hiloReg;

	
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
		.stall(stallF), //wait to finish
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
		.stall(stallD),
		.pc(pcF),
		.inst(inst_sram_rdata),
		.controls(controlsD),
		.alucontrol(alucontrolD),
		.rs(rsD),
		.rt(rtD),
		.rd(rdD),
		.sa(saD),
		.pc_next(pcD),
		.rf_outa(rf_outaD),
		.rf_outb(rf_outbD),
		.srca(srcaD),
		.srcb(srcbD),
		.extend_imm(extend_immD)

    );

	// exe stage
	exe_stage exe_stage(
    	.clk(clk),
		.resetn(resetn),
		.stall(stallE),
    	.pc(pcD),
		.srca(srcaD),
		.srcb(srcbD),
		.extend_imm(extend_immD),
		.controls({controlsD[12:10],controlsD[8:7],controlsD[2]}),
		.alucontrol(alucontrolD),
   		.rs(rsD),
		.rt(rtD),
		.rd(rdD),
		.sa(saD),

		//forward
    	.forwardaE(forwardaE),
		.forwardbE(forwardbE),
    	.resultM(resultM),
		.resultW(resultW),

    	.aluout(aluoutE),
    	.writereg(writeregE),
		.rs_next(rsE),
		.rt_next(rtE),
		.pc_next(pcE),
		.controls_next(controlsE),

		.hilo(hiloReg),
		.hiloM(hiloM),
		.hiloW(hiloW),
		.forwardhilo(forwardHiLoE),
		.hilo_write(hilo_writeE),
		.hilo_next(hiloE),

		//div
    	.div_result(div_resultE),
		.div_ready(div_readyE),
		.start_div(start_divE),
		.signed_div(signed_divE),
		.stall_div(stall_divE),
		.div_srca(div_srcaE),
		.div_srcb(div_srcbE)

    );

	div div(
    	.clk(clk),
		.resetn(resetn),
	
		.signed_div_i(signed_divE),
		.opdata1_i(div_srcaE),
		.opdata2_i(div_srcbE),
		.start_i(start_divE),
		.annul_i(1'b0),
	
		.result_o(div_resultE),
		.ready_o(div_readyE)
);
	
	//mem stage
	mem_stage mem_stage(
		.clk(clk),
		.resetn(resetn),
		.pc(pcE),
    	.mem_read(),
		.aluout(aluoutE),
   		.writereg(writeregE),
		.controls(controlsE),
		.pc_next(pcM),
    	.result(resultM),
    	.writereg_next(writeregM),
		.controls_next(controlsM),

		.hilo_write(hilo_writeE),
		.hilo(hiloE),
		.hilo_write_next(hilo_writeM),
		.hilo_next(hiloM)
    );

	//writeback stage
	wb_stage wb_stage(
		.clk(clk),
		.resetn(resetn),
   		.pc(pcM),
	   	.result(resultM),
		.writereg(writeregM),
		.controls(controlsM),
		.pc_next(),
		.result_next(resultW),
		.writereg_next(writeregW),
		.regwrite(regwriteW),

		.hilo_write(hilo_writeM),
		.hilo(hiloM),
		.hilo_write_next(hilo_writeW),
		.hilo_next(hiloW)
    );

	// hazard module
	hazard hazard(
	//execute stage
		.rsE(rsE),
		.rtE(rtE),
		.stall_divE(stall_divE),
		.forwardaE(forwardaE),
		.forwardbE(forwardbE),
		.forwardHiLoE(forwardHiLoE),
	//mem stage
		.writeregM(writeregM),
		.regwriteM(controlsM),
		.hilo_writeM(hilo_writeM),
	
	//write back stage
		.writeregW(writeregW),
		.regwriteW(regwriteW),
		.hilo_writeW(hilo_writeW),

		.stallF(stallF),
		.stallD(stallD),
		.stallE(stallE)
	
    );


	// regfile
	regfile regfile(
		.clk(clk),
		.we3(regwriteW), //regwrite
		.ra1(inst_sram_rdata[25:21]), // rs
		.ra2(inst_sram_rdata[20:16]), // rt
		.wa3(writeregW),	//
		.wd3(resultW),	//
		.rd1(rf_outaD),	//
		.rd2(rf_outbD)	//
    );
	
	//hilo reg
	hilo_reg hilo_reg(
		.clk(clk),
		.resetn(resetn),
		.we(hilo_writeW),
		.hi(hiloW[63:32]),
		.lo(hiloW[31:0]),
		.hi_o(hiloReg[63:32]),
		.lo_o(hiloReg[31:0])
    );

endmodule
