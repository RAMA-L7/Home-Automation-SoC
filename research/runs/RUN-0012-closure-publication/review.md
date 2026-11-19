# RUN-0012 — review record and interventions

## Review condition

| Item | Value |
|---|---|
| Experiment condition | development |
| Author of the changes | agent (Buffy, model DeepSeek V4.1 Flash) |
| Author of the checks | agent |
| Independent evaluator | **none available** |
| Autonomy classification | **SELF-EVALUATED** |
| Effect on acceptance | G4.4 stays OPEN; no result in this run may be cited as independently validated |

The agent wrote both the fixes and the checks that judge them. Negative
controls are the only defence against that circularity here, which is why every
claim in `evidence-matrix.md` that could be gamed has at least one control that
must fail: four publication controls, sixteen structural controls, seven memory
controls and three I2C timing controls. Controls show that a check *can* fail;
they do not make the agent independent.

## External review as an intervention

The task text is itself an external review of revision `418688b`. It is recorded
here as an intervention rather than as acceptance: a reviewer found that the
published tree did not contain the files its own commands and reports cited, that
a checker self-test had been standing in for a design check, that the I²C claim
covered transactions but not timing, and that the memory sizes in the RTL and in
the requirement disagreed. Those four findings were acted on in this run
(F5, F8, F10, and the publication repair). The reviewer is not available to
evaluate the result, so the findings are marked closed by the *author*, and the
review that would close them independently has not happened.

## Interventions during the run

| # | Intervention | Why | Effect on results |
|---|---|---|---|
| 1 | The first closure run at `1f0b27f` passed every functional stage but the `structural-design` reason string still quoted the pre-F5 geometry (ROM 16384x32, SRAM 65536x32) | the declared gap must describe the design that is actually synthesised, or a stale inventory reads as current | committed as `a40687d`; the gate was re-run and this directory records that run, not the earlier one |
| 2 | The earlier session's memory investigation recommended widening the address map (Option B) | the recommended option changed an approved requirement and the area budget to match oversized arrays | superseded in the same document, with the reasoning and the actual change recorded; F5 resolved the other way |
| 3 | `tb_mem_contract.v` needed a module-scope package import | Icarus rejects it there; file-scope import with the package first on the command line works in both Icarus and Verilator | testbench structure only; no check relaxed |
| 4 | Fast-mode I²C (400 kHz) was considered and dropped | a symmetric 2-high/2-low quarter duty gives tLOW 1.24 us at 403 kHz against a 1.3 us minimum; meeting it needs a duty setting the generator does not have | 400 kHz documented as unsupported instead of claimed |

## What a reviewer should look at first

1. `git ls-files research` versus the paths quoted in `README.md` and `AGENTS.md`.
2. `scripts/verify.js` stage list against `logs/closure_verify.log`.
3. `sim/sim_top/tb_i2c_timing.v` — whether the measurement is at the pins and
   whether the limits quoted are the standard-mode ones.
4. `rtl/rtl_top/boot_rom.sv` and the SRAM instance in `has_soc.sv` against
   `has_addr_map.sv`, `linker.ld` and FR-MEM-001/003.
5. The three failing controls in `logs/stage_i2c-timing.log` — a green control
   proves nothing; these three are required to fail.
