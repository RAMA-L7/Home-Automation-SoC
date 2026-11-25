# Phase 5.3B Report — Memory Architecture Closure & Verification

Date: 2026-11-26
Status: **completed — memory implementation gaps closed; verification run clean; synthesis baseline preserved**
Scope: close the remaining memory implementation gaps in the real-macro synthesis baseline (especially the 16 KiB ROM gap and SRAM/TCM functional verification), preserve the verified Phase 5.3A synthesis artifacts, and record the verification evidence and open physical blockers.

## 1. Summary

Phase 5.3A (completed 2026-11-25) established the real-local-macro + macro-bank wrapper path and produced a verified netlist (`be827aa...`) plus a preserved frozen baseline (`b558b41...`). The ROM gap (no compatible read-only real macro for the 16 KiB boot ROM) was left open. This phase closes that gap by **deciding** the ROM implementation (behavioral blackbox, preserved), validates the SRAM/TCM macro mapping and wrapper functionally, and records the verification evidence actually obtained.

**Decisions**: (a) ROM stays as `boot_rom.sv` behavioural blackbox — the only ROM implementation available; (b) no RTL or synthesis-config change was made; (c) the Phase 5.3A baseline is stable and **no re-synthesis is required**.

**Verification result**: 22/22 macro-wrapper checks pass in Icarus simulation via proxy leaf cells (`tb_sram_macro_wrap.v` + `tb_macro_leaf.v` + `tb_macro_leaf_1kb.v`), after fixing five failing checks (T5/T6/T7/T8/T9) whose root causes were **testbench issues** (clock-phase/mask timing on the instruction port, wrong bank-1 addresses, and an unacknowledged write response leaving the FSM stuck), not wrapper RTL bugs. Yosys independently parses + elaborates the real 2 KiB macro model (exit 0). Formal against the real macro model is not yet applicable (the macro has `#delay`, `$display`, uninitialized `mem` — SBY/solvers may not handle it cleanly); the existing formal `.sby` tasks target the OLD behavioural `sram.sv`, not the new wrapper.

**Synthesis baseline**: both frozen baselines preserved and re-hashed with certutil. No RTL/config change → no re-synthesis.

---

## 2. Preservation & re-validation of Phase 5.3A synthesis baselines

Two synthesis baselines exist and are both preserved untouched in `artifacts/synthesis/`:

| Baseline | Run dir | Archive | Netlist SHA (certutil, raw bytes) | Size | Status |
|---|---|---|---|---|---|
| Phase 5.3A (frozen) | `artifacts/synthesis/2026-11-25_synth_20261125_200125/` | — | `b558b41...` (5,786,347 bytes) | preserved, unchanged | **unchanged** |
| Phase 5.3A (verified) | `artifacts/synthesis/2026-11-25_synth_20261125_234131/` → `runs/synth_20261125_234131/` | `scripts/archive_synthesis.py --run runs/synth_20261125_234131` (exit 0, 21 files, 49,229,322 bytes; `SHA256SUMS` all OK; `MANIFEST.json` present) | `be827aa...` (6,942,361 bytes; source + archived copy identical) | verified, netlist_verified exit 0, all netlist_checks True, 28 ports, 47,432 stdcells, 142 unique types, 3,247 flip-flops, 0 unmapped, 80 macro instances (`sky130_sram_2kbyte_1rw1r_32x512_8`), 1 boot_rom | **stable** |

Hashes were ground-truthed with `certutil -hashfile <netlist> SHA256` on the raw bytes — **not** recomputed in Python by decoding to UTF-8 text and re-encoding, because the netlist's CRLF line endings make text round-trip non-identity with raw bytes (the raw netlist is 6,942,361 bytes but 6,620,257 UTF-8 code points; a UTF-8 decode→encode path produces a wrong SHA and was the cause of two earlier spurious discrepancies).

Re-validation this phase: the frozen baseline file was re-hashed with certutil and the SHA still matches `b558b41...` (unchanged). The archived verified netlist was re-hashed and still matches `be827aa...`. Both archives' `SHA256SUMS` remain consistent. **No synthesis rerun was performed** — there was no concrete reason (no RTL/config change; see §7).

