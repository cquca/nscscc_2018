`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/08/08 10:17:43
// Design Name: 
// Module Name: mips_top
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

`include "defines.vh"

module mips_top(
	input wire clk,
	input wire hrst,
	input wire[5:0] int_i,
	output wire timer_int_o,

	input wire inst_sram_ack,
	input wire inst_sram_rrdy,
	input wire[`RegBus] inst_sram_rdata,
	output wire[`RegBus] inst_sram_addr,
	output wire[`RegBus] inst_sram_wdata,
	output wire inst_sram_wr,
	output wire[3:0] inst_sram_cen,

	input wire data_sram_ack,
	input wire data_sram_rrdy,
	input wire[`RegBus] data_sram_rdata,
	output wire[`RegBus] data_sram_addr,
	output wire[`RegBus] data_sram_wdata,
	output wire data_sram_wr,
	output wire[3:0] data_sram_cen
	
    );
	wire rst;
	assign rst = ~hrst;
	//connect if_id and id
	wire[`InstAddrBus] pc;
	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus] id_inst_i;
	
	//connect id and id_ex
	wire[`AluOpBus] id_aluop_o;
	wire[`AluSelBus] id_alusel_o;
	wire[`RegBus] id_reg1_o;
	wire[`RegBus] id_reg2_o;
	wire id_wreg_o;
	wire[`RegBus] id_inst_o;
	wire[`RegAddrBus] id_wd_o;
	wire id_is_in_delayslot;
	wire[`RegBus] id_link_addr;
	wire id_next_inst_in_delayslot;
	wire is_in_delayslot_o;
	wire[`RegBus] id_excepttype_o;
	wire[`RegBus] id_current_inst_address_o;
	//connect id_ex and ex

	wire[`AluOpBus] ex_aluop_i;
	wire[`AluSelBus] ex_alusel_i;
	wire[`RegBus] ex_reg1_i;
	wire[`RegBus] ex_reg2_i;
	wire ex_wreg_i;
	wire[`RegBus] ex_inst_i;
	wire[`RegAddrBus] ex_wd_i;
	wire ex_is_in_delayslot;
	wire[`RegBus] ex_link_address;
	wire[`RegBus] ex_current_inst_address;
	wire[`RegBus] ex_excepttype;
	//connect ex and ex_mem
	wire ex_wreg_o;
	wire[`RegAddrBus] ex_wd_o;
	wire[`RegBus] ex_wdata_o;
	wire[`RegBus] ex_hi_o;
	wire[`RegBus] ex_lo_o;
	wire ex_whilo_o;
	wire[`DoubleRegBus] ex_hilo_i;
	wire[`DoubleRegBus] ex_hilo_o;
	wire[1:0] ex_cnt_i;
	wire[1:0] ex_cnt_o;
	wire[`AluOpBus] ex_aluop_o;
	wire[`RegBus] ex_mem_addr_o;
	wire[`RegBus] ex_reg2_o;
	wire ex_cp0_reg_we_o;
	wire[4:0] ex_cp0_reg_write_addr_o;
	wire[`RegBus] ex_cp0_reg_data_o;
	wire[4:0] ex_cp0_reg_read_addr_o;
	wire[`RegBus] ex_cp0_reg_data_i;
	wire[`RegBus] ex_excepttype_o;
	wire[`RegBus] ex_current_inst_address_o;
	wire ex_is_in_delayslot_o;
	//connect ex_mem and mem
	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
	wire[`RegBus] mem_hi_i;
	wire[`RegBus] mem_lo_i;
	wire mem_whilo_i;
	wire[`AluOpBus] mem_aluop_i;
	wire[`RegBus] mem_mem_addr_i;
	wire[`RegBus] mem_reg2_i;
	wire mem_cp0_reg_we_i;
	wire[4:0] mem_cp0_reg_write_addr_i;
	wire[`RegBus] mem_cp0_reg_data_i;
	wire[`RegBus] mem_excepttype_i;
	wire mem_is_in_delayslot_i;
	wire[`RegBus] mem_current_inst_address_i;
	//connect mem and mem_wb
	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	wire[`RegBus] mem_hi_o;
	wire[`RegBus] mem_lo_o;
	wire mem_whilo_o;
	wire mem_LLbit_we_o;
	wire mem_LLbit_value_o;
	wire mem_cp0_reg_we_o;
	wire[4:0] mem_cp0_reg_write_addr_o;
	wire[`RegBus] mem_cp0_reg_data_o;
	wire[`RegBus] mem_bad_addr;
 	//connect mem_wb and wb
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	wire[`RegBus] wb_hi_i;
	wire[`RegBus] wb_lo_i;
	wire wb_whilo_i;
	wire wb_cp0_reg_we_i;
	wire[4:0] wb_cp0_reg_write_addr_i;
	wire[`RegBus] wb_cp0_reg_data_i;
	//connect hilo_reg and ex
	wire[`RegBus] hi_i;
	wire[`RegBus] lo_i;
	//connect id and regfile
	wire reg1_read;
	wire reg2_read;
	wire[`RegBus] reg1_data;
	wire[`RegBus] reg2_data;
	wire[`RegAddrBus] reg1_addr;
	wire[`RegAddrBus] reg2_addr;
	//stall
	wire[5:0] stall;
	wire stallreq_from_id;
	wire stallreq_from_ex;
	wire stallreq_from_if;
	wire stallreq_from_mem;
	//div
	wire signed_div;
	wire[31:0] div_opdata1;
	wire[31:0] div_opdata2;
	wire div_start;
	wire[63:0] div_result;
	wire div_ready;
	//for branch
	wire branch_flag;
	wire[`RegBus] branch_target_address;
	wire is_branch;
	//LLbit
	wire wb_LLbit_we;
	wire wb_LLbit_value;
	wire LLbit_o;

	//flush
	wire flush;
	wire[`RegBus] new_pc;

	//cp0 and mem
	wire[`RegBus] cp0_status_i;
	wire[`RegBus] cp0_cause_i;
	wire[`RegBus] cp0_epc_i;
	wire[`RegBus] cp0_excepttype_o;
	wire[`RegBus] cp0_epc_o;
	wire cp0_is_in_delayslot_o;
	wire[`RegBus] cp0_current_inst_address_o;


	//ahb bus
	wire pc_ce;
	wire[`RegBus] pc_data_o;
	wire[`RegBus] mem_addr;
	wire mem_ce;
	wire[`RegBus] mem_data_o;
	wire[`RegBus] mem_data_i;
	wire mem_we;
	wire[3:0] mem_sel;
//pc_reg
	pc_reg pc_reg0(
		.clk(clk),
		.rst(rst),
		.pc(pc),
		.stall(stall),
		.flush(flush),
		.new_pc(new_pc),
		.ce(pc_ce),
		.branch_flag_i(branch_flag),
		.branch_target_address_i(branch_target_address)
		);
	ahb_bus_if inst_ahb_bus_if(
		.clk(clk),
		.rst(rst),
		// .branch(branch_flag),
		//from ctrl
		.stall_i(stall),
		.flush_i(flush),

		//CPU side
		.cpu_ce_i(pc_ce),
		.cpu_data_i(`ZeroWord),
		.cpu_addr_i(pc),
		.cpu_we_i(1'b0),
		.cpu_sel_i(4'b1111),
		.cpu_data_o(pc_data_o),
		//ahb bus side
		.addr_ok(inst_sram_ack),
		.data_ok(inst_sram_rrdy),
		.dout(inst_sram_rdata),
		.addr(inst_sram_addr),
		.din(inst_sram_wdata),
		.wr(inst_sram_wr),
		.ben(inst_sram_cen),

		.stallreq(stallreq_from_if)
		);
//if_id

	if_id if_id0(
		.clk(clk),
		.rst(rst),
		.flush(flush),
		.stall(stall),
		.if_pc(pc),
		.if_inst(pc_data_o),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i)
		);
	//id
	id id0(
		.rst(rst),
		.stallreq(stallreq_from_id),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),
		//from regfile
		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),
		//to regfile
		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read),
		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr),
		//to id_ex
		.aluop_o(id_aluop_o),
		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),
		.reg2_o(id_reg2_o),
		.wd_o(id_wd_o),
		.wreg_o(id_wreg_o),
		.inst_o(id_inst_o),
		//data front push
		.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),
		.mem_wreg_i(mem_wreg_o),
		.mem_wd_i(mem_wd_o),
		.mem_wdata_i(mem_wdata_o),
		.is_in_delayslot_i(is_in_delayslot_o),
		.next_inst_in_delayslot_o(id_next_inst_in_delayslot),
		.branch_flag_o(branch_flag),
		.branch_target_address_o(branch_target_address),
		.link_addr_o(id_link_addr),
		.is_in_delayslot_o(id_is_in_delayslot),
		.ex_aluop_i(ex_aluop_o),
		.excepttype_o(id_excepttype_o),
		.current_inst_address_o(id_current_inst_address_o)
		);
	//regfile
	regfile regfile1(
		.clk(clk),
		.rst(rst),
		.we(wb_wreg_i),
		.waddr(wb_wd_i),
		.wdata(wb_wdata_i),
		.re1(reg1_read),
		.raddr1(reg1_addr),
		.rdata1(reg1_data),
		.re2(reg2_read),
		.raddr2(reg2_addr),
		.rdata2(reg2_data)
		);
	//id_ex
	id_ex id_ex0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.flush(flush),
		//from id
		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),
		.id_wreg(id_wreg_o),
		.id_inst(id_inst_o),
		.id_excepttype(id_excepttype_o),
		.id_current_inst_address(id_current_inst_address_o),
		//to ex
		.ex_aluop(ex_aluop_i),
		.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),
		.ex_wreg(ex_wreg_i),
		.ex_inst(ex_inst_i),
		.ex_current_inst_address(ex_current_inst_address),
		.ex_excepttype(ex_excepttype),

		.id_link_address(id_link_addr),
		.id_is_in_delayslot(id_is_in_delayslot),
		.next_inst_in_delayslot_i(id_next_inst_in_delayslot),
		.ex_link_address(ex_link_address),
		.ex_is_in_delayslot(ex_is_in_delayslot),
		.is_in_delayslot_o(is_in_delayslot_o)
		);

	//ex
	ex ex0(
		.rst(rst),
		.stallreq(stallreq_from_ex),
		//from id_ex
		.aluop_i(ex_aluop_i),
		.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),
		.wreg_i(ex_wreg_i),
		.inst_i(ex_inst_i),
		.excepttype_i(ex_excepttype),
		.current_inst_address_i(ex_current_inst_address),
		//to ex_mem
		.excepttype_o(ex_excepttype_o),
		.current_inst_address_o(ex_current_inst_address_o),
		.is_in_delayslot_o(ex_is_in_delayslot_o),
		.wd_o(ex_wd_o),
		.wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o),
		//from hi/lo
		.hi_i(hi_i),
		.lo_i(lo_i),

		//wb front push
		.wb_hi_i(wb_hi_i),
		.wb_lo_i(wb_lo_i),
		.wb_whilo_i(wb_whilo_i),
		//mem front push 
		.mem_hi_i(mem_hi_o),
		.mem_lo_i(mem_lo_o),
		.mem_whilo_i(mem_whilo_o),
		//ex write hi/lo
		.hi_o(ex_hi_o),
		.lo_o(ex_lo_o),
		.whilo_o(ex_whilo_o),
		//for madd/msub
		.hilo_temp_i(ex_hilo_i),
		.cnt_i(ex_cnt_i),
		.hilo_temp_o(ex_hilo_o),
		.cnt_o(ex_cnt_o),
		.div_result_i(div_result),
		.div_ready_i(div_ready),
		.div_opdata1_o(div_opdata1),
		.div_opdata2_o(div_opdata2),
		.div_start_o(div_start),
		.signed_div_o(signed_div),
		.link_address_i(ex_link_address),
		.is_in_delayslot_i(ex_is_in_delayslot),
		.aluop_o(ex_aluop_o),
		.mem_addr_o(ex_mem_addr_o),
		.reg2_o(ex_reg2_o),
		//cp0 mem correlation
		.mem_cp0_reg_we(mem_cp0_reg_we_o),
		.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
		.mem_cp0_reg_data(mem_cp0_reg_data_o),
		//cp0 wb correlation
		.wb_cp0_reg_we(wb_cp0_reg_we_i),
		.wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		.wb_cp0_reg_data(wb_cp0_reg_data_i),

		//connect cp0
		.cp0_reg_data_i(ex_cp0_reg_data_i),
		.cp0_reg_read_addr_o(ex_cp0_reg_read_addr_o),
		//to mem
		.cp0_reg_we_o(ex_cp0_reg_we_o),
		.cp0_reg_write_addr_o(ex_cp0_reg_write_addr_o),
		.cp0_reg_data_o(ex_cp0_reg_data_o)

		);
	//ex_mem
	ex_mem ex_mem0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.flush(flush),
		//from ex
		.ex_wd(ex_wd_o),
		.ex_wreg(ex_wreg_o),
		.ex_wdata(ex_wdata_o),
		.ex_hi(ex_hi_o),
		.ex_lo(ex_lo_o),
		.ex_whilo(ex_whilo_o),
		.ex_aluop(ex_aluop_o),
		.ex_mem_addr(ex_mem_addr_o),
		.ex_reg2(ex_reg2_o),
		.ex_cp0_reg_we(ex_cp0_reg_we_o),
		.ex_cp0_reg_write_addr(ex_cp0_reg_write_addr_o),
		.ex_cp0_reg_data(ex_cp0_reg_data_o),
		.ex_excepttype(ex_excepttype_o),
		.ex_is_in_delayslot(ex_is_in_delayslot_o),
		.ex_current_inst_address(ex_current_inst_address_o),
		//to mem
		.mem_excepttype(mem_excepttype_i),
		.mem_is_in_delayslot(mem_is_in_delayslot_i),
		.mem_current_inst_address(mem_current_inst_address_i),
		.mem_wd(mem_wd_i),
		.mem_wreg(mem_wreg_i),
		.mem_wdata(mem_wdata_i),
		.mem_hi(mem_hi_i),
		.mem_lo(mem_lo_i),
		.mem_whilo(mem_whilo_i),
		.mem_aluop(mem_aluop_i),
		.mem_mem_addr(mem_mem_addr_i),
		.mem_reg2(mem_reg2_i),
		.mem_cp0_reg_we(mem_cp0_reg_we_i),
		.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_i),
		.mem_cp0_reg_data(mem_cp0_reg_data_i),
		.hilo_i(ex_hilo_o),
		.cnt_i(ex_cnt_o),
		.hilo_o(ex_hilo_i),
		.cnt_o(ex_cnt_i)
		);
	//mem
	mem mem0(
		.rst(rst),
		//from ex_mem
		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
		.hi_i(mem_hi_i),
		.lo_i(mem_lo_i),
		.whilo_i(mem_whilo_i),
		.aluop_i(mem_aluop_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),
		.cp0_reg_we_i(mem_cp0_reg_we_i),
		.cp0_reg_write_addr_i(mem_cp0_reg_write_addr_i),
		.cp0_reg_data_i(mem_cp0_reg_data_i),
		.excepttype_i(mem_excepttype_i),
		.is_in_delayslot_i(mem_is_in_delayslot_i),
		.current_inst_address_i(mem_current_inst_address_i),
		//from cp0
		.cp0_status_i(cp0_status_i),
		.cp0_cause_i(cp0_cause_i),
		.cp0_epc_i(cp0_epc_i),
		//for data correlation
		.wb_cp0_reg_we(wb_cp0_reg_we_i),
		.wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		.wb_cp0_reg_data(wb_cp0_reg_data_i),

		.excepttype_o(cp0_excepttype_o),
		.cp0_epc_o(cp0_epc_o),
		.is_in_delayslot_o(cp0_is_in_delayslot_o),
		.current_inst_address_o(cp0_current_inst_address_o),
		//to mem_wb
		.wd_o(mem_wd_o),
		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),
		.hi_o(mem_hi_o),
		.lo_o(mem_lo_o),
		.whilo_o(mem_whilo_o),
		.cp0_reg_we_o(mem_cp0_reg_we_o),
		.cp0_reg_write_addr_o(mem_cp0_reg_write_addr_o),
		.cp0_reg_data_o(mem_cp0_reg_data_o),
		//from ram
		.mem_data_i(mem_data_i),
		//to ram
		.mem_addr_o(mem_addr),
		.mem_we_o(mem_we),
		.mem_sel_o(mem_sel),
		.mem_data_o(mem_data_o),
		.mem_ce_o(mem_ce),
		.LLbit_i(LLbit_o),
		.wb_LLbit_we_i(wb_LLbit_we),
		.wb_LLbit_value_i(wb_LLbit_value),
		.LLbit_we_o(mem_LLbit_we_o),
		.LLbit_value_o(mem_LLbit_value_o),
		.bad_addr_o(mem_bad_addr)
		);

	ahb_bus_if data_ahb_bus_if(
		.clk(clk),
		.rst(rst),
		// .branch(branch_flag),
		//from ctrl
		.stall_i(stall),
		.flush_i(flush),

		//CPU side
		.cpu_ce_i(mem_ce),
		.cpu_data_i(mem_data_o),
		.cpu_addr_i(mem_addr),
		.cpu_we_i(mem_we),
		.cpu_sel_i(mem_sel),
		.cpu_data_o(mem_data_i),
		//ahb bus side
		.addr_ok(data_sram_ack),
		.data_ok(data_sram_rrdy),
		.dout(data_sram_rdata),
		.addr(data_sram_addr),
		.din(data_sram_wdata),
		.wr(data_sram_wr),
		.ben(data_sram_cen),

		.stallreq(stallreq_from_mem)
		);

	//mem_wb
	mem_wb mem_wb0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.flush(flush),

		//from mem
		.mem_wd(mem_wd_o),
		.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),
		.mem_hi(mem_hi_o),
		.mem_lo(mem_lo_o),
		.mem_whilo(mem_whilo_o),
		.mem_LLbit_we(mem_LLbit_we_o),
		.mem_LLbit_value(mem_LLbit_value_o),
		.mem_cp0_reg_we(mem_cp0_reg_we_o),
		.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
		.mem_cp0_reg_data(mem_cp0_reg_data_o),
		//to wb
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i),
		.wb_hi(wb_hi_i),
		.wb_lo(wb_lo_i),
		.wb_whilo(wb_whilo_i),
		.wb_LLbit_we(wb_LLbit_we),
		.wb_LLbit_value(wb_LLbit_value),
		.wb_cp0_reg_we(wb_cp0_reg_we_i),
		.wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		.wb_cp0_reg_data(wb_cp0_reg_data_i)
		);
	hilo_reg hilo_reg0(
		.clk(clk),
		.rst(rst),
		.we(wb_whilo_i),
		.hi_i(wb_hi_i),
		.lo_i(wb_lo_i),
		.hi_o(hi_i),
		.lo_o(lo_i)
		);
	ctrl ctrl0(
		.rst(rst),
		.stallreq_from_id(stallreq_from_id),
		.stallreq_from_ex(stallreq_from_ex),
		.stallreq_from_if(stallreq_from_if),
		.stallreq_from_mem(stallreq_from_mem),
		.excepttype_i(cp0_excepttype_o),
		.cp0_epc_i(cp0_epc_o),

		.new_pc(new_pc),
		.flush(flush),
		.stall(stall)
		);
	div div0(
		.clk(clk),
		.rst(rst),
		.signed_div_i(signed_div),
		.opdata1_i(div_opdata1),
		.opdata2_i(div_opdata2),
		.start_i(div_start),
		.annul_i(flush),
		.result_o(div_result),
		.ready_o(div_ready)
		);
	LLbit LLbit0(
		.clk(clk),
		.rst(rst),
		.flush(flush),
		.LLbit_i(wb_LLbit_value),
		.we(wb_LLbit_we),
		.LLbit_o(LLbit_o)
		);
	cp0_reg cp0_reg0(
		.clk(clk),
		.rst(rst),
		.we_i(wb_cp0_reg_we_i),
		.waddr_i(wb_cp0_reg_write_addr_i),
		.raddr_i(ex_cp0_reg_read_addr_o),
		.data_i(wb_cp0_reg_data_i),
		.int_i(int_i),
		.bad_addr_i(mem_bad_addr),
		.data_o(ex_cp0_reg_data_i),
		.count_o(),
		.compare_o(),
		.status_o(cp0_status_i),
		.cause_o(cp0_cause_i),
		.epc_o(cp0_epc_i),
		.config_o(),
		.prid_o(),
		.badvaddr(),
		.timer_int_o(timer_int_o),
		.excepttype_i(cp0_excepttype_o),
		.current_inst_addr_i(cp0_current_inst_address_o),
		.is_in_delayslot_i(cp0_is_in_delayslot_o)
		);
endmodule
