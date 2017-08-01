///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: mti.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
// v1.0.1 Eagle-2016-11-14 16:09 PM 添加过零比较
// v1.0.2 Eagle-2016-11-15 14:20 PM 添加门限调整后的输出
// v1.0.3 Eagle-2016-11-17 15:11 PM 将门限调整电路更换为积分+门限调整
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module mti( 
	output adc_clk,						//adc clock
	output adc_cnv, adc_cs, adc_rst,	//adc control signal
	input adc_din, adc_busy,			//adc input signal
	input adc_start,					//adc launch
	output adc_done,					//adc 转换结束
	// input ad_clk,
	
	output [15:0] fifo_rddata,			//fifo 相关端口
	output [2:0] fifo_rdstate,
	output fifo_rdstb,
	input fifo_rden,
	
	input [15:0] thresh_hander,			//手动门限
	output reg stream,					//手动门限 比较结果输出
	output [15:0] update_mti_door, //MTI门限调整结果
	// input [15:0] error_mti, step_mti,
	// input start_mti,
	
	input clk, reset
);

	//* ADC控制模块
	// wire adc_done;
	wire [15:0] adc_data;
	adc7610d u0(
		.adc_data(adc_data),
		.adc_clk(adc_clk),
		.adc_cnvst(adc_cnv), 
		.adc_cs(adc_cs), 
		.adc_rst(adc_rst),
		.adc_done(adc_done),
		.adc_din(adc_din), 
		.adc_busy(adc_busy),
		.adc_start(adc_start),
		// .ad_clk(ad_clk),
		.clk(clk), 
		.reset(reset)
	);
	
	//* 过零比较 
	wire [15:0] mti_adc_data;
	assign mti_adc_data = adc_data[15] ? {1'b0,adc_data[14:0]} : 16'h0000;
	
	//* 积分电路 Eagle-2016-11-17
	wire [15:0] sum;
	sum8 u3( 
		.clk(clk), 
		.reset(reset),
		.adc_done(adc_done),
		.adc_data(mti_adc_data),
		.sum8(sum)
	);
	
	//* 调整门限 Eagle-2016-11-17
	reg [15:0] door;
	always @(posedge clk, negedge reset)begin
		if(!reset) door <= {16{1'b0}};
		else door <= sum + thresh_hander;
	end
	
	assign update_mti_door = door; //更新数据 Eagle-2016-11-15
	
	//* 数据比较
	wire bits;
	assign bits = adc_data > door ? 1'b1 : 1'b0;
	
	always @(posedge clk, negedge reset)begin
		if(!reset) stream <= 1'b0;
		else if(adc_done) stream <= bits;
	end
	
	//* ADC数据FIFO
	//* 容量 256X16 bit
	adc_fifo256x16 u2( 
		.rddata(fifo_rddata),
		.rdstate(fifo_rdstate),
		.rdstb(fifo_rdstb),
		.wrdata(adc_data),
		.wren(adc_done), 
		.rden(fifo_rden),
		.wrclk(clk), 
		.rdclk(clk),
		.reset(reset)
	);

endmodule
