	`timescale 1ns/1ps
	module clock_sim(CK50M, fr_SW, fr_KEY, to_LEDR, to_HEX0, to_HEX1, to_HEX2, to_HEX3, to_HEX4, to_HEX5);
		 input CK50M;
		 input [9:0] fr_SW;
		 input [1:0] fr_KEY;
		 output [9:0] to_LEDR;
		 output [7:0] to_HEX0, to_HEX1, to_HEX2, to_HEX3, to_HEX4, to_HEX5;

		 // LED mirror
		 assign to_LEDR = fr_SW;

		 // Input decoding
		 wire show_date = fr_SW[9];
		 wire [1:0] which_field = fr_SW[8:7];
		 wire [6:0] sw_value = fr_SW[6:0];

		 // Tick Generator (1Hz)
		 wire [25:0] sec_counter;
		 wire sec_tick;
		 param_ctr #(5, 8) sec_ctr(CK50M, sec_counter, sec_tick);

		 // Edge Detector for Buttons
		 reg [1:0] key_ff1 = 2'b11, key_ff2 = 2'b11;
		 wire key0_edge, key1_edge;
		 always @(posedge CK50M) begin
			  key_ff1 <= fr_KEY;
			  key_ff2 <= key_ff1;
		 end
		 assign key0_edge = key_ff2[0] & ~key_ff1[0];
		 assign key1_edge = key_ff2[1] & ~key_ff1[1];

		 // Button press sync with 1Hz domain
		 reg key0_sync_ff = 0, key1_sync_ff = 0;
		 reg key0_sync = 0, key1_sync = 0;
		 reg key0_press = 0, key1_press = 0;
		 always @(posedge CK50M) begin
			  key0_sync_ff <= key0_edge;
			  key1_sync_ff <= key1_edge;
			  if (sec_tick) begin
					key0_press <= key0_sync;
					key1_press <= key1_sync;
					key0_sync <= 0;
					key1_sync <= 0;
			  end else begin
					if (key0_sync_ff) key0_sync <= 1;
					if (key1_sync_ff) key1_sync <= 1;
			  end
		 end



		 // Time Registers
		 reg [5:0] sec = 0, min = 0, day = 1;
		 reg [4:0] hour = 0;
		 reg [6:0] year = 0;
		 reg [3:0] month = 1;

		 // Alarm Registers
		 reg [5:0] alarm_sec = 0, alarm_min = 0;
		 reg [4:0] alarm_hour = 0;
		 reg alarm_active = 0, alarm_triggered = 0;
		 reg [3:0] alarm_timer = 0;
		 reg alarm_mode = 0;

		 // Main FSM
		 always @(posedge sec_tick) begin
			  // Clock counting
			  sec <= (sec == 59) ? 0 : sec + 1;
			  if (sec == 59) begin
					min <= (min == 59) ? 0 : min + 1;
					if (min == 59) begin
						 hour <= (hour == 23) ? 0 : hour + 1;
						 if (hour == 23) begin
							  if (day == max_day(month, year)) begin
									day <= 1;
									if (month == 12) begin
										 month <= 1;
										 year <= year + 1;
									end else begin
										 month <= month + 1;
									end
							  end else begin
									day <= day + 1;
							  end
						 end
					end
			  end

			  // Toggle alarm mode on key1 press
			  if (key1_press) begin
					alarm_mode <= ~alarm_mode;
					if (!alarm_mode) alarm_active <= 1;
			  end

			  // Update values
			  if (!alarm_mode && key0_press) begin
					if (!show_date) begin
						 case (which_field)
							  2'b01: if (sw_value < 60)  sec  <= sw_value;
							  2'b10: if (sw_value < 60)  min  <= sw_value;
							  2'b11: if (sw_value < 24)  hour <= sw_value[4:0];
						 endcase
					end else begin
						 case (which_field)
							  2'b01: if (sw_value >= 1 && sw_value <= 31) day   <= sw_value;
							  2'b10: if (sw_value >= 1 && sw_value <= 12) month <= sw_value[3:0];
							  2'b11: if (sw_value < 100)                  year  <= sw_value[6:0];
						 endcase
					end
			  end else if (alarm_mode && key0_press) begin
					case (which_field)
						 2'b01: if (sw_value < 60) alarm_sec  <= sw_value;
						 2'b10: if (sw_value < 60) alarm_min  <= sw_value;
						 2'b11: if (sw_value < 24) alarm_hour <= sw_value[4:0];
					endcase
					alarm_active <= 1;
			  end

			  // Trigger alarm
			  if (alarm_active && !alarm_triggered &&
					hour == alarm_hour && min == alarm_min && sec == alarm_sec) begin
					alarm_triggered <= 1;
					alarm_timer <= 9;
			  end

			  // Reset alarm after 10 seconds
			  if (alarm_triggered) begin
					if (alarm_timer > 0)
						 alarm_timer <= alarm_timer - 1;
					else begin
						 alarm_triggered <= 0;
						 alarm_active <= 0;
					end
			  end
		 end

		 // Max Day Function
		 function [5:0] max_day;
			  input [3:0] m;
			  input [4:0] y;
			  reg leap;
			  begin
					leap = (y % 4 == 0);
					case (m)
						 1,3,5,7,8,10,12: max_day = 31;
						 4,6,9,11:        max_day = 30;
						 2:               max_day = leap ? 29 : 28;
						 default:         max_day = 31;
					endcase
			  end
		 endfunction

		 // Display Logic
		 wire [7:0] val0 = (alarm_mode ? alarm_sec  : show_date ? day   : sec);
		 wire [7:0] val1 = (alarm_mode ? alarm_min  : show_date ? month : min);
		 wire [7:0] val2 = (alarm_mode ? alarm_hour : show_date ? year  : hour);

		 wire [3:0] d0 = val0 % 10;
		 wire [3:0] d1 = val0 / 10;
		 wire [3:0] d2 = val1 % 10;
		 wire [3:0] d3 = val1 / 10;
		 wire [3:0] d4 = val2 % 10;
		 wire [3:0] d5 = val2 / 10;

		 wire blank = alarm_triggered;

		 Seven_Seg_Display disp0(to_HEX0, d0, blank);
		 Seven_Seg_Display disp1(to_HEX1, d1, blank);
		 Seven_Seg_Display disp2(to_HEX2, d2, blank);
		 Seven_Seg_Display disp3(to_HEX3, d3, blank);
		 Seven_Seg_Display disp4(to_HEX4, d4, blank);
		 Seven_Seg_Display disp5(to_HEX5, d5, blank);
	endmodule


	// Param Counter Module
	module param_ctr (clk, count, rollover);
		 parameter MAX = 59;
		 parameter BITS = 8;

		 input clk;
		 output reg [BITS-1:0] count = 0;
		 output reg rollover = 0;

		 reg [BITS-1:0] next_count;
		 reg next_rollover;

		 // Combinational Logic: Next State
		 always @(*) begin
			  if (count == MAX - 1) begin
					next_count = 0;
					next_rollover = 1;
			  end else begin
					next_count = count + 1;
					next_rollover = 0;
			  end
		 end

		 // Sequential Logic: State Update
		 always @(posedge clk) begin
			  count <= next_count;
			  rollover <= next_rollover;
		 end
	endmodule



	// 7-Segment Display Module
	module Seven_Seg_Display(Display, BCD, Blanking);
		 output reg [7:0] Display;
		 input [3:0] BCD;
		 input Blanking;

		 parameter BLANK = 8'b11111111;
		 parameter ZERO  = 8'b11000000;
		 parameter ONE   = 8'b11111001;
		 parameter TWO   = 8'b10100100;
		 parameter THREE = 8'b10110000;
		 parameter FOUR  = 8'b10011001;
		 parameter FIVE  = 8'b10010010;
		 parameter SIX   = 8'b10000010;
		 parameter SEVEN = 8'b11111000;
		 parameter EIGHT = 8'b10000000;
		 parameter NINE  = 8'b10010000;

		 always @(*) begin
			  if (Blanking)
					Display = BLANK;
			  else begin
					case (BCD)
						 4'd0: Display = ZERO;
						 4'd1: Display = ONE;
						 4'd2: Display = TWO;
						 4'd3: Display = THREE;
						 4'd4: Display = FOUR;
						 4'd5: Display = FIVE;
						 4'd6: Display = SIX;
						 4'd7: Display = SEVEN;
						 4'd8: Display = EIGHT;
						 4'd9: Display = NINE;
						 default: Display = BLANK;
					endcase
			  end
		 end
	endmodule
