//
// @2017. KeA418, eagle. all right reserved.
//

//
// ExternSynclk.v
// extern synclk signals
// eagle
// v1.0.0
// 2017-8-1
//

module ExternSynclk(
	input Clk, nReset,
	input Synclk,
	output oSynclk,
	output [7:0] SynclkCout
);
	reg synclk;
	always @(posedge Clk, negedge nReset)begin
		if(!nReset) synclk <= 1'b0;
		else synclk <= Synclk;
	end
	
	wire pos_synclk;
	CapturePosedge cap_pos_synclk(
		.Clk		( Clk ),
		.nReset		( nReset ),
		.Signals	( Synclk ),
		.PosSignals	( pos_synclk )
	);
	
	wire [7:0] synclk_cout;
	Countor #(8) countor_range(
		.Clk	( Clk ),
		.nReset	( nReset ),
		.Enable	( pos_synclk ),
		.Clear	( 1'b0 ),
		.Q		( synclk_cout )
	);
	
	assign oSynclk = synclk;
	assign SynclkCout = synclk_cout;
	
endmodule
