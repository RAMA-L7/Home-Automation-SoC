# Home-Automation-SoC — ASIC Flow Phase 1 Baseline Report

**Project:** Home-Automation-SoC  
**Repository:** `D:\Home-Automation-SoC`  
**Date:** 2026-11-14  
**Branch:** `main`  
**HEAD:** `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1`  

**Scope:** Documentation/planning only. No RTL, wrapper, testbench, script, filelist, PDK, SDC, evidence, or Git operations were mutated. No ASIC signoff or tapeout readiness claim is made.

**Top-level outcomes:**

- ✅ Decision record preserved/corrected as PROPOSED with required verification ID coverage.
- ✅ Specification SHA-256 confirmed against reported final hash.
- ✅ PDK/macros inspected; Sky130HD TT platform and `sky130_sram_1rw1r_128x256_8` macro views present.
- ✅ Generic synthesis completed for the listed modules.
- ⚠️ Technology mapping explored for `riscv_core` and selected logic-only peripherals; tech-mapped synthesis is **blocked** by unsupported async-reset sequential cells in this Yosys build. Historical Phase 1 techmap logs recorded `$adffe`-class wide-cell messages for some modules; the corrected Phase 1.1 runs on riscv_core and the six missing peripherals produced `$adff` cells during proc/techmap and then failed at DFF legalization on unsupported async-reset sequential cells (`$_DFF_PN0_`/`$_DFF_PN1_`), with no `$adffe` created in those corrected runs. Both are blocked; the blocker class differs between the historical logs and the corrected runs.
- ❌ OpenROAD physical-flow smoke test is **BLOCKED** by missing OpenROAD/OpenSTA binaries in both the host Windows environment and the WSL Ubuntu-24.04 environment.
- ✅ SRAM macro integration readiness documented, without creating wrapper RTL.
- 📄 Final baseline report written.

---

## 1. Repository integrity

- Branch: `main`
- HEAD: `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1`
- Tracked diff blob hash (SHA-1, git object hash of the unified diff against HEAD): `0c4bd5d5c1378229735a71b3a28da5913481b306` (verified by reproducing the tracked diff as a git blob with `git diff HEAD > /tmp/tracked_diff_patch.txt && git hash-object -t blob /tmp/tracked_diff_patch.txt`). The same tracked diff file's SHA-256 content hash is `f0245fac670fd4a4920637f3f543e22b3266e658f1cfa16f993fb63bc097990d`; both values are quoted so either reference can be reproduced and verified.
- No mutating Git operations were performed. Repository state was inspected using read-only commands.

---

## 2. Specification verification

- Specification file: `reports/ASIC_MEMORY_WRAPPER_ARCHITECTURE_SPEC.md`
- Verified SHA-256: `8d7221f7e195a11ece2881f97a2d3cfeb4cb9b23677c4e9184060a01550d71b5`
- Table D was inspected directly in the live specification and is already corrected in the repository file.
- No spec correction was required during this session.

---

## 3. Tool availability

Available on the host Windows environment with `D:\tools\oss-cad-suite` on PATH:

- **Yosys:** `Yosys 0.69+154 (git sha1 30d62572e-dirty, Release, GNU /usr/bin/x86_64-w64-mingw32-g++ 15.2.1)` — path `D:\tools\oss-cad-suite\bin\yosys.exe`
- **Yosys (YoWASP):** `Yosys 0.69 (git sha1 9f75ca1f9, Release, Clang /workspace/YoWASP/yosys/wasi-sdk-33.0-x86_64-linux/share/cmake/../..//bin/clang++ 22.1.0)` — also present
- **Verilator:** present at `D:\tools\oss-cad-suite\bin\verilator.exe`, but the Windows host Perl runtime is missing `Pod::Usage`, so `--version` could not be completed from the host shell.
- **Icarus Verilog:** present at `D:\tools\oss-cad-suite\bin\iverilog.exe`, but the Windows-native `--version` flag is not accepted by this executable (`unknown option -- -`).

Not available:

- **OpenROAD:** not present on the host Windows `PATH`; not present in WSL `Ubuntu-24.04`.
- **OpenSTA:** not present on the host Windows `PATH`; not present in WSL `Ubuntu-24.04`.
- **OpenLane:** not present on the host Windows `PATH`; not present in WSL `Ubuntu-24.04`.
- **Magic:** wrapper script present at `D:\tools\magic\bin\magic`, but the wrapped Tcl runtime is broken — `magicdnull not found under /mnt/d/tools/magic/usr/lib/x86_64-linux-gnu/magic/tcl`. Not usable.
- **Netgen:** wrapper script present at `D:\tools\netgen\bin\netgen`, but fails with `.../mnt/d/tools/netgen/usr/bin/netgen: No such file or directory`. Not usable.
- **KLayout:** wrapper script present at `D:\tools\KLayout\bin\klayout.sh`, but fails with `.../mnt/d/tools/KLayout/usr/bin/klayout: No such file or directory`. Not usable.
- **Python:** not available on the host environment for checking `openroad`/`opensta` Python packages.

WSL note: invoking any `/mnt/d/tools/...` Windows path through `wsl.exe -d Ubuntu-24.04` without `MSYS_NO_PATHCONV=1` rewrites the path to `C:/Program Files/Git/mnt/...` and fails. Even with that prefix, `which openroad`, `which sta`, `which magic`, `which netgen`, `which klayout` all failed in `Ubuntu-24.04`, and the flow-script tree itself does not contain installed OpenROAD/OpenSTA binaries.

---

## 4. PDK validation

**Platform tree:** `D:\rta-real-world-benchmark\02_projects\OpenROAD-flow-scripts\flow\platforms\sky130hd`

Present views:

- Liberty: `flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib`
- LEF: `flow/platforms/sky130hd/lef/sky130_fd_sc_hd.tlef`
- LEF: `flow/platforms/sky130hd/lef/sky130_fd_sc_hd_merged.lef`
- GDS: `flow/platforms/sky130hd/gds/sky130_fd_sc_hd.gds`
- Dummy-io lib: `flow/platforms/sky130hd/lib/sky130_dummy_io.lib`

**SRAM macro tree:** `D:\rta-real-world-benchmark\02_projects\OpenROAD-flow-scripts\flow\platforms\sky130ram\sky130_sram_1rw1r_128x256_8`

Present macro views:

- Verilog model: `sky130_sram_1rw1r_128x256_8.v`
- LEF: `sky130_sram_1rw1r_128x256_8.lef`
- GDS: `sky130_sram_1rw1r_128x256_8.gds`
- TT Liberty: `sky130_sram_1rw1r_128x256_8_TT_1p8V_25C.lib`
- SPICE views: `sky130_sram_1rw1r_128x256_8.sp`, `sky130_sram_1rw1r_128x256_8.lvs.sp`, `functional_stim.sp`
- Python description: `sky130_sram_1rw1r_128x256_8.py`

**Compatibility notes (not assumed, confirmed by inspection):**

- The standard-cell platform LEF uses `vdd`/`gnd` power pins.
- The SRAM macro liberty uses `VDD`/`GND` power names and declares `pg_pin(gnd)` and `pg_pin(vdd)`.
- The macro LEF also declares `gnd` and `vdd` pins, so the macro physical-pin naming matches the platform LEF convention, but the macro liberty naming is different.
- This is a documented integration check only; no PDK, SDC, or config files were modified.

---

## 5. Macro integration findings

**Macro identity:**

- Cell name: `sky130_sram_1rw1r_128x256_8`
- Parameters: `ADDR_WIDTH=8`, `DATA_WIDTH=128`, `NUM_WMASKS=16`, `RAM_DEPTH=256`
- Words: 256
- Word size: 128 bits
- Write size: 8 bits
- Write mask: 16 bits
- Address: 8 bits
- Ports: 1RW + 1R

**Physical size (from LEF):**

- Macro size: `1141.72 x 632.475`
- Symmetry: `X Y R90`

**Interface summary (from LEF + liberty):**

- LEF pins: `clk0`, `clk1`, `csb0`, `csb1`, `web0`, `wmask0`, `addr0`, `din0`, `dout0`, `addr1`, `dout1`, plus power `vdd`/`gnd`
- Liberty pin groups include `clk0`, `clk1`, `csb0`, `csb1`, `web0`, `wmask0[15:0]`, `addr0[7:0]`, `din0[127:0]`, `dout0[127:0]`, `addr1[7:0]`, `dout1[127:0]`

**Behavioral observations relevant to wrapper design:**

