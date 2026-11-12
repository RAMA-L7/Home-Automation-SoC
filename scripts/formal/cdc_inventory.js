#!/usr/bin/env node
/*
 * Home-Automation-SoC — CDC inventory (Phase 3)
 *
 * The Phase-2 version walked every RTL port and inferred a crossing from the
 * number of registers on the path.  That produced 95 "crossings", most of them
 * false: every APB port, every clock and every unused pin was counted.  This
 * version starts from the actual clocking architecture and classifies each real
 * top-level input explicitly.
 *
 * Clock architecture (rtl/rtl_top/has_soc.sv):
 *   clk          single board clock
 *   core_clk     = clk & core_clk_en_q     (gated, same edge)
 *   periph_clk   = clk & periph_clk_en_q   (gated, same edge)
 *   jtag_tck     independent debugger clock, sampled in the clk domain
 * Gated clocks are derived from the same source with a registered enable, so a
 * register-to-register path between core_clk and periph_clk is synchronous and
 * is NOT a clock-domain crossing.
 *
 * Classification vocabulary:
 *   async CDC        two different asynchronous clocks
 *   synchronous      same clock (or gated version of the same clock)
 *   gated clock      a clock that is a gated copy of another clock
 *   pin async        a top-level pin with no clock relationship to the SoC
 *   unused           present at the top level but never consumed
 *   single-stage     one flop only — metastability cannot be excluded
 *   multi-stage      two or more flops before the destination logic
 *   protocol         the crossing is resolved by the protocol, not by flops
 *
 * Every entry carries a structural check that is executed against the RTL, so
 * the table cannot silently drift away from the code.  A check failure exits 1.
 *
 * What this script cannot do: it cannot prove metastability safety, MTBF, or
 * that the destination logic consumes the last synchroniser stage.  Those are
 * statements about silicon, not RTL; the formal tasks cover the modelled
 * behaviour and the status column says exactly that.
 *
 * Usage: node scripts/formal/cdc_inventory.js [--json] [--strict]
 *   --strict also fails on any UNVERIFIED or BLOCKED row.
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const asJson = process.argv.includes('--json');
const strict = process.argv.includes('--strict');

const SOC = 'rtl/rtl_top/has_soc.sv';
const UART = 'rtl/rtl_peripherals/uart.sv';
const GPIO = 'rtl/rtl_peripherals/gpio.sv';
const PLIC = 'rtl/rtl_peripherals/plic.sv';
const SPI = 'rtl/rtl_peripherals/spi_ctrl.sv';
const JTAG = 'rtl/rtl_peripherals/debug_jtag.sv';
const PWR = 'rtl/rtl_peripherals/power_mgr.sv';
const I2S = 'rtl/rtl_peripherals/i2s.sv';

/*
 * Each row: signal, source, destination, mechanism, verification, status,
 * plus `check`: text that must (or must not) appear in `file` to justify the
 * mechanism.
 */
