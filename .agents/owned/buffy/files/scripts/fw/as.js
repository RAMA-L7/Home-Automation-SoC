#!/usr/bin/env node
/*
 * Home-Automation-SoC — minimal RISC-V RV32IM assembler
 * ----------------------------------------------------
 * No RISC-V cross-toolchain (gcc/clang/llvm) is installed on this machine and
 * downloading one needs explicit approval, so the firmware is written in
 * assembly and assembled by this dependency-free Node script.
 *
 * Scope: RISC-V RV32IM integer subset, labels, .org/.equ/.word/.byte/.ascii,
 * and the common pseudo-instructions (li/la/j/ret/mv/beqz/bnez/csrr...).
 * NOT supported: C, ELF, relocations, linker scripts, debug info, macros.
 *
 * Output: $readmemh image (one 32-bit word per line) and an optional listing.
 *
 * Usage: node scripts/fw/as.js <input.S> <output.hex> [listing.lst]
 */
'use strict';
const fs = require('fs');

// ---------------------------------------------------------------------------
// Registers
// ---------------------------------------------------------------------------
const REGS = {};
['zero','ra','sp','gp','tp','t0','t1','t2','s0','s1','a0','a1','a2','a3','a4','a5',
 'a6','a7','s2','s3','s4','s5','s6','s7','s8','s9','s10','s11','t3','t4','t5','t6']
  .forEach((n, i) => { REGS[n] = i; REGS['x' + i] = i; });
REGS['fp'] = 8;

const reg = (tok) => {
  const t = String(tok).trim().toLowerCase();
  if (!(t in REGS)) throw new Error('bad register: ' + tok);
  return REGS[t];
};

const CSR = {
  mstatus: 0x300, misa: 0x301, mie: 0x304, mtvec: 0x305, mscratch: 0x340,
  mepc: 0x341, mcause: 0x342, mtval: 0x343, mip: 0x344,
  mcycle: 0xb00, minstret: 0xb02, mvendorid: 0xf11, marchid: 0xf12,
  mhartid: 0xf14
};

const csrNum = (tok) => {
  const t = String(tok).trim().toLowerCase();
  return (t in CSR) ? CSR[t] : immVal(t, {});
};

// ---------------------------------------------------------------------------
// Immediates / symbols
// ---------------------------------------------------------------------------
let SYM = {};

