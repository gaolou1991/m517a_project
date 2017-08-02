//
// @2017. KeA418, eagle. all right reserved.
//

//
// ExternBearShip.v
// extern bear and ship signals
// eagle
// v1.0.0
// 2017-8-1
//

module ExternBearShip(
	input Clk, nReset,
	input [1:0] PdiDat,
	output [1:0] PdiClk, PdiLt,
	output [11:0] Bear,
	output [7:0] Ship
);
	SSC extern_bear
	( 
		.CLK	( Clk	),
		.nRESET	( nReset),
		.pdi_clk( PdiClk),
		.pdi_dat( PdiDat),
		.pdi_lt	( PdiLt	),
		.Square	( Bear	),
		.Ship	( Ship	)
	);
	
endmodule

module SSC( CLK,nRESET,pdi_clk,pdi_dat,pdi_lt,Square,Ship);
	input CLK, nRESET;
	input [1:0] pdi_dat;
	output [1:0] pdi_clk, pdi_lt;
	
	output [11:0] Square;	//Square code
	output [7:0] Ship;		//Ship code
	//output Done;
	
	//internal wire of SN74HC165
	wire [1:0] done;
	wire [15:0] q[1:0];
	
	sn74hc165 u0
	(
		.SH_LD	( pdi_lt[0]	),
		.CLK	( pdi_clk[0]),
		.QH		( pdi_dat[0]), 
		.MCLK	( CLK		),
		.nRESET	( nRESET	),
		.Q		( q[0]		),
		.DONE	( done[0]	)
	);
	
	sn74hc165 u1
	(
		.SH_LD	( pdi_lt[1]	),
		.CLK	( pdi_clk[1]),
		.QH		( pdi_dat[1]), 
		.MCLK	( CLK		),
		.nRESET	( nRESET	),
		.Q		( q[1]		),
		.DONE	( done[1]	)
	);
	
	reg [15:0] q0;
	reg [15:0] q1;
	
	always @(posedge CLK) begin
		if( done[0]) q0 <= q[0][15:0];
	end
	always @(posedge CLK) begin
		if( done[1]) q1 <= q[1][15:0];
	end
	
	assign Square = q0[12:1];
	assign Ship = {q0[13],q0[14],q0[15],q1[0],q1[1],q1[2],q1[3],q1[4]};
	
endmodule

//
// sn74hc165
//
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

	reg [4:0] dcnt;
	wire dclk;
	always @(posedge MCLK,negedge nRESET)begin
		if(!nRESET) dcnt <= {5{1'b0}};
		else dcnt <= dcnt + 1'b1;
	end
	assign dclk = dcnt[4];
	
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