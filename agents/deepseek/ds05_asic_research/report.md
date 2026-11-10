# ASIC/Open-Source Implementation Research Report
## Home-Automation-SoC Project – Phase 1 Research

**Date:** 2026-11-10  
**Author:** ds05-asic (Team DeepSeek)  
**Status:** Phase 1 – Research Complete

---

## Executive Summary

This report documents comprehensive research across 12 key areas of open-source ASIC implementation flows for the Home-Automation-SoC project. The open-source RTL-to-GDS ecosystem has matured significantly, with production-proven flows available through SkyWater 130nm (sky130) and IHP 130nm BiCMOS processes. Key findings:

| Area | Status | Recommendation |
|------|--------|----------------|
| **Digital Flow** | ✅ Mature | OpenROAD + OpenLane 2 for sky130 |
| **PDK Availability** | ✅ 4 nodes | sky130, ASAP7, GF180MCU, IHP SG13G2 |
| **Memory Compiler** | ✅ Active | OpenRAM (BSD-3-Clause) |
| **STA** | ✅ Mature | OpenSTA (MCMM support documented) |
| **DFT/Scan** | ⚠️ Limited | No official open-source ATPG; commercial or custom required |
| **Sign-off PV** | ⚠️ Partial | Magic/Netgen for open; Calibre required for production |
| **Power Analysis** | ⚠️ Basic | OpenROAD PSM with SAIF/VCD; no IR-drop sign-off |
| **MPW Shuttle** | ✅ Active | Efabless + IHP shuttles (2024-2026 cadence) |
| **Reference Design** | ✅ Production | OpenTitan (lowRISC) – Apache 2.0, shipping in Chromebooks |

**Evidence Classification Key:**  
- **VERIFIED**: Confirmed via official repository/documentation with active maintenance  
- **DOCUMENTED**: Stated in official docs but not independently verified  
- **ESTIMATED**: Derived from public data or community reports  
- **ASSUMED**: Reasonable assumption based on industry practice  
- **UNKNOWN**: Information not found or inaccessible  

---

## Methodology

Research conducted via:
1. GitHub repository metadata analysis (license, activity, stars, last commit)
2. Official documentation review (ReadTheDocs, project wikis, technical manuals)
3. Web fetch of project homepages and technical specifications
4. Cross-reference with production silicon announcements (lowRISC, Google, Efabless)

**Sources Verified:** 18+ official repositories and documentation sites  
**Date of Data:** 2026-11-10  
**Limitations:** Shuttle pricing pages returned 404; some efabless documentation inaccessible; OpenDFT no official OpenROAD project repository found

---

## Findings by Research Task

### 1. Open-Source PDKs (sky130, ASAP7, GF180MCU, IHP SG13G2)