- The model contains the warning path: `if (!csb0 && !web0 && !csb1 && (addr0 == addr1))` → `$display("WARNING: Writing and reading addr0=... and addr1=... simultaneously!")`.
- This documents the same-address collision limitation the wrapper must manage.
- The macro is a 256-word by 128-bit array; one instance covers 256 × 128 = 32,768 bits = 4,096 bytes = 4 KB.

**Estimated macro count for full SoC memory:**

- SRAM: 128 KB = 131,072 bytes → 131,072 / 4,096 = 32 instances
- TCM: 32 KB = 32,768 bytes → 32,768 / 4,096 = 8 instances
- Total: 40 macro instances

**Total estimated macro area before placement overhead:**

- Per instance: `1141.72 × 632.475 = 722,109.357` square units
- 40 instances: = `28,884,374.28` square units

This is a pre-placement macro-area estimate only; no floorplan, routing, or congestion analysis was performed.

**Missing or incomplete integration views / findings:**

- Only the TT corner (`TT_1p8V_25C`) is available for this macro.
- No multi-corner timing signoff claim is made (matches D8).
- The macro liberty uses `vdd`/`gnd` power names while the standard-cell liberty/platform LEF uses `vdd`/`gnd`, so power-pin naming compatibility must be verified at the integration level, not assumed from matching Sky130 names.
- No wrapper RTL exists yet, so macro-to-wrapper pin mapping and timing-closure approach are not yet validated.

---

## 6. Generic synthesis results (Phase 3)

Tool: Yosys 0.69+154  
Liberty: not used for generic synthesis  
Output directory: `build/asic_flow/phase1/generic_synthesis/`

Modules synthesized (generic, no PDK mapping):

- `riscv_core`
- `gpio`
- `uart`
- `timer`
- `watchdog`
- `plic`
- `clint`
- `spi_ctrl`
- `i2c_ctrl`
- `pwm`
- `i2s`
- `qspi_flash_ctrl`
- `axi_lite_to_apb`
- `req_gnt_to_axi_lite`
- `reset_ctrl`

Each log records the Yosys version, the frontend used, pass summaries, and final `stat`-style information. Generic synthesis for these modules completed without the async-reset wide-cell blocker that appears later in tech mapping; that blocker is a sequential-cell-mapping limitation, not a generic-elaboration failure.

**Generic synthesis outcome:**

- Generic synthesis for all listed modules completed.
- The behavioral SRAM array is **not** mapped as standard cells here; it is left as a behavioral memory representation, consistent with the restriction not to treat the behavioral array as an acceptable ASIC memory implementation.
- Full-chip elaboration was **not** completed because the top-level `axi_lite_interconnect.sv` contains an unpacked-array port syntax error that blocks both the native Yosys and YoWASP frontends. That limitation prevented full-top synthesis without RTL changes, which were not permitted.

---

## 7. Technology-mapped synthesis results (Phase 4)

Tool: Yosys 0.69+154  
Liberty: `D:\rta-real-world-benchmark\02_projects\OpenROAD-flow-scripts\flow\platforms\sky130hd\lib\sky130_fd_sc_hd__tt_025C_1v80.lib`  
Output directory: `build/asic_flow/phase1/techmap/`

**Plan followed:**

1. Generic prepass: `read_verilog -sv ...`, `hierarchy`, `proc`, `opt`, `memory`, `opt`, `techmap`.
2. Sequential mapping attempted through multiple command variants:
   - `dfflegalize -direct`
   - `dfflegalize` without `-direct`
   - `dfflegalize` after `techmap`
   - `libmap`-style `read_liberty -lib ...`
   - `abc -liberty ...`
3. The surviving Yosys path that advanced furthest was `techmap` + `dfflegalize`/DFFLIBMAP-style mapping, which produced partial mapping tables for several modules before failing on unsupported wide sequential cells.

**Key finding:**

- The Yosys techmap/DFFLEGALIZE flow fails on **wide register cells**, specifically `$adfe`, `$adffe`, and `$adff` variants, with messages such as:
  - `ERROR: Wide register cell type $adffe is not supported.`
  - `ERROR: Wide register cell type $adff is not supported.`
  - `ERROR: FF ... (type $_DFF_PN0_) cannot be legalized: dffs with async set or reset are not supported`
