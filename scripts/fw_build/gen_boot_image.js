#!/usr/bin/env node
/*
 * Home-Automation-SoC — assemble the production boot ROM image.
 *
 * The production boot path is: boot ROM -> loader -> TCM/SRAM -> payload.
 * Nothing is preloaded into the memories, so this script exists to build the
 * one artifact that path needs: a 16 KiB ROM image containing
 *
 *   0x0000  loader code            (firmware/boot/loader.S)
 *   0x0800  boot header            (written here, from the payload's real size)
 *   0x1000  TCM image              (payload words [0, 0x400))
 *   0x2000  .data image            (payload words [0x400, end))
 *
 * and to record the numbers it used, so a run can be checked against the image
 * instead of trusted.
 *
 * Usage:
 *   node scripts/fw_build/gen_boot_image.js [--out build/fw/boot_rom.hex]
 *
 * Exits 2 if a piece does not fit the 16 KiB ROM or the 32 KiB TCM — an
 * oversized image must fail the build, not be silently truncated.
 */
const { spawnSync } = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.join(ROOT, 'build', 'fw');

const ROM_BYTES = 16 * 1024;
const ROM_WORDS = ROM_BYTES / 4;
const TCM_BYTES = 32 * 1024;
const TCM_WORDS = TCM_BYTES / 4;

const HDR_WORD = 0x0800 / 4;      // 512
const TCM_SRC_WORD = 0x1000 / 4;  // 1024
const DATA_IMAGE_WORD = 0x3C0;    // 0x0F00/4: payload split point (see payload.S)

const DATA_DST = 0x20000000;
const TCM_DST = 0x00010000;

function assemble(src, hexOut, lstOut) {
  const r = spawnSync(process.execPath,
    [path.join(ROOT, 'scripts', 'fw', 'as.js'), src, hexOut, lstOut],
    { cwd: ROOT, encoding: 'utf8' });
  if (r.status !== 0) {
    console.error(`FATAL: assembling ${src} failed (exit ${r.status})\n${r.stdout || ''}${r.stderr || ''}`);
    process.exit(r.status || 1);
  }
  const words = fs.readFileSync(hexOut, 'utf8')
    .split('\n').map(l => l.trim()).filter(Boolean);
  return words;
}

const loaderWords = assemble('firmware/boot/loader.S',
  path.join(OUT, 'loader.hex'), path.join(OUT, 'loader.lst'));
const payloadWords = assemble('firmware/boot/payload.S',
  path.join(OUT, 'payload.hex'), path.join(OUT, 'payload.lst'));

const tcmWords = Math.min(DATA_IMAGE_WORD, payloadWords.length);
const dataWords = Math.max(0, payloadWords.length - DATA_IMAGE_WORD);

if (payloadWords.length < DATA_IMAGE_WORD) {
  console.error(`FATAL: payload image is ${payloadWords.length} words, shorter than the ` +
                `${DATA_IMAGE_WORD}-word split point; .data would be empty`);
  process.exit(2);
}
if (tcmWords > TCM_WORDS) {
  console.error(`FATAL: TCM image ${tcmWords} words exceeds ${TCM_WORDS} words of TCM`);
  process.exit(2);
}
if (HDR_WORD < loaderWords.length) {
  console.error(`FATAL: loader is ${loaderWords.length} words and overruns the header at 0x0800`);
  process.exit(2);
}
if (TCM_SRC_WORD + tcmWords + dataWords > ROM_WORDS) {
  console.error('FATAL: loader + images do not fit the 16 KiB boot ROM');
  process.exit(2);
}

const rom = new Array(ROM_WORDS).fill('00000000');
const put = (wordIndex, words) => {
  for (let i = 0; i < words.length; i++) rom[wordIndex + i] = words[i].padStart(8, '0');
};

put(0, loaderWords);
put(TCM_SRC_WORD, payloadWords.slice(0, tcmWords));
put(TCM_SRC_WORD + tcmWords, payloadWords.slice(DATA_IMAGE_WORD));

const bssAddress = DATA_DST + dataWords * 4;
const header = [
  TCM_DST,
  tcmWords,
  DATA_DST,
  dataWords,
  bssAddress,
  1,                              // one bss word (payload.S: BSS_ADDR)
  TCM_DST,                        // payload entry
  (TCM_SRC_WORD + tcmWords) * 4,  // .data image offset inside the ROM
];
put(HDR_WORD, header.map(v => (v >>> 0).toString(16)));

const outHex = process.argv.includes('--out')
  ? process.argv[process.argv.indexOf('--out') + 1]
  : path.join(OUT, 'boot_rom.hex');
fs.writeFileSync(outHex, rom.join('\n') + '\n');

const sha256 = crypto.createHash('sha256').update(fs.readFileSync(outHex)).digest('hex');
const info = {
  generated_by: 'scripts/fw_build/gen_boot_image.js',
  loader: { source: 'firmware/boot/loader.S', words: loaderWords.length },
  payload: {
    source: 'firmware/boot/payload.S',
    words: payloadWords.length,
    tcm_words: tcmWords,
    data_words: dataWords,
  },
  rom: { bytes: ROM_BYTES, words: ROM_WORDS, loader_at: 0, header_at: 0x0800,
         tcm_image_at: 0x1000, data_image_at: (TCM_SRC_WORD + tcmWords) * 4 },
  header: {
    tcm_dst: TCM_DST, tcm_words: tcmWords, data_dst: DATA_DST, data_words: dataWords,
    bss_dst: bssAddress, bss_words: 1, entry: TCM_DST,
    data_src: (TCM_SRC_WORD + tcmWords) * 4,
  },
  objects: { sim_mem_preload: false },
  output: { path: path.relative(ROOT, outHex).replace(/\\/g, '/'), sha256 },
};
fs.writeFileSync(path.join(OUT, 'boot_rom.json'), JSON.stringify(info, null, 2) + '\n');

console.log(`boot image: loader ${loaderWords.length} words, payload ${payloadWords.length} words ` +
            `(tcm ${tcmWords}, data ${dataWords}), bss at 0x${bssAddress.toString(16)}`);
console.log(`wrote ${path.relative(ROOT, outHex)} sha256 ${sha256}`);
