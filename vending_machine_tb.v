`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Simple testbench for: vending_machine
//   Single product, price = 15/-, coins accepted: 5/- and 10/-
//
// coin encoding: 00 = no coin, 01 = 5/- coin, 10 = 10/- coin
//
// This is a plain stimulus + $monitor testbench: it just drives coins in,
// one clock cycle at a time, and prints every signal on every clock edge.
// You read the printed table and check it matches what you expect by eye -
// no automatic pass/fail checking, which keeps it easy to follow.
//////////////////////////////////////////////////////////////////////////////////

module vending_machine_tb;

    reg        clk, rst;
    reg  [1:0] coin;
    wire       dispense;
    wire       change_5;
    wire [4:0] balance;

    // Instantiate the vending machine
    vending_machine dut (
        .dispense (dispense),
        .change_5 (change_5),
        .balance  (balance),
        .coin     (coin),
        .clk      (clk),
        .rst      (rst)
    );

    // Clock: toggles every 5ns -> 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Print every signal, every time any of them changes
    initial begin
        $display(" time  rst coin balance dispense change_5");
        $monitor(" %4t   %b   %b    %2d       %b        %b",
                  $time, rst, coin, balance, dispense, change_5);
    end

    initial begin
        // 1) Reset the machine
        rst  = 1;
        coin = 2'b00;
        #10;
        rst = 0;

        // 2) Insert a 5/- coin, then a 10/- coin -> total 15, exact price
        #10 coin = 2'b01;   // 5/-
        #10 coin = 2'b10;   // 10/-  -> balance should reach 15, dispense = 1
        #10 coin = 2'b00;   // no coin -> machine goes back to IDLE, balance = 0

        // 3) Insert two 10/- coins -> total 20, which is 5/- more than the price
        #10 coin = 2'b10;   // 10/-
        #10 coin = 2'b10;   // 10/-  -> balance should reach 20, dispense = 1, change_5 = 1
        #10 coin = 2'b00;   // no coin -> machine goes back to IDLE, balance = 5 (change)

        // 4) Insert three 5/- coins -> total 15, exact price
        #10 coin = 2'b01;
        #10 coin = 2'b01;
        #10 coin = 2'b01;   // -> balance should reach 15, dispense = 1
        #10 coin = 2'b00;   // -> back to IDLE, balance = 0

        // 5) Idle for a bit with no coin - nothing should change
        #10 coin = 2'b00;
        #10 coin = 2'b00;

        // 6) Reset again in the middle of nothing, just to confirm it clears
        #10 rst = 1;
        #10 rst = 0;

        #20;
        $display("Testbench finished.");
        $finish;
    end
    initial begin
	$dumpfile("vending_machine.vcd");
	$dumpvars(0,vending_machine_tb);
    end
endmodule
