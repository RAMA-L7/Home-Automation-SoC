#!/usr/bin/env python3
"""
Home-Automation-SoC — rewrite the diagram sections of README.md.

Replaces the Mermaid block and the ASCII block between their headings with
the current, accurate versions, then injects the generated ASCII art.

    python scripts/docs/sync_readme_diagram.py
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gen_block_diagram import build  # noqa: E402

BEGIN = "<!-- BEGIN GENERATED BLOCK DIAGRAM -->"
END = "<!-- END GENERATED BLOCK DIAGRAM -->"

MERMAID = """```mermaid
graph TB
    %% ---- External interfaces ----
    subgraph External["External Interfaces"]
        UART[UART0 / UART1<br/>115200 baud]
        SPI[SPI + QSPI Master<br/>Mode 0/3, up to 50 MHz]
        I2C[I²C Master<br/>100k / 400k / 1M Hz]
        GPIO[GPIO 16-bit<br/>3.3V tolerant]
        PWM[PWM 4-ch<br/>16-bit resolution]
        I2S[I²S Transmit<br/>Master / Slave]
        JTAG[JTAG Debug TAP<br/>TCK / TMS / TDI / TDO]
        WDOG[Watchdog Reset Out]
        WAKE[Wake Req / Ack]
    end

    %% ---- SoC ----
    subgraph SoC["Home-Automation-SoC — RV32IM, QFN-64, sky130"]
        direction TB

        subgraph Core_Cluster["Processing Subsystem"]
            CORE["RV32IM CORE<br/>riscv_core.sv<br/>multi-cycle · machine mode<br/>CSRs · traps · M extension<br/>no C-ext · no user mode · no PMP"]
            FETCHMUX{{"Instruction Fetch Mux<br/>ROM / TCM / SRAM<br/>out-of-range to fault"}}
            ROM[Boot ROM 16 KB<br/>0x0000_0000]
            TCM[TCM 32 KB<br/>0x0001_0000]
            SRAM[SRAM 128 KB<br/>0x2000_0000]
        end

        subgraph Bus["Bus Fabric — single outstanding transaction"]
            REQ["req/gnt to AXI4-Lite<br/>req_gnt_to_axi_lite"]
            AXI["AXI4-Lite Interconnect<br/>1 master x 6 slaves"]
            APB["AXI4-Lite to APB Bridge<br/>9 x 4 KB slots, one-hot"]
            INTC["INTc — CLINT + PLIC mux<br/>addr[12] selects"]
        end

        subgraph Peripherals["Peripherals"]
            CLINT[CLINT<br/>MTIME · MTIMECMP · MSIP]
            PLIC[PLIC<br/>8 sources · 1 context]
            GPIO_PERIPH[GPIO 16-bit]
            UART_PERIPH[UART0 / UART1]
            I2C_PERIPH[I²C Controller]
            SPI_PERIPH[SPI Controller]
            PWM_PERIPH[PWM 4-ch]
            TIMER_PERIPH[Timer]
            WATCHDOG[Watchdog Timer]
            I2S_PERIPH[I²S Controller]
            QSPI_PERIPH[QSPI Flash Controller<br/>0x4000_0000]
            PWR_MGR[Power Manager<br/>0x5000_8000]
            DEBUG_JTAG[Debug JTAG TAP]
        end

        subgraph Power["Power & Reset"]
            RESET_CTRL["Reset Controller<br/>watchdog to 16-cycle reset pulse"]
            CLOCK_GEN["Clock Generation<br/>50 MHz system clock"]
        end
    end

    %% ---- External wiring ----
    UART ---|UART| UART_PERIPH
    SPI ---|SPI / QSPI| QSPI_PERIPH
    I2C ---|I2C| I2C_PERIPH
    GPIO ---|GPIO| GPIO_PERIPH
    PWM ---|PWM| PWM_PERIPH
    I2S ---|I2S| I2S_PERIPH
    JTAG ---|JTAG| DEBUG_JTAG
    WDOG ---|WDOG| WATCHDOG
    WAKE ---|WAKE| PWR_MGR

    %% ---- Core cluster ----
    CORE -->|fetch / data| FETCHMUX
    FETCHMUX --> ROM
    FETCHMUX --> TCM
    FETCHMUX --> SRAM
    CORE -->|req/gnt| REQ

    %% ---- Bus fabric ----
    REQ --> AXI
    AXI -->|slave 0| ROM
    AXI -->|slave 1| TCM
    AXI -->|slave 2| SRAM
    AXI -->|slave 3| QSPI_PERIPH
    AXI -->|slave 4| APB
    AXI -->|slave 5| INTC
    APB -->|APB| GPIO_PERIPH
    APB -->|APB| UART_PERIPH
    APB -->|APB| I2C_PERIPH
    APB -->|APB| SPI_PERIPH
    APB -->|APB| PWM_PERIPH
    APB -->|APB| TIMER_PERIPH
    APB -->|APB| WATCHDOG
    APB -->|APB| I2S_PERIPH
    APB -->|APB| PWR_MGR
    APB -->|APB| DEBUG_JTAG
    INTC -->|addr[12]=0| CLINT
    INTC -->|addr[12]=1| PLIC

    %% ---- Power ----
    RESET_CTRL -->|reset| CORE
    CLOCK_GEN -->|clk| CORE
    CLOCK_GEN -->|clk| AXI
    PWR_MGR -.->|clock gate| CORE
    WATCHDOG -.->|timeout| RESET_CTRL

    %% ---- Interrupt path ----
    PLIC -.->|irq| CORE
    CLINT -.->|software / timer irq| CORE
```
"""


def main():
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    readme = os.path.join(root, "README.md")
    diagram = os.path.join(root, "docs", "architecture", "BLOCK_DIAGRAM.txt")

    art = build()

    with open(readme, "r", encoding="utf-8") as fh:
        lines = fh.read().split("\n")

    # ---- 1. replace the Mermaid block -------------------------------------
    try:
        m_start = lines.index("```mermaid")
    except ValueError:
        raise SystemExit("README.md: no ```mermaid block found")
    m_end = lines.index("```", m_start + 1)
    lines[m_start:m_end + 1] = MERMAID.rstrip("\n").split("\n")

    # ---- 2. replace the ASCII block ---------------------------------------
    try:
        a_start = lines.index("### ASCII Block Diagram")
    except ValueError:
        raise SystemExit("README.md: no '### ASCII Block Diagram' heading found")

    # find the end of the fenced code block that follows the heading
    fence = None
    for i in range(a_start, len(lines)):
        if lines[i].startswith("```"):
            fence = i
            break
    if fence is None:
        raise SystemExit("README.md: ASCII diagram has no fenced code block")
    close = fence + 1
    while close < len(lines) and not lines[close].startswith("```"):
        close += 1
    if close >= len(lines):
        raise SystemExit("README.md: ASCII diagram fence is not closed")

    block = [
        BEGIN,
        "<!-- Generated by scripts/docs/gen_block_diagram.py - do not edit by hand -->",
        "<!-- Source of truth: rtl/rtl_top/has_soc.sv, has_addr_map.sv, intc_axi.sv -->",
        "",
        "```text",
        art,
        "```",
        END,
    ]
    lines[fence:close + 1] = block

    with open(readme, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines))

    with open(diagram, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(art + "\n")

    print(f"[updated] {readme}")
    print(f"[written] {diagram}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
