# Limitations (as of 2026-11-18)

## Evaluation
- **No independent evaluator exists** in this environment. Every check in this
  tree is SELF-EVALUATED. G4 (audited handoff) is therefore unreachable by
  construction, whatever the local results.
- No held-out test set, no external reference model, no third-party signoff.

## Provenance and attribution
- Original prompts and transcripts from earlier sessions are not present in the
  repository. Autonomy attribution for that work relies on `AGENTS.md` entries
  and the recorded external review, not on primary transcripts.
- The current continuation is review-assisted: the defect list came from an
  external review at `025ef24`. Findings are re-verified against source, but the
  agenda was supplied.

## Environment
- No fab PDK provisioning: sky130A is not volare-enabled, so no OpenLane 2 flow
  has executed. No place, route, extraction, DRC/LVS, antenna or power analysis
  exists for the full SoC.
- No Vivado and no FPGA hardware: Stage 5 cannot be synthesised or programmed.
- `verilator` (the Perl wrapper at `D:\tools\oss-cad-suite\bin\verilator`) fails
  on this shell — `Pod/Usage.pm` is missing. `verilator_bin.exe` 5.053 works and
  is what RUN-0011 used. The gate's tool inventory now reports it (falling back
  from `verilator` to `verilator_bin`) instead of calling Verilator absent.
- Verilator lint exits 1 under `-Wall`: 0 errors, 123 warnings over 24 files.
  Calling that "PASS" without the warning count overstates it.
- The Verilator C++ boot is fast in absolute terms but not 20,000× real time:
  4 ms simulated in 0.233 s wall (≈17 ms simulated per wall-second).
- `build/verify/` is a single mutable log directory shared by real gate runs and
  negative controls; a control run overwrites the evidence of the previous real
  run (this happened at 20:51 on 2026-11-18 and was repaired by re-running the
  gate). Run-scoped log directories are not implemented.
- `python` on PATH is the Windows Store stub; scripts that assume it fail. The
  venv interpreter (`D:\tools\venv\Scripts\python.exe`) works and is what the
  gate uses.
- Toolchain discovery is unified (F6 fixed, RUN-0010): one validated resolver,
  xPack GCC 12.2.0-2 only. `build_fw.py` delegates to it and therefore needs
  `node`; a second, genuine toolchain is unavailable for conflict testing.
- Windows/Git Bash: no `make`, no POSIX shell inside cmd; tools are invoked
  through `cmd //c "call D:\tools\oss-cad-suite\environment.bat && …"`.

## Evidence
- Verification results are reproducible from this tree for the targets in
  `runs/RUN-0011-evidence-provenance/evidence-matrix.md`, but the older
  `reports/verification/*` snapshots and `build/baseline/*` logs still contain
  superseded numbers (banner-marked, preserved as history). A number quoted
  without its run id is not trustworthy.
- `build/verify/` is a single mutable log directory: a negative-control run
  overwrites a real gate run's logs. RUN-0011 re-ran the gate last and recorded
  the log hashes, but run-scoped log paths are still not implemented.
- PPA does not exist for this design in this environment: no ABC `-liberty`, no
  PDK, no place/route. Cell counts are generic and pre-ABC (`riscv_core`:
  44,323 cells), not area or timing.
- The in-tree library `build/asic_evidence/sky130_full_subset.lib` is a subset:
  it carries 11 cells, each with an `ff`/`clocked_on` block identical to the full
  liberty. The earlier claim that it omitted `dfrbp`'s block was wrong
  (corrected in RUN-0008). Cells outside the subset still cannot be confirmed
  in-tree, and the full `sky130_tt.lib` is untracked (hash recorded per run).
- The behavioural stub proves cell **function** only: no timing, no
  recovery/removal, no power pins. `dfrbp` is modelled and tested (RUN-0008) but
  no flow emits it — the mapper uses `dfxtp_1`/`dfrtp_1`/`dfstp_1` — so that
  model is verified without a mapped netlist using it.
- Memory implementation is unresolved and now quantified (RUN-0009): 4 inferred
  `$mem_v2` — boot ROM 16384x32 (2R), TCM 8192x32 (2R1W), SRAM 65536x32 (2R1W),
  and an 18 B APB decode LUT — plus 136 B of register storage. That is 360,466 B
  of arrays against 180,224 B of addressable space: the ROM is 4x and the SRAM
  2x the aperture they are decoded into (F5). No `.lib`/`.lef`/`.gds` macro exists
  and no memory compiler has run (F7).
- RAM contents are undefined at power-up (no array reset); only the boot ROM has
  initialization data, and by default that data is NOP fill, not a boot image.
- Reported PPA numbers are pre-ABC cell counts and tool-reported area at
  `tt_025C_1v80`; they are not silicon measurements and not timing-closed.
- No silicon exists. Any statement implying measurement, foundry approval or
  manufacturing signoff would be false.

## Study design
- One agent, one model, one repository: a case study, not a benchmark. It
  cannot establish general model superiority.
- Ten-calendar-day ceiling; the deadline limits execution time, not criteria.
