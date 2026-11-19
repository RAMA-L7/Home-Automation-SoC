# Techmap unit probes for the `$pmux` rule in build/asic_evidence/sky130_map.v.
#
# Each module contains exactly one $pmux cell and nothing else, so a mapping
# error cannot be hidden by surrounding logic. The cells are written directly in
# RTLIL because inference from Verilog is free to rewrite $pmux into $mux before
# techmap ever sees it - the rule under test would then never be exercised.
#
# Parameters of interest:
#   WIDTH   = width of A, Y and of each B slice
#   S_WIDTH = number of select bits

# The defect: one select bit with a vector payload.
module \pmux_s1_w8
  wire width 8 input 1 \a
  wire width 8 input 2 \b
  wire input 3 \s
  wire width 8 output 4 \y
  cell $pmux \u
    parameter \WIDTH 8
    parameter \S_WIDTH 1
    connect \A \a
    connect \B \b
    connect \S \s
    connect \Y \y
  end
end

# Control: multi-select chain (already instantiates one cell per bit).
module \pmux_s3_w8
  wire width 8  input 1 \a
  wire width 24 input 2 \b
  wire width 3  input 3 \s
  wire width 8  output 4 \y
  cell $pmux \u
    parameter \WIDTH 8
    parameter \S_WIDTH 3
    connect \A \a
    connect \B \b
    connect \S \s
    connect \Y \y
  end
end

# Control: scalar payload, the only case the single-select branch handles today.
module \pmux_s1_w1
  wire input 1 \a
  wire input 2 \b
  wire input 3 \s
  wire output 4 \y
  cell $pmux \u
    parameter \WIDTH 1
    parameter \S_WIDTH 1
    connect \A \a
    connect \B \b
    connect \S \s
    connect \Y \y
  end
end