// Tiny expression evaluator for immediates: numbers (dec/hex), 'c' character
// literals, symbols, parentheses, unary -, and the usual integer operators.
function immVal(tok, symbols) {
  const src = String(tok).trim();
  if (src === '') return 0;

  const toks = [];
  let i = 0;
  while (i < src.length) {
    const c = src[i];
    if (/\s/.test(c)) { i++; continue; }
    if (c === "'") {
      const ch = src[i + 1];
      toks.push({ k: 'num', v: ch === '\\' ? escChar(src[i + 2]) : ch.charCodeAt(0) });
      i += 3;
      continue;
    }
    if (/[0-9]/.test(c)) {
      const m = src.slice(i).match(/^0x[0-9a-fA-F]+|^\d+/);
      toks.push({ k: 'num', v: m[0].startsWith('0x') ? parseInt(m[0], 16)
                                                       : parseInt(m[0], 10) });
      i += m[0].length;
      continue;
    }
    if (/[A-Za-z_.$]/.test(c)) {
      const m = src.slice(i).match(/^[A-Za-z_.$][\w.$]*/);
      toks.push({ k: 'sym', v: m[0] });
      i += m[0].length;
      continue;
    }
    const two = src.slice(i, i + 2);
    if (['<<', '>>'].includes(two)) { toks.push({ k: 'op', v: two }); i += 2; continue; }
    if ('+-*/%&|^~()'.includes(c)) { toks.push({ k: 'op', v: c }); i++; continue; }
    throw new Error('bad expression character: ' + c);
  }

  let p = 0;
  const peek = () => toks[p];
  const eat = (v) => (toks[p] && toks[p].v === v ? (p++, true) : false);

  function primary() {
    const t = toks[p++];
    if (!t) throw new Error('bad expression: ' + src);
    if (t.k === 'num') return t.v | 0;
    if (t.k === 'sym') return lookup(t.v, symbols);
    if (t.v === '(') { const v = expr(0); if (!eat(')')) throw new Error('missing )'); return v; }
    if (t.v === '-') return (-primary()) | 0;
    if (t.v === '~') return (~primary()) | 0;
    if (t.v === '+') return primary();
    throw new Error('bad expression: ' + src);
  }

  const PREC = { '|': 1, '^': 2, '&': 3, '<<': 4, '>>': 4, '+': 5, '-': 5, '*': 6, '/': 6, '%': 6 };
  function expr(minPrec) {
    let lhs = primary();
    for (;;) {
      const t = peek();
      if (!t || t.k !== 'op' || !(t.v in PREC)) break;
      const prec = PREC[t.v];
      if (prec < minPrec) break;
      p++;
      const rhs = expr(prec + 1);
      switch (t.v) {
        case '+': lhs = (lhs + rhs) | 0; break;
        case '-': lhs = (lhs - rhs) | 0; break;
        case '*': lhs = Math.imul(lhs, rhs) | 0; break;
        case '/': lhs = rhs === 0 ? -1 : (lhs / rhs) | 0; break;
        case '%': lhs = rhs === 0 ? lhs : (lhs % rhs) | 0; break;
        case '<<': lhs = (lhs << rhs) | 0; break;
        case '>>': lhs = (lhs >> rhs) | 0; break;
        case '&': lhs = lhs & rhs; break;
        case '|': lhs = lhs | rhs; break;
        case '^': lhs = lhs ^ rhs; break;
      }
    }
    return lhs | 0;
  }

  const v = expr(0);
  if (p !== toks.length) throw new Error('trailing tokens in expression: ' + src);
  return v | 0;
}

function escChar(c) {
  return { n: 10, r: 13, t: 9, '0': 0, '\\': 92, "'": 39 }[c] || c.charCodeAt(0);
}

function lookup(name, symbols) {
  const syms = symbols || SYM;
  if (!(name in syms)) throw new Error('undefined symbol: ' + name);
  return syms[name] | 0;
}

// ---------------------------------------------------------------------------
// Encoders — names are distinct from the operand helpers used in encode()
// ---------------------------------------------------------------------------
const encR = (f7, rs2, rs1, f3, rd, op) =>
  ((f7 & 0x7f) << 25) | ((rs2 & 31) << 20) | ((rs1 & 31) << 15) |
  ((f3 & 7) << 12) | ((rd & 31) << 7) | (op & 0x7f);

const encI = (imm, rs1, f3, rd, op) =>
  (((imm | 0) & 0xfff) << 20) | ((rs1 & 31) << 15) | ((f3 & 7) << 12) |
  ((rd & 31) << 7) | (op & 0x7f);

const encS = (imm, rs2, rs1, f3, op) => {
  const v = imm | 0;
  return (((v >> 5) & 0x7f) << 25) | ((rs2 & 31) << 20) | ((rs1 & 31) << 15) |
         ((f3 & 7) << 12) | ((v & 0x1f) << 7) | (op & 0x7f);
};

const encB = (imm, rs2, rs1, f3, op) => {
  const v = imm | 0;
  return (((v >> 12) & 1) << 31) | (((v >> 5) & 0x3f) << 25) |
         ((rs2 & 31) << 20) | ((rs1 & 31) << 15) | ((f3 & 7) << 12) |
         (((v >> 1) & 0xf) << 8) | (((v >> 11) & 1) << 7) | (op & 0x7f);
};

const encU = (imm, rd, op) => ((imm | 0) & 0xfffff000) | ((rd & 31) << 7) | (op & 0x7f);

const encJ = (imm, rd, op) => {
  const v = imm | 0;
  return (((v >> 20) & 1) << 31) | (((v >> 1) & 0x3ff) << 21) |
         (((v >> 11) & 1) << 20) | (((v >> 12) & 0xff) << 12) |
         ((rd & 31) << 7) | (op & 0x7f);
};

