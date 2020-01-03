`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/10/17 12:25:41
// Design Name: 
// Module Name: Top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Top(
	input clk,
	input rstn,
	input [15:0]SW,
	output hs,
	output vs,
	output [3:0] r,
	output [3:0] g,
	output [3:0] b,
	output SEGLED_CLK,
	output SEGLED_CLR,
	output SEGLED_DO,
	output SEGLED_PEN,
   output LED_CLK,
	output LED_CLR,
	output LED_DO,
	output LED_PEN,
	
	inout [4:0]BTN_X,
	inout [3:0]BTN_Y,
	input ps2_clk, 
	input ps2_data, 
	//output buzzer,
	output wire [3:0] AN,
   output wire [7:0] SEGMENT,
   output wire [7:0] LED
   );
	reg [31:0]clkdiv;//clkdiv
	
	always @(posedge clk) begin
		clkdiv <= clkdiv + 1'b1;
	end
	
	assign buzzer = 1'b1;
	reg [15:0] waittodel;
	reg [3:0] save_map [19:0][19:0];//original map
	
//去抖动	
	wire [15:0] SW_OK;
	AntiJitter #(4) a0[15:0](.clk(clkdiv[15]), .I(SW), .O(SW_OK));
	
	wire [4:0] keyCode;
	wire keyReady;
	Keypad k0 (.clk(clkdiv[15]), .keyX(BTN_Y), .keyY(BTN_X), .keyCode(keyCode), .ready(keyReady));
	
	wire [31:0] segTestData;
	wire [3:0]sout;
   Seg7Device segDevice(.clkIO(clkdiv[3]), .clkScan(clkdiv[15:14]), .clkBlink(clkdiv[25]),
		.data(segTestData), .point(8'h0), .LES(8'h0),
		.sout(sout));
	assign SEGLED_CLK = sout[3];
	assign SEGLED_DO = sout[2];
	assign SEGLED_PEN = sout[1];
	assign SEGLED_CLR = sout[0];
 	
	
	reg [9:0] x;
	reg [8:0] y;
	//原始地图显示
 	reg 	[11:0] vga_data,spo;
 	wire 	[11:0] col_wo,col_wt,col_addr,col_brick,col_box,col_grass;//CHangable 改成9
 	wire	[10:0] row_addr;
	wire 	[11:0] orimap,tka,tkb;
	reg 	[17:0] ckmapa;
	reg 	[9:0] atkaddr,btkaddr,endover;
	
	vgac v0 (
		.vga_clk(clkdiv[1]), .clrn(SW_OK[0]), .d_in(vga_data), .row_addr(row_addr), .col_addr(col_addr), .r(r), .g(g), .b(b), .hs(hs), .vs(vs)
	);
	
	 //wire[9:0] data_out;
	 wire [9:0] tank1_attack;
	 wire [9:0] tank2_attack;
	 wire [9:0] tank1_move;
	 wire [9:0] tank2_move;
	 reg lock;
	 reg gameover;
	 reg [1:0] winner;
	 initial begin
		lock = 0;
		gameover = 0;
		winner = 2'b11;
	 end
	 
	 ps2 ps2keyboard(
        .clk(clk),
		  .rst(lock),
        .ps2_clk(ps2_clk),
		  .ps2_data(ps2_data),
        .tank1_move(tank1_move),
        .tank2_move(tank2_move),
        .ready(),
		  .tank1_attack(tank1_attack),
		  .tank2_attack(tank2_attack)
    );

	localparam tanksize = 23;
	
	// bullet
	localparam bullet_radius = 4;
	localparam bullet_num = 8;
	localparam bullet_speed = 4'd12;
	reg [11:0] bullet1_x [bullet_num - 1:0],bullet2_x [bullet_num - 1:0];
   reg [10:0] bullet1_y [bullet_num - 1:0],bullet2_y [bullet_num - 1:0];
	reg [2:0] bullet1_direction [bullet_num- 1:0],bullet2_direction [bullet_num-1:0];
	reg [2:0] bullet1_count,bullet2_count;
	wire [19:0] bullet1_x_sqr[bullet_num - 1:0],bullet2_x_sqr[bullet_num - 1:0];
	wire [19:0] bullet1_y_sqr[bullet_num - 1:0],bullet2_y_sqr[bullet_num - 1:0];
	integer i;
	
	genvar j;
	generate
		for(j=0; j<bullet_num; j=j+1) begin
			assign bullet1_x_sqr[j] = (bullet1_x[j] - col_addr) * (bullet1_x[j] - col_addr);
			assign bullet1_y_sqr[j] = (bullet1_y[j] - row_addr) * (bullet1_y[j] - row_addr);
			assign bullet2_x_sqr[j] = (bullet2_x[j] - col_addr) * (bullet2_x[j] - col_addr);
			assign bullet2_y_sqr[j] = (bullet2_y[j] - row_addr) * (bullet2_y[j] - row_addr);
		end
	endgenerate
	
	 //tankl initialize
	reg	[11:0] LR_distance_tank1,TMP_LR_distance_tank1;
	reg	[10:0] UD_distance_tank1,TMP_UD_distance_tank1;
	reg  [1:0]  direction_tank1;
	initial begin LR_distance_tank1 = 0; end
	initial begin UD_distance_tank1 = 455; end 
	
	//tank1 move and turn
	always @(posedge clkdiv[19] or posedge SW[15]) begin
		if(SW[15])begin
			LR_distance_tank1 = 0;
			UD_distance_tank1 = 455;
			
		end
		else begin 
			if(tank1_move[8] == 1'b0 && tank1_move[7:0] == 8'h1C && LR_distance_tank1 > 0) begin
					  TMP_LR_distance_tank1 = LR_distance_tank1 - 8'h01;
					  direction_tank1 = 2'b00;//left
					  if(TMP_LR_distance_tank1 > 0 && (save_map[(UD_distance_tank1 + tanksize)/24][TMP_LR_distance_tank1/24] == 4'b0000 || save_map[(UD_distance_tank1 + tanksize)/24][TMP_LR_distance_tank1/24] == 4'b0001)&&(save_map[UD_distance_tank1/24][TMP_LR_distance_tank1/24] == 4'b0000 || save_map[UD_distance_tank1/24][TMP_LR_distance_tank1/24] == 4'b0001))begin
							LR_distance_tank1 = TMP_LR_distance_tank1;
					  end
			end
			else if(tank1_move[8] == 1'b0 && tank1_move[7:0] == 8'h23 && LR_distance_tank1 + tanksize < 479) begin
					  TMP_LR_distance_tank1 = LR_distance_tank1 + 8'h01;
					  direction_tank1 = 2'b01;//right
					  if(TMP_LR_distance_tank1 + tanksize <= 479 && (save_map[(UD_distance_tank1)/24][(TMP_LR_distance_tank1 + tanksize)/24] == 4'b0000 || save_map[(UD_distance_tank1)/24][(TMP_LR_distance_tank1 + tanksize)/24] == 4'b0001)&&(save_map[(UD_distance_tank1 + tanksize)/24][(TMP_LR_distance_tank1 + tanksize)/24] == 4'b0000 || save_map[(UD_distance_tank1 + tanksize)/24][(TMP_LR_distance_tank1 + tanksize)/24] == 4'b0001))begin
							LR_distance_tank1 = TMP_LR_distance_tank1;
					  end
			end
			else if(tank1_move[8] == 1'b0 && tank1_move[7:0] == 8'h1D && UD_distance_tank1 > 0) begin
						TMP_UD_distance_tank1 = UD_distance_tank1 - 8'h01;
						direction_tank1 = 2'b10;//up
						if(TMP_UD_distance_tank1 > 0 && (save_map[TMP_UD_distance_tank1/24][LR_distance_tank1/24] == 4'b0000 || save_map[TMP_UD_distance_tank1/24][LR_distance_tank1/24] == 4'b0001)&&(save_map[TMP_UD_distance_tank1/24][(LR_distance_tank1 + tanksize)/24] == 4'b0000 || save_map[TMP_UD_distance_tank1/24][(LR_distance_tank1 + tanksize)/24] == 4'b0001))begin
							 UD_distance_tank1 = TMP_UD_distance_tank1;
						end
			end
			else if(tank1_move[8] == 1'b0 && tank1_move[7:0] == 8'h1B && UD_distance_tank1 + tanksize < 479) begin
						TMP_UD_distance_tank1 = UD_distance_tank1 + 8'h01;
						direction_tank1 = 2'b11;//down
						if(TMP_UD_distance_tank1 + tanksize < 479 && (save_map[(TMP_UD_distance_tank1 + tanksize)/24][LR_distance_tank1/24] == 4'b0000 || save_map[(TMP_UD_distance_tank1 + tanksize)/24][LR_distance_tank1/24] == 4'b0001)&&(save_map[(TMP_UD_distance_tank1 + tanksize)/24][(LR_distance_tank1 + tanksize)/24] == 4'b0000 || save_map[(TMP_UD_distance_tank1 + tanksize)/24][(LR_distance_tank1 + tanksize)/24] == 4'b0001))begin
							 UD_distance_tank1 = TMP_UD_distance_tank1;
						end
			end
		end
	end
	always @(posedge clkdiv[22] or posedge SW[15]) begin
		if(SW[15])begin
			for(i=0; i<bullet_num; i=i+1) begin
				bullet1_x[i] = 500;
				bullet1_y[i] = 500;
				bullet1_direction[i] = 3'b100;
				bullet1_count = 0;
				bullet2_x[i] = 500;
				bullet2_y[i] = 500;
				bullet2_direction[i] = 3'b100;
				bullet2_count = 0;
			end
			save_map[0][1] = 4'b0010;
			save_map[0][3] = 4'b0010;
			save_map[0][5] = 4'b0010;
			save_map[0][8] = 4'b0010;
			save_map[0][9] = 4'b0010;
			save_map[0][12] = 4'b0010;
			save_map[0][13] = 4'b0010;
			
			save_map[1][8] = 4'b0010;
			save_map[1][9] = 4'b0010;
			save_map[1][12] = 4'b0010;
			save_map[1][13] = 4'b0010;
			save_map[1][15] = 4'b0010;
			save_map[1][16] = 4'b0010;
			
			save_map[2][3] = 4'b0010;
			save_map[2][4] = 4'b0010;
			save_map[2][8] = 4'b0010;
			save_map[2][9] = 4'b0010;
			save_map[2][10] = 4'b0010;
			save_map[2][11] = 4'b0010;
			save_map[2][12] = 4'b0010;
			save_map[2][13] = 4'b0010;
			save_map[2][15] = 4'b0010;
			save_map[2][16] = 4'b0010;
			
			save_map[3][8] = 4'b0010;
			save_map[3][9] = 4'b0010;
			save_map[3][10] = 4'b0010;
			save_map[3][11] = 4'b0010;
			save_map[3][12] = 4'b0010;
			save_map[3][13] = 4'b0010;
			
			save_map[4][16] = 4'b0010;
			
			save_map[5][16] = 4'b0010;
			
			save_map[6][7] = 4'b0010;
			save_map[6][8] = 4'b0010;
			save_map[6][11] = 4'b0010;
			save_map[6][14] = 4'b0010;
			save_map[6][15] = 4'b0010;
			
			save_map[7][7] = 4'b0010;
			save_map[7][8] = 4'b0010;
			save_map[7][11] = 4'b0010;
			save_map[7][14] = 4'b0010;
			save_map[7][15] = 4'b0010;
			
			save_map[8][7] = 4'b0010;
			save_map[8][8] = 4'b0010;
			save_map[8][9] = 4'b0010;
			save_map[8][10] = 4'b0010;
			save_map[8][11] = 4'b0010;
			save_map[8][14] = 4'b0010;
			save_map[8][15] = 4'b0010;
			save_map[8][17] = 4'b0010;
			save_map[8][18] = 4'b0010;
			save_map[8][19] = 4'b0010;
			
			save_map[9][0] = 4'b0010;
			save_map[9][1] = 4'b0010;
			save_map[9][2] = 4'b0010;
			save_map[9][3] = 4'b0010;
			save_map[9][8] = 4'b0010;
			save_map[9][17] = 4'b0010;
			save_map[9][18] = 4'b0010;
			save_map[9][19] = 4'b0010;
			
			save_map[11][2] = 4'b0010;
			save_map[11][3] = 4'b0010;
			save_map[11][4] = 4'b0010;
			save_map[11][16] = 4'b0010;
			save_map[11][17] = 4'b0010;
			
			save_map[12][2] = 4'b0010;
			save_map[12][3] = 4'b0010;
			save_map[12][4] = 4'b0010;
			save_map[12][8] = 4'b0010;
			save_map[12][12] = 4'b0010;
			save_map[12][16] = 4'b0010;
			save_map[12][17] = 4'b0010;
			
			save_map[13][9] = 4'b0010;
			save_map[13][12] = 4'b0010;
			
			save_map[14][17] = 4'b0010;
			
			save_map[15][16] = 4'b0010;
			
			save_map[16][8] = 4'b0010;
			save_map[16][9] = 4'b0010;
			save_map[16][10] = 4'b0010;
			save_map[16][11] = 4'b0010;
			save_map[16][12] = 4'b0010;
			save_map[16][13] = 4'b0010;
			
			save_map[17][3] = 4'b0010;
			save_map[17][4] = 4'b0010;
			save_map[17][8] = 4'b0010;
			save_map[17][9] = 4'b0010;
			save_map[17][10] = 4'b0010;
			save_map[17][11] = 4'b0010;
			save_map[17][12] = 4'b0010;
			save_map[17][13] = 4'b0010;
			
			save_map[18][8] = 4'b0010;
			save_map[18][9] = 4'b0010;
			save_map[18][12] = 4'b0010;
			save_map[18][13] = 4'b0010;
			save_map[18][16] = 4'b0010;
			save_map[18][17] = 4'b0010;
			
			save_map[19][3] = 4'b0010;
			save_map[19][4] = 4'b0010;
			save_map[19][8] = 4'b0010;
			save_map[19][9] = 4'b0010;
			save_map[19][12] = 4'b0010;
			save_map[19][13] = 4'b0010;
			save_map[19][16] = 4'b0010;
			save_map[19][17] = 4'b0010;
			
			save_map[4][17] = 4'b0001;
			save_map[4][18] = 4'b0001;
			save_map[4][19] = 4'b0001;
			
			save_map[5][17] = 4'b0001;
			save_map[5][18] = 4'b0001;
			save_map[5][19] = 4'b0001;
			
			save_map[6][9] = 4'b0001;
			save_map[6][10] = 4'b0001;
			save_map[6][17] = 4'b0001;
			save_map[6][18] = 4'b0001;
			save_map[6][19] = 4'b0001;
			
			save_map[7][9] = 4'b0001;
			save_map[7][10] = 4'b0001;
			save_map[7][17] = 4'b0001;
			save_map[7][18] = 4'b0001;
			save_map[7][19] = 4'b0001;

			save_map[10][8] = 4'b0001;
			save_map[10][9] = 4'b0001;
			save_map[10][10] = 4'b0001;
			save_map[10][11] = 4'b0001;
			
			save_map[11][8] = 4'b0001;
			save_map[11][9] = 4'b0001;
			save_map[11][10] = 4'b0001;
			save_map[11][11] = 4'b0001;
			
			save_map[12][9] = 4'b0001;
			save_map[12][10] = 4'b0001;
			save_map[12][11] = 4'b0001;
			
			save_map[13][10] = 4'b0001;
			save_map[13][11] = 4'b0001;

			save_map[17][18] = 4'b0001;
			save_map[17][19] = 4'b0001;
			
			save_map[18][18] = 4'b0001;
			save_map[18][19] = 4'b0001;
			
			save_map[4][3] = 4'b0011;
			save_map[4][9] = 4'b0011;
			save_map[4][10] = 4'b0011;

			save_map[5][3] = 4'b0011;
			
			save_map[6][3] = 4'b0011;
			
			save_map[7][3] = 4'b0011;
			
			save_map[8][0] = 4'b0011;
			
			save_map[12][0] = 4'b0011;
			save_map[12][1] = 4'b0011;
			save_map[12][18] = 4'b0011;
			save_map[12][19] = 4'b0011;
			
			save_map[13][0] = 4'b0011;
			save_map[13][1] = 4'b0011;
			save_map[13][2] = 4'b0011;
			save_map[13][3] = 4'b0011;
			save_map[13][4] = 4'b0011;
			save_map[13][16] = 4'b0011;
			save_map[13][17] = 4'b0011;
			save_map[13][18] = 4'b0011;
			save_map[13][19] = 4'b0011;
			
			save_map[14][10] = 4'b0011;
			save_map[14][11] = 4'b0011;
			
			save_map[17][16] = 4'b0011;
			save_map[17][17] = 4'b0011;
			
			lock = 0;	
			winner = 2'b11;
			gameover = 0;
		end
		else begin 
			if(tank1_attack[8] == 1'b0 && tank1_attack[7:0] == 8'h29) begin
				//waittodel <= 16'h4321;
				if(direction_tank1 == 2'b00)begin
					bullet1_x[bullet1_count] = LR_distance_tank1;
					bullet1_y[bullet1_count] = UD_distance_tank1 + 11'd12;//already done
					waittodel = {bullet1_count, 1'b0, bullet1_y[bullet1_count]};
				end
				else if(direction_tank1 == 2'b01)begin
					bullet1_x[bullet1_count] = LR_distance_tank1 + 12'd23;
					bullet1_y[bullet1_count] = UD_distance_tank1 + 11'd12;//already done
				end
				else if(direction_tank1 == 2'b10)begin
					bullet1_x[bullet1_count] = LR_distance_tank1 + 12'd12;
					bullet1_y[bullet1_count] = UD_distance_tank1;//already done
				end
				else if(direction_tank1 == 2'b11)begin
					bullet1_x[bullet1_count] = LR_distance_tank1 + 12'd12;
					bullet1_y[bullet1_count] = UD_distance_tank1 + 11'd23;//already done
				end
				bullet1_direction[bullet1_count] = {1'b0, direction_tank1};
				bullet1_count = bullet1_count + 4'b0001;
			end
			
			for(i=0; i<bullet_num; i=i+1) begin
				if(bullet1_direction[i]==3'b000) begin
					bullet1_x[i] = bullet1_x[i] - bullet_speed;
				end
				else if(bullet1_direction[i]==3'b001) begin
					bullet1_x[i] = bullet1_x[i] + bullet_speed;
				end
				else if(bullet1_direction[i]==3'b010) begin
					bullet1_y[i] = bullet1_y[i] - bullet_speed;
				end
				else if(bullet1_direction[i]==3'b011) begin
					bullet1_y[i] = bullet1_y[i] + bullet_speed;
				end
				
				if(bullet1_y[i		] <= 0 || bullet1_y[i] >= 479 || bullet1_x[i] <= 0 || bullet1_x[i] >= 479)begin
					bullet1_x[i] = 500;
					bullet1_y[i] = 500;
					bullet1_direction[i] = 3'b100;
				end
				else if(save_map[bullet1_y[i]/24][bullet1_x[i]/24] == 4'b0010)begin
					save_map[bullet1_y[i]/24][bullet1_x[i]/24] = 4'b0;
					bullet1_x[i] = 500;
					bullet1_y[i] = 500;
					bullet1_direction[i] = 3'b100;
				end
				else if(save_map[bullet1_y[i]/24][bullet1_x[i]/24] == 4'b0011)begin
					bullet1_x[i] = 500;
					bullet1_y[i] = 500;
					bullet1_direction[i] = 3'b100;
				end
				else if(bullet1_x[i] >= LR_distance_tank2 && bullet1_x[i] <= LR_distance_tank2 +23 && bullet1_y[i] >= UD_distance_tank2 && bullet1_y[i] <= UD_distance_tank2 + 23) begin
					bullet1_x[i] = 500;
					bullet1_y[i] = 500;
					bullet1_direction[i] = 3'b100;
					lock = 1;
					winner = 2'b0;
					gameover = 1;
				end
			end
			
			if(tank2_attack[8] == 1'b0 && tank2_attack[7:0] == 8'h5A) begin
				if(direction_tank2 == 2'b00)begin
					bullet2_x[bullet2_count] = LR_distance_tank2;
					bullet2_y[bullet2_count] = UD_distance_tank2 + 11'd12;//already done
				end
				else if(direction_tank2 == 2'b01)begin
					bullet2_x[bullet2_count] = LR_distance_tank2 + 12'd23;
					bullet2_y[bullet2_count] = UD_distance_tank2 + 11'd12;//already done
				end
				else if(direction_tank2 == 2'b10)begin
					bullet2_x[bullet2_count] = LR_distance_tank2 + 12'd12;
					bullet2_y[bullet2_count] = UD_distance_tank2;//already done
				end
				else if(direction_tank2 == 2'b11)begin
					bullet2_x[bullet2_count] = LR_distance_tank2 + 12'd12;
					bullet2_y[bullet2_count] = UD_distance_tank2 + 11'd23;//already done
				end
				bullet2_direction[bullet2_count] = {1'b0, direction_tank2};
				bullet2_count = bullet2_count + 4'b1;
			end
				
			for(i=0; i<bullet_num; i=i+1) begin
				if(bullet2_direction[i]==3'b000) begin
					bullet2_x[i] = bullet2_x[i] - bullet_speed;
				end
				else if(bullet2_direction[i]==3'b001) begin
					bullet2_x[i] = bullet2_x[i] + bullet_speed;
				end
				else if(bullet2_direction[i]==3'b010) begin
					bullet2_y[i] = bullet2_y[i] - bullet_speed;
				end
				else if(bullet2_direction[i]==3'b011) begin
					bullet2_y[i] = bullet2_y[i] + bullet_speed;
				end
				
				if(bullet2_y[i] <= 0 || bullet2_y[i] >= 479 || bullet2_x[i] <= 0 || bullet2_x[i] >= 479)begin
					bullet2_x[i] = 500;
					bullet2_y[i] = 500;
					bullet2_direction[i] = 3'b100;
				end
				else if(save_map[bullet2_y[i]/24][bullet2_x[i]/24] == 4'b0010)begin
					save_map[bullet2_y[i]/24][bullet2_x[i]/24] = 0;
					bullet2_x[i] = 500;
					bullet2_y[i] = 500;
					bullet2_direction[i] = 3'b100;
				end
				else if(save_map[bullet2_y[i]/24][bullet2_x[i]/24] == 4'b0011)begin
					bullet2_x[i] = 500;
					bullet2_y[i] = 500;
					bullet2_direction[i] = 3'b100;
				end
				else if(bullet2_x[i] >= LR_distance_tank1 && bullet2_x[i] <= LR_distance_tank1 + 23 && bullet2_y[i] >= UD_distance_tank1 && bullet2_y[i] <= UD_distance_tank1 + 23) begin
					bullet2_x[i] = 500;
					bullet2_y[i] = 500;
					bullet2_direction[i] = 3'b100;
					lock = 1;
					gameover = 1;
					winner = 2'b1;
				end
			end
		end
	end
	//tank2 initialize
	reg	[11:0] LR_distance_tank2,TMP_LR_distance_tank2;
	reg	[10:0] UD_distance_tank2,TMP_UD_distance_tank2;
	reg   [1:0]  direction_tank2;
	initial begin LR_distance_tank2 = 431; end
	initial begin UD_distance_tank2 = 0; end 
	//tank2 move and turn
	always @(posedge clkdiv[19] or posedge SW[15]) begin
		if(SW[15])begin
			LR_distance_tank2 = 431;
			UD_distance_tank2 = 0;
		end
		else begin 
			if(tank2_move[8] == 1'b0 && tank2_move[7:0] == 8'h3B && LR_distance_tank2 > 0) begin
					  TMP_LR_distance_tank2 = LR_distance_tank2 - 8'h01;
					  direction_tank2 = 2'b00;//left
					  if(TMP_LR_distance_tank2 > 0 && (save_map[(UD_distance_tank2 + tanksize)/24][TMP_LR_distance_tank2/24] == 4'b0000 || save_map[(UD_distance_tank2 + tanksize)/24][TMP_LR_distance_tank2/24] == 4'b0001)&&(save_map[UD_distance_tank2/24][TMP_LR_distance_tank2/24] == 4'b0000 || save_map[UD_distance_tank2/24][TMP_LR_distance_tank2/24] == 4'b0001))begin
							LR_distance_tank2 = TMP_LR_distance_tank2;
					  end
			end
			else if(tank2_move[8] == 1'b0 && tank2_move[7:0] == 8'h4B && LR_distance_tank2 + tanksize < 479) begin
					  TMP_LR_distance_tank2 = LR_distance_tank2 + 8'h01;
					  direction_tank2 = 2'b01;//right
					  if(TMP_LR_distance_tank2 + tanksize < 479 && (save_map[(UD_distance_tank2)/24][(TMP_LR_distance_tank2 + tanksize)/24] == 4'b0000 || save_map[(UD_distance_tank2)/24][(TMP_LR_distance_tank2 + tanksize)/24] == 4'b0001)&&(save_map[(UD_distance_tank2 + tanksize)/24][(TMP_LR_distance_tank2 + tanksize)/24] == 4'b0000 || save_map[(UD_distance_tank2 + tanksize)/24][(TMP_LR_distance_tank2 + tanksize)/24] == 4'b0001))begin
							LR_distance_tank2 = TMP_LR_distance_tank2;
					  end
			end
			else if(tank2_move[8] == 1'b0 && tank2_move[7:0] == 8'h43 && UD_distance_tank2 > 0) begin
						TMP_UD_distance_tank2 = UD_distance_tank2 - 8'h01;
						direction_tank2 = 2'b10;//up
						if(TMP_UD_distance_tank2 > 0 && (save_map[TMP_UD_distance_tank2/24][LR_distance_tank2/24] == 4'b0000 || save_map[TMP_UD_distance_tank2/24][LR_distance_tank2/24] == 4'b0001)&&(save_map[TMP_UD_distance_tank2/24][(LR_distance_tank2 + tanksize)/24] == 4'b0000 || save_map[TMP_UD_distance_tank2/24][(LR_distance_tank2 + tanksize)/24] == 4'b0001))begin
							 UD_distance_tank2 = TMP_UD_distance_tank2;
						end
			end
			else if(tank2_move[8] == 1'b0 && tank2_move[7:0] == 8'h42 && UD_distance_tank2 + tanksize < 479) begin
						TMP_UD_distance_tank2 = UD_distance_tank2 + 8'h01;
						direction_tank2 = 2'b11;//down
						if(TMP_UD_distance_tank2 + tanksize < 479 && (save_map[(TMP_UD_distance_tank2 + tanksize)/24][LR_distance_tank2/24] == 4'b0000 || save_map[(TMP_UD_distance_tank2 + tanksize)/24][LR_distance_tank2/24] == 4'b0001)&&(save_map[(TMP_UD_distance_tank2 + tanksize)/24][(LR_distance_tank2 + tanksize)/24] == 4'b0000 || save_map[(TMP_UD_distance_tank2 + tanksize)/24][(LR_distance_tank2 + tanksize)/24] == 4'b0001))begin
							 UD_distance_tank2 = TMP_UD_distance_tank2;
						end
			end
		end
	end


   assign LED = 8'b11111111;
	always @(*) begin
		if(row_addr >= 0 && row_addr <= 479)begin
			if(col_addr >= 0 && col_addr <= 479) begin
				ckmapa = row_addr * 480 + col_addr;
			end
			else begin ckmapa = 0; end
		end
		else begin ckmapa = 0; end
		
		if(row_addr >= 120 && row_addr <= 359 && col_addr >= 120 && col_addr <= 359)begin
			endover = (row_addr - 120) / 10 * 24 + (col_addr - 120) / 10;
		end
		else begin
			endover = 0;
		end
		//tank1 address
		if(direction_tank1 == 2'b00) begin
			if(row_addr >= UD_distance_tank1 && row_addr <= UD_distance_tank1 + tanksize && col_addr >= LR_distance_tank1 && col_addr <= LR_distance_tank1 + tanksize) begin
				atkaddr = (row_addr - UD_distance_tank1) * 24 + col_addr - LR_distance_tank1;
			end                                                                                                                                                                     
		end 
		else if(direction_tank1 == 2'b01) begin
			if(row_addr >= UD_distance_tank1 && row_addr <= UD_distance_tank1 + tanksize && col_addr >= LR_distance_tank1 && col_addr <= LR_distance_tank1 + tanksize) begin
				atkaddr = (row_addr - UD_distance_tank1) * 24 + tanksize - col_addr + LR_distance_tank1;
			end
		end 
		else if(direction_tank1 == 2'b10) begin
			if(row_addr >= UD_distance_tank1 && row_addr <= UD_distance_tank1 + tanksize && col_addr >= LR_distance_tank1 && col_addr <= LR_distance_tank1 + tanksize) begin
				atkaddr = (row_addr - UD_distance_tank1) + (col_addr - LR_distance_tank1)*24;
			end
		end 
		else if(direction_tank1 == 2'b11) begin
			if(row_addr >= UD_distance_tank1 && row_addr <= UD_distance_tank1 + tanksize && col_addr >= LR_distance_tank1 && col_addr <= LR_distance_tank1 + tanksize) begin
				atkaddr = (tanksize - row_addr + UD_distance_tank1) + (tanksize - col_addr + LR_distance_tank1)*24;
			end
		end 
		
		//tank2 address
		if(direction_tank2 == 2'b00) begin
			if(row_addr >= UD_distance_tank2 && row_addr <= UD_distance_tank2 + tanksize && col_addr >= LR_distance_tank2 && col_addr <= LR_distance_tank2 + tanksize) begin
				btkaddr = (row_addr - UD_distance_tank2) * 24 + col_addr - LR_distance_tank2;
			end
		end 
		else if(direction_tank2 == 2'b01) begin
			if(row_addr >= UD_distance_tank2 && row_addr <= UD_distance_tank2 + tanksize && col_addr >= LR_distance_tank2 && col_addr <= LR_distance_tank2 + tanksize) begin
				btkaddr = (row_addr - UD_distance_tank2) * 24 + tanksize - col_addr + LR_distance_tank2;
			end
		end 
		
		else if(direction_tank2 == 2'b10) begin
			if(row_addr >= UD_distance_tank2 && row_addr <= UD_distance_tank2 + tanksize && col_addr >= LR_distance_tank2 && col_addr <= LR_distance_tank2 + tanksize) begin
				btkaddr = (row_addr - UD_distance_tank2) + (col_addr - LR_distance_tank2)*24;
			end
		end 
		else if(direction_tank2 == 2'b11) begin
			if(row_addr >= UD_distance_tank2 && row_addr <= UD_distance_tank2 + tanksize && col_addr >= LR_distance_tank2 && col_addr <= LR_distance_tank2 + tanksize) begin
				btkaddr = (tanksize - row_addr + UD_distance_tank2) + (tanksize - col_addr + LR_distance_tank2)*24;
			end
		end
	end
	
	//change color
	always @(posedge clk or posedge gameover) begin
		if(gameover == 1'b1) begin
			if(row_addr >= 120 && row_addr <= 359 && col_addr >= 120 && col_addr <= 359)begin
				if(winner == 1'b0) vga_data <= col_wo;
				else vga_data <= col_wt;
			end
			else begin
				vga_data <= 0;
			end
		end
		else begin
			if(row_addr >= 480 || col_addr >= 480)begin
				vga_data <= 0;
			end
			else if(save_map[row_addr / 24][col_addr / 24] == 4'b0001)begin		//green grass
				vga_data <= col_grass;
			end
			else if(bullet1_x_sqr[0] + bullet1_y_sqr[0] < bullet_radius * bullet_radius) begin
				vga_data <= 12'h347;
			end
			else if(bullet1_x_sqr[1] + bullet1_y_sqr[1] < bullet_radius * bullet_radius) begin
				vga_data <= 12'h347;
			end
			else if(bullet1_x_sqr[2] + bullet1_y_sqr[2] < bullet_radius * bullet_radius) begin
				vga_data <= 12'h347;
			end
			else if(bullet1_x_sqr[3] + bullet1_y_sqr[3] < bullet_radius * bullet_radius) begin
				vga_data <= 12'h347;
			end
			else if(bullet1_x_sqr[4] + bullet1_y_sqr[4] < bullet_radius * bullet_radius) begin
				vga_data <= 12'h347;
			end
			else if(bullet1_x_sqr[5] + bullet1_y_sqr[5] < bullet_radius * bullet_radius) begin
				vga_data <= 12'h347;
			end
			else if(bullet1_x_sqr[6] + bullet1_y_sqr[6] < bullet_radius * bullet_radius) begin
				vga_data <= 12'h347;
			end
			else if(bullet1_x_sqr[7] + bullet1_y_sqr[7] < bullet_radius * bullet_radius) begin
				vga_data <= 12'h347;
			end
			else if(bullet2_x_sqr[0] + bullet2_y_sqr[0] < bullet_radius * bullet_radius) begin
				vga_data <= 12'hca9;
			end
			else if(bullet2_x_sqr[1] + bullet2_y_sqr[1] < bullet_radius * bullet_radius) begin
				vga_data <= 12'hca9;
			end
			else if(bullet2_x_sqr[2] + bullet2_y_sqr[2] < bullet_radius * bullet_radius) begin
				vga_data <= 12'hca9;
			end
			else if(bullet2_x_sqr[3] + bullet2_y_sqr[3] < bullet_radius * bullet_radius) begin
				vga_data <= 12'hca9;
			end
			else if(bullet2_x_sqr[4] + bullet2_y_sqr[4] < bullet_radius * bullet_radius) begin
				vga_data <= 12'hca9;
			end
			else if(bullet2_x_sqr[5] + bullet2_y_sqr[0] < bullet_radius * bullet_radius) begin
				vga_data <= 12'hca9;
			end
			else if(bullet2_x_sqr[6] + bullet2_y_sqr[1] < bullet_radius * bullet_radius) begin
				vga_data <= 12'hca9;
			end
			else if(bullet2_x_sqr[7] + bullet2_y_sqr[2] < bullet_radius * bullet_radius) begin
				vga_data <= 12'hca9;
			end
			else if(row_addr >= UD_distance_tank1 && row_addr <= UD_distance_tank1 + 23 && col_addr >= LR_distance_tank1 && col_addr <= LR_distance_tank1 + 23)begin
					if(tka >= 12'b110011001100) begin
						vga_data <= orimap;
					end
					else begin
						vga_data <= tka;
					end
			end
			else if(row_addr >= UD_distance_tank2 && row_addr <= UD_distance_tank2 + 23 && col_addr >= LR_distance_tank2 && col_addr <= LR_distance_tank2 + 23)begin
					if(tkb >= 12'b110011001100) begin
						vga_data <= orimap;
					end
					else begin
						vga_data <= tkb;
					end
					
			end
			else begin 
	//			if(row_addr >= UD_distance && row_addr <= UD_distance + 47 && col_addr >= LR_distance && col_addr <= LR_distance + 47)begin
		//		end
			//	else begin
					if(save_map[row_addr / 24][col_addr / 24] == 4'b0000)begin //black orimap
						vga_data <= orimap;
					end
					else if(save_map[row_addr / 24][col_addr / 24] == 4'b0010)begin	//red brick
						vga_data <= col_brick;
					end
					else if(save_map[row_addr / 24][col_addr / 24] == 4'b0011)begin		//blue box
						vga_data <= col_box;//
					end
				//end
			end
		end
	end
	
	disp_num m0(clk,winner,4'b0,4'b0,1'b0,AN,SEGMENT);
	
	winone fir (
	  .clka(clk),
	  .wea(0),
	  .addra(endover), // input [9 : 0] a
	  .dina(0),
	  .douta(col_wo) // output [11 : 0] spo
	);
	wintwo sec (
	  .clka(clk),
	  .wea(0),
	  .addra(endover), // input [9 : 0] a
	  .dina(0),
	  .douta(col_wt) // output [11 : 0] spo
	);
	FTanka atank(
	  .clka(clk),
	  .wea(0),
	  .addra(atkaddr),
	  .dina(0),
	  .douta(tka)
	);
	FTankb btank(
	  .clka(clk),
	  .wea(0),
	  .addra(btkaddr),
	  .dina(0),
	  .douta(tkb)
	);
	FBrick getbr(
	  .clka(clk), // input clka
	  .wea(0), // input [0 : 0] wea
	  .addra(row_addr % 24 * 24 + col_addr % 24), // input [17 : 0] addra
	  .dina(0), // input [11 : 0] dina
	  .douta(col_brick) // output [11 : 0] douta
	);
	FBox getbo(
	  .clka(clk), // input clka
	  .wea(0), // input [0 : 0] wea
	  .addra(row_addr % 24 * 24 + col_addr % 24), // input [17 : 0] addra
	  .dina(0), // input [11 : 0] dina
	  .douta(col_box) // output [11 : 0] douta
	);
	FGrass getgs(
	  .clka(clk), // input clka
	  .wea(0), // input [0 : 0] wea
	  .addra(row_addr % 24 * 24 + col_addr % 24), // input [17 : 0] addra
	  .dina(0), // input [11 : 0] dina
	  .douta(col_grass) // output [11 : 0] douta
	);
	amp getma(
	  .clka(clk), // input clka
	  .wea(0), // input [0 : 0] wea
	  .addra(ckmapa), // input [17 : 0] addra
	  .dina(0), // input [11 :
	  .douta(orimap) // output [11 : 0] douta
	);
	
	assign segTestData = {7'b0,x,8'b0,y};
	wire [15:0] ledData;
	assign ledData = SW_OK;
	ShiftReg #(.WIDTH(16)) ledDevice (.clk(clkdiv[3]), .pdata(~ledData), .sout({LED_CLK,LED_DO,LED_PEN,LED_CLR}));
endmodule