- For `riscv_core`, the final failure is `ERROR: Wide register cell type $adffe is not supported.` in the DFFLEGALIZE pass.
- This is a Yosys sequential-cell support limitation in this run, not an ASIC MACRO issue.

**Per-module techmap outcome:**

Modules with a `build/asic_flow/phase1/techmap/<module>.log` and partial mapping:

- `riscv_core` — partial mapping; **blocked** by one `$adffe` cell in DFFLEGALIZE.
- `gpio` — partial mapping; **blocked** by `$adffe`.
- `uart` — partial mapping; **blocked** by `$adff`.
- `timer` — partial mapping; **blocked** by `$adffe`.
- `watchdog` — partial mapping; **blocked** by `$adff`.
- `reset_ctrl` — partial mapping; **blocked** by `$adff`.
- `axi_lite_to_apb` — partial mapping; **blocked** by `$adffe`.
- `req_gnt_to_axi_lite` — partial mapping; **blocked** by `$adffe`.
- `plic` — partial mapping; **blocked** by `$adff`.

Per-module techmap logs were **not** present in the repository for:

- `clint`
- `spi_ctrl`
- `i2c_ctrl`
- `pwm`
- `i2s`
- `qspi_flash_ctrl`

Those modules were included in the synthesis scope for this phase but did not have a completed techmap log under `build/asic_flow/phase1/techmap/` at original report time. This does **not** imply they passed; it means their techmap result was not available then and is **NOT RUN / EVIDENCE MISSING** from Phase 1, not PASS.

Phase 1.1 corrected these gaps: the six modules were re-inspected with corrected Yosys RTL-path form and correct source directory (`build/asic_flow/phase1_1/techmap` and `reports/evidence/asic_flow_phase1_1`), but the per-module techmap did **not** produce mapped netlists — each failed at DFF legalization on an unsupported `$adff`-type async-reset sequential cell. Those Phase 1.1 outcomes are documented in the Phase 1.1 section and `reports/ASIC_FLOW_PHASE1_1_MAPPING_CLOSURE.md`, and are separate from the historical Phase 1 techmap logs under `build/asic_flow/phase1/techmap/`.

**What worked, what did not:**

- Yosys `read_liberty` and `abc -liberty` are the supported paths in this Yosys build; a plain `liberty` command does not exist.
- `dfflegalize -direct` is **not** accepted by this Yosys build; it produces `ERROR: Command syntax error: Unknown option or option in arguments.`
- Several `dfflegalize` flag combinations were rejected with the same syntax-error form.
- `abc -liberty` can load the Sky130HD TT Liberty through the external `yosys-abc -c "read_lib ..."` entry point, but Yosys `abc -liberty` still cannot complete mapping here because the pre-ABC sequential-cell legalization fails first.
- No technology-mapped netlist was produced for `riscv_core` that is clean enough for downstream OpenROAD use.

**Outcome:**

- Technology-mapped synthesis for `riscv_core` is **BLOCKED**.
- Technology mapping was attempted for selected logic-only peripherals; per the corrected Phase 1.1 runs, **all six missing modules** (clint, spi_ctrl, i2c_ctrl, pwm, i2s, qspi_flash_ctrl) created `$adff` cells during proc/techmap and then failed at DFF legalization on one unsupported async-reset sequential cell (`$_DFF_PN0_` or `$_DFF_PN1_`). The historical Phase 1 logs recorded `$adffe`-class wide-cell messages for some modules; the corrected Phase 1.1 runs produced no `$adffe` and the confirmed blocker in those runs is the `$adff`-class async-reset DFFLEGALIZE failure. Both are blocked; the blocker class differs between the historical logs and the corrected runs.
- No mapped netlist is available for OpenROAD input.

---

## 8. OpenROAD physical-flow smoke test

**Status:** **BLOCKED — tools not available**

No physical-flow smoke test could be run because:

- `openroad` is not installed on the host Windows environment.
- `sta` / `opensta` is not installed on the host Windows environment.
- `openroad` and `sta` are not present in WSL `Ubuntu-24.04` either.
- The flow-script repository contains build scripts (`build_openroad.sh`, `setup.sh`, `dev_env.sh`, `env.sh`) but **no prebuilt OpenROAD or OpenSTA binaries** under `flow/platforms`, `flow/`, or `tools/`.

Because OpenROAD is unavailable, the following were **not** executed and remain **BLOCKED**, not PASS:

