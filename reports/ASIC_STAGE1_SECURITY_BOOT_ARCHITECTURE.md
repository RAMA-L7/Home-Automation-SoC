# ASIC Stage 1 — Security and Boot Architecture

Date: 2026-11-15
Status: **READY FOR APPROVAL** (TD-007)
Constraint: no fake cryptography, no claimed capability without implementation.

---

## 1. Verified current state

| Component | Reality | Evidence |
|---|---|---|
| Boot ROM | Inferred 64 KB array; 16 KB decoded; hand-written test image at 0x0000_0000 | `boot_rom.sv`; `firmware/boot/boot.S` |
| Secure boot | `boot_verify_signature()` returns failure by design; no verifier linked | `firmware/bare_metal/boot.c:102-109` |
| Image validation | Header magic/bounds/entry checks exist; signature always fails | `boot.c:83-109` |
| Key storage | No OTP/eFuse; no DUK; no trust anchor | RTL inventory |
| Crypto accelerators | None (no AES, SHA, TRNG, ECC) | RTL inventory |
| QSPI | Single-line read only; writes return SLVERR; no program/erase | `qspi_flash_ctrl.sv:7-10` |
| OTA | Explicit fail-closed stub; returns unsupported | `firmware/bare_metal/ota.c:5,33` |
| Debug | JTAG TAP subset; no DMI/IDCODE; no fuse lock | `debug_jtag.sv`; ARC-024 |
| Rollback | No counter, no A/B partitions | RTL/firmware |
| Attestation | None | RTL/firmware |

**Conclusion:** the project has a *boot* flow (ROM → firmware image) but no *secure* boot and no OTA. The documentation describes an OpenTitan-class root of trust that does not exist.

---

## 2. Requirements vs implementation

| Requirement | Status | Gap |
|---|---|---|
| FR-SEC-001 ECDSA-P256 secure boot | NOT_IMPLEMENTED | No verifier, no key, no OTP |
| FR-SEC-002 SHA-256 measurement | NOT_IMPLEMENTED | No SHA engine or software hash in boot |
| FR-SEC-003 DUK from TRNG → OTP | NOT_IMPLEMENTED | No TRNG, no OTP |
| FR-SEC-004 AES-256 | NOT_IMPLEMENTED | No engine |
| FR-SEC-005 SHA-256 engine | NOT_IMPLEMENTED | No engine |
| FR-SEC-006 TRNG | NOT_IMPLEMENTED | No engine |
| FR-SEC-006 (OTA) | NOT_IMPLEMENTED | OTA stub; no verify/decrypt |
| FR-SEC-007 rollback protection | NOT_IMPLEMENTED | No counter/NVRAM |
| FR-SEC-008 JTAG disable fuse | NOT_IMPLEMENTED | No fuse |
| NFR-PERF-003 verify <100 ms | NOT_VERIFIABLE | No implementation |
| NFR-QUA-001/002 DFT/MBIST | BLOCKED | Tooling absent |

The SRS also assumes Ibex PMP and M/U modes (FR-PROC-003/004) for secure/non-secure partitioning. The core is machine-mode-only with no PMP, so **hardware-enforced privilege separation is impossible** on the current core.

---

## 3. Minimum viable security options

### S0 — No secure boot (explicit descope)

- Boot ROM loads a known image; no signature.
- All security claims removed from docs, datasheet and product.
- Debug lock via package strap or external means.
- Pros: zero new silicon, smallest ROM, fastest boot.
- Cons: fails mandatory FR-SEC-001..008; unacceptable for a connected home-automation device exposed to OTA threats.

### S1 — Verified boot with hardware SHA-256 + ECDSA-P256

- ROM contains a root public-key hash (or key) in OTP/eFuse or a secure element.
- ROM computes SHA-256 over the image and verifies ECDSA-P256 signature.
- On failure: fail closed to recovery (UART or QSPI recovery image).
- Requires: SHA-256 engine, ECDSA-P256 verify engine (or a verified software implementation with acceptable boot time), OTP/eFuse or external secure element, image header, key provisioning flow.
- Pros: meets FR-SEC-001/002 at a credible performance level; enables attestation later.
- Cons: significant RTL/verification work; OTP macro not available; key provisioning infrastructure.

### S2 — Symmetric verified boot (HMAC-SHA-256)

- Pre-shared per-device key in OTP/secure element; ROM verifies HMAC.
- Cheaper than ECDSA, but key distribution/revocation is worse and does not support a manufacturer signing chain.
- Not recommended for a product with OTA and multiple firmware authors.

### S3 — External secure element / companion MCU

- SoC treats a secure element as the root of trust over I2C/SPI; ROM asks it to verify the image.
- Avoids on-chip OTP/crypto; adds board cost, latency, and a new interface.
- Viable fallback if on-chip OTP is unavailable before tapeout.

