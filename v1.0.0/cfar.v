///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: cfar.v
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

`define			CFAR_DELAY_40			(8'd39)
`define			CFAR_PULES_100		(8'd99)

module cfar( 
	output reg [15:0] statistic,
	output reg [15:0] door,
	input [15:0] init_door, error, step,
	input start, bits, enable,
	input clk, synclk, reset
);

	localparam [4:0] s0 = 5'b0_0001, s1 = 5'b0_0010, s2 = 5'b0_0100, s3 = 5'b0_1000, s4 = 5'b1_0000;
	
	reg [7:0] delay_cnt, pules_cnt;
	reg [15:0] statistic_cnt;
	reg delay_en;
	reg delay_rst, statistic_rst;
	reg init_en;
	reg done;
	
	reg [4:0] cur_state, nxt_state;
	always @(posedge clk, negedge reset)begin
		if(!reset) cur_state <= s0;
		else cur_state <= nxt_state;
	end
	
	always @(*)begin
		case(cur_state)
		s0 : nxt_state <= s1;
		s1 : if(start) nxt_state <= s2; else nxt_state <= s1;
		s2 : if(delay_cnt == `CFAR_DELAY_40) nxt_state <= s3; else nxt_state <= s2;
		s3 : if(pules_cnt == `CFAR_PULES_100)nxt_state <= s4; else nxt_state <= s1;
		s4 : nxt_state <= s1;
		default : nxt_state <= s0;
		endcase
	end

	always @(posedge clk, negedge reset)begin
		if(!reset) begin 
			delay_en <= 1'b0; delay_rst <= 1'b1; done <= 1'b0; init_en <= 1'b0; statistic_rst <= 1'b1;  
		end
		else begin
			case(cur_state)
			s0 : begin init_en <= 1'b1; statistic_rst <= 1'b0; end
			s1 : begin init_en <= 1'b0; delay_rst <= 1'b0; done <= 1'b0; statistic_rst <= 1'b1; end
			s2 : begin delay_rst <= 1'b1; delay_en <= 1'b1; end
			s3 : begin delay_en <= 1'b0; end
			s4 : begin done <= 1'b1; statistic_rst <= 1'b0; end
			endcase
		end
	end
	
	always @(posedge clk, negedge reset)begin
		if(!reset) statistic <= {16{1'b0}};
		else if(done) statistic <= statistic_cnt;
		else statistic <= statistic;
	end
	
	always @(posedge clk, negedge reset)begin
		if(!reset) door <= {16{1'b0}};
		else if( init_en) door <= init_door;
		else if(done)begin
			if(statistic_cnt > error) door <= door + step;
			else if(statistic_cnt < error) door <= door - step;
			else door <= door;
		end
		else door <= door;
	end
	
	always @(posedge clk, negedge delay_rst)begin
		if(!delay_rst) delay_cnt <= {8{1'b0}};
		else if(delay_en && enable) delay_cnt <= delay_cnt + 1'b1;
		else delay_cnt <= delay_cnt;
	end
	
	always @(posedge clk, negedge reset)begin
		if(!reset) statistic_cnt <= {16{1'b0}};
		else if(!statistic_rst) statistic_cnt <= {16{1'b0}};
		else if(delay_en && bits && enable) statistic_cnt <= statistic_cnt + 1'b1;
		else statistic_cnt <= statistic_cnt;
	end
	
	wire clr;
	assign clr = reset & statistic_rst;
	always @(posedge synclk, negedge clr)begin
		if(!clr) pules_cnt <= {8{1'b0}};
		// else if( !statistic_rst) pules_cnt <= {8{1'b0}};
		else pules_cnt <= pules_cnt + 1'b1;
	end

endmodule

