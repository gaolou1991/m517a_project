///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: sn74hc165.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::Fusion> <Die::AFS600> <Package::256 FBGA>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module sn74hc165(SH_LD,CLK,QH, MCLK,nRESET,Q,DONE);
	//sn74hc165 interface
	output SH_LD; 	//shift_load
	output CLK; 	//clock
	input QH;		//MSB
	
	//system interface
	input MCLK; 		//system clock 40MHz
	input nRESET;		//system reset
	output [15:0] Q; 	//input data
	output DONE;		//done

	//division frequency
	// reg dcnt; //20MHz
	// always @(posedge MCLK,negedge nRESET)begin
		// if(!nRESET) dclk <= 1'b1;
		// else dclk <= ~dclk;
	// end
	reg [4:0] dcnt;
	wire dclk;
	always @(posedge MCLK,negedge nRESET)begin
		if(!nRESET) dcnt <= {5{1'b0}};
		else dcnt <= dcnt + 1'b1;
	end
	assign dclk = dcnt[4];
	
	//read data from sn74hc165
	//s0: load s1:shift s2:done
	// localparam [1:0] s0 = 2'b00, s1 = 2'b01, s2 = 2'b10;
	// reg [1:0] cur_state, nxt_state;
	
	// always @(posedge dclk,negedge nRESET)begin
		// if(!nRESET) cur_state <= s0;
		// else cur_state <= nxt_state;
	// end
	
	// reg [4:0] cnt; 
	// always @(*)begin
		// if(!nRESET) nxt_state = s0;
		// else case (cur_state)
			// s0: nxt_state = s1;
			// s1: if(cnt[4]) nxt_state = s2; else nxt_state = s1;
			// s2: nxt_state = s0;
			// default : nxt_state = s0;
		// endcase
	// end
	
	// reg sh_ld;
	// reg done;
	// reg [15:0] q;
	// reg shift_en;
	// always @(posedge dclk,negedge nRESET)begin
		// if(!nRESET)begin 
			// cnt <= {5{1'b0}};
			// sh_ld <= 1'b0;
			// done <= 1'b0;
			// shift_en <= 1'b0;
		// end
		// else case (cur_state)
			// s0: begin cnt <= 5'd0; sh_ld <= 1'b0; done <= 1'b0; end 
			// s1: begin 
				// cnt <= cnt + 1'b1; sh_ld <= 1'b1; 
				// shift_en <= 1'b1;
			// end
			// s2: begin done <= 1'b1; shift_en <= 1'b0; end
			// default: begin cnt <= {5{1'b0}}; sh_ld <= 1'b0; done <= 1'b0; end
		// endcase
	// end
	
	// always @(negedge dclk,negedge nRESET)begin
		// if(!nRESET) q <= {16{1'b0}};
		// else if(!sh_ld) q <= {16{1'b0}};
		// else if(shift_en) q <= {q[14:0],QH};
	// end
	
	localparam [3:0] s0 = 4'b0001, s1 = 4'b0010, s2 = 4'b0100, s3 = 4'b1000;
	reg [3:0] cur, nxt;
	
	always @(posedge dclk, negedge nRESET)begin
		if(!nRESET) cur <= s0;
		else cur <= nxt;
	end
	
	reg [3:0] cnt;
	always @(*)begin
		if(!nRESET) nxt = s0;
		else case (cur)
			s0 : nxt = s1;
			s1 : nxt = s2;
			s2 : if(cnt == 4'd14) nxt = s3; else nxt = s2;
			s3 : nxt = s0;
			default : nxt = s0;
		endcase
	end
	
	reg sh_ld, done, shift_en;
	always @(posedge dclk, negedge nRESET)begin
		if(!nRESET) begin sh_ld <= 1'b0; done <= 1'b0; shift_en <= 1'b0; end
		else case(cur)
			s0 : begin done <= 1'b0; sh_ld <= 1'b0; end
			s1 : begin sh_ld <= 1'b1; end
			s2 : begin shift_en <= 1'b1; end
			s3 : begin shift_en <= 1'b0; done <= 1'b1; end
		endcase
	end
	
	always @(posedge dclk, negedge nRESET)begin
		if(!nRESET) cnt <= {4{1'd0}};
		else if(!sh_ld) cnt <= {4{1'd0}};
		else if(shift_en) cnt <= cnt + 1'b1;
	end
	
	reg [15:0] q;
	always @(negedge dclk,negedge nRESET)begin
		if(!nRESET) q <= {16{1'b0}};
		else if(!sh_ld) q <= {16{1'b0}};
		else if(shift_en) q <= {q[14:0],QH};
	end
	
	assign SH_LD = sh_ld;
	assign DONE = done;
	assign Q = q;
	assign CLK = shift_en == 1 ? dclk : 1'bz;
endmodule