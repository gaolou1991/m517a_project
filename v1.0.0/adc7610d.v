///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <KeA418>
//
// File: adc7610c.v
// File history:
//      <V2.0.0>: <2016/10/31>: <adc7610 control>
//      <V2.0.1>: <2016/11/03>: <将ADC的读数据时钟，调整为由PLL产生的8MHz的时钟>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
// 1:启动时,复位ADC
// 2:在启动信号start有效,并且busy为空闲的情况下,启动ADC转换,输出ADC数据
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::208 PQFP>
// Author: <Eagle>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

`define		AD0_DELAY_RESET				(6'd20)		//reset delay
`define		AD0_DELAY_CONVERSION		(6'd40)		//conversion delay
`define		AD0_SHIFT_BITS					(5'd14)		//shift bits

module adc7610d(
	output reg [15:0] adc_data,					//adc out data
	output adc_clk,									//adc clock
	output reg adc_cnvst, adc_cs, adc_rst,	//adc control signal
	output reg adc_done,							//adc done
	input adc_din, adc_busy,						//adc input signal
	input adc_start,									//adc launch
	// input ad_clk,
	input clk, reset									//system clock(33M) and reset 
);

	localparam [3:0] t0 = 4'b0001, t1 = 4'b0010, t2 = 4'b0100, t3 = 4'b1000;
	reg [3:0] cur, nxt;
	
	reg adc_start2;
	reg [2:0] scnt;
	reg [7:0] sdelay;
	
	always @(posedge clk, negedge reset) begin
		if(!reset) cur <= t0;
		else cur <= nxt;
	end
	
	always @(*)begin
		if(!reset) nxt = t0;
		else case (cur)
			t0 : if(adc_start) nxt = t1; else nxt = t0;
			t1 : if(scnt < 3'd2) nxt = t2; else nxt = t0;
			t2 : nxt = t3;
			t3 : if(sdelay == 8'd80) nxt = t1; else nxt = t3;
			default : nxt = t0;
		endcase
	end
	
	always @(posedge clk, negedge reset)begin
		if(!reset) begin adc_start2 <= 1'b0; sdelay <= {8{1'b0}}; end
		else case(cur)
			t0 : begin adc_start2 <= 1'b0; end
			t1 : begin sdelay <= {8{1'b0}}; end
			t2 : begin adc_start2 <= 1'b1; end
			t3 : begin adc_start2 <= 1'b0; sdelay <= sdelay + 1'b1; end
			default : begin adc_start2 <= 1'b0; sdelay <= {8{1'b0}}; end
		endcase
	end


	localparam [9:0] s0 = 10'b00_0000_0001, s1 = 10'b00_0000_0010, s2 = 10'b00_0000_0100, s3 = 10'b00_0000_1000, s4 = 10'b00_0001_0000,
					 s5 = 10'b00_0010_0000, s6 = 10'b00_0100_0000, s7 = 10'b00_1000_0000, s8 = 10'b01_0000_0000, s9 = 10'b10_0000_0000,
					 s10 = 10'b00_0000_0000;

	reg [5:0] delay;					//delay reg
	reg [4:0] shift_cnt;			//shift counter reg
	reg delay_en, shift_en;		//delay and shift enable reg
	reg delay_rst, shift_rst;	//delay and shift counter clear reg (async)
	
	//* ADC转态机
	reg [9:0] cur_state, nxt_state;
	always @(posedge clk, negedge reset)begin
		if(!reset) cur_state <= s0;
		else cur_state <= nxt_state;
	end
	

	always @(*)begin
		case(cur_state)
		s0 : nxt_state <= s1;
		s1 : if(delay == `AD0_DELAY_RESET) nxt_state <= s2; else nxt_state <= s1;
		s2: if((!adc_busy) && adc_start2) nxt_state <= s3; else nxt_state <= s2;
		s3 : nxt_state <= s4;
		s4 : if(delay == `AD0_DELAY_CONVERSION) nxt_state <= s5; else nxt_state <= s4;
		s5 : nxt_state <= s6;
		s6 : if(shift_cnt == `AD0_SHIFT_BITS) nxt_state <= s7; else nxt_state <= s6;
		s7 : nxt_state <= s8;
		s8 : nxt_state <= s9;
		s9 : if(scnt == 2'd2) nxt_state <= s10; else nxt_state <= s2;
		s10 : nxt_state <= s2;
		default : nxt_state <= s0;
		endcase
	end
	
	reg adc_done2;
	always @(posedge clk, negedge reset)begin
		if(!reset) begin
			delay_en <= 1'b0; shift_en <= 1'b0;
			delay_rst <= 1'b1; shift_rst <= 1'b1;
			adc_rst <= 1'b0; adc_cnvst <= 1'b1; adc_cs <= 1'b1;
			adc_done <= 1'b0;
			adc_done2 <= 1'b0;
		end
		else begin
			case(cur_state)
			s0 : begin delay_rst <= 1'b0; adc_rst <= 1'b1; end
			s1 : begin delay_rst <= 1'b1; delay_en <= 1'b1; adc_rst <= 0; end
			s2 : begin delay_en <= 1'b0; adc_done2 <= 1'b0; adc_done <= 1'b0; end
			s3 : begin adc_cnvst <= 1'b0; delay_rst <= 1'b0; end
			s4 : begin delay_rst <= 1'b1; delay_en <= 1'b1; end
			s5 : begin adc_cnvst <= 1'b1; delay_en <= 1'b0; adc_cs <= 1'b0; shift_rst <= 1'b0; end
			s6 : begin shift_rst <= 1'b1; shift_en <= 1'b1; end
			s7 : begin adc_cs <= 1'b1; shift_en <= 1'b0; adc_done2 <= 1'b1; end
			s8 : begin adc_done2 <= 1'b0; end
			s9 : begin end
			s10 : begin adc_done <= 1'b1; end
			endcase
		end
	end
	
	//* 延时计数
	always @(posedge clk, negedge delay_rst)begin
		if(!delay_rst) delay <= {6{1'b0}};
		else if(delay_en) delay <= delay + 1'b1;
		else delay <= delay;
	end
	
	//* 时钟调整2016-11-03
	//* 产生ADC读取数据是在
	//* 最大10MHz 
	// reg [2:0] div;
	// always @(posedge clk, negedge reset)begin
		// if(!reset) div <= {3{1'b0}};
		// else div <= div + 1'b1;
	// end
	
	wire clk_4;
	//assign clk_4 = div[1];
	assign clk_4 = clk;
	
	//* 产生移位和移位计数的门控信号
	reg  q2;
	always @(posedge clk_4, negedge reset)begin
		if(!reset) q2 <= 1'b0;
		else q2 <= shift_en;
	end
	assign adc_clk = q2 & (clk_4);
	
	wire shift_en2;
	assign shift_en2 = shift_en & q2;
		
	//* 移位计数与移位
	always @( posedge clk_4, negedge shift_rst)begin
		if(!shift_rst) shift_cnt <= {5{1'b0}};
		else if(shift_en2) shift_cnt <= shift_cnt + 1'b1;
	end

	reg [15:0] shift_data;
	always @(posedge clk_4, negedge shift_rst)begin
		if(!shift_rst) shift_data <= {16{1'b0}};
		else if(shift_en2) shift_data <= {shift_data[14:0], adc_din};
		else shift_data <= shift_data;
	end
	

	
	always @(posedge clk, negedge reset)begin
		if(!reset) scnt <= {3{1'b0}};
		else if(adc_start) scnt <= {3{1'b0}};
		else if(adc_done2) scnt <= scnt + 1'b1;
	end
	
	reg [17:0] sum;
	always @(posedge clk, negedge reset)begin
		if(!reset) sum <= {18{1'b0}};
		else if(adc_start) sum <= {18{1'b0}};
		else if(adc_done2) sum <= sum + shift_data;
	end
	
		//* 输出锁存
	always @(posedge clk, negedge reset)begin
		if(!reset) adc_data <= {16{1'b0}};
		else if(adc_done) begin adc_data <= {2'b10,sum[14:1]}; end//adc_data <= shift_data;
	end
	
endmodule