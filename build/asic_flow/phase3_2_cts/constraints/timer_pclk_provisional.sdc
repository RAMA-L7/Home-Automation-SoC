# ---------------------------------------------------------------------------
# Home-Automation-SoC — timer block: PROVISIONAL clock constraint for CTS
#
# STATUS: PROVISIONAL — NOT APPROVED. Not a signoff constraint. It exists so the
#         CTS configuration can be prepared and reviewed, not so timing can be
#         claimed. See reports/ASIC_PHASE3_2_CTS_READINESS.md.
#
# Block under constraint : timer (rtl/rtl_peripherals/timer.sv, unmodified)
# Clock port             : pclk
# Netlist                : build/asic_flow/phase3_exploratory_pnr/02_mapping_probe/timer_sky130.v
# Baseline database      : build/asic_flow/phase3_exploratory_pnr/03_mapped_timer/timer_mapped_placed.odb
#
# WHY 40.000 ns
#   docs/requirements/system_requirements.md
#     FR-CLK-002 "Peripheral clock: 25 MHz (core/2), synchronous"  (Mandatory)
#   docs/architecture/ARCHITECTURE_DECISION_RECORDS.md
#     ARC-006    "Clocking: 50 MHz core (Si5351), 25 MHz periph, 32 kHz LPO"  (PROPOSED)
#   docs/requirements/performance_requirements.md
#     "Timer0/1 | Resolution | 32-bit @ 25 MHz | 40 ns ticks"
#   25 MHz  ->  1/25e6 s = 40.000 ns exactly (derived, not estimated).
#
#   This is the *architecture* number for the peripheral domain. It is NOT an
#   approved implementation target for this block, and it is NOT what the RTL
#   currently produces: has_soc.sv drives the timer from
#   `periph_clk = clk & periph_clk_en_q` (gated, same rate as clk) — there is no
#   core/2 divider in the RTL. See §4 of the readiness report.
# ---------------------------------------------------------------------------

create_clock -name pclk -period 40.000 [get_ports pclk]

# Uncertainty: the two values below are carried over verbatim from the only
# project-level constraint file that exists,
# constraints/timing_constraints/has_soc.sdc, where they were written for
# sys_clk at 20 ns. Reusing them for a 40 ns peripheral clock is an ASSUMPTION
# and part of the approval request — it is not an approved figure for pclk.
set_clock_uncertainty -setup 0.100 [get_clocks pclk]
set_clock_uncertainty -hold  0.050 [get_clocks pclk]

# ---------------------------------------------------------------------------
# DELIBERATELY MISSING — not invented, must be supplied before any STA result
# on this block can mean anything:
#
#   1. Input delays for the APB request side (penable, pwrite, paddr[31:0],
#      pwdata[31:0], pstrb[3:0]) relative to pclk.
#   2. Output delays for the APB response side (prdata[31:0], pready, pslverr)
#      and for irq.
#   3. Clock transition / clock latency targets (CTS sizing and skew targets).
#   4. Drive strength / load model for pclk's off-block driver.
#
# The SoC-level SDC sets `set_input_delay -max 5.0 [all_inputs]` and
# `set_output_delay -max 5.0 [all_outputs]`; that is a top-level pin budget and
# cannot be transferred to a block whose ports are all synchronous APB signals
# (and `all_inputs` there would include the clock port itself). Copying it would
# be an invented constraint, so it is left out on purpose.
# ---------------------------------------------------------------------------