**Recommended: S1** if an OTP/eFuse macro or external secure element can be committed before Stage 2 freeze. **S0** only as an owner-signed descope; never label it secure boot.

---

## 4. Key storage and provisioning

| Option | Description | Availability |
|---|---|---|
| K-A | On-chip OTP/eFuse (256-bit DUK + key hash) | No macro in repository; must be sourced |
| K-B | External secure element (I2C) | Requires new interface and board part |
| K-C | Key hash in mask ROM (fixed per design) | Prevents per-device keys; only a fixed vendor key |
| K-D | No key (S0) | No security |

Minimum for S1: a device-unique secret or a manufacturer public-key hash stored immutably. A fixed key in mask ROM is acceptable only if per-device uniqueness is explicitly not required (weakens cloning resistance).

Provisioning flow (S1, K-A):

1. Factory generates DUK in TRNG (on-chip or tester).
2. DUK and key hash are programmed into OTP; OTP is locked.
3. Public key/certificate is stored in QSPI; ROM verifies the chain to the OTP-held hash.
4. Debug fuse is programmed after provisioning.

No step of this flow exists today.

---

## 5. Image format

Recommended first-silicon header (128 bytes, little-endian, 4-byte aligned):

| Offset | Field | Size |
|---:|---|---:|
| 0x00 | magic `0x4841534F` ("HASO") | 4 |
| 0x04 | version (monotonic) | 4 |
| 0x08 | payload size | 4 |
| 0x0C | load address | 4 |
| 0x10 | entry point | 4 |
| 0x14 | flags (encrypted/compressed) | 4 |
| 0x18 | reserved | 8 |
| 0x20 | SHA-256 of payload | 32 |
| 0x40 | ECDSA-P256 signature (r‖s) | 64 |
| 0x80 | end | — |

The existing `boot.c` header already validates magic, bounds and entry; it must be extended with the hash/signature fields and a real verifier.

Encryption (AES-GCM) is **not** required for integrity; it is only needed if firmware confidentiality is a requirement. Adding AES without a key-management story creates complexity without a clear threat benefit. Recommendation: sign, do not encrypt, in first silicon.

---

## 6. Boot flow (recommended first silicon)

```
POR
 → AON reset release
 → ROM self-test (minimal)
 → read image header from QSPI (single-line read works today)
 → bounds/entry checks
 → SHA-256(payload)
 → ECDSA-P256 verify(hash, sig, key)
 → on failure: recovery (UART) — fail closed
 → on success: copy payload to TCM/SRAM, jump
```

XIP is not required for first silicon; copying a ≤64 KB image to SRAM/TCM is simpler and avoids QSPI performance/aliasing issues.

---

## 7. Debug policy

| Mode | Access | Mechanism |
|---|---|---|
| Manufacturing | Full JTAG | Before provisioning |
| Provisioned | Disabled | OTP fuse or package strap |
| RMA | Challenge-response | Not implemented; defer |

The current TAP has no DMI/IDCODE, so OpenOCD debug is not usable. If debug is a product requirement, that is Stage 2 work independent of security.

---

## 8. OTA and rollback

| Feature | Recommendation |
|---|---|
| OTA download | Defer to second silicon unless QSPI program/erase is implemented |
| A/B partitions | 32 MB each is oversized for a ≤64 KB image; use 256 KB slots if implemented |
| Rollback counter | OTP or PMIC NVRAM; no NVRAM interface exists |
| Runtime verifier | Reuse S1 hash/signature engine |
| Recovery | UART recovery image; ROM fail-closed path |

OTA is not required for a first tapeout if the product can be updated via debug/programming during bring-up, but the requirement must then be explicitly deferred.

---

## 9. Decision package (TD-007)

| Item | Content |
|---|---|
| Current | No verifier, no key storage, no crypto, OTA stub, no debug lock |
| Options | S0 descope, S1 hardware verified boot, S2 HMAC, S3 external secure element |
| Recommended | S1 with K-A (OTP) if macro available, else S3; otherwise S0 with explicit descope |
| Risks | OTP macro unavailable; ECDSA RTL effort; key provisioning infrastructure; boot time |
| Downstream | Stage 2 RTL, Stage 4 verification, Stage 16 DFT (key/test access), Stage 17 package |
| Approval | User/design owner + security owner (unassigned) |
| Acceptance | Approved option; key storage chosen; image format frozen; debug policy defined; OTA explicitly in/out of first silicon |

**Verified:** no crypto/OTP, fail-closed boot, read-only QSPI, OTA stub.
**Recommended:** S1 (or S3 fallback); S0 only as an explicit descope.
**Not approved:** TD-007 remains READY FOR APPROVAL.
