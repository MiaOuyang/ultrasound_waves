/*
---------------------------------------------------------
    Name:       beepled
    Author:     欧阳紫樱
    Date:       2023-6-1
    Time:       9:56
---------------------------------------------------------
    Software:   
                VS Code
*/
module beepled (
    input   wire        Clk,
    input   wire        Rst_n,
    input   wire [18:0] data_o,
    output  wire        beep,
    output  wire [3:0]  led
);

parameter	MAX1S	=	26'd2500_0000	;
parameter	MAX1_2S	=	26'd1250_0000	;
reg [25:0]	cnt1s						;
reg [25:0]  cnt1_2s                     ;
reg [3:0]	led_r						;
reg         beep_r                      ;

//1s计数器
always @(posedge Clk or negedge Rst_n) begin
	if (!Rst_n) begin
		cnt1s <= 26'd0;						//复位，重新计数
	end
	else if (cnt1s == MAX1S - 1'd1) begin
		cnt1s <= 26'd0;						//记到最大数4999_9999后复位
	end
	else begin
		cnt1s <= cnt1s + 1'd1;				//其他情况+1
	end
end

//0.5s计数器
always @(posedge Clk or negedge Rst_n) begin
	if (!Rst_n) begin
		cnt1_2s <= 26'd0;						//复位，重新计数
	end
	else if (cnt1s == MAX1_2S - 1'd1) begin
		cnt1_2s <= 26'd0;						//记到最大数2499_9999后复位
	end
	else begin
		cnt1_2s <= cnt1_2s + 1'd1;				//其他情况+1
	end
end

//led灯
always @(posedge Clk or negedge Rst_n) begin
    if (!Rst_n) begin
        led_r <= 4'b0000;
    end
    else if(data_o/1000 <= 20) begin
        led_r <= 4'b1111;
    end
    else begin
        led_r <= 4'b0000;
    end
end

//蜂鸣器

always@(posedge Clk or negedge Rst_n)begin
	if(!Rst_n)begin//复位信号
		beep_r <= 1'b0;//蜂鸣器默认设置为0
	end
	else if (data_o/1000 > 20)begin
		beep_r <= 1'b0;
	end
	else if (data_o/1000 <= 20)begin
		if (cnt1s == MAX1S - 1'd1)begin
			beep_r <= ~beep_r;
		end
		else if (data_o/1000 <= 10 && cnt1s == MAX1_2S - 1'd1)begin
			beep_r <= ~beep_r;
		end
		else begin
			beep_r <= beep_r;
		end
	end
	else begin 
		beep_r <= 1'b0;//否则不变 
    end
end


assign beep = beep_r;
assign led = led_r;
endmodule