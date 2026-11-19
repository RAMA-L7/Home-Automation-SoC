# RUN-0009 — memory architecture audit (F5, F7)

- **Local / UTC:** 2026-11-18 19:51–20:05 IST (2026-11-18T14:21–14:35Z)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`
- **Reviewer:** self (same agent) — **not independent**
- **Base:** `025ef24` + dirty worktree; no functional RTL touched
- **Full report:** `research/MEMORY_ARCHITECTURE_AUDIT.md`

## Verdict

| Finding | Verdict | Meaning |
|---|---|---|
| F5 — declared vs implemented capacity | **PASS** (audit) | inventory complete, reconciliation exact, mismatch confirmed and quantified |
| F7 — inferred memories without implementation | **BLOCKED** | 4 inferred memories, no macro, no usable PDK |
| Overall | **PARTIAL** | the audit question is answered; the implementation question cannot be |

No ASIC-readiness claim is made. Nothing was ordered, generated or estimated.

## What was measured (not counted)

`asic/synthesis/memory_audit.ys` elaborates `has_soc`, runs `proc`,
`memory_collect`, `stat -json` and `write_rtlil` — no techmap, no flatten — so
the numbers come from the design, not from RTL comments.

| Memory | Geometry | Bytes | Ports | Decoded aperture | Result |
|---|---|---|---|---|---|
| Boot ROM | 16384 × 32 | 65,536 | 2R 0W | 16,384 | **4× the aperture** |
| TCM | 8192 × 32 | 32,768 | 2R, 1W ×4 lanes | 32,768 | match |
| SRAM | 65536 × 32 | 262,144 | 2R, 1W ×4 lanes | 131,072 | **2× the aperture** |
| APB decode LUT | 16 × 9 | 18 | 1R 0W | n/a (logic) | fine |

Totals: **360,466 B of arrays against 180,224 B addressable**; 136 B of
register storage (`rf` 1024 bits, `plic prio` 64 bits). No FIFOs exist — the
UART explicitly has none (`FCR` reads `0x01`) and no peripheral declares an array
other than the PLIC priority registers.

The earlier "4 memories" count is reproduced and explained: two SRAM
parameterizations, the boot ROM, and the 18 B decode LUT inferred from the APB
slot `case`. The older "3" undercounted by missing the LUT.

## Reconciliation

Four descriptions agree with each other and disagree with the arrays:

- `has_addr_map.sv`: ROM 16 KiB, TCM 32 KiB, SRAM 128 KiB;
- `axi_lite_interconnect.sv:114-120`: the same apertures as literals;
- `firmware/bare_metal/linker.ld`: 16K / 32K / 128K;
- `docs/requirements/system_requirements.md` FR-MEM-001: 128 KB SRAM.

So the surplus is unreachable and the defect is area/macro sizing, not function.
Which side to change is a decision, not a measurement; both options are recorded
and neither was executed (RTL frozen for this audit).

## Controls

`scripts/eda/audit_memory.js` compares elaboration, inventory, address map and
interconnect, and exits `0 PASS / 1 FAIL / 2 BLOCKED`. Seven controls prove it can
fail: clean design → 2, missing entry → 1, edited depth → 1, false "fixed" claim
→ 1, changed map size → 1, changed interconnect aperture → 1, lost ROM init → 1.
All 7 pass.

## Why F7 is BLOCKED (not "almost done")

- No `.lib`, `.lef`, `.gds` or blackbox for any memory; no memory compiler has run.
- No PDK is provisioned, so a macro cannot be generated or characterised here.
- A macro cannot be sized before the F5 capacity decision.
- The RTL needs 2 read ports plus byte-enabled write, and a dual-read ROM; whether
  a sky130 macro supports that combination has **not** been verified.
- ROM initialization (`$readmemh`) has no ASIC equivalent yet; the default
  elaboration bakes NOP fill only, i.e. no boot image in the netlist.

## Residual concerns

1. Read-during-write semantics of any replacement macro must be checked; the RTL
   currently returns the pre-write word in the write cycle.
2. The 16×9 decode LUT is an inferred ROM but must stay logic, not become a macro;
   a future mapper change could accidentally push it toward a ROM implementation.
3. `struct` fields marked `verified_by: manual` in the inventory (capacity choice,
   macro requirements) are analysis, not proof.
4. Self-reviewed only; G4.4 remains open.

## Reproduce

```bash
yosys -s asic/synthesis/memory_audit.ys      # exit 0, ~15 s
node scripts/eda/audit_memory.js --verbose   # exit 2 (BLOCKED)
node scripts/eda/audit_memory.js --self-test # 7/7, exit 0
node scripts/verify.js                       # 10/10, exit 0
```
