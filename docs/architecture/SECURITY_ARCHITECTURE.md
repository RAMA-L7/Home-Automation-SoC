# Security Architecture

## 1. Security Objectives

The Home-Automation-SoC implements a hardware root of trust suitable for residential IoT devices requiring:
- **Secure Boot:** Authenticate firmware before execution
- **Firmware Integrity:** Verify OTA updates cryptographically
- **Key Management:** Device-unique keys, secure storage, controlled access
- **Cryptographic Services:** AES, SHA, TRNG for protocol security (Matter, Thread, TLS)
- **Tamper Resistance:** Basic physical and logical protection

**Threat Model:** Remote firmware modification, key extraction, rollback attacks, side-channel leakage (basic mitigation).

---

## 2. Secure Boot ROM (ARC-004, ARC-025, ARC-033)

### 2.1 Implementation
- **Source:** OpenTitan ROM (lowRISC, Apache-2.0)
- **Size:** 16 KB (0x0000_0000 – 0x0000_3FFF)
- **ISA:** RV32IMC (matches Ibex)
- **Function:**
  1. Power-on self-test (SRAM, registers)
  2. Initialize TRNG, AES, SHA engines
  3. Load firmware header from QSPI (0x4000_0000)
  4. Verify ECDSA-P256 signature using device public key
  5. Measure firmware hash into SHA-256 (for remote attestation)
  6. Jump to firmware entry point (TCM or SRAM)

### 2.2 Key Provisioning Flow (ARC-025)
```
Manufacturing:
  1. TRNG generates 256-bit device-unique key (DUK)
  2. DUK → OTP/fuse region (one-time programmable)
  3. DUK used to derive:
     - Root signing key (ECDSA-P256) for firmware
     - AES-256 wrapping key for encrypted OTA payloads
     - HMAC key for secure boot measurements
  4. Public key certificate signed by manufacturer CA → stored in QSPI

Field:
  5. Boot ROM reads DUK from OTP
  6. Derives verification key
  7. Verifies firmware signature chain
```

### 2.3 OTP / Fuse Requirements
- **Size:** 256 bits (DUK) + 256 bits (manufacturer key hash) + 128 bits (config)
- **Technology:** SkyWater 130nm eFuse macro (or emulated in SRAM for prototype)
- **Access:** Read-only after boot ROM locks it (via PMU register)

---

## 3. Cryptographic Accelerators

### 3.1 AES-256 Engine
- **Modes:** ECB, CBC, CTR, GCM (AEAD)
- **Key Sizes:** 128, 256 bits
- **Interface:** APB memory-mapped (0x5000_8000)
- **DMA Support:** Optional (future phase)
- **Side-Channel Countermeasures:** Masking, constant-time S-box (OpenTitan AES)
- **Evidence:** DS-01 Section 5 (DOCUMENTED)

### 3.2 SHA-256 Engine
- **Algorithm:** FIPS 180-4 SHA-256
- **Interface:** APB memory-mapped (0x5000_9000)
- **Streaming:** Block-by-block with context save/restore
- **Use Cases:** Firmware measurement, TLS certificates, HMAC
- **Evidence:** DS-01 Section 5 (DOCUMENTED)

### 3.3 True Random Number Generator (TRNG)
- **Source:** Ring oscillator jitter / metastability (OpenTitan TRNG)
- **Output:** 256-bit entropy per request
- **Health Tests:** Continuous (FIPS 140-2), startup
- **Interface:** APB memory-mapped (0x5000_A000)
- **Reseed:** Automatic from entropy pool
- **Evidence:** DS-01 Section 5 (DOCUMENTED)

### 3.4 Public Key Engine (PKE) — Future Phase
- **Not in Baseline:** ECC-P256, RSA-2048 hardware acceleration
- **Software Fallback:** Mbed TLS (Zephyr)
- **Area Cost:** ~50 kGE (deferred to Phase 2)

---

## 4. Memory Protection

### 4.1 Physical Memory Protection (PMP) — Ibex Built-in
- **Regions:** 16 configurable (TOR / NAPOT mode)
- **Permissions:** R/W/X per region, per privilege mode (M/U)
- **Boot ROM Configuration:** Locks OTP region, marks QSPI executable
- **Firmware Configuration:** Isolates secure/non-secure partitions