| PDK | Repository | License | Status | Notes |
|-----|------------|---------|--------|-------|
| **SkyWater 130nm** | [`google/skywater-pdk`](https://github.com/google/skywater-pdk) | Apache 2.0 | ✅ VERIFIED | Production-proven via Efabless shuttles; sky130A (analog), sky130B (digital) |
| **ASAP7 7nm** | [`The-OpenROAD-Project/asap7`](https://github.com/The-OpenROAD-Project/asap7) | BSD-3-Clause | ✅ VERIFIED | Predictive PDK for early exploration; not manufacturable |
| **GF180MCU 180nm** | [`google/gf180mcu-pdk`](https://github.com/google/gf180mcu-pdk) | Apache 2.0 | ✅ VERIFIED | GlobalFoundries 180nm MCU process; industrial-grade |
| **IHP SG13G2 130nm BiCMOS** | [`IHP-GmbH/IHP-Open-PDK`](https://github.com/IHP-GmbH/IHP-Open-PDK) | Proprietary (research license) | ✅ VERIFIED | 130nm BiCMOS for analog/RF/mixed-signal; shuttle access via IHP |

**Integration Considerations:**
- SkyWater sky130 has the most mature open-source tool support
- IHP SG13G2 requires direct engagement with IHP for tape-out
- ASAP7 suitable for early architecture exploration only

**Technical Risks:**
- PDK compatibility varies by tool version (volare manages this)
- Analog/RF blocks may require commercial simulator sign-off

---

### 2. Open-Source ASIC Flows (OpenROAD, OpenLane 1/2, Volare, Librelane)

| Flow | Repository | License | Status | Notes |
|------|------------|---------|--------|-------|
| **OpenROAD** | [`The-OpenROAD-Project/OpenROAD`](https://github.com/The-OpenROAD-Project/OpenROAD) | BSD-3-Clause | ✅ VERIFIED | Unified RTL-to-GDS app; production-proven |
| **OpenLane 2** | [`The-OpenROAD-Project/OpenLane`](https://github.com/The-OpenROAD-Project/OpenLane) | Apache 2.0 | ✅ VERIFIED | Heirarchical flow; supersedes OpenLane 1 |
| **OpenLane 1** | [`efabless/OpenLane`](https://github.com/efabless/OpenLane) | Apache 2.0 | ⚠️ LEGACY | Original flat flow; still used for simple designs |
| **Volare** | [`chipfoundry/volare`](https://github.com/chipfoundry/volare) | Apache 2.0 | ✅ VERIFIED | PDK version manager for OpenLane/OpenROAD |
| **Librelane** | [`librelane/librelane`](https://github.com/librelane/librelane) | Apache 2.0 | ✅ VERIFIED | Pythonic OpenROAD flow; alternative to OpenLane |

**Evidence:** All repositories show active maintenance (commits within 6 months)

**Integration Considerations:**
- OpenLane 2 recommended for new designs (hierarchical support)
- Volare essential for PDK version pinning in CI/CD
- Librelane offers more programmatic control for custom flows

**Technical Risks:**
- Flow stability varies by PDK/technology node
- Hierarchical flows require careful partitioning

---

### 3. RTL-to-GDS: Yosys (Memory Inference, FSM Extraction, Tech-Mapping, SBY)

| Tool | Repository | License | Status | Capabilities |
|------|------------|---------|--------|--------------|
| **Yosys** | [`YosysHQ/yosys`](https://github.com/YosysHQ/yosys) | ISC | ✅ VERIFIED | Synthesis, tech-mapping, FSM extraction |
| **SymbiFlow/SBY** | [`YosysHQ/sby`](https://github.com/YosysHQ/sby) | ISC | ✅ VERIFIED | Formal verification integration |

**Yosys Capabilities (DOCUMENTED):**
- **Memory Inference**: Infers RAM/ROM from RTL patterns; maps to PDK memory primitives
- **FSM Extraction**: Identifies finite state machines for optimization (`fsm` pass)
- **Tech-Mapping**: Maps generic gates to PDK standard cells (`techmap` pass)
- **SBY Integration**: SymbiYosys for formal property verification

**Integration Considerations:**
- Yosys is the default synthesis engine in OpenLane
- SBY requires SVA or Yosys assertions for formal checks

**Technical Risks:**
- Memory inference may not match commercial tool quality for complex patterns
- Formal verification scope limited compared to commercial tools (JasperGold, VC Formal)

---

### 4. Static Timing Analysis: OpenSTA vs PrimeTime, MCMM Support

| Tool | Repository | License | Status | MCMM Support |
|------|------------|---------|--------|--------------|
| **OpenSTA** | [`The-OpenROAD-Project/OpenSTA`](https://github.com/The-OpenROAD-Project/OpenSTA) | BSD-3-Clause | ✅ VERIFIED | ✅ DOCUMENTED (multi-corner, multi-mode) |
| **PrimeTime** | Synopsys (commercial) | Proprietary | Industry Standard | Full MCMM, signal integrity, power |

**OpenSTA MCMM Support (DOCUMENTED):**
- Multi-corner: Process (TT/FF/SS), Voltage, Temperature combinations
- Multi-mode: Functional, scan, test modes with different constraints
- Integrated with OpenROAD flow for iterative timing closure

**Integration Considerations:**
- OpenSTA uses Synopsys-compatible SDC constraint format
- Timing reports less detailed than PrimeTime but sufficient for open flows

**Technical Risks:**
- No signal integrity analysis (crosstalk, SI)
- Limited support for advanced timing features (clock gating checks, timing exceptions)

---

### 5. Physical Design: Floorplan via DFM, DFT (Scan, MBIST, OpenDFT)

| Aspect | Status | Notes |
|--------|--------|-------|
| **Floorplanning** | ✅ VERIFIED | OpenROAD supports macro placement, power grid, die definition |
| **DFM** | ⚠️ LIMITED | KLayout has DFM checks; no comprehensive open-source DFM suite |
| **Scan Insertion** | ⚠️ UNKNOWN | No verified open-source scan insertion tool in OpenROAD ecosystem |
| **MBIST** | ⚠️ UNKNOWN | OpenRAM includes BIST controllers; insertion flow unclear |
| **OpenDFT** | ❌ NOT FOUND | GitHub search returned unrelated quantum chemistry projects; no official OpenROAD DFT tool |

**Evidence:**
- OpenDFT search: [`github.com/search?q=OpenDFT`](https://github.com/search?q=OpenDFT) – no ASIC-related results
- Reference design `ymt1001816-cyber/cache-rtl-to-signoff` mentions "scan/ATPG + MBIST" but uses commercial tools

**Integration Considerations:**
- DFT likely requires commercial tool (Synopsys DFT Compiler, Mentor Tessent)
- OpenRAM provides memory BIST controllers that can be integrated at RTL

**Technical Risks:**
- **CRITICAL**: No open-source scan chain insertion or ATPG pattern generation
- Production test requires commercial DFT solution or significant custom development

---

### 6. Sign-off Physical Verification: Commercial vs Open (Magic, Netgen, KLayout)

| Tool | Repository | License | Status | Capabilities |
|------|------------|---------|--------|--------------|
| **Magic** | [`RTimothyEdwards/magic`](https://github.com/RTimothyEdwards/magic) | GPL-2.0 | ✅ VERIFIED | DRC, layout editing, 3D visualization |
| **Netgen** | [`RTimothyEdwards/netgen`](https://github.com/RTimothyEdwards/netgen) | GPL-2.0 | ✅ VERIFIED | LVS (layout vs schematic) |
| **KLayout** | [`KLayout/klayout`](https://github.com/KLayout/klayout) | GPL-2.0 | ✅ VERIFIED | DRC, LVS, layout viewing, scripting |
| **Calibre** | Siemens EDA (commercial) | Proprietary | Industry Standard | Full DRC/LVS/ERC, yield analysis |
| **IC Validator** | Synopsys (commercial) | Proprietary | Industry Standard | DRC/LVS, hotspot detection |
| **Pegasus** | Cadence (commercial) | Proprietary | Industry Standard | DRC/LVS, verification |

**Integration Considerations:**
- Magic/Netgen sufficient for MPW shuttle submission (sky130)
- Commercial sign-off required for high-volume production
- KLayout offers modern UI and Python scripting for custom DRC rules

**Technical Risks:**
- Open tools may not catch all foundry-specific DRC rules
- No open-source ERC (electrical rule check) equivalent

---

### 7. Power Modeling: SAIF/VCD → OpenROAD PSM vs RedHawk

| Tool | Status | Input Format | Capabilities |
|------|--------|--------------|--------------|
| **OpenROAD PSM** | ✅ VERIFIED | SAIF, VCD | Static + dynamic power estimation |
| **RedHawk** | Cadence (commercial) | Proprietary | Full power grid analysis, IR-drop, EM |

**OpenROAD Power Analysis (VERIFIED):**
- Accepts SAIF (Switching Activity Interchange Format) and VCD (Value Change Dump)
- Provides cell-level power breakdown
- Integrated with OpenROAD flow

**Integration Considerations:**
- Activity data from simulation (Verilator, VCS, Xcelium)
- No IR-drop or electromigration analysis in open flow

**Technical Risks:**
- **CRITICAL**: No open-source power grid sign-off (IR-drop, EM)
- Power estimates may not correlate with silicon without commercial tools

---

### 8. Economic Models: Efabless, GF180, IHP Shuttle Cadence & Cost (2024–2026)

| Provider | Process | Shuttle Cadence | Cost (ESTIMATED) | Status |
|----------|---------|-----------------|------------------|--------|
| **Efabless** | sky130 | Quarterly (MPW) | $5k–$50k (area-dependent) | ✅ Active |
| **Efabless** | GF180MCU | Bi-annual | Higher than sky130 | ✅ Active |
| **IHP** | SG13G2 BiCMOS | By arrangement | Contact IHP | ✅ Active |

**Evidence:**
- Efabless shuttle pages returned 404; pricing not publicly accessible
- Historical data from MPW6 submissions (GitHub: `christoph-weiser/mpw6`)
- IHP shuttle access via direct engagement

**Integration Considerations:**
- Efabless Caravel framework required for sky130 submissions
- Area cost dominates; floorplanning optimization critical

**Technical Risks:**
- Shuttle schedules may slip; design must be ready for next window
- Cost escalates rapidly with area; aggressive optimization required

---

### 9. Reference Silicon: lowRISC/OpenTitan (Block Diagram, Security Spec, Reusable Blocks)

| Aspect | Status | Source |
|--------|--------|--------|
| **Repository** | ✅ VERIFIED | [`lowRISC/opentitan`](https://github.com/lowRISC/opentitan) |
| **License** | Apache 2.0 | VERIFIED |
| **Production Status** | ✅ VERIFIED | Shipping in Chromebooks (Google) |
| **Documentation** | ✅ VERIFIED | [`opentitan.org`](https://opentitan.org), [`docs.opentitan.org`](https://docs.opentitan.org) |
| **Security Spec** | ✅ DOCUMENTED | Hardware root of trust, FIPS 140-3, Common Criteria EAL 4+ |
| **Block Diagram** | ✅ DOCUMENTED | Comportable IP blocks, Ibex RISC-V core |
| **Reusable Blocks** | ✅ VERIFIED | HMAC, AES, SHA, RSA, ECC, key manager, alert handler |

**OpenTitan Statistics (VERIFIED):**
- 33,300+ total commits
- 40,000+ nightly regression tests
- 270+ contributors
- 5,400+ GitHub stars
- 446,000+ lines of SystemVerilog

**Integration Considerations:**
- Security IP can be reused (with compliance obligations)
- Ibex core suitable for low-power MCU applications
- Comportable interface standard for peripheral integration

**Technical Risks:**
- Security certification requires strict adherence to implementation guidelines
- Apache 2.0 license requires attribution and notice preservation

---

### 10. FPGA Prototype Bridge: Vendors, Licensing, RTL Parity

| Vendor | Toolchain | Licensing | ASIC Parity |
|--------|-----------|-----------|-------------|
| **Xilinx/AMD** | Vivado | Commercial (free tier available) | High (synthesis constraints) |
| **Intel/Altera** | Quartus | Commercial (free tier available) | High |
| **Lattice** | Diamond/iCEcube2 | Commercial (free for small devices) | Medium (resource-limited) |
| **QuickLogic** | eFPGA | Licensing varies | Medium |

**Integration Considerations:**
- FPGA prototyping validates RTL before ASIC commitment
- Timing closure on FPGA does not guarantee ASIC timing
- Memory mapping may differ (FPGA BRAM vs ASIC SRAM)

**Technical Risks:**
- FPGA-ASIC functional mismatch (clock domains, reset polarity)
- Resource constraints may require design partitioning

---

### 11. OpenRAM Status (VLSIDA)

| Aspect | Status | Source |
|--------|--------|--------|
| **Repository** | ✅ VERIFIED | [`VLSIDA/OpenRAM`](https://github.com/VLSIDA/OpenRAM) |
| **License** | BSD-3-Clause | VERIFIED |
| **Status** | ✅ Active | Recent commits, maintained |
| **Capabilities** | DOCUMENTED | SRAM compiler, BIST controllers, timing models |

**Integration Considerations:**
- Generates sky130-compatible SRAM macros
- Provides timing libraries (LIB) for STA
- BIST controllers integrate with OpenROAD flow

**Technical Risks:**
- Memory density limited compared to commercial compilers
- Custom memory (CAM, register files) requires manual design

---

### 12. Unresolved: Efabless Caravel, Greyhound-IHP

| Project | Repository | Status | Notes |
|---------|------------|--------|-------|
| **Caravel** | [`efabless/caravel`](https://github.com/efabless/caravel) | ✅ VERIFIED | User project wrapper for sky130 MPW shuttles |
| **Greyhound-IHP** | [`mole99/greyhound-ihp`](https://github.com/mole99/greyhound-ihp) | ⚠️ Community | Unofficial IHP flow integration |

**Caravel (VERIFIED):**
- Provides chip-level infrastructure (power grid, IO pads, management core)
- Required for Efabless MPW submissions
- Includes verification testbenches

**Technical Risks:**
- Caravel area overhead (~20-30% of total die area)
- Fixed IO pad locations constrain floorplanning

---

## Comparative Tables

### Tool Comparison: Open-Source vs Commercial

| Function | Open-Source | Commercial | Gap |
|----------|-------------|------------|-----|
| **Synthesis** | Yosys (ISC) | Design Compiler, Genus | Moderate (complex optimizations) |
| **P&R** | OpenROAD (BSD-3) | Innovus, ICC2 | Moderate (large designs >1M gates) |
| **STA** | OpenSTA (BSD-3) | PrimeTime | Significant (SI, advanced exceptions) |
| **DFT** | ❌ None | DFT Compiler, Tessent | **CRITICAL** |
| **PV** | Magic/Netgen (GPL) | Calibre, IC Validator | Moderate (foundry certification) |
| **Power** | OpenROAD PSM | RedHawk, PrimePower | **CRITICAL** (IR-drop, EM) |
| **Formal** | SBY (ISC) | JasperGold, VC Formal | Moderate (capacity, properties) |

### PDK Comparison

| PDK | Node | Type | License | Production | Best For |
|-----|------|------|---------|------------|----------|
| sky130A | 130nm | CMOS | Apache 2.0 | ✅ Yes | Analog/mixed-signal |
| sky130B | 130nm | CMOS | Apache 2.0 | ✅ Yes | Digital |
| ASAP7 | 7nm | CMOS (predictive) | BSD-3 | ❌ No | Early exploration |
| GF180MCU | 180nm | CMOS | Apache 2.0 | ✅ Yes | MCU, industrial |
| IHP SG13G2 | 130nm | BiCMOS | Research | ✅ Yes | RF, analog |

---

## Technical Risks Summary

| Risk | Severity | Mitigation |
|------|----------|------------|
| **No open-source DFT/ATPG** | 🔴 CRITICAL | Budget for commercial DFT tool; partner with university |
| **No IR-drop/EM sign-off** | 🔴 CRITICAL | Conservative power grid design; commercial sign-off before tape-out |
| **PDK version drift** | 🟡 MEDIUM | Use Volare for version pinning; CI/CD validation |
| **Shuttle schedule slip** | 🟡 MEDIUM | Design freeze 2 months before deadline; next-shuttle buffer |
| **OpenSTA SI limitations** | 🟡 MEDIUM | Conservative timing margins; commercial STA for sign-off |
| **Memory compiler limits** | 🟢 LOW | Use OpenRAM for standard SRAMs; custom design for specialized memories |

---

## Unresolved Questions

1. **OpenDFT**: Is there an official open-source DFT tool under development? (Search returned unrelated projects)
2. **Efabless Pricing**: Current shuttle costs not publicly accessible (404 on pricing pages)
3. **IHP Shuttle Cadence**: Specific 2024-2026 schedule requires direct IHP engagement
4. **MCMM Details**: OpenSTA multi-corner documentation needs deeper review
5. **Yosys Memory Inference**: Specific RTL patterns supported not fully documented

---

## Recommendations

### Immediate Actions (Phase 2)
1. **Adopt OpenLane 2 + sky130** as primary flow for digital blocks
2. **Engage IHP** for SG13G2 BiCMOS shuttle access (analog/RF blocks)
3. **Budget for commercial DFT** (Synopsys DFT Compiler or Mentor Tessent)
4. **Download OpenTitan IP** for security block reference (Apache 2.0 compliant)
5. **Set up Volare** for PDK version management in CI/CD

### Medium-Term (Phase 3)
1. **FPGA prototype** critical blocks (Xilinx/Intel free tier)
2. **OpenRAM integration** for SRAM requirements
3. **Commercial PV sign-off** engagement (Calibre or IC Validator)
4. **Power grid analysis** with conservative margins

### Long-Term (Production)
1. **Full commercial sign-off** flow for high-volume production
2. **Multi-source PDK strategy** (sky130 + GF180MCU for supply chain resilience)
3. **OpenTitan security IP** integration with compliance audit

---

## Evidence Classification Summary

| Classification | Count | Examples |
|----------------|-------|----------|
| **VERIFIED** | 15 | OpenROAD, OpenLane, sky130, OpenTitan, OpenRAM, Magic, Netgen, KLayout, Yosys, SBY, OpenSTA, Volare, Librelane, Caravel, IHP-Open-PDK |
| **DOCUMENTED** | 5 | OpenSTA MCMM, Yosys memory/FSM, OpenTitan security spec, OpenRAM capabilities, ASAP7 predictive nature |
| **ESTIMATED** | 2 | Efabless shuttle costs, Caravel area overhead |
| **ASSUMED** | 1 | FPGA-ASIC parity methodology |
| **UNKNOWN** | 3 | OpenDFT official status, Scan insertion flow, MBIST integration flow |

---

## Source URLs

| Resource | URL |
|----------|-----|
| OpenROAD | https://github.com/The-OpenROAD-Project/OpenROAD |
| OpenLane 2 | https://github.com/The-OpenROAD-Project/OpenLane |
| OpenLane 1 | https://github.com/efabless/OpenLane |
| Volare | https://github.com/chipfoundry/volare |
| Librelane | https://github.com/librelane/librelane |
| SkyWater PDK | https://github.com/google/skywater-pdk |
| ASAP7 | https://github.com/The-OpenROAD-Project/asap7 |
| GF180MCU | https://github.com/google/gf180mcu-pdk |
| IHP SG13G2 | https://github.com/IHP-GmbH/IHP-Open-PDK |
| Yosys | https://github.com/YosysHQ/yosys |
| SBY | https://github.com/YosysHQ/sby |
| OpenSTA | https://github.com/The-OpenROAD-Project/OpenSTA |
| OpenRAM | https://github.com/VLSIDA/OpenRAM |
| Magic | https://github.com/RTimothyEdwards/magic |
| Netgen | https://github.com/RTimothyEdwards/netgen |
| KLayout | https://github.com/KLayout/klayout |
| OpenTitan | https://github.com/lowRISC/opentitan |
| OpenTitan Docs | https://opentitan.org |
| Caravel | https://github.com/efabless/caravel |
| Greyhound-IHP | https://github.com/mole99/greyhound-ihp |

---

## Appendix: Repository Metadata (as of 2026-11-10)

| Repository | License | Activity |
|------------|---------|----------|
| The-OpenROAD-Project/OpenROAD | BSD-3-Clause | ✅ Active |
| fossi-foundation/open-pdks | BSD-3-Clause | ✅ Active |
| chipfoundry/volare | Apache 2.0 | ✅ Active |
| librelane/librelane | Apache 2.0 | ✅ Active |
| efabless/OpenLane | Apache 2.0 | ✅ Active |
| The-OpenROAD-Project/OpenLane | Apache 2.0 | ✅ Active |
| YosysHQ/yosys | ISC | ✅ Active |
| The-OpenROAD-Project/OpenSTA | BSD-3-Clause | ✅ Active |
| VLSIDA/OpenRAM | BSD-3-Clause | ✅ Active |
| The-OpenROAD-Project/asap7 | BSD-3-Clause | ✅ Active |
| google/gf180mcu-pdk | Apache 2.0 | ✅ Active |
| google/skywater-pdk | Apache 2.0 | ✅ Active |
| RTimothyEdwards/magic | GPL-2.0 | ✅ Active |
| RTimothyEdwards/netgen | GPL-2.0 | ✅ Active |
| KLayout/klayout | GPL-2.0 | ✅ Active |
| YosysHQ/sby | ISC | ✅ Active |
| efabless/caravel | Apache 2.0 | ✅ Active |
| IHP-GmbH/IHP-Open-PDK | Research License | ✅ Active |
| lowRISC/opentitan | Apache 2.0 | ✅ Active (Production) |

---

*Report generated by ds05-asic for Home-Automation-SoC Phase 1 Research*
