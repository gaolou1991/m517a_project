///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: sectionalizer.v
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
`ifdef DELAY_MAX_SIZE
`undef DELAY_MAX_SIZE
`endif

`ifdef SECTION_COUNTER_MAX
`undef SECTION_COUNTER_MAX
`endif

`define		DELAY_MAX_SIZE				(10'd598)
`define 	SECTION_COUNTER_MAX			(2'd3)

module sectionalizer(
	input clk, reset,
	input start,
	input [9:0] addr,
	input synclk,
	input ibits,
	input [7:0] thresh_sectionalizer,
	output reg done, obits
);

	//* 分段器计数
	reg [1:0] sect;
	always @(posedge synclk, negedge reset)begin
		if(!reset) sect <= {2{1'b0}};
		else sect <= sect + 1'b1;
	end
	
	//* 状态机
	localparam [7:0] r0 = 8'b0000_0001, s0 = 8'b0000_0010, s1 = 8'b0000_0100, s2 = 8'b0000_1000, s3 = 8'b0001_0000,
							s4 = 8'b0010_0000, s5 = 8'b0100_0000, s6 = 8'b1000_0000;
							
	reg clr_en;
	reg [9:0] clr_addr;
	reg write_en, read_en;
	reg shift_en, sum_en, cmp_en;
	reg clr2_en;
	reg [7:0] shift;
	reg [7:0] sum;
	
	wire [7:0] ram_rddata, ram_wrdata;
	wire [9:0] ram_wraddr;
	
	reg [7:0] cur_sta, nxt_sta;
	always @(posedge clk, negedge reset)begin
		if(!reset) cur_sta <= r0;
		else cur_sta <= nxt_sta;
	end
	
	always @(*)begin
		case(cur_sta)
		r0 : if(clr_addr == `DELAY_MAX_SIZE) nxt_sta <= s0; else nxt_sta <= r0;
		s0 : if(start) nxt_sta <= s1; else nxt_sta <= s0;
		s1 : nxt_sta <= s2;
		s2 : nxt_sta <= s3;
		s3 : if(sect == `SECTION_COUNTER_MAX) nxt_sta <= s4; else nxt_sta <= s0;
		s4 : nxt_sta <= s5;
		s5 : nxt_sta <= s6;
		s6 : nxt_sta <= s0;
		default : nxt_sta <= s0;
		endcase
	end
	
	always @(posedge clk, negedge reset)begin
		if(!reset) begin
			write_en <= 1'b0; read_en <= 1'b0; 
			shift_en <= 1'b0; sum_en <= 1'b0; cmp_en <= 1'b0;
			clr_en <= 1'b0; clr2_en <= 1'b0;
			done <= 1'b0;
		end
		else begin
			case(cur_sta)
			r0 : begin write_en <= 1'b1; clr_en <= 1'b1; clr2_en <= 1'b1; end
			s0 : begin write_en <= 1'b0; done <= 1'b0; clr_en <= 1'b0; clr2_en <= 1'b0; end
			s1 : begin read_en <= 1'b1; end
			s2 : begin read_en <= 1'b0; shift_en <= 1'b1; end
			s3 : begin shift_en <= 1'b0; write_en <= 1'b1; end
			s4 : begin write_en <= 1'b0; sum_en <= 1'b1; end
			s5 : begin sum_en <= 1'b0; cmp_en <= 1'b1; end
			s6 : begin cmp_en <= 1'b0; done <= 1'b1; write_en <= 1'b1; clr2_en <= 1'b1; end
			endcase
		end
	end
	
	//* 移位
	always @(posedge clk, negedge reset)begin
		if(!reset) shift <= {8{1'b0}};
		else if(shift_en) shift <= {ram_rddata[6:0],ibits};
	end
	
	//* 求和
	always @(posedge clk, negedge reset)begin
		if(!reset) sum <= {8{1'b0}};
		else if(sum_en) sum <= shift[0] + shift[1] + shift[2] + shift[3] + shift[4] + shift[5] + shift[6] + shift[7];
	end
	
	//* 比较
	always @(posedge clk,negedge reset)begin
		if(!reset) obits <= 1'b0;
		else if(cmp_en) obits <= (sum > thresh_sectionalizer) ? 1'b1 : 1'b0; 
	end
	
	//* 清除
	always @(posedge clk, negedge reset)begin
		if(!reset) clr_addr <= {10{1'b0}};
		else if(clr_en) clr_addr <= clr_addr + 1'b1;
	end
	
	assign ram_wraddr = clr_en ? clr_addr : addr;
	assign ram_wrdata = clr2_en ? {8{1'b0}} : shift;
	
	ram_600x8bit u0(
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