- Liberty/LEF loading
- Mapped-netlist reading
- Design linking
- Provisional floorplan initialization
- Global placement
- Detailed placement
- Placement checks
- Area/cell statistics from the physical flow

Missing evidence must remain **BLOCKED**, not **PASS**.

---

## 9. SDC limitations

- No SDC was created, modified, or validated during this phase.
- No signoff constraints were invented.
- No STA signoff claim is made from incomplete constraints.
- CTS, routing, and physical signoff were not attempted.

---

## 10. Failed and blocked stages

| Stage | Result | Reason |
|-------|--------|--------|
| Repository integrity | ✅ Passed | Read-only inspection only |
| Specification SHA-256 verification | ✅ Passed | Matched reported final hash |
| Table D inspection | ✅ Passed | Already corrected in live spec |
| Decision record preservation | ✅ Passed | PROPOSED, coverage intact |
| PDK/macros preflight | ✅ Passed | Views present and inspected |
| Generic synthesis (listed modules) | ✅ Passed | Completed with Yosys |
| Full-chip elaboration | ❌ Blocked | Interconnect unpacked-array port syntax error; no RTL change allowed |
| Technology-mapped synthesis — riscv_core | ❌ Blocked | Unsupported `$adff` async-reset sequential cells in DFFLEGALIZE in this Yosys build + Liberty not resolvable from Yosys this session |
| Technology-mapped synthesis — selected peripherals | ❌ Partial / Blocked | Some advanced to DFFLEGALIZE; all hit unsupported wide-cell failure |
| OpenROAD physical flow | ❌ Blocked | OpenROAD/OpenSTA not available on host or WSL |
| SRAM macro integration readiness | ✅ Passed (documented) | Inspected without wrapper RTL |

---

## 11. Evidence files produced (historical Phase 1) and Phase 1.1 evidence

Output locations (historical Phase 1):

- Build evidence: `build/asic_flow/phase1/`
- Reports evidence: `reports/evidence/asic_flow_phase1/`

Historical Phase 1 existing logs (predate this session):

- Generic synthesis logs: `build/asic_flow/phase1/generic_synthesis/*.log`
- Techmap logs: `build/asic_flow/phase1/techmap/*.log`
- Baseline report: `reports/ASIC_FLOW_PHASE1_BASELINE.md`
- Decision record: `reports/ASIC_MEMORY_WRAPPER_DECISION_RECORD.md`
- Spec file: `reports/ASIC_MEMORY_WRAPPER_ARCHITECTURE_SPEC.md`

No successful downstream artifact from the historical Phase 1 run (no OpenROAD output and no clean mapped netlist) was available to hash at that time.

Phase 1.1 evidence created in this session (separate from historical Phase 1 artifacts):

- Build evidence: `build/asic_flow/phase1_1/`
- Reports evidence: `reports/evidence/asic_flow_phase1_1/`
- Primary consolidated log: `build/asic_flow/phase1_1/techmap/riscv_core_tmap_investigation.log`
- Reproduction script: `build/asic_flow/phase1_1/scripts/technology_mapping_investigation.sh`
- Evidence index and hashes: `reports/evidence/asic_flow_phase1_1/index.log`, `reports/evidence/asic_flow_phase1_1/sha256sum.log`
- Tool versions: `reports/evidence/asic_flow_phase1_1/tool_versions.log`
- Reproduction commands: `reports/evidence/asic_flow_phase1_1/reproduce_commands.log`

Phase 1.1 produced investigation evidence and tool-version/reproduction artifacts, but did **not** produce a clean mapped netlist, so no Phase 1.1 mapped-netlist SHA-256 is reported. Phase 1.1 is documented as evidence closure and blocker investigation, not as a successful techmap result.

---

## 12. SHA-256 hashes of key repository documents

These hashes verify the documents actually inspected/written, not results of tool execution. Note: the specification hash appears once, labeled, and the decision record hash appears once, labeled.

- `reports/ASIC_MEMORY_WRAPPER_ARCHITECTURE_SPEC.md`: `8d7221f7e195a11ece2881f97a2d3cfeb4cb9b23677c4e9184060a01550d71b5` (specification under audit)
- `reports/ASIC_MEMORY_WRAPPER_DECISION_RECORD.md`: `55d3f5684d32f6b83768775d87a6c17999a2493233e197ec0646053771a0b6af` (decision record)
- `reports/ASIC_FLOW_PHASE1_BASELINE.md`: the final SHA-256 of this baseline report is recorded externally in `reports/evidence/asic_flow_phase1_1/final_report_sha256.txt`; it is not embedded in this document.

