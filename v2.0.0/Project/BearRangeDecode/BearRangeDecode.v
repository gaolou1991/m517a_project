//
// @2017. KeA418, eagle. all right reserved.
//

//
// BearRangeDecode.v
// bear and range decode
// eagle
// v1.0.0
// 2017-8-1
//

//
// range decode 
// StdLib.v
//
`define		COUNTOR_200K		(8'd200)
`define 	RANGE_TRACE			(10'd600)
`define		ADC_LAUNCH			(8'd1)

module RangeDecode(
	input Clk, nReset,
	input Synclk,
	output [9:0] RangeCode,
	output RangeTrace,
	output AdcLauch
);
	wire pos_synclk;
	CapturePosedge cap_pos_range(
		.Clk		( Clk ),
		.nReset		( nReset ),
		.Signals	( Synclk ),
		.PosSignals	( pos_synclk )
	);
	
	wire [7:0] cout_200k;
	wire clear, clk200k;
	
	assign clk200k = cout_200k == `COUNTOR_200K;
	assign clear = pos_synclk | clk200k;
	
	Countor #(8) countor_200k(
		.Clk	( Clk ),
		.nReset	( nReset ),
		.Enable	( 1'b1 ),
		.Clear	( clear ),
		.Q		( cout_200k )
	);
	
	wire [9:0] range;
	Countor #(10) countor_range(
		.Clk	( Clk ),
		.nReset	( nReset ),
		.Enable	( clk200k ),
		.Clear	( pos_synclk ),
		.Q		( range )
	);
	
	assign RangeCode = range;
	assign RangeTrace = range < `RANGE_TRACE;
	assign AdcLauch = cout_200k == `ADC_LAUNCH;
	
endmodule

module BearDecode(
	input Clk, nReset,
	input [11:0] Bear,
	output [3:0] BearSector,
	output BearNorth,
	output [11:0] BearCode
);
	reg [11:0] bear;
	always @(posedge Clk, negedge nReset)begin
		if(!nReset) bear <= {12{1'b0}};
		else bear <= Bear;
	end
	
	assign BearCode = bear;
	assign BearSector = bear[11:8];
	assign BearNorth = bear[11:8] == 4'd0;

endmodule