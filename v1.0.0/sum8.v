///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: sum8.v
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

module sum8( 
	input clk, reset,
	input adc_done,
	input [15:0] adc_data,
	output [15:0]sum8
);
	//* 移位寄存器
	reg [15:0] shift0, shift1, shift2, shift3, shift4, shift5, shift6, shift7;
	always @(posedge clk, negedge reset)begin
		if(!reset) begin 
			shift0 <= {16{1'b0}};
			shift1 <= {16{1'b0}};
			shift2 <= {16{1'b0}};
			shift3 <= {16{1'b0}};
			shift4 <= {16{1'b0}};
			shift5 <= {16{1'b0}};
			shift6 <= {16{1'b0}};
			shift7 <= {16{1'b0}};
		end
		else if(adc_done) begin
			shift0 <= adc_data;
			shift1 <= shift0;
			shift2 <= shift1;
			shift3 <= shift2;
			shift4 <= shift3;
			shift5 <= shift4;
			shift6 <= shift5;
			shift7 <= shift6;
		end
	end
	
	reg adc_done2;
	always @(posedge clk,negedge reset)begin
		if(!reset) adc_done2 <= 1'b0;
		else adc_done2 <= adc_done;
	end
	//* 求和
	reg [18:0] sum;
	always @(posedge clk, negedge reset)begin
		if(!reset) sum <= {19{1'b0}};
		else if(adc_done2) begin
			sum <= shift0 + shift1 + shift2 + shift3 + shift4 + shift5 + shift6 + shift7;
		end
	end
	
	assign sum8 = sum[18:3];


endmodule

