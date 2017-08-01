///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: data_process.v
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

module data_process( 
	input clk, reset,
	
	input wrclk, wren,
	input [10:0] wraddr,
	input  wrdata,
	
	input adc_start,
	input pros, bits, adc_done,
	input [4:0] echo, //MSB 11-7
	input [9:0] addr,
	
	input synclk,
	
	input [7:0] thresh_target_start, thresh_target_end,

	output target_start, target_end,
	output dp_done
);
	//*屏蔽区
	wire mask;
	wire shield_start;
	
	assign shield_start = adc_start & pros; //仅在正程才启动屏蔽
	
	shield u0( 
		.reset(reset),
		.rdclk(clk), 
		.wrclk(wrclk),
		.rden(shield_start), 
		.wren(wren),
		.wraddr(wraddr),
		.addr(addr[9:3]),
		.bear(echo),
		.wrdata(wrdata),
		.rddata(mask)
	);
	
	//*输出数据
	wire stream;
	assign stream = mask & bits & pros; //仅处理正程数据
	
	//*滑窗
	wire swd_start;
	assign swd_start = pros & adc_done; //进在正程才启动数据处理
	
	slider_window_decode u1(
		.clk(clk), 
		.reset(reset),
		.addr(addr),
		.start(swd_start),
		.bits(stream),
		.thresh_sectionalizer(8'd1),
		.synclk(synclk),
		.thresh_start(thresh_target_start), 
		.thresh_end(thresh_target_end),
		.done(dp_done),
		.target_start(target_start), 
		.target_end(target_end)
	);
	
endmodule