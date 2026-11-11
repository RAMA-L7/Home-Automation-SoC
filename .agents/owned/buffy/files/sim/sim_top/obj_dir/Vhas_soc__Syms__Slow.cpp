// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vhas_soc__pch.h"

Vhas_soc__Syms::Vhas_soc__Syms(VerilatedContext* contextp, const char* namep, Vhas_soc* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    , __Vm_didInit{modelp->m_didInit}
    // Setup top module instance
    , TOP{this, namep}
{
    // Check resources
    Verilated::stackCheck(569);
    // Setup sub module instances
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-12);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
}

Vhas_soc__Syms::~Vhas_soc__Syms() {
    // Tear down scopes
    // Tear down sub module instances
}
