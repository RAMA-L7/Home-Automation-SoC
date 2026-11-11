// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VHAS_SOC__SYMS_H_
#define VERILATED_VHAS_SOC__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vhas_soc.h"

// INCLUDE MODULE CLASSES
#include "Vhas_soc___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES) Vhas_soc__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vhas_soc* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool& __Vm_didInit;

    // MODULE INSTANCE STATE
    Vhas_soc___024root             TOP;

    // CONSTRUCTORS
    Vhas_soc__Syms(VerilatedContext* contextp, const char* namep, Vhas_soc* modelp);
    ~Vhas_soc__Syms();

    // METHODS
    const char* name() const { return TOP.vlNamep; }
};

#endif  // guard
