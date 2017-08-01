///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: sim_main_range.v
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

module sim_main_range(  
	input resset,
	input [9:0] range,							//方位码
	input [9:0] start_range,					//目标起始和结束角度
	input fast_slow,							//目标速度选择 快飞和慢飞 0快飞 1慢飞
	input static_motion,						//静止和运动选择		  0静止 1运动
	input inward_outward,						//向里走和向外走选择	  0向外 1向里
	output target_range,						//角度目标输出
	output target_ref							//静止参考目标
);
	//*产生静止的参考角度目标
	wire static_target;
	assign static_target = (range == start_range) ? 1'b1 : 1'b0;
	
	assign target_ref = static_target;
	
	//*快飞和慢飞
/* 	reg [2:0] div;
	always @(posedge static_target, negedge resset)begin
		if(!resset) div <= {3{1'b0}};
		else div <= div + 1'b1;
	end */
	reg [12:0] div;
	always @(posedge static_target, negedge resset)begin
		if(!resset) div <= {13{1'b0}};
		else div <= div + 1'b1;
	end
	
	wire vclk;
	assign vclk = fast_slow ? div[12] : div[10];
	
	//*产生目标运动的偏移量
	reg [9:0] diff;
	always @(posedge vclk, negedge resset)begin
		if(!resset) diff <= {10{1'b0}};
		else if(static_motion) diff <= diff + 1'b1; //运动
		else diff <= {10{1'b0}}; 					//静止
	end
	
	//*产生运动目标
	//*对于跨4096的位置的数据没有做处理
	reg [11:0] vstart;
	always @(posedge vclk)begin
		if(inward_outward) vstart <= start_range + diff;
		else vstart <= start_range - diff;
	end
	
	assign target_range = (range == vstart) ? 1'b1 : 1'b0;



endmodule
