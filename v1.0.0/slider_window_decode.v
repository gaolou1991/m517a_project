///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: slider_window_decode.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::144 FBGA>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module slider_window_decode(
	input clk, reset,
	
	input [9:0] addr,
	
	input start,
	input bits,
	input [7:0] thresh_sectionalizer,
	input synclk,
	
	input [7:0] thresh_start, thresh_end,
	output done,
	output target_start, target_end
);
	wire sect_done;
	wire sect_obits;
	sectionalizer u0(
		.clk(clk), 
		.reset(reset),
		.start(start),
		.addr(addr),
		.synclk(synclk),
		.ibits(bits),
		.thresh_sectionalizer(thresh_sectionalizer),
		.done(sect_done), 
		.obits(sect_obits)
	);

	wire slide_done;
	wire [7:0] slide_sum;
	slide_window u1( 
		.clk(clk), 
		.reset(reset),
		.bits(sect_obits),
		.start(sect_done),
		.addr(addr),
		.done(slide_done),
		.sum(slide_sum)
	);

	criterion u2( 
		.clk(clk), 
		.reset(reset),
		.start(slide_done),
		.addr(addr),
		.sum(slide_sum),
		.thresh_start(thresh_start), 
		.thresh_end(thresh_end),
		.done(done),
		.target_start(target_start), 
		.target_end(target_end)
	);


endmodule

