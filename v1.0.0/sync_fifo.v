///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: sync_fifo.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
// v1.0.1 Eagle-2016-11-15 15:07 PM 添加自动门限nv_mti_door到数据中
// v1.0.2 eagle-2016-12-14 21:07 修改写数据部分的时钟为下降沿
//
// <Description here>
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module sync_fifo (
	input reset,
	input rdclk, wrclk,
	input [9:0] addr,
	input [11:0] bear,
	input f1, f2,
	input swd_done, target_start, target_end,		//写控制信号
	input rden,
	output reg [31:0] rddata,
	output [2:0] rdstate,
	output rdstb,
	input nv_mti_door //自动门限选择
);

	//* FIFO 写数据
	//* FIFO写数据前 将数据缓存
	reg [31:0] fifo_data;
	always @(negedge wrclk, negedge reset)begin
		if(!reset) begin fifo_data <= {32{1'b0}}; end
		else if(swd_done) begin
			if(target_start)  fifo_data <= {2'b01,nv_mti_door,5'b00_000,{f2,f1},bear,addr}; //2+6+2+12+10bit
			if(target_end) 	  fifo_data <= {2'b10,nv_mti_door,5'b00_000,{f2,f1},bear,addr};
		end
	end
	
	//* 写数据状态机
	localparam [3:0] ws0 = 4'b0001, ws1 = 4'b0010, ws2 = 4'b0100, ws3 = 4'b1000;
	
	reg [3:0] wcur_sta, wnxt_sta;
	always @(negedge wrclk, negedge reset)begin
		if(!reset) wcur_sta <= ws0;
		else wcur_sta <= wnxt_sta;
	end
	
	wire wack;
	always @(*)begin
		case(wcur_sta)
		ws0 :  begin
			if(swd_done)begin
				if(target_start) wnxt_sta = ws1;
				else if(target_end) wnxt_sta = ws2;
				else wnxt_sta = ws0;
			end
			else wnxt_sta = ws0;
		end
		ws1 : wnxt_sta = ws3;
		ws2 : wnxt_sta = ws3;
		ws3 : if(wack) wnxt_sta = ws0; else wnxt_sta = ws3;
		default : wnxt_sta = ws0;
		endcase
	end
	
	reg write_en;
	always @(negedge wrclk, negedge reset)begin
		if(!reset) write_en <= 1'b0;
		else begin
			case(wcur_sta)
			ws0 : write_en <= 1'b0;
			ws1 : write_en <= 1'b1;
			ws2 : write_en <= 1'b1;
			ws3 : write_en <= 1'b0;
			default : write_en <= 1'b0;
			endcase
		end
	end
	
	//* FIFO读取数据
	//* 捕获使能信号边沿
	reg pold, pnew;
	always @(posedge rdclk)begin
		if(!reset) begin pold <= 1'b0; pnew <= 1'b0; end
		else begin pold <= pnew; pnew <= rden; end
	end
	
	wire ff_rden;
	assign ff_rden = pnew & (!pold);
	
	localparam [4:0] s0 = 5'b0_0001, s1 = 5'b0_0010, s2 = 5'b0_0100, s3 = 5'b0_1000, s4 = 5'b1_0000;
	
	reg fifo_rden;
	
	reg [4:0] cur_state, nxt_state;
	always @(posedge rdclk)begin
		if(!reset) cur_state <= s0;
		else cur_state <= nxt_state;
	end
	
	wire dvld;
	always @(*)begin
		case(cur_state)
		s0 : if(ff_rden) nxt_state <= s1; else nxt_state <= s0;
		s1 : nxt_state <= s2;
		s2 : if(dvld) nxt_state <= s3; else nxt_state <= s2;
		s3 : nxt_state <= s0;
		endcase
	end
	
	reg rd_done;
	wire [31:0] wrddata;
	always @(posedge rdclk)begin
		if(!reset) begin rd_done <= 1'b0; fifo_rden <= 1'b0; end
		else begin
			case(cur_state)
			s0 : rd_done <= 1'b1;
			s1 : begin rd_done <= 1'b0; fifo_rden <= 1'b1; end
			s2 : fifo_rden <= 1'b0;
			s3 : begin rddata <= wrddata; end
			default : begin rd_done <= 1'b1; fifo_rden <= 1'b0; end
			endcase
		end
	end
	
	assign rdstb = rd_done;

	
	wire full, afull, empty;
	fifo512x32 u0(
		.DATA(fifo_data),
		.Q(wrddata),
		.WE(write_en),
		.RE(fifo_rden),
		.WCLOCK(wrclk),
		.RCLOCK(rdclk),
		.FULL(full),
		.EMPTY(empty),
		.RESET(reset),
		.AFULL(afull),
		.WACK(wack),
		.DVLD(dvld)
	);
	assign rdstate[0] = full;
	assign rdstate[1] = afull;
	assign rdstate[2] = empty;
	
endmodule