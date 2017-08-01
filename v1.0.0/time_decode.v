///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: time_decode.v
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
`define		US_CNT_MAX		(12'd3999)		//4000*5us = 20_000us = 20ms

module time_decode(
	input clk, reset,
	input time_clr,
	input t5us,
	output reg [15:0] timer
);
	//* 捕获同步信号
	reg pold, pnew;
	always @(posedge clk, negedge reset)begin
		if(!reset) begin pold <= 1'b0; pnew <= 1'b0; end
		else begin pold <= pnew; pnew <= time_clr; end
	end
	
	wire timer_clr;
	assign timer_clr = pnew & (!pold);
	
	//* us计数
	//* 统计5us个数
	reg [11:0] us;
	always @(posedge clk,negedge reset)begin
		if(!reset) us <= {12{1'b0}};
		else if(timer_clr) us <= {12{1'b0}};
		else if(us == `US_CNT_MAX) us <= {12{1'b0}}; 
		else if(t5us) us <= us + 1'b1;
	end
	
	reg ms_en;
	always @(posedge clk,negedge reset)begin
		if(!reset) ms_en <= 1'b0;
		else if(us == `US_CNT_MAX) ms_en <= 1'b1;
		else ms_en <= 1'b0;
	end
	
	//* ms计数
	//* 统计20ms个数
	always @(posedge clk, negedge reset)begin
		if(!reset) timer <= {16{1'b0}};
		else if(timer_clr) timer <= {16{1'b0}};
		else if(ms_en) timer <= timer + 1'b1;
	end
	

endmodule