const CROSSINGS = [
  {
    signal: 'uart_rx',
    source: 'pad, asynchronous to periph_clk',
    dest: 'periph_clk (uart)',
    mechanism: 'multi-stage: 2-FF synchroniser (rx_sync1 -> rx_sync2)',
    verification: 'sim tb_uart.v pin-level test; structurally checked',
    status: 'simulation tested',
    file: UART,
    must: ['rx_sync1 <= uart_rx', 'rx_sync2 <= rx_sync1', 'if (!rx_sync2)'],
  },
  {
    signal: 'gpio[..]',
    source: 'pad, asynchronous to periph_clk',
    dest: 'periph_clk (gpio)',
    mechanism: 'multi-stage: 2-FF synchroniser + edge detect (sync2 vs prev)',
    verification: 'sim tb_gpio.v; structurally checked',
    status: 'simulation tested',
    file: GPIO,
    must: ['gpio_in_sync1 <= gpio', 'gpio_in_sync2 <= gpio_in_sync1', 'gpio_in_prev  <= gpio_in_sync2'],
  },
  {
    signal: 'ext_irq[31:0] (pads)',
    source: 'pad array at the SoC boundary',
    dest: 'none — the pads are not connected',
    mechanism: 'unused: the PLIC is fed from the internal periph_irq bus',
    verification: 'structural: has_soc.sv discards the vector; PLIC port uses periph_irq',
    status: 'structurally checked',
    file: SOC,
    must: ['wire unused_ext_irq = ^ext_irq;', '.ext_irq  (periph_irq)'],
  },
  {
    signal: 'periph_irq -> plic.ext_irq',
    source: 'periph_clk peripherals (gated copy of clk)',
    dest: 'core_clk (plic, gated copy of clk)',
    mechanism: 'synchronous path: both ends are gated copies of the same clk, so this is NOT a CDC. '
             + 'A defensive 2-FF synchroniser + rising-edge capture (irq_event) is retained because '
             + 'ext_irq is a module port that may be driven asynchronously in other integration contexts.',
    verification: 'sim tb_plic_proto.v (18 checks) + formal plic_regs (depth 52)',
    status: 'bounded proven',
    file: PLIC,
    must: ['irq_meta <= ext_irq', 'irq_sync <= irq_meta', 'irq_prev <= irq_sync', 'irq_sync & ~irq_prev'],
  },
  {
    signal: 'spi_miso',
    source: 'pad, asynchronous to the SPI bit clock',
    dest: 'pclk (spi_ctrl)',
    mechanism: 'protocol: MISO is launched by the slave on the SCK falling edge and sampled by '
             + 'pclk in the middle of the high phase.  SCK is generated by that same pclk, so '
             + 'there is no second clock domain and a 2-FF synchroniser would only add latency '
             + 'and break setup/hold.',
    verification: 'sim tb_spi_device.v (device model, both directions, back-to-back, reset)',
    status: 'simulation tested',
    file: SPI,
    must: ['shift    <= {shift[6:0], mosi_sample};', 'sck_r <= 1\'b1;'],
  },
  {
    signal: 'jtag_tms',
    source: 'jtag_tck (debugger clock)',
    dest: 'clk domain TAP state machine',
    mechanism: 'multi-stage: 2-FF synchroniser, TAP advances only on a detected tck_rise',
    verification: 'sim tb_jtag_proto.v (full TAP walk, 16 checks); structurally checked',
    status: 'simulation tested',
    file: JTAG,
    must: ['tms_meta  <= tms;  tms_sync  <= tms_meta;', 'tck_rise'],
  },
  {
    signal: 'jtag_tdi',
    source: 'jtag_tck (debugger clock)',
    dest: 'clk domain shift registers',
    mechanism: 'multi-stage: 2-FF synchroniser, consumed on tck_rise',
    verification: 'sim tb_jtag_proto.v (TDI fill + shift); structurally checked',
    status: 'simulation tested',
    file: JTAG,
    must: ['tdi_meta  <= tdi;  tdi_sync  <= tdi_meta;'],
  },
  {
    signal: 'jtag_tck',
    source: 'debugger clock, asynchronous to clk',
    dest: 'clk domain edge detector',
    mechanism: 'multi-stage: 2-FF synchroniser + edge detect (tck_sync1 & ~tck_sync2). '
             + 'Requires clk >= ~4x tck; documented in the RTL header and asserted by the testbench.',
    verification: 'sim tb_jtag_proto.v (10x clock ratio); structurally checked',
    status: 'simulation tested',
    file: JTAG,
    must: ['tck_sync1 <= tck', 'tck_sync2 <= tck_sync1'],
  },
  {
    signal: 'jtag_trst_n',
    source: 'debugger reset pin',
    dest: 'none — declared but not used',
    mechanism: 'unused: the TAP is reset by the system reset or by 5 TCK cycles with TMS high',
    verification: 'sim tb_jtag_proto.v T9 asserts the pin has no effect',
    status: 'structurally checked',
    // has_soc wires the pin in; debug_jtag only declares the port and never
    // reads it, which is what T9 of tb_jtag_proto.v asserts.
    file: SOC,
    must: ['.trst_n (jtag_trst_n)'],
    alsoCheck: { file: JTAG, mustNot: ['!trst_n', 'trst_n &&', 'trst_n =='] },
  },
  {
    signal: 'wake_ack',
    source: 'pad, asynchronous to periph_clk',
    dest: 'periph_clk (power_mgr)',
    mechanism: 'multi-stage: 2-FF synchroniser (wake_sync)',
    verification: 'formal cdc_power_mgr (bounded depth 30)',
    status: 'bounded proven',
    file: PWR,
    must: ['wake_sync <= {wake_sync[0], wake_ack}'],
  },
  {
    signal: 'i2s_din',
    source: 'pad',
    dest: 'none — the I2S receiver is not implemented',
    mechanism: 'unused: the port is declared and wired through the top level only',
    verification: 'structural: no read of i2s_din inside i2s.sv',
    status: 'structurally checked',
    file: SOC,
    must: ['.i2s_din(i2s_din)'],
    // Inside i2s.sv the name may only appear in the port declaration.
    alsoCheck: { file: I2S, countAtMost: { 'i2s_din': 1 } },
  },
  {
    signal: 'core_clk / periph_clk',
    source: 'clk with registered enables',
    dest: 'each other',
    mechanism: 'gated clock: both are clk gated by a registered enable, so every path between '
             + 'them is a same-edge synchronous path.  No CDC, no synchroniser required.',
    verification: 'structural: the enables are registered on the same edge',
    status: 'structurally checked',
    file: SOC,
    must: ['core_clk_en_q', 'periph_clk_en_q'],
  },
];

