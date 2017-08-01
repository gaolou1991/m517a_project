///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: sim_main_angle.v
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
// v1.0.0 创建文件 完成基本功能 2016-10-1
// v1.0.1 修改产生目标宽度，可以跨0扇区 2017-4-23
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module sim_main_angle( 
	input resset,
	input [11:0] bear,							//方位码
	input [11:0] start_angle, end_angle,		//目标起始和结束角度
	input fast_slow,							//目标速度选择 快飞和慢飞 0快飞 1慢飞
	input static_motion,						//静止和运动选择		  0静止 1运动
	input inward_outward,						//向里走和向外走选择	  0向外 1向里
	output target_angle,						//角度目标输出
	output target_ref							//静止参考目标
);
	//*产生静止的参考角度目标
	wire static_target;
	assign static_target = ((bear<end_angle) && (bear>start_angle)) ? 1'b1 : 1'b0;
	// reg static_target;
	// always @(*)begin
		// if(end_angle > start_angle) begin
			// if((bear<end_angle) && (bear>start_angle)) static_target = 1'b1;
			// else static_target = 1'b0;
		// end
		// else begin
			// if((12'b1111_1111_1111-bear<start_angle) && (bear>end_angle)) static_target = 1'b1;
			// else static_target = 1'b0;
		// end
	// end
	
	assign target_ref = static_target;
	
	//*快飞和慢飞
	reg [2:0] div;
	always @(posedge static_target, negedge resset)begin
		if(!resset) div <= {3{1'b0}};
		else div <= div + 1'b1;
	end
	
	wire vclk;
	assign vclk = fast_slow ? div[2] : div[0];
	
	//*产生目标运动的偏移量
	reg [11:0] diff;
	always @(posedge vclk, negedge resset)begin
		if(!resset) diff <= {12{1'b0}};
		else if(static_motion) diff <= diff + 1'b1; //运动
		else diff <= {12{1'b0}}; 					//静止
	end
	
	//*产生运动目标
	//*对于跨4096的位置的数据没有做处理
	reg [11:0] vstart, vend;
	always @(posedge vclk)begin
		if(inward_outward) vstart <= start_angle + diff;
		else vstart <= start_angle - diff;
		if(inward_outward) vend <= end_angle + diff;
		else vend <= end_angle - diff;
	end
	
	//assign target_angle = ((bear>vstart) && (bear<vend)) ? 1'b1 : 1'b0;
	reg otarget_angle;
	always @(*)begin
		if(vend > vstart) begin
			if((bear>vstart) && (bear<vend)) otarget_angle = 1'b1;
			else otarget_angle = 1'b0;
		end
		else begin
			if((12'b1111_1111_1111-bear<vend) && (bear>vstart)) otarget_angle = 1'b1;
			else otarget_angle = 1'b0;
		end
	end
	assign target_angle = otarget_angle;
	
endmodule
