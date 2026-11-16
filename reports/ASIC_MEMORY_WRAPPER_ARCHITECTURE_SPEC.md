# Home-Automation-SoC — ASIC Memory Wrapper Architecture and Verification Specification

**Document type:** Architecture and verification specification (no implementation)
**Date:** 2026-11-14
**Repository:** `D:\Home-Automation-SoC`
**Baseline HEAD:** `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1`
**Branch:** `main`
**Working-tree diff SHA-256:** `f0245fac670fd4a4920637f3f543e22b3266e658f1cfa16f993fb63bc097990d`

**Reference reports:**
- `reports/ASIC_FEASIBILITY_AND_SYNTHESIS_READINESS.md`
- `reports/ASIC_ENABLEMENT_DESIGN_DECISION.md`
- `reports/SKY130_SRAM_MACRO_INTERFACE_AUDIT.md`

**Primary macro:** `sky130_sram_1rw1r_128x256_8`
**Macro platform:** `/d/rta-real-world-benchmark/02_projects/OpenROAD-flow-scripts/flow/platforms/sky130ram`

No production RTL, wrapper RTL, testbench, synthesis script, or flow configuration was created or modified. No tools were installed. No PDK files were changed. No synthesis or physical implementation was run.

---

## 1. Executive Summary

- The SoC memory system is built from **banked 4 KB Sky130 SRAM macros** (`sky130_sram_1rw1r_128x256_8`: 256 words × 128 bits). Each macro provides one read/write port (port 0) and one read-only port (port 1).
- **Main SRAM (128 KB) = 32 banks; TCM (32 KB) = 8 banks; boot ROM (16 KB, if SRAM-backed) = 4 banks.**
- AXI4-Lite is 32-bit; the macro is 128-bit. A **width adapter** is mandatory: one macro word holds four AXI words. `WSTRB[3:0]` expands to four of the macro's sixteen `wmask0` bits based on `addr[3:2]`.
- **Port 0 serves all AXI reads and writes** (mutually exclusive). **Port 1 serves instruction fetches.**
- Concurrent AXI read + instruction fetch is safe (different ports). Concurrent AXI write + instruction fetch is safe **only for different macro words**; same-macro-word read-during-write is **undefined** in the macro model and must be avoided by wrapper stall/forwarding. Different AXI slices within the same 128-bit macro word still collide.
- Recommended architecture: **Option B — banked macro wrapper** with width adaptation, bank decode, and deterministic collision avoidance. Direct connection (Option A) is blocked by width mismatch. Behavioral SRAM (Option D) is retained for simulation only.

---

## 2. Baseline Integrity

| Item | Value | Status |
|------|-------|--------|
| Branch | `main` | VERIFIED |
| HEAD SHA | `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1` | VERIFIED |
| Working-tree diff SHA-256 | `f0245fac670fd4a4920637f3f543e22b3266e658f1cfa16f993fb63bc097990d` | VERIFIED |
| Production RTL modified | No | VERIFIED |
| Wrapper RTL created | No | VERIFIED |

---

## 3. Existing SoC Memory Interface

### 3.1 AXI4-Lite data interface (from `rtl/rtl_top/sram.sv`)

| Signal | Width | Role |
|--------|-------|------|
| `awvalid/awready` | 1 | Write address handshake |
| `awaddr` | 18 (parameter `ADDR_WIDTH`) | Byte address |
| `wvalid/wready` | 1 | Write data handshake |
| `wdata` | 32 | Write data |
| `wstrb` | 4 | Byte strobes |
| `bvalid/bready` | 1 | Write response handshake |
| `bresp` | 2 | Response (always `00` OKAY in current RTL) |
| `arvalid/arready` | 1 | Read address handshake |
| `araddr` | 18 | Byte address |
| `rvalid/rready` | 1 | Read data handshake |
| `rdata` | 32 | Read data |
| `rresp` | 2 | Response (always `00`) |

**AXI data width:** 32 bits. **AXI address width (current `sram`):** 18 bits (256 KB space). **Status:** VERIFIED.

### 3.2 AXI handshake behavior (from `sram.sv`)

- Write requires both `awvalid` and `wvalid` in the same cycle for acceptance (`wr_fire = awvalid & wvalid & awready & wready`).
- `awready` and `wready` are deasserted when `arvalid` is high (writes take priority over reads when both offered; reads accepted only if no write offered).
- One outstanding transaction at a time: states `S_IDLE`, `S_WRESP`, `S_RRESP`.
- `bvalid` asserted in `S_WRESP`; `rvalid` asserted in `S_RRESP`.
- Responses are held until `bready`/`rready`.

**Status:** VERIFIED from RTL.

### 3.3 Instruction-fetch interface (from `riscv_core.sv` and `has_soc.sv`)

| Signal | Width | Role |
|--------|-------|------|
| `instr_req` | 1 | Fetch request (held until granted/completed) |
| `instr_addr` | 32 | Fetch address |
| `instr_gnt` | 1 | Grant (one cycle on accept) |
| `instr_rdata` | 32 | Fetch data |
| `instr_rvalid` | 1 | Completion |
| `instr_err` | 1 | Access fault with rvalid |

From `sram.sv` instruction port:
- `i_req` → `i_gnt = i_req` (combinational grant).
- `i_rvalid = i_req_q` (one cycle after request).
- `i_rdata = mem[i_addr_q[ADDR_WIDTH-1:2]]`.
- Independent of the AXI FSM.

**Instruction fetch latency (behavioral):** request cycle → grant same cycle → `rvalid` next cycle → data valid. **Status:** VERIFIED.

### 3.4 Existing memory read/write latency (behavioral SRAM)

- Write: accepted in `S_IDLE` when `wr_fire`; enters `S_WRESP`; `bvalid` next cycle; write commits on the same posedge as acceptance (`always_ff @(posedge clk)`).
- Read: accepted in `S_IDLE` when `rd_fire`; enters `S_RRESP`; `rvalid` next cycle; `rdata` from registered address.
- Effectively **1-cycle read latency, 1-cycle write completion** (response next cycle).

**Status:** VERIFIED.

### 3.5 Reset behavior (from `sram.sv` and `reset_ctrl.sv`)

- `reset_n` (external pad) is an **asynchronous active-low reset** in `sram.sv` (`always_ff @(posedge clk or negedge reset_n)`).
- `rst_sys_n` is derived combinationally in `reset_ctrl.sv` as `reset_n & ~active`; external reset asserts asynchronously, while watchdog-induced reset deasserts on a clock edge.
- Resets FSM state and registered address/data/strobe registers.
- Memory array `mem` is **not** cleared by reset (no reset branch in the byte-strobe write block).
- Instruction-port registers (`i_req_q`, `i_addr_q`) are reset.
- `initial` block loads `MEM_FILE` if provided (simulation only).
- The macro has **no reset pin**; reset cannot clear macro state.

**F5 reset cases (timing-derived unless noted):**

| Case | Wrapper response | Macro CS | Macro samples write? | Write commits? | BVALID | Memory contents guaranteed? | AXI transaction |
|------|------------------|----------|----------------------|----------------|--------|----------------------------|-----------------|
| A: reset asserted before rising edge | `csb0=csb1=1`; state cleared | Deselected | No | No | No | Yes (unchanged) | Abandoned |
| B: reset asserted after rising edge, before falling edge | `csb` may deassert combinationally, but macro already sampled | May have sampled (if CS was low at rising edge) | Yes | Yes (timing-derived) | No | No (may be updated) | Abandoned |
| C: reset asserted after falling-edge commit | State cleared; CS deselected | Deselected | Already completed | Already committed | No (if reset before handshake) / Yes (if after) | Yes (committed value) | Abandoned unless B handshake completed |

