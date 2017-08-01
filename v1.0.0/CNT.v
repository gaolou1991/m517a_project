///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: CNT.v
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

module CNT( CLK,CLR,Q );
	parameter Bits = 8;
	
	input CLK, CLR;
	output [Bits-1:0]Q;
	
	reg [Bits-1:0] cnt;
	always @(posedge CLK, negedge CLR)begin
		if(!CLR) cnt <= {Bits{1'b0}};
		else cnt <= cnt + 1'b1;
	end

	assign Q = cnt;

endmodule

