///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: radio.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
// v1.0.1 Eagle-2016-11-15 14:22 PM 
// 1) 添加NV和MTI通路门限调整后的输出端口 update_cfar_door update_mti_door
// 2) 添加自动门限选择输出 nv_mti_door
// 3) 添加data_bus模块,并屏蔽了以前的数据选择通路
// v1.0.2 Eagle-2016-11-28 10:46 AM 添加扇区号sector输出 
// v1.0.3 Eagle-2017-4-27 9:33 添加正逆程信号pros输出   添加对外部时钟的计数
// 
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module radio( 
	input clk, reset,
	//* 解码单元相关端口
	input [11:0] angle,
	input [5:0] delay_angle_in,
	output north,onorth,
	output [3:0] sector,
	
	input synclk,
	
	input time_clr,
	output[15:0] timer,
	
	input target,					//目标信号
	input sim_target_sel,		//目标信号源选择
	//* 数据通路相关端口
	output [1:0] adc_rst,adc_cnv,adc_cs, adc_clk,
	input  [1:0] adc_din,adc_busy,
	// input ad_clk,
	
	output [15:0] ffa_rddata, ffb_rddata,
	output [2:0] ffa_rdstate, ffb_rdstate,
	output ff_rdstb,
	input ffa_rden, ffb_rden,
	
	input [15:0] pf_cfar, step_cfar,
	output [15:0] statistic_cfar,
	output [15:0] update_cfar_door,
	// input [15:0] error_mti, step_mti,
	output [15:0] update_mti_door,
	
	input [15:0] thresh_hander_nv, thresh_auto_nv, thresh_hander_mti,
	
	input [2:0] bus_mode,
	//* 数据处理相关端口
	input wrclk_dp, wren_dp,
	input [10:0] wraddr_dp,
	input wrdata_dp,
	
	input [7:0] thresh_target_start, thresh_target_end,
	
	output target_start, target_end,
	output dp_done,
	
	output [9:0] range,
	output [11:0] bear,
	
	output nv_mti_door,
	
	output[7:0] SyncCnt,
	
	output opros
);
	//* 解码单元
	//* 数据处理准备模块 为后续的数据处理提供必要的控制和准备数据
	//* 解码方位码 解码距离码 解码时间码
	wire pros; 
	assign opros = ~pros;
	
	wire adc_start;
	wire osynclk;
	// wire [11:0] bear;
	// wire [9:0] range;
	
	decode pro_u0(
		.clk(clk), 
		.reset(reset),
		.angle(angle),
		.delay(delay_angle_in),
		.bear(bear),
		.north(north),
		.sector(sector), 	//Eagle-2016-11-28
		.synclk(synclk),
		.range(range),
		.pros(pros),
		.adc_start(adc_start),
		.time_clr(time_clr),
		.timer(timer),
		.osynclk(osynclk),
		.onorth(onorth)
	);
	
	//外部同步时钟计数
	CNT u2
	( 
		.CLK	( synclk),
		.CLR	( reset),
		.Q 		( SyncCnt)
	);
	
	
	//* 数据通路
	//* nv 和 mti 数据通路设置

	wire [1:0] adc_done;	
	wire bitsa, bitsb, bitsc;
	wire ffa_rdstb;
	wire start_cfar;
	
	reg pold, pnew;
	always @(posedge clk, negedge reset)begin
		if(!reset)begin pold <= 1'b0; pnew <= 1'b0; end
		else begin pold <= pnew; pnew <= pros; end
	end
	assign start_cfar = pold & (!pnew);
	
	nv bus_u0( 
		.adc_clk(adc_clk[0]),						//adc clock
		.adc_cnv(adc_cnv[0]), 
		.adc_cs(adc_cs[0]), 
		.adc_rst(adc_rst[0]),	//adc control signal
		.adc_din(adc_din[0]), 
		.adc_busy(adc_busy[0]),			//adc input signal
		.adc_start(adc_start),					//adc launch
		.adc_done(adc_done[0]),					//adc 转换结束
		// .ad_clk(ad_clk),
		
		.fifo_rddata(ffa_rddata),			//fifo 相关端口
		.fifo_rdstate(ffa_rdstate),
		.fifo_rdstb(ffa_rdstb),
		.fifo_rden(ffa_rden),
		
		.thresh_hander(thresh_hander_nv),			//手动门限
		.streama(bitsa),					//手动门限 比较结果输出
		
		.thresh_auto(thresh_auto_nv),
		.streamb(bitsb),
		.pf_cfar(pf_cfar), .step_cfar(step_cfar),
		.statistic_cfar(statistic_cfar),
		.start_cfar(start_cfar),
		.synclk(synclk),
		.update_cfar_door(update_cfar_door),
	
		.clk(clk), 
		.reset(reset)
	);
	
	wire ffb_rdstb;
	mti bus_u1( 
		.adc_clk(adc_clk[1]),						//adc clock
		.adc_cnv(adc_cnv[1]), 
		.adc_cs(adc_cs[1]), 
		.adc_rst(adc_rst[1]),	//adc control signal
		.adc_din(adc_din[1]), 
		.adc_busy(adc_busy[1]),			//adc input signal
		.adc_start(adc_start),					//adc launch
		.adc_done(adc_done[1]),					//adc 转换结束
		// .ad_clk(ad_clk),
		
		.fifo_rddata(ffb_rddata),			//fifo 相关端口
		.fifo_rdstate(ffb_rdstate),
		.fifo_rdstb(ffb_rdstb),
		.fifo_rden(ffb_rden),
		
		.thresh_hander(thresh_hander_mti),			//手动门限
		.stream(bitsc),					//手动门限 比较结果输出
/* 		.error_mti(error_mti), .step_mti(step_mti),
		.start_mti(start_cfar), */
		.update_mti_door(update_mti_door),
		
		.clk(clk), 
		.reset(reset)
	);
	assign ff_rdstb = ffa_rdstb & ffb_rdstb;
	
	//* 控制数据通路
	//* bus_mode 数据通路控制器
	// bit2 bit1 bit0
	//  0    0    0     nv  hander door
	//  0    0    1     nv  auto door / cfar
	//  0    1    0     mti
	//  1    0    0     auto mti/nv
	wire bus_auto;
	assign bus_auto = range < 10'd159 ? 1'b1 : 1'b0;
	
	
	// wire bits_nv;
	// assign bits_nv = bus_mode[0] ? bitsb : bitsa;
	
	// wire sel_mti;
	// assign sel_mti = bus_mode[2] ? bus_auto : bus_mode[1];
	// assign nv_mti_door = sel_mti; //Eagle-2016-11-15
	 
	//* 数据输出 供下一级使用
	// wire stream_nv_mti;
	// assign stream_nv_mti = sel_mti ? bitsc : bits_nv; 
	
	//* 选择输出的目标信号
	//* sim_target_sel 0选择NV通路或MTI通路的信号
	//*                1选择simulate模块产生的目标信号(直接短接,旁路ADC)
	wire stream;
	// assign stream = sim_target_sel ? target : stream_nv_mti; 
	data_bus bus_u2(
		.mode_nv(bus_mode[0]), .mode_mti_nv(bus_mode[1]), .mode_auto(bus_mode[2]), 
		.data_source(sim_target_sel), .auto(bus_auto),
		.bitsa(bitsa), .bitsb(bitsb), .bitsc(bitsc), .simulate(target), 
		.bits(stream), .mti_nv(nv_mti_door)
	);
	//* adc_done信号输出
	wire adc_ok;
	assign adc_ok = bus_mode[1] ? adc_done[1] : adc_done[0];
	
	reg adc_ok1, adc_ok2, adc_ok3;
	always @(posedge clk, negedge reset)begin
		if(!reset) begin adc_ok1 <= 1'b0; adc_ok2 <= 1'b0; adc_ok3 <= 1'b0; end
		else begin  adc_ok1 <= adc_ok; adc_ok2 <= adc_ok1; adc_ok3 <= adc_ok2; end
	end
	//* 数据处理单元
	//* 滑窗 屏蔽区 角度检测
	
	data_process pcs_u0(
		.clk(clk), 
		.reset(reset),
		.wrclk(wrclk_dp), 
		.wren(wren_dp),
		.wraddr(wraddr_dp),
		.wrdata(wrdata_dp),
		.pros(pros), 
		.bits(stream), 
		.adc_start(adc_start),
		.adc_done(adc_ok3),
		.echo(bear[11:7]),
		.addr(range),
		.thresh_target_start(thresh_target_start), 
		.thresh_target_end(thresh_target_end),
		.target_start(target_start), 
		.target_end(target_end),
		.synclk(osynclk),
		.dp_done(dp_done)
	);

endmodule