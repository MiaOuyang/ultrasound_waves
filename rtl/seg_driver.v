/*
---------------------------------------------------------
    Name:       seg_driver
    Author:     欧阳紫樱
    Date:       2023-5-27
    Time:       20:01
---------------------------------------------------------
    Software:   
                VS Code
*/
module seg_driver(
    input   wire        Clk     ,
    input   wire        Rst_n   ,
    input   wire [18:0] data_o  ,

    output  wire [6:0]  hex1    ,
    output  wire [6:0]  hex2    ,
    output  wire [6:0]  hex3    ,
    output  wire [6:0]  hex4    ,
    output  wire [6:0]  hex5    ,
    output  wire [6:0]  hex6    ,
    output  wire [6:0]  hex7    ,
    output  wire [6:0]  hex8     
);

parameter   NOTION  = 4'd10,
            FUSHU   = 4'd11;
parameter   MAX20us = 10'd1000;
reg [9:0]   cnt_20us;
reg [7:0]   sel_r;
reg [3:0]   number;
reg [6:0]   seg_r;
reg [6:0]   hex1_r;
reg [6:0]   hex2_r;
reg [6:0]   hex3_r;
reg [6:0]   hex4_r;
reg [6:0]   hex5_r;
reg [6:0]   hex6_r;
reg [6:0]   hex7_r;
reg [6:0]   hex8_r;



//20微妙计数器
always @(posedge Clk or negedge Rst_n) begin
    if (!Rst_n) begin
        cnt_20us <= 10'd0;
    end
    else if (cnt_20us == MAX20us - 1'd1) begin
        cnt_20us <= 10'd0;
    end
    else begin
        cnt_20us <= cnt_20us + 1'd1;
    end
end



//单个信号sel_r位拼接约束
always @(posedge Clk or negedge Rst_n) begin
    if (!Rst_n) begin
        sel_r <= 8'b11_11_11_10;
    end
    else if (cnt_20us == MAX20us - 1'd1) begin
        sel_r <= {sel_r[6:0],sel_r[7]};
    end
    else begin
        sel_r <= sel_r;
    end
end

/*拿到数字*/
always @(*) begin
    case (sel_r)
        8'b11_11_11_10:     number  = NOTION                                        ;
        8'b11_11_11_01:     number  = data_o/10_0000                                ;
        8'b11_11_10_11:     number  = (data_o%10_0000)/1_0000                       ;
        8'b11_11_01_11:     number  = ((data_o%10_0000)%1_0000)/1000                ;
        8'b11_10_11_11:     number  = FUSHU                                         ;
        8'b11_01_11_11:     number  = (((data_o%10_0000)%1_0000)%1000)/100          ;
        8'b10_11_11_11:     number  = ((((data_o%10_0000)%1_0000)%1000)%100)/10     ;
        8'b01_11_11_11:     number  = ((((data_o%10_0000)%1_0000)%1000)%100)%10     ;
        default:            number  = 4'd0                                          ;
    endcase
end

/*通过数字解析出seg值*/
always @(*) begin
    case (number)
        4'd0    :       seg_r   =  7'b100_0000;
        4'd1    :       seg_r   =  7'b111_1001;
        4'd2    :       seg_r   =  7'b010_0100;
        4'd3    :       seg_r   =  7'b011_0000;
        4'd4    :       seg_r   =  7'b001_1001;
        4'd5    :       seg_r   =  7'b001_0010;
        4'd6    :       seg_r   =  7'b000_0010;
        4'd7    :       seg_r   =  7'b111_1000;
        4'd8    :       seg_r   =  7'b000_0000;
        4'd9    :       seg_r   =  7'b001_0000;
        NOTION  :       seg_r   =  7'b111_1111;
        FUSHU   :       seg_r   =  7'b011_1111;
        default :       seg_r   =  7'b111_1111;
    endcase
end

always @(*) begin
    case (sel_r)
		8'b11_11_11_10:     hex1_r = seg_r;
		8'b11_11_11_01:     hex2_r = seg_r;
		8'b11_11_10_11:     hex3_r = seg_r;
		8'b11_11_01_11:     hex4_r = seg_r;
		8'b11_10_11_11:     hex5_r = seg_r;
		8'b11_01_11_11:     hex6_r = seg_r;
		8'b10_11_11_11:     hex7_r = seg_r;
		8'b01_11_11_11:     hex8_r = seg_r;
		default:            seg_r  = seg_r;
	endcase
end

assign  hex1 = hex1_r;
assign  hex2 = hex2_r;
assign  hex3 = hex3_r;
assign  hex4 = hex4_r;
assign  hex5 = hex5_r;
assign  hex6 = hex6_r;
assign  hex7 = hex7_r;
assign  hex8 = hex8_r;

endmodule