Add 3-state Moore FSM vending machine RTL and testbench

### Summary
Implements a single-product vending machine RTL module along with a simulation testbench.

### Key Details
* **Vending Machine (`vending_machine.v`)**:
  * Product price set to 15/- units.
  * Accepts 5/- (`2'b01`) and 10/- (`2'b10`) coins.
  * Uses a 3-state Moore Finite State Machine (`IDLE`, `WAIT_ST`, `DISPENSE`).
  * Features glitch-free outputs for item dispensation (`dispense`) and change calculation (`change_5`).

* **Testbench (`vending_machine_tb.v`)**:
  * Drives various coin insertion sequences (exact payment, overpayment requiring change, multiple 5/- coins).
  * Includes `$monitor` task for terminal logging and `$dumpvars` for GTKWave/VCD waveform viewing.
