`timescale 1ns/1ps
module clock_sim_tb;

    // Inputs
    reg CK50M = 0;
    reg [9:0] fr_SW = 0;
    reg [1:0] fr_KEY = 2'b11;

    // Outputs
    wire [9:0] to_LEDR;
    wire [7:0] to_HEX0, to_HEX1, to_HEX2, to_HEX3, to_HEX4, to_HEX5;

    // Instantiate the Unit Under Test
    clock_sim uut (.CK50M(CK50M), .fr_SW(fr_SW), .fr_KEY(fr_KEY), .to_LEDR(to_LEDR), .to_HEX0(to_HEX0),
        .to_HEX1(to_HEX1), .to_HEX2(to_HEX2), .to_HEX3(to_HEX3), .to_HEX4(to_HEX4), .to_HEX5(to_HEX5));

    // 500 MHz Clock for faster simulation (2 ns period) 
    always #1 CK50M = ~CK50M;

    initial begin
        // Initial state - wait a bit
        #200;

        // Set TIME 
        // Show time mode
        fr_SW[9] = 0;

        // Set hour to 23 
        fr_SW[8:7] = 2'b11;  // hour field
        fr_SW[6:0] = 7'd23;
        #20;  fr_KEY[0] = 0;  // key0 press
        #20;  fr_KEY[0] = 1;  // key0 release
        #200;

        // Set minute to 59
        fr_SW[8:7] = 2'b10;  // minute field
        fr_SW[6:0] = 7'd59;
        #20;  fr_KEY[0] = 0;
        #20;  fr_KEY[0] = 1;
        #200;

        // Set second to 58
        fr_SW[8:7] = 2'b01;  // second field
        fr_SW[6:0] = 7'd58;
        #20;  fr_KEY[0] = 0;
        #20;  fr_KEY[0] = 1;
        #500;

        // Set DATE
        fr_SW[9] = 1;  // switch to date mode
        #200;

        // Set day to 31 
        fr_SW[8:7] = 2'b01;
        fr_SW[6:0] = 7'd31;
        #20;  fr_KEY[0] = 0;
        #20;  fr_KEY[0] = 1;
        #200;

        // Set month to 12 
        fr_SW[8:7] = 2'b10;
        fr_SW[6:0] = 7'd12;
        #20;  fr_KEY[0] = 0;
        #20;  fr_KEY[0] = 1;
        #200;

        // Set year to 25
        fr_SW[8:7] = 2'b11;
        fr_SW[6:0] = 7'd25;
        #20;  fr_KEY[0] = 0;
        #20;  fr_KEY[0] = 1;
        #1000;

        // Trigger alarm mode via KEY1
        #200;
        fr_KEY[1] = 0;  // key1 press
        #20;
        fr_KEY[1] = 1;  // key1 release
        #200;

        // Set alarm time: 00:00:05
        fr_SW[9] = 0;  
        fr_SW[8:7] = 2'b11;  // hour
        fr_SW[6:0] = 7'd0;
        #20; fr_KEY[0] = 0; #20; fr_KEY[0] = 1; #200;

        fr_SW[8:7] = 2'b10;  // minute
        fr_SW[6:0] = 7'd0;
        #20; fr_KEY[0] = 0; #20; fr_KEY[0] = 1; #200;

        fr_SW[8:7] = 2'b01;  // second
        fr_SW[6:0] = 7'd5;
        #20; fr_KEY[0] = 0; #20; fr_KEY[0] = 1; #200;

        //Let the system run
        #5000;

        $stop;
    end

endmodule
