///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: sim_code.v
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
// `undef CLK33M
`define CLK33M

`define		RANGE_200_MAX		(10'd999)	
`define		RANGE_250_MAX		(10'd799)
`define		SELECT_250HZ		(6'd32)
`define		PULSE_CNT_MAX		(6'd32)
`define		TIME_15s			(12'd2999)

module sim_code( 
`ifndef CLK33M
	input clk,
`endif
	input clk273, clk200k, reset,
	output reg [9:0] range,
	output reg [11:0] bear,
	output f1, f2,
	output reg synclk
);

`ifdef CLK33M
	//* 同步时间信号
/* 	reg [9:0] time_5us;
	always @(posedge clk200k, negedge reset)begin
		if(!reset) time_5us <= {10{1'b0}};
		else if(time_5us == 10'd999) time_5us <= {10{1'b0}};
		else time_5us <= time_5us + 1'b1;
	end
	
	reg [11:0] time_5ms;
	always @(posedge clk200k, negedge reset)begin
		if(!reset) time_5ms <= {12{1'b0}};
		else if(time_5ms == 12'd2999) time_5ms <= {12{1'b0}};
		else if(time_5us == 10'd999) time_5ms <= time_5ms + 1'b1;
	end
	
	reg sync_time;	
	always @(posedge clk200k)begin
		if(time_5ms == 12'd2999) sync_time <= 1'b1;
		else sync_time <= 1'b0;
	end */
	//* 产生方位码
	always @(posedge clk273, negedge reset)begin
		if(!reset) bear <= {12{1'b0}};
		// else if(sync_time) bear <= {12{1'b0}};
		else bear <= bear + 1'b1;
	end
	
	//* 产生距离码
	reg [5:0] cnt;
	always @(posedge clk200k, negedge reset)begin
		if(!reset) begin range <= {10{1'b0}}; cnt <= {6{1'b0}}; end
		else if(cnt == 6'd32) begin
			if(range == 10'd799) begin
				range <= {10{1'b0}};
				cnt <= {6{1'b0}};
			end
			else range <= range + 1'b1;
			if(range == 10'd0) synclk <= 1'b1;
			if(range == 10'd399) synclk <= 1'b0;
		end
		else begin
			if(range == 10'd999) begin
				range <= {10{1'b0}};
				cnt <= cnt + 1'b1;
			end
			else range <= range + 1'b1;
			if(range == 10'd0) synclk <= 1'b1;
			if(range == 10'd499) synclk <= 1'b0;
		end
	end
	assign f1 = 1'b0;
	assign f2 = cnt == 6'd32 ? 1'b1 : 1'b0;
`else 
	//* 产生方位码
	//* 同步时间信号
	reg [9:0] time_5us;
	always @(posedge clk, negedge reset)begin
		if(!reset) time_5us <= {10{1'b0}};
		else if(time_5us == `RANGE_200_MAX) time_5us <= {10{1'b0}};
		else if(clk200k) time_5us <= time_5us + 1'b1;
	end
	
	reg [11:0] time_5ms;
	always @(posedge clk, negedge reset)begin
		if(!reset) time_5ms <= {12{1'b0}};
		else if(time_5ms == `TIME_15s) time_5ms <= {12{1'b0}};
		else if(time_5us == `RANGE_200_MAX) time_5ms <= time_5ms + 1'b1;
	end
	
	reg sync_time;	
	always @(posedge clk)begin
		if(time_5ms == `TIME_15s) sync_time <= 1'b1;
		else sync_time <= 1'b0;
	end
	
	always @(posedge clk, negedge reset)begin
		if(!reset) bear <= {12{1'b0}};
		else if(sync_time) bear <= {12{1'b0}};
		else if(clk273) bear <= bear + 1'b1;
	end
	
	//* 产生距离码
	//* 距离码
/* 	always @(posedge clk, negedge reset)begin
		if(!reset) range <= {10{1'b0}};
		else if(clk200k)begin
			if(range == `RANGE_200_MAX) range <= {10{1'b0}};
			else range <= range + 1'b1;
		end
	end
	 */
	reg [5:0] cnt;
	always @(posedge clk, negedge reset)begin
		if(!reset) begin range <= {10{1'b0}}; cnt <= {6{1'b0}}; synclk <= 1'b0; end
		else if(cnt == 6'd32) begin
			if(range == 10'd799) begin range <= {10{1'b0}}; cnt <= {6{1'b0}}; end
			else if(clk200k) range <= range + 1'b1;
			//250Hz
			if(range == 10'd0) synclk <= 1'b1;
			if(range == 10'd399) synclk <= 1'b0;
		end
		else begin
			if(range == 10'd999) begin range <= {10{1'b0}}; cnt <= cnt + 1'b1; end
			else if(clk200k) range <= range + 1'b1;
			//200Hz
			if(range == 10'd0) synclk <= 1'b1;
			if(range == 10'd499) synclk <= 1'b0;
		end
	end
	assign f1 = 1'b0;
	assign f2 = cnt == 6'd32 ? 1'b1 : 1'b0;
	
`endif
	
endmodule
