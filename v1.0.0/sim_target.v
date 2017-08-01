///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: sim_target.v
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

module sim_target( 
	input resset,
	input [11:0] start_angle, end_angle,
	input [9:0] start_range,
	input [2:0] angle_mode, range_mode,
	input [11:0] bear,
	input [9:0] range,
	output target, target_ref
);
	wire target_angle, target_angle_ref;
	sim_main_angle u0( 
		.resset(resset),
		.bear(bear),							//方位码
		.start_angle(start_angle), 
		.end_angle(end_angle),		//目标起始和结束角度
		.fast_slow(angle_mode[0]),							//目标速度选择 快飞和慢飞 0快飞 1慢飞
		.static_motion(angle_mode[1]),						//静止和运动选择		  0静止 1运动
		.inward_outward(angle_mode[2]),						//向里走和向外走选择	  0向外 1向里
		.target_angle(target_angle),						//角度目标输出
		.target_ref(target_angle_ref)							//静止参考目标
	);

	wire target_range, target_range_ref;
	sim_main_range u1(  
		.resset(resset),
		.range(range),							//方位码
		.start_range(start_range),					//目标起始和结束角度
		.fast_slow(range_mode[0]),							//目标速度选择 快飞和慢飞 0快飞 1慢飞
		.static_motion(range_mode[1]),						//静止和运动选择		  0静止 1运动
		.inward_outward(range_mode[2]),						//向里走和向外走选择	  0向外 1向里
		.target_range(target_range),						//角度目标输出
		.target_ref(target_range_ref)							//静止参考目标
	);
	
	assign target = target_angle & target_range;
	assign target_ref = target_angle_ref & target_range_ref;
	
endmodule

