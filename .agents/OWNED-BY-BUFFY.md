# AGENTS.md — Home-Automation-SoC Project Handoff Documentation

**Purpose:** This file tells every agent working on this project what has been completed, what is in progress, what is blocked, and what NOT to repeat. Read this FIRST before doing any work.

**Agent Identity Format:** When you work on this project, identify yourself as:  
`Agent: <your-agent-name> (model: <your-model-id>)`

---
struct ProjectOverview {
  name: "Home-Automation-SoC",
  root: "D:\\Home-Automation-SoC",
  host: "Home Assistant + Claude voice assistant (off-chip)",
  core: "Custom RV32IM (`rtl/rtl_top/riscv_core.sv`) — not Ibex",
  package: "QFN-64",
  process: "SkyWater 130nm (sky130) — PDK downloaded, OpenLane not installed",
}
---
plain-language summary of the latest session (2026-11-12, session 5):
- Closed the last regression failure. Regression is now PASS 17/17 (exit 0).
- Root cause 1 (firmware): main.c armed the watchdog with CTRL=0x01, i.e. counter
  enable only. Bit 1 is reset-enable, so reset_n_out could never assert and the
  SoC never reset. Now armed with WDOG_CTRL_ARMED (0b11) via named constants,
  and delay() pets every 4,096 cycles (the old 0xFFFF mask was unreachable in a
  50,000-cycle delay).
- Root cause 2 (bench): tb_firmware compared all 16 GPIO bits, but GPIO[15:1]
  are high-Z, so `!=` was X and no LED edge was ever counted. It now counts
  two-state edges of GPIO[0].
- Measured in the C demo: watchdog expiry at 20.005 ms, 16-cycle rst_sys_n pulse
  from reset_ctrl, firmware reboots from the boot ROM, GPIO0 blinks again.
  35.7 ms of simulated time, ~1 min wall clock.
- Still NOT proven: image authentication (boot.c fails closed by design), flash
  programming, OTA, retention across reset, CDC/formal.
- LICENSE is still an explicit placeholder.
- Toolchain present: /d/tools/xpack-riscv-none-elf-gcc-12.2.0-2/bin
  (gcc 12.2.0; readelf/objdump 2.38). C firmware build uses
  scripts/fw_build/build_fw.js; Python is not available.
- Icarus 14.0 simulates; Verilator 5.053 is lint-only here.
- 2026-11-12 toolchain reconciliation: every EDA tool now lives under D:\tools
  (see D:\tools\EDA_TOOL_REGISTRY.md). README/TECH_STACK/AGENTS/resume and the
  reports were corrected where they still said g++/make, OpenLane 2, KiCad,
  SymbiYosys, cocotb or the RISC-V toolchain were missing.
  Re-verified directly: g++ 16.1.0, make 4.4.1, verible v0.0-4298, kicad-cli
  10.0.8, SBY v0.69, Verilator 5.053, yowasp-yosys 0.70, Python 3.10.11,
  riscv-none-elf-gcc 12.2.0. Magic/Netgen/OpenROAD/OpenSTA/KLayout/volare are
  WSL-only and were not re-run — those entries stay DOCUMENTED from the registry.
---

AGENTS.md session log being mirrored below:

## 13. SESSION LOG 5 — Buffy (closing the last regression failure)

Agent: Buffy (model: DeepSeek V4.1 Flash) — session of 2026-11-12.

Scope I took: make the one remaining failing regression entry,
`firmware (C demo)`, actually pass — or record honestly why it cannot.

Two independent causes:
1. Firmware armed the watchdog without its reset output: main.c wrote
   REG_WDOG_CTRL = 0x01. Bit 0 enables the counter, bit 1 (reset_en) gates
   reset_n_out = ~(expired && reset_en). With only bit 0 the counter expired and
   raised irq, but reset_n_out stayed high, so reset_ctrl never saw a timeout and
   wdog_reset_n never pulsed. Now armed with WDOG_CTRL_ARMED (enable |
   reset-enable) through named constants, and delay() pets every 4,096 cycles.
2. The bench could not count LED edges: it compared all 16 GPIO bits while
   GPIO[15:1] are high-Z, and `!=` on a vector containing z is x, so the
   condition was false for every real edge. It now counts two-state edges of
   GPIO[0] and traces rst_sys_n transitions with the watchdog state.

Measured result:

  export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"
  node scripts/eda/run_regression.js

  PASS 17 / 17        (exit 0)

  [fw] 20005090000 watchdog reset asserted
  [rst] 20005090000 rst_sys_n=0 timeout=1 en=1 ld=1000000 cnt=0 exp=1
  [fw] 20005410000 watchdog reset released
  [rst] 20005410000 rst_sys_n=1 timeout=0 en=0 ld=0 cnt=0 exp=0
  [fw] 35721390000 blink observation done: gpio toggles 2
  [fw] RESULT: PASS

Still NOT proven: image authentication (boot.c fails closed by design), flash
programming, OTA, retention across reset, CDC/formal verification.

Files changed: firmware/bare_metal/main.c, sim/sim_top/tb_firmware.v, build/fw/*
(regenerated), README.md, AGENTS.md, resume.md, .agents/OWNED-BY-BUFFY.md.

---

## 12. SESSION LOG 4 — Buffy (documentation refresh)

> Superseded by Section 13: the 16/17 result below was accurate then, it is 17/17 now.

Agent: Buffy (model: Solar Pro4) — session of 2026-11-11 (fourth), continuing
from a paused Phase-2 run where `tb_firmware.v` still timed out at 120 ms with
`wdog pulses 0`.

Scope I took: (1) re-run the full regression and record the result honestly;
(2) rewrite `docs/architecture/SYSTEM_BLOCK_DIAGRAM.md` as both a Mermaid diagram
and an ASCII block diagram that matches the actual RTL, not the originally
proposed Ibex block; (3) refresh `README.md` and `AGENTS.md` so status, evidence,
and commands all point at measured reality and are searchable on GitHub.

Measured regression result (re-run this session):

  export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"
  node scripts/eda/run_regression.js

  PASS 16 / 17
  FAIL  firmware (C demo)  [exit 1]

The 16 passing entries are unchanged from the prior measured run: isa, boot,
uart, reset_ctrl, power_mgr, clint, plic, gpio, spi, i2c, pwm, timer,
watchdog, i2s, sram, debug_jtag. The one remaining failure is firmware (C demo)
— tb_firmware.v boots the C image, prints the full banner, receives the UART r
command and echoes Cmd: r / Reboot requested, but does NOT observe a watchdog
reset pulse within the 120 ms hang guard (wdog pulses 0). The block-level pieces
are proven separately (reset_ctrl 15/15, uart 153/153, boot 7/7), so the open
item is the integration/observation in tb_firmware.v, not a fresh RTL defect.

Files changed this session: docs/architecture/SYSTEM_BLOCK_DIAGRAM.md,
README.md, AGENTS.md, resume.md, .agents/OWNED-BY-BUFFY.md. Nothing committed.

