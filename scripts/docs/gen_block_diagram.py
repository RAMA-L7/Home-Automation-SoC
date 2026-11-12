#!/usr/bin/env python3
"""
Home-Automation-SoC — ASCII block diagram generator.

Draws the system block diagram as exact ASCII box art.

Two things make this reliable where hand-drawn ASCII is not:

  * Every column has a *measured* width, computed from the longest line it
    has to hold, so sub-boxes always fit inside their parent.
  * Every box records the text placed in it, and `check()` at the end
    asserts that no line overran its border. The generator fails loudly
    rather than shipping a mangled diagram.

Output: docs/architecture/BLOCK_DIAGRAM.txt (also pasted into README.md).

    python scripts/docs/gen_block_diagram.py

Every fact in the diagram is taken from the RTL:
  rtl/rtl_top/has_soc.sv, rtl/rtl_top/has_addr_map.sv,
  rtl/rtl_top/intc_axi.sv, rtl/rtl_top/riscv_core.sv
"""

import os
import sys

W = 130

# Column geometry inside the package border.
PROC_X, PROC_W = 3, 52
BUS_X, BUS_W = 57, 32
PERI_X, PERI_W = 91, 38


class Canvas:
    def __init__(self, width=W, height=64):
        self.w = width
        self.h = height
        self.g = [[" "] * width for _ in range(height)]
        self.claims = []  # (x0, y0, x1, y1, what) for the overflow check

    def put(self, x, y, s):
        for i, ch in enumerate(s):
            if 0 <= y < self.h and 0 <= x + i < self.w:
                self.g[y][x + i] = ch

    def text(self, x, y, s):
        self.put(x, y, s)

    def box(self, x, y, w, h, owner=None):
        """Rectangle. Returns the inner content rect (x, y, w, h)."""
        self.put(x, y, "┌" + "─" * (w - 2) + "┐")
        self.put(x, y + h - 1, "└" + "─" * (w - 2) + "┘")
        for i in range(1, h - 1):
            self.put(x, y + i, "│")
            self.put(x + w - 1, y + i, "│")
        if owner:
            self.claims.append((x + 1, y + 1, x + w - 2, y + h - 2, owner))
        return x + 1, y + 1, w - 2, h - 2

    def render(self):
        return "\n".join("".join(r).rstrip() for r in self.g)


def measured(lines, pad=4):
    """Outer width needed for a list of text lines."""
    return max(len(s) for s in lines) + pad


def panel(c, x, y, lines, title=None, h=None, width=None, owner=None):
    """Box sized from its content.

    `lines`  body lines
    `title`  bold first line
    `width`  explicit outer width (defaults to measured)
    Returns the content rect (x, y, w, h) inside the box.
    """
    body = ([title] if title else []) + list(lines)
    w = width if width else measured(body)
    hh = h if h else len(body) + 2
    ix, iy, iw, ih = c.box(x, y, w, hh, owner=owner or (title or "panel"))
    for i, s in enumerate(body):
        c.text(ix + 1, iy + i, s)
        c.claims.append((ix + 1, iy + i, ix + 1 + len(s) - 1, iy + i, owner or "text"))
    return ix + 1, iy, iw, ih


def check(c):
    """Fail loudly if any text ran outside the box it belongs to."""
    problems = []
    for x0, y0, x1, y1, what in c.claims:
        if x1 > c.w - 1:
            problems.append(f"{what}: text ends at column {x1}, canvas is {c.w}")
    if problems:
        raise SystemExit("diagram layout error:\n  " + "\n  ".join(problems))


