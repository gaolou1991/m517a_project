///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: pci_bus.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
// v1.0.1 Eagle-2016-11-15 14:32 PM 添加门限更新接口 update_cfar_door update_mti_door
// v1.0.2 Eagle-2016-11-28 10:50 AM 添加扇区号sector到总线上
//
// <Description here>
//
// Targeted device: <Family::ProASIC3> <Die::A3P600> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module pci_bus( 
	//* pin define
	input pci_clk, pci_rstn, pci_idsel,
	inout [31:0]pci_ad,	//inout pin
	inout pci_framen, pci_irdyn, pci_par, pci_intan, pci_trdyn, pci_stopn, pci_serrn, pci_devseln, pci_perrn,
	inout [3:0]pci_cben,-[]
	//* user pin
	output pclk, preset,
	
	output reg [3:0] aa_mux,
	output reg [2:0] bb_mux,
	//* 时钟接口 register 1 0x010
	output reg user_reset, 
	input clock_state,
	//* 解码单元相关端口 register 2 0x020
	output reg [5:0] delay_angle_in,
	input north,
	input [15:0] timer,
	input [3:0] sector,
	//* 数据通路相关端口 register 3 0x030
	input [15:0] ffa_rddata, ffb_rddata, 
	input [31:0] ffc_rddata,
	input [2:0] ffa_rdstate, ffb_rdstate, ffc_rdstate,
	input ff_rdstb,
	output ffa_rden, ffb_rden, ffc_rden,
	input cfifo_done,
	//* register 4 0x040
	output reg [15:0] pf_cfar, step_cfar,
	input [15:0] statistic_cfar,
	input [15:0] update_cfar_door,
	input [15:0] update_mti_door,
	
	output reg [15:0] thresh_hander_nv, thresh_auto_nv, thresh_hander_mti,
	//* register 5 0x050
	//*MTD
	output reg mtd_en, mtd_rst,
	input [1:0]mtd_state, //hb empty
	input [15:0] mtd_data,
	output reg mtd_wen,
	output reg [15:0] mtd_wdata,
	//* course
	input [7:0]course,
	
	output reg [3:0] bus_mode,
	//* 数据处理相关端口 register 6 0x060
	output reg wren_dp,
	output reg [10:0] wraddr_dp,
	output reg  wrdata_dp,
	//* register 7 0x070
	output reg [7:0] thresh_target_start, thresh_target_end,
	//* 测试模块端口 register 8 0x080
	output reg [31:0] angle, angle2, angle3, angle4,
	output reg [9:0] range, range2, range3, range4,
	output reg [31:0] range_mode, angle_mode,
	output reg [3:0] target_enable,
	output reg [7:0]self_check,
	output  reg sim_target_sel,//, user_target_reset
	
	input [7:0] SyncCnt
);

