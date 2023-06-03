/*
---------------------------------------------------------
    Name:       hc_sr_driver
    Author:     欧阳紫樱
    Date:       2023-5-27
    Time:       19:50
---------------------------------------------------------
    Software:   
                VS Code
*/
module hc_sr_driver (
    input   wire        Clk     ,
    input   wire        Rst_n   ,
    input   wire        echo    ,

    output  wire        trig    ,
    output  wire [18:0] data_o  
);

wire        clk_us;


hc_sr_echo u_hc_sr_echo(
	.Clk		(Clk    ), //clock 50MHz
	.clk_us	    (clk_us ), //system clock 1MHz
	.Rst_n	    (Rst_n  ), //reset ，low valid
	
	.echo	    (echo   ), //
	.data_o	    (data_o )  //检测距离，保留3位小数，*1000实现
);

hc_sr_trig u_hc_sr_trig(
	.clk_us	    (clk_us ), //system clock 1MHz
	.Rst_n	    (Rst_n  ), //reset ，low valid
	
	.trig	    (trig   )//触发测距信号
);

clk_div u_clk_div(
	.Clk		(Clk    ), //system clock 50MHz
	.Rst_n	    (Rst_n  ), //reset ，low valid
	
	.clk_us     (clk_us )//
);


endmodule

