//
// @2017. KeA418, eagle. all right reserved.
//

//
// BearRangeDecodeTop.v
// bear and range decode top level
// eagle
// v1.0.0
// 2017-8-1
//

module BearRangeDecodeTop(
	input Clk33M, Clk40M, nReset,
	//config and status
	input [2:0] WriteAddr, ReadAddr,
	input WriteEnable, ReadEnable,
	input [1:0] Cmd,
	output [11:0] StatusData,
	//extern port
	input [1:0] PdiDat,
	output [1:0] PdiClk, PdiLt,
	input Synclk,
	//insidde port
	input [11:0] InsideBear,
	input InsideSynclk,
	//inside port
	output [11:0] BearCode,
	output [9:0] RangeCode,
	output RangeTrace, AdcLauch,
	output BearNorth
);
	wire [1:0] select;
	ConfigRegDecode config_decode(
		.Clk	( Clk33M ), 
		.nReset	( nReset ),
		.Addr	( WriteAddr ),
		.Enable	( WriteEnable),
		.Command( Cmd),
		.oCmd	( select )
	);

	wire [11:0] ex_bear;
	wire [7:0] ex_ship;
	ExternBearShip ex_bear_ship(
		.Clk	( Clk40M ), 
		.nReset	( nReset ),
		.PdiDat	( PdiDat ),
		.PdiClk	( PdiClk ), 
		.PdiLt	( PdiLt ),
		.Bear	( ex_bear ),
		.Ship	( ex_ship )
	);
	
	wire [11:0] in_bear;
	assign in_bear = InsideBear;
	
	wire [11:0] bear;
	assign bear = select[0] ? ex_bear : in_bear;
	
	wire [3:0] sector;
	BearDecode bear_decode(
		.Clk		( Clk40M ), 
		.nReset		( nReset ),
		.Bear		( bear ),
		.BearSector	( sector ),	
		.BearNorth	( BearNorth ),
		.BearCode	( BearCode )
	);
	
	wire ex_synclk;
	wire [7:0] synclk_cout;
	
	ExternSynclk extern_synclk(
		.Clk		( Clk40M ), 
		.nReset		( nReset ),
		.Synclk		( Synclk ),
		.oSynclk	( ex_synclk ),
		.SynclkCout	( synclk_cout )
	);
	
	wire in_synclk;
	assign in_synclk = InsideSynclk;
	
	wire synclk;
	assign synclk = select[1] ? ex_synclk : in_synclk;
	
	RangeDecode range_decode(
		.Clk		( Clk40M ), 
		.nReset		( nReset ),
		.Synclk		( synclk ),
		.RangeCode	( RangeCode ),
		.RangeTrace	( RangeTrace ),
		.AdcLauch	( AdcLauch )
	);
	
	StatusRegDecode status_decode(
		.Clk		( Clk33M ), 
		.nReset		( nReset ),
		.Addr		( ReadAddr),
		.Enable		( ReadEnable),
		.Select		( select ), 
		.Bear		( bear ),
		.Ship		( ex_ship ),
		.SynclkCount( synclk_cout),
		.Data		( StatusData)
	);

endmodule

module ConfigRegDecode(
	input Clk, nReset,
	input [2:0] Addr,
	input Enable,
	input [1:0] Command,
	output [1:0] oCmd
);
	reg [1:0] cmd;
	always @(posedge Clk, negedge nReset)begin
		if(!nReset) cmd <= {2{1'b0}};
		else if( Enable) begin 
			case (Addr)
				3'd0 : cmd <= Command;
				default : cmd <= cmd;
			endcase
		end
	end
	assign oCmd = cmd;
	
endmodule

module StatusRegDecode(
	input Clk, nReset,
	input [2:0] Addr,
	input Enable,
	input [1:0] Select,
	input [11:0] Bear,
	input [7:0] Ship,
	input [7:0] SynclkCount,
	output [11:0] Data
);
	reg [11:0] data;
	always @(posedge Clk, negedge nReset)begin
		if(!nReset) data <= {12{1'b0}};
		else if(Enable) begin
			case (Addr)
				3'd0 : data <= {10'd0, Select};
				3'd1 : data <= Bear;
				3'd2 : data <= {4'd0, Ship};
				3'd3 : data <= {4'd0, SynclkCount};
				default : data <= {12{1'b0}};
			endcase
		end
	end
	assign Data = data;
	
endmodule