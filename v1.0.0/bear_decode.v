///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: bear_decode.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//	v1.0.1 Eagle-2016-11-28 10:44 AM 添加扇区号输出 sector
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module bear_decode( 
	input clk, reset,
	input [11:0] angle,
	input synclk,
	input [5:0] delay,
	input t5us,
	output reg [11:0] bear,
	output reg north,
	output onorth,
	output [3:0]sector
);
	//* 同步脉冲
	reg pos_new, pos_old;
	always @( posedge clk, negedge reset)begin
		if(!reset) begin pos_new <= 1'b0; pos_old <= 1'b0; end
		else begin pos_new <= synclk; pos_old <= pos_new; end
	end
	
	wire us_clr;
	assign us_clr = pos_new & (!pos_old); 
	
	//* 延时计数
	reg [5:0] us_delay;
	always @(posedge clk, negedge reset)begin
		if(!reset) us_delay <= {6{1'b0}};
		else if(us_clr) us_delay <= {6{1'b0}};
		else if(us_delay == delay) us_delay <= us_delay;
		else if(t5us) us_delay <= us_delay + 1'b1;
	end
	
	always @(posedge clk,negedge reset)begin
		if(!reset) bear <= {12{1'b0}};
		else if(us_delay == delay) bear <= angle;
		else bear <= bear;
	end
	
/* 	reg pos_new, pos_old;
	always @( posedge clk, negedge reset)begin
		if(!reset) begin pos_new <= 1'b0; pos_old <= 1'b0; end
		else begin pos_new <= synclk; pos_old <= pos_new; end
	end
	
	wire clr;
	assign clr = pos_new & (!pos_old); 
	
	
	reg [5:0] ns_25;
	always @(posedge clk, negedge reset)begin
		if(!reset) ns_25 <= {5{1'b0}};
		else if(clr) ns_25 <= {5{1'b0}};
		else if(ns_25 == `DELAY_NS_25) ns_25 <= {5{1'b0}};
		else ns_25 <= ns_25 + 1'b1;
	end
	
	reg us_en;
	always @(posedge clk)begin
		if(ns_25 == `DELAY_NS_25) us_en <= 1'b1;
		else us_en <= 1'b0;
	end
	
	reg [5:0] delay_us;
	always @(posedge clk, negedge reset)begin
		if(!reset) delay_us <= {5{1'b0}};
		else if(clr) delay_us <= {5{1'b0}};
		else if(delay_us == delay) delay_us <= delay_us;
		else if(us_en) delay_us <= delay_us + 1'b1;
	end
	
	always @(posedge clk)begin
		if(delay_us == delay) bear <= angle;
	end */
	
	always @(posedge clk, negedge reset)begin
		if(!reset) north <= 1'b0;
		else north <= (bear[11:8] == 4'b0000) ? 1'b1 : 1'b0;
	end
	
	
	reg north_flg;
	always @(posedge clk, negedge reset)begin
		if(!reset) north_flg <= 1'b0;
		else north_flg <= (bear[11:8] == 4'b0000) ? 1'b1 : 1'b0;
	end
	
	reg p1, p2;
	always @(posedge clk, negedge reset)begin
		if(!reset) begin p1 <= 1'b0; p2 <= 1'b0; end
		else begin p1 <= north_flg; p2 <= p1; end
	end
	
	wire north_start;
	assign north_start = p1 & (!p2);
	
	reg [31:0] delay_north;
	always @(posedge clk, negedge reset) begin
		if(!reset) delay_north <= {32{1'b1}};
		else if(north_start) delay_north <= {12{1'b0}};
		else if(delay_north < 32'd3199999) delay_north <= delay_north + 1'b1;
		else delay_north <= delay_north ;
	end
	
	assign onorth = delay_north < 32'd3199999 ? 1'b0 : 1'b1;
	
	assign sector = bear[11:8];  //update sector
	
endmodule