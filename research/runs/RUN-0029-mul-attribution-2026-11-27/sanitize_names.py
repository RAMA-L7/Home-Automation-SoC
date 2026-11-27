"""RUN-0029: rewrite escaped identifiers in the gate netlist to plain names.

Pure renaming: every escaped identifier (Yosys writes buses as `\\core.pc`
plus a bit select) becomes an ordinary identifier, so the Verilog reader has
nothing to interpret. No connectivity, cell or pin changes.

  python sanitize_names.py <in.v> <out.v>
"""
import re
import sys
import collections

src_path, out_path = sys.argv[1], sys.argv[2]
src = open(src_path, encoding='utf8', errors='replace').read()

mapping = {}


def sanitize(m):
    raw = m.group(1)
    if raw not in mapping:
        s = re.sub(r'[^A-Za-z0-9_]', '_', raw)
        if not s or s[0].isdigit():
            s = 'e_' + s
        mapping[raw] = s
    return mapping[raw]


out = re.sub(r'\\([^\s(){};,]+)', sanitize, src)
open(out_path, 'w', encoding='utf8', newline='\n').write(out)

vals = list(mapping.values())
dups = [v for v, c in collections.Counter(vals).items() if c > 1]
print('escaped identifiers: %d' % len(mapping))
print('unique sanitized:    %d' % len(set(vals)))
print('collisions:          %s' % (dups[:5] if dups else 'none'))
print('backslash remaining: %d' % out.count(chr(92)))
