///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: top.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
// v1.0.1 Eagle-2016-11-15 14:24 PM 
// 1) 添加radio门限调整端口到PCI 
// 2) 添加自动门限选择信号nv_mti_door到数据处理FIFO
// v1.0.2 Eagle-2016-11-28 10:48 AM 添加扇区号sector到PCI总线
// v1.0.3 Eagle-2017-4-28 9:13 修改通路选择 添加外部引脚 修改HC165 修改MTD
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module top( 
	//* pin define
	input pci_clk, pci_rstn, pci_idsel,
	inout [31:0]pci_ad,	//inout pin
	inout pci_framen, pci_irdyn, pci_par, pci_intan, pci_trdyn, pci_stopn, pci_serrn, pci_devseln, pci_perrn,
	inout [3:0]pci_cben,
	//* adc pin
	output [1:0] adc_rst,adc_cnv,adc_cs, adc_clk,
	input  [1:0] adc_din,adc_busy,
	//output [3:0] aa_mux,
	//output [2:0] bb_mux,
	//* decode
	input extern_synclk, extern_sync_time,
	input extern_f2,
	//input extern_f2, extern_f1,
	
	input [1:0] pdi_dat, //串并转换
	output [1:0] pdi_lt, pdi_clk,
	//*MTD
 	output extern_mtd_en, extern_mtd_rst,
	input [1:0]extern_mtd_state, //hb empty
	input [15:0] extern_mtd_data, 
	//* 测试模块端口
	output  [1:0] da_rst, da_clr, da_clk, da_cs, da_dat, da_lt,
	
	//工作状态输出
	output MIX, RN, N
);
	//* pci bus
	wire pclk, preset;
	//* 时钟接口
	wire user_reset, clock_state;
	//* 解码单元相关端口
	wire [5:0] delay_angle_in;
	wire north;
	
	wire onorth;
	
	assign N = onorth;
	
	wire [15:0] timer;
	wire [3:0] sector;
	//* 数据通路相关端口	
	wire [15:0] ffa_rddata, ffb_rddata;
	wire [31:0] ffc_rddata;
	wire [2:0] ffa_rdstate, ffb_rdstate, ffc_rdstate;
	wire ff_rdstb;
	wire ffa_rden, ffb_rden, ffc_rden;
	wire cfifo_done;
	
	wire [15:0] pf_cfar, step_cfar;
	wire [15:0] statistic_cfar;
	wire [15:0] update_cfar_door;
	// wire [15:0] error_mti, step_mti;
	wire [15:0] update_mti_door;
	
	wire [15:0] thresh_hander_nv, thresh_auto_nv, thresh_hander_mti;
	wire [3:0] bus_mode;
	
	assign MIX = bus_mode[2] | bus_mode[3];
	//* 数据处理相关端口
	wire wren_dp;
	wire [10:0] wraddr_dp;
	wire wrdata_dp;
	
	wire [7:0] thresh_target_start, thresh_target_end;
	//* 测试模块端口
	wire [31:0] angle, angle2, angle3, angle4;
	wire [9:0] range, range2, range3, range4;
	wire [31:0] range_mode, angle_mode;
	wire [3:0] target_enable;
	wire [7:0] self_check;
	wire sim_target_sel;	//目标信号选择 	0选择外部目标信号 1直接短接目标信号到数据处理部分
	
	wire [7:0] ship;

	
	wire [7:0] SyncCnt;
	
	wire mtd_en, mtd_rst;
	wire [1:0]mtd_state; //hb empty
	wire [15:0] mtd_data;
	wire mtd_wen;
	wire [15:0] mtd_wdata;
	
	pci_bus u0( 
		//* pin define
		.pci_clk(pci_clk), .pci_rstn(pci_rstn), .pci_idsel(pci_idsel),
		.pci_ad(pci_ad),	//inout pin
		.pci_framen(pci_framen), .pci_irdyn(pci_irdyn), .pci_par(pci_par), .pci_intan(pci_intan), 
		.pci_trdyn(pci_trdyn), .pci_stopn(pci_stopn), .pci_serrn(pci_serrn), .pci_devseln(pci_devseln), 
		.pci_perrn(pci_perrn),.pci_cben(pci_cben),
		//* user pin
		.pclk(pclk), .preset(preset),
		//* system_clock
		.user_reset(user_reset), .clock_state(clock_state),
		//*adc
		//.aa_mux(aa_mux),.bb_mux(bb_mux),
		//* 解码单元相关端口
		.delay_angle_in(delay_angle_in),
		.north(north),
		.timer(timer),
		.sector(sector),
		//* 数据通路相关端口
		.ffc_rddata(ffc_rddata),
		.ffc_rdstate(ffc_rdstate),
		.ff_rdstb(ff_rdstb),
		.ffc_rden(ffc_rden),
		.cfifo_done(cfifo_done),
	
		.pf_cfar(pf_cfar), .step_cfar(step_cfar),
		.statistic_cfar(statistic_cfar),
		.update_cfar_door(update_cfar_door),
		// .error_mti(error_mti), .step_mti(step_mti),
		.update_mti_door(update_mti_door),
		.thresh_hander_nv(thresh_hander_nv), .thresh_auto_nv(thresh_auto_nv), .thresh_hander_mti(thresh_hander_mti),

		//* course
		.course(ship),
		
		.bus_mode(bus_mode),
		//* 数据处理相关端口
		.wren_dp(wren_dp),
		.wraddr_dp(wraddr_dp),
		.wrdata_dp(wrdata_dp),
	
		.thresh_target_start(thresh_target_start), .thresh_target_end(thresh_target_end),
		//* 测试模块端口
		.self_check(self_check),
		.sim_target_sel(sim_target_sel),
		.angle(angle), .angle2(angle2), .angle3(angle3), .angle4(angle4),
		.range(range), .range2(range2), .range3(range3), .range4(range4),
		.range_mode(range_mode), .angle_mode(angle_mode),
		.target_enable(target_enable),
		
		.SyncCnt(SyncCnt)
	);
	
	//* 并串转换
	
	//* 系统时钟单元
	//* 时钟单元产生40MHz的方波信号 供数据处理使用
	wire mclk, sync_reset;
	system_clock u1(
		.clk(pclk), 
		.reset(preset),				//system signal
		.user_reset(user_reset),				//user reset
		.state(clock_state),					//pll lock 0
		.mclk(mclk),  
		.sync_reset(sync_reset)
	);
	
	//internal wire 
	wire [11:0] extern_bear;
	//wire [7:0] ship;
	
	SSC u5
	( 
		.CLK	( mclk		),
		.nRESET	( preset	),
		.pdi_clk( pdi_clk	),
		.pdi_dat( pdi_dat	),
		.pdi_lt	( pdi_lt	),
		.Square	( extern_bear	),
		.Ship	( ship	)
	);

	
	


	//* 系统自测模拟数据产生
	wire target_end, target_start;
	wire [9:0] addr;
	wire [11:0] bear;
	wire ff_rdstb2;
	
	wire synclk;
	wire [11:0] echo;
	wire time_clr;
	wire f1, f2;
	
	wire [11:0] sim_bear;
	wire sim_synclk, sim_f1, sim_f2;
	wire sim_timer_sync;
	
	wire target;
	
	
	simulate u4(
		.clk(pclk), 
		//.reset(preset),
		.reset(sync_reset),
		.da_rst(da_rst), .da_clr(da_clr), .da_clk(da_clk), 
		.da_cs(da_cs), .da_dat(da_dat), .da_lt(da_lt),
		.angle(angle), .angle2(angle2), .angle3(angle3), .angle4(angle4),
		.range(range), .range2(range2), .range3(range3), .range4(range4),
		.range_mode(range_mode), .angle_mode(angle_mode),
		.target_enable(target_enable),
		.bear(sim_bear),
		.synclk(sim_synclk),
		.f1(sim_f1), .f2(sim_f2),
		.time_clr(sim_timer_sync),
		//.dac1_data(dac1_data),
		.target(target)
	);
	
	wire internal_mtd_rst, internal_mtd_wen, internal_mtd_rden;
	wire [15:0] internal_mtd_wdata, internal_mtd_rdata;
	wire [1:0] internal_mtd_state;
	//* 通路选择
	//* self_check 0 选择外部端口接入数据 1 自测模式 数据由内部产生
	assign synclk 	= self_check[0] ? sim_synclk 		: extern_synclk;
	assign time_clr = self_check[1] ? sim_timer_sync 	: extern_sync_time;
	assign f2 		= self_check[2] ? sim_f2 		  	: extern_f2;
	assign echo 	= self_check[3] ? sim_bear 	 	 	: extern_bear[11:0];
	
	
	//* 数据处理单元
	wire dp_done;
	
	wire nv_mti_door; //自动门限选择
	
	radio u2(
		.clk(mclk), .reset(sync_reset),
		//* 解码单元相关端口
		.angle(echo),
		.delay_angle_in(delay_angle_in),
		.north(north),
		.onorth(onorth),
		.sector(sector),
	
		.synclk(synclk),
	
		.time_clr(time_clr),
		.timer(timer),
		
		.target(target),
		.sim_target_sel(sim_target_sel),
		
		.opros(RN),
		//* 数据通路相关端口
		.adc_rst(adc_rst),.adc_cnv(adc_cnv),.adc_cs(adc_cs), .adc_clk(adc_clk),
		.adc_din(adc_din),.adc_busy(adc_busy),
	
	
		.pf_cfar(pf_cfar), .step_cfar(step_cfar),
		.statistic_cfar(statistic_cfar),
		.update_cfar_door(update_cfar_door),
		.update_mti_door(update_mti_door),
		
		.thresh_hander_nv(thresh_hander_nv), .thresh_auto_nv(thresh_auto_nv), .thresh_hander_mti(thresh_hander_mti),
	
		.bus_mode(bus_mode),
		//* 数据处理相关端口
		.wrclk_dp(pclk), .wren_dp(wren_dp),
		.wraddr_dp(wraddr_dp),
		.wrdata_dp(wrdata_dp),
	
		.thresh_target_start(thresh_target_start), .thresh_target_end(thresh_target_end),
	
		.target_start(target_start), .target_end(target_end),
		.dp_done(dp_done),
		.range(addr),
		.bear(bear),
		.SyncCnt(SyncCnt),
		.nv_mti_door(nv_mti_door)
	);
	
	//* 同步FIFO PCI和数据处理单元的数据通道
	wire ffc_rdstb;
	sync_fifo  u3(
		.reset(sync_reset),
		.rdclk(pclk), 
		.wrclk(mclk),
		.addr(addr),
		.bear(bear),
		.f1(f1), .f2(f2),
		.swd_done(dp_done), .target_start(target_start), .target_end(target_end),		//写控制信号
		.rden(ffc_rden),
		.rddata(ffc_rddata),
		.rdstate(ffc_rdstate),
		.rdstb(ffc_rdstb),
		.nv_mti_door(nv_mti_door)
	);

	
	assign ff_rdstb = ff_rdstb2;
	assign cfifo_done = ffc_rdstb;
	
endmodule