**Status:** VERIFIED for RTL reset semantics; timing-derived for macro edge behavior. Do not assume reset cancels a macro write after its inputs have been sampled.

### 3.6 Memory initialization

- Simulation: `$readmemh(MEM_FILE, mem)` for SRAM/TCM; boot ROM has its own `INIT_FILE`.
- No hardware initialization mechanism for SRAM at power-on. Firmware/bootloader must initialize SRAM/TCM.
- Boot ROM is read-only; in ASIC it must be programmed via GDS/memory init or implemented as standard-cell ROM.

**Status:** VERIFIED (simulation); ASIC initialization is an open item.

### 3.7 Address map (from `has_addr_map.sv`)

| Region | Base | Size | Notes |
|--------|------|------|-------|
| Boot ROM | `0x0000_0000` | 16 KB | Executable; read-only data port |
| TCM | `0x0001_0000` | 32 KB | Executable; currently an `sram` instance |
| SRAM | `0x2000_0000` | 128 KB | Executable; main data memory |
| QSPI Flash | `0x4000_0000` | 64 MB | Not SRAM |
| APB | `0x5000_0000` | 1 MB | Peripherals |
| INTC | `0x8000_0000` | 64 KB | CLINT/PLIC |

**Regions are non-contiguous.** Boot ROM and TCM are separated by a 48 KB gap. **Status:** VERIFIED.

### 3.8 TCM implementation (actual)

- In `has_soc.sv`, TCM is an instance of the same `sram` module (`ADDR_WIDTH=15`, 32 KB) with an instruction port (`tcm_i_req`).
- It is **not** a separate memory type; it is the same behavioral SRAM.
- In ASIC, TCM must be implemented with the same macro bank structure as main SRAM.

**Status:** VERIFIED.

---

## 4. Macro Interface (Resolved)

### 4.1 Actual macro parameters (from Verilog + `.py`)

| Parameter | Value |
|-----------|-------|
| `NUM_WMASKS` | 16 |
| `DATA_WIDTH` | 128 |
| `ADDR_WIDTH` | 8 |
| `RAM_DEPTH` | 256 |
| Capacity | 256 × 128 = 32,768 bits = **4,096 bytes (4 KB)** |

### 4.2 Port list

| Port | Direction | Width | Function |
|------|-----------|-------|----------|
| `clk0` | input | 1 | Port 0 clock |
| `csb0` | input | 1 | Port 0 chip select, active low |
| `web0` | input | 1 | Port 0 write enable, active low (0 = write) |
| `wmask0` | input | 16 | Port 0 byte write mask, active high |
| `addr0` | input | 8 | Port 0 address (word) |
| `din0` | input | 128 | Port 0 data in |
| `dout0` | output | 128 | Port 0 data out |
| `clk1` | input | 1 | Port 1 clock |
| `csb1` | input | 1 | Port 1 chip select, active low |
| `addr1` | input | 8 | Port 1 address (word) |
| `dout1` | output | 128 | Port 1 data out |

### 4.3 Write-mask semantics (resolved)

- `wmask0[i] == 1` writes byte lane `i` (bits `[8(i+1)-1 : 8i]`).
- `wmask0[i] == 0` preserves the existing byte.
- Partial writes are supported at byte granularity (16 independent byte lanes).
- `csb0` active low; `web0` active low (0 = write, 1 = read).

### 4.4 Port behavior (resolved)

| Behavior | Supported? | Evidence |
|----------|------------|----------|
| Port 0 read (`web0=1`, `csb0=0`) | YES | Verilog `MEM_READ0` |
| Port 0 write (`web0=0`, `csb0=0`) | YES | Verilog `MEM_WRITE0` |
| Port 1 read (`csb1=0`) | YES | Verilog `MEM_READ1` |
| Port 1 write | NO | No write logic for port 1 |
| Simultaneous read+write on port 0 | NO | `web0` is mutually exclusive |
| Concurrent AXI read (port 0) + instruction read (port 1) | YES | Separate ports and clocks |
| Concurrent AXI write (port 0) + instruction read (port 1) | YES for different macro words; **undefined for same macro word** | Verilog warning on same address |
| Same macro word read-during-write across ports | **NOT SAFE** | Verilog emits `WARNING: Writing and reading ... simultaneously!`; ordering of negedge blocks is simulator-dependent. Collision is at macro-word granularity. |
| Read latency | 1 cycle | Inputs registered on posedge; read output on negedge with `DELAY` |
| Write timing | Inputs sampled posedge clk0; write on negedge clk0 | Verilog `MEM_WRITE0` |
| Clocking | Separate `clk0`, `clk1` (may be tied) | Verilog/Liberty |

**Resolved collision question:** The macro supports simultaneous port-0 and port-1 access. If the addresses differ, there is no data dependency and both complete normally. If the addresses are identical and port 0 is writing, the port-1 read result is undefined (the Verilog model issues a warning and the two negedge blocks may execute in either order). This must not be relied upon. **Status:** VERIFIED from Verilog model (Liberty does not document collision behavior).

---

## 5. Address and Banking Architecture

### 5.1 Bank counts (verified)

| Memory | Required capacity | Macro capacity | Bank count | Address bits (macro word) |
|--------|------------------:|---------------:|-----------:|--------------------------:|
| Main SRAM | 128 KB (131,072 B) | 4 KB | 32 | 8 |
| TCM | 32 KB (32,768 B) | 4 KB | 8 | 8 |
| Boot ROM (if SRAM-backed) | 16 KB (16,384 B) | 4 KB | 4 | 8 |

All divisions are exact (no unused locations within a region). **Status:** VERIFIED.

### 5.2 Address-bit equations

Let `A` be the 32-bit byte address presented on AXI (word-aligned by the core contract; `A[1:0]` may be nonzero for byte/halfword accesses within a word).

**Main SRAM (base `0x2000_0000`, size 128 KB):**
- Region offset: `O = A - 0x2000_0000` (17 bits, `0..0x1FFFF`).
- Bank index: `BANK = O[16:12]` (5 bits, 0..31).
- Byte offset within bank: `BO = O[11:0]` (12 bits).
- Macro word address: `WA = BO[11:4]` (8 bits, 0..255).
- AXI-word slice within macro word: `SLICE = BO[3:2]` (2 bits, 0..3).
- Byte offset within AXI word: `BYTE = BO[1:0]` (2 bits).

**TCM (base `0x0001_0000`, size 32 KB):**
- Region offset: `O = A - 0x0001_0000` (15 bits, `0..0x7FFF`).
- Bank index: `BANK = O[14:12]` (3 bits, 0..7).
- Byte offset within bank: `BO = O[11:0]`.
- Macro word address: `WA = BO[11:4]`.
- Slice: `SLICE = BO[3:2]`.
- Byte: `BYTE = BO[1:0]`.