const OP = 0x33, OPIMM = 0x13, LOAD = 0x03, STORE = 0x23, BRANCH = 0x63,
      LUI = 0x37, AUIPC = 0x17, JAL = 0x6f, JALR = 0x67, SYSTEM = 0x73;

// `li` expansion: lui + addi with rounding correction
function liWords(value, rd) {
  const v = value | 0;
  if (v >= -2048 && v <= 2047) return [encI(v, 0, 0, rd, OPIMM)];
  const hi = ((v + 0x800) >> 12) & 0xfffff;
  const lo = (v - (hi << 12)) | 0;
  return [encU(hi << 12, rd, LUI), encI(lo, rd, 0, rd, OPIMM)];
}

// ---------------------------------------------------------------------------
// Instruction encoding
// ---------------------------------------------------------------------------
function encode(mnem, ops, pc, symbols) {
  const im = (k) => immVal(ops[k], symbols);
  const rg = (k) => reg(ops[k]);

  switch (mnem) {
    case 'add':  return encR(0x00, rg(2), rg(1), 0, rg(0), OP);
    case 'sub':  return encR(0x20, rg(2), rg(1), 0, rg(0), OP);
    case 'sll':  return encR(0x00, rg(2), rg(1), 1, rg(0), OP);
    case 'slt':  return encR(0x00, rg(2), rg(1), 2, rg(0), OP);
    case 'sltu': return encR(0x00, rg(2), rg(1), 3, rg(0), OP);
    case 'xor':  return encR(0x00, rg(2), rg(1), 4, rg(0), OP);
    case 'srl':  return encR(0x00, rg(2), rg(1), 5, rg(0), OP);
    case 'sra':  return encR(0x20, rg(2), rg(1), 5, rg(0), OP);
    case 'or':   return encR(0x00, rg(2), rg(1), 6, rg(0), OP);
    case 'and':  return encR(0x00, rg(2), rg(1), 7, rg(0), OP);
    case 'mul':    return encR(0x01, rg(2), rg(1), 0, rg(0), OP);
    case 'mulh':   return encR(0x01, rg(2), rg(1), 1, rg(0), OP);
    case 'mulhsu': return encR(0x01, rg(2), rg(1), 2, rg(0), OP);
    case 'mulhu':  return encR(0x01, rg(2), rg(1), 3, rg(0), OP);
    case 'div':    return encR(0x01, rg(2), rg(1), 4, rg(0), OP);
    case 'divu':   return encR(0x01, rg(2), rg(1), 5, rg(0), OP);
    case 'rem':    return encR(0x01, rg(2), rg(1), 6, rg(0), OP);
    case 'remu':   return encR(0x01, rg(2), rg(1), 7, rg(0), OP);

    case 'addi':  return encI(im(2), rg(1), 0, rg(0), OPIMM);
    case 'slti':  return encI(im(2), rg(1), 2, rg(0), OPIMM);
    case 'sltiu': return encI(im(2), rg(1), 3, rg(0), OPIMM);
    case 'xori':  return encI(im(2), rg(1), 4, rg(0), OPIMM);
    case 'ori':   return encI(im(2), rg(1), 6, rg(0), OPIMM);
    case 'andi':  return encI(im(2), rg(1), 7, rg(0), OPIMM);
    case 'slli':  return encI(im(2) & 31, rg(1), 1, rg(0), OPIMM);
    case 'srli':  return encI(im(2) & 31, rg(1), 5, rg(0), OPIMM);
    case 'srai':  return encI(0x400 | (im(2) & 31), rg(1), 5, rg(0), OPIMM);

    case 'lb': case 'lh': case 'lw': case 'lbu': case 'lhu': {
      const f3 = { lb: 0, lh: 1, lw: 2, lbu: 4, lhu: 5 }[mnem];
      const m = String(ops[1]).match(/^(.*)\((\w+)\)$/);
      if (!m) throw new Error('bad load operand: ' + ops[1]);
      return encI(immVal(m[1].trim() || '0', symbols), reg(m[2]), f3, rg(0), LOAD);
    }
    case 'sb': case 'sh': case 'sw': {
      const f3 = { sb: 0, sh: 1, sw: 2 }[mnem];
      const m = String(ops[1]).match(/^(.*)\((\w+)\)$/);
      if (!m) throw new Error('bad store operand: ' + ops[1]);
      return encS(immVal(m[1].trim() || '0', symbols), rg(0), reg(m[2]), f3, STORE);
    }

    case 'beq': case 'bne': case 'blt': case 'bge': case 'bltu': case 'bgeu': {
      const f3 = { beq: 0, bne: 1, blt: 4, bge: 5, bltu: 6, bgeu: 7 }[mnem];
      return encB(im(2) - pc, rg(1), rg(0), f3, BRANCH);
    }

    case 'jal':
      if (ops.length === 1) return encJ(im(0) - pc, 1, JAL);
      return encJ(im(1) - pc, rg(0), JAL);
    case 'jalr':
      if (ops.length === 1) return encI(0, rg(0), 0, 1, JALR);
      if (ops.length === 2) return encI(0, rg(1), 0, rg(0), JALR);
      return encI(im(2), rg(1), 0, rg(0), JALR);

    case 'lui':   return encU(im(1), rg(0), LUI);
    case 'auipc': return encU(im(1), rg(0), AUIPC);

    case 'ecall':  return 0x00000073;
    case 'ebreak': return 0x00100073;
    case 'mret':   return 0x30200073;
    case 'wfi':    return 0x10500073;
    case 'fence':  return 0x0ff0000f;

    case 'csrrw':  return encI(csrNum(ops[1]), rg(2), 1, rg(0), SYSTEM);
    case 'csrrs':  return encI(csrNum(ops[1]), rg(2), 2, rg(0), SYSTEM);
    case 'csrrc':  return encI(csrNum(ops[1]), rg(2), 3, rg(0), SYSTEM);
    case 'csrrwi': return encI(csrNum(ops[1]), im(2), 5, rg(0), SYSTEM);
    case 'csrrsi': return encI(csrNum(ops[1]), im(2), 6, rg(0), SYSTEM);
    case 'csrrci': return encI(csrNum(ops[1]), im(2), 7, rg(0), SYSTEM);

    // ---- pseudo ----
    case 'nop':  return 0x00000013;
    case 'mv':   return encI(0, rg(1), 0, rg(0), OPIMM);
    case 'not':  return encI(-1, rg(1), 4, rg(0), OPIMM);
    case 'neg':  return encR(0x20, rg(1), 0, 0, rg(0), OP);
    case 'seqz': return encI(1, rg(1), 3, rg(0), OPIMM);
    case 'j':    return encJ(im(0) - pc, 0, JAL);
    case 'jr':   return encI(0, rg(0), 0, 0, JALR);
    case 'ret':  return encI(0, 1, 0, 0, JALR);
    case 'call': return encJ(im(0) - pc, 1, JAL);
    case 'beqz': return encB(im(1) - pc, 0, rg(0), 0, BRANCH);
    case 'bnez': return encB(im(1) - pc, 0, rg(0), 1, BRANCH);
    case 'csrr': return encI(csrNum(ops[1]), 0, 2, rg(0), SYSTEM);
    case 'csrw': return encI(csrNum(ops[0]), rg(1), 1, 0, SYSTEM);
    case 'csrs': return encI(csrNum(ops[0]), rg(1), 2, 0, SYSTEM);
    case 'csrc': return encI(csrNum(ops[0]), rg(1), 3, 0, SYSTEM);
    case 'csrwi': return encI(csrNum(ops[0]), im(1), 5, 0, SYSTEM);
    case 'csrci': return encI(csrNum(ops[0]), im(1), 7, 0, SYSTEM);
    case 'csrsi': return encI(csrNum(ops[0]), im(1), 6, 0, SYSTEM);
    case 'li': case 'la':
      return liWords(im(1), rg(0))[0];   // length handled by pre-pass
    default:
      throw new Error('unknown mnemonic: ' + mnem);
  }
}

