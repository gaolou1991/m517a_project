//
// @2017. KeA-418, eagle. All Right Reserved.
//

//
// stdlib.v.v
// stand librery
// eagle
// 2017-8-1
// v1.0.0
//

module Countor #(parameter Bits = 8)(
	input Clk, nReset,
	input Enable, Clear,
	output [Bits-1:0] Q
);
	reg [Bits-1:0] q;
	always @(posedge Clk, negedge nReset)begin
		if(!nReset) q <= {Bits{1'b0}};
		else if(Clear) q <= {Bits{1'b0}};
		else if(Enable) q <= q + 1'b1;
		else q <= q;
	end
	assign Q = q;
	
endmodule

module CapturePosedge(
	input Clk, nReset,
	input Signals,
	output PosSignals
);
	reg [1:0] pos;
	always @(posedge Clk, negedge nReset)begin
		if(!nReset) pos <= {2{1'b0}};
		else pos <= {pos[0],Signals};
	end
	assign PosSignals = (!pos[0]) & pos[1];
	
endmodule