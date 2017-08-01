///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: decode.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
// v1.0.1 Eagle-2016-11-28 10:44 AM 添加扇区号输出 sector
// 
// <Description here>
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module decode( 
	input clk, reset,
	
	input [11:0] angle,
	input [5:0] delay,
	output [11:0] bear,
	output north, onorth,
	output [3:0]sector,
	
	input synclk,
	output [9:0] range,
	output pros,
	output adc_start,
	
	input time_clr,
	output[15:0] timer,
	output osynclk
);
	wire t5us;
	
	bear_decode u0(
		.clk(clk), 
		.reset(reset),
		.angle(angle),
		.synclk(synclk),
		.delay(delay),
		.bear(bear),
		.north(north),
		.onorth(onorth),
		.t5us(t5us),
		.sector(sector)
	);
	
	range_decode u1( 
		.clk(clk), 
		.reset(reset),
		.synclk(synclk),
		.range(range),
		.pros(pros),
		.adc_start(adc_start),
		.osynclk(osynclk),
		.t5us(t5us)
	);
	
	time_decode u3(
		.clk(clk), 
		.reset(reset),
		.time_clr(time_clr),
		.timer(timer),
		.t5us(t5us)
	);

endmodule