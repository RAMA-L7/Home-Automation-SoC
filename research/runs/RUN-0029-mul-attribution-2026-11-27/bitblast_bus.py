"""RUN-0029: bit-blast one escaped bus in the gate netlist.

The Yosys netlist declares `wire [31:0] \\core.pc ;` and references bits as
`\\core.pc [k]`. This rewrites that single bus into 32 scalar nets so no bus
remains to be interpreted by the reader. Pure renaming + splitting: every
connection is preserved.

  python bitblast_bus.py <in.v> <out.v> <escaped bus name, e.g. core.pc>
"""
import re
import sys

src_path, out_path, bus = sys.argv[1], sys.argv[2], sys.argv[3]

src = open(src_path, encoding='utf8', errors='replace').read()

decl = re.compile(r'wire\s+\[\s*(\d+)\s*:\s*0\s*\]\s*\\' + re.escape(bus) + r'\s*;')
m = decl.search(src)
if not m:
    sys.exit('declaration of \\%s not found' % bus)
width = int(m.group(1)) + 1

flat = ['wire %s_bit_%d ;' % (bus.replace('.', '_'), k) for k in range(width)]
src = decl.sub(' '.join(flat), src, count=1)

# references: \core.pc [k] and part-selects \core.pc [hi:lo]
ref = re.compile(r'\\' + re.escape(bus) + r'\s*\[\s*(\d+)\s*(?::\s*(\d+)\s*)?\]')
join = bus.replace('.', '_') + '_bit_'


def repl(m):
    hi = int(m.group(1))
    lo = int(m.group(2)) if m.group(2) is not None else hi
    if max(hi, lo) >= width:
        sys.exit('bits [%d:%d] out of range for \\%s' % (hi, lo, bus))
    if hi == lo:
        return join + str(hi)
    return '{' + ', '.join(join + str(k) for k in range(hi, lo - 1, -1)) + '}'


out, n = ref.subn(repl, src)
open(out_path, 'w', encoding='utf8', newline='\n').write(out)
print('bus \\%s: width %d, scalar nets %d, references rewritten %d' % (bus, width, width, n))
print('leftover \\%s references: %d' % (bus, len(re.findall(r'\\' + re.escape(bus) + r'\b', out))))
