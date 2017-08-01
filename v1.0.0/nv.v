 ///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: nv.v
// File history:
//      <v1.0.0>: <2016/10/30>: <完成基本的NV通路 仅有一个ADC和一个FIFO>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
// v1.0.0 : Eagle-2016-10-30
// 1) ADC采样数据，经过比较输出，在adc_done信号到来时，锁存输出。
// 2) 对ADC的数据进FIFO，共后端测试使用
// v1.0.1 : Eagle-2016-11-14 16:06 PM 添加过零比较
// v1.0.2 : Eagle-2016-11-15 14:21 PM 添加CFAR调整的门限输出 
// v1.0.3 : Eagle-2016-11-17 15:09 PM 添加积分电路
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module nv( 
	output adc_clk,						//adc clock
	output adc_cnv, adc_cs, adc_rst,	//adc control signal
	input adc_din, adc_busy,			//adc input signal
	input adc_start,					//adc launch
	output adc_done,					//adc 转换结束
	// input ad_clk,
	
	
	input [15:0] thresh_hander,			//手动门限
	output reg streama,					//手动门限 比较结果输出
	
	
	input [15:0] thresh_auto,			//自动门限 CFAR模式
	output reg streamb,					//自动门限 CFAR模式 比较结果输出
	input [15:0] pf_cfar, step_cfar,
	output [15:0] statistic_cfar,
	input start_cfar,
	input synclk,
	output [15:0] update_cfar_door,	//CFAR门限更新
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
	
	//* 数据比较
	wire bitsa;
	assign bitsa = adc_data > thresh_hander ? 1'b1 : 1'b0;
	
	always @(posedge clk,negedge reset)begin
		if(!reset) streama <= 1'b0;
		else if(adc_done) streama <= bitsa;
	end
	
	

endmodule