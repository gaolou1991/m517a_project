///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: sim_clock.v
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

`ifdef CLK33M //33MHz	
	`define		CLK_BEAR_MAX			 (17'd120878)
	`define		CLK_BEAR_MAX_HB		(17'd60439)
	`define		CLK_RANGE_MAX			(8'd164)
	`define		CLK_RANGE_MAX_HB	(8'd82)
`else  //4MHz
	`define		CLK_BEAR_MAX		(16'd14651)
	`define		CLK_RANGE_MAX		(5'd19)
`endif


module sim_clock( 
	input clk, reset,			//in 33MHz/4MHz
	output reg clk273, clk200k	//out 273 200k
);
`ifdef CLK33M
	//* 33M->273
	reg [16:0] adiv;
	always @(posedge clk, negedge reset)begin
		if(!reset) adiv <= {17{1'b0}};
		else if(adiv == `CLK_BEAR_MAX) adiv <= {17{1'b0}};
		else adiv <= adiv + 1'b1;
	end
	
	always @(posedge clk, negedge reset)begin
		if(!reset) clk273 <= 1'b0;
		else if(adiv == `CLK_BEAR_MAX) clk273 <= 1'b1;
		else if(adiv == `CLK_BEAR_MAX_HB) clk273 <= 1'b0;
	end
	
	//* 33MHz->200KHz
	reg [7:0] rdiv;
	always @(posedge clk, negedge reset)begin
		if(!reset) rdiv <= {8{1'b0}};
		else if(rdiv == `CLK_RANGE_MAX) rdiv <= {8{1'b0}};
		else rdiv <= rdiv + 1'b1;
	end
	
	always @(posedge clk, negedge reset)begin
		if(!reset) clk200k <= 1'b0;
		else if(rdiv == `CLK_RANGE_MAX) clk200k <= 1'b1;
		else if(rdiv == `CLK_RANGE_MAX_HB) clk200k <= 1'b0;
	end
`else 
	//* 4MHz -> 200KHz
	reg [4:0] rdiv;
	always @(posedge clk, negedge reset)begin
		if(!reset) rdiv <= {5{1'b0}};
		else if(rdiv == `CLK_RANGE_MAX) rdiv <= {5{1'b0}};
		else rdiv <= rdiv + 1'b1;
	end
	
	always @(posedge clk)begin
		if(rdiv == `CLK_RANGE_MAX) clk200k <= 1'b1;		//200KHz counter enable
		else clk200k <= 1'b0;
	end
	
	//4MHz->273
	reg [15:0] adiv;
	always @(posedge clk, negedge reset) begin
		if(!reset) adiv <= {16{1'b0}};
		else if(adiv == `CLK_BEAR_MAX) adiv <= {16{1'b0}};
		else adiv <= adiv + 1'b1;
	end
	
	always @(posedge clk)begin
		if(adiv == `CLK_BEAR_MAX) clk273 <= 1'b1;
		else clk273 <= 1'b0;
	end
	
`endif

endmodule