function read(rel) {
  const p = path.join(ROOT, rel);
  return fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : null;
}

function runChecks() {
  const results = [];
  for (const c of CROSSINGS) {
    const text = read(c.file);
    const problems = [];
    if (text === null) {
      problems.push(`missing file ${c.file}`);
    } else {
      for (const m of c.must || []) if (!text.includes(m)) problems.push(`missing: ${m}`);
      for (const m of c.mustNot || []) if (text.includes(m)) problems.push(`unexpected: ${m}`);
      if (c.alsoCheck) {
        const other = read(c.alsoCheck.file);
        if (other === null) {
          problems.push(`missing file ${c.alsoCheck.file}`);
        } else {
          for (const m of c.alsoCheck.mustNot || [])
            if (other.includes(m)) problems.push(`unexpected in ${c.alsoCheck.file}: ${m}`);
          for (const [needle, max] of Object.entries(c.alsoCheck.countAtMost || {})) {
            const n = other.split(needle).length - 1;
            if (n > max) problems.push(`${c.alsoCheck.file} uses ${needle} ${n} times (max ${max})`);
          }
        }
      }
    }
    results.push({ ...c, ok: problems.length === 0, problems });
  }
  return results;
}

const results = runChecks();
const failed = results.filter(r => !r.ok);

if (asJson) {
  console.log(JSON.stringify({
    clockDomains: {
      clk: 'single board clock',
      core_clk: 'clk & core_clk_en_q (gated)',
      periph_clk: 'clk & periph_clk_en_q (gated)',
      jtag_tck: 'independent debugger clock',
    },
    crossings: results.map(r => ({
      signal: r.signal, source: r.source, destination: r.dest, mechanism: r.mechanism,
      verification: r.verification, status: r.status, structuralCheck: r.ok ? 'pass' : 'fail',
      problems: r.problems,
    })),
  }, null, 2));
} else {
  const pad = (s, n) => (s.length > n ? s.slice(0, n - 1) + '…' : s.padEnd(n));
  console.log('CDC INVENTORY — Home-Automation-SoC');
  console.log('clock domains: clk (board), core_clk / periph_clk (gated copies of clk), jtag_tck (debugger)\n');
  console.log(pad('Signal', 24) + pad('Source', 30) + pad('Destination', 22)
            + pad('Mechanism', 40) + pad('Verification', 34) + 'Status');
  console.log('-'.repeat(172));
  for (const r of results) {
    console.log(pad(r.signal, 24) + pad(r.source, 30) + pad(r.dest, 22)
              + pad(r.mechanism.split(':')[0], 40) + pad(r.verification.split(';')[0], 34)
              + r.status);
  }
  console.log('-'.repeat(172));
  const byStatus = results.reduce((a, r) => (a[r.status] = (a[r.status] || 0) + 1, a), {});
  console.log(`total rows: ${results.length}  ` +
    Object.entries(byStatus).map(([k, v]) => `${k}: ${v}`).join('  '));
  console.log('note: a row proves RTL structure and modelled behaviour only — not metastability');
  console.log('      immunity, MTBF, or silicon timing. Those need STA and silicon bring-up.');

  if (failed.length) {
    console.log('\nSTRUCTURAL CHECK FAILURES');
    for (const f of failed) {
      console.log(`  ${f.signal} (${f.file})`);
      for (const p of f.problems) console.log(`    - ${p}`);
    }
  } else {
    console.log('\nstructural checks: all rows match the RTL');
  }
}

let exitCode = failed.length ? 1 : 0;
if (strict) {
  const soft = results.filter(r => ['unverified', 'blocked'].includes(r.status));
  if (soft.length) {
    console.log(`\n--strict: ${soft.length} row(s) are not verified`);
    exitCode = 1;
  }
}
process.exit(exitCode);
