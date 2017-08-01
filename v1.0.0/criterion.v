///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: criterion.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>
`ifdef RAM_CLR_ADDR
`undef RAM_CLR_ADDR
`endif

`define		RAM_CLR_ADDR		(10'd598)

module criterion( 
	input clk, reset,
	input start,
	input [9:0] addr,
	input [7:0] sum,
	input [7:0] thresh_start, thresh_end,
	output reg done,
	output reg target_start, target_end
);

	localparam [7:0] r0 = 8'b0000_0001, s0 = 8'b0000_0010, s1 = 8'b0000_0100, s2 = 8'b0000_1000, s3 = 8'b0001_0000,
							s4 = 8'b0010_0000, s5 = 8'b0100_0000;

	reg write_en, read_en, cmp_en;
	reg clr_en;
	reg [9:0] clr_addr;
	
	wire [9:0] ram_wraddr;
	wire ram_rddata, ram_wrdata;
	reg write_data;
	
	reg [7:0] cur_sta, nxt_sta;
	always @(posedge clk, negedge reset)begin
		if(!reset) cur_sta <= r0;
		else cur_sta <= nxt_sta;
	end
	
	always @(*)begin
		case(cur_sta)
		r0 : if(clr_addr == `RAM_CLR_ADDR) nxt_sta <= s0; else nxt_sta <= r0;
		s0 : if(start) nxt_sta <= s1; else nxt_sta <= s0;
		s1 : nxt_sta <= s2;
		s2 : nxt_sta <= s3;
		s3 : nxt_sta <= s4;
		s4 : nxt_sta <= s0;
		default : nxt_sta <= s0;
		endcase
	end
	
	always @(posedge clk, negedge reset)begin
		if(!reset) begin
			clr_en <= 1'b0;
			write_en <= 1'b0; read_en <= 1'b0; cmp_en <= 1'b0;
			done <= 1'b0;
		end
		else begin
			case(cur_sta)
			r0 : begin clr_en <= 1'b1; write_en <= 1'b1; end
			s0 : begin clr_en <= 1'b0; write_en <= 1'b0; done <= 1'b0; end
			s1 : begin read_en <= 1'b1; end
			s2 : begin read_en <= 1'b0; cmp_en <= 1'b1; end
			s3 : begin cmp_en <= 1'b0; write_en <= 1'b1; end
			s4 : begin write_en <= 1'b0; done <= 1'b1; end
			endcase
		end
	end
	
	//* RESET RAM
	always @(posedge clk, negedge reset)begin
		if(!reset) clr_addr <= {10{1'b0}};
		else clr_addr <= clr_addr + 1'b1;
	end
	
	//* 比较
	always @(posedge clk, negedge reset)begin
		if(!reset) begin
			target_start <= 1'b0;
			target_end <= 1'b0;
			write_data <= 1'b0;
		end
		else if(cmp_en) begin
			if( (!ram_rddata) &&  (sum == thresh_start) ) begin
				target_start <= 1'b1;
				write_data <= 1'b1;
			end
			else if((ram_rddata) && (sum == thresh_end)) begin
				target_end <= 1'b1;
				write_data <= 1'b0;
			end
			else begin
				target_start <= 1'b0;
				target_end <= 1'b0;
				write_data <= ram_rddata;
			end
		end
	end
	
	assign ram_wraddr = clr_en ? clr_addr : addr;
	assign ram_wrdata = clr_en ? {1{1'b0}} : write_data;
	
	ram_600x1bit u0(
		.WD(ram_wrdata),
		.RD(ram_rddata),
		.WEN(write_en),
		.REN(read_en),
		.WADDR(ram_wraddr),
		.RADDR(addr),
		.RWCLK(clk),
		.RESET(reset)
    );
							
endmodule