//*
//* PCI pin 
//* the connection of PCI wire
//* The global pin of PCI 		
	wire lreset;		//system reset, out form PCI
	wire bpclk;			//system clock, out from PCI
	
	wire wr_cyc, rd_cyc;  
	wire [31:0] data_out; 
	wire [31:0] data_in;
	wire [3:0] wr_be_now; 
	wire rd_std_out;
	wire [11:0]ma;		//memey address
	wire [2:0] bar_select;
	wire rd_stb_in;


	HPCI pci_u0( 							//@ pci core by actel
		// Inputs
		.BUSY          ( 1'b0        ),   //  When HIGH, indicating  backend  cannot complete the current transfer
		.CLK           ( pci_clk     ),
		.ERROR         ( 1'b0        ),   //  When HIGH, force the PCI core to terminate
		.EXT_INTN      ( 1'b1        ),   //  Active LOW interrupt from the backend
		.IDSEL         ( pci_idsel   ),
		.MEM_DATA_IN   ( data_in 	 ),
		.RD_STB_IN     (rd_stb_in),   // Active HIGH , indicating  backend is ready to provide data to the core
		.RD_SYNC       ( 1'b0        ),   // Null use
		.RSTN          ( pci_rstn    ),   //  
		.WR_BE_RDY     ( 1'b1        ),   // When HIGH, indicating  backend is ready to receive data from the core
	
		// Outputs
		.BAR_SELECT   ( bar_select ),     // 
		.BYTE_ENN     (            ),     // byte enable          some backend logic need 
		.BYTE_VALN    (            ),     // strobe byte enable   some backend logic need
		.CFG_STATUS   (            ),     // 
		.CLK_OUT      ( bpclk      ),     // buffered PCI clock
		.DP_DONE      ( 		   ),
		.DP_START     ( 		   ),
		.FRAMEN_OUT   (            ),
		.INTAN_OUT    (            ),
		.IRDYN_OUT    (            ),     // Buffered of pci_sign
		.MEM_ADD      ( ma         ),
		.MEM_DATA_OE  (            ),     // for bidirectional I/O
		.MEM_DATA_OUT ( data_out   ),
		.RD_CYC       ( rd_cyc     ),     // no use
		.RD_STB_OUT   ( rd_std_out ),
		.RST_OUTN     ( lreset     ), 
		.SERRN_OUT    (            ),
		.WR_BE_NOW    ( wr_be_now  ),     // byte select
		.WR_CYC       ( wr_cyc     ),     // write to local bus
	
		// Inouts
		.AD           ( pci_ad     ),
		.CBEN         ( pci_cben   ),
		.DEVSELN      ( pci_devseln),
		.FRAMEN       ( pci_framen ),
		.INTAN        ( pci_intan  ),
		.IRDYN        ( pci_irdyn  ),
		.M66EN        (            ),
		.PAR          ( pci_par    ),
		.PERRN        ( pci_perrn  ),
		.SERRN        ( pci_serrn  ),
		.STOPN        ( pci_stopn  ),
		.TRDYN        ( pci_trdyn  ));
	
//* 
//* clock reset
assign pclk = bpclk;
assign preset = lreset;
	
//* 
//* The register config
//* Enable signal
	wire wr2, rd2;
	wire [31:0]ld;

	assign   wr2 = ((bar_select [2:0] == 3'h2) && (wr_be_now[3:0]!=4'h0) && wr_cyc ) ? 1'b1 : 1'b0;
	assign   rd2 = ((bar_select [2:0] == 3'h2) && (rd_cyc )) ? 1'b1 : 1'b0;
	
	reg [6:0] wraddr;
	reg [4:0] wrbear;
	
	wire [5:0] wraddr2;
	assign wraddr2 = wraddr[6] ? 6'h3F : wraddr[5:0];
	
	reg fifo_rden;
	
	// assign wraddr_dp = {wrbear, wraddr2};
	always @(posedge bpclk)begin
		wraddr_dp <= {wrbear, wraddr2};
	end

	//* The wirte function of PCI
	//* add your use at here
	always@(posedge bpclk )begin  //   pci read funtion logic
		if( !lreset)begin  
			aa_mux <= 4'b1100; bb_mux <= 3'b110;
			user_reset <= 1'b0;
			delay_angle_in <= 6'd29; 
			pf_cfar <= 16'd50; step_cfar <= 16'd5;//error_mti <= 16'd50; step_mti <= 16'd5;
			thresh_hander_nv <= 16'h8500; thresh_auto_nv <= 16'h8000; thresh_hander_mti <= 16'h8500;
			bus_mode <= 4'b0000;
			wren_dp <= 1'b0; wraddr <= 6'd0; wrbear <= 5'd0; wrdata_dp <= 1'd0;
			thresh_target_start <= 8'd9; thresh_target_end <= 8'd9;
			// sim_angle <= 1'b1; sim_range <= 1'b1; sim_speed <= 1'b1; sim_mode <= 3'b111; sim_target_range <= 10'd200;
			self_check <= 8'b1111_1111; /* dac1_data <= 16'hFFFF; */ 
			sim_target_sel <= 1'b0;
			//sim_target_sel <= 1'b1; //2017-3-22 change the value to 1
			//angle <= 32'h0250_01B0; angle2 <= 32'h0350_02B0; angle3 <= 32'h0850_07B0; angle4 <= 32'h0C50_0BB0;
			//range <= 10'd266; range2 <= 10'd400; range3 <= 10'd533; range4 <= 10'd133;
			angle <= 32'h0C50_0BB0; angle2 <= 32'h0350_02B0; angle3 <= 32'h0850_07B0; angle4 <= 32'h0250_01B0;
			range <= 10'd120; range2 <= 10'd120; range3 <= 10'd120; range4 <= 10'd120;
			angle_mode <= 32'h0202_0202; range_mode <= 32'h0000_0000;
			target_enable <= 4'b1111; //user_target_reset <= 1'b0; 
			//angle_mode <= 32'h0000_0000; range_mode <= 32'h0000_0000;
			//target_enable <= 4'b1111; //user_target_reset <= 1'b0; 
			mtd_en <= 1'b1;
			fifo_rden <= 1'b0;
		end
		else if(wr2)
			case(ma[11:2]) 
			10'h003 : aa_mux <= ld[3:0];
			10'h004 : bb_mux <= ld[2:0];
			
			10'h010 : user_reset <= ld[0];
			// 10'h011 : clock_state <= ld[0];
			
			10'h020 : delay_angle_in <= ld[5:0];
			// 10'h021 : north <= ld[0];
			// 10'h022 : timer <= ld[15:0];
			
			// 10'h030 : ffa_rddata <= ld[15:0];
			// 10'h031 : ffb_rddata <= ld[15:0];
			// 10'h032 : ffc_rddata <= ld[15:0];
			// 10'h033 : ffa_rdstate <= ld[2:0];
			// 10'h034 : ffb_rdstate <= ld[2:0];
			// 10'h035 : ffc_rdstate <= ld[2:0];
			10'h036 : fifo_rden <= ld[0];
			
			10'h040 : pf_cfar <= ld[15:0];
			10'h041 : step_cfar <= ld[15:0];
			// 10'h043 : error_mti <= ld[15:0];
			// 10'h044 : step_mti <= ld[15:0];
			10'h045 : thresh_hander_nv <= ld[15:0];
			10'h046 : thresh_auto_nv <= ld[15:0];
			10'h047 : thresh_hander_mti <= ld[15:0];
			10'h048 : mtd_en <= ld[0];
			10'h053 : mtd_rst <= ld[0];
			10'h051 : mtd_wen <= ld[0];
			10'h052 : mtd_wdata <= ld[15:0];
			
			10'h050 : bus_mode <= ld[4:0];
			
			10'h060 : wren_dp <= ld[0];
			10'h061 : wraddr <= ld[6:0];
			10'h062 : wrdata_dp <= ld[0];
			10'h063 : wrbear <= ld[4:0];
			
			10'h070 : thresh_target_start <= ld[7:0];
			10'h071 : thresh_target_end <= ld[7:0]; 
			
			10'h080 : self_check <= ld[7:0];
			10'h087 : sim_target_sel <= ld[0];
			
			10'h090 : angle_mode <= ld[31:0];
			10'h091 : range_mode <= ld[31:0];
			10'h092 : angle  <= ld[31:0];
			10'h093 : range  <= ld[9:0];
			10'h094 : angle2 <= ld[31:0];
			10'h095 : range2 <= ld[9:0];
			10'h096 : angle3 <= ld[31:0];
			10'h097 : range3 <= ld[9:0];
			10'h098 : angle4 <= ld[31:0];
			10'h099 : range4 <= ld[9:0];
			10'h09A : target_enable <= ld[3:0];
			endcase 
		else begin   
		end
	end    
		 
	//* Output bus
	assign ld  = data_out;
//////////////////////////////////////////////////////////////////////////////////////////////
//*
//* The read function of PCI
	reg [31:0]rld;
	
	//* add your use at here
	always @( * )begin  //  pci read funtion logic
		case(ma[11:2])
		10'h000 : rld <= 32'h20162016;
		10'h001 : rld <= 32'h4CF4F33C;
		10'h002 : rld <= 32'h8DDA3B5F;
		10'h003 : rld <= 32'h23261635;
		10'h004 : rld <= 32'hDA821395;
		10'h005 : rld <= 32'h113AA564;
		10'h006 : rld <= 32'h8E6A4C44;
		10'h007 : rld <= 32'hB4EB20F0;
		10'h008 : rld <= 32'hFEECC579;
		
		
		10'h010 : rld <= {31'd0, user_reset};
		10'h011 : rld <= {31'd0, clock_state};
		
		10'h020 : rld <= {26'd0, delay_angle_in};
		10'h021 : rld <= {31'd0, north};
		10'h022 : rld <= {16'd0, timer};
		10'h023 : rld <= {28'd0, sector}; //Eagle-2016-11-28
		
		10'h030 : rld <= {16'd0, ffa_rddata};
		10'h031 : rld <= {16'd0, ffb_rddata};
		10'h032 : rld <= ffc_rddata;
		10'h033 : rld <= {29'd0, ffa_rdstate};
		10'h034 : rld <= {29'd0, ffb_rdstate};
		10'h035 : rld <= {29'd0, ffc_rdstate};
		//10'h036 : rld <= {}
		10'h037 : rld <= {31'd0, cfifo_done};
		
		10'h040 : rld <= {16'd0, pf_cfar};
		10'h041 : rld <= {16'd0, step_cfar};
		10'h042 : rld <= {16'd0, statistic_cfar};
		10'h043 : rld <= {16'd0, update_cfar_door}; //Eagle-2016-11-15
		10'h044 : rld <= {16'd0, update_mti_door};   //Eagle-2016-11-15
		10'h045 : rld <= {16'd0, thresh_hander_nv};
		10'h046 : rld <= {16'd0, thresh_auto_nv};
		10'h047 : rld <= {16'd0, thresh_hander_mti};
		10'h048 : rld <= {31'd0, mtd_en};
		10'h049 : rld <= {29'd0, mtd_state};
		10'h04a : rld <= {16'd0, mtd_data};
		10'h04b : rld <= {24'd0, course};
		
		10'h050 : rld <= {29'd0, bus_mode};
		
		10'h060 : rld <= {31'd0, wren_dp};
		10'h061 : rld <= {21'd0, wraddr_dp};
		10'h062 : rld <= {31'd0, wrdata_dp};
		
		10'h070 : rld <= {25'd0, thresh_target_start};
		10'h071 : rld <= {25'd0, thresh_target_end};
		
		10'h080 : rld <= {24'd0, self_check};
		10'h087 : rld <= {31'd0, sim_target_sel};
		
		10'h090 : rld <= angle_mode;
		10'h091 : rld <= range_mode;
		10'h092 : rld <= angle;
		10'h093 : rld <= {22'd0, range};
		10'h094 : rld <= angle2;
		10'h095 : rld <= {22'd0, range2};
		10'h096 : rld <= angle3;
		10'h097 : rld <= {22'd0, range3};
		10'h098 : rld <= angle4;
		10'h099 : rld <= {22'd0, range4};
		10'h09a : rld <= {28'd0,target_enable};
		
		10'h0A0 : rld <= {24'd0,SyncCnt};

		default : rld <= 32'h09322016;
		endcase    
	end

 	//* Select the input bus
	assign  data_in  =  ((bar_select [2:0] == 3'h2)&&(rd_cyc ))  ? rld[31:0] : 32'hzzzzzzzz;    

//////////////////////////////////////////////////////////////////////////////////////////////

	//assign ff_rden = (rd2 && (ma[11:2]==10'h030)) ? 1'b1 : 1'b0;
	//read data enable
	assign ffa_rden = (rd2 && (ma[11:2]==10'h030)) ? 1'b1 : 1'b0;
	assign ffb_rden = (rd2 && (ma[11:2]==10'h031)) ? 1'b1 : 1'b0;
	//assign ffc_rden = (rd2 && (ma[11:2]==10'h032)) ? 1'b1 : 1'b0;
	assign ffc_rden = fifo_rden;

	
	assign rd_stb_in = ff_rdstb;
	
	

//////////////////////////////////////////////////////////////////////////////////////////////
// interrupt
	
	// assign intn = 1'b1;
	
	
endmodule