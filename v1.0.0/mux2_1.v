///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: mux2_1.v
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

module mux2_1( 
	input A_1, B_0,
	input S,
	output C
);
	
	assign C = S ? A_1 : B_0;

endmodule

