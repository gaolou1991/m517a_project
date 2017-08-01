// AD5632.v
module  AD5632  (
   input          bpclk    ,
   input          lreset   ,

   input          xtm_trg  , // Ê±ÖÓ±ä»»±ßÔµ
   input          xtm_clk  , 

   output         dac_rst  ,
   output         dac_clr  ,
   output         dac_clk  ,
   output         dac_cs   , 
   output         dac_dat  ,
   output         dac_lt   ,

   input  [31:0]  cmd_dat  ,
   input          cmd_str  
  
 );


 reg [23:0]  run_buf   ;
 reg [4 :0]  run_cnt   ;
 reg [3 :0]  run_sta   ;
 reg         run_cs    ;
 reg         run_lt    ;

 always@(posedge bpclk)                    
  begin
     if( !lreset)   
         begin  
		  run_buf <=25'h1234567;
          run_cnt <= 0  ;
          run_cs  <= 1  ;
          run_sta <= 0  ;
          run_lt  <= 1  ;
         end
      else
      case( run_sta[3:0])
       
      4'h0 :begin  
              if( cmd_str )
                 begin
                  run_buf[23:0]  <= cmd_dat [23:0] ;
                  run_cnt        <= 5'h17    ;
                  run_sta        <= 14'h1    ; 
                 end
            end
      4'h1 :begin
               if(xtm_trg && (!xtm_clk)) 
                  begin 
                    run_cs <=0   ;
                    run_sta<=4'h2 ;
                  end
            end
       4'h2:begin
               if(xtm_trg && (!xtm_clk))  
                  begin  
                    run_buf[23:0]  <= {run_buf[22:0] ,1'b1};
                    run_cnt        <= run_cnt-1;
                    if(run_cnt==0) run_sta<=4'h3 ;
                  end
             end
        4'h3:begin  
                run_sta<= 4'h4 ;
                run_cs <= 1'b1 ;

             end
       
        4'h4:begin  
                if(xtm_trg && (!xtm_clk))  
                 begin 
                     run_sta<= 4'h5 ;
                     run_lt <= 1'b0 ;
                 end
             end
       
        4'h5:begin  
                if(xtm_trg && (!xtm_clk))  
                begin  
                     run_sta<= 4'h0 ;
                     run_lt <= 1'b1 ;
                end
             end

        default : run_cs<=1'b1;
        
        endcase       
     
  end      
  assign dac_rst =  lreset     ;
  assign dac_clr =  1'b1       ;
  assign dac_clk =  xtm_clk    ;
  assign dac_cs  =  run_cs     ;
  assign dac_dat =  run_buf[23];
  assign dac_lt  =  run_lt     ; 

 endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
 