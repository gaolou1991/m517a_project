 ///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: simulate.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
// 产生必须的仿真信号
// 1) 200/250Hz同步信号
// 2) 四个目标信号(目标信号经过外部的DAC回环到系统)。
//    a.目标信号是相互独立的，互不干扰，其工作状态(静止 切向 径向 螺旋)可由VX控制
//	  b.目标在200KHz信号的上升沿送进DAC，每200K更新一次DAC的值
// 3) 产生角度码
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module simulate( 
	input clk, reset,
	// input clk4m, target_reset,
	output [1:0] da_rst, da_clr, da_clk, da_cs, da_dat, da_lt,
	// input sim_angle, sim_range, sim_speed,
	// input [2:0] sim_mode,
	// input [9:0] sim_target_range,
	// input [15:0] dac1_data,
	
	input [31:0] angle, angle2, angle3, angle4,
	input [9:0] range, range2, range3, range4,
	input [31:0] range_mode, angle_mode,
	input [3:0] target_enable,
	
	output [11:0] bear,
	output synclk,
	output f1, f2,
	output target,
	output time_clr	
);
	// wire target;
/* 	wire clk200k;
	STM u0(
		.clk4m(clk4m), 
		.reset(reset),
		.speed(sim_speed), 
		.range(sim_range), 
		.angle(sim_angle),		//速度选择 距离单元运动/静止控制 方位码运动/静止控制
		.mode(sim_mode),				//目标模式
		.tarrange(sim_target_range),			//目标距离
		.bear(bear),
		.f1(f1), .f2(f2),		
		.target(target),
		.synclk(synclk),					//200/250hz输出
		.aclk(clk200k)
	); */
	
	assign time_clr = reset;
	
	wire clk200k;
	wire target_out, target_out_ref;
	sim u0( 
		.clk(clk), 
		.reset(reset),
		.angle(angle), .angle2(angle2), .angle3(angle3), .angle4(angle4),
		.range(range), .range2(range2), .range3(range3), .range4(range4),
		.angle_mode(angle_mode), .range_mode(range_mode),
		.target_enable(target_enable),
		.bear(bear),
		.target_out(target_out), 
		.target_out_ref(target_out_ref),
		.clk200k(clk200k),
		.synclk(synclk),
		.f1(f1), .f2(f2)
	);
	
	assign target = target_out;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////  
// M5712 DAC  FUNC 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
 reg [2 :0]  dac_dly   ;
 reg         dac_trg   ;
 reg         dac_clk   ;

 always@(posedge clk)                    
 begin 
     if  ( !reset  )       begin dac_trg <=0 ; dac_dly <=3'h1      ; end
     else if(dac_dly==3'h0) begin dac_trg <=1 ; dac_dly <=3'h1       ; end
     else                   begin dac_trg <=0 ; dac_dly <= dac_dly -1; end
 end 

 always@(posedge clk)                    
 begin 
     if  ( !reset   )      dac_clk <=1         ;
     else  if(dac_trg)      dac_clk <=~ dac_clk ;
 end 
 
/*  reg div;
 always @(posedge clk200k, negedge reset)begin
	if(!reset) div <= 1'b0;
	else div <= ~div;
 end */
 
/*  reg [1:0]delay;
 always @(posedge clk200k)begin
	delay[0] <= target_out;
	delay[1] <= delay[0];
 end
 
 wire trg_dac;
 assign trg_dac = target_out | delay[1];
 
  reg [1:0]delay2;
 always @(posedge clk200k)begin
	delay2[0] <= target_out_ref;
	delay2[1] <= delay[0];
 end
 
 wire trg_dac2;
 assign trg_dac2 = target_out_ref | delay2[1]; */
 
/*  reg pos_old, pos_new;
 always @(posedge clk, negedge reset)begin
	if(!reset) begin pos_new <= 1'b0; pos_old <= 1'b0; end
	else begin pos_new <= trg_dac; pos_old <= pos_new; end
 end
 wire daa_str;
 assign daa_str = pos_new & (!pos_old);
 
 reg pos_old2, pos_new2;
 always @(posedge clk, negedge reset)begin
	if(!reset) begin pos_new2 <= 1'b0; pos_old2 <= 1'b0; end
	else begin pos_new2 <= trg_dac2; pos_old2 <= pos_new2; end
 end
 wire daa_str2;
 assign daa_str2 = pos_new2 & (!pos_old2); */
 
  reg pos_old, pos_new;
 always @(posedge clk, negedge reset)begin
	if(!reset) begin pos_new <= 1'b0; pos_old <= 1'b0; end
	else begin pos_new <= clk200k; pos_old <= pos_new; end
 end
 wire daa_str;
 assign daa_str = pos_new & (!pos_old);
 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//DAC0 _AD5362A------------------------------------------------------------------------------------
/////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
	wire [15:0] dac_data;
	assign dac_data = target_out ? 16'hFFFF : 16'h8000; 
	
	AD5632  DAC0  (
		.bpclk    ( clk     ),
		.lreset   ( reset    ),

		.xtm_trg  ( dac_trg   ), // 时钟变换边缘
		.xtm_clk  ( dac_clk   ), 

		.dac_rst  ( da_rst[0]),
		.dac_clr  ( da_clr[0]),
		.dac_clk  ( da_clk[0]),
		.dac_cs   ( da_cs[0]),
		.dac_dat  ( da_dat[0]),
		.dac_lt   ( da_lt[0]),

		.cmd_dat  ( {8'b11_001_000, dac_data}   ),
		.cmd_str  ( daa_str   )
	); 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//DAC1 _AD5362A------------------------------------------------------------------------------------
/////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
	/* reg [15:0] dac_data_temp;
	always @(posedge clk)begin
		if(daa_str) dac_data_temp <= dac1_data;
	end */
	wire [15:0] dac_data2;
	assign dac_data2 = target_out_ref ? 16'hFFFF : 16'h8000; 
	
	AD5632  DAC1  (
		.bpclk    ( clk     ),
		.lreset   ( reset    ),

		.xtm_trg  ( dac_trg   ), // 时钟变换边缘
		.xtm_clk  ( dac_clk   ), 

		.dac_rst  ( da_rst [1]),
		.dac_clr  ( da_clr [1]),
		.dac_clk  ( da_clk [1]),
		.dac_cs   ( da_cs  [1]),
		.dac_dat  ( da_dat [1]),
		.dac_lt   ( da_lt  [1]),

		.cmd_dat  ( {8'b11_001_000, dac_data2 }  ),
		.cmd_str  ( daa_str   )
	); 

endmodule