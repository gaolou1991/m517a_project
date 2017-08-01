///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: range_decode.v
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

`define		DIVISION_FACTOR		(8'd199)


module range_decode( 
/* 	output reg [9:0] range,
	output reg pros,
	output clk200k_pos, clk200k_neg,
	input clk200k, clk200_250,
	input clk, reset */
	input clk, reset,
	input synclk,
	output reg [9:0] range,
	output reg pros,
	output reg adc_start,
	output reg osynclk,
	output t5us
);
	reg pos_new, pos_old;
	always @( posedge clk, negedge reset)begin
		if(!reset) begin pos_new <= 1'b0; pos_old <= 1'b0; end
		else begin pos_new <= synclk; pos_old <= pos_new; end
	end
	
	wire clr;
	assign clr = pos_new & (!pos_old);
	
	always @(posedge clk,negedge reset)begin
		if(!reset) osynclk <= 1'b0;
		else osynclk <= synclk;
	end
	
	reg [7:0] counter;
	always @(posedge clk, negedge reset)begin
		if(!reset) counter <= {8{1'b0}};
		else if(clr) counter <= {8{1'b0}};
		else if(counter == `DIVISION_FACTOR) counter <= {8{1'b0}};
		else counter <= counter + 1'b1;
	end
	
	reg rcounter_en;
	always @(posedge clk, negedge reset)begin
		if(!reset) rcounter_en <= 1'b0;
		else if(counter == `DIVISION_FACTOR) rcounter_en <= 1'b1;
		else rcounter_en <= 1'b0;
		
		//if(counter == 8'b0000_0010) adc_start <= 1'b1;
		//else adc_start <= 1'b0;
	end 
	
	assign t5us = rcounter_en;		//output 5us
	
	always @(posedge clk, negedge reset)begin
		if(!reset) adc_start <= 1'b0;
		else adc_start <= rcounter_en;
	end
	
	always @(posedge clk, negedge reset)begin
		if(!reset) range <= {10{1'b0}};
		else if(clr) range <= {10{1'b0}};
		else if(rcounter_en) range <= range + 1'b1;
	end
	
	always @(posedge clk,negedge reset)begin
		if(!reset) pros <= 1'b0;
		else pros <= range < 10'd599 ? 1'b1 : 1'b0;
	end
/* 	reg pos_old, pos_new;
	always @(posedge clk, negedge reset)begin
		if(!reset) begin pos_new <= 1'b0; pos_old <= 1'b0; end
		else begin pos_new <= clk200k; pos_old <= pos_new; end
	end
	
	wire counter_en;
	assign counter_en = pos_new & (!pos_old);
	
	assign clk200k_neg = (!pos_new) & pos_old; 
	assign clk200k_pos = counter_en;
	
	reg pos_new2, pos_old2;
	always @(posedge clk, negedge reset)begin
		if(!reset) begin pos_new2 <= 1'b0; pos_old2 <= 1'b0; end
		else begin pos_new2 <= clk200_250; pos_old2 <= pos_new2; end
	end
	
	wire counter_clr;
	assign counter_clr = pos_new2 & (!pos_old2);
	
	always @(posedge clk, negedge reset)begin
		if(!reset) range <= {10{1'b1}};
		else if(counter_clr) range <= {10{1'b0}};
		else if(counter_en) range <= range + 1'b1;
		else range <= range;
	end
	
	always @(posedge clk)begin
		pros <= range > 10'd599 ? 1'b0 : 1'b1;
	end */
	
endmodule