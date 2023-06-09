/*
---------------------------------------------------------
    Name:       hc_sr_trig
    Author:     欧阳紫樱
    Date:       2023-5-27
    Time:       19:27
---------------------------------------------------------
    Software:   
                VS Code
*/
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

