// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vhas_soc.h for the primary calling header

#include "Vhas_soc__pch.h"

void Vhas_soc___024root___ctor_var_reset(Vhas_soc___024root* vlSelf);

Vhas_soc___024root::Vhas_soc___024root(Vhas_soc__Syms* symsp, const char* namep)
 {
    vlSymsp = symsp;
    vlNamep = strdup(namep);
    // Reset structure values
    Vhas_soc___024root___ctor_var_reset(this);
}

Vhas_soc___024root::~Vhas_soc___024root() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}
