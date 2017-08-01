///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: SSC.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
// Square cord and Ship cord
// <Description here>
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module SSC( CLK,nRESET,pdi_clk,pdi_dat,pdi_lt,Square,Ship);
	input CLK, nRESET;
	input [1:0] pdi_dat;
	output [1:0] pdi_clk, pdi_lt;
	
	output [11:0] Square;	//Square code
	output [7:0] Ship;		//Ship code
	//output Done;
	
	//internal wire of SN74HC165
	wire [1:0] done;
	wire [15:0] q[1:0];
	
	sn74hc165 u0
	(
		.SH_LD	( pdi_lt[0]	),
		.CLK	( pdi_clk[0]),
		.QH		( pdi_dat[0]), 
		.MCLK	( CLK		),
		.nRESET	( nRESET	),
		.Q		( q[0]		),
		.DONE	( done[0]	)
	);
	
	sn74hc165 u1
	(
		.SH_LD	( pdi_lt[1]	),
		.CLK	( pdi_clk[1]),
		.QH		( pdi_dat[1]), 
		.MCLK	( CLK		),
		.nRESET	( nRESET	),
		.Q		( q[1]		),
		.DONE	( done[1]	)
	);
	
	reg [15:0] q0;
	reg [15:0] q1;
	
	always @(posedge CLK) begin
		if( done[0]) q0 <= q[0][15:0];
	end
	always @(posedge CLK) begin
		if( done[1]) q1 <= q[1][15:0];
	end
	
	//assign Square = q[0][12:1];
	//assign Ship = {q[0][13],q[0][14],q[0][15],q[1][0],q[1][1],q[1][2],q[1][3],q[1][4]};
	//assign Done = done[0] & done[1];
	assign Square = q0[12:1];
	assign Ship = {q0[13],q0[14],q0[15],q1[0],q1[1],q1[2],q1[3],q1[4]};
	
endmodule