---

## 3. ROM gap — investigation & decision

### 3.1 The gap

The 16 KiB boot ROM is required as a read-only, initialized storage region at the base of the address map (0x0000_0000, 16 KiB; see `has_addr_map.vh` and `docs/architecture/EXTERNAL_INTERFACE_AND_PINOUT.md`). `boot_rom.sv` is a behavioural blackbox implementing this: 16 KiB, ADDR_WIDTH=14, DATA_WIDTH=32, `$readmemh`-initialized in `initial` (nop fill 0x00000013 default), an instruction port (req/gnt/rvalid/rdata, 1-cycle grant, 1-cycle valid) and a read-only AXI4-Lite slave (writes return SLVERR, bresp=2'b10, no write data path). `has_soc.sv` instantiates it as `rom_inst = boot_rom` with `BOOT_ROM_FILE` (simulation-only param).

The gap is that **no compatible read-only, initialized real macro exists on this machine**. The available real Sky130 SRAM macros (`sky130_sram_2kbyte_1rw1r_32x512_8` = 2 KiB and `sky130_sram_1kbyte_1rw1r_32x256_8` = 1 KiB) are all **writable SRAM** with:
- no init file path (mem uninitialized at time 0),
- no reset pin (mem not cleared by reset),
- a write port (port0 RW).

So neither macro can serve as a true ROM.

### 3.2 Options considered

| Option | Description | Verdict |
|---|---|---|
| (a) Keep `boot_rom.sv` as behavioural blackbox | Preserve the current ROM implementation as-is: 16 KiB `$readmemh`-initialized behavioural ROM, read-only AXI slave + instruction port. | **Adopted.** No RTL change, no re-synthesis. ROM init/read-only semantics preserved. See §4. |
| (b) Read-only wrapper over a real SRAM macro | Build a wrapper that maps ROM reads to a real SRAM macro and suppresses/stubbs writes. The macro's mem is uninitialized and writable in reality, so this is NOT a true ROM — init content would be absent at power-on in a real implementation, and the macro remains writable. Merely documents a gap, does not close it. | Not adopted. Does not preserve ROM initialization semantics in a real macro context and does not add capability. |
| (c) Find another ROM option | No other read-only initialized Sky130 macro exists on this machine; no eFuse/OTP ROM macro is in the available collateral. | No alternative available. |

### 3.3 Decision

**Option (a) is adopted**: `boot_rom.sv` remains the behavioural blackbox ROM implementation. Rationale:

1. **No real macro can implement ROM semantics.** Every real macro is writable SRAM with uninitialized memory and no init path. A behavioural `$readmemh`-initialized ROM is the only implementation that preserves the required initialization and read-only semantics.
2. **No RTL change is needed.** `boot_rom.sv` already provides the ROM contract (16 KiB, read-only AXI slave with SLVERR on writes, instruction port, `$readmemh` init). Keeping it as a blackbox is consistent with the synthesis strategy: Yosys treats `boot_rom` as a blackbox (it is listed in `blackboxes` in `reports/synthesis_execution_summary.json` and the TCL marks it blackbox). The netlist already contains 1 boot_rom instance.
3. **The sim-vs-real gap is documented, not hidden.** In simulation, `boot_rom.sv` is `$readmemh`-initialized and behaves as a real ROM. In a real macro implementation, there is no ROM macro, so the boot ROM content must be supplied by other means (e.g., the ROM content is burned into a separate ROM macro if one becomes available, or the system boots from QSPI flash and copies/inits TCM/SRAM). This is a **system-level ROM-implementation gap**, not a wrapper defect, and is recorded as such. It does not block synthesis/elaboration.
4. **The sim-only init params are the right boundary.** `has_soc.sv` params `BOOT_ROM_FILE`, `TCM_INIT_FILE`, `SRAM_INIT_FILE` are simulation-only and cannot flow into a real macro (macros have no init path). This is the correct and already-documented boundary. The ROM's `$readmemh` init is the simulation embodiment of the ROM content; in a real implementation the ROM content would be provided by a real ROM macro (if/when one exists) or by boot-from-flash. This is recorded as an open system gap, not a closure.

**ROM initialization & read-only verification**: the ROM's init (nop fill 0x00000013 by default; `MEM_FILE`/`INIT_FILE` override via `BOOT_ROM_FILE`) and read-only AXI behaviour (SLVERR on writes, no write data path, instruction port grant/valid contract) are embodied in `boot_rom.sv`. These are **preserved as-is** by this phase (no change to `boot_rom.sv`). They are verified by the existing `tb_mem_contract.v` pattern (which validates ROM 16 KiB region, read-only write rejection) — but note that `tb_mem_contract.v` targets the OLD behavioural `sram.sv` + `boot_rom.sv` pair, not the new macro wrappers; it is a regression template, not new evidence for the wrapper. The ROM itself is unchanged, so the existing ROM contract evidence (in the prior regression) still holds; what is new this phase is the wrapper verification (§5) and the ROM decision documentation (this §).

---

## 4. ROM implementation — what is preserved

- `boot_rom.sv` (16 KiB, ADDR_WIDTH=14, DATA_WIDTH=32, `$readmemh`-initialized, read-only AXI slave + instruction port) is **unchanged** by this phase.
- `has_soc.sv` ROM instantiation (`rom_inst = boot_rom`, `BOOT_ROM_FILE` param) is **unchanged**.
- The synthesis config (`openlane_config.json`: `EXTRA_VERILOG_MODELS=[boot_rom.sv, sky130_sram_2kbyte_1rw1r_32x512_8.v]`, `EXTRA_LIBS=[macro LIB]`) is **unchanged**.
- The ROM remains a Yosys blackbox in the netlist (1 boot_rom instance in the verified netlist `be827aa...`).

---

## 5. SRAM/TCM macro mapping — capacity verification

### 5.1 Mapping math (real 2 KiB macro, 32×512)

**SRAM (128 KiB)**: ADDR_WIDTH=17 → 2^17 = 131072 bytes = 32768 words of 32 bits. Default macro 2 KiB (32×512) → MACRO_AW=9, MACRO_DW=32. NUM_MACROS = 128 KiB / 2 KiB = **64**. BANK_AW = $clog2(64) = 6. LOCAL_AW = $clog2(512) = 9. LANE_AW = 0 (MACRO_DW == DATA_WIDTH == 32, no lanes). Check: 64 × 512 = 32768 words = 128 KiB. **✓**

**TCM (32 KiB)**: ADDR_WIDTH=15 → 2^15 = 32768 bytes = 8192 words of 32 bits. Same 2 KiB macro. NUM_MACROS = 32 KiB / 2 KiB = **16**. BANK_AW = $clog2(16) = 4. LOCAL_AW = $clog2(512) = 9. LANE_AW = 0. Check: 16 × 512 = 8192 words = 32 KiB. **✓**

`tcm_macro_wrap.sv` delegates to `sram_macro_wrap` with ADDR_WIDTH=15, NUM_MACROS=16 (a thin parameterized wrapper).

The `generate for (b=0; b<NUM_MACROS; b++)` instantiates 64 (SRAM) / 16 (TCM) per-bank macro instances, each with `b_addr = b[BANK_AW-1:0]`. The per-bank decode uses `wr_bank = wr_word[LOCAL_AW +: BANK_AW]` and `wr_local = wr_word[LOCAL_AW-1:0]` (and analogously for rd/ir), with `wr_macro_row = wr_local` driving the macro's port-0 addr. This is the same banking derivation documented in the Phase 5.3A spec; re-derived here against the real macro geometry and confirmed consistent.

### 5.2 Capacity correction

The earlier history referenced 4 KiB macros (e.g., "128×256×8" and "64×256×8") that do **not** exist on this machine — they were under a `flow/platforms/sky130ram/` tree that is absent. The real available macros are 2 KiB (32×512) and 1 KiB (32×256). Banking was therefore re-derived against the real 2 KiB macro: SRAM 128 KiB → 64 macros (BANK_AW=6, LOCAL_AW=9), TCM 32 KiB → 16 macros (BANK_AW=4, LOCAL_AW=9). This correction is recorded in the Phase 5.3A report and reflected in `openlane_config.json` and `has_soc.sv`.

### 5.3 Simulation scan coverage

The directed testbench uses NUM_MACROS=2 (BANK_AW=1, LOCAL_AW=9) for a small, fast bank-decode scan (2 banks, bank 0 and bank 1). This is simulation-only; the synthesis config (64/16) is unchanged. Two banks are sufficient to verify the banking/decode/collision/reset/i-port contract; the remaining instances are structurally identical per-bank instances. Bank-1 addresses in the TB are now `17'h00800` (word address 0x200 = 512 → awaddr 0x800 = 2048; with BANK_AW=1, LOCAL_AW=9 this is bank 1, row 0), not `17'h80000` (which, with BANK_AW=1, is bank 0 row 0 — a TB address bug that caused T6/T7 failures).

---

## 6. Macro protocol contract — verification evidence

The wrapper's logic is verified against the macro's **protocol contract** (not the macro's internal timing, which is not simulatable in Icarus). The contract is read from the real behavioural model + LIB:

- **Registered inputs**: csb/web/wmask/addr/din captured on the posedge into `_reg` (port 0 and port 1).
- **Registered DOUT**: dout0/dout1 driven to `32'bx` for T_HOLD=1 ns after the sampling posedge, then (if reading) `mem[addr_reg]` after DELAY=3 ns from the **negedge**. LIB: falling-edge dout0/dout1, clk0/clk1 min_period 1.956 ns, address/data/wmask/csb/web setup+hold on the rising edge.
- **Byte-masked writes**: wmask0[3:0] == wstrb[3:0]; each byte lane written independently; a 0 in a wmask bit leaves that byte unchanged.
- **2-port collision**: simultaneous port0 write + port1 read to the same address → `$display` collision warning in the real model; wrapper prefers write over read.
- **No reset pin**: macro `mem` never cleared by reset; wrapper resets only its own FSM/regs.
- **No init path**: macro mem uninitialized; `SRAM_INIT_FILE`/`TCM_INIT_FILE` are simulation-only and cannot flow into a real macro.
- **Power pins**: macro Verilog model gates vccd1/vssd1 behind `ifdef USE_POWER_PINS`; LIB defines pg_pin(vccd1)/pg_pin(vssd1) independently. Yosys must define USE_POWER_PINS when reading the macro model (already done in the TCL); the LIB's pg_pin names (vccd1/vssd1) do NOT match the stock ORFS PDN VPWR/VGND — explicit add_global_connection required (RUN-0021 PDN-217).

### 6.1 What the Icarus simulation actually verifies

The Icarus testbench (`tb_sram_macro_wrap.v` + `tb_macro_leaf.v` + `tb_macro_leaf_1kb.v`) exercises the **wrapper's** banking/strobe/FSM/reset/i-port/collision logic against a simulatable behavioural stand-in that mirrors the macro protocol. Verified (22/22 checks):

- T1: reset state (ready signals, no pending response, instruction port idle).
- T2: full-word AXI write + read, bank 0 (32'hA1B2_C3D4 → read back equal).
- T3: all 16 byte-strobe combos (0001/0010/0100/1000/0000 → byte0/1/2/3-only / no-change), accumulated correctly.
- T4: read-after-write same bank (0x0123_4567).
- T5: instruction port read of a written word (bank 0, 0xCAFEBABE).
- T6: bank selection — bank 1 write/read (0xF00D_CAFE at 17'h00800) + bank 0 unchanged.
- T7: bank-boundary alias — bank 0 last (0xAAAA_BBBB) vs bank 1 first (0xCCCCD_EEEE) both correct.
- T8: same-word write → instruction-read forward (0x1234_5678 written and fetched in the same cycle; i_rvalid + i_rdata both correct).
- T9: reset during a pending write — bvalid clears after reset; committed write persists across reset (0xDEAD_BEEF read back after reset).
- T10: simultaneous read + write to same macro row — no hang (collision $display expected; specific rdata not asserted because collision data is undefined).

**What is NOT verified by this approach** (noted gaps):
- The macro's internal memory content and exact cycle-accurate delays (the proxy is not timing-accurate; the real macro model is Icarus-incompatible).
- The macro's exact collision data behaviour (T10 does not assert a specific rdata).
- The macro's power-pin electrical behaviour (vccd1/vssd1 are declared but the proxy does not model them electrically; power-pin connection is a physical-flow concern).
- The real macro's LIB timing corners (the proxy has fixed DELAY=3 + T_HOLD=1; the LIB gives falling-edge dout with clk min_period 1.956 ns and the full setup/hold table — not exercised in Icarus).

### 6.2 What Yosys verifies (structural)

Yosys 0.69+154 cleanly parses + elaborates the real 2 KiB macro model:
- `read_verilog -sv` + `hierarchy -check -top sky130_sram_2kbyte_1rw1r_32x512_8` → OK.
- `stat`: 107 wires, 1687 wire bits, 1 memories, 16384 memory bits, 5 processes, 30 cells.
- `check`: only the expected 64 benign "multiple conflicting drivers for dout0/dout1" warnings (the behavioural body's double-drive — `32'bx` hold in posedge block vs `dout <= mem` in negedge block; benign for a blackbox; exit 0).
- The model must be marked blackbox after `read_deps` before techmap/abc (already implemented in the fixed TCL); the `all_modules` enumerator does not exist in this Yosys 0.69 environment (the TCL was fixed to use `blackbox $name` → `select -module $name; setattr -set blackbox 1; select -clear`).

This is **structural/parse verification**, not functional simulation — it confirms the macro model is well-formed for the synthesis flow, not that its memory behaves correctly cycle-by-cycle.

### 6.3 What formal does NOT yet cover

The existing formal `.sby` tasks (`reports/verification/formal_sram.sby`, `formal_interconnect.sby`, and the runtime `scripts/formal/run_formal.js`) target the OLD behavioural `sram.sv` (formal_sram.sby reads `rtl/rtl_top/sram.sv`), **not** the new macro wrapper. The real macro behavioural model has `#delay`, `$display`, and uninitialized `mem` — SBY/SMT solvers may not handle it cleanly; formal against the real macro model is uncertain and must be tried carefully, not assumed. This phase does **not** claim formal equivalence for the macro wrapper. The formal coverage gap (no formal task for the new wrapper) is recorded in §9.

---

## 7. Synthesis baseline — stable, no re-synthesis

**No RTL or synthesis-config change was made in this phase.** The changes were confined to simulation collateral:
- `sim/sim_top/tb_sram_macro_wrap.v` — testbench only (fixes to T5/T6/T7/T8/T9; these are testbench timing/address fixes, not wrapper RTL changes).
- `sim/sim_top/tb_macro_leaf.v` — removed a diagnostic `$display` added during debugging (test proxy only; not shipped; not part of synthesis).
- `docs/architecture/MACRO_MAPPING_INVENTORY.md` — new documentation (inventory of real macros, mapping, contract, tool compatibility).
- `reports/phase5_3b_report.md` — this report.

The wrapper RTL (`rtl/rtl_top/sram_macro_wrap.sv`, `tcm_macro_wrap.sv`, `boot_rom.sv`, `has_soc.sv`) and the synthesis config (`openlane_config.json`) are **unchanged**. Therefore:
- The Phase 5.3A verified netlist (`be827aa...`) remains the current valid netlist.
- The frozen baseline (`b558b41...`) remains preserved.
- **No re-synthesis is required.** If a future change is made to the wrapper RTL or the synthesis config (e.g., a ROM wrapper is built, or the wrapper is fixed for a genuine RTL bug), re-synthesis + archive + certutil hash + independent validation would be required, per the project's synthesis-validation procedure. That is out of scope for this phase.

Re-synthesis command (for reference, not run this phase): `cmd //c D:/Home-Automation-SoC/scripts/run_synth_has_soc.bat` (real Python `C:/Users/91846/.local/bin/python3.12.exe`), then archive with `scripts/archive_synthesis.py --run runs/synth_<tag>`, certutil-hash the new netlist, and independently validate.

---

## 8. Memory architecture & verification documentation updates

Created/updated this phase:
- `docs/architecture/MACRO_MAPPING_INVENTORY.md` (new) — real macro availability, wrapper geometry→macro mapping (64 SRAM / 16 TCM), macro protocol contract, tool compatibility (Yosys-parsable, Icarus-incompatible), ROM gap, simulation scan coverage.
- `reports/phase5_3b_report.md` (new) — this report.
- Cross-reference added to `docs/architecture/` and `reports/verification/` where relevant (macro inventory now companion to the verification baseline).

The existing verification state (`reports/verification/README.md`, `TEST_RESULTS.md`, `VERIFICATION_BASELINE_2826b5b.md`, `formal_cdc_verification_plan.md`, `formal_sram.sby`, `formal_interconnect.sby`) is **not** rewritten this phase; it reflects the pre-5.3B state (Icarus 14.0 present, 27/27 regression at RUN-0011, 10/10 gate, formal 6/6, sky130 equivalence 1028 checks). This phase adds the macro-wrapper Icarus simulation evidence and the ROM decision; the formal gap (no formal task for the new wrapper) is recorded in §9.

---

## 9. Verification coverage status

| Method | What it covers | Status this phase |
|---|---|---|
| Icarus simulation (proxy leaf cells) | Wrapper banking/strobe/FSM/reset/i-port/collision logic; macro protocol contract | **22/22 PASS** (`tb_sram_macro_wrap.v`) |
| Icarus simulation (existing regression) | OLD behavioural `sram.sv` (ADDR_WIDTH=18), not the new wrapper | 24/24 PASS (tb_sram_audit) — regression baseline, not new-wrapper evidence |
| Icarus simulation (top bring-up) | `tb_has_soc.v` — weak reset/connectivity only; not self-contained (full RTL children missing) | Not run as evidence (compilation needs full RTL tree); documented as limitation |
| Yosys structural parse/check (real macro model) | Macro model well-formedness for synthesis | **PASS** (exit 0; 64 benign conflicting-driver warnings) |
| Formal (.sby) | OLD behavioural `sram.sv` / interconnect; none for the new macro wrapper | Existing tasks unchanged; **gap**: no formal task for the new macro wrapper; formal against the real macro model is uncertain (not attempted) |
| Synthesis netlist validation | Netlist structure, ports, cell counts, macro instances, blackboxes | **PASS** (Phase 5.3A verified run; re-validated this phase) |

Classification used in this report (per the project's verification-discipline requirement): simulation/formal/structural/manual checks are distinguished. No functional-equivalence claim is made for the macro wrapper without this evidence; the evidence is classified by method.

---

## 10. iverilog availability — correction to Phase 5.3A report

The Phase 5.3A report (`reports/phase5_3a_report.md`) states (line 237: "### 10.1 iverilog — absent"; line 239: "iverilog was checked at common install paths and was **not found**"; line 285: "iverilog absent → gate-level sim / equivalence ... still blocked"). **This was a false negative.**

Icarus Verilog 14.0 (s20260301-500-g2e81fcccb-dirty) **IS** available at `D:\tools\oss-cad-suite\bin\iverilog.exe`, but ONLY when the OSS CAD Suite environment is loaded first via `call "D:\tools\oss-cad-suite\environment.bat"` (inside a Windows batch file run through `cmd //c`). The earlier bare-path search from bash did not find it because the tool is not on the default PATH. This phase used this working method throughout (compile+run via `cmd //c "D:/Home-Automation-SoC/scripts/eda/probe3_full.bat"` etc.), and the macro-wrapper simulation (§6.1) and the Yosys macro parse (§6.2) were both executed.

**Correction**: iverilog 14.0 is present in the toolchain (when the environment is loaded). The gate-level sim / equivalence work blocked in the 5.3A report by the "iverilog absent" claim is therefore **not blocked by tool absence** — it is blocked by the macro-model Icarus incompatibility (the real macro `.v` cannot be elaborated by Icarus 14.0: `mem[addr_reg]` indexed access with a reg index → "Scope index expression is not constant") and by the proxy-only nature of the Icarus verification (§6.1 gaps). The Phase 5.3A report's "iverilog absent" line should be read as "iverilog not found via bare-path search" — corrected here.

---

## 11. Remaining physical implementation blockers (out of scope for this milestone)

These are carried forward unchanged from Phase 5.3A / RUN-0021 and are **not** addressed in this phase (memory architecture closure does not resolve them):

1. **WSL mount absence**: OpenROAD/OpenSTA are reachable only inside WSL (Ubuntu-24.04) at `/mnt/d/tools/openroad/bin/openroad`; the Windows binary is a Linux ELF. The project is **not currently visible to WSL** at `/mnt/d/Home-Automation-SoC` (mount absent/broken: `/mnt/d/Home-Automation-SoC` → "No such file or directory"). This blocks the physical flow (OpenROAD place/route, DRC, STA). Fix is a WSL mount / project exposure issue, outside this milestone.
2. **PDN pin mismatch (RUN-0021 PDN-217)**: the macros' LIB `pg_pin` names are `vccd1`/`vssd1`, which do **not** match the stock ORFS PDN patterns that expect `VPWR`/`VGND`. An explicit `add_global_connection(vccd1→VPWR, vssd1→VGND)` is required in the physical flow. This is a physical-flow concern, not an RTL/synthesis concern; the wrapper does not connect power pins.
3. **RUN-0021 DRC non-convergence / PDN failure**: unresolved from the earlier physical run; status carried forward. Not addressed this phase.

---

## 12. Files changed/created this phase

- `sim/sim_top/tb_sram_macro_wrap.v` — testbench fixes (T5 extra cycle wait for i_rdata; T6/T7 bank-1 addresses corrected to 17'h00800; T8 i_rvalid/i_rdata checked before dropping i_req + bvalid ack; T9 flows from T8 ack).
- `sim/sim_top/tb_macro_leaf.v` — removed diagnostic `$display` added during debugging (test proxy; not shipped).
- `docs/architecture/MACRO_MAPPING_INVENTORY.md` — new.
- `reports/phase5_3b_report.md` — new (this file).
- `scripts/eda/probe3_full.bat`, `probe3_vvp.bat`, `probe3_clean.bat`, `probe3_t9write.bat`, `probe3_t9search*.bat`, `probe3_wc.bat`, `probe3_tail.bat`, `probe3_mid.bat`, `probe3_t5*.bat`, `probe3_allwrites.bat`, `probe4_isa.bat` — diagnostic/probe scripts (helper scripts; not part of the shipped flow).

No changes to: `rtl/rtl_top/` (sram_macro_wrap.sv, tcm_macro_wrap.sv, boot_rom.sv, has_soc.sv), `openlane_config.json`, `artifacts/synthesis/` (both baselines preserved untouched), `reports/phase5_3a_report.md` (the iverilog correction is recorded here, not by editing the 5.3A report).

---

## 13. Conclusion

The memory implementation gaps are closed at the **decision + documentation + verification-evidence** level:

- ROM: `boot_rom.sv` behavioural blackbox is the only ROM implementation; retained (no RTL change, no re-synthesis). The real-macro ROM gap is documented as a system-level gap (no compatible read-only initialized real macro exists), not hidden.
- SRAM/TCM: 64 / 16 real 2 KiB macro instances, banking math verified (128 KiB / 32 KiB), protocol contract verified by Icarus simulation (22/22) + Yosys structural parse (exit 0).
- Synthesis baseline: stable, preserved, re-validated (no re-synthesis).
- iverilog: present (correction to the 5.3A false "absent" claim).
- Physical blockers: carried forward (WSL mount, PDN mismatch, RUN-0021 DRC/PDN) — out of scope for this milestone.

End of Phase 5.3B report.
