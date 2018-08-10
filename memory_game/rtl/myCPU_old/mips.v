`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
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


module mips(
	
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
    output wire bready          //master end ready to receive write response

	// input wire if_addr_ok,if_data_ok,
    // input wire[31:0] if_rdata,
    // output wire[31:0] if_addr,if_wdata,
    // output wire if_wr,
    // output wire[3:0] if_ben,
	
	// input wire mem_addr_ok,mem_data_ok,
    // input wire[31:0] mem_rdata,
    // output wire[31:0] mem_addr,mem_wdata,
    // output wire mem_wr,
    // output wire[3:0] mem_ben
    );
	
	wire [5:0] opD,functD,rtD;
	wire [1:0] pcsrcD;
	wire regdstE,alusrcE,memtoregE,memtoregM,memtoregW,
			regwriteE,regwriteM,memwriteM,memenM,dram_enM,
			regwriteW,jalW,
			jumpD,jrD,jrW,is_in_slotW,invalidD,stall_by_iram;
	wire [7:0] alucontrolE;
	wire stallE,flushE,flushM,flushW,overflowE,equalD,regwriteD;
	wire[31:0] pcF,instrF,instrD;
	wire[3:0] selM;
	wire[31:0] aluoutM,writedataM,readdataM;
	controller c(
		clk,rst,
		//decode stage
		instrD,
		pcsrcD,branchD,jumpD,jrD,regwriteD,balD,invalidD,
		equalD,
		
		//execute stage
		stallE,flushE,overflowE,
		memtoregE,alusrcE,
		regdstE,regwriteE,jalE,	
		alucontrolE,

		//mem stage
		memtoregM,memenM,memwriteM,
		regwriteM,flushM,adelM,
		//write back stage
		memtoregW,regwriteW,jrW,is_in_slotW,flushW
		);
	datapath dp(
		clk,rst,
		//fetch stage
		pcF,
		instrF,stall_by_iram,
		//decode stage
		pcsrcD,branchD,
		jumpD,jrD,regwriteD,balD,invalidD,
		equalD,
		instrD,
		//execute stage
		memtoregE,
		alusrcE,regdstE,
		regwriteE,jalE,
		alucontrolE,
		stallE,flushE,
		overflowE,
		//mem stage
		memtoregM,
		regwriteM,
		aluoutM,writedataM,
		readdataM,selM,adelM,adesM,flushM,
		//writeback stage
		int_i,
		memtoregW,
		regwriteW,jrW,is_in_slotW,flushW
	    );
	iram_port iram_port(
	// to core side
		pcF,
		instrF,stall_by_iram,
	//to bus side
		if_addr_ok,if_data_ok,
    	if_rdata,
   		if_addr,if_wdata,
    	if_wr,
    	if_ben,
    	memenM
    );
	assign dram_enM = memenM & !adelM & !adesM;
    dram_port dram_port(
	//to core side
		aluoutM,writedataM,
		readdataM,
		selM,
		memwriteM,dram_enM,
	//to bus side
		mem_addr_ok,mem_data_ok,
	    mem_rdata,
	    mem_addr,mem_wdata,
	    mem_wr,
	    mem_ben
    );

		i_cache i_cache(
        .p_a(pc),
        .p_din(pc_data_o),
        .p_strobe(pc_ce),
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
        .p_a(mem_addr),
        .p_dout(mem_data_o),
        .p_din(mem_data_i),
        .p_strobe(mem_ce),
        .p_rw(mem_we), //0: read, 1:write
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
	assign m_sel = sel_i ? mem_sel : 4'b1111;
	assign mem_write = sel_i ? m_st : 1'b0;
	//demux
	assign m_i_ready = mem_ready & ~sel_i;
	assign m_d_ready = mem_ready & sel_i;
	
	assign stallreq_from_if = ~i_ready;
	assign stallreq_from_mem = m_ld_st & ~d_ready;

	
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
