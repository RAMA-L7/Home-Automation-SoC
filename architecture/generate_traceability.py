#!/usr/bin/env python3
"""Generate architecture/requirements_traceability.csv from the SRS.

Stage 1 artifact. Read-only on the SRS; writes only the Stage 1 CSV.
Run: python3 architecture/generate_traceability.py
"""
import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "requirements" / "system_requirements.md"
OUT = ROOT / "architecture" / "requirements_traceability.csv"

rows = []
for line in SRC.read_text(encoding="utf-8-sig").splitlines():
    m = re.match(r"\|\s*\*\*((?:FR|NFR|IF)-[A-Z]+-\d+)\*\*\s*\|(.*)\|", line)
    if m:
        rid = m.group(1)
        cols = [c.strip() for c in m.group(2).split("|")]
        text = cols[0]
        if rid.startswith("NFR"):
            pri = "Target"
            ver = cols[2] if len(cols) > 2 else ""
        else:
            pri = cols[1] if len(cols) > 1 and cols[1] else "Mandatory"
            ver = cols[2] if len(cols) > 2 else ""
        rows.append((rid, text, pri, ver))
    m = re.match(r"\|\s*\*\*(VR-\d+)\*\*\s*\|(.*)\|", line)
    if m:
        cols = [c.strip() for c in m.group(2).split("|")]
        rows.append((m.group(1), cols[0], "Mandatory", cols[1] if len(cols) > 1 else ""))

seen = {}
out = []
for rid, text, pri, ver in rows:
    if rid in seen:
        seen[rid] += 1
        rid = f"{rid}-DUP{seen[rid]}"
    else:
        seen[rid] = 1
    out.append((rid, text, pri, ver))

DEFAULT = {
    "FR-PROC": ("PARTIAL", "riscv_core", "Core is custom RV32IM, not Ibex; C/user/PMP absent"),
    "FR-MEM": ("PARTIAL", "sram/boot_rom/qspi_flash_ctrl", "Inferred arrays; ROM/SRAM sizes disagree with map; no macro"),
    "FR-BUS": ("IMPLEMENTED", "axi_lite_interconnect/axi_lite_to_apb", "Fabric and bridge exercised by 22/22 regression"),
    "FR-PER": ("PARTIAL", "peripherals", "Peripheral feature set is a subset of the requirement"),
    "FR-SEC": ("NOT_IMPLEMENTED", "none", "No crypto/TRNG/OTP; boot fails closed"),
    "FR-CLK": ("NOT_IMPLEMENTED", "has_soc", "Single gated 50 MHz clock; no 25 MHz divider or 32 kHz AON"),
    "FR-RST": ("PARTIAL", "reset_ctrl", "Reset pin and watchdog pulse exist; no PMIC sequencing or per-peripheral reset"),
    "FR-PWR": ("NOT_IMPLEMENTED", "power_mgr", "Clock gating only; no power domains/retention"),
    "FR-EXT": ("NOT_IMPLEMENTED", "has_soc", "No UART1/RF_CTRL pins or mux"),
    "FR-DBG": ("PARTIAL", "debug_jtag", "TAP subset; no DMI/IDCODE"),
    "NFR-PERF": ("NOT_VERIFIED", "full SoC", "No full-SoC implementation or STA"),
    "NFR-PWR": ("NOT_VERIFIED", "full SoC", "No power measurement or power intent"),
    "NFR-AREA": ("ESTIMATED", "full SoC", "Only estimates; macro tiling exceeds target"),
    "NFR-ENV": ("NOT_VERIFIED", "package/board", "No qualification or board"),
    "NFR-QUA": ("BLOCKED", "full SoC", "No DFT/ATPG/IR/EM tooling"),
    "IF-PIN": ("PARTIAL", "has_soc/padring", "Package spec exists; RTL pin list does not fit"),
    "IF-ELE": ("NOT_IMPLEMENTED", "padring", "No pad ring or voltage domains"),
    "IF-COM": ("PARTIAL", "peripherals", "Protocols are subsets"),
    "IF-SW": ("PARTIAL", "firmware", "Bare-metal only; no Zephyr/TLS/OTA"),
    "VR": ("NOT_STARTED", "verification env", "Method defined but not executed at full SoC"),
}