**Boot ROM (base `0x0000_0000`, size 16 KB, if SRAM-backed):**
- Region offset: `O = A - 0x0000_0000` (14 bits, `0..0x3FFF`).
- Bank index: `BANK = O[13:12]` (2 bits, 0..3).
- Byte offset within bank: `BO = O[11:0]`.
- Macro word address: `WA = BO[11:4]`.
- Slice: `SLICE = BO[3:2]`.
- Byte: `BYTE = BO[1:0]`.

**Bank-select decode:** Each region has its own bank-count; bank index must not be derived from absolute address bits without first subtracting the region base (regions are not contiguous and do not start at 0). **Status:** PROPOSED (derived from address map + macro capacity).

### 5.3 Bank-enable generation

- For a given access, exactly one bank's `csb` is asserted (active low) per region.
- All other banks in that region receive `csb = 1` (deselected).
- A single wrapper instance manages one region (SRAM, TCM, or boot ROM) and instantiates the required number of macros.
- Cross-region access is handled by the AXI interconnect (different slaves), not by this wrapper.

### 5.4 Read-data selection

- The selected bank's `dout0`/`dout1` (128 bits) is routed to the wrapper.
- The wrapper selects the 32-bit slice using `SLICE`: `rdata32 = dout128[32*(SLICE+1)-1 : 32*SLICE]`.
- The core then extracts byte/halfword from `rdata32` using `BYTE` (existing `ld_data` logic).

### 5.5 Address alignment and invalid addresses

- The wrapper assumes word-aligned macro accesses as produced by the core (misaligned word accesses trap in the core before reaching the bus).
- Byte and halfword accesses arrive as word-aligned AXI transactions with partial `wstrb` (writes) or full-word reads followed by core extraction (reads).
- Out-of-range addresses within a region and invalid bank indices must return `SLVERR` (or be treated as unmapped by the interconnect).

---

## 6. AXI Width Adapter

### 6.1 Write path (32-bit AXI → 128-bit macro)

Given AXI write to address `A` with `wdata[31:0]` and `wstrb[3:0]`:

1. Compute `SLICE = ((A - region_base) >> 2) & 3` (which 32-bit word within the 128-bit macro word).
2. Form `din0` (128 bits): place `wdata` at bits `[32*(SLICE+1)-1 : 32*SLICE]`; all other bits = 0 (masked off).
3. Form `wmask0` (16 bits): for `i = 0..3`, `wmask0[4*SLICE + i] = wstrb[i]`; all other bits = 0.
4. Assert `csb0 = 0`, `web0 = 0` on the selected bank for one cycle.
5. Other banks: `csb0 = 1`.

### 6.1.1 Write-mask mapping table (all slices and byte lanes)

Derived from the Verilog model: `wmask0[k]` controls macro bits `[8(k+1)-1 : 8k]`.

For a 32-bit AXI write at slice `SLICE` (0..3) with strobe bit `j` (0..3), the macro mask bit is `4*SLICE + j`.

| SLICE (addr[3:2]) | WSTRB bit 0 (byte 0) | WSTRB bit 1 (byte 1) | WSTRB bit 2 (byte 2) | WSTRB bit 3 (byte 3) | Full strobe 1111 |
|---:|---|---|---|---|---|
| 0 | `wmask0[0]` = 0x0001 | `wmask0[1]` = 0x0002 | `wmask0[2]` = 0x0004 | `wmask0[3]` = 0x0008 | 0x000F |
| 1 | `wmask0[4]` = 0x0010 | `wmask0[5]` = 0x0020 | `wmask0[6]` = 0x0040 | `wmask0[7]` = 0x0080 | 0x00F0 |
| 2 | `wmask0[8]` = 0x0100 | `wmask0[9]` = 0x0200 | `wmask0[10]` = 0x0400 | `wmask0[11]` = 0x0800 | 0x0F00 |
| 3 | `wmask0[12]` = 0x1000 | `wmask0[13]` = 0x2000 | `wmask0[14]` = 0x4000 | `wmask0[15]` = 0x8000 | 0xF000 |

Status: VERIFIED (from macro Verilog).

**Worked example 1 — Full 32-bit write:**
- AXI: `wstrb = 1111`, `wdata = 0xDEADBEEF`, address slice 0.
- `wmask0 = 0x000F` (bits [3:0]).
- `din0[31:0] = 0xDEADBEEF`; bits [127:32] = 0 (masked).
- Result: bytes [3:0] of the macro word updated; bytes [15:4] unchanged.

**Worked example 2 — Single-byte write:**
- AXI: `wstrb = 0001`, `wdata[7:0] = 0xAB`, slice 2.
- `wmask0 = 0x0100` (`wmask0[8] = 1`, since `4*2 + 0 = 8`).
- `din0[71:64] = 0xAB`; all other mask bits 0.
- Result: byte 8 of the 128-bit word updated; all other bytes unchanged.

**Worked example 3 — Two-byte write:**
- AXI: `wstrb = 0011`, `wdata[15:0] = 0x1234`, slice 1.
- `wmask0` bits [7:4] = `0011` → `wmask0 = 0x0030`.
- `din0[47:32] = 0x1234`.
- Result: bytes 4,5 updated; rest unchanged.

**Worked example 4 — Read from each slice:**
- Macro `dout0` = 128-bit word. For slice `k`, `rdata32 = dout0[32(k+1)-1 : 32k]`.
- Slice 0 → bits [31:0]; slice 1 → [63:32]; slice 2 → [95:64]; slice 3 → [127:96].

**Worked example 5 — Access to different banks:**
- Two AXI writes to addresses in different banks (different `BANK` index) target different macro instances; both can be accepted in separate transactions (serialized by the AXI FSM). No shared state between banks.

### 6.2 Read path (128-bit macro → 32-bit AXI)

1. Assert `csb0 = 0`, `web0 = 1` on the selected bank with `addr0 = WA`.
2. Wait for read completion (1 cycle).
3. Capture `dout0` (128 bits).
4. Select slice: `rdata = dout0[32*(SLICE+1)-1 : 32*SLICE]`.
5. Return `rdata` on AXI `R` channel with `rresp = 00`.

### 6.3 Partial writes and byte strobes

- All 16 combinations of `wstrb` are supported (including `0000`, which performs no write but still completes with OKAY).
- `wstrb = 0000` is a no-op write; the wrapper still asserts the bank for one cycle with all mask bits 0 (or may optimize by skipping the macro access and returning OKAY immediately; if skipped, timing differs — specify one policy). **Recommended:** skip macro access for `wstrb=0000` and return OKAY in the next cycle to save power, but document that this changes latency for the no-op case. **Alternative:** always access macro. **Decision required.**

### 6.4 Unaligned access handling

- The core traps on misaligned word/halfword addresses before issuing the bus transaction (see `mem_misaligned` in `riscv_core.sv`).
- The wrapper does not need to handle sub-word unaligned AXI addresses for correctness of the core.
- If a misaligned address arrives (e.g., from a buggy master), the wrapper returns `SLVERR` and performs no write. **Status:** PROPOSED.

### 6.5 AXI response behavior

- `bresp`/`rresp` = `00` (OKAY) for successful in-range accesses.
- `SLVERR` (`10`) for out-of-range bank, invalid slice, or misaligned address.
- No `DECERR` generation in the wrapper (interconnect handles unmapped regions).

### 6.6 Backpressure