// ---------------------------------------------------------------------------
// Two-pass assembly
// ---------------------------------------------------------------------------
const DIRECTIVE_NOOP = new Set(['.text', '.data', '.globl', '.global', '.align',
                                '.option', '.section', '.type', '.size']);

function isLiLine(line) {
  const m = line.match(/^\s*(li|la)\s+([^,]+),\s*(.+)$/i);
  return m ? { rd: m[2].trim(), expr: m[3].trim() } : null;
}

function sizeOfLine(line, symbols) {
  const mnem = line.split(/\s+/)[0].toLowerCase();
  const rest = line.slice(mnem.length).trim();
  if (mnem === '.org') return { org: immVal(rest, symbols) };
  if (mnem === '.equ' || mnem === '.set') {
    const parts = rest.split(',').map(s => s.trim());
    symbols[parts[0]] = immVal(parts[1], symbols);
    return { size: 0 };
  }
  if (mnem === '.word' || mnem === '.int' || mnem === '.long')
    return { size: 4 * rest.split(',').length };
  if (mnem === '.byte') return { size: rest.split(',').length };
  if (mnem === '.ascii' || mnem === '.asciz' || mnem === '.string') {
    const mm = rest.match(/^"(.*)"$/);
    let s = mm ? mm[1].replace(/\\r/g, '\r').replace(/\\n/g, '\n')
                        .replace(/\\0/g, '\0').replace(/\\t/g, '\t') : '';
    if (mnem !== '.ascii') s += '\0';
    return { size: s.length };
  }
  if (DIRECTIVE_NOOP.has(mnem)) return { size: 0 };
  return { size: 4 };
}