OVR = {
    "FR-PROC-001": ("PARTIAL", "Custom RV32IM core instead of Ibex; C extension absent"),
    "FR-PROC-002": ("PARTIAL", "50 MHz is a pad frequency assumption; no PLL or full-chip STA"),
    "FR-PROC-003": ("NOT_IMPLEMENTED", "Machine mode only; no U mode or privileged 1.12"),
    "FR-PROC-004": ("NOT_IMPLEMENTED", "No PMP"),
    "FR-PROC-005": ("PARTIAL", "WFI is a NOP; clock gating is entered via PMM register only"),
    "FR-MEM-001": ("PARTIAL", "RTL array is 256 KB; 128 KB mapped; no macro"),
    "FR-MEM-002": ("PARTIAL", "32 KB inferred array; not direct-to-core zero-wait"),
    "FR-MEM-003": ("PARTIAL", "RTL array is 64 KB; 16 KB mapped; not immutable mask ROM"),
    "FR-MEM-004": ("PARTIAL", "Single-line 0x03 read; no quad/DDR/XIP; 24-bit address aliases 64 MB"),
    "FR-MEM-005": ("PARTIAL", "RTL decode consistent internally; docs use a different peripheral order"),
    "FR-MEM-006": ("NOT_IMPLEMENTED", "No ECC"),
    "FR-BUS-004": ("PARTIAL", "Bridge latency not measured against the 2-cycle target"),
    "FR-PER-001": ("PARTIAL", "One UART; no FIFO; 16550 subset"),
    "FR-PER-002": ("PARTIAL", "Single-byte I2C; no clock stretching; no device model"),
    "FR-PER-003": ("PARTIAL", "SPI mode 0 only; one CS; no DDR"),
    "FR-PER-004": ("PARTIAL", "16 GPIO without pull/drive/alternate-function control"),
    "FR-PER-005": ("IMPLEMENTED", "4x16-bit PWM implemented and tested"),
    "FR-PER-006": ("PARTIAL", "I2S TX 16-bit only; no RX/master-slave selection"),
    "FR-PER-007": ("PARTIAL", "One APB timer plus CLINT; second timer absent"),
    "FR-PER-008": ("NOT_IMPLEMENTED", "No LPTIM/AON timer"),
    "FR-PER-009": ("PARTIAL", "PLIC has 8 sources, not >=32"),
    "FR-PER-010": ("IMPLEMENTED", "CLINT implemented with non-standard 4 KB offsets"),
    "FR-SEC-001": ("NOT_IMPLEMENTED", "Boot verifier fails closed; no ECDSA"),
    "FR-SEC-002": ("NOT_IMPLEMENTED", "No SHA-256 measurement"),
    "FR-SEC-003": ("NOT_IMPLEMENTED", "No TRNG/OTP/DUK"),
    "FR-SEC-004": ("NOT_IMPLEMENTED", "No AES engine"),
    "FR-SEC-005": ("NOT_IMPLEMENTED", "No SHA engine"),
    "FR-SEC-006": ("NOT_IMPLEMENTED", "No TRNG"),
    "FR-SEC-006-DUP2": ("NOT_IMPLEMENTED", "OTA verification absent; OTA stub"),
    "FR-SEC-007": ("NOT_IMPLEMENTED", "No rollback counter/OTP"),
    "FR-SEC-008": ("NOT_IMPLEMENTED", "No fuse-based debug lock"),
    "FR-CLK-001": ("PARTIAL", "External 50 MHz pin only; no PLL; ARC-041 external source"),
    "FR-CLK-002": ("NOT_IMPLEMENTED", "Peripheral is a gated 50 MHz copy; no /2"),
    "FR-CLK-003": ("NOT_IMPLEMENTED", "QSPI SCK divider only; no 12.5/50 MHz DDR scheme"),
    "FR-CLK-004": ("NOT_IMPLEMENTED", "No 32 kHz AON clock"),
    "FR-CLK-005": ("PARTIAL", "Two domain gates only; no per-peripheral enables"),
    "FR-RST-001": ("PARTIAL", "reset_n and reset_ctrl; no PMIC multi-stage POR"),
    "FR-RST-002": ("PARTIAL", "Watchdog resets whole system; no software core reset"),
    "FR-RST-003": ("NOT_IMPLEMENTED", "No per-peripheral reset registers"),
    "FR-PWR-001": ("NOT_IMPLEMENTED", "Single 1.8 V SoC; domains are board-level only"),
    "FR-PWR-002": ("NOT_IMPLEMENTED", "PMIC is board-level; no SoC interface"),
    "FR-PWR-003": ("NOT_IMPLEMENTED", "No power gating; <1 mW unverified"),
    "FR-PWR-004": ("PARTIAL", "Only external wake_ack; no GPIO/LPTIM/PMIC wake"),
    "FR-PWR-005": ("NOT_VERIFIED", "No wake latency measurement"),
    "FR-PWR-006": ("NOT_IMPLEMENTED", "No brown-out/power-loss detect"),
    "FR-DBG-001": ("PARTIAL", "TAP subset; no IDCODE/DMI"),
    "FR-DBG-002": ("NOT_IMPLEMENTED", "No SWD"),
    "FR-DBG-003": ("IMPLEMENTED", "UART0 console at 115200 8N1"),
    "NFR-PERF-001": ("PARTIAL", "Target only; no full-SoC STA at 50 MHz"),
    "NFR-PERF-006": ("FAILED", "Single-line QSPI at 50 MHz is ~6.25 MB/s; target is >=20 MB/s"),
    "NFR-PERF-007": ("NOT_IMPLEMENTED", "No AES"),
    "NFR-PERF-008": ("NOT_IMPLEMENTED", "No SHA"),
    "NFR-AREA-001": ("AT_RISK", "Tiling 4 KB macros for 176 KB needs ~31.8 mm2"),
    "NFR-QUA-001": ("BLOCKED", "No scan/ATPG"),
    "NFR-QUA-002": ("BLOCKED", "No MBIST"),
    "NFR-QUA-003": ("PARTIAL", "Timer block DRC 0; no LVS/full chip"),
    "IF-PIN-002": ("FAILED", "RTL exposes 81 pad signals for 56 usable I/O"),
    "IF-PIN-004": ("PARTIAL", "CSV includes pins absent from RTL and omits ext_irq"),
    "IF-ELE-006": ("NOT_IMPLEMENTED", "sky130hd is 1.8 V; no 3.3 V tolerant pads"),
    "IF-ELE-008": ("PARTIAL", "No XTAL pins; single clock input"),
    "IF-COM-001": ("IMPLEMENTED", "115200 8N1 UART"),
    "IF-COM-002": ("NOT_IMPLEMENTED", "No UART1"),
    "IF-COM-003": ("PARTIAL", "400 kHz capable; no stretch/device test"),
    "IF-COM-004": ("PARTIAL", "Single-line mode 0; no quad/DDR"),
    "IF-COM-005": ("PARTIAL", "Mode 0 at <=25 MHz possible; no CS1"),
    "IF-COM-006": ("PARTIAL", "I2S TX 16-bit; 24/32-bit modes absent"),
    "IF-SW-001": ("PARTIAL", "RV32IM, not RV32IMC"),
    "IF-SW-003": ("NOT_IMPLEMENTED", "No Zephyr port"),
    "IF-SW-004": ("NOT_IMPLEMENTED", "No Mbed TLS/PSA"),
    "IF-SW-005": ("PARTIAL", "Boot chain exists but no secure verify"),
    "IF-SW-006": ("NOT_IMPLEMENTED", "OTA stub"),
    "IF-SW-007": ("PARTIAL", "JTAG TAP only; no OpenOCD DMI"),
    "VR-001": ("PARTIAL", "Icarus 22/22; Verilator not in current gate"),
    "VR-002": ("PARTIAL", "5 block proofs; CDC plan blocked"),
    "VR-003": ("NOT_STARTED", "No FPGA"),
    "VR-004": ("NOT_STARTED", "No Zephyr tests"),
    "VR-005": ("NOT_STARTED", "No Renode/HW"),
    "VR-006": ("NOT_STARTED", "No power bench"),
    "VR-007": ("NOT_STARTED", "No EMC scan"),
    "VR-008": ("NOT_STARTED", "No ASIC signoff"),
}