- The wrapper accepts a new AXI transaction only when idle (`state == S_IDLE`).
- If busy, `awready`/`wready`/`arready` are deasserted.
- The interconnect/master must hold `awvalid`/`wvalid`/`arvalid` until accepted.
- Write has priority over read when both are offered in the same cycle (matching current `sram.sv` policy). **Status:** PROPOSED (carried from existing RTL).

### 6.7 Transaction ordering

- One outstanding transaction at a time per wrapper instance (no reordering).
- Reads and writes are serialized at port 0.
- No write-to-read or read-to-write reordering.

### 6.8 AXI4-Lite independent channel handling (proposed, F2)

The existing `sram.sv` accepts `AWVALID` and `WVALID` together in the same cycle. That is **not** fully AXI4-Lite compliant; AW and W are independent channels and may arrive in any order. The wrapper shall implement independent capture as follows:

1. **Independent capture:** AW and W are captured independently.
   - `AWREADY` is asserted when the write-address buffer is empty.
   - `WREADY` is asserted when the write-data buffer is empty.
   - `ARREADY` is asserted when the read path is idle.
2. **One address beat and one data beat are buffered:**
   - Write-address buffer holds `awaddr` (and any region/bank decode).
   - Write-data buffer holds `wdata` and `wstrb`.
3. **Write acceptance occurs only when both buffers are valid** (address captured AND data captured). No macro access is started on a partial arrival.
4. **Pairing:** because AXI4-Lite has no transaction IDs, the single buffered address is paired with the single buffered data. With one outstanding write, ordering is implicit.
5. **Backpressure:**
   - If the address buffer is full, `AWREADY = 0`.
   - If the data buffer is full, `WREADY = 0`.
   - If a write is pending/in-flight, both buffers remain unavailable and both readies are 0.
   - `BVALID` is held until `BREADY`.
   - `RVALID` is held until `RREADY`.
6. **Reads and writes remain serialized at port 0:** `ARREADY = 0` while a write is pending or in-flight. This preserves the current one-outstanding-transaction behavior and avoids port-0 conflicts.
7. **Reset behavior for buffered transactions:**
   - Reset clears the address buffer, data buffer, pending flag, busy flag, `BVALID`, and `RVALID`.
   - A reset after AW capture but before W capture discards the buffered address; no write occurs.
   - A reset after W capture but before AW capture discards the buffered data; no write occurs.
   - A reset during an accepted/in-flight write abandons the AXI transaction; the macro may still commit (no reset pin), so memory state is not guaranteed.
8. **BVALID handling:** `BVALID` remains asserted until `BREADY`; `bresp` is stable during that time.
9. **Duplicate-write prevention:**
   - A write is initiated exactly once, on the cycle when both buffers become valid and no write is pending.
   - On initiation, both buffers are cleared and a `write_pending` flag is set.
   - While `write_pending` is set, new AW/W beats are backpressured.
   - `write_pending` clears only after the macro write commits and `BVALID` is accepted (or after reset).
   - Re-asserted AWVALID/WVALID while pending do not create a second write.

### 6.8.1 Read acceptance during partial writes (F6)

Sequence: AW handshake occurs; W is delayed; AR arrives before W; W eventually arrives; write executes and responds.

**Deterministic policy (chosen):** reads do **not** bypass a partially captured or pending write. While a write is partially captured (AW buffered without W, or W buffered without AW) or pending/in-flight, `ARREADY = 0`. The read waits until the write completes and `BVALID` is accepted.

Behavior:
- **AWREADY after address capture:** 0 until the write completes and buffers clear.
- **WREADY before address capture:** 1 if the data buffer is empty (capture allowed).
- **WREADY after address capture:** 0 once the data buffer is full or a write is pending; 1 only if the data buffer is empty and no write is pending.
- **ARREADY while only AW is buffered:** 0 (read waits).
- **ARREADY while only W is buffered:** 0 (read waits).
- **ARREADY while both buffers are valid:** 0 (write initiation in progress).
- **ARREADY while write is in-flight:** 0.
- **Transaction ordering:** AW, W, and the eventual write response remain ordered; no read is interleaved.
- **Whether reads wait for pending writes:** Yes.
- **Response ordering:** BVALID for the write precedes any RVALID for a read accepted after the write.
- **Reset behavior:** reset clears partial AW/W captures and pending state; no write occurs for partial captures.

**Consequences:** this preserves the one-outstanding-transaction architecture and avoids read-write hazards, but a read arriving during a partial write experiences backpressure until the write completes. This is preferred over allowing reads during partial writes, which would complicate ordering and risk stale data.

Status: PROPOSED (protocol decision; not implemented).

---

## 7. Instruction/Data Arbitration

### 7.1 Port allocation

- **Port 0 (rw):** all AXI data reads and writes.
- **Port 1 (r):** all instruction fetches.

This maps directly to the macro's 1rw + 1r architecture.

### 7.2 Access cases

| AXI operation | Instruction operation | Same bank? | Same macro word (WA)? | Expected behavior |
|---------------|----------------------|------------|----------------------|-------------------|
| Read bank A | Read bank A | Yes | Any | Both proceed: AXI on port 0, I-fetch on port 1. Reads are safe even for the same macro word. |
| Read bank A | Read bank B | No | N/A | Both proceed on separate macros. No interaction. |
| Write bank A | Read bank A | Yes | Yes | **Hazard.** Stall instruction fetch (deassert `i_gnt`, delay `i_rvalid`) for one cycle; AXI write proceeds. The collision is at macro-word granularity; differing AXI slices do not avoid it. |
| Write bank A | Read bank A | Yes | No | Both proceed: AXI write on port 0, I-fetch on port 1. Different macro words in the same bank are concurrent. |
| Write bank A | Read bank B | No | N/A | Both proceed on separate macros. No interaction. |
| Idle | Read bank A | Yes | N/A | I-fetch proceeds on port 1. Port 0 idle. |

**Collision rule (F4):** a collision exists when `AXI_write.BANK == I_fetch.BANK` AND `AXI_write.WA == I_fetch.WA`. The AXI slice (`addr[3:2]`) does **not** eliminate the collision because four AXI words share one 128-bit macro word. Different macro words in the same bank remain concurrent; different banks remain independent.

### 7.3 Arbitration priority

- **Instruction fetch is not starved by AXI writes:** if a write stalls an I-fetch at the same address, the stall lasts exactly one cycle (the write completes on the next negedge), then the fetch may proceed.
- **AXI writes are not reordered** with respect to I-fetches; the wrapper does not forward a write to an I-fetch unless explicitly designed.
- If forwarding is implemented, it must be documented and verified (forward write data to I-fetch when addresses match and write is in-flight).

### 7.4 Stall behavior

- When stalling an I-fetch: `i_gnt = 0`, `i_rvalid = 0` until the hazard clears.
- The core holds `instr_req` and `instr_addr` stable until `instr_rvalid` (per its FSM contract).
- No AXI backpressure is generated by an I-fetch stall (AXI transactions proceed independently).

### 7.5 Response ordering

- I-fetch completion (`instr_rvalid`) may be delayed relative to the AXI transaction that caused the stall, but relative order among I-fetches is preserved.
- AXI responses are not delayed by I-fetch activity.

---

## 8. Collision Handling

### 8.1 Deterministic policy

The wrapper must **never** rely on the macro's undefined same-macro-word read-during-write behavior. The policy is:

1. Track in-flight writes per bank (bank index + macro word address `WA` + active flag).
2. If an I-fetch targets a bank with an in-flight write to the **same macro word** (`BANK` and `WA` match), stall the I-fetch until the write completes. Differing AXI slices within that macro word still collide.
3. If the macro words differ, allow concurrent access even within the same bank.
4. If two AXI transactions target the same bank, serialize them at port 0 (existing FSM).

### 8.2 Forwarding (optional, PROPOSED)

- If an I-fetch is stalled due to a same-macro-word write, the wrapper may forward the write data (the 32-bit slice being written) to `i_rdata` instead of stalling, completing in the same cycle.
- Forwarding requires that the write data is available and the slice matches.
- **Decision required** before implementation: stall-only vs. stall+forward. Stall-only is simpler and avoids forwarding bugs; recommended for first implementation.

### 8.3 AXI read during AXI write (same bank)

- Serialized by the AXI FSM; no concurrency. No hazard.

### 8.4 Cycle-accurate collision timing (F3)

Macro edge behavior (from Verilog): inputs are sampled on the **rising edge** of the clock; writes commit on the **falling edge**; read outputs update on the **falling edge**. Port 0 and port 1 are separate but share the same physical memory array.

**Key timing rule:** a port-0 write and a port-1 read to the **same address** must not be enabled in the **same cycle**, because both would sample on the same rising edge and commit on the same falling edge with undefined ordering. A one-cycle stall of the instruction fetch is sufficient **if** the fetch is not enabled in the write's enable cycle.

Assumed wrapper timing (proposed): an accepted AXI write enables the macro in the same cycle (inputs stable before the rising edge); the write commits on that cycle's falling edge; `BVALID` is returned the next cycle. An instruction fetch enabled in a cycle samples on that rising edge and commits its read on that falling edge.

#### Table A — Same bank, same macro word (write + instruction fetch)

| Cycle | AXI write | I-fetch request | Wrapper action | Macro port 0 | Macro port 1 | Result |
|---:|---|---|---|---|---|---|
| 0 | Accepted (handshake) | Arrives, same address | Collision detected; port 1 **not** enabled; stall asserted (`i_gnt=0`) | Write enabled; samples inputs on rising edge; commits on falling edge | Disabled (`csb1=1`) | Write commits; fetch stalled |
| 1 | Complete (`BVALID`) | Held request | Stall cleared; port 1 enabled | Idle | Read enabled; samples address on rising edge; commits on falling edge | Fetch data available cycle 2 |
| 2 | — | — | — | — | — | `i_rvalid=1`, data valid (post-write value) |

**Conclusion:** one-cycle stall is sufficient because the fetch is enabled only in cycle 1, after the write committed on the falling edge of cycle 0.

**Note (F4):** Table A applies to any fetch from the same macro word, including a different AXI slice (e.g., write slice 0, fetch slice 2). The slice does not avoid the collision.

#### Table B — Same bank, different macro word (write + instruction fetch)

| Cycle | AXI write | I-fetch request | Wrapper action | Macro port 0 | Macro port 1 | Result |
|---:|---|---|---|---|---|---|
| 0 | Accepted | Arrives, different address | No collision; both enabled | Write enabled; commits on falling edge | Read enabled; commits on falling edge | Both complete; addresses independent |
| 1 | `BVALID` | Response | — | — | — | `i_rvalid=1`, correct data |

No stall required.

#### Table C — Different bank (write + instruction fetch)

| Cycle | AXI write | I-fetch request | Wrapper action | Result |
|---:|---|---|---|---|
| 0 | Accepted (bank X) | Arrives (bank Y) | No interaction; separate macros enabled | Both complete independently |
| 1 | `BVALID` | Response | — | `i_rvalid=1` |

No stall required.

#### Table D — Reset asserted while a write is in flight (F5 case B: reset between rising and falling edges)

| Cycle / edge | Event | Wrapper | Macro | Memory state |
|---:|---|---|---|---|
| 0, rising edge | Write accepted and enabled | `write_pending=1`; AW/W captured | Samples inputs on rising edge | Pending (not yet committed) |
| 0, after rising edge, before falling edge | `reset_n` asserted (asynchronous active-low) | Clears state/buffers; abandons the AXI transaction; suppresses `BVALID` | No reset pin; already sampled inputs are not cancelled by reset and may still commit | Not guaranteed (may remain uncommitted or update on the falling edge) |
| 0, falling edge | Possible macro commit from sampled inputs | No `BVALID` (transaction abandoned) | May commit the sampled write | May be updated if commit occurs; otherwise unchanged |
| 1+ | Reset held | All `csb=1`; no accesses; `write_pending=0` | Idle | Retains last committed value |
| After reset deassertion | — | Re-initializes to idle; no stale `BVALID` | — | Last committed value, if any |

**Cross-check (F5):** Case A (reset before the rising edge) samples and commits nothing; Case C (reset after the falling edge) retains the committed value and returns `BVALID` only if that handshake completed. Case B above is the reset-between-edges case and is the only case where memory contents are not guaranteed.

**Limitation:** the macro has no reset pin. A reset cannot abort a write that has already been sampled. If reset is asserted after the rising edge but before the falling edge of the enable cycle, the write may still commit. The wrapper must not report `BVALID` for an abandoned transaction, and software must not rely on write atomicity across reset. Status: PARTIALLY VERIFIED (macro has no reset; timing derived from Verilog model).

---

## 9. Latency Contract

### 9.1 RTL-cycle latency (proposed, based on macro behavior)

| Operation | Request accepted | Data/response available | Cycles |
|-----------|-----------------|------------------------|--------|
| AXI read | Cycle 0 (rd_fire) | Cycle 1 (rvalid) | 1 |
| AXI write | Cycle 0 (wr_fire) | Cycle 1 (bvalid) | 1 |
| Instruction fetch | Cycle 0 (i_req) | Cycle 1 (i_rvalid) | 1 |
| Stalled I-fetch (same-address write) | Cycle 0 (stalled) | Cycle 2 (after write completes) | 2 |

### 9.2 Macro timing (Liberty, TT corner)

| Parameter | Value | Status |
|-----------|-------|--------|
| Setup (din0, addr0, wmask0, csb0, web0 vs clk0) | 0.165 ns | VERIFIED |
| Hold | -0.052 ns | VERIFIED |
| Clock-to-output (dout0/dout1) | 0.366–0.511 ns | VERIFIED |
| Read latency | 1 cycle (registered output) | VERIFIED (Liberty + Verilog) |
| Operating voltage | 1.8 V | VERIFIED |
| Temperature | 25 °C | VERIFIED |
| Process corner | TT (process 1.0) | VERIFIED |
| SS/FF/FS/SF views | Not available for this macro | NOT AVAILABLE |

### 9.3 Physical clock-to-output delay

- The macro's `dout` is registered and updated on the falling edge of the clock (Verilog `MEM_READ` on `negedge clk`).
- In a single-clock design, read data is stable by the next rising edge (1 cycle later).
- The Verilog `DELAY = 3` parameter is arbitrary and must **not** be used as physical timing evidence. **Status:** VERIFIED (Liberty clk-to-q is authoritative).

### 9.4 Reset interruption behavior (F5)

