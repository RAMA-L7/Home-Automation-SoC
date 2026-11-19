# Self-review — RUN-0004 (I2C STOP fix)

Status: **SELF-EVALUATED** (no independent reviewer available).

## What changed
- `rtl/rtl_peripherals/i2c_ctrl.sv`: `I_STOP_B` now runs all four quarters and
  drives SDA low for `q < 2`, releasing it at `q == 2` while SCL is high.
- `sim/sim_top/tb_i2c_xfer.v`: STOP detection now requires SCL high at the
  previous sample (`scl_p && scl && !sda_p && sda`); an SDA rise while SCL was
  still low is counted as `invalid_stop` and fails the test.

## Why this is not a weakened test
The assertion got stricter, not looser. The negative control (RUN-0002, same
test, unmodified RTL) fails with 5 reported failures and exit 1; the fix is
what makes it pass.

## Residual doubts
- The test measures one clock-domain view of SCL/SDA (2-cycle edge sampling at
  `pclk=100 MHz`, `CLKDIV=2`). It proves ordering (SCL high before SDA rises),
  not analog setup/hold times.
- No pull-up strength or bus capacitance is modelled, so rise time is ideal.
- `do_stop` is still ignored by the FSM: a command without the stop bit also
  ends with a STOP. That is a separate deviation from the register contract and
  is not fixed here (would need repeated-START support).
