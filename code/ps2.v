`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:20:18 01/04/2019 
// Design Name: 
// Module Name:    ps2 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ps2(
    input clk,
    input rst,
    input ps2_clk,
    input ps2_data,
    output reg[9:0] tank1_move,
	 output reg[9:0] tank2_move,
	 output reg[9:0] tank1_attack,
	 output reg[9:0] tank2_attack,
    output ready
);

    reg ps2_clk_flag0, ps2_clk_flag1, ps2_clk_flag2;
    wire negedge_ps2_clk;
	 wire [9:0] data_out;
    assign data_out = data;
    always @ (posedge clk or posedge rst) begin 
        if(rst) begin
            ps2_clk_flag0 <= 1'b0;
            ps2_clk_flag1 <= 1'b0;
            ps2_clk_flag2 <= 1'b0;
        end
        else begin 
            ps2_clk_flag0 <= ps2_clk;
            ps2_clk_flag1 <= ps2_clk_flag0;
            ps2_clk_flag2 <= ps2_clk_flag1;
        end
    end
    assign negedge_ps2_clk = !ps2_clk_flag1 & ps2_clk_flag2;
    reg [3:0] num;

    always @(posedge clk or posedge rst) begin
        if(rst)
            num <= 4'd0;
        else if(num == 4'd11)
            num <= 4'd0;
        else if(negedge_ps2_clk)
            num <= num + 1'b1;
    end

    reg negedge_ps2_clk_shift;
    always @(posedge clk) begin
        negedge_ps2_clk_shift <= negedge_ps2_clk;
    end

    reg [7:0] temp_data;
    always @(posedge clk or posedge rst) begin
        if(rst)
            temp_data <= 8'd0;
        else if(negedge_ps2_clk_shift) begin 
            case (num)
              4'd2 : temp_data[0] <= ps2_data; 
              4'd3 : temp_data[1] <= ps2_data; 
              4'd4 : temp_data[2] <= ps2_data; 
              4'd5 : temp_data[3] <= ps2_data; 
              4'd6 : temp_data[4] <= ps2_data; 
              4'd7 : temp_data[5] <= ps2_data; 
              4'd8 : temp_data[6] <= ps2_data; 
              4'd9 : temp_data[7] <= ps2_data; 
				  //4'd10 : temp_data[8] <= ps2_data;                                       
              default: temp_data <= temp_data;
            endcase
        end else 
            temp_data <= temp_data;
    end 
    reg data_break, data_done, data_expand;
    reg [9:0] data;
	 
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            data_break <= 1'b0;
            data <= 10'd0;
            data_done <= 1'b0;
            data_expand <= 1'b0;
				if(data_out[7:0] == 8'h1C || data_out[7:0] == 8'h23 || data_out[7:0] == 8'h1D || data_out[7:0]== 8'h1B) 
				 tank1_move <= data_out;
				else if((data_out[7:0] == 8'h3B) || (data_out[7:0] == 8'h4B) || (data_out[7:0] == 8'h43) || (data_out[7:0]== 8'h42))
				 tank2_move <= data_out;
				else if(data_out[7:0] == 8'h29) tank1_attack <= data_out;
				else if(data_out[7:0] == 8'h5A) tank2_attack <= data_out;
					 
		  end
        else if (num == 4'd11) begin
            if(temp_data == 8'hE0)
                data_expand <= 1'b1;
            else if(temp_data == 8'hF0)
                data_break <= 1'b1;
            else begin 
                data <= {data_expand, data_break, temp_data};
                data_done <= 1'b1;
                data_expand <= 1'b0;
                data_break <= 1'b0;
					 if(data_out[7:0] == 8'h1C || data_out[7:0] == 8'h23 || data_out[7:0] == 8'h1D || data_out[7:0]== 8'h1B) 
						tank1_move <= data_out;
					 else if((data_out[7:0] == 8'h3B) || (data_out[7:0] == 8'h4B) || (data_out[7:0] == 8'h43) || (data_out[7:0]== 8'h42))
						tank2_move <= data_out;
					 else if(data_out[7:0] == 8'h29) tank1_attack <= data_out;
					 else if(data_out[7:0] == 8'h5A) tank2_attack <= data_out;
					 
            end
        end
        else begin 
			
            data <= data;
            data_done <= 1'b0;
            data_expand <=data_expand;
            data_break <= data_break;
				if(data_out[7:0] == 8'h1C || data_out[7:0] == 8'h23 || data_out[7:0] == 8'h1D || data_out[7:0]== 8'h1B) 
				 tank1_move <= data_out;
				else if((data_out[7:0] == 8'h3B) || (data_out[7:0] == 8'h4B) || (data_out[7:0] == 8'h43) || (data_out[7:0]== 8'h42))
				 tank2_move <= data_out;
				else if(data_out[7:0] == 8'h29) tank1_attack <= data_out;
				else if(data_out[7:0] == 8'h5A) tank2_attack <= data_out;	 
        end
	end
	//wire yes1;
	//assign yes1 = data_out[7:0] == 8'h1C;
	//always @(posedge clk or posedge rst) begin
	//tank1_move<=10'h0;
		//if(yes1)begin end
		//if(&data_out)begin end
		// if((data_out[7:0] == 8'h1C) || (data_out[7:0] == 8'h23) || (data_out[7:0] == 8'h1D )|| (data_out[7:0]== 8'h1B)) 
		 //begin end
		 //else if((data_out[7:0] == 8'h3B) || (data_out[7:0] == 8'h4B) || (data_out[7:0] == 8'h43) || (data_out[7:0]== 8'h42)) 
		// begin end
	 //end
	 
	
    assign ready = data_done;
endmodule
