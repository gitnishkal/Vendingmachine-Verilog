`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : vending_machine
// Description : 3-state Moore FSM vending machine, simplified to a single
//               product priced at 15/-, paid for with 5/- and 10/- coins.
//
//   No product-select input is needed anymore since there's only one item -
//   inserting a coin is itself the start of a purchase.
//
//   With coins of only 5/- and 10/- and a price of 15/-, the only way to
//   overpay is 10/- + 10/- = 20/-, which is exactly 5/- too much. So the
//   change owed is always either 0 or a single 5/- coin - no need for a
//   multi-bit change amount, one output bit is enough.
//
// States:
//   IDLE     - no active purchase. Any coin starts one: latch its value into
//              balance and decide whether it's already enough.
//   WAIT_ST  - a purchase is in progress; each cycle's coin (if any) adds to
//              balance until it covers the price.
//   DISPENSE - one-cycle pulse: assert `dispense` (and `change_5` if the
//              balance was 20), subtract price from balance, then go back
//              to IDLE.
//////////////////////////////////////////////////////////////////////////////////

module vending_machine(
    output reg       dispense,
    output reg       change_5,     // pulses for one cycle if a 5/- coin is owed as change
    output reg [4:0] balance,
    input      [1:0] coin,        // 2'b00 = no coin, 2'b01 = 5/- coin, 2'b10 = 10/- coin
    input            clk, rst
);

    // Coin codes
    localparam [1:0] COIN_NONE = 2'b00;
    localparam [1:0] COIN_5    = 2'b01;
    localparam [1:0] COIN_10   = 2'b10;
    // 2'b11 is unused/illegal for coin - treated as no coin below

    localparam [4:0] PRICE = 5'd15;

    // FSM states
    localparam [1:0] IDLE     = 2'b00;
    localparam [1:0] WAIT_ST  = 2'b01;
    localparam [1:0] DISPENSE = 2'b10;

    reg [1:0] state, next_state;
    reg [4:0] balance_next;
    reg [4:0] coin_value;     // rupee value of whatever coin is on the input this cycle

    // Combinational coin-value lookup
    always @(*) begin
        case (coin)
            COIN_5:  coin_value = 5'd5;
            COIN_10: coin_value = 5'd10;
            default: coin_value = 5'd0;  // COIN_NONE or illegal code -> no money added
        endcase
    end

    // Next-state / next-balance logic. Every branch has a default, so
    // nothing here can synthesize to a latch.
    always @(*) begin
        next_state   = state;
        balance_next = balance;

        case (state)
            IDLE: begin
                if (coin_value != 5'd0) begin
                    balance_next = coin_value;
                    if (coin_value >= PRICE)
                        next_state = DISPENSE;
                    else
                        next_state = WAIT_ST;
                end
            end

            WAIT_ST: begin
                balance_next = balance + coin_value;
                if (balance_next >= PRICE)
                    next_state = DISPENSE;
                else
                    next_state = WAIT_ST;
            end

            DISPENSE: begin
                balance_next = balance - PRICE;
                next_state   = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // State/balance register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            balance <= 5'd0;
        end else begin
            state   <= next_state;
            balance <= balance_next;
        end
    end

    // Moore outputs: driven purely by registered state (+ balance, which is
    // also registered), so they're glitch-free and valid exactly one cycle
    // after entering DISPENSE.
    always @(*) begin
        dispense = (state == DISPENSE);
        change_5 = (state == DISPENSE) && (balance == 5'd20); // 10+10 overpay case
    end

endmodule
