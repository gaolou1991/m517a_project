///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: sim.v
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
// `undef CLK33M
`define CLK33M

module sim( 
	input clk, reset,
	input [31:0] angle, angle2, angle3, angle4,
	input [9:0] range, range2, range3, range4,
	input [31:0] angle_mode, range_mode,
	input [3:0] target_enable,
	output [11:0] bear,
	output target_out, target_out_ref,
	output clk200k, f2, f1, synclk
);

	wire clk273;
	sim_clock u0( 
		.clk(clk), 
		.reset(reset),			//in 33MHz
		.clk273(clk273), 
		.clk200k(clk200k)	//out 273 200k
	);

	wire [9:0] addr;
	sim_code u1(
	`ifndef CLK33M
		.clk(clk),
 	`endif
		.clk273(clk273), 
		.clk200k(clk200k), 
		.reset(reset),
		.range(addr),
		.bear(bear),
		.f1(f1), 
		.f2(f2),
		.synclk(synclk)
	);

	//* 产生目标
	//* 目标1
	wire target1, target_ref1;
	sim_target u2( 
		.resset(reset),
		.start_angle(angle[11:0]), 
		.end_angle(angle[27:16]),
		.start_range(range[9:0]),
		.angle_mode(angle_mode[2:0]), 
		.range_mode(range_mode[2:0]),
		.bear(bear),
		.range(addr),
		.target(target1), 
		.target_ref(target_ref1)
	);
	
	//* 目标2
	wire target2, target_ref2;
	sim_target u3( 
		.resset(reset),
		.start_angle(angle2[11:0]), 
		.end_angle(angle2[27:16]),
		.start_range(range2[9:0]),
		.angle_mode(angle_mode[10:8]), 
		.range_mode(range_mode[10:8]),
		.bear(bear),
		.range(addr),
		.target(target2), 
		.target_ref(target_ref2)
	);
	
	//* 目标3
	wire target3, target_ref3;
	sim_target u4( 
		.resset(reset),
		.start_angle(angle3[11:0]), 
		.end_angle(angle3[27:16]),
		.start_range(range3[9:0]),
		.angle_mode(angle_mode[18:16]), 
		.range_mode(range_mode[18:16]),
		.bear(bear),
		.range(addr),
		.target(target3), 
		.target_ref(target_ref3)
	);
	
	//* 目标4
	wire target4, target_ref4;
	sim_target u5( 
		.resset(reset),
		.start_angle(angle4[11:0]), 
		.end_angle(angle4[27:16]),
		.start_range(range4[9:0]),
		.angle_mode(angle_mode[26:24]), 
		.range_mode(range_mode[26:24]),
		.bear(bear),
		.range(addr),
		.target(target4), 
		.target_ref(target_ref4)
	);
	
	//* enable
	assign target_out = (target1&target_enable[0]) | (target2&target_enable[1]) | (target3&target_enable[2]) | (target4&target_enable[3]);
	assign target_out_ref = (target_ref1&target_enable[0]) | (target_ref2&target_enable[1]) | (target_ref3&target_enable[2]) | (target_ref4&target_enable[3]);
	
endmodule