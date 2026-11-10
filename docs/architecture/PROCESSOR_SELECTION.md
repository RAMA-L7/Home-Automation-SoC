# Processor Selection Architecture

## 1. Executive Summary
This document analyzes credible processor candidates for the Home-Automation-SoC (HAS-SoC) and records the selection criteria, evidence, risks, and provisional recommendation based on research report ds01_ip_research/report.md and ds02_rtl_research/report.md.

## 2. Processor Candidates Evaluation

| Candidate | ISA Support | Pipeline Stages | Area (kGE) | License | Verification Status | Source Reference |
|-----------|-------------|-----------------|------------|---------|---------------------|------------------|
| **Ibex (lowRISC)** | RV32I/E, M, C, B | 4-5 stage | 16.9 - 32.5 | Apache-2.0 | Proven tape-outs, mature | DS-01 Section 1 |
| **VexRiscv (SpinalHDL)** | RV32I/M/A/F/D/C | 2-5 stage | 20 - 40 (est) | BSD-3-Clause | Community-tested | DS-01 Section 1 |
| **SCR1 (Syntacore)** | RV32I/E, optional M, C | 2-4 stage | ~20 (synth) | SHL (permissive) | Silicon-proven | DS-01 Section 1 |
| **CV32E40P (OpenHW)** | RV32IMFCX | 4 stage | ~30 (synth) | Apache-2.0 | Formal verification suite | DS-01 Section 1 |
| **NEORV32** | RV32I, Zicsr, Zifencei, C | 5 stage | ~12 (ASIC) | MIT | FPGA-first, active | DS-01 Section 1 |

## 3. Detailed Architectural Trade-offs
- **Ibex:** Selected as primary candidate due to silicon provenance in OpenTitan, Apache-2.0 licensing, robust verification harness, and low power footprint (~16-32 kGE). Supports RV32IMC configuration suitable for home automation.
- **CV32E40P:** Strong alternative with DSP extensions, derived from RI5CY, but slightly larger area (~30 kGE).
- **VexRiscv:** Excellent for FPGA prototyping via SpinalHDL, but lacks formal ASIC tape-out history in standard open flows.

## 4. Decision Analysis Matrix
- **Available Options:** Ibex, VexRiscv, SCR1, CV32E40P, NEORV32.
- **Technical Advantages:** Ibex provides proven lowRISC ecosystem integration, Apache-2.0 license, and compact RV32IMC footprint.
- **Technical Disadvantages:** Limited vector extensions in baseline configuration.
- **Evidence:** DS-01 Section 1, DS-02 Section 1.
- **Dependencies:** AXI4-Lite bus bridge, PLIC/CLINT interrupt controllers.
- **Risks:** Integration complexity of custom extensions if required.
- **Recommended Option:** Ibex (lowRISC) configured for RV32IMC.
- **Approval Status:** **PENDING APPROVAL** (Unapproved default decision per project rules).
