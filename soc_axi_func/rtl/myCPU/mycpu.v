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
	input wire[5:0] int,
	input wire aclk,aresetn,
	
	 // axi port
    //ar
    output wire[3:0] arid,      //read request id, fixed 4'b0
    output wire[31:0] araddr,   //read request address
    output wire[7:0] arlen,     //read request transfer length(beats), fixed 4'b0
    output wire[2:0] arsize,    //read request transfer size(bytes per beats)
    output wire[1:0] arburst,   //transfer type, fixed 2'b01
    output wire[1:0] arlock,    //atomic lock, fixed 2'b0
    output wire[3:0] arcache,   //cache property, fixed 4'b0
    output wire[2:0] arprot,    //protect property, fixed 3'b0
    output wire arvalid,        //read request address valid
    input wire arready,         //slave end ready to receive address transfer
    //r              
    input wire[3:0] rid,        //equal to arid, can be ignored
    input wire[31:0] rdata,     //read data
    input wire[1:0] rresp,      //this read request finished successfully, can be ignored
    input wire rlast,           //the last beat data for this request, can be ignored
    input wire rvalid,          //read data valid
    output wire rready,         //master end ready to receive data transfer
    //aw           
    output wire[3:0] awid,      //write request id, fixed 4'b0
    output wire[31:0] awaddr,   //write request address
    output wire[3:0] awlen,     //write request transfer length(beats), fixed 4'b0
    output wire[2:0] awsize,    //write request transfer size(bytes per beats)
    output wire[1:0] awburst,   //transfer type, fixed 2'b01
    output wire[1:0] awlock,    //atomic lock, fixed 2'b01
    output wire[3:0] awcache,   //cache property, fixed 4'b01
    output wire[2:0] awprot,    //protect property, fixed 3'b01
    output wire awvalid,        //write request address valid
    input wire awready,         //slave end ready to receive address transfer
    //w          
    output wire[3:0] wid,       //equal to awid, fixed 4'b0
    output wire[31:0] wdata,    //write data
    output wire[3:0] wstrb,     //write data strobe select bit
    output wire wlast,          //the last beat data signal, fixed 1'b1
    output wire wvalid,         //write data valid
    input wire wready,          //slave end ready to receive data transfer
    //b              
    input  wire[3:0] bid,       //equal to wid,awid, can be ignored
    input  wire[1:0] bresp,     //this write request finished successfully, can be ignored
    input wire bvalid,          //write data valid
    output wire bready,          //master end ready to receive write response

	//debug signals
	output wire [31:0] debug_wb_pc,
	output wire [3 :0] debug_wb_rf_wen,
	output wire [4 :0] debug_wb_rf_wnum,
	output wire [31:0] debug_wb_rf_wdata

    );


	//fetch stage signal
	wire [31:0] pcF,pc_nextF,newpcF;
	wire stallF;
	

	//decode stage signal
	wire[12:0] controlsD;
	wire[4:0] rsD,rtD,rdD,saD,alucontrolD;
	wire[31:0] rf_outaD,rf_outbD;
	wire[31:0] srcaD,srcbD,extend_immD,pcD,jr_srcD,instD;
	wire stallD;
	wire branchD;
	wire[5:0] opD;
		//forward
	wire[1:0] forwardaD,forwardbD;
	
	wire [7:0] exception_codeD;
	wire is_in_slotD;

	//exe stage signal
	wire[31:0] pcE,aluoutE,badaddrE,mem_write_dataE;
	wire[4:0] writeregE,rsE,rtE,rdE;
	wire [3:0] controlsE;
	wire[5:0] opE;
	wire flushE;
	wire [7:0] exception_codeE;
	wire is_in_slotE;

		//forward
	wire[1:0] forwardaE,forwardbE,forwardHiLoE,forwardCP0E;
	wire[63:0] hiloE;
	wire hilo_writeE,cp0_writeE;
		//div
	wire[63:0] div_resultE;
	wire div_readyE,start_divE,signed_divE,stall_divE;
    wire[31:0] div_srcaE,div_srcbE;
	wire stallE;
		//cp0
	wire[31:0] cp0_srcE;

	//mem stage signal
	wire[31:0] pcM,resultM,excepttypeM,badaddrM;
	wire[4:0] writeregM;
	wire controlsM;
	wire[63:0] hiloM;
	wire hilo_writeM,cp0_writeM;
	wire stallM;
	wire[31:0] cp0_statusE,cp0_causeE,cp0_epcM;
	wire is_in_slotM;


	//wb stage signal
	wire[31:0] resultW;
	wire[4:0] writeregW;
	wire regwriteW;
	wire[63:0] hiloW;
	wire hilo_writeW,cp0_writeW;

	wire [63:0] hiloReg;
	wire stallW;

	wire flushALL;

	//cache mux signal
	wire cache_miss,sel_i;
	wire[31:0] i_addr,d_addr,m_addr;
	wire m_fetch,m_ld_st,mem_access;
	wire mem_write,m_st;
	wire mem_ready,m_i_ready,m_d_ready,i_ready,d_ready;
	wire[31:0] mem_st_data,mem_data;
	wire[1:0] mem_size,d_size;// size not use
	wire[3:0] m_sel;
	wire stallreq_from_if,stallreq_from_mem;

	//sram signal
	//cpu inst sram
	wire        inst_sram_en;
	wire [3 :0] inst_sram_wen;
	wire [31:0] inst_sram_addr;
	wire [31:0] inst_sram_wdata;
	wire [31:0] inst_sram_rdata;
	//cpu data sram
	wire        data_sram_en,data_sram_write;
	wire [3 :0] data_sram_wen;
	wire [31:0] data_sram_addr;
	wire [31:0] data_sram_wdata;
	wire [31:0] data_sram_rdata;




	//next PC logic (operates in fetch an decode)
	pc_next pc_next(
   		.pc(pcF), //from fetch stage
		.inst(instD), //from decode stage
    	.signal({branchD,controlsD[6],controlsD[4]}),//wait to finish
		.jr_src(jr_srcD),
    	.pc_next(pc_nextF) // to fetch stage
    );

	//fetch stage logic
	fetch_stage fetch_stage(
		.clk(aclk),
		.resetn(aresetn),
		.stall(stallF),
		.flush(flushALL),
		.pc_next(pc_nextF),
		.newpc(newpcF),

		.inst_sram_addr(inst_sram_addr),//pc_next if not stall and flush
		.inst_sram_en(inst_sram_en),
		.pc(pcF)
	);
		//iram control
	// assign inst_sram_en = 1'b1;
	assign inst_sram_wen = 4'b0000;
	assign inst_sram_wdata = 32'b0;

	//decode stage logicinst_sram_rdata

	decode_stage decode_stage(
    	.clk(aclk),
		.resetn(aresetn),
		.stall(stallD),
		.flush(flushALL),
		.inst_sram_en(inst_sram_en),
		.pc(pcF),
		.instr(inst_sram_rdata),
		.controls(controlsD),
		.alucontrol(alucontrolD),
		.rs(rsD),
		.rt(rtD),
		.rd(rdD),
		.sa(saD),
		.op(opD),
		.pc_next(pcD),
		.inst(instD),
		.rf_outa(rf_outaD),
		.rf_outb(rf_outbD),
		.srca(srcaD),
		.srcb(srcbD),
		.extend_imm(extend_immD),
		.jr_src(jr_srcD),
		.branch(branchD),

		//forward
		.forwardaD(forwardaD),
		.forwardbD(forwardbD),
		.aluoutE(aluoutE),
		.resultM(resultM),
		.resultW(resultW),

		//exception
		.exception_code(exception_codeD),

		//delay slot
		.is_in_slot(controlsD[1]),
		.is_in_slot_next(is_in_slotD)

    );

	// exe stage
	exe_stage exe_stage(
    	.clk(aclk),
		.resetn(aresetn),
		.stall(stallE),
		.flush(flushE | flushALL),
    	.pc(pcD),
		.srca(srcaD),
		.srcb(srcbD),
		.extend_imm(extend_immD),
		.controls({controlsD[3],controlsD[4],controlsD[5],controlsD[12:10],controlsD[8:7],controlsD[2]}),//5
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
		.div_srcb(div_srcbE),

		//mem
		.op(opD),
		.opE(opE),
		.mem_write_data(mem_write_dataE),

		//cp0
		.cp0_src(cp0_srcE),
    	.forwardCP0(forwardCP0E),
    	.cp0_write(cp0_writeE),
		.rd_next(rdE),

		//exception
		.exception_code(exception_codeD),
		.exception_code_next(exception_codeE),

		//delay slot
		.is_in_slot(is_in_slotD),
		.is_in_slot_next(is_in_slotE)
    );

	div div(
    	.clk(aclk),
		.resetn(aresetn),
	
		.signed_div_i(signed_divE),
		.opdata1_i(div_srcaE),
		.opdata2_i(div_srcbE),
		.start_i(start_divE),
		.annul_i(flushALL),
	
		.result_o(div_resultE),
		.ready_o(div_readyE)
);
	
	//mem stage
	mem_stage mem_stage(
		.clk(aclk),
		.resetn(aresetn),
		.stall(stallM),
		.flush(flushALL),
		.op(opE),
		.pc(pcE),
    	.mem_read(data_sram_rdata),
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
		.hilo_next(hiloM),

		//cp0
		.cp0_write(cp0_writeE),
		.cp0_write_next(cp0_writeM),
		//exception
		.exception_code(exception_codeE),
		.excepttype(excepttypeM),
		.badaddr_next(badaddrM),

		//delay slot
		.is_in_slot(is_in_slotE),
		.is_in_slot_next(is_in_slotM),

		.mem_write_data(mem_write_dataE),
		.addr(data_sram_addr),
		.en(data_sram_en),
		.write(data_sram_write),
		.writedata(data_sram_wdata),
    	.sel(data_sram_wen),
		.size(d_size)
    );

	//writeback stage
	wb_stage wb_stage(
		.clk(aclk),
		.resetn(aresetn),
		.stall(stallW),
		.flush(flushALL),
   		.pc(pcM),
	   	.result(resultM),
		.writereg(writeregM),
		.controls(controlsM),
		.pc_next(debug_wb_pc),
		.result_next(resultW),
		.writereg_next(writeregW),
		.regwrite(regwriteW),

		.hilo_write(hilo_writeM),
		.hilo(hiloM),
		.hilo_write_next(hilo_writeW),
		.hilo_next(hiloW),

		//cp0
		.cp0_write(cp0_writeM),
		.cp0_write_next(cp0_writeW)
    );

	assign debug_wb_rf_wdata = resultW;
	assign debug_wb_rf_wen = {4{regwriteW}};
	assign debug_wb_rf_wnum = writeregW;
	
	// hazard module
	hazard hazard(
		//decode stage
		.rsD(rsD),
		.rtD(rtD),
		.forwardaD(forwardaD),
		.forwardbD(forwardbD),
	//execute stage
		.rsE(rsE),
		.rtE(rtE),
		.rdE(rdE),
		.stall_divE(stall_divE),
		.forwardaE(forwardaE),
		.forwardbE(forwardbE),
		.forwardHiLoE(forwardHiLoE),
		.forwardCP0E(forwardCP0E),

		.writeregE(writeregE),
		.regwriteE(controlsE[1]),
		.memtoregE(controlsE[0]),
	//mem stage
		.writeregM(writeregM),
		.regwriteM(controlsM),
		.hilo_writeM(hilo_writeM),
		.cp0_writeM(cp0_writeM),
	
	//write back stage
		.writeregW(writeregW),
		.regwriteW(regwriteW),
		.hilo_writeW(hilo_writeW),
		.cp0_writeW(cp0_writeW),

		.stallF(stallF),
		.stallD(stallD),
		.stallE(stallE),
		.stallM(stallM),
		.stallW(stallW),
		.flushE(flushE),
		.flushALL(flushALL),

		.excepttype(excepttypeM),
		.cp0_epc(cp0_epcM),
		.newpc(newpcF),

		.stallreq_from_if(stallreq_from_if),
		.stallreq_from_mem(stallreq_from_mem)
	
    );


	// regfile
	regfile regfile(
		.clk(aclk),
		.we3(regwriteW), //regwrite
		.ra1(instD[25:21]), // rs
		.ra2(instD[20:16]), // rt
		.wa3(writeregW),	//
		.wd3(resultW),	//
		.rd1(rf_outaD),	//
		.rd2(rf_outbD)	//
    );
	
	//hilo reg
	hilo_reg hilo_reg(
		.clk(aclk),
		.resetn(aresetn),
		.we(hilo_writeW),
		.hi(hiloW[63:32]),
		.lo(hiloW[31:0]),
		.hi_o(hiloReg[63:32]),
		.lo_o(hiloReg[31:0])
    );

	//cp0 reg
	cp0_reg cp0_reg(
		.clk(aclk),
		.resetn(aresetn),

		.we_i(cp0_writeW),
		.waddr_i(writeregW),
		.raddr_i(rdE),
		.data_i(resultW),

		.int_i(int),

		.excepttype_i(excepttypeM),
		.current_inst_addr_i(pcM),
		.is_in_delayslot_i(is_in_slotM),
		.bad_addr_i(badaddrM),

	
		.data_o(cp0_srcE),
		.status_o(cp0_statusE),
		.cause_o(cp0_causeE),
		.epc_o(cp0_epcM),
	
		.badvaddr(),
		.timer_int_o()
    );


	i_cache i_cache(
        .p_a(inst_sram_addr),
        .p_din(inst_sram_rdata),
        .p_strobe(inst_sram_en),
        .p_ready(i_ready),
		// .cache_miss(cache_miss),

        .clk(aclk),
		.clrn(aresetn),
        .m_a(i_addr),
        .m_dout(mem_data),
        .m_strobe(m_fetch),
        .m_ready(m_i_ready)
		
    );

	d_cache d_cache(
        .p_a(data_sram_addr),
        .p_dout(data_sram_wdata),
        .p_din(data_sram_rdata),
        .p_strobe(data_sram_en),
        .p_rw(data_sram_write), //0: read, 1:write
        .p_ready(d_ready),
		.cache_miss(cache_miss),

        .clk(aclk),
		.clrn(aresetn),
        .m_a(d_addr),
        .m_dout(mem_data),
        .m_din(mem_st_data),
        .m_strobe(m_ld_st),
        .m_rw(m_st),
        .m_ready(m_d_ready)
    );

	

	// assign sel_i = cache_miss;
	// assign m_addr = sel_i ? i_addr : d_addr;
	// assign mem_access = sel_i ? m_fetch : m_ld_st;
	// assign mem_size = sel_i ? 2'b10 : d_size;
	// assign m_sel = sel_i ? 4'b1111 : mem_sel;
	// assign mem_write = sel_i ? 1'b0 : m_st;

	// //demux
	// assign m_i_ready = mem_ready & sel_i;
	// assign m_d_ready = mem_ready & ~sel_i;

	assign sel_i = cache_miss;
	assign m_addr = sel_i ? d_addr : i_addr;
	assign mem_access = sel_i ? m_ld_st : m_fetch;
	assign mem_size = sel_i ? d_size : 2'b10;
	assign m_sel = sel_i ? data_sram_wen : 4'b1111;
	assign mem_write = sel_i ? m_st : 1'b0;
	//demux
	assign m_i_ready = mem_ready & ~sel_i;
	assign m_d_ready = mem_ready & sel_i;
	
	assign stallreq_from_if = aresetn ? ~i_ready : 1'b0 ;
	assign stallreq_from_mem = data_sram_en & ~d_ready;

	axi_interface interface(
		.clk(aclk),
		.resetn(aresetn),
		
		 //cache port
		.mem_a(m_addr),
		.mem_access(mem_access),
		.mem_write(mem_write),
		.mem_size(mem_size),
		.mem_sel(m_sel),
		.mem_ready(mem_ready),
		.mem_st_data(mem_st_data),
		.mem_data(mem_data),

		.arid      (arid      ),
		.araddr    (araddr    ),
		.arlen     (arlen     ),
		.arsize    (arsize    ),
		.arburst   (arburst   ),
		.arlock    (arlock    ),
		.arcache   (arcache   ),
		.arprot    (arprot    ),
		.arvalid   (arvalid   ),
		.arready   (arready   ),
					
		.rid       (rid       ),
		.rdata     (rdata     ),
		.rresp     (rresp     ),
		.rlast     (rlast     ),
		.rvalid    (rvalid    ),
		.rready    (rready    ),
				
		.awid      (awid      ),
		.awaddr    (awaddr    ),
		.awlen     (awlen     ),
		.awsize    (awsize    ),
		.awburst   (awburst   ),
		.awlock    (awlock    ),
		.awcache   (awcache   ),
		.awprot    (awprot    ),
		.awvalid   (awvalid   ),
		.awready   (awready   ),
		
		.wid       (wid       ),
		.wdata     (wdata     ),
		.wstrb     (wstrb     ),
		.wlast     (wlast     ),
		.wvalid    (wvalid    ),
		.wready    (wready    ),
		
		.bid       (bid       ),
		.bresp     (bresp     ),
		.bvalid    (bvalid    ),
		.bready    (bready    )
	);

endmodule
