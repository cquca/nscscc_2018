`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 15:12:22
// Design Name: 
// Module Name: datapath
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


module datapath(
	input wire clk,rst,
	//fetch stage
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	input wire stall_by_iram,
	//decode stage
	input wire [1:0] pcsrcD,
	input wire branchD,
	input wire jumpD,jrD,regwriteD,balD,invalidD,
	output wire equalD,
	output wire[31:0] instrD,
	//execute stage
	input wire memtoregE,
	input wire alusrcE,regdstE,
	input wire regwriteE,jalE,
	input wire[7:0] alucontrolE,
	output wire stallE,flushE,overflowE,
	//mem stage
	input wire memtoregM,
	input wire regwriteM,
	output wire[31:0] aluoutM,writedata2M,
	input wire[31:0] readdataM,
	output wire[3:0] selM,
	output wire adelM,adesM,flushM,
	//writeback stage
	input wire[5:0] int_i,
	input wire memtoregW,
	input wire regwriteW,jrW,is_in_slotW,
	output wire flushW
    );
	
	//fetch stage
	wire stallF,flushF;
	wire [7:0] exceptF;
	//FD
	wire [31:0] pcnextbrFD,pcnextFD,pcplus4F,pcbranchD,pcJrD,pcFlushD;
	//decode stage
	wire [7:0] exceptD;
	wire [31:0] pcplus4D;
	wire forwardaD,forwardbD,forwarda2D,forwardb2D;
	wire [5:0] opD,functD;
	wire [4:0] rsD,rtD,rdD;//
	wire flushD,stallD,brachFlushD; 
	wire syscallD,breakD,eretD;
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,src2aD,srca2D,srca3D,srcbD,src2bD,srcb2D,srcb3D;
	//execute stage
	wire [7:0] exceptE;
	wire hilo_writeE,cp0_writeE;
	wire [1:0] forwardaE,forwardbE,forwardHiLoE,forwardCP0E;
	wire [4:0] rsE,rtE,rdE;
	wire [4:0] writeregE,writereg2E;
	wire [31:0] signimmE,pcplus8E;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE,aluout2E,cp0_iE;
	wire [63:0] hilo_iE,hilo_oE,div_resultE;
	wire div_readyE,signed_divE,start_divE,stall_divE,jrE,balE;
	//mem stage
	wire [7:0] exceptM;
	wire [4:0] writeregM,rdM;
	wire hilo_writeM,cp0_writeM;
	wire [63:0] hiloM;
	wire [7:0] alucontrolM;
	wire[31:0] writedataM,readdata2M,pcplus8M,excepttypeM,cp0_statusM,cp0_causeM,bad_addrM;
	//writeback stage
	// wire [7:0] exceptW;
	wire hilo_writeW,cp0_writeW;
	wire [4:0] writeregW,rdW;
	wire [31:0] aluoutW,readdataW,resultW,pcplus8W,excepttypeW,
				cp0_oW,cp0_statusW,cp0_causeW,cp0_epcW,newpcW,bad_addrW;
	wire [63:0] hilo_iW,hilo_oW;

	//hazard detection
	hazard h(
		//fetch stage
		stall_by_iram,
		stallF,flushF,
		//decode stage
		rsD,rtD,
		brachFlushD,jumpD,
		forwardaD,forwardbD,forward2aD,forward2bD,forwarda2D,forwardb2D,
		stallD,flushD,
		//execute stage
		rsE,rtE,rdE,
		writeregE,
		regwriteE,
		memtoregE,
		forwardaE,forwardbE,forwardHiLoE,forwardCP0E,
		stallE,flushE,stall_divE,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		hilo_writeM,cp0_writeM,
		stallM,flushM,
		//write back stage
		writeregW,
		regwriteW,
		hilo_writeW,cp0_writeW,
		excepttypeW,cp0_epcW,
		newpcW,flushW
		);

	//next PC logic (operates in fetch an decode)
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD[0],pcnextbrFD);
	mux2 #(32) pcmux(pcnextbrFD,
		{pcplus4D[31:28],instrD[25:0],2'b00},
		pcsrcD[1],pcnextFD);
	mux2 #(32) pcjrmux(pcnextFD,srca3D,jrD,pcJrD);
	mux2 #(32) flushmux(pcJrD,newpcW,flushF,pcFlushD);
	// mux4 #(32) pcmux(pcplus4F,pcbranchD,{pcplus4D[31:28],instrD[25:0],2'b00},srcaD,pcsrcD,pcnextFD);
	//regfile (operates in decode and writeback)
	// mux2 #(1) rfmux1(regwriteW,regwriteD,alD[0],regwriteWD);
	// assign writeregD = (alD == 2'b01) ? 5'b11111 :
	// 					(alD == 2'b11) ? rdD : writeregW;
	// mux2 #(32) rfmux3(resultW,pcplus8W,jalW|jrW,resultWD);
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);

	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,pcFlushD,pcF);
	assign exceptF = (pcF[1:0] == 2'b00) ? 8'b00000000 : 8'b10000000;
	adder pcadd1(pcF,32'b100,pcplus4F);
	//decode stage
	
	assign brachFlushD = (branchD & !balD);

	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(8) r3D(clk,rst,~stallD,flushD,exceptF,exceptD);
	// assign instrD = ~stallD ? instrF : instrD;
	signext se(instrD[15:0],instrD[29:28],signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd2(pcplus4D,signimmshD,pcbranchD);
	mux2 #(32) forwardamux(srcaD,aluoutE,forwardaD,src2aD);
	mux2 #(32) forwardbmux(srcbD,aluoutE,forwardbD,src2bD);
	mux2 #(32) forward2amux(src2aD,aluoutM,forward2aD,srca2D);
	mux2 #(32) forward2bmux(src2bD,aluoutM,forward2bD,srcb2D);
	mux2 #(32) forwarda2mux(srca2D,readdata2M,forwarda2D,srca3D);
	mux2 #(32) forwardb2mux(srcb2D,readdata2M,forwardb2D,srcb3D);
	eqcmp comp(srca3D,srcb3D,opD,rtD,equalD);

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];

	assign syscallD = (opD == 6'b000000 && functD == 6'b001100);
	assign breakD = (opD == 6'b000000 && functD == 6'b001101);
	assign eretD = (instrD == 32'b01000010000000000000000000011000);
	//execute stage
	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc #(5) r4E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc #(5) r5E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc #(5) r6E(clk,rst,~stallE,flushE,rdD,rdE);
	flopenrc #(1) r7E(clk,rst,~stallE,flushE,jrD,jrE);
	flopenrc #(32) r8E(clk,rst,~stallE,flushE,pcplus4D+4,pcplus8E);
	flopenrc #(1) r9E(clk,rst,~stallE,flushE,balD,balE);
	flopenrc #(8) r10E(clk,rst,~stallE,flushE,
		{exceptD[7],syscallD,breakD,eretD,invalidD,exceptD[2:0]},
		exceptE);

	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux3 #(64) forwardhilomux(hilo_oW,hilo_iW,hiloM,forwardHiLoE,hilo_iE);
	mux3 #(32) forwardCP0mux(cp0_oW,aluoutW,aluoutM,forwardCP0E,cp0_iE);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	alu alu(
		srca2E,srcb3E,cp0_iE,alucontrolE,
		signimmE[10:6],aluoutE,
		hilo_iE,hilo_oE,hilo_writeE,cp0_writeE,overflowE,
		div_resultE,div_readyE,start_divE,signed_divE,stall_divE);
	div div(~clk,rst,signed_divE,srca2E,srcb3E,start_divE,1'b0,div_resultE,div_readyE);
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE);
	//
	mux2 #(5) wrmux2(writeregE,5'b11111,jalE|balE,writereg2E);
	mux2 #(32) wrmux3(aluoutE,pcplus8E,jalE|jrE|balE,aluout2E);
	
	//mem stage
	flopenrc #(32) r1M(clk,rst,~stallM,flushM,srcb2E,writedataM);
	flopenrc #(32) r2M(clk,rst,~stallM,flushM,aluout2E,aluoutM);
	flopenrc #(5) r3M(clk,rst,~stallM,flushM,writereg2E,writeregM);
	flopenrc #(1) r4M(clk,rst,~stallM,flushM,hilo_writeE,hilo_writeM);
	flopenrc #(64) r5M(clk,rst,~stallM,flushM,hilo_oE,hiloM);
	flopenrc #(8) r6M(clk,rst,~stallM,flushM,alucontrolE,alucontrolM);
	flopenrc #(1) r7M(clk,rst,~stallM,flushM,cp0_writeE,cp0_writeM);
	// flopenrc #(5) r8M(clk,rst,~stallM,flushM,rdE,rdM);
	flopenrc #(8) r9M(clk,rst,~stallM,flushM,{exceptE[7:3],overflowE,exceptE[1:0]},exceptM);
	flopenrc #(32) r10M(clk,rst,~stallM,flushM,pcplus8E,pcplus8M);

	memsel memsel(pcplus8M,alucontrolM,aluoutM,writedataM,readdataM,selM,writedata2M,readdata2M,bad_addrM,adelM,adesM);
	exception exception(rst,exceptM,adelM,adesM,cp0_statusM,cp0_causeM,excepttypeM);

	//writeback stage

	floprc #(32) r1W(clk,rst,flushW,aluoutM,aluoutW);
	floprc #(32) r2W(clk,rst,flushW,readdata2M,readdataW);
	floprc #(5) r3W(clk,rst,flushW,writeregM,writeregW);
	floprc #(1) r4W(clk,rst,flushW,hilo_writeM,hilo_writeW);
	floprc #(64) r5W(clk,rst,flushW,hiloM,hilo_iW);
	floprc #(1) r6W(clk,rst,flushW,cp0_writeM,cp0_writeW);
	// floprc #(5) r7W(clk,rst,flushW,rdM,rdW);
	floprc #(32) r8W(clk,rst,flushW,excepttypeM,excepttypeW);
	floprc #(32) r9W(clk,rst,flushW,pcplus8M,pcplus8W);
	floprc #(32) r10W(clk,rst,flushW,bad_addrM,bad_addrW);
	// floprc #(1) r10W(clk,rst,flushW,)
	hilo_reg hilo(clk,rst,hilo_writeW,hilo_iW[63:32],hilo_iW[31:0],hilo_oW[63:32],hilo_oW[31:0]);
	cp0_reg cp0_reg(clk,rst,cp0_writeW,writeregW,rdE,aluoutW,int_i,excepttypeW,pcplus8W-8,is_in_slotW,bad_addrW,cp0_oW,cp0_statusW,cp0_causeW,cp0_epcW);
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);
endmodule
