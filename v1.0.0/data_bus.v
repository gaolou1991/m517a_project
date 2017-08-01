///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: data_bus.v
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

module data_bus(
	input mode_nv, mode_mti_nv, mode_auto, data_source, auto,
	input bitsa, bitsb, bitsc, simulate, 
	output bits, mti_nv
);
	wire bits_nv;
	mux2_1 u0(
		.A_1(bitsb), .B_0(bitsa),
		.S(mode_nv),
		.C(bits_nv)
	);
	
	wire mti_nv_sel;
	mux2_1 u1(
		.A_1(auto), .B_0(mode_mti_nv),
		.S(mode_auto),
		.C(mti_nv_sel)
	);
	assign mti_nv = mti_nv_sel;
	
	wire mti_nv_bits;
	mux2_1 u2(
		.A_1(bitsc), .B_0(bits_nv),
		.S(mti_nv_sel),
		.C(mti_nv_bits)
	);
	
	mux2_1 u3(
		.A_1(simulate), .B_0(mti_nv_bits),
		.S(data_source),
		.C(bits)
	);

endmodule
