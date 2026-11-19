// Minimal behavioural model of the one cell the $pmux rule instantiates.
//
// It is deliberately not the whole stub library: `flatten` of a design that
// contains the full stub segfaults Yosys 0.69+154 here, and only mux2_1 is
// needed. The function is the library's own:
//   build/asic_evidence/sky130_full_subset.lib, cell sky130_fd_sc_hd__mux2_1,
//   pin X, function : "(A0&!S) | (A1&S)"
// and it is identical to build/asic_evidence/arith_work/sky130_stub.v.
//
// Read this file AFTER `techmap -map sky130_map.v`: otherwise the map file also
// expands the $not/$and/$or cells this model is written with, and the
// equivalence check then sees undefined sky130 cells inside the model.

module sky130_fd_sc_hd__mux2_1 (input A0, input A1, input S, output X);
  assign X = (A0 & ~S) | (A1 & S);
endmodule
