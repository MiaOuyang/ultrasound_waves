# 前言
## 环境
- 硬件
	DE2-115
	HC-SR04超声波传感器
- 软件
	Quartus 18.1
## 目标结果
使用DE2-115开发板驱动HC-SR04模块，并将所测得数据显示到开发板上的数码管。
> 为模拟倒车雷达，添加蜂鸣器指示，小于20cm，1s一响；小于10cm，0.5s一响

# 1 实验原理
## 1.1 超声波原理
`HC-SR04`超声波测距模块可提供 2cm-400cm的非接触式距离感测功能，测距精度可达高到 3mm；模块包括超声波发射器、接收器与控制电路。图1为`HC-SR04`外观，其基本工作原理为给予此超声波测距模块触发信号后模块发射超声波，当超声波投射到物体而反射回来时，模块输出回响信号，以触发信号和回响信号间的时间差，来判定物体的距离。

![在这里插入图片描述](https://img-blog.csdnimg.cn/dbdd688b7df34e3a9274d20ee601e553.png)
![在这里插入图片描述](https://img-blog.csdnimg.cn/1f0a23590fcc450dbe31470328445c0a.png)

## 1.2 硬件模块时序图

![在这里插入图片描述](https://img-blog.csdnimg.cn/4d45e49c907d4e059c978683d2582e97.png)

以上时序图表明你只需要提供-个10uS以上脉冲触发信号，该模块内部将发出8个40kHz周期电平并检测回波。一旦检测到有回波信号则输出回响信号。回响信号的脉冲宽度与所测的距离成正比。由此通过发射信号到收到的回响信号时间间隔可以计算得到距离。公式: uS/58 =厘米或者uS/148= =英寸;或是:距离=高电平时间*声速(340M/S) /2;建议测量周期为60ms以上，以防止发射信号对回响信号的影响。
## 1.3 模块说明
DE2-115引脚分配如下

![在这里插入图片描述](https://img-blog.csdnimg.cn/055d995d90674f6fb8e9f4634b8004c0.png)

HC-SR04超声波测距模块需要5V供电，其余trigger和echo自由接线，本文使用的是GPIO[0]和GPIO[1]

# 2 设计文件
## 2.1 时钟分频
定义时钟分频模块，产生周期为`1us`的时钟信号

```verilog
module 	clk_div(
	input  wire			Clk		, //system clock 50MHz
	input  wire 		Rst_n	, //reset ，low valid
		   
	output wire  		clk_us 	  //
);
//Parameter Declarations
	parameter CNT_MAX = 19'd50;//1us的计数值为 50 * Tclk（20ns）

//Interrnal wire/reg declarations
	reg		[5:00]	cnt		; //Counter 
	wire			add_cnt ; //Counter Enable
	wire			end_cnt ; //Counter Reset 
	
//Logic Description
	
	always @(posedge Clk or negedge Rst_n)begin  
		if(!Rst_n)begin  
			cnt <= 'd0; 
		end  
		else if(add_cnt)begin  
			if(end_cnt)begin  
				cnt <= 'd0; 
			end  
			else begin  
				cnt <= cnt + 1'b1; 
			end  
		end  
		else begin  
			cnt <= cnt;  
		end  
	end 
	
	assign add_cnt = 1'b1; 
	assign end_cnt = add_cnt && cnt >= CNT_MAX - 19'd1;
	
	assign clk_us = end_cnt;
	

endmodule 
```
## 2.2 超声波测距
实现`HC-SR04`超声波传感器的触发模块，用于生成触发测距信号（trig）

```verilog
module 	hc_sr_trig(
	input  wire			clk_us	, //system clock 1MHz
	input  wire 		Rst_n	, //reset ，low valid
		   
	output wire  		trig	  //触发测距信号
);
//Parameter Declarations
	parameter CYCLE_MAX = 19'd300_000;

//Interrnal wire/reg declarations
	reg		[18:00]	cnt		; //Counter 
	wire			add_cnt ; //Counter Enable
	wire			end_cnt ; //Counter Reset 

//Logic Description	
	
	always @(posedge clk_us or negedge Rst_n)begin  
		if(!Rst_n)begin  
			cnt <= 'd0; 
		end  
		else if(add_cnt)begin  
			if(end_cnt)begin  
				cnt <= 'd0; 
			end  
			else begin  
				cnt <= cnt + 1'b1; 
			end  
		end  
		else begin  
			cnt <= cnt;  
		end  
	end 
	
	assign add_cnt = 1'b1; 
	assign end_cnt = add_cnt && cnt >= CYCLE_MAX - 9'd1; 
	
	assign trig = cnt < 15 ? 1'b1 : 1'b0;

endmodule 
```
定义`HC-SR04`超声波传感器的回声模块，用于测量距离并输出检测距离数据（data_o）
```verilog
module 	hc_sr_echo(
	input  wire 		Clk		, //clock 50MHz
	input  wire			clk_us	, //system clock 1MHz
	input  wire 		Rst_n	, //reset ，low valid
		   
	input  wire 		echo	, //
	output wire [18:00]	data_o	  //检测距离，保留3位小数，*1000实现
);
/* 		S(um) = 17 * t 		-->  x.abc cm	*/
//Parameter Declarations
	parameter T_MAX = 16'd60_000;//510cm 对应计数值

//Interrnal wire/reg declarations
	reg				r1_echo,r2_echo; //边沿检测	
	wire			echo_pos,echo_neg; //
	
	reg		[15:00]	cnt		; //Counter 
	wire			add_cnt ; //Counter Enable
	wire			end_cnt ; //Counter Reset 
	
	reg		[18:00]	data_r	;
//Logic Description
	//如果使用clk_us 检测边沿，延时2us，差值过大
	always @(posedge Clk or negedge Rst_n)begin  
		if(!Rst_n)begin  
			r1_echo <= 1'b0;
			r2_echo <= 1'b0;
		end  
		else begin  
			r1_echo <= echo;
			r2_echo <= r1_echo;
		end  
	end
	
	assign echo_pos = r1_echo & ~r2_echo;
	assign echo_neg = ~r1_echo & r2_echo;
	
	
	always @(posedge clk_us or negedge Rst_n)begin  
		if(!Rst_n)begin  
			cnt <= 'd0; 
		end 
		else if(add_cnt)begin  
			if(end_cnt)begin  
				cnt <= cnt; 
			end  
			else begin  
				cnt <= cnt + 1'b1; 
			end  
		end  
		else begin  //echo 低电平 归零
			cnt <= 'd0;  
		end  
	end 
	
	assign add_cnt = echo; 
	assign end_cnt = add_cnt && cnt >= T_MAX - 1; //超出最大测量范围则保持不变，极限
	
	always @(posedge Clk or negedge Rst_n)begin  
		if(!Rst_n)begin  
			data_r <= 'd2;
		end  
		else if(echo_neg)begin  
			data_r <= (cnt << 4) + cnt;
		end  
		else begin  
			data_r <= data_r;
		end  
	end //always end
	
	assign data_o = data_r >> 1;

endmodule 
```
## 2.3 超声波驱动
查看平台手册，发现`DE2-115`开发板不涉及位选信号，每个段选信号都有一个单独的引脚。

![在这里插入图片描述](https://img-blog.csdnimg.cn/0e6298766f6d47d3b5fa95e43be1cef7.png)
![在这里插入图片描述](https://img-blog.csdnimg.cn/4941e93516e54b7395c75d6ad8833f20.png)

数码管驱动器模块代码如下，用于将输入的数据（data_o）转换为对应的数码管显示：

```verilog
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
```

# 3 实验验证
## 3.1 编译

查看RTL门级电路，如下图：

![在这里插入图片描述](https://img-blog.csdnimg.cn/3583a9a0c14b411f97bdd7d4a35b2f64.png)

## 3.3 硬件测试
引脚绑定：

```verilog
package require ::quartus::project

set_location_assignment PIN_Y2 -to Clk
set_location_assignment PIN_M23 -to Rst_n
set_location_assignment PIN_AC15 -to echo
set_location_assignment PIN_AB22 -to trig
set_location_assignment PIN_AA14 -to hex1[6]
set_location_assignment PIN_AG18 -to hex1[5]
set_location_assignment PIN_AF17 -to hex1[4]
set_location_assignment PIN_AH17 -to hex1[3]
set_location_assignment PIN_AG17 -to hex1[2]
set_location_assignment PIN_AE17 -to hex1[1]
set_location_assignment PIN_AD17 -to hex1[0]
set_location_assignment PIN_AC17 -to hex2[6]
set_location_assignment PIN_AA15 -to hex2[5]
set_location_assignment PIN_AB15 -to hex2[4]
set_location_assignment PIN_AB17 -to hex2[3]
set_location_assignment PIN_AA16 -to hex2[2]
set_location_assignment PIN_AB16 -to hex2[1]
set_location_assignment PIN_AA17 -to hex2[0]
set_location_assignment PIN_AH18 -to hex3[6]
set_location_assignment PIN_AF18 -to hex3[5]
set_location_assignment PIN_AG19 -to hex3[4]
set_location_assignment PIN_AH19 -to hex3[3]
set_location_assignment PIN_AB18 -to hex3[2]
set_location_assignment PIN_AC18 -to hex3[1]
set_location_assignment PIN_AD18 -to hex3[0]
set_location_assignment PIN_AE18 -to hex4[6]
set_location_assignment PIN_AF19 -to hex4[5]
set_location_assignment PIN_AE19 -to hex4[4]
set_location_assignment PIN_AH21 -to hex4[3]
set_location_assignment PIN_AG21 -to hex4[2]
set_location_assignment PIN_AA19 -to hex4[1]
set_location_assignment PIN_AB19 -to hex4[0]
set_location_assignment PIN_Y19 -to hex5[6]
set_location_assignment PIN_AF23 -to hex5[5]
set_location_assignment PIN_AD24 -to hex5[4]
set_location_assignment PIN_AA21 -to hex5[3]
set_location_assignment PIN_AB20 -to hex5[2]
set_location_assignment PIN_U21 -to hex5[1]
set_location_assignment PIN_V21 -to hex5[0]
set_location_assignment PIN_W28 -to hex6[6]
set_location_assignment PIN_W27 -to hex6[5]
set_location_assignment PIN_Y26 -to hex6[4]
set_location_assignment PIN_W26 -to hex6[3]
set_location_assignment PIN_Y25 -to hex6[2]
set_location_assignment PIN_AA26 -to hex6[1]
set_location_assignment PIN_AA25 -to hex6[0]
set_location_assignment PIN_U24 -to hex7[6]
set_location_assignment PIN_U23 -to hex7[5]
set_location_assignment PIN_W25 -to hex7[4]
set_location_assignment PIN_W22 -to hex7[3]
set_location_assignment PIN_W21 -to hex7[2]
set_location_assignment PIN_Y22 -to hex7[1]
set_location_assignment PIN_M24 -to hex7[0]
set_location_assignment PIN_H22 -to hex8[6]
set_location_assignment PIN_J22 -to hex8[5]
set_location_assignment PIN_L25 -to hex8[4]
set_location_assignment PIN_L26 -to hex8[3]
set_location_assignment PIN_E17 -to hex8[2]
set_location_assignment PIN_F22 -to hex8[1]
set_location_assignment PIN_G18 -to hex8[0]
set_location_assignment PIN_E21 -to led[0]
set_location_assignment PIN_E22 -to led[1]
set_location_assignment PIN_E25 -to led[2]
set_location_assignment PIN_E24 -to led[3]
set_location_assignment PIN_AG26 -to beep
```

下载测试：

![在这里插入图片描述](https://img-blog.csdnimg.cn/d20f71e7950646e6af03fe312afa9a9a.gif)