BLOCK = {
    "FR-PROC": "Core", "FR-MEM": "Memory", "FR-BUS": "Bus", "FR-PER": "Peripherals",
    "FR-SEC": "Security", "FR-CLK": "Clock", "FR-RST": "Reset", "FR-PWR": "Power",
    "FR-EXT": "External interfaces", "FR-DBG": "Debug", "NFR-PERF": "Performance",
    "NFR-PWR": "Power", "NFR-AREA": "Physical/area", "NFR-ENV": "Environmental",
    "NFR-QUA": "DFT/signoff", "IF-PIN": "Package", "IF-ELE": "Electrical",
    "IF-COM": "Peripherals", "IF-SW": "Software", "VR": "Verification",
}
STAGE = {
    "FR-PROC": 2, "FR-MEM": 3, "FR-BUS": 3, "FR-PER": 2, "FR-SEC": 2, "FR-CLK": 2,
    "FR-RST": 2, "FR-PWR": 2, "FR-EXT": 2, "FR-DBG": 2, "NFR-PERF": 15, "NFR-PWR": 15,
    "NFR-AREA": 9, "NFR-ENV": 18, "NFR-QUA": 16, "IF-PIN": 9, "IF-ELE": 10,
    "IF-COM": 2, "IF-SW": 4, "VR": 4,
}

with OUT.open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["requirement_id", "requirement_text", "priority", "architecture_block",
                "rtl_module", "verification_method", "current_evidence", "status",
                "gap", "proposed_resolution", "downstream_stage"])
    for rid, text, pri, ver in out:
        g = "VR" if rid.startswith("VR") else "-".join(rid.split("-")[:2])
        st, mod, gap = DEFAULT.get(g, ("NOT_VERIFIED", "unknown", "No mapping"))
        if rid in OVR:
            ov = OVR[rid]
            if len(ov) == 3:
                st, mod, gap = ov
            else:
                st, gap = ov
        res = "Retain and regression-protect"
        if st != "IMPLEMENTED":
            res = "Implement per the approved Stage 1 baseline and re-verify"
        if st in ("NOT_IMPLEMENTED", "NOT_STARTED"):
            res = "Implement or obtain owner-approved descope before this stage"
        if st == "BLOCKED":
            res = "Resolve tool/DFT dependency or approve waiver"
        if st == "FAILED":
            res = "Redesign to meet the requirement or re-baseline the requirement"
        w.writerow([rid, text, pri, BLOCK.get(g, ""), mod, ver or "Review",
                    "Stage 0 audit + Stage 1 docs", st, gap, res, STAGE.get(g, "")])

print(f"wrote {len(out)} requirements to {OUT}")
