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
plain-language summary of the latest session:
- Re-ran the regression: PASS 16/17, with `firmware (C demo)` the one FAIL
  (tb_firmware boots, prints the banner, receives UART 'r', but watchdog
  pulse still not observed; wdog pulses 0, 120 ms timeout).
- Rewrote SYSTEM_BLOCK_DIAGRAM.md as Mermaid + ASCII that matches the
  implemented RTL, plus an explicit NOT IMPLEMENTED list.
- Refreshed README.md and AGENTS.md so status, evidence, commands, and
  GitHub-searchable keywords all match measured reality.
- Wrote resume.md as a one-paragraph redo/index for onboarding.
- Mirrored SESSION LOG 4 into this .agents/OWNED-BY-BUFFY.md file.
- All changes are documentation only this session; no RTL/firmware/tb fix
  was made that would convert the firmware FAIL into PASS.
- Working tree uncommitted on top of 2a0c42c; LICENSE still a placeholder.
- Toolchain present: /d/tools/xpack-riscv-none-elf-gcc-12.2.0-2/bin
  (gcc 12.2.0; readelf/objdump 2.38). C firmware build uses
  scripts/fw_build/build_fw.js; Python is not available.
- Icarus 14.0 simulates; Verilator 5.053 is lint-only here (no g++/make).
- Owned files changed since snapshot: 11 of 228.
---

AGENTS.md session log being mirrored below:

## 12. SESSION LOG 4 — Buffy (documentation refresh)

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

