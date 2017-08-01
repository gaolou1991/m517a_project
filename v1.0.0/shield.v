///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: shield.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::144 FBGA>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module shield( 
	input reset,
	input rdclk, wrclk,
	input rden, wren,
	input [10:0] wraddr,
	input [6:0] addr,
	input [4:0] bear,
	input wrdata,
	output reg rddata
);

	//* 屏蔽区写数据
	//* 捕获写信号的上升沿
	reg pold, pnew;
	always @(posedge wrclk)begin
		if(!reset) begin pold <= 1'b0; pnew <= 1'b0; end
		else begin pold <= pnew; pnew <= wren; end
	end
	
	wire ram_wren;
	assign ram_wren = pnew & (!pold);
	
/* 	wire write_en;
	assign write_en = pnew & (!pold); */
	
	//* 屏蔽区状态机
	/* localparam [1:0] ws0 = 2'b01, ws1 = 2'b10;
	
	reg ram_wren;
	
	reg [1:0] wcur_sta, wnxt_sta;
	always @(posedge wrclk)begin
		if(!reset) wcur_sta <= ws0;
		else wcur_sta <= wnxt_sta;
	end
	
	always @(*) begin
		case(wcur_sta)
		ws0 : if(write_en) wnxt_sta <= ws1; else wnxt_sta <= ws0;
		ws1 : wnxt_sta <= ws0;
		default : wnxt_sta <= ws0;
		endcase
	end
	
	always @(posedge wrclk)begin
		if(!reset) begin ram_wren <= 1'b0; end
		else begin
			case(wcur_sta)
			ws0 : ram_wren <= 1'b0;
			ws1 : ram_wren <= 1'b1;
			endcase
		end
	end */
	
	//* 屏蔽区读取数据
	wire [5:0]range;
	assign range = addr[6] ? 6'h3F : addr[5:0];
	
	reg [10:0] ram_rdaddr;
	always @(posedge rdclk)begin
		ram_rdaddr <= { bear, range};
	end
	
	localparam [3:0] s0 = 4'b0001, s1 = 4'b0010, s2 = 4'b0100, s3 = 4'b1000;
	
	reg [3:0] cur_sta, nxt_sta;
	always @(posedge rdclk, negedge reset)begin
		if(!reset) cur_sta <= s0;
		else cur_sta <= nxt_sta;
	end
	
	always @(*)begin
		case(cur_sta)
		s0 : if(rden) nxt_sta <= s1; else nxt_sta <= s0;
		s1 : nxt_sta <= s2;
		s2 : nxt_sta <= s3;
		s3 : nxt_sta <= s0;
		default : nxt_sta <= s0;
		endcase
	end
	
	reg ram_rden, done;
	always @(posedge rdclk, negedge reset)begin
		if(!reset) begin ram_rden <= 1'b0; done <= 0; end
		else begin
			case(cur_sta)
			s0 : done <= 1'b0;
			s1 : ram_rden <= 1'b1;
			s2 : ram_rden <= 1'b0;
			s3 : done <= 1'b1;
			endcase
		end
	end
	
	wire ram_rddata;
	always @(posedge rdclk, negedge reset)begin
		if(!reset) rddata <= 1'b0;
		else if(done) rddata <= ram_rddata;
	end
/* 	localparam [2:0] rs0 = 3'b001, rs1 = 3'b010, rs2 = 3'b100;
	
	reg ram_rden;
	reg done;
	wire ram_rddata;
	wire [10:0] ram_rdaddr; */
	
	//* 形成读地址
/* 	wire [5:0] rd_addr;
	assign rd_addr = addr[6] ? addr[5:0] : 6'd63;

	assign ram_rdaddr = {bear, rd_addr};
	
	reg [2:0] rcur_sta, rnxt_sta;
	always @(posedge rdclk, negedge reset)begin
		if(!reset) rcur_sta <= rs0;
		else rcur_sta <= rnxt_sta;
	end
	
	always @(*)begin
		case(rcur_sta)
		rs0 : if(rden) rnxt_sta <= rs1; else rnxt_sta <= rs0;
		rs1 : rnxt_sta <= rs2;
		rs2 : rnxt_sta <= rs0;
		default : rnxt_sta <= rs0;
		endcase
	end

	always @(posedge rdclk, negedge reset)begin
		if(!reset) begin ram_rden <= 1'b0; done <= 1'b0; end	
		else begin
			case(rcur_sta)
			rs0 : done <= 1'b0;
			rs1 : ram_rden <= 1'b1;
			rs2 : begin ram_rden <= 1'b0; done <= 1'b1; end
			endcase
		end
	end */
	
	//*剔除450KM之外的数据
	// wire over;
	// assign over = addr > 7'd74 ? 1'b1 : 1'b0;
	
/* 	always @(posedge rdclk,negedge reset)begin
		if(!reset) rddata <= 1'b0;
		else if(done) rddata <= ram_rddata;//rddata <= ram_rddata | over;
	end */
	
	ram_2048x1bit u0(
		.WD(wrdata),
		.RD(ram_rddata),
		.WEN(ram_wren),
		.REN(ram_rden),
		.WADDR(wraddr),
		.RADDR(ram_rdaddr),
		.WCLK(wrclk),
		.RCLK(rdclk),
		.RESET(reset)
    );
	
endmodule