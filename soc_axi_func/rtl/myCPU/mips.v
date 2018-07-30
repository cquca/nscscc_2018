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

	input wire aclk,
	input wire aresetn,

	// axi port
    //ar
    output wire[3:0] arid,      //read request id, fixed 4'b0
    output wire[31:0] araddr,   //read request address
    output wire[3:0] arlen,     //read request transfer length(beats), fixed 4'b0
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
    output wire[7:0] awlen,     //write request transfer length(beats), fixed 4'b0
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

    //debug interface
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
    );
	
	//Fetch
	wire[31:0] pcF;
	wire[31:0] instrF;
	wire instr_readyF;

	//Decode
	wire [5:0] opD,functD;
	wire regdstE,alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW,
			regwriteE,regwriteM,regwriteW;
	wire [2:0] alucontrolE;
	wire flushE,equalD;

	
	wire memwriteM;
	wire[31:0] aluoutM,writedataM;
	wire[31:0] readdataM; 

	//cache mux signal
	wire d_cache_miss,sel_i;
	wire[31:0] i_addr,d_addr,mem_addr;
	wire m_fetch,m_ld_st,mem_access;
	wire mem_write,m_st;
	wire mem_ready,i_ready,d_ready;
	wire mem_st_data,mem_data;
	wire[1:0] mem_size,d_size;
	wire mldst = 1'b0;
	wire i_cache_stall,d_cache_stall;

	controller c(
		.clk(aclk),
		.rst(aresetn),
		//decode stage
		.opD(opD),
		.functD(functD),
		.pcsrcD(pcsrcD),
		.branchD(branchD),
		.equalD(equalD),
		.jumpD(jumpD),
		
		//execute stage
		.flushE(flushE),
		.memtoregE(memtoregE),
		.alusrcE(alusrcE),
		.regdstE(regdstE),
		.regwriteE(regwriteE),	
		.alucontrolE(alucontrolE),

		//mem stage
		.memtoregM(memtoregE),
		.memwriteM(memwriteM),
		.regwriteM(regwriteM),
		//write back stage
		.memtoregW(memtoregW),
		.regwriteW(regwriteW)
		);


	datapath dp(
		.clk(aclk),
		.rst(~aresetn),
		//fetch stage
		.pcF(pcF),
		.instrF(instrF),
		.instr_readyF(instr_readyF),
		//decode stage
		.pcsrcD(pcsrcD),
		.branchD(branchD),
		.jumpD(jumpD),
		.equalD(equalD),
		.opD(opD),
		.functD(functD),
		//execute stage
		.memtoregE(memtoregE),
		.alusrcE(alusrcE),
		.regdstE(regdstE),
		.regwriteE(regwriteE),
		.alucontrolE(alucontrolE),
		.flushE(flushE),
		//mem stage
		.memtoregM(memtoregM),
		.regwriteM(regwriteM),
		.aluoutM(aluoutM),
		.writedataM(writedataM),
		.readdataM(readdataM),
		//writeback stage
		.memtoregW(memtoregW),
		.regwriteW(regwriteW),
		//debug interface
		.pcW(debug_wb_pc),
		.debug_wb_rf_wen(debug_wb_rf_wen),
		.writeregW(debug_wb_rf_wnum),
		.resultW(debug_wb_rf_wdata)
	    );

	i_cache i_cache(
        .p_a(pcF),
        .p_din(instrF),
        .p_strobe(1'b1),
        .p_ready(instr_readyF),
        .clk(aclk),
		.clrn(aresetn),
        .m_a(i_addr),
        .m_dout(mem_data),
        .m_strobe(m_fetch),
        .m_ready(i_ready)
		
    );


	d_cache d_cache(
        .p_a(aluoutM),
        .p_dout(writedataM),
        .p_din(readdataM),
        .p_strobe(mldst),
        .p_rw(), //0: read, 1:write
        .p_ready(),
        .cache_miss(d_cache_miss),
        .clk(aclk),
		.clrn(aresetn),
        .m_a(d_addr),
        .m_dout(mem_data),
        .m_din(mem_st_data),
        .m_strobe(m_ld_st),
        .m_rw(m_st),
        .m_ready(d_ready)
    );

	//mux, i_cache has higher priority than d_cache
	assign sel_i = d_cache_miss & m_ld_st;
	assign mem_addr = sel_i ? d_addr : i_addr;
	assign mem_access = sel_i ? m_ld_st : m_fetch;

	assign mem_write = sel_i ? m_st : 1'b0;
	assign i_ready = mem_ready & ~sel_i;
	assign d_ready = mem_ready & sel_i;
	assign mem_size = sel_i ? d_size : 2'b10;
	assign i_cache_stall = ~i_ready;
	assign d_cache_stall = mldst & ~d_ready;

	
	axi_interface interface(
		.clk(aclk),
		.resetn(aresetn),
		
		 //cache port
		.mem_a(mem_addr),
		.mem_access(mem_access),
		.mem_write(mem_write),
		.mem_size(mem_size),
		.mem_sel(),
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
