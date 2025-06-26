FPGA-Based Real-Time Clock and Alarm System
This project implements a real-time digital clock and alarm system on an FPGA board. The design uses a parametric counter for timekeeping, supports date and alarm settings via switches and buttons, and displays output on 7-segment displays.

Project Summary
Platform: FPGA (50 MHz system clock)
Language: Verilog

Features:
Real-time clock (hours, minutes, seconds)
Full calendar (day, month, year)
Alarm system with 10-second visual alert
Date & time configuration via switches (fr_SW)
Mode switching and confirmation via push-buttons (fr_KEY)
FSM-based control logic for mode transitions
BCD to 7-segment display logic
Leap year-aware date handling

Demo & Simulation
Clock increments every second with correct rollovers (e.g., sec → min → hr).
Date mode allows manual setting of day/month/year.
Alarm mode activates at a predefined time and blanks all displays for 10 seconds.
Detailed testbench simulations verify each time unit transition and alarm behavior.

System Architecture
param_ctr: Generic parametric counter for clock division (e.g., 50MHz → 1Hz)
FSM: Controls normal clock progression and alarm trigger
max_day(): Determines maximum day count per month, accounting for leap years
Seven_Seg_Display: Converts BCD inputs to 7-segment format
Edge Detection: Debounced trigger for push-buttons (key0, key1)
Display Mode Toggle: Toggle between clock and date view using fr_SW[9]
