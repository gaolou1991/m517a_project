///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: adc_fifo256x16.v
// File history:
//      <Revision number>: <Date>: <adc sampling data fifo>
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

module adc_fifo256x16( 
	output [15:0] rddata,
	output [2:0] rdstate,
	output reg rdstb,
	input [15:0] wrdata,
	input wren, rden,
	input wrclk, rdclk,
	input reset
);
	//* fifo read
	localparam [3:0] s0 = 4'b0001, s1 = 4'b0010, s2 = 4'b0100, s3 = 4'b1000;
	
	reg fifo_rden;
	
	reg [3:0] cur_state, nxt_state;
	always @(posedge rdclk, negedge reset)begin
		if(!reset) cur_state <= s0;
		else cur_state <= nxt_state;
	end
	
	always @(*)begin
		case(cur_state)
		s0 : if(rden) nxt_state <= s1; else nxt_state <= s0;
		s1 : nxt_state <= s2;
		s2 : nxt_state <= s3;
		s3 : nxt_state <= s0;
		default : nxt_state <= s0;
		endcase
	end
	
	
	always @(posedge rdclk, negedge reset)begin
		if(!reset)begin fifo_rden <= 1'b0; rdstb <= 1'b1; end
		else begin
			case(cur_state)
			s0 : begin rdstb <= 1'b1; end
			s1 : begin fifo_rden <= 1'b1; rdstb <= 1'b0; end
			s2 : begin fifo_rden <= 1'b0; end
			s3 : begin end
			endcase
		end
	end
	
	wire full, afull, empty;
	fifo256x16 u0(
		.DATA(wrdata),
		.Q(rddata),
		.WE(wren),
		.RE(fifo_rden),
		.WCLOCK(wrclk),
		.RCLOCK(rdclk),
		.FULL(full),
		.EMPTY(empty),
		.RESET(reset),
		.AFULL(afull)
	);
	assign rdstate[0] = full;
	assign rdstate[1] = afull;
	assign rdstate[2] = empty;

endmodule