---

## 12.1. Phase 1.1 evidence summary (added by this session; separate from historical Phase 1)

Phase 1.1 closure added the following, without modifying production RTL, existing Phase 1 logs, or the tracked-diff hash above:

- Created `build/asic_flow/phase1_1/` and `reports/evidence/asic_flow_phase1_1/`.
- Generated the consolidated investigation log `build/asic_flow/phase1_1/techmap/riscv_core_tmap_investigation.log` containing:
  - Yosys 0.69+154 version.
  - `dfflegalize` and `abc` supported command syntax verification.
  - Liberty host-accessibility failure (Yosys `read_liberty` and `yosys-abc read_lib` could not open the Sky130HD TT liberty from the `/d/...` path in this session).
  - WSL tool-availability results (OpenROAD/STA not present; Magic/Netgen/KLayout wrappers present but broken; `python3` present).
  - The `riscv_core` frontend failure under isolated scratch scripts (`read_verilog -sv /d/Home-Automation-SoC/rtl/rtl_top/riscv_core.sv` failed with `ERROR: File '/d/Home-Automation-SoC/rtl/rtl_top/riscv_core.sv' not found or is a directory`).
  - Corrected-path re-runs of riscv_core sequential-mapping attempts (`step_c1`..`step_c4`) and the six missing peripherals (`clint`, `spi_ctrl`, `i2c_ctrl`, `pwm`, `i2s`, `qspi_flash_ctrl`).
- Recorded per-module evidence: each of the six peripherals created `$adff` cells during proc/techmap and then failed at DFF legalization with one unsupported async-reset sequential cell (`$_DFF_PN0_` or `$_DFF_PN1_`); `riscv_core` created 265 `$adff` cells and failed at DFF legalization on `riscv_core.$auto$ff.cc:337:slice$37771` (`$_DFF_PN0_`).
- Documented the blocker summary:
  - `$adff` present (proc-created async-reset FF) in riscv_core and all six peripherals.
  - `$adfe` not present.
  - `$adffe` not present in the corrected runs.
  - No wide-cell blocker evidence in these runs.
  - Liberty host accessibility BLOCKED for `read_liberty` in Yosys 0.69+154 this session.
  - ABC run condition not satisfied: cannot proceed without a valid mapped netlist and a resolvable Liberty.
- Wrote `reports/ASIC_FLOW_PHASE1_1_MAPPING_CLOSURE.md`.

Phase 1.1 classifications:

- GENERIC SYNTHESIS: PASS (predates Phase 1.1).
- SEQUENTIAL LEGALIZATION: BLOCKED for riscv_core and all six missing peripherals (failed at DFF legalization on `$adff`-type async-reset cells).
- TECHNOLOGY MAPPING: BLOCKED for riscv_core and all six missing peripherals (mapping did not reach a valid mapped netlist).
- ABC MAPPING: BLOCKED for riscv_core and all six missing peripherals (blocked upstream by sequential legalization failure and Liberty-host-access failure).
- OPENROAD PHYSICAL FLOW: BLOCKED until tools available.
- FULL-CHIP SYNTHESIS: BLOCKED until frontend issue resolved.

**End of Phase 1.1 evidence summary.**

---

## 13. Exact reproduction commands

### Repository integrity

```bash
cd /d/Home-Automation-SoC
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD
git status --short
git diff --stat
```

### Tracked diff hash

The tracked diff (worktree vs HEAD) can be reproduced and verified in two equivalent forms:

```bash
cd /d/Home-Automation-SoC
# SHA-1 git object hash of the tracked diff as a blob (quoted value in this report):
git diff HEAD > /tmp/tracked_diff_patch.txt && git hash-object -t blob /tmp/tracked_diff_patch.txt
# SHA-256 content hash of the same tracked-diff file:
sha256sum /tmp/tracked_diff_patch.txt
```

Expected values (verified):

- git blob hash: `0c4bd5d5c1378229735a71b3a28da5913481b306`
- SHA-256 content hash: `f0245fac670fd4a4920637f3f543e22b3266e658f1cfa16f993fb63bc097990d`

