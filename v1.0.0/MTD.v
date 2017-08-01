///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: MTD.v
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

module MTD( RST, WD, WCLK, RD, RCLK,STATE );
	input RST;
	input WCLK, RCLK;
	output [1:0] STATE;
	
	output [15:0] RD;
	input [15:0] WD;
	
	
	MTD_FIFO u0
	(
		.DATA		( WD),
		.Q			( RD),
		.WE		( 1'b1),
		.RE		( 1'b1),
		.WCLOCK	( WCLK),
		.RCLOCK	( RCLK),
		.FULL		( ),
		.EMPTY	( STATE[1]),
		.RESET	( RST),
		.AFULL	( STATE[0])
	);

endmodule

