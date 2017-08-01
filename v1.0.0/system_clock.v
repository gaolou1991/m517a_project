///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: system_clock.v
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

module system_clock( 
	input clk, reset,				//system signal
	input user_reset,				//user reset
	output state,					//pll lock 0
	// output adc_clk,
	output mclk, aclk, sync_reset
);
	synclock_pll u0(
       .POWERDOWN(1'b1),	//0 power down
       .CLKA(clk),			//33MHz pci bus
       .LOCK(state),		//0 pll state
       .GLA(mclk),			//40MHz main clock
       .GLB(aclk)			//4MHz auix clock
	 // .GLC(adc_clk)			//8MHz adc
    );
	
	//* 异步复位 同步释放
	reg rst_old, rst_new;
	
	wire user_reset2;
	assign user_reset2 = user_reset & reset;
	
	always @(posedge mclk, negedge user_reset2)begin
		if(!user_reset2) begin rst_new <= 1'b0; rst_old <= 1'b0; end
		else begin rst_new <= rst_old; rst_old <= 1'b1; end
	end
	assign sync_reset = rst_new;
	
	//* 异步复位 同步释放
/* 	reg rst_old2, rst_new2;
	
	always @(posedge aclk, negedge user_target_reset)begin
		if(!user_target_reset) begin rst_new2 <= 1'b0; rst_old2 <= 1'b0; end
		else begin rst_new2 <= rst_old2; rst_old2 <= 1'b1; end
	end
	assign target_reset = rst_new2; */

endmodule