### 4.2 Secure/Non-Secure Partitioning (Future: PMP + TEE)
- **Not in Baseline:** Full TEE (TrustZone-M equivalent) requires Ibex PMP + secure firmware
- **Current:** Single M-mode execution; secure services via SBI calls

---

## 5. Anti-Tamper & Physical Security

| Feature | Implementation | Status |
|---------|----------------|--------|
| **Clock Glitch Detection** | On-chip monitor (AON domain) | PROPOSED |
| **Voltage Glitch Detection** | PMIC alert + brown-out detect | PROPOSED (TPS65217) |
| **Temperature Sensor** | Internal diode + ADC | PROPOSED |
| **Active Mesh** | Not implemented (cost) | DEFERRED |
| **JTAG Lock** | Fuse bit disables debug after provisioning | PROPOSED |

---

## 6. OTA Update Security (ARC-026)

### 6.1 Update Flow
1. **Host (Home Assistant)** signs firmware image with manufacturer private key
2. **Image Format:** Header (version, hash, signature) + encrypted payload (AES-256-GCM)
3. **Delivery:** MQTT/CoAP over TLS → QSPI staging area
4. **Verification:** Boot ROM (on next reset) or runtime verifier (AES + SHA + ECDSA)
5. **Atomic Swap:** A/B partitions in QSPI; rollback on verification failure

### 6.2 Key Hierarchy
```
Manufacturer Root CA (offline, HSM)
    │
    ├── Device Provisioning CA (online, signs device certs)
    │       │
    │       └── Device Certificate (ECDSA-P256, in QSPI)
    │
    └── Firmware Signing Key (ECDSA-P256, in HSM)
            │
            └── Firmware Signature (in image header)
```

### 6.3 Rollback Protection
- **Monotonic Counter:** In OTP / PMIC NVRAM (incremented per successful update)
- **Version Check:** Boot ROM rejects firmware with version ≤ stored counter

---

## 7. Debug Security

### 7.1 Debug Access Control
| Mode | Access | Condition |
|------|--------|-----------|
| **Manufacturing** | Full JTAG/SWD | Before OTP lock |
| **Field (Provisioned)** | Disabled | OTP debug-disable bit = 1 |
| **RMA / Failure Analysis** | Limited | Challenge-response with manufacturer |

### 7.2 Secure Debug (Future)
- **Not in Baseline:** Certificate-based debug unlock (OpenTitan style)
- **Current:** Permanent JTAG disable after provisioning

---

## 8. Compliance Mapping

| Requirement | Standard | Implementation |
|-------------|----------|----------------|
| Secure Boot | IEC 62443-4-2 | OpenTitan ROM + ECDSA |
| Key Storage | FIPS 140-2 Level 2 | OTP + TRNG-derived keys |
| Crypto Algorithms | NIST SP 800-57 | AES-256, SHA-256, ECDSA-P256 |
| Entropy | NIST SP 800-90B | TRNG with health tests |
| OTA Integrity | Matter Spec | Signed + encrypted images |

---

## 9. Open Decisions (Traceable to ARCs)

| Decision | ARC Ref | Status |
|----------|---------|--------|
| OTP macro selection (eFuse vs emulated) | ARC-025 | PROPOSED |
| Exact Boot ROM size (16 KB vs 32 KB) | ARC-004, ARC-011 | PROPOSED |
| PMP region allocation table | ARC-033 | PENDING |
| JTAG disable fuse bit assignment | ARC-024 | PROPOSED |
| Side-channel countermeasure level | ARC-004 | PROPOSED |
| PKE inclusion (ECC/RSA HW) | — | DEFERRED |

---

## 10. Integration Dependencies

- **Clock/Reset:** TRNG requires AON clock (32 kHz); AES/SHA require core clock (50 MHz)
- **Power:** Crypto engines in Core domain (1.0 V); TRNG in AON (3.3 V)
- **Bus:** All engines on APB (0x5000_8000 – 0x5000_AFFF)
- **Interrupts:** Crypto done → PLIC; TRNG alarm → PLIC
- **Firmware:** Mbed TLS PSA API for crypto abstraction (Zephyr)

---

*All decisions traceable to ARC IDs in Phase 0 Closure Matrix. Evidence tags: VERIFIED, DOCUMENTED, PROPOSED, UNKNOWN.*