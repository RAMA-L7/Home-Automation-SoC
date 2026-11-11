# Phase 1A Human Approval Checklist

This checklist extracts the decisions that require explicit human approval and explains each in plain technical language along with the potential consequences of approving or rejecting them.

---

## A. Processor & ISA
| Decision | What will approving mean? | Consequence of rejection |
|----------|---------------------------|--------------------------|
| **ARC‑001 (Processor selection)** | Approve Ibex (RV32IMC) as the processor.  All downstream bus, memory, and power decisions are built around it. | Must switch to a different core (e.g., CV32E40P or VexRiscv), which would cascade changes to bus adapters, interrupt controller, and mailbox interfaces.

## B. Bus & Adapters
| Decision | What will approving mean? | Consequence of rejection |
|----------|---------------------------|--------------------------|
| **ARC‑002 (Bus architecture)** | Approve AXI4‑Lite as system bus and APB for peripherals. | Must redefine core‑to‑memory path (e.g., open‑source Wishbone) and redesign peripheral bus.
| **ARC‑011 & ARC‑012 (Adapter Chain)** | Approve LiteX ibex_axi_bridge and pb_bridge. | Bus signals incompatible with Ibex; would need custom bridge design.

## C. Memory Map
| Decision | Approval impact | Uncertainty |
|----------|----------------|-----------|
| **ARC‑019 (Memory map)** | Deploy the 32‑bit addresses above. | Minor risk of address wrap‑around if new peripherals added.
| **ARC‑020 (Address details)** | Confirm register layout. | None.

## D. Peripherals
| Decision | Approval impact | Dependencies |
|----------|----------------|--------------|
| **ARC‑005 (Peripheral set)** | Confirm presence of UART, SPI, I²C, GPIO, SMBus, PWM, etc. | Must be included in register map.

## E. Clock & Reset
| Decision | Approval impact | Risks |
|----------|----------------|------|
| **ARC‑006 (Clocking)** | Confirm PLL and LPO usage. | Needs to be validated against low‑power spec.
| **ARC‑007 (Reset)** | Approve reset hierarchy. | Imperfect reset may freeze downstream logic.

## F. Power & PMIC
| Decision | Approval impact | Notes |
|----------|----------------|------|
| **ARC‑009 (PMIC)** | Approve TPS65217. | Requires endorsement of interconnect and slope control.
| **ARC‑028–029 (Regulator assignment & loss calc.)** | Approve current distribution and dropout methodology. | Must be verified with simulation.

## G. Security & Boot
| Decision | Approval impact | Consequence |
|----------|----------------|-------------|
| **ARC‑025–§** | Approve secure boot flow, key provisioning, and cryptographic accelerators. | Without these, OTA and secure firmware cannot be ensured.

## H. Firmware & Boot
| Decision | Approval Impact | Notes |
|----------|----------------|------|
| **ARC‑018 (Boot sequence)** | Approve the flow steps and address points. | No apparent contradiction.

## I. Package & Pinout
| Decision | Approval impact | Notes |
|----------|----------------|------|
| **ARC‑022–023 (Package & Pinout)** | Approve QFN‑64 and the pin mapping as specified. | Pin‑count satisfies peripheral needs.

## J. Verification & DFT
| Decision | Blocker status | Resolution |
|----------|----------------|------------|
| **ARC‑036 (Formal CDC)** | BLOCKED until formal verification is defined. | Plan to add properties in docs/architecture/CLOCK_RESET_AND_POWER_ARCHITECTURE.md.
| **ARC‑037 (DFT/ATPG)** | BLOCKED; requires commercial tooling. | Pro‑cure and integrate a DFT solution.

## K. PDK & ASIC
| Decision | Status | Notes |
|----------|--------|-------|
| N/A | Verification of SkyWater 130 nm flow pending. | No blocker at this stage.

**Summary:** All decisions marked PENDING‑APPROVAL or BLOCKED need your explicit sign‑off or additional evidence before the architecture can freeze and RTL can start.