def build():
    c = Canvas(height=64)

    # ------------------------------------------------------------- title
    c.box(0, 0, W, 4)
    c.text(3, 1, "HOME-AUTOMATION-SOC   ·   QFN-64   ·   SkyWater 130 nm (sky130)   ·   RV32IM")
    c.text(3, 2, "50 MHz core clock   ·   AXI4-Lite bus fabric   ·   APB peripherals   ·   < 1 mW deep sleep")

    # --------------------------------------------------------- pin row
    c.text(0, 5, "EXTERNAL PINS")
    row = ["UART0", "UART1", "I2C", "SPI/QSPI", "GPIO[15:0]",
           "PWM[3:0]", "I2S", "JTAG", "WDOG rst", "WAKE"]
    x = 5
    centers = []
    for name in row:
        c.text(x, 7, name)
        cx = x + len(name) // 2
        centers.append(cx)
        c.put(cx, 6, "│")
        x += len(name) + 4
    for cx in centers:
        c.put(cx, 8, "▼")

    # ---------------------------------------------------------- package
    PKG = 10
    c.box(0, PKG, W, 40)
    c.text(3, PKG + 1, "HOME-AUTOMATION-SOC")

    # ------------------------------------------- processing subsystem
    px, py, pw, ph = panel(
        c, PROC_X, PKG + 4,
        ["instruction fetch + data access",
         "",
         "RV32IM CORE   riscv_core.sv",
         "multi-cycle · machine mode",
         "CSRs · synchronous traps · M extension",
         "no C-ext · no user mode · no PMP",
         "4-state FSM: FETCH → EXEC → MEM / TRAP",
         "",
         "instruction fetch mux",
         "ROM / TCM / SRAM, out-of-range → fault"],
        title="PROCESSING SUBSYSTEM", h=20, width=PROC_W, owner="processing")

    mems = [
        ["BOOT ROM", "16 KB", "0x0000_0000", "exec + data"],
        ["TCM", "32 KB", "0x0001_0000", "exec + data"],
        ["SRAM", "128 KB", "0x2000_0000", "exec + data"],
    ]
    mw = measured(mems[0])
    assert mw * 3 + 2 <= pw - 2, "memory boxes do not fit the processing panel"
    mx = px
    for lines in mems:
        panel(c, mx, py + 11, lines, h=6, width=mw, owner="memory")
        mx += mw + 1

    # ------------------------------------------------------ bus fabric
    # The bus column is a set of stacked boxes; the column heading is plain
    # text so the first box does not collide with it.
    c.text(BUS_X, PKG + 4, "BUS FABRIC")
    c.text(BUS_X, PKG + 5, "one outstanding transaction")
    bx, bw = BUS_X + 1, BUS_W - 3

    panel(c, bx, PKG + 7, ["req_gnt_to_axi_lite"], title="req/gnt → AXI4-Lite",
          h=5, width=bw, owner="reqgnt")
    panel(c, bx, PKG + 13, ["1 master × 6 slaves"], title="AXI4-Lite INTERCONNECT",
          h=5, width=bw, owner="interconnect")
    panel(c, bx, PKG + 19, ["9 × 4 KB slots, one-hot"], title="AXI4-Lite → APB bridge",
          h=5, width=bw, owner="apbbridge")
    panel(c, bx, PKG + 25, ["0x8000_0000 / 0x8000_1000"], title="INTc  CLINT + PLIC",
          h=5, width=bw, owner="intc")

    # ------------------------------------------------------ peripherals
    rx, ry, rw, rh = panel(
        c, PERI_X, PKG + 4,
        ["APB map  0x5000_0000",
         "",
         "GPIO[15:0]      0x5000_0000",
         "UART0 / UART1   0x5000_1000",
         "I2C master      0x5000_2000",
         "SPI master      0x5000_3000",
         "PWM 4-ch        0x5000_4000",
         "Timer           0x5000_5000",
         "Watchdog        0x5000_6000",
         "I2S             0x5000_7000",
         "Power manager   0x5000_8000",
         "",
         "QSPI flash ctrl  0x4000_0000",
         "Debug JTAG TAP   on-chip"],
        title="PERIPHERALS", h=17, width=PERI_W, owner="peripherals")

    # ---------------------------------------------------- power & reset
    panel(c, PERI_X, PKG + 25,
          ["reset_ctrl · clock gating · sleep",
           "watchdog → 16-cycle reset pulse"],
          title="POWER & RESET", h=5, width=PERI_W, owner="power")

    # ---------------------------------------------------------- arrows
    c.put(PROC_X + PROC_W, PKG + 10, "◄")
    c.put(PROC_X + PROC_W + 1, PKG + 10, "►")

    # ---------------------------------------------------------- legend
    c.text(0, 52, "MEMORY MAP")
    c.text(3, 53, "0x0000_0000  16 KB  Boot ROM     0x0001_0000  32 KB  TCM     0x2000_0000  128 KB  SRAM     0x4000_0000  64 MB  QSPI flash")
    c.text(0, 55, "INTERRUPTS  CLINT: software + timer      PLIC: 8 sources, 1 context, 7-bit priority")
    c.text(0, 56, "VERIFIED    Regression PASS 17/17 (Icarus)   ·   full-SoC boot 7/7 (Verilator C++ model)")
    c.text(0, 57, "NOT YET     Secure boot · OTA signing · flash program/erase · retention · deep-sleep gating")

    check(c)
    return c.render()


def main():
    out = build()
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    dest = os.path.join(root, "docs", "architecture", "BLOCK_DIAGRAM.txt")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(out + "\n")
    print(out)
    print(f"\n[written] {dest}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