- The macro has **no reset port**. Memory contents survive reset.
- The wrapper's reset (`reset_n`/`rst_sys_n`) aborts in-flight transactions at the AXI level (deasserts ready, clears state) but **cannot guarantee** that a macro write already sampled on a rising edge will not commit on the following falling edge.
- **Policy:** during reset, `csb0 = csb1 = 1` (all macros deselected); no new transactions accepted. In-flight transactions are abandoned; memory state after reset is not guaranteed for a write in progress at reset assertion.
- Use the F5 case table in Section 3.5 for reset timing. Reset is asynchronous in the RTL, but macro edge behavior is timing-derived.
- Software/firmware must not depend on atomicity of writes across a reset.

---

## 10. Reset and Initialization

### 10.1 Macro behavior during reset

- No reset pin; contents persist.
- Wrapper gates all chip selects during reset.

### 10.2 SRAM/TCM initialization policy

- Uninitialized at power-on (arbitrary values).
- Firmware/bootloader must initialize SRAM/TCM before use.
- Simulation uses `$readmemh` (MEM_FILE).

### 10.3 Boot ROM initialization policy

- If implemented as standard-cell ROM (recommended by enablement decision): initialized by GDS/memory image.
- If SRAM-backed: 4 banks must be initialized with the boot image during manufacturing/test or via a programming interface. **Open question.**

### 10.4 Power-on behavior

- Macro power pins (`vdd`, `gnd`) must be stable before clock.
- No power-sequencing specification available in the macro views. **Status:** NOT AVAILABLE.

### 10.5 Reset during outstanding read/write (F5)

Use the F5 case table in Section 3.5. Reset is asynchronous in the RTL but macro edge behavior is timing-derived.

- Wrapper clears AXI state; macro may complete an in-flight write.
- After reset, the wrapper re-initializes to idle; no stale data is returned.

### 10.6 Interrupted transactions

- Abandoned; no retry or completion. Master (interconnect/core) handles timeout/retry per AXI protocol.

---

## 11. Verification Matrix

### 11.1 Functional tests

| Test ID | Initial conditions | Stimulus | Expected result | Observable signals | Pass criteria |
|---------|-------------------|----------|----------------|-------------------|---------------|
| F-01 | Bank selected, all bytes = 0x00 | Full-word write 0xA5A5A5A5 to word 0 | Word 0 = 0xA5A5A5A5 | `dout0`, `rdata` | Exact match |
| F-02 | Bank selected | Write to word 0, read word 0 | Read returns written value | `rdata` | Exact match |
| F-03 | Bank selected | Single-byte write (each of 4 bytes) | Only targeted byte changes | `rdata` before/after | Unchanged bytes identical |
| F-04 | Bank selected | Two-byte write (each adjacent pair) | Only targeted bytes change | `rdata` | Unchanged bytes identical |
| F-05 | Bank selected | Write to word 0, read word 1 | Word 1 unchanged | `rdata` | Word 1 = initial |
| F-06 | All banks | Write/read to first and last word of each bank | Correct data per bank | `rdata` | All banks pass |
| F-07 | Bank selected | Read from each of 4 slices | Correct 32-bit slice | `rdata` | Slice matches |
| F-08 | Bank selected | Back-to-back writes to same word | Final value = last write | `rdata` | Exact match |
| F-09 | Bank selected | `wstrb = 0000` write | No data change, OKAY response | `rdata`, `bresp` | `bresp=00`, data unchanged |
| F-10 | Multiple banks | Address isolation between banks | No cross-bank corruption | `rdata` per bank | Each bank independent |

### 11.2 Concurrency tests

| Test ID | Initial conditions | Stimulus | Expected result | Observable signals | Pass criteria |
|---------|-------------------|----------|----------------|-------------------|---------------|
| C-01 | Two banks idle | Simultaneous AXI read bank A + I-fetch bank A (same or different macro words) | Both complete, correct data | `rdata`, `i_rdata`, `rvalid`, `i_rvalid` | Both valid, correct |
| C-02 | Bank A idle | I-fetch bank A during AXI write bank A, same bank, different macro word (`WA`) | Both complete (concurrent permitted) | `i_rvalid`, `bvalid` | Both valid |
| C-02A | Bank A idle | I-fetch bank A during AXI write bank A, same bank, same macro word, different AXI slices | I-fetch stalled 1 cycle; then completes with defined data | `i_gnt`, `i_rvalid` | Stall observed; no X |
| C-03 | Bank A idle | I-fetch bank A during AXI write bank A, same address | I-fetch stalled 1 cycle, then completes with defined data | `i_gnt`, `i_rvalid` | No undefined value; stall observed |
| C-04 | Two banks idle | AXI read bank A + I-fetch bank B | Both complete independently | `rvalid`, `i_rvalid` | Both valid |
| C-05 | Bank A idle | Two I-fetches same bank (serialized by core) | Sequential completion | `i_rvalid` | Correct order |
| C-06 | Bank A busy (write) | AXI read to same bank arrives | Read waits (backpressure) | `arready=0` then accept | No data loss |
| C-07 | Bank A idle | AXI read + AXI write same bank (any macro words) | Serialized; both complete | `rvalid`, `bvalid` | Both valid, correct |

### 11.3 Protocol tests

| Test ID | Initial conditions | Stimulus | Expected result | Observable signals | Pass criteria |
|---------|-------------------|----------|----------------|-------------------|---------------|
| P-01 | Idle | AXI read with `rready=0` | `rvalid` held until `rready` | `rvalid`, `rready` | No data loss |
| P-02 | Idle | AXI write with `bready=0` | `bvalid` held until `bready` | `bvalid`, `bready` | No data loss |
| P-03 | Idle | Reset during read | Transaction aborted; no `rvalid` after reset | `rvalid`, `reset_n` | No completion after reset |
| P-04 | Idle | Reset during write | Transaction aborted; no `bvalid` after reset | `bvalid`, `reset_n` | No completion after reset |
| P-05 | Idle | Out-of-range address | `SLVERR` response | `rresp`/`bresp` | `10` |
| P-06 | Idle | Misaligned address (if injected) | `SLVERR`, no write | `bresp`, bank data | Data unchanged |
| P-07 | Idle | All 16 `wstrb` combinations | Correct byte updates | `rdata` | Match expected |
| P-08 | Idle | Back-to-back reads same bank | Both complete with correct data | `rdata` | Both match |

### 11.4 Negative tests

| Test ID | Initial conditions | Stimulus | Expected result | Observable signals | Pass criteria |
|---------|-------------------|----------|----------------|-------------------|---------------|
| N-01 | Idle | Invalid bank index | `SLVERR`, no macro access | `csb` all high | No `csb=0` |
| N-02 | Idle | Address beyond region size | `SLVERR` | `rresp`/`bresp` | `10` |
| N-03 | Idle | Unsupported access size (if any) | `SLVERR` | `bresp` | `10` |
| N-04 | Bank A idle | Same-address write+fetch collision attempt | I-fetch stalled, no undefined read | `i_rdata` not X | No X/Z |
| N-05 | Idle | Reset during in-flight write | No crash; memory may be indeterminate | Simulation completes | No X propagation to AXI |

**Note:** No tests have been run. This matrix defines required coverage only. **Status:** PROPOSED.

### 11.5 AXI channel-independence and collision tests (F2/F3)

