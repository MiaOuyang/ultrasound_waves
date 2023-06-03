/*
---------------------------------------------------------
    Name:       hc_sr_top
    Author:     欧阳紫樱
    Date:       2023-5-27
    Time:       20:33
---------------------------------------------------------
    Software:   
                VS Code
*/
module hc_sr_top (
    input   wire        Clk     ,
    input   wire        Rst_n   ,
    input   wire        echo    ,

    output  wire        trig    ,
    output  wire [6:0]  hex1    ,
    output  wire [6:0]  hex2    ,
    output  wire [6:0]  hex3    ,
    output  wire [6:0]  hex4    ,
    output  wire [6:0]  hex5    ,
    output  wire [6:0]  hex6    ,
    output  wire [6:0]  hex7    ,
    output  wire [6:0]  hex8    ,
    output  wire        beep    ,
    output  wire [3:0]  led 
);

wire    [18:0]  data_o;

hc_sr_driver u_hc_sr_driver(
    .Clk        (Clk        ),
    .Rst_n      (Rst_n      ),
    .echo       (echo       ),

    .trig       (trig       ),
    .data_o     (data_o     )
);

seg_driver u_seg_driver(
    .Clk        (Clk        ),
    .Rst_n      (Rst_n      ),
    .data_o     (data_o     ),

    .hex1       (hex1),
    .hex2       (hex2),
    .hex3       (hex3),
    .hex4       (hex4),
    .hex5       (hex5),
    .hex6       (hex6),
    .hex7       (hex7),
    .hex8       (hex8) 
);

beepled u_beepled(
    .Clk        (Clk)   ,
    .Rst_n      (Rst_n) ,
    .data_o     (data_o),
    .beep       (beep)  ,
    .led        (led)
);
endmodule