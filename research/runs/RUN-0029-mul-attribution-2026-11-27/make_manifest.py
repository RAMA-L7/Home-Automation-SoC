"""RUN-0029: build manifest.json from the files actually present."""
import glob
import hashlib
import json
import os

R = 'research/runs/RUN-0029-mul-attribution-2026-11-27'


def sha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def rel(p):
    return p.replace(os.sep, '/')


m = {
    "run": "RUN-0029-mul-attribution-2026-11-27",
    "date_utc": "2026-11-27T17:45Z/2026-11-28T00:15Z",
    "purpose": "Prove or refute that the 21.00 ns residual critical path is the "
               "RV32M multiplier cone, then characterise all four variants.",
    "verdict": "REFUTED. The path is the single-cycle pc -> alu_a mux -> ALU adder -> "
               "mem_misaligned/exception -> pc_next loop. No RTL changed.",
    "baseline_commit": "83b7e01",
    "tools": {
        "yosys": "0.69+154",
        "opensta": "3.1.0",
        "pdk": "sky130A volare 0fe599b2afb6708d281543108caf8310912f54af",
        "lib": "sky130_fd_sc_hd__tt_025C_1v80",
    },
    "inputs": {p: sha(p) for p in [
        "rtl/rtl_top/riscv_core.sv",
        "rtl/rtl_top/sram_macro_wrap.sv",
        "constraints/timing_constraints/has_soc.sdc",
        "scripts/sta/synth_has_soc.ys",
        "scripts/sta/abc.constr",
        "scripts/sta/has_soc_sta.tcl",
    ]},
    "ablations": [
        {"tag": "nomul", "source": R + "/ablation/riscv_core_nomul.sv",
         "source_sha256": sha(R + "/ablation/riscv_core_nomul.sv"),
         "netlist_sha256": sha("build/sta/has_soc_gate_nomul.v"),
         "cells": 32314, "wns_ns": -1.8205935052617357, "tns_ns": -1110.9098382305087},
        {"tag": "uuonly", "source": R + "/ablation/riscv_core_uuonly.sv",
         "source_sha256": sha(R + "/ablation/riscv_core_uuonly.sv"),
         "netlist_sha256": sha("build/sta/has_soc_gate_uuonly.v"),
         "cells": 37901, "wns_ns": -2.210967471685704, "tns_ns": -2289.0324736913217},
        {"tag": "noadd", "source": R + "/ablation/riscv_core_noadd.sv",
         "source_sha256": sha(R + "/ablation/riscv_core_noadd.sv"),
         "netlist_sha256": sha("build/sta/has_soc_gate_noadd.v"),
         "cells": 44723, "wns_ns": -1.200676925201719, "tns_ns": -1051.4167185603426},
    ],
    "flow_checks": [
        {"tag": "sanitized", "netlist_sha256": sha("build/sta/has_soc_gate_sanitized.v"),
         "wns_ns": -1.2141488158527418, "tns_ns": -107.65510743128912,
         "note": "plain identifiers, no escaped names: identical to baseline"},
        {"tag": "pcb2x", "netlist_sha256": sha("build/sta/has_soc_gate_pcb2x.v"),
         "wns_ns": -1.2141488158527418, "tns_ns": -107.65510743128912,
         "note": "core.pc bit-blasted with part-selects expanded: identical to baseline"},
        {"tag": "pcb", "netlist_sha256": sha("build/sta/has_soc_gate_pcb.v"),
         "wns_ns": 0.7128378089570354,
         "note": "INVALID: first bit-blast left part-selects dangling; kept only as a negative control"},
    ],
    "probe": {"source": R + "/probe/mul_probe.sv", "sdc": R + "/probe/probe.sdc",
              "netlist_sha256": sha("build/sta/mul_probe_gate.v"),
              "wns_setup_ns": 7.0887351328642785, "wns_hold_ns": 0.5288996057486905,
              "result": "PASS", "worst_variant": "MULHU"},
    "baseline_reproduced": {"netlist_sha256": sha("build/sta/has_soc_gate.v"),
                            "wns_ns": -1.2141488158527418,
                            "tns_ns": -107.65510743128912, "registers": 3594},
    "critical_path": {
        "arrival_ns": 21.0033, "cells": 57, "maj3": 23, "mux2": 6, "clkbuf_1": 5,
        "startpoint": "_64744_ Q=core.pc[2]", "endpoint": "_66077_ D=core.pc[31]",
        "segments_ns": {"c2q": 0.3109, "pc_net_buffers": 4.8684, "alu_a_mux": 0.6540,
                        "alu_adder_chain": 9.0980, "align_exception": 4.4816,
                        "pc_next_select": 1.5904},
    },
    "files": {rel(p): sha(p) for p in sorted(glob.glob(R + '/**/*', recursive=True))
              if os.path.isfile(p)},
}

with open(R + '/manifest.json', 'w', encoding='utf8', newline='\n') as f:
    json.dump(m, f, indent=2)
    f.write('\n')
print('files hashed: %d' % len(m['files']))
print('manifest bytes: %d' % os.path.getsize(R + '/manifest.json'))