| Test ID | Initial conditions | Stimulus | Expected result | Observable signals | Pass criteria |
|---------|-------------------|----------|----------------|-------------------|---------------|
| AXI-01 | Idle | `AWVALID` asserted, `WVALID` delayed 3 cycles | Address buffered; no write until W arrives; then one write | `AWREADY`, `WREADY`, `csb0`, `bvalid` | One macro write, one B |
| AXI-02 | Idle | `WVALID` asserted, `AWVALID` delayed 3 cycles | Data buffered; no write until AW arrives | `WREADY`, `AWREADY`, `csb0`, `bvalid` | One macro write, one B |
| AXI-03 | Idle | `AWVALID` and `WVALID` same cycle | Write accepted once | `csb0` pulse count, `bvalid` | Exactly one write, one B |
| AXI-04 | Write pending | `AWVALID`/`WVALID` re-asserted while pending | Backpressure; no duplicate write | `AWREADY=0`, `WREADY=0`, `csb0` | No second write |
| AXI-05 | Idle | `BREADY` delayed | `BVALID` held; no new write accepted | `bvalid`, `bready`, `awready` | B stable until ready |
| AXI-06 | Idle | `RREADY` delayed | `RVALID` held; data stable | `rvalid`, `rready`, `rdata` | Data stable until ready |
| AXI-07 | Idle | Reset after AW capture, before W capture | Buffered address discarded; no write | `csb0` never asserted | No write |
| AXI-08 | Idle | Reset after W capture, before AW capture | Buffered data discarded; no write | `csb0` never asserted | No write |
| AXI-09 | Write in flight | Reset during accepted write | Transaction abandoned; no `BVALID`; memory may be indeterminate | `bvalid=0` after reset | No B response |
| COLL-01 | Bank idle | Same-address write + I-fetch, fetch arrives same cycle as write | Fetch stalled one cycle; completes with post-write value | `i_gnt`, `i_rvalid`, `i_rdata` | Stall observed; no X |
| COLL-02 | Bank idle | Same-address write + I-fetch, fetch arrives one cycle after write | No stall; fetch returns post-write value | `i_rvalid` timing | No stall |
| COLL-03 | Bank idle | Same macro word, different AXI slices/addresses, same-bank write + I-fetch | Stall; slice does not avoid collision | `i_gnt`, `i_rvalid` | Stall observed |
| COLL-03A | Bank idle | Different macro word, same-bank write + I-fetch | No stall; both complete | `bvalid`, `i_rvalid` | Both valid |
| COLL-04 | Two banks idle | Different-bank write + I-fetch | No stall; both complete | `bvalid`, `i_rvalid` | Both valid |
| COLL-05 | Bank idle | Reset during write + I-fetch collision | No undefined read; fetch not exposed to collision data | `i_rdata` not X | No X/Z |

Status: PROPOSED (tests defined only; not run).

### 11.6 F4/F5/F6 tests (proposed)

| Test ID | Initial conditions | Stimulus | Expected result | Observable signals | Pass criteria |
|---------|-------------------|----------|----------------|-------------------|---------------|
| MACWORD-01 | Bank idle | AXI write slice 0, I-fetch slice 2, same bank+WA | Fetch stalled; no undefined read | `i_gnt`, `i_rvalid`, `i_rdata` | Stall observed; no X |
| MACWORD-02 | Bank idle | AXI write slice 2, I-fetch slice 0, same bank+WA | Fetch stalled; no undefined read | `i_gnt`, `i_rvalid` | Stall observed |
| MACWORD-03 | Bank idle | Same bank+WA, different byte lanes | Fetch stalled at macro-word granularity | `i_rvalid` timing | Stall observed |
| MACWORD-04 | Bank idle | Different WA, same bank | No stall; concurrent completion | `bvalid`, `i_rvalid` | Both valid |
| MACWORD-05 | Two banks idle | Different banks | No stall; independent completion | `bvalid`, `i_rvalid` | Both valid |
| RESET-01 | Idle | Reset before rising edge of write enable | No sample, no commit | `csb0`, memory | Memory unchanged |
| RESET-02 | Write enabled | Reset after rising edge, before falling edge | Macro may commit; BVALID not returned | `bvalid=0`, memory | No B response |
| RESET-03 | Write committed | Reset after falling edge | Memory committed; BVALID only if handshake completed | `memory`, `bvalid` | Committed value retained |
| PARTIAL-01 | Idle | AW captured, W delayed 3 cycles, AR arrives before W | AR backpressured until write completes | `ARREADY=0`, then accept | Read waits |
| PARTIAL-02 | Idle | W captured, AW delayed 3 cycles, AR arrives before AW | AR backpressured until write completes | `ARREADY=0`, then accept | Read waits |
| PARTIAL-03 | Idle | Reset after partial AW capture | No write | `csb0` never asserted | No write |
| PARTIAL-04 | Idle | Reset after partial W capture | No write | `csb0` never asserted | No write |

Status: PROPOSED (tests defined only; not run).

---

## 12. Physical Integration Requirements

### 12.1 Required macro instances

| Region | Banks | Instances |
|--------|-------|-----------|
| Main SRAM | 32 | 32 |
| TCM | 8 | 8 |
| Boot ROM (if SRAM-backed) | 4 | 4 |
| **Total** | **44** | **44** |

### 12.2 Macro views

- **LEF:** `sky130_sram_1rw1r_128x256_8.lef` — 1141.72 × 632.475 µm, CLASS BLOCK, power pins `vdd`/`gnd`.
- **Liberty:** `sky130_sram_1rw1r_128x256_8_TT_1p8V_25C.lib` — TT only.
- **GDS:** `sky130_sram_1rw1r_128x256_8.gds` — present.
- **SPICE:** `.sp`, `.lvs.sp`, `functional_stim.sp` — present.

All views agree on name, data width (128), address width (8), mask width (16), and power pins. **Status:** VERIFIED.

### 12.3 Power pins

- `vdd` (primary power), `gnd` (primary ground) — INOUT.
- Must be connected to the power distribution network (PDN).
- Leakage power: 0.039892 (Liberty). **Status:** VERIFIED (from Liberty).

### 12.4 Clock connections

- `clk0` → AXI port clock (core clock).
- `clk1` → instruction-fetch clock (core clock).
- Both may be tied to the same physical clock, but STA must analyze skew between the two ports. **Status:** PROPOSED.

### 12.5 Bank placement considerations

- 44 macros of ~1142 × 632 µm each → significant area.
- Banked array layout; address decode and read-data mux routing between macros and logic.
- Exact placement and routing not determined. **Status:** NOT AVAILABLE (no implementation).

### 12.6 Macro timing constraints

- Setup/hold: 0.165 ns / -0.052 ns (inputs vs clk0/clk1).
- Clock-to-output: 0.366–0.511 ns (clk-to-q).
- Use Liberty for STA; do not use Verilog `DELAY = 3`.

### 12.7 TT-only timing limitations

- Only TT corner (1.8 V, 25 °C) is available. SS/FF/FS/SF views are **not available**.
- Setup/hold margins at other corners are unknown.
- This is a **blocker** for signoff at non-TT corners. **Status:** BLOCKED (pending additional macro views or derating analysis).

---

## 13. Architecture Decision