// One label/address sweep.  Kept as a function because the sweep is repeated
// until the symbol table stops changing (see build() below).
function pass1(raw, baseAddr, seed) {
  const symbols = { ...seed };
  let pc = baseAddr;
  for (const sourceLine of raw) {
    let line = clean(sourceLine);
    if (!line) continue;

    let lm;
    while ((lm = line.match(/^([A-Za-z_.$][\w.$]*)\s*:\s*(.*)$/))) {
      symbols[lm[1]] = pc;
      line = lm[2].trim();
      if (!line) break;
    }
    if (!line) continue;

    const li = isLiLine(line);
    if (li) {
      // `li`/`la` are 1 word (fits in an I-type immediate) or 2.  Charging a
      // flat 2 words here shifts every later label relative to what pass 2
      // emits, which is how labels used to resolve into the string table.
      let n;
      try { n = liWords(immVal(li.expr, symbols), 0).length; }
      catch (e) { n = 2; }        // forward reference: assume the longer form
      pc += n * 4;
      continue;
    }

    const r = sizeOfLine(line, symbols);
    if (r.org !== undefined) pc = r.org;
    else pc += r.size;
  }
  return symbols;
}

function build(text, baseAddr) {
  const raw = text.split(/\r?\n/);

  // ---- pass 1: labels and addresses -------------------------------------
  // Iterated: an `li` whose value is a later label is assumed to be 2 words on
  // the first sweep and is re-measured once that label is known.  Two or three
  // sweeps are normally enough; the limit only guards against a cycle.
  let symbols = {};
  SYM = symbols;
  let pc = baseAddr;
  for (let iter = 0; iter < 8; iter++) {
    const next = pass1(raw, baseAddr, symbols);
    const stable = JSON.stringify(next) === JSON.stringify(symbols);
    symbols = next;
    SYM = symbols;
    if (stable) break;
  }

  // ---- pass 2: emit ------------------------------------------------------
  const words = [];
  pc = baseAddr;
  for (const sourceLine of raw) {
    let line = clean(sourceLine);
    if (!line) continue;

    let lm;
    while ((lm = line.match(/^([A-Za-z_.$][\w.$]*)\s*:\s*(.*)$/))) {
      line = lm[2].trim();
      if (!line) break;
    }
    if (!line) continue;

    const li = isLiLine(line);
    if (li) {
      const v = immVal(li.expr, symbols);
      for (const w of liWords(v, reg(li.rd))) {
        words.push({ addr: pc, word: w >>> 0, size: 4 });
        pc += 4;
      }
      continue;
    }

    const parts = line.split(/\s+/);
    const mnem = parts[0].toLowerCase();
    const rest = line.slice(parts[0].length).trim();

    if (mnem === '.org') { pc = immVal(rest, symbols); continue; }
    if (mnem === '.equ' || mnem === '.set') continue;
    if (mnem === '.word' || mnem === '.int' || mnem === '.long') {
      for (const t of rest.split(',')) {
        words.push({ addr: pc, word: immVal(t.trim(), symbols) >>> 0, size: 4 });
        pc += 4;
      }
      continue;
    }
    if (mnem === '.byte') {
      for (const t of rest.split(',')) {
        words.push({ addr: pc, word: immVal(t.trim(), symbols) & 0xff, size: 1 });
        pc += 1;
      }
      continue;
    }
    if (mnem === '.ascii' || mnem === '.asciz' || mnem === '.string') {
      const m = rest.match(/^"(.*)"$/);
      if (!m) throw new Error('bad string: ' + line);
      let s = m[1].replace(/\\r/g, '\r').replace(/\\n/g, '\n')
                   .replace(/\\0/g, '\0').replace(/\\t/g, '\t');
      if (mnem !== '.ascii') s += '\0';
      for (const ch of s) {
        words.push({ addr: pc, word: ch.charCodeAt(0) & 0xff, size: 1 });
        pc += 1;
      }
      continue;
    }
    if (DIRECTIVE_NOOP.has(mnem)) continue;

    const ops = rest ? rest.split(',').map(s => s.trim()) : [];
    words.push({ addr: pc, word: encode(mnem, ops, pc, symbols) >>> 0, size: 4 });
    pc += 4;
  }

  return { symbols, words };
}

