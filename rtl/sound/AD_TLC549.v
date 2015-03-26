/****************************************Copyright (c)**************************************************
**                                      Dongdong   Studio 
**                                     
**---------------------------------------File Info-----------------------------------------------------
** File name:           AD_TLC549
** Last modified Date:  2012-10-8
** Last Version:        1.1
** Descriptions:        AD_TLC549
**------------------------------------------------------------------------------------------------------
** Created by:          dongdong
** Created date:        2012-10-8
** Version:             1.0
** Descriptions:        The original version
**
**------------------------------------------------------------------------------------------------------
** Modified by:
** Modified date:
** Version:
** Descriptions:
**
**------------------------------------------------------------------------------------------------------
********************************************************************************************************/
module AD_TLC549 ( 
                  //input 
input             sys_clk             ,    //system clock;
input             sys_rst_n           ,    //system reset, low is active;

input             AD_IO_DATA          ,    

                  //output 
output reg        AD_IO_CLK           ,     
output reg        AD_CS               ,    

output reg [7:0]  LED                 
              );

//Reg define 
reg    [4:0]             div_cnt             ;
reg                      ad_clk              ;

reg    [4:0]             ctrl_cnt            ;

reg    [7:0]             ad_data_shift       ;

//Wire define 


//************************************************************************************
//**                              Main Program    
//**  
//************************************************************************************


// counter used for div osc clk to ad ctrl clk  24M/32 = 0,75Mhz
always @(posedge sys_clk or negedge sys_rst_n) begin 
    if (sys_rst_n ==1'b0) 
        div_cnt <= 4'b0;
    else  
        div_cnt <= div_cnt + 4'b1;
end

//gen ad_clk
always @(posedge sys_clk or negedge sys_rst_n) begin 
    if (sys_rst_n ==1'b0) 
	     ad_clk <= 1'b0 ;
    else if ( div_cnt <= 4'd16 ) 
        ad_clk <= 1'b1 ;
    else  
        ad_clk <= 1'b0 ;
end

// ad ctrl signal gen 
// ctrl_cnt  0 - 32is for ad ctrl

always @(posedge ad_clk or negedge sys_rst_n) begin 
    if (sys_rst_n ==1'b0) 
        ctrl_cnt <= 5'b0;
    else  
        ctrl_cnt <= ctrl_cnt + 5'b1;
end

always @(posedge ad_clk or negedge sys_rst_n) begin 
    if (sys_rst_n ==1'b0) 
        AD_IO_CLK <= 1'b0;
    else if (  ctrl_cnt == 5'd6  || ctrl_cnt == 5'd8  || ctrl_cnt == 5'd10
            || ctrl_cnt == 5'd12 || ctrl_cnt == 5'd14 || ctrl_cnt == 5'd16 
            || ctrl_cnt == 5'd18 || ctrl_cnt == 5'd20	)  // ad clk low
        AD_IO_CLK <= 1'b1;
	 else
	     AD_IO_CLK <= 1'b0;
end

always @(posedge ad_clk or negedge sys_rst_n) begin 
    if (sys_rst_n ==1'b0) 
        AD_CS <= 1'b1;
    else if ( ctrl_cnt >= 5'd1 && ctrl_cnt <= 5'd25 )  // ad output cs
        AD_CS <= 1'b0;
	 else
	     AD_CS <= 1'b1;
end

 // shift AD return analog DATA to ad_data_shift reg use AD_IO_CLK rising edge
always @(posedge ad_clk or negedge sys_rst_n) begin 
    if (sys_rst_n ==1'b0) 
        ad_data_shift <= 8'b0;
    else if ( AD_CS == 1'b1 )
        ad_data_shift <= 8'b0;
    else if ( AD_IO_CLK == 1'b1 )     
        ad_data_shift <= { ad_data_shift[6:0], AD_IO_DATA } ;
    else ;
end

//display AD sample data to LED when ad_data_shift is constanct
always @(posedge ad_clk or negedge sys_rst_n) begin 
    if (sys_rst_n ==1'b0) 
        LED <= 8'b0;
    else if ( ctrl_cnt == 5'd23 )
        LED <= ad_data_shift ;
    else ;
end

endmodule
//end of RTL code                       

