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

`include "defines.h"
module mem_stage(
    input wire clk,resetn,
    input wire stall,flush,
    input wire[5:0] op,
    input wire[31:0] pc,mem_read,aluout,
    input wire[4:0] writereg,
    input wire[3:0] controls,
    output wire[31:0] pc_next,result,
    output reg[4:0] writereg_next,
    output wire controls_next,

    input wire hilo_write,
    input wire[63:0] hilo,
    output reg hilo_write_next,
    output reg[63:0] hilo_next,
	//cp0
	input wire cp0_write,
	output reg cp0_write_next,
	//exception
	input wire[7:0] exception_code,
	output reg[31:0] excepttype,
    output wire[31:0] badaddr_next,
	//delay slot
	input wire is_in_slot,
	output reg is_in_slot_next,

	input wire[31:0] mem_write_data,
	output wire[31:0] addr,
    output wire en,write,
    output reg[31:0] writedata,
    output reg[3:0] sel,
	output reg[1:0] size
    );

    reg[31:0] pcM,aluoutM,mem_readM,badaddrM,mem_write_dataM;
    reg[3:0] controlsM;
	reg[5:0] opM;
	reg[7:0] exception_codeM;

    always @(posedge clk) begin
        if (~resetn) begin
            pcM <= 32'hbfc00000;
            aluoutM <= 32'b0;
            writereg_next <= 5'b0;
            controlsM <= 2'b0;
            hilo_next <= 64'b0;
            hilo_write_next <= 1'b0;
			cp0_write_next <= 1'b0;
			opM <= 5'b0;
			exception_codeM <= 8'b0;
			is_in_slot_next <= 1'b0;
			mem_write_dataM <= 32'b0;
        end else if(flush) begin
            pcM <= 32'hbfc00000;
            aluoutM <= 32'b0;
            writereg_next <= 5'b0;
            controlsM <= 2'b0;
            hilo_next <= 64'b0;
            hilo_write_next <= 1'b0;
			cp0_write_next <= 1'b0;
			opM <= 5'b0;
			exception_codeM <= 8'b0;
			mem_write_dataM <= 32'b0;

        end else if(~stall) begin
            pcM <= pc;
            aluoutM <= aluout;
            writereg_next <= writereg;
            controlsM <= controls;
            hilo_next <= hilo;
            hilo_write_next <= hilo_write;
			opM <= op;
			cp0_write_next <= cp0_write;
			exception_codeM <= exception_code;
			is_in_slot_next <= is_in_slot;
			mem_write_dataM <= mem_write_data;
        end
      
    end
    
    assign result = controlsM[0] ? mem_readM : aluoutM;
    assign controls_next = controlsM[1];
    assign pc_next = pcM;
	assign badaddr_next = (pcM[1:0] != 2'b00) ? pcM : badaddr;

	//mem
	reg ades,adel;
	reg[31:0] badaddr;
    assign en = controlsM[2] & ~(|excepttype);
	assign write = controlsM[3];
    assign addr = aluoutM;
	
    always @(*) begin
        ades <= 1'b0;
        adel <= 1'b0;
        badaddr <= 32'b0;
		case (opM)
			// `LW,`LB,`LBU,`LH,`LHU:sel <= 4'b0000;
            `LW:begin
				size <= 2'b10;
				if(addr[1:0] != 2'b00) begin
					adel <= 1'b1;
					badaddr <= addr;
					sel <= 4'b0000;
				end else begin
                    sel <= 4'b1111;
                end
			end
			`LB,`LBU:begin
				size <= 2'b00;
				sel <= 4'b1111;
			end
			`LH,`LHU:begin
				size <= 2'b01;
                if ((addr[1:0] == 2'b10) | (addr[1:0] == 2'b00)) begin
                    sel <= 4'b1111;
                end else begin
                    adel <= 1'b1;
					badaddr <= addr;
                    sel <= 4'b0000;
                end
			end
			
			`SW:begin
				size <= 2'b10;
				if(addr[1:0] == 2'b00) begin
					/* code */
					sel <= 4'b1111;
                    writedata <= mem_write_dataM;
				end else begin
                    ades <= 1'b1;
                    badaddr <= addr;
					sel <= 4'b0000;
				end
			end
			`SH:begin
				size <= 2'b01;
				writedata <= {mem_write_dataM[15:0],mem_write_dataM[15:0]};
				case (addr[1:0])
					2'b10:sel <= 4'b1100;
					2'b00:sel <= 4'b0011;
					default :begin
                        ades <= 1'b1;
                        badaddr <= addr;
						sel <= 4'b0000;
					end 
				endcase
			end
			`SB:begin
				size <= 2'b00;
				writedata <= {mem_write_dataM[7:0],mem_write_dataM[7:0],mem_write_dataM[7:0],mem_write_dataM[7:0]};
				case (addr[1:0])
					2'b11:sel <= 4'b1000;
					2'b10:sel <= 4'b0100;
					2'b01:sel <= 4'b0010;
					2'b00:sel <= 4'b0001;
					default : /* default */;
				endcase
			end
			default : sel <= 4'b0000;
		endcase
    end
    always @(*) begin
		case (opM)
			`LW:begin 
				if(aluoutM[1:0] == 2'b00) begin
					/* code */
					mem_readM <= mem_read;
				end
			end
			`LB:begin 
				case (aluoutM[1:0])
					2'b11: mem_readM <= {{24{mem_read[31]}},mem_read[31:24]};
					2'b10: mem_readM <= {{24{mem_read[23]}},mem_read[23:16]};
					2'b01: mem_readM <= {{24{mem_read[15]}},mem_read[15:8]};
					2'b00: mem_readM <= {{24{mem_read[7]}},mem_read[7:0]};
					default : /* default */;
				endcase
			end
			`LBU:begin 
				case (aluoutM[1:0])
					2'b11: mem_readM <= {{24{1'b0}},mem_read[31:24]};
					2'b10: mem_readM <= {{24{1'b0}},mem_read[23:16]};
					2'b01: mem_readM <= {{24{1'b0}},mem_read[15:8]};
					2'b00: mem_readM <= {{24{1'b0}},mem_read[7:0]};
					default : /* default */;
				endcase
			end
			`LH:begin 
				case (aluoutM[1:0])
					2'b10: mem_readM <= {{16{mem_read[31]}},mem_read[31:16]};
					2'b00: mem_readM <= {{16{mem_read[15]}},mem_read[15:0]};
					default : ;
				endcase
			end
			`LHU:begin 
				case (aluoutM[1:0])
					2'b10: mem_readM <= {{16{1'b0}},mem_read[31:16]};
					2'b00: mem_readM <= {{16{1'b0}},mem_read[15:0]};
					default : ;
				endcase
			end
			default : mem_readM <= 32'b0;
		endcase
	end
	
	//0:eret, 1:break, 2:syscall, 3:ri, 4:overflow, 5:ades, 6:adel, 7:int
	always @(*) begin
		if(~resetn) begin
			/* code */
			excepttype <= 32'b0;
		end else begin 
			excepttype <= 32'b0;
			if(exception_codeM[7]) begin
				/* code */
				excepttype <= 32'h00000001;//interrupt
			end else if(adel | (pcM[1:0] != 2'b00)) begin
				/* code */
				excepttype <= 32'h00000004;//adel
			end else if(ades) begin
				/* code */
				excepttype <= 32'h00000005;//ades
			end else if(exception_codeM[2]) begin
				/* code */
				excepttype <= 32'h00000008;//syscall
			end else if(exception_codeM[1]) begin
				/* code */
				excepttype <= 32'h00000009;//break
			end else if(exception_codeM[0]) begin
				/* code */
				excepttype <= 32'h0000000e;//eret
			end else if(exception_codeM[3]) begin
				/* code */
				excepttype <= 32'h0000000a;//ri
			end else if(exception_codeM[4]) begin
				/* code */
				excepttype <= 32'h0000000c;//overflow
			end
		end
	
	end
    

endmodule