### Specification hash

```bash
cd /d/Home-Automation-SoC
sha256sum reports/ASIC_MEMORY_WRAPPER_ARCHITECTURE_SPEC.md
```

### Yosys generic synthesis (representative command)

```bash
cd /d/Home-Automation-SoC
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"
yosys.exe -s build/asic_flow/phase1/generic_synthesis/<module>.ys > build/asic_flow/phase1/generic_synthesis/<module>.log 2>&1
echo "exit=$?"
```

Replace `<module>.ys` with the actual module script in `build/asic_flow/phase1/generic_synthesis/`.

### Yosys techmap attempt (representative command, historical Phase 1)

```bash
cd /d/Home-Automation-SoC
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"
yosys.exe -s build/asic_flow/phase1/techmap/<module>.ys > build/asic_flow/phase1/techmap/<module>.log 2>&1
echo "exit=$?"
```

### Phase 1.1 technology-mapping investigation (reproduces the Phase 1.1 consolidated log)

```bash
cd /d/Home-Automation-SoC
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"
bash build/asic_flow/phase1_1/scripts/technology_mapping_investigation.sh
```

The script targets `build/asic_flow/phase1_1/techmap/riscv_core_tmap_investigation.log` and uses corrected RTL-path form (`D:/Home-Automation-SoC/...`) and correct peripheral source directory (`rtl/rtl_peripherals/`). It records Yosys version, Liberty path, per-step exit status, and the blocker evidence grep.

### Macro audit (representative inspection)

```bash
cd /d/Home-Automation-SoC
export ORFD="/d/rta-real-world-benchmark/02_projects/OpenROAD-flow-scripts"
SRA="$ORFD/flow/platforms/sky130ram/sky130_sram_1rw1r_128x256_8"
ls -la "$SRA"
grep -E "MACRO|SIZE|SYMMETRY" "$SRA/sky130_sram_1rw1r_128x256_8.lef" | head -6
grep -E "voltage_map|pg_pin" "$SRA/sky130_sram_1rw1r_128x256_8_TT_1p8V_25C.lib" | head
grep -nE "ADDR_WIDTH|NUM_WMASKS|DATA_WIDTH" "$SRA/sky130_sram_1rw1r_128x256_8.v" | head
```

### Tool presence checks

```bash
cd /d/Home-Automation-SoC
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"
for v in yosys yosys.exe yowasp-yosys yowasp-yosys.exe; do
  p=$(command -v "$v" 2>/dev/null)
  if [ -n "$p" ]; then "$p" --version 2>&1 | head -1; fi
done
```

---

## 14. Final ASIC readiness verdict

**Not ready. Documentation/planning only.**

- The decision record is corrected and PROPOSED.
- The specification is verified.
- The PDK and macro views are present.
- Generic synthesis completed.
- Technology mapping advanced for some logic-only blocks but is **blocked** by unsupported `$adff` async-reset sequential cells in this Yosys build; no clean mapped netlist is available for `riscv_core`.
- Phase 1.1 provided corrected evidence for the six previously-missing peripherals; their techmap is also **BLOCKED** at `$adff` DFF legalization, and the Liberty-host-access failure and Yosys RTL-path issue prevented a clean mapped netlist from this environment.
- OpenROAD and OpenSTA are **not available** on the current host or WSL environment, so physical-flow smoke testing is **blocked**.
- SRAM macro integration is documented, but no wrapper RTL exists.

No ASIC signoff or tapeout readiness is claimed.

---

## 15. Next steps before implementation

1. Resolve the OpenROAD/OpenSTA availability gap if physical-flow smoke testing is wanted.
2. Resolve the Yosys `$adff` async-reset sequential-cell mapping blocker for `riscv_core` and the six missing peripherals (or use a mapping flow supported by this Yosys build) before any downstream physical-flow use.
3. Resolve the Liberty-host-accessibility failure for Yosys `read_liberty`/`yosys-abc` on this host if Liberty-based mapping is required here.
4. Fix or workaround the top-level interconnect elaboration blocker only through approved RTL changes if full-chip synthesis is desired; no workaround was attempted here.
5. Obtain explicit approval before any wrapper RTL creation or production RTL modification.

**End of Phase 1 baseline.**
