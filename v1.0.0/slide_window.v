///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: slide_window.v
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
`ifdef RAM_CLR_ADDR
`undef RAM_CLR_ADDR
`endif

`define		RAM_CLR_ADDR		(10'd598)		//0~599

module slide_window( 
	input clk, reset,
	input bits,
	input start,
	input [9:0] addr,
	output reg done,
	output reg [7:0] sum
);
	
	localparam [7:0] r0 = 8'b0000_0001, s0 = 8'b0000_0010, s1 = 8'b0000_0100, s2 = 8'b0000_1000, s3 = 8'b0001_0000,
					 s4 = 8'b0010_0000, s5 = 8'b0100_0000;
	
	reg read_en, write_en, sum_en, shift_en;
	reg clr_en;
	reg [9:0] clr_addr;
	reg [39:0] shift;
	
	wire [39:0] ram_rddata, ram_wrdata;
	wire [9:0] ram_wraddr;
	
	reg [7:0] cur_sta, nxt_sta;
	always @(posedge clk, negedge reset)begin
		if(!reset) cur_sta <= r0;
		else cur_sta <= nxt_sta;
	end
	
	always @(*)begin
		case(cur_sta)
		r0 : if(clr_addr == `RAM_CLR_ADDR) nxt_sta <= s0; else nxt_sta <= r0;
		s0 : if(start) nxt_sta <= s1; else nxt_sta <= s0;
		s1 : nxt_sta <= s2;
		s2 : nxt_sta <= s3;
		s3 : nxt_sta <= s4;
		s4 : nxt_sta <= s5;
		s5 : nxt_sta <= s0;
		default : nxt_sta <= s0;
		endcase
	end
	
	always @(posedge clk, negedge reset)begin
		if(!reset) begin
			read_en <= 1'b0; write_en <= 1'b0; sum_en <= 1'b0; shift_en <= 1'b0;
			clr_en <= 1'b0; done <= 1'b0;
		end
		else begin
			case(cur_sta)
			r0 : begin clr_en <= 1'b1; write_en <= 1'b1; end
			s0 : begin clr_en <= 1'b0; done <= 1'b0; write_en <= 1'b0; end
			s1 : begin read_en <= 1'b1; end
			s2 : begin read_en <= 1'b0; shift_en <= 1'b1; end
			s3 : begin shift_en <= 1'b0; write_en <= 1'b1; end
			s4 : begin write_en <= 1'b0; sum_en <= 1'b1; end
			s5 : begin sum_en <= 1'b0; done <= 1'b1; end
			endcase
		end
	end
	
	//* RESET RAM
	always @(posedge clk, negedge reset)begin
		if(!reset) clr_addr <= {10{1'b0}};
		else if(clr_en) clr_addr <= clr_addr + 1'b1;
	end
	
	//* 移位
	always @(posedge clk, negedge reset)begin
		if(!reset) shift <= {40{1'b0}};
		else if(shift_en) shift <= {ram_rddata[38:0], bits};
	end
	
	//* 求和
	always @(posedge clk, negedge reset)begin
		if(!reset) sum <= {8{1'b0}};
		else if(sum_en) sum <= shift[0] + shift[1] + shift[2] + shift[3] + shift[4] + shift[5] + shift[6]
		+ shift[7] + shift[8] + shift[9] + shift[10] + shift[11] + shift[12] + shift[13] + shift[14]
		+ shift[15] + shift[16] + shift[17] + shift[18] + shift[19] + shift[20] + shift[21] + shift[22] 
		+ shift[23] + shift[24] + shift[25] + shift[26] + shift[27] + shift[28] + shift[29] + shift[30]
		+ shift[31] + shift[32] + shift[33] + shift[34] + shift[35] + shift[36] + shift[37] + shift[38]
		+ shift[39];
	end
	
	//* RAM
	assign ram_wrdata = clr_en ? {40{1'b0}} : shift;
	assign ram_wraddr = clr_en ? clr_addr : addr;
	
/* 	block_ram u0( 
		.clk(clk), 
		.reset(reset),
		.wrdata(ram_wrdata),
		.rddata(ram_rddata),
		.rdaddr(addr), 
		.wraddr(ram_wraddr),
		.wren(write_en), 
		.rden(read_en)
	); */
	ram_600x40bit u0(
		.WD(ram_wrdata),
		.RD(ram_rddata),
		.WEN(write_en),
		.REN(read_en),
		.WADDR(ram_wraddr),
		.RADDR(addr),
		.RWCLK(clk),
		.RESET(reset)
    );

endmodule

