`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/08/02 18:17:35
// Design Name: 
// Module Name: stage
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
    input wire clk,resetn,stall,flush,
    input wire[31:0] pc,srca,srcb,extend_imm,
    input wire[8:0] controls,
    input wire[4:0] alucontrol,
    input wire[4:0] rs,rt,rd,sa,

    //forward
    input wire[1:0] forwardaE,forwardbE,
    input wire[31:0] resultM,resultW,

    output reg[31:0] aluout,
    output wire[4:0] writereg,rs_next,rt_next,
    output wire[31:0] pc_next,
    output wire[3:0] controls_next,

    //hilo
    input wire[63:0] hilo,hiloM,hiloW,
    input wire[1:0] forwardhilo,
    output wire hilo_write,
    output reg[63:0] hilo_next,

    //div
    input wire[63:0] div_result,
	input wire div_ready,
	output reg start_div,signed_div,stall_div,
    output reg[31:0] div_srca,div_srcb,

    //mem
    input wire[5:0] op,
    output reg[5:0] opE,
    output wire[31:0] mem_write_data,

    //
    input wire[31:0] cp0_src,
    input wire[1:0] forwardCP0,
    output wire cp0_write,
    output wire[4:0] rd_next,
    //exception
	input wire[7:0] exception_code,
	output wire[7:0] exception_code_next,

    //delay slot
	input wire is_in_slot,
	output reg is_in_slot_next


    );
    reg[31:0] pcE,srcaE,srcbE,extend_immE;
    reg[4:0] rsE,rtE,rdE,saE,alucontrolE;
    reg[8:0] controlsE;
    reg[63:0] hiloE;
    reg[7:0] exception_codeE;
    wire[31:0] alu_srca,alu_srcb,forward_srcb,cp0_srcE;
    wire[63:0] hilo_E;

    wire[31:0] s,bout,mult_a,mult_b;
	wire[63:0] hilo_temp;
	wire a_lt_b,overflow;

    //0:eret, 1:break, 2:syscall, 3:ri, 4:overflow
    assign exception_code_next = {3'b0,overflow,exception_codeE[3:0]};
	
    always @(posedge clk) begin
        if (~resetn) begin
            pcE <= 32'hbfc00000;
            srcaE <= 32'b0;
            srcbE <= 32'b0;
            extend_immE <= 32'b0;
            rsE <= 5'b0;
            rtE <= 5'b0;
            rdE <= 5'b0;
            saE <= 5'b0;
            opE <= 6'b0;
            controlsE <= 13'b0;
            alucontrolE <= 5'b0;
            hiloE <= 64'b0;
            exception_codeE <= 8'b0;
            is_in_slot_next <= 1'b0;
        end else if (flush) begin
            pcE <= 32'hbfc00000;
            srcaE <= 32'b0;
            srcbE <= 32'b0;
            extend_immE <= 32'b0;
            rsE <= 5'b0;
            rtE <= 5'b0;
            rdE <= 5'b0;
            saE <= 5'b0;
            // opE <= 6'b0;
            controlsE <= 13'b0;
            alucontrolE <= 5'b0;
            hiloE <= 64'b0;
            exception_codeE <= 8'b0;
        end else if(~stall) begin
            pcE <= pc;
            srcaE <= srca;
            srcbE <= srcb;
            extend_immE <= extend_imm;
            rsE <= rs;
            rtE <= rt;
            rdE <= rd;
            saE <= sa;
            opE <= op;
            controlsE <= controls;
            alucontrolE <= alucontrol;
            hiloE <= hilo;
            exception_codeE <= exception_code;
            is_in_slot_next <= is_in_slot;
        end
      
    end

    assign pc_next = pcE;
    assign writereg = controlsE[6] | controlsE[8] ? 5'b11111 :
                    controlsE[4] ? rdE : rtE;
    assign alu_srca = (forwardaE == 2'b10) ? resultM :
                    (forwardaE == 2'b01) ? resultW : srcaE;

    assign forward_srcb = (forwardbE == 2'b10) ? resultM :
                    (forwardbE == 2'b01) ? resultW : srcbE;
    assign mem_write_data = forward_srcb;
    assign alu_srcb = controlsE[3] ? extend_immE : forward_srcb;

    assign hilo_E = (forwardhilo == 2'b10) ? hiloM :
                    (forwardhilo == 2'b01) ? hiloW : hiloE;
    assign rs_next = rsE;
    assign rt_next = rtE;
    assign rd_next = rdE;

    assign controls_next = {controlsE[0],controlsE[2],controlsE[5]^overflow,controlsE[1]};

    assign cp0_write = (alucontrolE == `MTC0_CONTROL);

    assign cp0_srcE = (forwardCP0 == 2'b10) ? resultM :
                    (forwardhilo == 2'b01) ? resultW : cp0_src;
    
	assign bout = ((alucontrolE == `SUB_CONTROL)|
					(alucontrolE == `SUBU_CONTROL)|
					(alucontrolE == `SLT_CONTROL)) ? (~alu_srcb + 1) : alu_srcb;
	assign s = alu_srca + bout;
	assign a_lt_b = (alucontrolE == `SLT_CONTROL) ? (
		(alu_srca[31] && !alu_srcb[31]) || (!alu_srca[31] && !alu_srcb[31] && s[31]) ||
		(alu_srca[31] && alu_srcb[31] && s[31])) : (alu_srca < alu_srcb);
	assign mult_a = ((alucontrolE == `MULT_CONTROL) && (alu_srca[31] == 1'b1)) ? (~alu_srca + 1) : alu_srca;
	assign mult_b = ((alucontrolE == `MULT_CONTROL) && (alu_srcb[31] == 1'b1)) ? (~alu_srcb + 1) : alu_srcb;
	assign hilo_temp = ((alucontrolE == `MULT_CONTROL) && (alu_srca[31] ^ alu_srcb[31] == 1'b1)) ?
						~(mult_a * mult_b) + 1 : mult_a * mult_b; 
	assign overflow = ((alucontrolE == `ADD_CONTROL) || (alucontrolE == `SUB_CONTROL))
						&& ((!alu_srca[31] && !bout[31] && s[31]) || (alu_srca[31] && bout[31] && !s[31]));

    always @(*) begin
		case (alucontrolE)
        	//logic inst
			`OR_CONTROL: aluout <= alu_srca | alu_srcb;
			`AND_CONTROL: aluout <= alu_srca & alu_srcb;
			`OR_CONTROL: aluout <= alu_srca | alu_srcb;
			`XOR_CONTROL: aluout <= alu_srca ^ alu_srcb;
			`NOR_CONTROL: aluout <= ~(alu_srca | alu_srcb);
			`LUI_CONTROL: aluout <= {alu_srcb[15:0],alu_srcb[31:16]};
            //shift inst
			`SLL_CONTROL: aluout <= alu_srcb << saE;
			`SRL_CONTROL: aluout <= alu_srcb >> saE;
			`SRA_CONTROL: aluout <= ({32{alu_srcb[31]}} << (6'd32-{1'b0,saE})) | alu_srcb >> saE;
			`SLLV_CONTROL: aluout <= alu_srcb << alu_srca[4:0];
			`SRLV_CONTROL: aluout <= alu_srcb >> alu_srca[4:0];
			`SRAV_CONTROL: aluout <= ({32{alu_srcb[31]}} << (6'd32-{1'b0,alu_srca[4:0]})) | alu_srcb >> alu_srca[4:0];
			//move inst
			`MTHI_CONTROL: hilo_next <= {alu_srca,hilo_E[31:0]};
			`MTLO_CONTROL: hilo_next <= {hilo_E[63:32],alu_srca};
			`MFHI_CONTROL: aluout <= hilo_E[63:32];
			`MFLO_CONTROL: aluout <= hilo_E[31:0];
            //arithmetic inst
			`ADD_CONTROL,`ADDU_CONTROL,`SUB_CONTROL,`SUBU_CONTROL: aluout <= s;
			`SLT_CONTROL,`SLTU_CONTROL: aluout <= a_lt_b;
			`MULT_CONTROL,`MULTU_CONTROL: hilo_next <= hilo_temp;
            `DIV_CONTROL,`DIVU_CONTROL: hilo_next <= div_result;

            `MTC0_CONTROL: aluout <= alu_srcb;
			`MFC0_CONTROL: aluout <= cp0_srcE;
            default : aluout <= |controlsE[8:6] ? pcE + 8 : 32'b0;
		endcase	
	end

    always @(*) begin
        div_srca <= 32'b0;
        div_srcb <= 32'b0;
		start_div <= 1'b0;
		signed_div <= 1'b0;
		stall_div <= 1'b0;
		case (alucontrolE)
			`DIV_CONTROL:begin 
				if(div_ready == 1'b0) begin
					/* code */
                    div_srca <= alu_srca;
                    div_srcb <= alu_srcb;
					start_div <= 1'b1;
					signed_div <= 1'b1;
					stall_div <= 1'b1;
				end else if(div_ready == 1'b1) begin
					/* code */
                    div_srca <= alu_srca;
                    div_srcb <= alu_srcb;
					start_div <= 1'b0;
					signed_div <= 1'b1;
					stall_div <= 1'b0;
				end else begin 
                    div_srca <= 32'b0;
                    div_srcb <= 32'b0;
					start_div <= 1'b0;
					signed_div <= 1'b1;
					stall_div <= 1'b0;
				end
			end
			`DIVU_CONTROL:begin 
				if(div_ready == 1'b0) begin
					/* code */
                    div_srca <= alu_srca;
                    div_srcb <= alu_srcb;
					start_div <= 1'b1;
					signed_div <= 1'b0;
					stall_div <= 1'b1;
				end else if(div_ready == 1'b1) begin
					/* code */
                    div_srca <= alu_srca;
                    div_srcb <= alu_srcb;
					start_div <= 1'b0;
					signed_div <= 1'b0;
					stall_div <= 1'b0;
				end else begin 
                    div_srca <= 32'b0;
                    div_srcb <= 32'b0;
					start_div <= 1'b0;
					signed_div <= 1'b0;
					stall_div <= 1'b0;
				end
			end
			default : /* default */;
		endcase	end
    assign hilo_write = (alucontrolE == `MTHI_CONTROL) | (alucontrolE == `MTLO_CONTROL)
                        |(alucontrolE == `MULT_CONTROL) | (alucontrolE == `MULTU_CONTROL)
                        |(((alucontrolE == `DIV_CONTROL) | (alucontrolE == `DIVU_CONTROL)) & (div_ready == 1'b1));

    
endmodule