| Option | Functional compat. | Byte-write compat. | Port compat. | Timing evidence | Physical views | Complexity | Blockers |
|--------|-------------------|-------------------|--------------|-----------------|----------------|------------|----------|
| A. Direct macro connection | NO (width mismatch) | N/A | NO | N/A | N/A | — | Width mismatch, address mapping |
| B. Banked macro wrapper | YES | YES (with adapter) | YES (with collision avoidance) | TT only | VERIFIED | High | Read-during-write hazard, TT-only timing, 44-macro routing |
| C. Alternative 64-bit macro organization | YES | YES | YES | TT only | VERIFIED | Medium-High | Double bank count (64 banks for 128 KB), width adapter still needed |
| D. Behavioral SRAM retained for simulation only | YES (sim) | YES | YES | N/A | N/A | Low (sim) | Not synthesizable to ASIC |

**Recommendation:** Option B (banked 128-bit macros + wrapper). It is the only viable ASIC path among available macros. It requires resolving the read-during-write hazard (stall policy) and accepting TT-only timing until additional corner views are obtained.

---

## 14. Open Questions

1. **SS/FF/FS/SF Liberty views:** Not available for this macro. Are they obtainable from the macro provider or via characterization?
2. **Boot ROM implementation:** Standard-cell ROM (recommended) vs. SRAM-backed (4 banks). If SRAM-backed, initialization mechanism?
3. **Clock skew:** Can `clk0` and `clk1` be the same physical clock with acceptable skew for STA?
4. **Forwarding:** Stall-only vs. stall+forward for same-address write/fetch collisions. (Recommend stall-only initially.)
5. **No-op write (`wstrb=0000`):** Skip macro access or always access?
6. **AXI outstanding transactions:** Does the interconnect support more than one outstanding transaction per slave? Current wrapper supports one.
7. **Unaligned AXI addresses:** Wrapper returns SLVERR, but is this consistent with interconnect behavior?
8. **Power sequencing:** No specification in macro views. Required for PDN design.
9. **Area/timing:** No implementation evidence. Cannot estimate without synthesis/P&R.

---

## 15. Implementation Acceptance Criteria

The wrapper implementation (future work) must satisfy:

1. **Correct 32-bit to 128-bit data mapping:** Slice selection by `addr[3:2]`; write data placed in correct slice; read data extracted from correct slice.
2. **Correct byte-write semantics:** `WSTRB[3:0]` expands to the correct 4 of 16 `wmask0` bits; unselected bytes preserved.
3. **Correct bank addressing:** Bank index derived from region offset, not absolute address; no cross-bank corruption.
4. **Macro-word collision detection:** Collision uses bank + macro word (`WA`); differing AXI slices do not avoid collision.
5. **Safe instruction/data concurrency:** No reliance on undefined macro collision behavior; same-macro-word write/fetch handled by stall.
6. **Deterministic collision handling:** Stall policy documented and verified; no X/Z propagation.
7. **Defined request/response latency:** 1 cycle read, 1 cycle write, 1 cycle fetch (2 cycles if stalled).
8. **Correct reset behavior:** Macros deselected during reset; no crash; AXI state cleared.
9. **Complete verification coverage:** All tests in Section 11 pass.
10. **TT-only timing acknowledged:** No signoff claim at non-TT corners until additional views are available.

---

## 16. Evidence and Reproducibility

- Macro Verilog: `/d/rta-real-world-benchmark/.../sky130ram/sky130_sram_1rw1r_128x256_8/sky130_sram_1rw1r_128x256_8.v`
- Macro generator config: `.../sky130_sram_1rw1r_128x256_8.py`
- Liberty: `.../sky130_sram_1rw1r_128x256_8_TT_1p8V_25C.lib`
- LEF: `.../sky130_sram_1rw1r_128x256_8.lef`
- GDS: `.../sky130_sram_1rw1r_128x256_8.gds`
- SoC SRAM RTL: `rtl/rtl_top/sram.sv`
- SoC address map: `rtl/rtl_top/has_addr_map.sv`
- SoC top (fetch mux, TCM instance): `rtl/rtl_top/has_soc.sv`
- Core interface: `rtl/rtl_top/riscv_core.sv`
- Prior reports: `reports/ASIC_FEASIBILITY_AND_SYNTHESIS_READINESS.md`, `reports/ASIC_ENABLEMENT_DESIGN_DECISION.md`, `reports/SKY130_SRAM_MACRO_INTERFACE_AUDIT.md`
- Evidence directory: `reports/evidence/sky130_sram_macro_audit/`

## 17. Revision History (F1-F6 corrections)

| Finding | Original | Correction | Evidence | Remaining limitation |
|---------|----------|------------|----------|----------------------|
| F1 | Worked example 2 used `wmask0 = 0x0040` for slice 2, WSTRB 0001 | Corrected to `wmask0 = 0x0100` (`wmask0[8]`). Added full 4×4 slice/byte mapping table. | Macro Verilog: `wmask0[8]` controls bits [71:64] | None |
| F2 | Spec assumed AW and W arrive together (carried from `sram.sv`) | Defined independent capture, buffering, pairing, backpressure, reset, BVALID hold, duplicate prevention. | AXI4-Lite channel independence; `sram.sv` handshake inspection | Protocol not implemented; RTL unchanged |
| F3 | Collision handling stated one-cycle stall without cycle proof | Added cycle-accurate tables for same-macro-word, different-macro-word, different-bank, and reset-in-flight cases. Proved one-cycle stall sufficient when fetch is not enabled in write enable cycle. | Macro Verilog rising-edge sample, falling-edge commit | Macro has no reset pin; in-flight write may commit across reset |
| F4 | Collision described at AXI-address granularity | Redefined collision at bank + macro-word (`WA`) granularity; slice does not avoid collision. Corrected Sections 7.2, 8.1, Tables A/B/C, latency/arbitration, COLL-03, and added MACWORD tests. | Macro is 128 bits = four AXI words per macro word | None |
| F5 | Reset described as both asynchronous and synchronous without case split | Added F5 case table (reset before rising edge, between edges, after commit) using RTL reset semantics. Distinguished verified RTL behavior from timing-derived macro inference. | `sram.sv` async `negedge reset_n`; `reset_ctrl.sv` | Macro has no reset pin; in-flight write may commit |
| F6 | Read acceptance during partial writes unspecified | Chose deterministic policy: reads wait while a write is partially captured or pending/in-flight; ARREADY=0 until write completes. Added PARTIAL tests. | One-outstanding-transaction architecture | Read latency may be delayed by pending writes |

### Additional consistency checks performed

| Item | Result |
|------|--------|
| Bank address equations | VERIFIED (region offset used; non-contiguous regions) |
| Main SRAM region boundary (128 KB at 0x2000_0000) | VERIFIED |
| TCM region boundary (32 KB at 0x0001_0000) | VERIFIED |
| Boot ROM region boundary (16 KB at 0x0000_0000) | VERIFIED |
| 128-to-32 slice mapping | VERIFIED |
| Byte offset handling | VERIFIED (core handles sub-word extraction) |
| WSTRB expansion | VERIFIED (F1 corrected) |
| Macro write-mask polarity | VERIFIED (active-high write) |
| Read latency | VERIFIED (1 cycle) |
| Write completion latency | VERIFIED (1 cycle) |
| Zero-strobe writes | PARTIALLY VERIFIED (policy open: skip vs access) |
| Unaligned accesses | PARTIALLY VERIFIED (wrapper returns SLVERR; core traps) |
| Reset behavior | PARTIALLY VERIFIED (macro has no reset) |
| Verification matrix | UPDATED (Section 11.5 added) |

No other contradictory statements were found. Unresolved decisions remain explicitly marked (Sections 6.3, 8.2, 14).