function clean(line) {
  return line.replace(/\/\/.*$/, '').replace(/#.*$/, '').replace(/;.*$/, '').trim();
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------
function main() {
  const [, , inp, outp, lstp] = process.argv;
  if (!inp || !outp) {
    console.error('usage: as.js <input.S> <output.hex> [listing.lst]');
    process.exit(2);
  }
  const text = fs.readFileSync(inp, 'utf8');
  const orgMatch = text.match(/^\s*\.org\s+(\S+)/m);
  const base = orgMatch ? immVal(orgMatch[1], {}) : 0;

  const { symbols, words } = build(text, base);

  const minAddr = Math.min(...words.map(w => w.addr));
  const maxAddr = Math.max(...words.map(w => w.addr + (w.size === 1 ? 0 : 3)));
  const nBytes = (maxAddr - minAddr + 4) & ~3;
  const bytes = new Uint8Array(nBytes);
  for (const w of words) {
    const off = w.addr - minAddr;
    if (w.size === 1) {
      bytes[off] = w.word & 0xff;
    } else {
      bytes[off]     = (w.word >>> 0) & 0xff;
      bytes[off + 1] = ((w.word >>> 8)) & 0xff;
      bytes[off + 2] = ((w.word >>> 16)) & 0xff;
      bytes[off + 3] = ((w.word >>> 24)) & 0xff;
    }
  }
  const img = [];
  for (let o = 0; o < nBytes; o += 4) {
    img.push(((bytes[o + 3] << 24) | (bytes[o + 2] << 16) |
              (bytes[o + 1] << 8) | bytes[o]) >>> 0);
  }

  fs.writeFileSync(outp, img.map(w => w.toString(16).padStart(8, '0')).join('\n') + '\n');

  if (lstp) {
    const lines = words.map(w =>
      `${w.addr.toString(16).padStart(8, '0')}: ${w.word.toString(16).padStart(8, '0')}`);
    lines.push('', 'Symbols:');
    for (const k of Object.keys(symbols))
      lines.push(`  ${k.padEnd(24)} 0x${(symbols[k] >>> 0).toString(16).padStart(8, '0')}`);
    fs.writeFileSync(lstp, lines.join('\n') + '\n');
  }

  console.log(`assembled ${words.filter(w => w.size === 4).length} words -> ${outp} ` +
              `(base 0x${minAddr.toString(16)}, image ${img.length} words)`);
}

if (require.main === module) main();
module.exports = { build, liWords, encode };
