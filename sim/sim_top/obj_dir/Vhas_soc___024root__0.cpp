// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vhas_soc.h for the primary calling header

#include "Vhas_soc__pch.h"

void Vhas_soc___024root___eval_sample(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_sample\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vhas_soc___024root___eval_triggers_vec__ico(Vhas_soc___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vhas_soc___024root___dump_triggers__ico(const VlUnpacked<QData/*63:0*/, 2> &triggers, const std::string &tag);
#endif  // VL_DEBUG
bool Vhas_soc___024root___trigger_anySet__ico(const VlUnpacked<QData/*63:0*/, 2> &in);

bool Vhas_soc___024root___eval_ico(Vhas_soc___024root* vlSelf, CData/*0:0*/ firstIteration) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_ico\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VicoExecute;
    // Body
    vlSelfRef.__VicoTriggered[1U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VicoTriggered[1U]) 
                                     | (IData)((IData)(firstIteration)));
    Vhas_soc___024root___eval_triggers_vec__ico(vlSelf);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vhas_soc___024root___dump_triggers__ico(vlSelfRef.__VicoTriggered, "ico"s);
    }
#endif
    __VicoExecute = Vhas_soc___024root___trigger_anySet__ico(vlSelfRef.__VicoTriggered);
    if (__VicoExecute) {
        {
            // Inlined CFunc: _eval_body__ico
            if ((2ULL & vlSelfRef.__VicoTriggered[0U])) {
                {
                    // Inlined CFunc: _ico_sequent__TOP__0
                    vlSelfRef.has_soc__DOT__presetn 
                        = vlSelfRef.reset_n;
                }
            }
            if ((0x0000000000000400ULL & vlSelfRef.__VicoTriggered[0U])) {
                {
                    // Inlined CFunc: _ico_sequent__TOP__1
                    vlSelfRef.wake_req = ((0U != (IData)(vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state)) 
                                          & ((IData)(vlSelfRef.wake_ack) 
                                             & (1U 
                                                == (IData)(vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state))));
                }
            }
            if ((1ULL & vlSelfRef.__VicoTriggered[0U])) {
                {
                    // Inlined CFunc: _ico_sequent__TOP__2
                    vlSelfRef.has_soc__DOT__core_clk 
                        = ((IData)(vlSelfRef.clk) & 
                           (1U != (IData)(vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state)));
                    vlSelfRef.has_soc__DOT__pclk = vlSelfRef.has_soc__DOT__core_clk;
                    vlSelfRef.i2s_bclk = vlSelfRef.has_soc__DOT__pclk;
                }
            }
        }
    }
    return (__VicoExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vhas_soc___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
void Vhas_soc___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in);

bool Vhas_soc___024root___eval_act(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_act\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    {
        // Inlined CFunc: _eval_triggers_vec__act
        vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                        ((((~ (IData)(vlSelfRef.has_soc__DOT__presetn)) 
                                                           & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__has_soc__DOT__presetn__0)) 
                                                          << 4U) 
                                                         | (((((IData)(vlSelfRef.has_soc__DOT__pclk) 
                                                               & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__has_soc__DOT__pclk__0))) 
                                                              << 3U) 
                                                             | (((IData)(vlSelfRef.clk) 
                                                                 & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__clk__1))) 
                                                                << 2U)) 
                                                            | ((((~ (IData)(vlSelfRef.reset_n)) 
                                                                 & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__reset_n__1)) 
                                                                << 1U) 
                                                               | ((IData)(vlSelfRef.has_soc__DOT__core_clk) 
                                                                  & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__has_soc__DOT__core_clk__0))))))));
        vlSelfRef.__Vtrigprevexpr___TOP__has_soc__DOT__core_clk__0 
            = vlSelfRef.has_soc__DOT__core_clk;
        vlSelfRef.__Vtrigprevexpr___TOP__reset_n__1 
            = vlSelfRef.reset_n;
        vlSelfRef.__Vtrigprevexpr___TOP__clk__1 = vlSelfRef.clk;
        vlSelfRef.__Vtrigprevexpr___TOP__has_soc__DOT__pclk__0 
            = vlSelfRef.has_soc__DOT__pclk;
        vlSelfRef.__Vtrigprevexpr___TOP__has_soc__DOT__presetn__0 
            = vlSelfRef.has_soc__DOT__presetn;
    }
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vhas_soc___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
    Vhas_soc___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    return (0U);
}

bool Vhas_soc___024root___eval_inact(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_inact\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    return (0U);
}

bool Vhas_soc___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);
void Vhas_soc___024root___eval_body__nba(Vhas_soc___024root* vlSelf);
void Vhas_soc___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out);

bool Vhas_soc___024root___eval_nba(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_nba\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vhas_soc___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        Vhas_soc___024root___eval_body__nba(vlSelf);
        Vhas_soc___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

bool Vhas_soc___024root___eval_obs(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_obs\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    return (0U);
}

bool Vhas_soc___024root___eval_react(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_react\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    return (0U);
}

void Vhas_soc___024root___eval_postponed(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_postponed\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vhas_soc___024root___eval_triggers_vec__ico(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_triggers_vec__ico\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered[0U] = (QData)((IData)(
                                                    (((((IData)(vlSelfRef.wake_ack) 
                                                        != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__wake_ack__0)) 
                                                       << 0x0000000aU) 
                                                      | ((((IData)(vlSelfRef.i2s_din) 
                                                           != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__i2s_din__0)) 
                                                          << 9U) 
                                                         | (((IData)(vlSelfRef.spi_miso) 
                                                             != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__spi_miso__0)) 
                                                            << 8U))) 
                                                     | (((((((IData)(vlSelfRef.uart_rx) 
                                                             != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__uart_rx__0)) 
                                                            << 3U) 
                                                           | ((vlSelfRef.ext_irq 
                                                               != vlSelfRef.__Vtrigprevexpr___TOP__ext_irq__0) 
                                                              << 2U)) 
                                                          | ((((IData)(vlSelfRef.jtag_trst_n) 
                                                               != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__jtag_trst_n__0)) 
                                                              << 1U) 
                                                             | ((IData)(vlSelfRef.jtag_tdi) 
                                                                != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__jtag_tdi__0)))) 
                                                         << 4U) 
                                                        | (((((IData)(vlSelfRef.jtag_tms) 
                                                              != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__jtag_tms__0)) 
                                                             << 3U) 
                                                            | (((IData)(vlSelfRef.jtag_tck) 
                                                                != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__jtag_tck__0)) 
                                                               << 2U)) 
                                                           | ((((IData)(vlSelfRef.reset_n) 
                                                                != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__reset_n__0)) 
                                                               << 1U) 
                                                              | ((IData)(vlSelfRef.clk) 
                                                                 != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__clk__0))))))));
    vlSelfRef.__Vtrigprevexpr___TOP__clk__0 = vlSelfRef.clk;
    vlSelfRef.__Vtrigprevexpr___TOP__reset_n__0 = vlSelfRef.reset_n;
    vlSelfRef.__Vtrigprevexpr___TOP__jtag_tck__0 = vlSelfRef.jtag_tck;
    vlSelfRef.__Vtrigprevexpr___TOP__jtag_tms__0 = vlSelfRef.jtag_tms;
    vlSelfRef.__Vtrigprevexpr___TOP__jtag_tdi__0 = vlSelfRef.jtag_tdi;
    vlSelfRef.__Vtrigprevexpr___TOP__jtag_trst_n__0 
        = vlSelfRef.jtag_trst_n;
    vlSelfRef.__Vtrigprevexpr___TOP__ext_irq__0 = vlSelfRef.ext_irq;
    vlSelfRef.__Vtrigprevexpr___TOP__uart_rx__0 = vlSelfRef.uart_rx;
    vlSelfRef.__Vtrigprevexpr___TOP__spi_miso__0 = vlSelfRef.spi_miso;
    vlSelfRef.__Vtrigprevexpr___TOP__i2s_din__0 = vlSelfRef.i2s_din;
    vlSelfRef.__Vtrigprevexpr___TOP__wake_ack__0 = vlSelfRef.wake_ack;
    if (VL_UNLIKELY(((1U & (~ (IData)(vlSelfRef.__VicoDidInit)))))) {
        vlSelfRef.__VicoDidInit = 1U;
        vlSelfRef.__VicoTriggered[0U] = (1ULL | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (2ULL | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (4ULL | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (8ULL | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000010ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000020ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000040ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000080ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000100ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000200ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000400ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
    }
}

bool Vhas_soc___024root___trigger_anySet__ico(const VlUnpacked<QData/*63:0*/, 2> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___trigger_anySet__ico\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((2U > n));
    return (0U);
}

bool Vhas_soc___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___trigger_anySet__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

void Vhas_soc___024root___nba_sequent__TOP__0(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___nba_sequent__TOP__0\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    SData/*15:0*/ __Vdly__has_soc__DOT__uart_inst__DOT__baud_cnt;
    __Vdly__has_soc__DOT__uart_inst__DOT__baud_cnt = 0;
    CData/*0:0*/ __Vdly__has_soc__DOT__uart_inst__DOT__thre;
    __Vdly__has_soc__DOT__uart_inst__DOT__thre = 0;
    CData/*7:0*/ __Vdly__has_soc__DOT__uart_inst__DOT__tx_shift;
    __Vdly__has_soc__DOT__uart_inst__DOT__tx_shift = 0;
    CData/*3:0*/ __Vdly__has_soc__DOT__uart_inst__DOT__tx_bits;
    __Vdly__has_soc__DOT__uart_inst__DOT__tx_bits = 0;
    CData/*0:0*/ __Vdly__has_soc__DOT__uart_inst__DOT__tx_busy;
    __Vdly__has_soc__DOT__uart_inst__DOT__tx_busy = 0;
    CData/*3:0*/ __Vdly__has_soc__DOT__uart_inst__DOT__rx_bits;
    __Vdly__has_soc__DOT__uart_inst__DOT__rx_bits = 0;
    CData/*7:0*/ __Vdly__has_soc__DOT__uart_inst__DOT__rx_shift;
    __Vdly__has_soc__DOT__uart_inst__DOT__rx_shift = 0;
    CData/*0:0*/ __Vdly__has_soc__DOT__uart_inst__DOT__rx_data_ready;
    __Vdly__has_soc__DOT__uart_inst__DOT__rx_data_ready = 0;
    SData/*15:0*/ __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v0;
    __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v0 = 0;
    SData/*15:0*/ __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v0;
    __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v0 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v0;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v0 = 0;
    SData/*15:0*/ __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v0;
    __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v0 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v0;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v0 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v1;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v1 = 0;
    SData/*15:0*/ __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v1;
    __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v1 = 0;
    SData/*15:0*/ __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v2;
    __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v2 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v2;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v2 = 0;
    SData/*15:0*/ __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v2;
    __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v2 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v2;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v2 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v3;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v3 = 0;
    SData/*15:0*/ __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v2;
    __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v2 = 0;
    SData/*15:0*/ __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v4;
    __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v4 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v4;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v4 = 0;
    SData/*15:0*/ __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v4;
    __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v4 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v4;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v4 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v5;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v5 = 0;
    SData/*15:0*/ __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v3;
    __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v3 = 0;
    SData/*15:0*/ __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v6;
    __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v6 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v6;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v6 = 0;
    SData/*15:0*/ __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v6;
    __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v6 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v6;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v6 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v7;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v7 = 0;
    // Body
    __Vdly__has_soc__DOT__uart_inst__DOT__baud_cnt 
        = vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt;
    __Vdly__has_soc__DOT__uart_inst__DOT__rx_bits = vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_bits;
    __Vdly__has_soc__DOT__uart_inst__DOT__tx_bits = vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_bits;
    __Vdly__has_soc__DOT__uart_inst__DOT__tx_busy = vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_busy;
    __Vdly__has_soc__DOT__uart_inst__DOT__rx_shift 
        = vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_shift;
    vlSelfRef.__Vdly__has_soc__DOT__timer_inst__DOT__count 
        = vlSelfRef.has_soc__DOT__timer_inst__DOT__count;
    __Vdly__has_soc__DOT__uart_inst__DOT__thre = vlSelfRef.has_soc__DOT__uart_inst__DOT__thre;
    __Vdly__has_soc__DOT__uart_inst__DOT__rx_data_ready 
        = vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_data_ready;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v0 = 0U;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v2 = 0U;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v4 = 0U;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v6 = 0U;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v0 = 0U;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v2 = 0U;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v4 = 0U;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v6 = 0U;
    vlSelfRef.__Vdly__has_soc__DOT__timer_inst__DOT__match_pend 
        = vlSelfRef.has_soc__DOT__timer_inst__DOT__match_pend;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v1 = 0U;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v3 = 0U;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v5 = 0U;
    __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v7 = 0U;
    vlSelfRef.__Vdly__has_soc__DOT__wdog_inst__DOT__count 
        = vlSelfRef.has_soc__DOT__wdog_inst__DOT__count;
    __Vdly__has_soc__DOT__uart_inst__DOT__tx_shift 
        = vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_shift;
    vlSelfRef.__Vdly__has_soc__DOT__gpio_inst__DOT__int_pend 
        = vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_pend;
    if ((1U & (~ (IData)(vlSelfRef.has_soc__DOT__presetn)))) {
        vlSelfRef.has_soc__DOT__spi_inst__DOT__rx_data = 0U;
        vlSelfRef.has_soc__DOT__pwrmgr_inst__DOT__in_sleep = 0U;
    }
    vlSelfRef.has_soc__DOT__pwrmgr_inst__DOT__in_sleep 
        = vlSelfRef.has_soc__DOT__pwrmgr_inst__DOT__sleep_req;
    vlSelfRef.pwm_out = ((0x0eU & (IData)(vlSelfRef.pwm_out)) 
                         | ((IData)(vlSelfRef.has_soc__DOT__presetn) 
                            && ((1U & (IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__enable)) 
                                && (vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[0U] 
                                    < vlSelfRef.has_soc__DOT__pwm_inst__DOT__duty[0U]))));
    vlSelfRef.pwm_out = ((0x0dU & (IData)(vlSelfRef.pwm_out)) 
                         | (((IData)(vlSelfRef.has_soc__DOT__presetn) 
                             && ((1U & ((IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__enable) 
                                        >> 1U)) && 
                                 (vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[1U] 
                                  < vlSelfRef.has_soc__DOT__pwm_inst__DOT__duty[1U]))) 
                            << 1U));
    vlSelfRef.pwm_out = ((0x0bU & (IData)(vlSelfRef.pwm_out)) 
                         | (((IData)(vlSelfRef.has_soc__DOT__presetn) 
                             && ((1U & ((IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__enable) 
                                        >> 2U)) && 
                                 (vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[2U] 
                                  < vlSelfRef.has_soc__DOT__pwm_inst__DOT__duty[2U]))) 
                            << 2U));
    vlSelfRef.pwm_out = ((7U & (IData)(vlSelfRef.pwm_out)) 
                         | (((IData)(vlSelfRef.has_soc__DOT__presetn) 
                             && ((1U & ((IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__enable) 
                                        >> 3U)) && 
                                 (vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[3U] 
                                  < vlSelfRef.has_soc__DOT__pwm_inst__DOT__duty[3U]))) 
                            << 3U));
    if (vlSelfRef.has_soc__DOT__presetn) {
        __Vdly__has_soc__DOT__uart_inst__DOT__baud_cnt 
            = ((0U == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt))
                ? 0x0000001aU : (0x0000ffffU & ((IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt) 
                                                - (IData)(1U))));
        if ((((~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_data_ready)) 
              & (~ (IData)(vlSelfRef.uart_rx))) & (0U 
                                                   == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt)))) {
            __Vdly__has_soc__DOT__uart_inst__DOT__rx_bits = 8U;
            __Vdly__has_soc__DOT__uart_inst__DOT__rx_shift = 0U;
        } else if (((0U != (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_bits)) 
                    & (0U == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt)))) {
            __Vdly__has_soc__DOT__uart_inst__DOT__rx_bits 
                = (0x0000000fU & ((IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_bits) 
                                  - (IData)(1U)));
            if ((1U == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_bits))) {
                __Vdly__has_soc__DOT__uart_inst__DOT__rx_bits = 0U;
            }
            __Vdly__has_soc__DOT__uart_inst__DOT__rx_shift 
                = (((IData)(vlSelfRef.uart_rx) << 7U) 
                   | (0x0000007fU & ((IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_shift) 
                                     >> 1U)));
        }
        if (vlSelfRef.has_soc__DOT__timer_inst__DOT__enable) {
            vlSelfRef.__Vdly__has_soc__DOT__timer_inst__DOT__count 
                = ((IData)(1U) + vlSelfRef.has_soc__DOT__timer_inst__DOT__count);
        }
        if ((((~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_busy)) 
              & (~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__thre))) 
             & (0U == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt)))) {
            __Vdly__has_soc__DOT__uart_inst__DOT__tx_bits = 0x0aU;
            __Vdly__has_soc__DOT__uart_inst__DOT__tx_busy = 1U;
        } else if (((IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_busy) 
                    & (0U == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt)))) {
            __Vdly__has_soc__DOT__uart_inst__DOT__tx_bits 
                = (0x0000000fU & ((IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_bits) 
                                  - (IData)(1U)));
            if ((1U == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_bits))) {
                __Vdly__has_soc__DOT__uart_inst__DOT__tx_busy = 0U;
            }
        }
        if ((IData)(((((2U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
                       & (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans)) 
                      & (0U == (0x00000ffcU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr))) 
                     & (~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__dlab))))) {
            __Vdly__has_soc__DOT__uart_inst__DOT__thre = 0U;
        }
        if ((((~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_busy)) 
              & (~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__thre))) 
             & (0U == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt)))) {
            __Vdly__has_soc__DOT__uart_inst__DOT__thre = 1U;
            __Vdly__has_soc__DOT__uart_inst__DOT__tx_shift 
                = (0x000000feU & ((IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__thr) 
                                  << 1U));
        } else if (((IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_busy) 
                    & (0U == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt)))) {
            __Vdly__has_soc__DOT__uart_inst__DOT__tx_shift 
                = (0x000000ffU & ((IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_shift) 
                                  >> 1U));
        }
        if ((IData)(((((2U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
                       & (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans)) 
                      & (0U == (0x00000ffcU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr))) 
                     & (~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__dlab))))) {
            vlSelfRef.has_soc__DOT__uart_inst__DOT__thr 
                = (0x000000ffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
        }
        if ((1U & (~ (((~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_data_ready)) 
                       & (~ (IData)(vlSelfRef.uart_rx))) 
                      & (0U == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt)))))) {
            if (((0U != (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_bits)) 
                 & (0U == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt)))) {
                if ((1U == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_bits))) {
                    __Vdly__has_soc__DOT__uart_inst__DOT__rx_data_ready = 1U;
                    vlSelfRef.has_soc__DOT__uart_inst__DOT__rbr 
                        = vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_shift;
                }
            }
        }
        if ((IData)(((((2U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
                       & (~ (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans))) 
                      & (0U == (0x00000ffcU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr))) 
                     & (~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__dlab))))) {
            __Vdly__has_soc__DOT__uart_inst__DOT__rx_data_ready = 0U;
        }
        __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v0 
            = ((1U & (IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__enable))
                ? ((vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[0U] 
                    == vlSelfRef.has_soc__DOT__pwm_inst__DOT__period[0U])
                    ? 0U : (0x0000ffffU & ((IData)(1U) 
                                           + (IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[0U]))))
                : 0U);
        __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v1 
            = ((2U & (IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__enable))
                ? ((vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[1U] 
                    == vlSelfRef.has_soc__DOT__pwm_inst__DOT__period[1U])
                    ? 0U : (0x0000ffffU & ((IData)(1U) 
                                           + (IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[1U]))))
                : 0U);
        __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v2 
            = ((4U & (IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__enable))
                ? ((vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[2U] 
                    == vlSelfRef.has_soc__DOT__pwm_inst__DOT__period[2U])
                    ? 0U : (0x0000ffffU & ((IData)(1U) 
                                           + (IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[2U]))))
                : 0U);
        __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v3 
            = ((8U & (IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__enable))
                ? ((vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[3U] 
                    == vlSelfRef.has_soc__DOT__pwm_inst__DOT__period[3U])
                    ? 0U : (0x0000ffffU & ((IData)(1U) 
                                           + (IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[3U]))))
                : 0U);
        if (vlSelfRef.has_soc__DOT__wdog_inst__DOT__enable) {
            vlSelfRef.__Vdly__has_soc__DOT__wdog_inst__DOT__count 
                = ((0U == vlSelfRef.has_soc__DOT__wdog_inst__DOT__count)
                    ? vlSelfRef.has_soc__DOT__wdog_inst__DOT__load
                    : (vlSelfRef.has_soc__DOT__wdog_inst__DOT__count 
                       - (IData)(1U)));
        }
        if (((2U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
             & (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans))) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT_I((
                                                   ((1U 
                                                     == 
                                                     (0x000003ffU 
                                                      & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                         >> 2U))) 
                                                    << 1U) 
                                                   | (0U 
                                                      == 
                                                      (0x000003ffU 
                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                          >> 2U)))))))))) {
                if ((0U == (((1U == (0x000003ffU & 
                                     (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                      >> 2U))) << 1U) 
                            | (0U == (0x000003ffU & 
                                      (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))))) {
                    if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                        VL_WRITEF_NX("[%0t] %%Error: pwm.sv:59: Assertion failed in %m: unique case, but none matched for '32'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.pwm_inst.g_pwm[0]", 'T',-12
                                     , '#',64,VL_TIME_UNITED_Q(1)
                                     , '#',32,(0x000003ffU 
                                               & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                  >> 2U)));
                        VL_STOP_MT("../../rtl/rtl_peripherals\\pwm.sv", 59, "");
                    }
                } else if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                    VL_WRITEF_NX("[%0t] %%Error: pwm.sv:59: Assertion failed in %m: unique case, but multiple matches found for '32'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.pwm_inst.g_pwm[0]", 'T',-12
                                 , '#',64,VL_TIME_UNITED_Q(1)
                                 , '#',32,(0x000003ffU 
                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)));
                    VL_STOP_MT("../../rtl/rtl_peripherals\\pwm.sv", 59, "");
                }
            }
            if ((0U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))) {
                __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v0 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v0 = 1U;
                vlSelfRef.has_soc__DOT__i2c_inst__DOT__enable 
                    = (1U & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                if ((1U & (~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__dlab)))) {
                    vlSelfRef.has_soc__DOT__uart_inst__DOT__thr 
                        = (0x000000ffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                }
            } else if ((1U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)))) {
                __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v0 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v0 = 1U;
                vlSelfRef.has_soc__DOT__i2c_inst__DOT__slave_addr 
                    = (0x0000007fU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                if ((1U & (~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__dlab)))) {
                    vlSelfRef.has_soc__DOT__uart_inst__DOT__ier 
                        = (0x000000ffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                }
            } else if ((2U != (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)))) {
                if ((3U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                           >> 2U)))) {
                    vlSelfRef.has_soc__DOT__uart_inst__DOT__lcr 
                        = (0x000000ffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                    vlSelfRef.has_soc__DOT__uart_inst__DOT__dlab 
                        = (1U & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata 
                                 >> 7U));
                } else if ((4U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                  >> 2U)))) {
                    vlSelfRef.has_soc__DOT__uart_inst__DOT__mcr 
                        = (0x000000ffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                } else if ((7U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                  >> 2U)))) {
                    vlSelfRef.has_soc__DOT__uart_inst__DOT__spr 
                        = (0x000000ffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                }
            }
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT_I((
                                                   ((3U 
                                                     == 
                                                     (0x000003ffU 
                                                      & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                         >> 2U))) 
                                                    << 1U) 
                                                   | (2U 
                                                      == 
                                                      (0x000003ffU 
                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                          >> 2U)))))))))) {
                if ((0U == (((3U == (0x000003ffU & 
                                     (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                      >> 2U))) << 1U) 
                            | (2U == (0x000003ffU & 
                                      (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))))) {
                    if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                        VL_WRITEF_NX("[%0t] %%Error: pwm.sv:59: Assertion failed in %m: unique case, but none matched for '32'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.pwm_inst.g_pwm[1]", 'T',-12
                                     , '#',64,VL_TIME_UNITED_Q(1)
                                     , '#',32,(0x000003ffU 
                                               & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                  >> 2U)));
                        VL_STOP_MT("../../rtl/rtl_peripherals\\pwm.sv", 59, "");
                    }
                } else if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                    VL_WRITEF_NX("[%0t] %%Error: pwm.sv:59: Assertion failed in %m: unique case, but multiple matches found for '32'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.pwm_inst.g_pwm[1]", 'T',-12
                                 , '#',64,VL_TIME_UNITED_Q(1)
                                 , '#',32,(0x000003ffU 
                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)));
                    VL_STOP_MT("../../rtl/rtl_peripherals\\pwm.sv", 59, "");
                }
            }
            if ((2U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))) {
                __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v2 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v2 = 1U;
            } else if ((3U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)))) {
                __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v2 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v2 = 1U;
            }
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT_I((
                                                   ((5U 
                                                     == 
                                                     (0x000003ffU 
                                                      & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                         >> 2U))) 
                                                    << 1U) 
                                                   | (4U 
                                                      == 
                                                      (0x000003ffU 
                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                          >> 2U)))))))))) {
                if ((0U == (((5U == (0x000003ffU & 
                                     (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                      >> 2U))) << 1U) 
                            | (4U == (0x000003ffU & 
                                      (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))))) {
                    if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                        VL_WRITEF_NX("[%0t] %%Error: pwm.sv:59: Assertion failed in %m: unique case, but none matched for '32'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.pwm_inst.g_pwm[2]", 'T',-12
                                     , '#',64,VL_TIME_UNITED_Q(1)
                                     , '#',32,(0x000003ffU 
                                               & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                  >> 2U)));
                        VL_STOP_MT("../../rtl/rtl_peripherals\\pwm.sv", 59, "");
                    }
                } else if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                    VL_WRITEF_NX("[%0t] %%Error: pwm.sv:59: Assertion failed in %m: unique case, but multiple matches found for '32'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.pwm_inst.g_pwm[2]", 'T',-12
                                 , '#',64,VL_TIME_UNITED_Q(1)
                                 , '#',32,(0x000003ffU 
                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)));
                    VL_STOP_MT("../../rtl/rtl_peripherals\\pwm.sv", 59, "");
                }
            }
            if ((4U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))) {
                __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v4 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v4 = 1U;
            } else if ((5U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)))) {
                __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v4 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v4 = 1U;
            }
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT_I((
                                                   ((7U 
                                                     == 
                                                     (0x000003ffU 
                                                      & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                         >> 2U))) 
                                                    << 1U) 
                                                   | (6U 
                                                      == 
                                                      (0x000003ffU 
                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                          >> 2U)))))))))) {
                if ((0U == (((7U == (0x000003ffU & 
                                     (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                      >> 2U))) << 1U) 
                            | (6U == (0x000003ffU & 
                                      (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))))) {
                    if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                        VL_WRITEF_NX("[%0t] %%Error: pwm.sv:59: Assertion failed in %m: unique case, but none matched for '32'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.pwm_inst.g_pwm[3]", 'T',-12
                                     , '#',64,VL_TIME_UNITED_Q(1)
                                     , '#',32,(0x000003ffU 
                                               & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                  >> 2U)));
                        VL_STOP_MT("../../rtl/rtl_peripherals\\pwm.sv", 59, "");
                    }
                } else if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                    VL_WRITEF_NX("[%0t] %%Error: pwm.sv:59: Assertion failed in %m: unique case, but multiple matches found for '32'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.pwm_inst.g_pwm[3]", 'T',-12
                                 , '#',64,VL_TIME_UNITED_Q(1)
                                 , '#',32,(0x000003ffU 
                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)));
                    VL_STOP_MT("../../rtl/rtl_peripherals\\pwm.sv", 59, "");
                }
            }
            if ((6U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))) {
                __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v6 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v6 = 1U;
            } else if ((7U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)))) {
                __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v6 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                __VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v6 = 1U;
            }
            if ((1U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))) {
                vlSelfRef.has_soc__DOT__spi_inst__DOT__busy = 1U;
                vlSelfRef.has_soc__DOT__i2s_inst__DOT__tx_sample 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
            } else {
                vlSelfRef.has_soc__DOT__spi_inst__DOT__busy = 0U;
            }
            if ((2U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))) {
                vlSelfRef.has_soc__DOT__spi_inst__DOT__tx_data 
                    = (0x000000ffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                vlSelfRef.has_soc__DOT__pwrmgr_inst__DOT__wake_en 
                    = (1U & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
            }
            if ((0U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))) {
                vlSelfRef.has_soc__DOT__i2s_inst__DOT__enable 
                    = (1U & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                vlSelfRef.has_soc__DOT__spi_inst__DOT__enable 
                    = (1U & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                vlSelfRef.has_soc__DOT__wdog_inst__DOT__load 
                    = vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata;
                vlSelfRef.has_soc__DOT__pwrmgr_inst__DOT__sleep_req 
                    = (1U & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
            }
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT_I((
                                                   (((3U 
                                                      == 
                                                      (0x000003ffU 
                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                          >> 2U))) 
                                                     << 3U) 
                                                    | ((2U 
                                                        == 
                                                        (0x000003ffU 
                                                         & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                            >> 2U))) 
                                                       << 2U)) 
                                                   | (((1U 
                                                        == 
                                                        (0x000003ffU 
                                                         & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                            >> 2U))) 
                                                       << 1U) 
                                                      | (0U 
                                                         == 
                                                         (0x000003ffU 
                                                          & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                             >> 2U))))))))))) {
                if ((0U == ((((3U == (0x000003ffU & 
                                      (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U))) << 3U) 
                             | ((2U == (0x000003ffU 
                                        & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                           >> 2U))) 
                                << 2U)) | (((1U == 
                                             (0x000003ffU 
                                              & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                 >> 2U))) 
                                            << 1U) 
                                           | (0U == 
                                              (0x000003ffU 
                                               & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                  >> 2U))))))) {
                    if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                        VL_WRITEF_NX("[%0t] %%Error: i2c_ctrl.sv:48: Assertion failed in %m: unique case, but none matched for '10'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.i2c_inst", 'T',-12
                                     , '#',64,VL_TIME_UNITED_Q(1)
                                     , '#',10,(0x000003ffU 
                                               & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                  >> 2U)));
                        VL_STOP_MT("../../rtl/rtl_peripherals\\i2c_ctrl.sv", 48, "");
                    }
                } else if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                    VL_WRITEF_NX("[%0t] %%Error: i2c_ctrl.sv:48: Assertion failed in %m: unique case, but multiple matches found for '10'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.i2c_inst", 'T',-12
                                 , '#',64,VL_TIME_UNITED_Q(1)
                                 , '#',10,(0x000003ffU 
                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)));
                    VL_STOP_MT("../../rtl/rtl_peripherals\\i2c_ctrl.sv", 48, "");
                }
            }
            vlSelfRef.has_soc__DOT__i2c_inst__DOT__busy 
                = (3U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                         >> 2U)));
            if ((1U & (~ VL_ONEHOT_I(((((7U == (0x000003ffU 
                                                & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                   >> 2U))) 
                                        << 5U) | ((
                                                   (4U 
                                                    == 
                                                    (0x000003ffU 
                                                     & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                        >> 2U))) 
                                                   << 4U) 
                                                  | ((3U 
                                                      == 
                                                      (0x000003ffU 
                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                          >> 2U))) 
                                                     << 3U))) 
                                      | (((2U == (0x000003ffU 
                                                  & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                     >> 2U))) 
                                          << 2U) | 
                                         (((1U == (0x000003ffU 
                                                   & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                      >> 2U))) 
                                           << 1U) | 
                                          (0U == (0x000003ffU 
                                                  & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                     >> 2U)))))))))) {
                if ((0U == ((((7U == (0x000003ffU & 
                                      (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U))) << 5U) 
                             | (((4U == (0x000003ffU 
                                         & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                            >> 2U))) 
                                 << 4U) | ((3U == (0x000003ffU 
                                                   & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                      >> 2U))) 
                                           << 3U))) 
                            | (((2U == (0x000003ffU 
                                        & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                           >> 2U))) 
                                << 2U) | (((1U == (0x000003ffU 
                                                   & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                      >> 2U))) 
                                           << 1U) | 
                                          (0U == (0x000003ffU 
                                                  & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                     >> 2U)))))))) {
                    if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                        VL_WRITEF_NX("[%0t] %%Error: uart.sv:139: Assertion failed in %m: unique case, but none matched for '10'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.uart_inst", 'T',-12
                                     , '#',64,VL_TIME_UNITED_Q(1)
                                     , '#',10,(0x000003ffU 
                                               & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                  >> 2U)));
                        VL_STOP_MT("../../rtl/rtl_peripherals\\uart.sv", 139, "");
                    }
                } else if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                    VL_WRITEF_NX("[%0t] %%Error: uart.sv:139: Assertion failed in %m: unique case, but multiple matches found for '10'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.uart_inst", 'T',-12
                                 , '#',64,VL_TIME_UNITED_Q(1)
                                 , '#',10,(0x000003ffU 
                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)));
                    VL_STOP_MT("../../rtl/rtl_peripherals\\uart.sv", 139, "");
                }
            }
        } else if (((2U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
                    & (~ (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans)))) {
            if ((4U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))) {
                vlSelfRef.has_soc__DOT__i2c_inst__DOT__rx_data = 0x55U;
            }
        }
        vlSelfRef.__Vdly__has_soc__DOT__gpio_inst__DOT__int_pend 
            = ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_pend) 
               | (((((~ (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio_in_prev)) 
                     & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio_in_sync2)) 
                    & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_rise_en)) 
                   | (((~ (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio_in_sync2)) 
                       & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio_in_prev)) 
                      & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_fall_en))) 
                  & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_en)));
        if ((IData)((((2U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
                      & (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans)) 
                     & (0x00000018U == (0x00000ffcU 
                                        & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr))))) {
            vlSelfRef.__Vdly__has_soc__DOT__gpio_inst__DOT__int_pend 
                = ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_pend) 
                   & (~ vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata));
        }
        if ((1U & (~ (((~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_busy)) 
                       & (~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__thre))) 
                      & (0U == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt)))))) {
            if (((IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_busy) 
                 & (0U == (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt)))) {
                vlSelfRef.uart_tx = (1U & (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_shift));
            }
        }
        vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio_in_prev 
            = vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio_in_sync2;
        if ((IData)((((2U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
                      & (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans)) 
                     & (0x00000020U == (0x00000ffcU 
                                        & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr))))) {
            vlSelfRef.has_soc__DOT__pwm_inst__DOT__enable 
                = (0x0000000fU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
        }
        vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio_in_sync2 
            = vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio_in_sync1;
        vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio_in_sync1 
            = vlSelfRef.gpio;
    } else {
        __Vdly__has_soc__DOT__uart_inst__DOT__baud_cnt = 0U;
        __Vdly__has_soc__DOT__uart_inst__DOT__rx_bits = 0U;
        __Vdly__has_soc__DOT__uart_inst__DOT__tx_bits = 0U;
        __Vdly__has_soc__DOT__uart_inst__DOT__tx_busy = 0U;
        __Vdly__has_soc__DOT__uart_inst__DOT__rx_shift = 0U;
        vlSelfRef.__Vdly__has_soc__DOT__timer_inst__DOT__count = 0U;
        __Vdly__has_soc__DOT__uart_inst__DOT__thre = 1U;
        __Vdly__has_soc__DOT__uart_inst__DOT__rx_data_ready = 0U;
        __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v0 = 0U;
        __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v1 = 0U;
        __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v2 = 0U;
        __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v3 = 0U;
        __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v1 = 1U;
        __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v3 = 1U;
        __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v5 = 1U;
        __VdlySet__has_soc__DOT__pwm_inst__DOT__period__v7 = 1U;
        vlSelfRef.__Vdly__has_soc__DOT__wdog_inst__DOT__count = 0U;
        __Vdly__has_soc__DOT__uart_inst__DOT__tx_shift = 0U;
        vlSelfRef.__Vdly__has_soc__DOT__gpio_inst__DOT__int_pend = 0U;
        vlSelfRef.uart_tx = 1U;
        vlSelfRef.has_soc__DOT__uart_inst__DOT__rbr = 0U;
        vlSelfRef.has_soc__DOT__spi_inst__DOT__busy = 0U;
        vlSelfRef.has_soc__DOT__i2s_inst__DOT__tx_sample = 0U;
        vlSelfRef.has_soc__DOT__spi_inst__DOT__tx_data = 0U;
        vlSelfRef.has_soc__DOT__pwrmgr_inst__DOT__wake_en = 0U;
        vlSelfRef.has_soc__DOT__i2s_inst__DOT__enable = 0U;
        vlSelfRef.has_soc__DOT__spi_inst__DOT__enable = 0U;
        vlSelfRef.has_soc__DOT__i2c_inst__DOT__enable = 0U;
        vlSelfRef.has_soc__DOT__i2c_inst__DOT__slave_addr = 0U;
        vlSelfRef.has_soc__DOT__i2c_inst__DOT__rx_data = 0U;
        vlSelfRef.has_soc__DOT__i2c_inst__DOT__busy = 0U;
        vlSelfRef.has_soc__DOT__i2c_inst__DOT__ack_received = 0U;
        vlSelfRef.has_soc__DOT__wdog_inst__DOT__load = 0U;
        vlSelfRef.has_soc__DOT__uart_inst__DOT__dlab = 0U;
        vlSelfRef.has_soc__DOT__uart_inst__DOT__thr = 0U;
        vlSelfRef.has_soc__DOT__uart_inst__DOT__ier = 0U;
        vlSelfRef.has_soc__DOT__uart_inst__DOT__iir = 1U;
        vlSelfRef.has_soc__DOT__uart_inst__DOT__lcr = 0U;
        vlSelfRef.has_soc__DOT__uart_inst__DOT__mcr = 0U;
        vlSelfRef.has_soc__DOT__uart_inst__DOT__spr = 0U;
        vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio_in_prev = 0U;
        vlSelfRef.has_soc__DOT__pwrmgr_inst__DOT__sleep_req = 0U;
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__enable = 0U;
        vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio_in_sync2 = 0U;
        vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio_in_sync1 = 0U;
    }
    vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_bits 
        = __Vdly__has_soc__DOT__uart_inst__DOT__tx_bits;
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__period__v0) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__period[0U] 
            = __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v0;
    }
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__period__v1) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__period[0U] = 0U;
    }
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__period__v2) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__period[1U] 
            = __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v2;
    }
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__period__v3) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__period[1U] = 0U;
    }
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__period__v4) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__period[2U] 
            = __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v4;
    }
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__period__v5) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__period[2U] = 0U;
    }
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__period__v6) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__period[3U] 
            = __VdlyVal__has_soc__DOT__pwm_inst__DOT__period__v6;
    }
    vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_shift 
        = __Vdly__has_soc__DOT__uart_inst__DOT__tx_shift;
    vlSelfRef.has_soc__DOT__uart_inst__DOT__tx_busy 
        = __Vdly__has_soc__DOT__uart_inst__DOT__tx_busy;
    vlSelfRef.has_soc__DOT__uart_inst__DOT__thre = __Vdly__has_soc__DOT__uart_inst__DOT__thre;
    vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_shift 
        = __Vdly__has_soc__DOT__uart_inst__DOT__rx_shift;
    vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_bits 
        = __Vdly__has_soc__DOT__uart_inst__DOT__rx_bits;
    vlSelfRef.has_soc__DOT__uart_inst__DOT__baud_cnt 
        = __Vdly__has_soc__DOT__uart_inst__DOT__baud_cnt;
    vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_data_ready 
        = __Vdly__has_soc__DOT__uart_inst__DOT__rx_data_ready;
    vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[0U] 
        = __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v0;
    vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[1U] 
        = __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v1;
    vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[2U] 
        = __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v2;
    vlSelfRef.has_soc__DOT__pwm_inst__DOT__counter[3U] 
        = __VdlyVal__has_soc__DOT__pwm_inst__DOT__counter__v3;
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v0) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__duty[0U] 
            = __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v0;
    }
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__period__v1) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__duty[0U] = 0U;
    }
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v2) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__duty[1U] 
            = __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v2;
    }
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__period__v3) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__duty[1U] = 0U;
    }
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v4) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__duty[2U] 
            = __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v4;
    }
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__period__v5) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__duty[2U] = 0U;
    }
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__duty__v6) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__duty[3U] 
            = __VdlyVal__has_soc__DOT__pwm_inst__DOT__duty__v6;
    }
    if (__VdlySet__has_soc__DOT__pwm_inst__DOT__period__v7) {
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__period[3U] = 0U;
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__duty[3U] = 0U;
    }
    vlSelfRef.i2s_dout = ((IData)(vlSelfRef.has_soc__DOT__i2s_inst__DOT__enable) 
                          & ((IData)(vlSelfRef.has_soc__DOT__i2s_inst__DOT__tx_sample) 
                             >> 0x0000000fU));
    vlSelfRef.spi_mosi = ((IData)(vlSelfRef.has_soc__DOT__spi_inst__DOT__enable) 
                          & ((IData)(vlSelfRef.has_soc__DOT__spi_inst__DOT__tx_data) 
                             >> 7U));
    vlSelfRef.spi_sck = (1U & (~ (IData)(vlSelfRef.has_soc__DOT__spi_inst__DOT__enable)));
    vlSelfRef.spi_cs_n = vlSelfRef.spi_sck;
}

extern const VlUnpacked<CData/*1:0*/, 32> Vhas_soc__ConstPool__TABLE_h4028fa87_0;
extern const VlUnpacked<CData/*1:0*/, 512> Vhas_soc__ConstPool__TABLE_hfa44c009_0;

void Vhas_soc___024root___nba_sequent__TOP__1(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___nba_sequent__TOP__1\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<CData/*7:0*/, 4> has_soc__DOT__plic_inst__DOT__priority_arr;
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        has_soc__DOT__plic_inst__DOT__priority_arr[__Vi0] = 0;
    }
    QData/*63:0*/ has_soc__DOT__clint_inst__DOT__mtimecmp;
    has_soc__DOT__clint_inst__DOT__mtimecmp = 0;
    CData/*0:0*/ __Vdly__has_soc__DOT____Vcellout__sram_inst__arready;
    __Vdly__has_soc__DOT____Vcellout__sram_inst__arready = 0;
    CData/*0:0*/ __Vdly__has_soc__DOT____Vcellout__tcm_inst__arready;
    __Vdly__has_soc__DOT____Vcellout__tcm_inst__arready = 0;
    SData/*9:0*/ __VdlyDim0__has_soc__DOT__qspi_ctrl__DOT__flash_mem__v0;
    __VdlyDim0__has_soc__DOT__qspi_ctrl__DOT__flash_mem__v0 = 0;
    // Body
    __Vdly__has_soc__DOT____Vcellout__sram_inst__arready 
        = vlSelfRef.has_soc__DOT____Vcellout__sram_inst__arready;
    __Vdly__has_soc__DOT____Vcellout__tcm_inst__arready 
        = vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__arready;
    vlSelfRef.__Vdly__has_soc__DOT____Vcellout__sram_inst__awready 
        = vlSelfRef.has_soc__DOT____Vcellout__sram_inst__awready;
    vlSelfRef.__Vdly__has_soc__DOT____Vcellout__tcm_inst__awready 
        = vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__awready;
    vlSelfRef.__Vdly__has_soc__DOT____Vcellout__sram_inst__wready 
        = vlSelfRef.has_soc__DOT____Vcellout__sram_inst__wready;
    vlSelfRef.__Vdly__has_soc__DOT____Vcellout__tcm_inst__wready 
        = vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__wready;
    vlSelfRef.__Vdly__has_soc__DOT__apb_bridge__DOT__state 
        = vlSelfRef.has_soc__DOT__apb_bridge__DOT__state;
    vlSelfRef.__Vdly__has_soc__DOT__core__DOT__pc = vlSelfRef.has_soc__DOT__core__DOT__pc;
    vlSelfRef.__Vdly__has_soc__DOT__data_adapter__DOT__state 
        = vlSelfRef.has_soc__DOT__data_adapter__DOT__state;
    if ((1U & (~ (IData)(vlSelfRef.reset_n)))) {
        vlSelfRef.has_soc__DOT__qspi_ctrl__DOT__unnamedblk1__DOT__i = 0U;
        while (VL_GTS_III(32, 0x00000400U, vlSelfRef.has_soc__DOT__qspi_ctrl__DOT__unnamedblk1__DOT__i)) {
            __VdlyDim0__has_soc__DOT__qspi_ctrl__DOT__flash_mem__v0 
                = (0x000003ffU & vlSelfRef.has_soc__DOT__qspi_ctrl__DOT__unnamedblk1__DOT__i);
            vlSelfRef.__VdlyCommitQueuehas_soc__DOT__qspi_ctrl__DOT__flash_mem.enqueue(0U, (IData)(__VdlyDim0__has_soc__DOT__qspi_ctrl__DOT__flash_mem__v0));
            vlSelfRef.has_soc__DOT__qspi_ctrl__DOT__unnamedblk1__DOT__i 
                = ((IData)(1U) + vlSelfRef.has_soc__DOT__qspi_ctrl__DOT__unnamedblk1__DOT__i);
        }
    }
    if (vlSelfRef.reset_n) {
        __Vdly__has_soc__DOT____Vcellout__sram_inst__arready 
            = ((IData)(vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__arvalid) 
               & (~ (IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__arready)));
        __Vdly__has_soc__DOT____Vcellout__tcm_inst__arready 
            = ((IData)(vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__arvalid) 
               & (~ (IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__arready)));
        vlSelfRef.__Vdly__has_soc__DOT____Vcellout__sram_inst__awready 
            = ((IData)(vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__awvalid) 
               & (~ (IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__awready)));
        vlSelfRef.__Vdly__has_soc__DOT____Vcellout__tcm_inst__awready 
            = ((IData)(vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__awvalid) 
               & (~ (IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__awready)));
        vlSelfRef.__Vdly__has_soc__DOT____Vcellout__sram_inst__wready 
            = ((IData)(vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__wvalid) 
               & (~ (IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__wready)));
        vlSelfRef.__Vdly__has_soc__DOT____Vcellout__tcm_inst__wready 
            = ((IData)(vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__wvalid) 
               & (~ (IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__wready)));
        vlSelfRef.has_soc__DOT__clint_inst__DOT__mtime 
            = (1ULL + vlSelfRef.has_soc__DOT__clint_inst__DOT__mtime);
        vlSelfRef.has_soc__DOT__core__DOT__csr_mcycle 
            = ((IData)(1U) + vlSelfRef.has_soc__DOT__core__DOT__csr_mcycle);
        vlSelfRef.has_soc__DOT__core__DOT__csr_minstret 
            = (vlSelfRef.has_soc__DOT__core__DOT__csr_minstret 
               + (((0U == (IData)(vlSelfRef.has_soc__DOT__core__DOT__state)) 
                   & (IData)(vlSelfRef.has_soc__DOT__core__DOT__fetch_valid))
                   ? 1U : 0U));
        vlSelfRef.__Vdly__has_soc__DOT__apb_bridge__DOT__state 
            = Vhas_soc__ConstPool__TABLE_h4028fa87_0
            [(((0U != (IData)(vlSelfRef.has_soc__DOT__apb_sel)) 
               << 4U) | (((IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__ar_fire) 
                          << 3U) | (((IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__aw_fire) 
                                     << 2U) | (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state))))];
        if ((1U & ((2U & (IData)(vlSelfRef.has_soc__DOT__core__DOT__state))
                    ? ((IData)(vlSelfRef.has_soc__DOT__core__DOT__state) 
                       | (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_2))
                    : (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_24)))) {
            vlSelfRef.__Vdly__has_soc__DOT__core__DOT__pc 
                = ((2U & (IData)(vlSelfRef.has_soc__DOT__core__DOT__state))
                    ? ((1U & (IData)(vlSelfRef.has_soc__DOT__core__DOT__state))
                        ? vlSelfRef.has_soc__DOT__core__DOT__next_pc
                        : ((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_2)
                            ? vlSelfRef.has_soc__DOT__core__DOT__next_pc
                            : vlSelfRef.has_soc__DOT__core__DOT__pc))
                    : ((1U & (IData)(vlSelfRef.has_soc__DOT__core__DOT__state))
                        ? ((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_1)
                            ? vlSelfRef.has_soc__DOT__core__DOT__pc
                            : ((0x73U == (0x0000007fU 
                                          & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))
                                ? vlSelfRef.has_soc__DOT__core__DOT__pc
                                : vlSelfRef.has_soc__DOT__core__DOT__next_pc))
                        : vlSelfRef.has_soc__DOT__core__DOT__pc));
        }
        vlSelfRef.__Vdly__has_soc__DOT__data_adapter__DOT__state 
            = Vhas_soc__ConstPool__TABLE_hfa44c009_0
            [((((((IData)(vlSelfRef.has_soc__DOT__data_req) 
                  << 4U) | (((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__ar_fire) 
                             << 3U) | ((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__aw_fire) 
                                       << 2U))) | (
                                                   ((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__w_fire) 
                                                    << 1U) 
                                                   | (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__r_fire))) 
               << 4U) | (((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__b_fire) 
                          << 3U) | (((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__is_write_q) 
                                     << 2U) | (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__state))))];
    } else {
        __Vdly__has_soc__DOT____Vcellout__sram_inst__arready = 0U;
        __Vdly__has_soc__DOT____Vcellout__tcm_inst__arready = 0U;
        vlSelfRef.__Vdly__has_soc__DOT____Vcellout__sram_inst__awready = 0U;
        vlSelfRef.__Vdly__has_soc__DOT____Vcellout__tcm_inst__awready = 0U;
        vlSelfRef.__Vdly__has_soc__DOT____Vcellout__sram_inst__wready = 0U;
        vlSelfRef.__Vdly__has_soc__DOT____Vcellout__tcm_inst__wready = 0U;
        vlSelfRef.has_soc__DOT__clint_inst__DOT__mtime = 0ULL;
        vlSelfRef.has_soc__DOT__core__DOT__csr_mcycle = 0U;
        vlSelfRef.has_soc__DOT__core__DOT__csr_minstret = 0U;
        vlSelfRef.__Vdly__has_soc__DOT__apb_bridge__DOT__state = 0U;
        vlSelfRef.__Vdly__has_soc__DOT__core__DOT__pc = 0U;
        vlSelfRef.__Vdly__has_soc__DOT__data_adapter__DOT__state = 0U;
    }
    vlSelfRef.__VdlyCommitQueuehas_soc__DOT__qspi_ctrl__DOT__flash_mem.commit(vlSelfRef.has_soc__DOT__qspi_ctrl__DOT__flash_mem);
    if (vlSelfRef.reset_n) {
        if (((((IData)(vlSelfRef.has_soc__DOT__m_awvalid) 
               & (IData)(vlSelfRef.has_soc__DOT__m_awready)) 
              & (IData)(vlSelfRef.has_soc__DOT__m_wvalid)) 
             & (IData)(vlSelfRef.has_soc__DOT__m_wready))) {
            vlSelfRef.has_soc__DOT__axi_ic__DOT__b_src 
                = (7U & ((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16) 
                         >> 1U));
            vlSelfRef.has_soc__DOT__axi_ic__DOT__b_decode_err 
                = (1U & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16));
        }
        if (((IData)(vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__arvalid) 
             & (IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__arready))) {
            vlSelfRef.has_soc__DOT__sram_inst__DOT__raddr_q 
                = (0x0003ffffU & vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q);
        }
        if (((IData)(vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__arvalid) 
             & (IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__arready))) {
            vlSelfRef.has_soc__DOT__tcm_inst__DOT__raddr_q 
                = (0x00007fffU & vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q);
        }
        if (((IData)(vlSelfRef.has_soc__DOT____Vcellinp__clint_inst__awvalid) 
             & (IData)(vlSelfRef.has_soc__DOT____Vcellinp__clint_inst__wvalid))) {
            if ((0x03f8U == (0x00000fffU & vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q))) {
                has_soc__DOT__clint_inst__DOT__mtimecmp 
                    = (0xffffffff00000000ULL & has_soc__DOT__clint_inst__DOT__mtimecmp);
            }
            if ((0x03fcU == (0x00000fffU & vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q))) {
                has_soc__DOT__clint_inst__DOT__mtimecmp 
                    = (0x00000000ffffffffULL & has_soc__DOT__clint_inst__DOT__mtimecmp);
            }
        }
        if (((IData)(vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__awvalid) 
             & (IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__awready))) {
            vlSelfRef.has_soc__DOT__sram_inst__DOT__waddr_q 
                = (0x0003ffffU & vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q);
        }
        if (((IData)(vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__awvalid) 
             & (IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__awready))) {
            vlSelfRef.has_soc__DOT__tcm_inst__DOT__waddr_q 
                = (0x00007fffU & vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q);
        }
        if ((((IData)(vlSelfRef.has_soc__DOT____Vcellinp__clint_inst__awvalid) 
              & (IData)(vlSelfRef.has_soc__DOT____Vcellinp__clint_inst__wvalid)) 
             & (0U == (0x00000fffU & vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q)))) {
            vlSelfRef.has_soc__DOT__clint_inst__DOT__msip = 0U;
        }
        if (((0U == (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__state)) 
             & (IData)(vlSelfRef.has_soc__DOT__data_req))) {
            vlSelfRef.has_soc__DOT__data_gnt = 1U;
        } else if (((0U != (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__state)) 
                    & (0U == Vhas_soc__ConstPool__TABLE_hfa44c009_0
                       [((((((IData)(vlSelfRef.has_soc__DOT__data_req) 
                             << 4U) | (((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__ar_fire) 
                                        << 3U) | ((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__aw_fire) 
                                                  << 2U))) 
                           | (((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__w_fire) 
                               << 1U) | (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__r_fire))) 
                          << 4U) | (((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__b_fire) 
                                     << 3U) | (((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__is_write_q) 
                                                << 2U) 
                                               | (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__state))))]))) {
            vlSelfRef.has_soc__DOT__data_gnt = 0U;
        }
        if (((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__r_fire) 
             & (~ (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__is_write_q)))) {
            vlSelfRef.has_soc__DOT__data_rvalid = 1U;
        } else if ((0U == Vhas_soc__ConstPool__TABLE_hfa44c009_0
                    [((((((IData)(vlSelfRef.has_soc__DOT__data_req) 
                          << 4U) | (((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__ar_fire) 
                                     << 3U) | ((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__aw_fire) 
                                               << 2U))) 
                        | (((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__w_fire) 
                            << 1U) | (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__r_fire))) 
                       << 4U) | (((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__b_fire) 
                                  << 3U) | (((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__is_write_q) 
                                             << 2U) 
                                            | (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__state))))])) {
            vlSelfRef.has_soc__DOT__data_rvalid = 0U;
        }
        if ((((vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
               >> 0x0000000cU) & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_5)) 
             & (IData)(vlSelfRef.has_soc__DOT____Vcellinp__clint_inst__wvalid))) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT_I((
                                                   (((0x0801U 
                                                      == 
                                                      (0x00003fffU 
                                                       & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                          >> 2U))) 
                                                     << 5U) 
                                                    | (((0x0800U 
                                                         == 
                                                         (0x00003fffU 
                                                          & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                             >> 2U))) 
                                                        << 4U) 
                                                       | ((3U 
                                                           == 
                                                           (0x00003fffU 
                                                            & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                               >> 2U))) 
                                                          << 3U))) 
                                                   | (((2U 
                                                        == 
                                                        (0x00003fffU 
                                                         & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                            >> 2U))) 
                                                       << 2U) 
                                                      | (((1U 
                                                           == 
                                                           (0x00003fffU 
                                                            & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                               >> 2U))) 
                                                          << 1U) 
                                                         | (0U 
                                                            == 
                                                            (0x00003fffU 
                                                             & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                                >> 2U)))))))))))) {
                if ((0U == ((((0x0801U == (0x00003fffU 
                                           & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                              >> 2U))) 
                              << 5U) | (((0x0800U == 
                                          (0x00003fffU 
                                           & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                              >> 2U))) 
                                         << 4U) | (
                                                   (3U 
                                                    == 
                                                    (0x00003fffU 
                                                     & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                        >> 2U))) 
                                                   << 3U))) 
                            | (((2U == (0x00003fffU 
                                        & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                           >> 2U))) 
                                << 2U) | (((1U == (0x00003fffU 
                                                   & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                      >> 2U))) 
                                           << 1U) | 
                                          (0U == (0x00003fffU 
                                                  & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                     >> 2U)))))))) {
                    if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                        VL_WRITEF_NX("[%0t] %%Error: plic.sv:53: Assertion failed in %m: unique case, but none matched for '14'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.plic_inst", 'T',-12
                                     , '#',64,VL_TIME_UNITED_Q(1)
                                     , '#',14,(0x00003fffU 
                                               & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                  >> 2U)));
                        VL_STOP_MT("../../rtl/rtl_peripherals\\plic.sv", 53, "");
                    }
                } else if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                    VL_WRITEF_NX("[%0t] %%Error: plic.sv:53: Assertion failed in %m: unique case, but multiple matches found for '14'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.plic_inst", 'T',-12
                                 , '#',64,VL_TIME_UNITED_Q(1)
                                 , '#',14,(0x00003fffU 
                                           & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                              >> 2U)));
                    VL_STOP_MT("../../rtl/rtl_peripherals\\plic.sv", 53, "");
                }
            }
            if ((0U == (0x00003fffU & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                       >> 2U)))) {
                vlSelfRef.has_soc__DOT__plic_inst__DOT__priority0 = 0U;
            } else if ((1U == (0x00003fffU & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                              >> 2U)))) {
                vlSelfRef.has_soc__DOT__plic_inst__DOT__priority1 = 0U;
            } else if ((2U == (0x00003fffU & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                              >> 2U)))) {
                vlSelfRef.has_soc__DOT__plic_inst__DOT__priority2 = 0U;
            } else if ((3U == (0x00003fffU & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                              >> 2U)))) {
                vlSelfRef.has_soc__DOT__plic_inst__DOT__priority3 = 0U;
            } else if ((0x0800U == (0x00003fffU & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                   >> 2U)))) {
                vlSelfRef.has_soc__DOT__plic_inst__DOT__enable = 0U;
            } else if ((0x0801U == (0x00003fffU & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                   >> 2U)))) {
                vlSelfRef.has_soc__DOT__plic_inst__DOT__threshold = 0U;
            }
        }
        vlSelfRef.has_soc__DOT__plic_inst__DOT__pending 
            = (((0U != ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_pend) 
                        & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_en))) 
                << 3U) | ((((IData)(vlSelfRef.has_soc__DOT__timer_inst__DOT__match_pend) 
                            & (IData)(vlSelfRef.has_soc__DOT__timer_inst__DOT__int_en)) 
                           << 1U) | (IData)(vlSelfRef.has_soc__DOT__wdog_inst__DOT__expired)));
        if (vlSelfRef.has_soc__DOT__rom_inst__DOT__req_q) {
            vlSelfRef.has_soc__DOT__core__DOT__fetch_valid = 1U;
        }
    } else {
        vlSelfRef.has_soc__DOT__axi_ic__DOT__b_src = 6U;
        vlSelfRef.has_soc__DOT__axi_ic__DOT__b_decode_err = 1U;
        vlSelfRef.has_soc__DOT__sram_inst__DOT__raddr_q = 0U;
        vlSelfRef.has_soc__DOT__tcm_inst__DOT__raddr_q = 0U;
        has_soc__DOT__clint_inst__DOT__mtimecmp = 0ULL;
        vlSelfRef.has_soc__DOT__sram_inst__DOT__waddr_q = 0U;
        vlSelfRef.has_soc__DOT__tcm_inst__DOT__waddr_q = 0U;
        vlSelfRef.has_soc__DOT__clint_inst__DOT__msip = 0U;
        vlSelfRef.has_soc__DOT__data_gnt = 0U;
        vlSelfRef.has_soc__DOT__data_rvalid = 0U;
        vlSelfRef.has_soc__DOT__plic_inst__DOT__priority0 = 0U;
        vlSelfRef.has_soc__DOT__plic_inst__DOT__priority1 = 0U;
        vlSelfRef.has_soc__DOT__plic_inst__DOT__priority2 = 0U;
        vlSelfRef.has_soc__DOT__plic_inst__DOT__priority3 = 0U;
        vlSelfRef.has_soc__DOT__plic_inst__DOT__enable = 0U;
        vlSelfRef.has_soc__DOT__plic_inst__DOT__threshold = 0U;
        vlSelfRef.has_soc__DOT__core__DOT__fetch_valid = 0U;
    }
    vlSelfRef.has_soc__DOT__sram_inst__DOT__read_d 
        = ((IData)(vlSelfRef.reset_n) && ((IData)(vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__arvalid) 
                                          & (IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__arready)));
    vlSelfRef.has_soc__DOT__tcm_inst__DOT__read_d = 
        ((IData)(vlSelfRef.reset_n) && ((IData)(vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__arvalid) 
                                        & (IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__arready)));
    vlSelfRef.has_soc__DOT____Vcellout__sram_inst__arready 
        = __Vdly__has_soc__DOT____Vcellout__sram_inst__arready;
    vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__arready 
        = __Vdly__has_soc__DOT____Vcellout__tcm_inst__arready;
    vlSelfRef.has_soc__DOT__s_rvalid = ((0x39U & (IData)(vlSelfRef.has_soc__DOT__s_rvalid)) 
                                        | (((IData)(vlSelfRef.has_soc__DOT__sram_inst__DOT__read_d) 
                                            << 2U) 
                                           | ((IData)(vlSelfRef.has_soc__DOT__tcm_inst__DOT__read_d) 
                                              << 1U)));
    vlSelfRef.has_soc__DOT__s_arready = ((0x39U & (IData)(vlSelfRef.has_soc__DOT__s_arready)) 
                                         | (((IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__arready) 
                                             << 2U) 
                                            | ((IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__arready) 
                                               << 1U)));
    has_soc__DOT__plic_inst__DOT__priority_arr[0U] 
        = vlSelfRef.has_soc__DOT__plic_inst__DOT__priority0;
    has_soc__DOT__plic_inst__DOT__priority_arr[1U] 
        = vlSelfRef.has_soc__DOT__plic_inst__DOT__priority1;
    has_soc__DOT__plic_inst__DOT__priority_arr[2U] 
        = vlSelfRef.has_soc__DOT__plic_inst__DOT__priority2;
    has_soc__DOT__plic_inst__DOT__priority_arr[3U] 
        = vlSelfRef.has_soc__DOT__plic_inst__DOT__priority3;
}

void Vhas_soc___024root___nba_sequent__TOP__3(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___nba_sequent__TOP__3\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VdlyVal__has_soc__DOT__core__DOT__rf__v0;
    __VdlyVal__has_soc__DOT__core__DOT__rf__v0 = 0;
    CData/*4:0*/ __VdlyDim0__has_soc__DOT__core__DOT__rf__v0;
    __VdlyDim0__has_soc__DOT__core__DOT__rf__v0 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__core__DOT__rf__v0;
    __VdlySet__has_soc__DOT__core__DOT__rf__v0 = 0;
    CData/*7:0*/ __VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v0;
    __VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v0 = 0;
    SData/*15:0*/ __VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v0;
    __VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v0;
    __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v1;
    __VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v1 = 0;
    SData/*15:0*/ __VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v1;
    __VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v1;
    __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v2;
    __VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v2 = 0;
    SData/*15:0*/ __VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v2;
    __VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v2;
    __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v3;
    __VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v3 = 0;
    SData/*15:0*/ __VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v3;
    __VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v3;
    __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v0;
    __VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v0 = 0;
    SData/*12:0*/ __VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v0;
    __VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v0;
    __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v1;
    __VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v1 = 0;
    SData/*12:0*/ __VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v1;
    __VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v1;
    __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v2;
    __VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v2 = 0;
    SData/*12:0*/ __VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v2;
    __VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v2;
    __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v3;
    __VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v3 = 0;
    SData/*12:0*/ __VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v3;
    __VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v3;
    __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v3 = 0;
    // Body
    __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v0 = 0U;
    __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v1 = 0U;
    __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v2 = 0U;
    __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v3 = 0U;
    __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v0 = 0U;
    __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v1 = 0U;
    __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v2 = 0U;
    __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v3 = 0U;
    __VdlySet__has_soc__DOT__core__DOT__rf__v0 = 0U;
    if (vlSelfRef.has_soc__DOT__sram_inst__DOT__write_d) {
        if ((1U & (IData)(vlSelfRef.has_soc__DOT__sram_inst__DOT__wstrb_q))) {
            __VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v0 
                = (0x000000ffU & vlSelfRef.has_soc__DOT__sram_inst__DOT__wdata_q);
            __VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v0 
                = (0x0000ffffU & vlSelfRef.has_soc__DOT__sram_inst__DOT__unnamedblk1__DOT__word_idx);
            __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v0 = 1U;
        }
        if ((2U & (IData)(vlSelfRef.has_soc__DOT__sram_inst__DOT__wstrb_q))) {
            __VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v1 
                = (0x000000ffU & (vlSelfRef.has_soc__DOT__sram_inst__DOT__wdata_q 
                                  >> 8U));
            __VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v1 
                = (0x0000ffffU & vlSelfRef.has_soc__DOT__sram_inst__DOT__unnamedblk1__DOT__word_idx);
            __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v1 = 1U;
        }
        if ((4U & (IData)(vlSelfRef.has_soc__DOT__sram_inst__DOT__wstrb_q))) {
            __VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v2 
                = (0x000000ffU & (vlSelfRef.has_soc__DOT__sram_inst__DOT__wdata_q 
                                  >> 0x10U));
            __VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v2 
                = (0x0000ffffU & vlSelfRef.has_soc__DOT__sram_inst__DOT__unnamedblk1__DOT__word_idx);
            __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v2 = 1U;
        }
        if ((8U & (IData)(vlSelfRef.has_soc__DOT__sram_inst__DOT__wstrb_q))) {
            __VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v3 
                = (vlSelfRef.has_soc__DOT__sram_inst__DOT__wdata_q 
                   >> 0x18U);
            __VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v3 
                = (0x0000ffffU & vlSelfRef.has_soc__DOT__sram_inst__DOT__unnamedblk1__DOT__word_idx);
            __VdlySet__has_soc__DOT__sram_inst__DOT__mem__v3 = 1U;
        }
    }
    if (vlSelfRef.has_soc__DOT__tcm_inst__DOT__write_d) {
        if ((1U & (IData)(vlSelfRef.has_soc__DOT__tcm_inst__DOT__wstrb_q))) {
            __VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v0 
                = (0x000000ffU & vlSelfRef.has_soc__DOT__tcm_inst__DOT__wdata_q);
            __VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v0 
                = (0x00001fffU & vlSelfRef.has_soc__DOT__tcm_inst__DOT__unnamedblk1__DOT__word_idx);
            __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v0 = 1U;
        }
        if ((2U & (IData)(vlSelfRef.has_soc__DOT__tcm_inst__DOT__wstrb_q))) {
            __VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v1 
                = (0x000000ffU & (vlSelfRef.has_soc__DOT__tcm_inst__DOT__wdata_q 
                                  >> 8U));
            __VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v1 
                = (0x00001fffU & vlSelfRef.has_soc__DOT__tcm_inst__DOT__unnamedblk1__DOT__word_idx);
            __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v1 = 1U;
        }
        if ((4U & (IData)(vlSelfRef.has_soc__DOT__tcm_inst__DOT__wstrb_q))) {
            __VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v2 
                = (0x000000ffU & (vlSelfRef.has_soc__DOT__tcm_inst__DOT__wdata_q 
                                  >> 0x10U));
            __VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v2 
                = (0x00001fffU & vlSelfRef.has_soc__DOT__tcm_inst__DOT__unnamedblk1__DOT__word_idx);
            __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v2 = 1U;
        }
        if ((8U & (IData)(vlSelfRef.has_soc__DOT__tcm_inst__DOT__wstrb_q))) {
            __VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v3 
                = (vlSelfRef.has_soc__DOT__tcm_inst__DOT__wdata_q 
                   >> 0x18U);
            __VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v3 
                = (0x00001fffU & vlSelfRef.has_soc__DOT__tcm_inst__DOT__unnamedblk1__DOT__word_idx);
            __VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v3 = 1U;
        }
    }
    if (((2U & (IData)(vlSelfRef.has_soc__DOT__core__DOT__state))
          ? ((1U & (IData)(vlSelfRef.has_soc__DOT__core__DOT__state))
              ? (0U != (0x0000001fU & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                       >> 7U))) : ((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_2) 
                                                   & ((3U 
                                                       == 
                                                       (0x0000007fU 
                                                        & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)) 
                                                      & (0U 
                                                         != 
                                                         (0x0000001fU 
                                                          & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                             >> 7U))))))
          : ((0U != (0x0000001fU & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                    >> 7U))) & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_24)))) {
        __VdlyVal__has_soc__DOT__core__DOT__rf__v0 
            = ((2U & (IData)(vlSelfRef.has_soc__DOT__core__DOT__state))
                ? ((1U & (IData)(vlSelfRef.has_soc__DOT__core__DOT__state))
                    ? ((0x00004000U & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                        ? ((0x00002000U & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                            ? (0x0000001fU & (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                                              & (- (IData)(
                                                           (1U 
                                                            & (~ 
                                                               (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                                >> 0x0000000cU)))))))
                            : ((0xffffffe0U & (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                                               & ((- (IData)(
                                                             (1U 
                                                              & (~ 
                                                                 (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                                  >> 0x0000000cU))))) 
                                                  << 5U))) 
                               | (0x0000001fU & vlSelfRef.has_soc__DOT__core__DOT__rs1_val)))
                        : ((0x00002000U & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                            ? (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                               & (- (IData)((1U & (~ 
                                                   (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                    >> 0x0000000cU))))))
                            : vlSelfRef.has_soc__DOT__core__DOT__rs1_val))
                    : (((3U == (0x0000007fU & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))
                         ? vlSelfRef.has_soc__DOT__data_rdata
                         : vlSelfRef.has_soc__DOT__core__DOT__alu_out) 
                       & (- (IData)((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_2)))))
                : (vlSelfRef.has_soc__DOT__core__DOT__alu_out 
                   & ((- (IData)((1U & (~ (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_1))))) 
                      & ((- (IData)((1U & (IData)(vlSelfRef.has_soc__DOT__core__DOT__state)))) 
                         & (- (IData)((0x73U != (0x0000007fU 
                                                 & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))))))));
        __VdlyDim0__has_soc__DOT__core__DOT__rf__v0 
            = (0x0000001fU & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                              >> 7U));
        __VdlySet__has_soc__DOT__core__DOT__rf__v0 = 1U;
    }
    if (__VdlySet__has_soc__DOT__sram_inst__DOT__mem__v0) {
        vlSelfRef.has_soc__DOT__sram_inst__DOT__mem[__VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.has_soc__DOT__sram_inst__DOT__mem
                [__VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v0]) 
               | (IData)(__VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v0));
    }
    if (__VdlySet__has_soc__DOT__sram_inst__DOT__mem__v1) {
        vlSelfRef.has_soc__DOT__sram_inst__DOT__mem[__VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.has_soc__DOT__sram_inst__DOT__mem
                [__VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__has_soc__DOT__sram_inst__DOT__mem__v2) {
        vlSelfRef.has_soc__DOT__sram_inst__DOT__mem[__VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.has_soc__DOT__sram_inst__DOT__mem
                [__VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v2) 
                  << 0x00000010U));
    }
    if (__VdlySet__has_soc__DOT__sram_inst__DOT__mem__v3) {
        vlSelfRef.has_soc__DOT__sram_inst__DOT__mem[__VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v3] 
            = ((0x00ffffffU & vlSelfRef.has_soc__DOT__sram_inst__DOT__mem
                [__VdlyDim0__has_soc__DOT__sram_inst__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__has_soc__DOT__sram_inst__DOT__mem__v3) 
                  << 0x00000018U));
    }
    if (__VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v0) {
        vlSelfRef.has_soc__DOT__tcm_inst__DOT__mem[__VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.has_soc__DOT__tcm_inst__DOT__mem
                [__VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v0]) 
               | (IData)(__VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v0));
    }
    if (__VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v1) {
        vlSelfRef.has_soc__DOT__tcm_inst__DOT__mem[__VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.has_soc__DOT__tcm_inst__DOT__mem
                [__VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v2) {
        vlSelfRef.has_soc__DOT__tcm_inst__DOT__mem[__VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.has_soc__DOT__tcm_inst__DOT__mem
                [__VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v2) 
                  << 0x00000010U));
    }
    if (__VdlySet__has_soc__DOT__tcm_inst__DOT__mem__v3) {
        vlSelfRef.has_soc__DOT__tcm_inst__DOT__mem[__VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v3] 
            = ((0x00ffffffU & vlSelfRef.has_soc__DOT__tcm_inst__DOT__mem
                [__VdlyDim0__has_soc__DOT__tcm_inst__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__has_soc__DOT__tcm_inst__DOT__mem__v3) 
                  << 0x00000018U));
    }
    if (__VdlySet__has_soc__DOT__core__DOT__rf__v0) {
        vlSelfRef.has_soc__DOT__core__DOT__rf[__VdlyDim0__has_soc__DOT__core__DOT__rf__v0] 
            = __VdlyVal__has_soc__DOT__core__DOT__rf__v0;
    }
}

void Vhas_soc___024root___nba_sequent__TOP__4(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___nba_sequent__TOP__4\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    SData/*15:0*/ __VdfgRegularize_h6e95ff9d_0_0;
    __VdfgRegularize_h6e95ff9d_0_0 = 0;
    // Body
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_pend 
        = vlSelfRef.__Vdly__has_soc__DOT__gpio_inst__DOT__int_pend;
    if (vlSelfRef.has_soc__DOT__presetn) {
        if (vlSelfRef.has_soc__DOT__wdog_inst__DOT__enable) {
            if ((0U == vlSelfRef.has_soc__DOT__wdog_inst__DOT__count)) {
                vlSelfRef.has_soc__DOT__wdog_inst__DOT__expired = 1U;
            }
        }
        if (((vlSelfRef.has_soc__DOT__timer_inst__DOT__count 
              == vlSelfRef.has_soc__DOT__timer_inst__DOT__compare) 
             & (IData)(vlSelfRef.has_soc__DOT__timer_inst__DOT__enable))) {
            vlSelfRef.__Vdly__has_soc__DOT__timer_inst__DOT__match_pend = 1U;
        }
        if ((IData)((((2U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
                      & (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans)) 
                     & (0x0000000cU == (0x00000ffcU 
                                        & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr))))) {
            vlSelfRef.__Vdly__has_soc__DOT__timer_inst__DOT__match_pend 
                = ((IData)(vlSelfRef.has_soc__DOT__timer_inst__DOT__match_pend) 
                   & (~ vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata));
        }
        if (((2U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
             & (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans))) {
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT_I((
                                                   ((2U 
                                                     == 
                                                     (0x000003ffU 
                                                      & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                         >> 2U))) 
                                                    << 1U) 
                                                   | (1U 
                                                      == 
                                                      (0x000003ffU 
                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                          >> 2U)))))))))) {
                if ((0U == (((2U == (0x000003ffU & 
                                     (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                      >> 2U))) << 1U) 
                            | (1U == (0x000003ffU & 
                                      (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))))) {
                    if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                        VL_WRITEF_NX("[%0t] %%Error: timer.sv:45: Assertion failed in %m: unique case, but none matched for '10'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.timer_inst", 'T',-12
                                     , '#',64,VL_TIME_UNITED_Q(1)
                                     , '#',10,(0x000003ffU 
                                               & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                  >> 2U)));
                        VL_STOP_MT("../../rtl/rtl_peripherals\\timer.sv", 45, "");
                    }
                } else if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                    VL_WRITEF_NX("[%0t] %%Error: timer.sv:45: Assertion failed in %m: unique case, but multiple matches found for '10'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.timer_inst", 'T',-12
                                 , '#',64,VL_TIME_UNITED_Q(1)
                                 , '#',10,(0x000003ffU 
                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)));
                    VL_STOP_MT("../../rtl/rtl_peripherals\\timer.sv", 45, "");
                }
            }
            if ((1U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))) {
                vlSelfRef.has_soc__DOT__timer_inst__DOT__compare 
                    = vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata;
            } else if ((2U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)))) {
                vlSelfRef.has_soc__DOT__timer_inst__DOT__enable 
                    = (1U & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
                vlSelfRef.has_soc__DOT__timer_inst__DOT__int_en 
                    = (1U & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata 
                             >> 1U));
            }
            if (VL_UNLIKELY(((1U & (~ VL_ONEHOT_I((
                                                   (((5U 
                                                      == 
                                                      (0x000003ffU 
                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                          >> 2U))) 
                                                     << 4U) 
                                                    | (((4U 
                                                         == 
                                                         (0x000003ffU 
                                                          & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                             >> 2U))) 
                                                        << 3U) 
                                                       | ((3U 
                                                           == 
                                                           (0x000003ffU 
                                                            & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                               >> 2U))) 
                                                          << 2U))) 
                                                   | (((2U 
                                                        == 
                                                        (0x000003ffU 
                                                         & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                            >> 2U))) 
                                                       << 1U) 
                                                      | (0U 
                                                         == 
                                                         (0x000003ffU 
                                                          & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                             >> 2U))))))))))) {
                if ((0U == ((((5U == (0x000003ffU & 
                                      (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U))) << 4U) 
                             | (((4U == (0x000003ffU 
                                         & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                            >> 2U))) 
                                 << 3U) | ((3U == (0x000003ffU 
                                                   & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                      >> 2U))) 
                                           << 2U))) 
                            | (((2U == (0x000003ffU 
                                        & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                           >> 2U))) 
                                << 1U) | (0U == (0x000003ffU 
                                                 & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                    >> 2U))))))) {
                    if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                        VL_WRITEF_NX("[%0t] %%Error: gpio.sv:113: Assertion failed in %m: unique case, but none matched for '10'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.gpio_inst", 'T',-12
                                     , '#',64,VL_TIME_UNITED_Q(1)
                                     , '#',10,(0x000003ffU 
                                               & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                  >> 2U)));
                        VL_STOP_MT("../../rtl/rtl_peripherals\\gpio.sv", 113, "");
                    }
                } else if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                    VL_WRITEF_NX("[%0t] %%Error: gpio.sv:113: Assertion failed in %m: unique case, but multiple matches found for '10'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.gpio_inst", 'T',-12
                                 , '#',64,VL_TIME_UNITED_Q(1)
                                 , '#',10,(0x000003ffU 
                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)));
                    VL_STOP_MT("../../rtl/rtl_peripherals\\gpio.sv", 113, "");
                }
            }
            if ((0U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))) {
                vlSelfRef.has_soc__DOT__gpio_inst__DOT__data_out_q 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
            } else if ((2U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)))) {
                vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
            } else if ((3U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)))) {
                vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_en 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
            } else if ((4U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)))) {
                vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_rise_en 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
            } else if ((5U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U)))) {
                vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_fall_en 
                    = (0x0000ffffU & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
            }
            if ((1U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                       >> 2U)))) {
                vlSelfRef.has_soc__DOT__wdog_inst__DOT__enable 
                    = (1U & vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata);
            }
        }
    } else {
        vlSelfRef.has_soc__DOT__wdog_inst__DOT__expired = 0U;
        vlSelfRef.__Vdly__has_soc__DOT__timer_inst__DOT__match_pend = 0U;
        vlSelfRef.has_soc__DOT__timer_inst__DOT__compare = 0U;
        vlSelfRef.has_soc__DOT__timer_inst__DOT__enable = 0U;
        vlSelfRef.has_soc__DOT__timer_inst__DOT__int_en = 0U;
        vlSelfRef.has_soc__DOT__gpio_inst__DOT__data_out_q = 0U;
        vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe = 0U;
        vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_en = 0U;
        vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_rise_en = 0U;
        vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_fall_en = 0U;
        vlSelfRef.has_soc__DOT__wdog_inst__DOT__enable = 0U;
    }
    vlSelfRef.has_soc__DOT__wdog_inst__DOT__count = vlSelfRef.__Vdly__has_soc__DOT__wdog_inst__DOT__count;
    vlSelfRef.has_soc__DOT__timer_inst__DOT__count 
        = vlSelfRef.__Vdly__has_soc__DOT__timer_inst__DOT__count;
    vlSelfRef.has_soc__DOT__timer_inst__DOT__match_pend 
        = vlSelfRef.__Vdly__has_soc__DOT__timer_inst__DOT__match_pend;
    vlSelfRef.wdog_reset_n_out = (1U & (~ (IData)(vlSelfRef.has_soc__DOT__wdog_inst__DOT__expired)));
    __VdfgRegularize_h6e95ff9d_0_0 = ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe) 
                                      & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__data_out_q));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out0 
        = ((0xfffeU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out0)) 
           | (1U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out1 
        = ((0xfffdU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out1)) 
           | (2U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out2 
        = ((0xfffbU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out2)) 
           | (4U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out3 
        = ((0xfff7U & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out3)) 
           | (8U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out4 
        = ((0xffefU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out4)) 
           | (0x00000010U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out5 
        = ((0xffdfU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out5)) 
           | (0x00000020U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out6 
        = ((0xffbfU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out6)) 
           | (0x00000040U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out7 
        = ((0xff7fU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out7)) 
           | (0x00000080U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out8 
        = ((0xfeffU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out8)) 
           | (0x00000100U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out9 
        = ((0xfdffU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out9)) 
           | (0x00000200U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out10 
        = ((0xfbffU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out10)) 
           | (0x00000400U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out11 
        = ((0xf7ffU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out11)) 
           | (0x00000800U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out12 
        = ((0xefffU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out12)) 
           | (0x00001000U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out13 
        = ((0xdfffU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out13)) 
           | (0x00002000U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out14 
        = ((0xbfffU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out14)) 
           | (0x00004000U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out15 
        = ((0x7fffU & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out15)) 
           | (0x00008000U & (IData)(__VdfgRegularize_h6e95ff9d_0_0)));
    vlSelfRef.gpio = ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe) 
                      & ((1U & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out0) 
                                & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                         | ((2U & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out1) 
                                   & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                            | ((4U & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out2) 
                                      & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                               | ((8U & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out3) 
                                         & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                                  | ((0x00000010U & 
                                      ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out4) 
                                       & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                                     | ((0x00000020U 
                                         & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out5) 
                                            & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                                        | ((0x00000040U 
                                            & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out6) 
                                               & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                                           | ((0x00000080U 
                                               & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out7) 
                                                  & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                                              | ((0x00000100U 
                                                  & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out8) 
                                                     & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                                                 | ((0x00000200U 
                                                     & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out9) 
                                                        & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                                                    | ((0x00000400U 
                                                        & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out10) 
                                                           & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                                                       | ((0x00000800U 
                                                           & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out11) 
                                                              & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                                                          | ((0x00001000U 
                                                              & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out12) 
                                                                 & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                                                             | ((0x00002000U 
                                                                 & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out13) 
                                                                    & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                                                                | ((0x00004000U 
                                                                    & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out14) 
                                                                       & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe))) 
                                                                   | (0x00008000U 
                                                                      & ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out15) 
                                                                         & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe)))))))))))))))))));
}

extern const VlWide<1024>/*32767:0*/ Vhas_soc__ConstPool__CONST_hfe1b4521_0;
extern const VlWide<14>/*447:0*/ Vhas_soc__ConstPool__CONST_ha8f4385c_0;
extern const VlUnpacked<CData/*3:0*/, 7> Vhas_soc__ConstPool__TABLE_h13faa646_0;

void Vhas_soc___024root___nba_sequent__TOP__5(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___nba_sequent__TOP__5\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ has_soc__DOT____Vcellinp__plic_inst__arvalid;
    has_soc__DOT____Vcellinp__plic_inst__arvalid = 0;
    IData/*31:0*/ has_soc__DOT__core__DOT__imm;
    has_soc__DOT__core__DOT__imm = 0;
    IData/*31:0*/ has_soc__DOT__axi_ic__DOT____VlemCall_20__addr_region;
    IData/*31:0*/ has_soc__DOT__axi_ic__DOT____VlemCall_19__addr_region;
    IData/*31:0*/ has_soc__DOT__axi_ic__DOT____VlemCall_18__addr_region;
    IData/*31:0*/ has_soc__DOT__axi_ic__DOT____VlemCall_17__addr_region;
    IData/*31:0*/ has_soc__DOT__axi_ic__DOT____VlemCall_16__addr_region;
    IData/*31:0*/ has_soc__DOT__axi_ic__DOT____VlemCall_15__addr_region;
    IData/*31:0*/ has_soc__DOT__axi_ic__DOT____VlemCall_6__addr_region;
    IData/*31:0*/ has_soc__DOT__axi_ic__DOT____VlemCall_5__addr_region;
    IData/*31:0*/ has_soc__DOT__axi_ic__DOT____VlemCall_4__addr_region;
    IData/*31:0*/ has_soc__DOT__axi_ic__DOT____VlemCall_3__addr_region;
    IData/*31:0*/ has_soc__DOT__axi_ic__DOT____VlemCall_2__addr_region;
    IData/*31:0*/ has_soc__DOT__axi_ic__DOT____VlemCall_1__addr_region;
    IData/*31:0*/ __Vfunc_addr_region__5__a;
    __Vfunc_addr_region__5__a = 0;
    IData/*31:0*/ __Vfunc_addr_region__6__a;
    __Vfunc_addr_region__6__a = 0;
    IData/*31:0*/ __Vfunc_addr_region__7__a;
    __Vfunc_addr_region__7__a = 0;
    IData/*31:0*/ __Vfunc_addr_region__8__a;
    __Vfunc_addr_region__8__a = 0;
    IData/*31:0*/ __Vfunc_addr_region__9__a;
    __Vfunc_addr_region__9__a = 0;
    IData/*31:0*/ __Vfunc_addr_region__10__a;
    __Vfunc_addr_region__10__a = 0;
    IData/*31:0*/ __Vfunc_addr_region__19__a;
    __Vfunc_addr_region__19__a = 0;
    IData/*31:0*/ __Vfunc_addr_region__20__a;
    __Vfunc_addr_region__20__a = 0;
    IData/*31:0*/ __Vfunc_addr_region__21__a;
    __Vfunc_addr_region__21__a = 0;
    IData/*31:0*/ __Vfunc_addr_region__22__a;
    __Vfunc_addr_region__22__a = 0;
    IData/*31:0*/ __Vfunc_addr_region__23__a;
    __Vfunc_addr_region__23__a = 0;
    IData/*31:0*/ __Vfunc_addr_region__24__a;
    __Vfunc_addr_region__24__a = 0;
    IData/*31:0*/ __VdfgRegularize_h6e95ff9d_0_7;
    __VdfgRegularize_h6e95ff9d_0_7 = 0;
    CData/*0:0*/ __VdfgRegularize_h6e95ff9d_0_9;
    __VdfgRegularize_h6e95ff9d_0_9 = 0;
    CData/*0:0*/ __VdfgRegularize_h6e95ff9d_0_18;
    __VdfgRegularize_h6e95ff9d_0_18 = 0;
    CData/*5:0*/ __VdfgRegularize_h6e95ff9d_0_19;
    __VdfgRegularize_h6e95ff9d_0_19 = 0;
    IData/*31:0*/ __VdfgRegularize_h6e95ff9d_0_26;
    __VdfgRegularize_h6e95ff9d_0_26 = 0;
    IData/*31:0*/ __Vtemp_1;
    // Body
    vlSelfRef.__VdfgRegularize_h6e95ff9d_0_2 = ((IData)(vlSelfRef.has_soc__DOT__data_gnt) 
                                                & (IData)(vlSelfRef.has_soc__DOT__data_rvalid));
    if (vlSelfRef.reset_n) {
        if (((IData)(vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__wvalid) 
             & (IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__wready))) {
            vlSelfRef.has_soc__DOT__sram_inst__DOT__wdata_q = 0U;
            vlSelfRef.has_soc__DOT__sram_inst__DOT__wstrb_q 
                = vlSelfRef.has_soc__DOT__data_wstrb;
        }
        if (((IData)(vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__wvalid) 
             & (IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__wready))) {
            vlSelfRef.has_soc__DOT__tcm_inst__DOT__wdata_q = 0U;
            vlSelfRef.has_soc__DOT__tcm_inst__DOT__wstrb_q 
                = vlSelfRef.has_soc__DOT__data_wstrb;
        }
        if (((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__r_fire) 
             & (~ (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__is_write_q)))) {
            vlSelfRef.has_soc__DOT__data_rdata = ((
                                                   (~ (IData)(vlSelfRef.has_soc__DOT__axi_ic__DOT__r_decode_err)) 
                                                   & (5U 
                                                      >= (IData)(vlSelfRef.has_soc__DOT__axi_ic__DOT__r_src)))
                                                   ? vlSelfRef.has_soc__DOT__s_rdata
                                                  [vlSelfRef.has_soc__DOT__axi_ic__DOT__r_src]
                                                   : 0U);
        }
        if (((0U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
             & ((IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__aw_fire) 
                | (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__ar_fire)))) {
            vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata = 0U;
            vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans 
                = vlSelfRef.has_soc__DOT__apb_bridge__DOT__aw_fire;
            vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
        }
        if (((IData)(vlSelfRef.has_soc__DOT__m_arvalid) 
             & (IData)(vlSelfRef.has_soc__DOT__m_arready))) {
            vlSelfRef.has_soc__DOT__axi_ic__DOT__r_decode_err 
                = (1U & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16));
            vlSelfRef.has_soc__DOT__axi_ic__DOT__r_src 
                = (7U & ((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16) 
                         >> 1U));
        }
        if (((0U == (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__state)) 
             & (IData)(vlSelfRef.has_soc__DOT__data_req))) {
            vlSelfRef.has_soc__DOT__data_adapter__DOT__is_write_q 
                = (IData)((((1U == (IData)(vlSelfRef.has_soc__DOT__core__DOT__state)) 
                            & (0x00000023U == (0x0000007fU 
                                               & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))) 
                           & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_1)));
            vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                = (vlSelfRef.has_soc__DOT__core__DOT__alu_out 
                   & (- (IData)((IData)(vlSelfRef.has_soc__DOT__data_req))));
        }
        if (vlSelfRef.has_soc__DOT__rom_inst__DOT__req_q) {
            vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                = vlSelfRef.has_soc__DOT__rom_inst__DOT__mem
                [(0x00003fffU & ((IData)(vlSelfRef.has_soc__DOT__rom_inst__DOT__addr_q) 
                                 >> 2U))];
        }
        vlSelfRef.has_soc__DOT__rom_inst__DOT__addr_q 
            = (0x0000ffffU & vlSelfRef.has_soc__DOT__core__DOT__pc);
    } else {
        vlSelfRef.has_soc__DOT__sram_inst__DOT__wdata_q = 0U;
        vlSelfRef.has_soc__DOT__sram_inst__DOT__wstrb_q = 0U;
        vlSelfRef.has_soc__DOT__tcm_inst__DOT__wdata_q = 0U;
        vlSelfRef.has_soc__DOT__tcm_inst__DOT__wstrb_q = 0U;
        vlSelfRef.has_soc__DOT__data_rdata = 0U;
        vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_wdata = 0U;
        vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans = 0U;
        vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr = 0U;
        vlSelfRef.has_soc__DOT__axi_ic__DOT__r_decode_err = 1U;
        vlSelfRef.has_soc__DOT__axi_ic__DOT__r_src = 6U;
        vlSelfRef.has_soc__DOT__data_adapter__DOT__is_write_q = 0U;
        vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q = 0U;
        vlSelfRef.has_soc__DOT__core__DOT__fetch_instr = 0U;
        vlSelfRef.has_soc__DOT__rom_inst__DOT__addr_q = 0U;
    }
    vlSelfRef.has_soc__DOT__sram_inst__DOT__write_d 
        = ((IData)(vlSelfRef.reset_n) && ((((IData)(vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__awvalid) 
                                            & (IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__awready)) 
                                           & (IData)(vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__wvalid)) 
                                          & (IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__wready)));
    vlSelfRef.has_soc__DOT__tcm_inst__DOT__write_d 
        = ((IData)(vlSelfRef.reset_n) && ((((IData)(vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__awvalid) 
                                            & (IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__awready)) 
                                           & (IData)(vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__wvalid)) 
                                          & (IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__wready)));
    vlSelfRef.has_soc__DOT____Vcellout__sram_inst__awready 
        = vlSelfRef.__Vdly__has_soc__DOT____Vcellout__sram_inst__awready;
    vlSelfRef.has_soc__DOT____Vcellout__sram_inst__wready 
        = vlSelfRef.__Vdly__has_soc__DOT____Vcellout__sram_inst__wready;
    vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__awready 
        = vlSelfRef.__Vdly__has_soc__DOT____Vcellout__tcm_inst__awready;
    vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__wready 
        = vlSelfRef.__Vdly__has_soc__DOT____Vcellout__tcm_inst__wready;
    vlSelfRef.has_soc__DOT__apb_bridge__DOT__state 
        = vlSelfRef.__Vdly__has_soc__DOT__apb_bridge__DOT__state;
    vlSelfRef.has_soc__DOT__s_bvalid = ((0x3bU & (IData)(vlSelfRef.has_soc__DOT__s_bvalid)) 
                                        | ((IData)(vlSelfRef.has_soc__DOT__sram_inst__DOT__write_d) 
                                           << 2U));
    vlSelfRef.has_soc__DOT__s_awready = ((0x3bU & (IData)(vlSelfRef.has_soc__DOT__s_awready)) 
                                         | ((IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__awready) 
                                            << 2U));
    vlSelfRef.has_soc__DOT__s_wready = ((0x3bU & (IData)(vlSelfRef.has_soc__DOT__s_wready)) 
                                        | ((IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__wready) 
                                           << 2U));
    vlSelfRef.has_soc__DOT__s_bvalid = ((0x3dU & (IData)(vlSelfRef.has_soc__DOT__s_bvalid)) 
                                        | ((IData)(vlSelfRef.has_soc__DOT__tcm_inst__DOT__write_d) 
                                           << 1U));
    vlSelfRef.has_soc__DOT__s_awready = ((0x3dU & (IData)(vlSelfRef.has_soc__DOT__s_awready)) 
                                         | ((IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__awready) 
                                            << 1U));
    vlSelfRef.has_soc__DOT__s_wready = ((0x3dU & (IData)(vlSelfRef.has_soc__DOT__s_wready)) 
                                        | ((IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__wready) 
                                           << 1U));
    vlSelfRef.has_soc__DOT__s_arready = ((0x2fU & (IData)(vlSelfRef.has_soc__DOT__s_arready)) 
                                         | ((0U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
                                            << 4U));
    vlSelfRef.has_soc__DOT__s_wready = ((0x2fU & (IData)(vlSelfRef.has_soc__DOT__s_wready)) 
                                        | ((0U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
                                           << 4U));
    vlSelfRef.has_soc__DOT__s_awready = ((0x2fU & (IData)(vlSelfRef.has_soc__DOT__s_awready)) 
                                         | ((0U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
                                            << 4U));
    if ((1U & (~ VL_ONEHOT_I(((((((0U == (0x000003ffU 
                                          & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                             >> 2U))) 
                                  << 4U) | (((0x0300U 
                                              == (0x000003ffU 
                                                  & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                     >> 2U))) 
                                             << 3U) 
                                            | ((0x0200U 
                                                == 
                                                (0x000003ffU 
                                                 & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                    >> 2U))) 
                                               << 2U))) 
                                | (((0x0100U == (0x000003ffU 
                                                 & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                    >> 2U))) 
                                    << 1U) | (0U == 
                                              (0x000003ffU 
                                               & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                  >> 2U))))) 
                               << 4U) | ((((0x0300U 
                                            == (0x000003ffU 
                                                & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                   >> 2U))) 
                                           << 3U) | 
                                          ((0x0200U 
                                            == (0x000003ffU 
                                                & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                   >> 2U))) 
                                           << 2U)) 
                                         | (((0x0100U 
                                              == (0x000003ffU 
                                                  & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                     >> 2U))) 
                                             << 1U) 
                                            | (0U == 
                                               (0x000003ffU 
                                                & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                   >> 2U)))))))))) {
        if ((0U != ((((((0U == (0x000003ffU & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                               >> 2U))) 
                        << 4U) | (((0x0300U == (0x000003ffU 
                                                & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                   >> 2U))) 
                                   << 3U) | ((0x0200U 
                                              == (0x000003ffU 
                                                  & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                     >> 2U))) 
                                             << 2U))) 
                      | (((0x0100U == (0x000003ffU 
                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                          >> 2U))) 
                          << 1U) | (0U == (0x000003ffU 
                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                              >> 2U))))) 
                     << 4U) | ((((0x0300U == (0x000003ffU 
                                              & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                 >> 2U))) 
                                 << 3U) | ((0x0200U 
                                            == (0x000003ffU 
                                                & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                   >> 2U))) 
                                           << 2U)) 
                               | (((0x0100U == (0x000003ffU 
                                                & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                   >> 2U))) 
                                   << 1U) | (0U == 
                                             (0x000003ffU 
                                              & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                 >> 2U)))))))) {
            if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                VL_WRITEF_NX("[%0t] %%Error: has_soc.sv:491: Assertion failed in %m: unique case, but multiple matches found for '10'h%X'\n",4, 'M',vlSymsp->name(),"has_soc", 'T',-12
                             , '#',64,VL_TIME_UNITED_Q(1)
                             , '#',10,(0x000003ffU 
                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                          >> 2U)));
                VL_STOP_MT("../../rtl/rtl_top\\has_soc.sv", 491, "");
            }
        }
    }
    vlSelfRef.has_soc__DOT__apb_sel = (0x000003ffU 
                                       & Vhas_soc__ConstPool__CONST_hfe1b4521_0
                                       [(0x000003ffU 
                                         & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                            >> 2U))]);
    __VdfgRegularize_h6e95ff9d_0_9 = ((0U != (IData)(vlSelfRef.has_soc__DOT__apb_sel)) 
                                      & (2U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)));
    vlSelfRef.has_soc__DOT__data_adapter__DOT__state 
        = vlSelfRef.__Vdly__has_soc__DOT__data_adapter__DOT__state;
    vlSelfRef.has_soc__DOT__s_rvalid = ((0x2fU & (IData)(vlSelfRef.has_soc__DOT__s_rvalid)) 
                                        | (((~ (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans)) 
                                            & (IData)(__VdfgRegularize_h6e95ff9d_0_9)) 
                                           << 4U));
    vlSelfRef.has_soc__DOT__s_bvalid = ((0x2fU & (IData)(vlSelfRef.has_soc__DOT__s_bvalid)) 
                                        | (((IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans) 
                                            & (IData)(__VdfgRegularize_h6e95ff9d_0_9)) 
                                           << 4U));
    vlSelfRef.has_soc__DOT__m_wvalid = ((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__is_write_q) 
                                        & (2U == (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__state)));
    vlSelfRef.has_soc__DOT__s_rdata[3U] = vlSelfRef.has_soc__DOT__qspi_ctrl__DOT__flash_mem
        [(0x000003ffU & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                         >> 2U))];
    vlSelfRef.has_soc__DOT__s_rdata[5U] = ((0U == (0x00000fffU 
                                                   & vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q))
                                            ? vlSelfRef.has_soc__DOT__clint_inst__DOT__msip
                                            : ((0x03f8U 
                                                == 
                                                (0x00000fffU 
                                                 & vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q))
                                                ? (IData)(vlSelfRef.has_soc__DOT__clint_inst__DOT__mtime)
                                                : ((IData)(
                                                           (vlSelfRef.has_soc__DOT__clint_inst__DOT__mtime 
                                                            >> 0x00000020U)) 
                                                   & (- (IData)(
                                                                (0x03fcU 
                                                                 == 
                                                                 (0x00000fffU 
                                                                  & vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q)))))));
    __Vfunc_addr_region__5__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
    has_soc__DOT__axi_ic__DOT____VlemCall_1__addr_region 
        = ((0x00004000U > __Vfunc_addr_region__5__a)
            ? 0U : (((0x00010000U <= __Vfunc_addr_region__5__a) 
                     & (0x00018000U > __Vfunc_addr_region__5__a))
                     ? 1U : (((0x20000000U <= __Vfunc_addr_region__5__a) 
                              & (0x20020000U > __Vfunc_addr_region__5__a))
                              ? 2U : (((0x40000000U 
                                        <= __Vfunc_addr_region__5__a) 
                                       & (0x44000000U 
                                          > __Vfunc_addr_region__5__a))
                                       ? 3U : (((0x50000000U 
                                                 <= __Vfunc_addr_region__5__a) 
                                                & (0x50100000U 
                                                   > __Vfunc_addr_region__5__a))
                                                ? 4U
                                                : (
                                                   ((0x80000000U 
                                                     <= __Vfunc_addr_region__5__a) 
                                                    & (0x80010000U 
                                                       > __Vfunc_addr_region__5__a))
                                                    ? 5U
                                                    : 6U))))));
    __Vfunc_addr_region__6__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
    has_soc__DOT__axi_ic__DOT____VlemCall_2__addr_region 
        = ((0x00004000U > __Vfunc_addr_region__6__a)
            ? 0U : (((0x00010000U <= __Vfunc_addr_region__6__a) 
                     & (0x00018000U > __Vfunc_addr_region__6__a))
                     ? 1U : (((0x20000000U <= __Vfunc_addr_region__6__a) 
                              & (0x20020000U > __Vfunc_addr_region__6__a))
                              ? 2U : (((0x40000000U 
                                        <= __Vfunc_addr_region__6__a) 
                                       & (0x44000000U 
                                          > __Vfunc_addr_region__6__a))
                                       ? 3U : (((0x50000000U 
                                                 <= __Vfunc_addr_region__6__a) 
                                                & (0x50100000U 
                                                   > __Vfunc_addr_region__6__a))
                                                ? 4U
                                                : (
                                                   ((0x80000000U 
                                                     <= __Vfunc_addr_region__6__a) 
                                                    & (0x80010000U 
                                                       > __Vfunc_addr_region__6__a))
                                                    ? 5U
                                                    : 6U))))));
    __Vfunc_addr_region__7__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
    has_soc__DOT__axi_ic__DOT____VlemCall_3__addr_region 
        = ((0x00004000U > __Vfunc_addr_region__7__a)
            ? 0U : (((0x00010000U <= __Vfunc_addr_region__7__a) 
                     & (0x00018000U > __Vfunc_addr_region__7__a))
                     ? 1U : (((0x20000000U <= __Vfunc_addr_region__7__a) 
                              & (0x20020000U > __Vfunc_addr_region__7__a))
                              ? 2U : (((0x40000000U 
                                        <= __Vfunc_addr_region__7__a) 
                                       & (0x44000000U 
                                          > __Vfunc_addr_region__7__a))
                                       ? 3U : (((0x50000000U 
                                                 <= __Vfunc_addr_region__7__a) 
                                                & (0x50100000U 
                                                   > __Vfunc_addr_region__7__a))
                                                ? 4U
                                                : (
                                                   ((0x80000000U 
                                                     <= __Vfunc_addr_region__7__a) 
                                                    & (0x80010000U 
                                                       > __Vfunc_addr_region__7__a))
                                                    ? 5U
                                                    : 6U))))));
    __Vfunc_addr_region__8__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
    has_soc__DOT__axi_ic__DOT____VlemCall_4__addr_region 
        = ((0x00004000U > __Vfunc_addr_region__8__a)
            ? 0U : (((0x00010000U <= __Vfunc_addr_region__8__a) 
                     & (0x00018000U > __Vfunc_addr_region__8__a))
                     ? 1U : (((0x20000000U <= __Vfunc_addr_region__8__a) 
                              & (0x20020000U > __Vfunc_addr_region__8__a))
                              ? 2U : (((0x40000000U 
                                        <= __Vfunc_addr_region__8__a) 
                                       & (0x44000000U 
                                          > __Vfunc_addr_region__8__a))
                                       ? 3U : (((0x50000000U 
                                                 <= __Vfunc_addr_region__8__a) 
                                                & (0x50100000U 
                                                   > __Vfunc_addr_region__8__a))
                                                ? 4U
                                                : (
                                                   ((0x80000000U 
                                                     <= __Vfunc_addr_region__8__a) 
                                                    & (0x80010000U 
                                                       > __Vfunc_addr_region__8__a))
                                                    ? 5U
                                                    : 6U))))));
    __Vfunc_addr_region__9__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
    has_soc__DOT__axi_ic__DOT____VlemCall_5__addr_region 
        = ((0x00004000U > __Vfunc_addr_region__9__a)
            ? 0U : (((0x00010000U <= __Vfunc_addr_region__9__a) 
                     & (0x00018000U > __Vfunc_addr_region__9__a))
                     ? 1U : (((0x20000000U <= __Vfunc_addr_region__9__a) 
                              & (0x20020000U > __Vfunc_addr_region__9__a))
                              ? 2U : (((0x40000000U 
                                        <= __Vfunc_addr_region__9__a) 
                                       & (0x44000000U 
                                          > __Vfunc_addr_region__9__a))
                                       ? 3U : (((0x50000000U 
                                                 <= __Vfunc_addr_region__9__a) 
                                                & (0x50100000U 
                                                   > __Vfunc_addr_region__9__a))
                                                ? 4U
                                                : (
                                                   ((0x80000000U 
                                                     <= __Vfunc_addr_region__9__a) 
                                                    & (0x80010000U 
                                                       > __Vfunc_addr_region__9__a))
                                                    ? 5U
                                                    : 6U))))));
    __Vfunc_addr_region__10__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
    has_soc__DOT__axi_ic__DOT____VlemCall_6__addr_region 
        = ((0x00004000U > __Vfunc_addr_region__10__a)
            ? 0U : (((0x00010000U <= __Vfunc_addr_region__10__a) 
                     & (0x00018000U > __Vfunc_addr_region__10__a))
                     ? 1U : (((0x20000000U <= __Vfunc_addr_region__10__a) 
                              & (0x20020000U > __Vfunc_addr_region__10__a))
                              ? 2U : (((0x40000000U 
                                        <= __Vfunc_addr_region__10__a) 
                                       & (0x44000000U 
                                          > __Vfunc_addr_region__10__a))
                                       ? 3U : (((0x50000000U 
                                                 <= __Vfunc_addr_region__10__a) 
                                                & (0x50100000U 
                                                   > __Vfunc_addr_region__10__a))
                                                ? 4U
                                                : (
                                                   ((0x80000000U 
                                                     <= __Vfunc_addr_region__10__a) 
                                                    & (0x80010000U 
                                                       > __Vfunc_addr_region__10__a))
                                                    ? 5U
                                                    : 6U))))));
    if ((1U & (~ VL_ONEHOT_I(((((5U == has_soc__DOT__axi_ic__DOT____VlemCall_1__addr_region) 
                                << 5U) | (((4U == has_soc__DOT__axi_ic__DOT____VlemCall_2__addr_region) 
                                           << 4U) | 
                                          ((3U == has_soc__DOT__axi_ic__DOT____VlemCall_3__addr_region) 
                                           << 3U))) 
                              | (((2U == has_soc__DOT__axi_ic__DOT____VlemCall_4__addr_region) 
                                  << 2U) | (((1U == has_soc__DOT__axi_ic__DOT____VlemCall_5__addr_region) 
                                             << 1U) 
                                            | (0U == has_soc__DOT__axi_ic__DOT____VlemCall_6__addr_region)))))))) {
        vlSelfRef.__Vfunc_addr_region__11__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
        vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_7__addr_region 
            = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__11__a)
                ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__11__a) 
                         & (0x00018000U > vlSelfRef.__Vfunc_addr_region__11__a))
                         ? 1U : (((0x20000000U <= vlSelfRef.__Vfunc_addr_region__11__a) 
                                  & (0x20020000U > vlSelfRef.__Vfunc_addr_region__11__a))
                                  ? 2U : (((0x40000000U 
                                            <= vlSelfRef.__Vfunc_addr_region__11__a) 
                                           & (0x44000000U 
                                              > vlSelfRef.__Vfunc_addr_region__11__a))
                                           ? 3U : (
                                                   ((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__11__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__11__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__11__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__11__a))
                                                     ? 5U
                                                     : 6U))))));
        vlSelfRef.__Vfunc_addr_region__12__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
        vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_8__addr_region 
            = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__12__a)
                ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__12__a) 
                         & (0x00018000U > vlSelfRef.__Vfunc_addr_region__12__a))
                         ? 1U : (((0x20000000U <= vlSelfRef.__Vfunc_addr_region__12__a) 
                                  & (0x20020000U > vlSelfRef.__Vfunc_addr_region__12__a))
                                  ? 2U : (((0x40000000U 
                                            <= vlSelfRef.__Vfunc_addr_region__12__a) 
                                           & (0x44000000U 
                                              > vlSelfRef.__Vfunc_addr_region__12__a))
                                           ? 3U : (
                                                   ((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__12__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__12__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__12__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__12__a))
                                                     ? 5U
                                                     : 6U))))));
        vlSelfRef.__Vfunc_addr_region__13__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
        vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_9__addr_region 
            = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__13__a)
                ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__13__a) 
                         & (0x00018000U > vlSelfRef.__Vfunc_addr_region__13__a))
                         ? 1U : (((0x20000000U <= vlSelfRef.__Vfunc_addr_region__13__a) 
                                  & (0x20020000U > vlSelfRef.__Vfunc_addr_region__13__a))
                                  ? 2U : (((0x40000000U 
                                            <= vlSelfRef.__Vfunc_addr_region__13__a) 
                                           & (0x44000000U 
                                              > vlSelfRef.__Vfunc_addr_region__13__a))
                                           ? 3U : (
                                                   ((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__13__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__13__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__13__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__13__a))
                                                     ? 5U
                                                     : 6U))))));
        vlSelfRef.__Vfunc_addr_region__14__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
        vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_10__addr_region 
            = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__14__a)
                ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__14__a) 
                         & (0x00018000U > vlSelfRef.__Vfunc_addr_region__14__a))
                         ? 1U : (((0x20000000U <= vlSelfRef.__Vfunc_addr_region__14__a) 
                                  & (0x20020000U > vlSelfRef.__Vfunc_addr_region__14__a))
                                  ? 2U : (((0x40000000U 
                                            <= vlSelfRef.__Vfunc_addr_region__14__a) 
                                           & (0x44000000U 
                                              > vlSelfRef.__Vfunc_addr_region__14__a))
                                           ? 3U : (
                                                   ((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__14__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__14__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__14__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__14__a))
                                                     ? 5U
                                                     : 6U))))));
        vlSelfRef.__Vfunc_addr_region__15__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
        vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_11__addr_region 
            = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__15__a)
                ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__15__a) 
                         & (0x00018000U > vlSelfRef.__Vfunc_addr_region__15__a))
                         ? 1U : (((0x20000000U <= vlSelfRef.__Vfunc_addr_region__15__a) 
                                  & (0x20020000U > vlSelfRef.__Vfunc_addr_region__15__a))
                                  ? 2U : (((0x40000000U 
                                            <= vlSelfRef.__Vfunc_addr_region__15__a) 
                                           & (0x44000000U 
                                              > vlSelfRef.__Vfunc_addr_region__15__a))
                                           ? 3U : (
                                                   ((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__15__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__15__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__15__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__15__a))
                                                     ? 5U
                                                     : 6U))))));
        vlSelfRef.__Vfunc_addr_region__16__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
        vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_12__addr_region 
            = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__16__a)
                ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__16__a) 
                         & (0x00018000U > vlSelfRef.__Vfunc_addr_region__16__a))
                         ? 1U : (((0x20000000U <= vlSelfRef.__Vfunc_addr_region__16__a) 
                                  & (0x20020000U > vlSelfRef.__Vfunc_addr_region__16__a))
                                  ? 2U : (((0x40000000U 
                                            <= vlSelfRef.__Vfunc_addr_region__16__a) 
                                           & (0x44000000U 
                                              > vlSelfRef.__Vfunc_addr_region__16__a))
                                           ? 3U : (
                                                   ((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__16__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__16__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__16__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__16__a))
                                                     ? 5U
                                                     : 6U))))));
        if ((0U != ((((5U == vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_7__addr_region) 
                      << 5U) | (((4U == vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_8__addr_region) 
                                 << 4U) | ((3U == vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_9__addr_region) 
                                           << 3U))) 
                    | (((2U == vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_10__addr_region) 
                        << 2U) | (((1U == vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_11__addr_region) 
                                   << 1U) | (0U == vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_12__addr_region)))))) {
            if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                vlSelfRef.__Vfunc_addr_region__17__a 
                    = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
                vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_13__addr_region 
                    = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__17__a)
                        ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__17__a) 
                                 & (0x00018000U > vlSelfRef.__Vfunc_addr_region__17__a))
                                 ? 1U : (((0x20000000U 
                                           <= vlSelfRef.__Vfunc_addr_region__17__a) 
                                          & (0x20020000U 
                                             > vlSelfRef.__Vfunc_addr_region__17__a))
                                          ? 2U : ((
                                                   (0x40000000U 
                                                    <= vlSelfRef.__Vfunc_addr_region__17__a) 
                                                   & (0x44000000U 
                                                      > vlSelfRef.__Vfunc_addr_region__17__a))
                                                   ? 3U
                                                   : 
                                                  (((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__17__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__17__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__17__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__17__a))
                                                     ? 5U
                                                     : 6U))))));
                VL_WRITEF_NX("[%0t] %%Error: axi_lite_interconnect.sv:69: Assertion failed in %m: unique case, but multiple matches found for '32'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.axi_ic", 'T',-12
                             , '#',64,VL_TIME_UNITED_Q(1)
                             , '#',32,vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_13__addr_region);
                VL_STOP_MT("../../rtl/rtl_top\\axi_lite_interconnect.sv", 69, "");
            }
        }
    }
    __Vfunc_addr_region__19__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
    has_soc__DOT__axi_ic__DOT____VlemCall_15__addr_region 
        = ((0x00004000U > __Vfunc_addr_region__19__a)
            ? 0U : (((0x00010000U <= __Vfunc_addr_region__19__a) 
                     & (0x00018000U > __Vfunc_addr_region__19__a))
                     ? 1U : (((0x20000000U <= __Vfunc_addr_region__19__a) 
                              & (0x20020000U > __Vfunc_addr_region__19__a))
                              ? 2U : (((0x40000000U 
                                        <= __Vfunc_addr_region__19__a) 
                                       & (0x44000000U 
                                          > __Vfunc_addr_region__19__a))
                                       ? 3U : (((0x50000000U 
                                                 <= __Vfunc_addr_region__19__a) 
                                                & (0x50100000U 
                                                   > __Vfunc_addr_region__19__a))
                                                ? 4U
                                                : (
                                                   ((0x80000000U 
                                                     <= __Vfunc_addr_region__19__a) 
                                                    & (0x80010000U 
                                                       > __Vfunc_addr_region__19__a))
                                                    ? 5U
                                                    : 6U))))));
    __Vfunc_addr_region__20__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
    has_soc__DOT__axi_ic__DOT____VlemCall_16__addr_region 
        = ((0x00004000U > __Vfunc_addr_region__20__a)
            ? 0U : (((0x00010000U <= __Vfunc_addr_region__20__a) 
                     & (0x00018000U > __Vfunc_addr_region__20__a))
                     ? 1U : (((0x20000000U <= __Vfunc_addr_region__20__a) 
                              & (0x20020000U > __Vfunc_addr_region__20__a))
                              ? 2U : (((0x40000000U 
                                        <= __Vfunc_addr_region__20__a) 
                                       & (0x44000000U 
                                          > __Vfunc_addr_region__20__a))
                                       ? 3U : (((0x50000000U 
                                                 <= __Vfunc_addr_region__20__a) 
                                                & (0x50100000U 
                                                   > __Vfunc_addr_region__20__a))
                                                ? 4U
                                                : (
                                                   ((0x80000000U 
                                                     <= __Vfunc_addr_region__20__a) 
                                                    & (0x80010000U 
                                                       > __Vfunc_addr_region__20__a))
                                                    ? 5U
                                                    : 6U))))));
    __Vfunc_addr_region__21__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
    has_soc__DOT__axi_ic__DOT____VlemCall_17__addr_region 
        = ((0x00004000U > __Vfunc_addr_region__21__a)
            ? 0U : (((0x00010000U <= __Vfunc_addr_region__21__a) 
                     & (0x00018000U > __Vfunc_addr_region__21__a))
                     ? 1U : (((0x20000000U <= __Vfunc_addr_region__21__a) 
                              & (0x20020000U > __Vfunc_addr_region__21__a))
                              ? 2U : (((0x40000000U 
                                        <= __Vfunc_addr_region__21__a) 
                                       & (0x44000000U 
                                          > __Vfunc_addr_region__21__a))
                                       ? 3U : (((0x50000000U 
                                                 <= __Vfunc_addr_region__21__a) 
                                                & (0x50100000U 
                                                   > __Vfunc_addr_region__21__a))
                                                ? 4U
                                                : (
                                                   ((0x80000000U 
                                                     <= __Vfunc_addr_region__21__a) 
                                                    & (0x80010000U 
                                                       > __Vfunc_addr_region__21__a))
                                                    ? 5U
                                                    : 6U))))));
    __Vfunc_addr_region__22__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
    has_soc__DOT__axi_ic__DOT____VlemCall_18__addr_region 
        = ((0x00004000U > __Vfunc_addr_region__22__a)
            ? 0U : (((0x00010000U <= __Vfunc_addr_region__22__a) 
                     & (0x00018000U > __Vfunc_addr_region__22__a))
                     ? 1U : (((0x20000000U <= __Vfunc_addr_region__22__a) 
                              & (0x20020000U > __Vfunc_addr_region__22__a))
                              ? 2U : (((0x40000000U 
                                        <= __Vfunc_addr_region__22__a) 
                                       & (0x44000000U 
                                          > __Vfunc_addr_region__22__a))
                                       ? 3U : (((0x50000000U 
                                                 <= __Vfunc_addr_region__22__a) 
                                                & (0x50100000U 
                                                   > __Vfunc_addr_region__22__a))
                                                ? 4U
                                                : (
                                                   ((0x80000000U 
                                                     <= __Vfunc_addr_region__22__a) 
                                                    & (0x80010000U 
                                                       > __Vfunc_addr_region__22__a))
                                                    ? 5U
                                                    : 6U))))));
    __Vfunc_addr_region__23__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
    has_soc__DOT__axi_ic__DOT____VlemCall_19__addr_region 
        = ((0x00004000U > __Vfunc_addr_region__23__a)
            ? 0U : (((0x00010000U <= __Vfunc_addr_region__23__a) 
                     & (0x00018000U > __Vfunc_addr_region__23__a))
                     ? 1U : (((0x20000000U <= __Vfunc_addr_region__23__a) 
                              & (0x20020000U > __Vfunc_addr_region__23__a))
                              ? 2U : (((0x40000000U 
                                        <= __Vfunc_addr_region__23__a) 
                                       & (0x44000000U 
                                          > __Vfunc_addr_region__23__a))
                                       ? 3U : (((0x50000000U 
                                                 <= __Vfunc_addr_region__23__a) 
                                                & (0x50100000U 
                                                   > __Vfunc_addr_region__23__a))
                                                ? 4U
                                                : (
                                                   ((0x80000000U 
                                                     <= __Vfunc_addr_region__23__a) 
                                                    & (0x80010000U 
                                                       > __Vfunc_addr_region__23__a))
                                                    ? 5U
                                                    : 6U))))));
    __Vfunc_addr_region__24__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
    has_soc__DOT__axi_ic__DOT____VlemCall_20__addr_region 
        = ((0x00004000U > __Vfunc_addr_region__24__a)
            ? 0U : (((0x00010000U <= __Vfunc_addr_region__24__a) 
                     & (0x00018000U > __Vfunc_addr_region__24__a))
                     ? 1U : (((0x20000000U <= __Vfunc_addr_region__24__a) 
                              & (0x20020000U > __Vfunc_addr_region__24__a))
                              ? 2U : (((0x40000000U 
                                        <= __Vfunc_addr_region__24__a) 
                                       & (0x44000000U 
                                          > __Vfunc_addr_region__24__a))
                                       ? 3U : (((0x50000000U 
                                                 <= __Vfunc_addr_region__24__a) 
                                                & (0x50100000U 
                                                   > __Vfunc_addr_region__24__a))
                                                ? 4U
                                                : (
                                                   ((0x80000000U 
                                                     <= __Vfunc_addr_region__24__a) 
                                                    & (0x80010000U 
                                                       > __Vfunc_addr_region__24__a))
                                                    ? 5U
                                                    : 6U))))));
    if ((1U & (~ VL_ONEHOT_I(((((5U == has_soc__DOT__axi_ic__DOT____VlemCall_15__addr_region) 
                                << 5U) | (((4U == has_soc__DOT__axi_ic__DOT____VlemCall_16__addr_region) 
                                           << 4U) | 
                                          ((3U == has_soc__DOT__axi_ic__DOT____VlemCall_17__addr_region) 
                                           << 3U))) 
                              | (((2U == has_soc__DOT__axi_ic__DOT____VlemCall_18__addr_region) 
                                  << 2U) | (((1U == has_soc__DOT__axi_ic__DOT____VlemCall_19__addr_region) 
                                             << 1U) 
                                            | (0U == has_soc__DOT__axi_ic__DOT____VlemCall_20__addr_region)))))))) {
        vlSelfRef.__Vfunc_addr_region__25__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
        vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_21__addr_region 
            = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__25__a)
                ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__25__a) 
                         & (0x00018000U > vlSelfRef.__Vfunc_addr_region__25__a))
                         ? 1U : (((0x20000000U <= vlSelfRef.__Vfunc_addr_region__25__a) 
                                  & (0x20020000U > vlSelfRef.__Vfunc_addr_region__25__a))
                                  ? 2U : (((0x40000000U 
                                            <= vlSelfRef.__Vfunc_addr_region__25__a) 
                                           & (0x44000000U 
                                              > vlSelfRef.__Vfunc_addr_region__25__a))
                                           ? 3U : (
                                                   ((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__25__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__25__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__25__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__25__a))
                                                     ? 5U
                                                     : 6U))))));
        vlSelfRef.__Vfunc_addr_region__26__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
        vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_22__addr_region 
            = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__26__a)
                ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__26__a) 
                         & (0x00018000U > vlSelfRef.__Vfunc_addr_region__26__a))
                         ? 1U : (((0x20000000U <= vlSelfRef.__Vfunc_addr_region__26__a) 
                                  & (0x20020000U > vlSelfRef.__Vfunc_addr_region__26__a))
                                  ? 2U : (((0x40000000U 
                                            <= vlSelfRef.__Vfunc_addr_region__26__a) 
                                           & (0x44000000U 
                                              > vlSelfRef.__Vfunc_addr_region__26__a))
                                           ? 3U : (
                                                   ((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__26__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__26__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__26__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__26__a))
                                                     ? 5U
                                                     : 6U))))));
        vlSelfRef.__Vfunc_addr_region__27__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
        vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_23__addr_region 
            = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__27__a)
                ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__27__a) 
                         & (0x00018000U > vlSelfRef.__Vfunc_addr_region__27__a))
                         ? 1U : (((0x20000000U <= vlSelfRef.__Vfunc_addr_region__27__a) 
                                  & (0x20020000U > vlSelfRef.__Vfunc_addr_region__27__a))
                                  ? 2U : (((0x40000000U 
                                            <= vlSelfRef.__Vfunc_addr_region__27__a) 
                                           & (0x44000000U 
                                              > vlSelfRef.__Vfunc_addr_region__27__a))
                                           ? 3U : (
                                                   ((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__27__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__27__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__27__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__27__a))
                                                     ? 5U
                                                     : 6U))))));
        vlSelfRef.__Vfunc_addr_region__28__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
        vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_24__addr_region 
            = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__28__a)
                ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__28__a) 
                         & (0x00018000U > vlSelfRef.__Vfunc_addr_region__28__a))
                         ? 1U : (((0x20000000U <= vlSelfRef.__Vfunc_addr_region__28__a) 
                                  & (0x20020000U > vlSelfRef.__Vfunc_addr_region__28__a))
                                  ? 2U : (((0x40000000U 
                                            <= vlSelfRef.__Vfunc_addr_region__28__a) 
                                           & (0x44000000U 
                                              > vlSelfRef.__Vfunc_addr_region__28__a))
                                           ? 3U : (
                                                   ((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__28__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__28__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__28__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__28__a))
                                                     ? 5U
                                                     : 6U))))));
        vlSelfRef.__Vfunc_addr_region__29__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
        vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_25__addr_region 
            = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__29__a)
                ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__29__a) 
                         & (0x00018000U > vlSelfRef.__Vfunc_addr_region__29__a))
                         ? 1U : (((0x20000000U <= vlSelfRef.__Vfunc_addr_region__29__a) 
                                  & (0x20020000U > vlSelfRef.__Vfunc_addr_region__29__a))
                                  ? 2U : (((0x40000000U 
                                            <= vlSelfRef.__Vfunc_addr_region__29__a) 
                                           & (0x44000000U 
                                              > vlSelfRef.__Vfunc_addr_region__29__a))
                                           ? 3U : (
                                                   ((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__29__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__29__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__29__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__29__a))
                                                     ? 5U
                                                     : 6U))))));
        vlSelfRef.__Vfunc_addr_region__30__a = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
        vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_26__addr_region 
            = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__30__a)
                ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__30__a) 
                         & (0x00018000U > vlSelfRef.__Vfunc_addr_region__30__a))
                         ? 1U : (((0x20000000U <= vlSelfRef.__Vfunc_addr_region__30__a) 
                                  & (0x20020000U > vlSelfRef.__Vfunc_addr_region__30__a))
                                  ? 2U : (((0x40000000U 
                                            <= vlSelfRef.__Vfunc_addr_region__30__a) 
                                           & (0x44000000U 
                                              > vlSelfRef.__Vfunc_addr_region__30__a))
                                           ? 3U : (
                                                   ((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__30__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__30__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__30__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__30__a))
                                                     ? 5U
                                                     : 6U))))));
        if ((0U != ((((5U == vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_21__addr_region) 
                      << 5U) | (((4U == vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_22__addr_region) 
                                 << 4U) | ((3U == vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_23__addr_region) 
                                           << 3U))) 
                    | (((2U == vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_24__addr_region) 
                        << 2U) | (((1U == vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_25__addr_region) 
                                   << 1U) | (0U == vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_26__addr_region)))))) {
            if (VL_UNLIKELY((vlSymsp->_vm_contextp__->assertOn()))) {
                vlSelfRef.__Vfunc_addr_region__31__a 
                    = vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q;
                vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_27__addr_region 
                    = ((0x00004000U > vlSelfRef.__Vfunc_addr_region__31__a)
                        ? 0U : (((0x00010000U <= vlSelfRef.__Vfunc_addr_region__31__a) 
                                 & (0x00018000U > vlSelfRef.__Vfunc_addr_region__31__a))
                                 ? 1U : (((0x20000000U 
                                           <= vlSelfRef.__Vfunc_addr_region__31__a) 
                                          & (0x20020000U 
                                             > vlSelfRef.__Vfunc_addr_region__31__a))
                                          ? 2U : ((
                                                   (0x40000000U 
                                                    <= vlSelfRef.__Vfunc_addr_region__31__a) 
                                                   & (0x44000000U 
                                                      > vlSelfRef.__Vfunc_addr_region__31__a))
                                                   ? 3U
                                                   : 
                                                  (((0x50000000U 
                                                     <= vlSelfRef.__Vfunc_addr_region__31__a) 
                                                    & (0x50100000U 
                                                       > vlSelfRef.__Vfunc_addr_region__31__a))
                                                    ? 4U
                                                    : 
                                                   (((0x80000000U 
                                                      <= vlSelfRef.__Vfunc_addr_region__31__a) 
                                                     & (0x80010000U 
                                                        > vlSelfRef.__Vfunc_addr_region__31__a))
                                                     ? 5U
                                                     : 6U))))));
                VL_WRITEF_NX("[%0t] %%Error: axi_lite_interconnect.sv:128: Assertion failed in %m: unique case, but multiple matches found for '32'h%X'\n",4, 'M',vlSymsp->name(),"has_soc.axi_ic", 'T',-12
                             , '#',64,VL_TIME_UNITED_Q(1)
                             , '#',32,vlSelfRef.has_soc__DOT__axi_ic__DOT____VlemCall_27__addr_region);
                VL_STOP_MT("../../rtl/rtl_top\\axi_lite_interconnect.sv", 128, "");
            }
        }
    }
    __Vtemp_1 = VL_MATCHMASKED_I(32, ((((0x00010000U 
                                         <= vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q) 
                                        & (0x00018000U 
                                           > vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q))
                                        ? 1U : (((0x20000000U 
                                                  <= vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q) 
                                                 & (0x20020000U 
                                                    > vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q))
                                                 ? 2U
                                                 : 
                                                (((0x40000000U 
                                                   <= vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q) 
                                                  & (0x44000000U 
                                                     > vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q))
                                                  ? 3U
                                                  : 
                                                 (((0x50000000U 
                                                    <= vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q) 
                                                   & (0x50100000U 
                                                      > vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q))
                                                   ? 4U
                                                   : 
                                                  (((0x80000000U 
                                                     <= vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q) 
                                                    & (0x80010000U 
                                                       > vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q))
                                                    ? 5U
                                                    : 6U))))) 
                                      & (- (IData)(
                                                   (0x00004000U 
                                                    <= vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q)))), Vhas_soc__ConstPool__CONST_ha8f4385c_0);
    vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16 = Vhas_soc__ConstPool__TABLE_h13faa646_0
        [__Vtemp_1];
    vlSelfRef.has_soc__DOT__m_awready = (1U & (((5U 
                                                 >= 
                                                 (7U 
                                                  & ((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16) 
                                                     >> 1U))) 
                                                && (1U 
                                                    & ((IData)(vlSelfRef.has_soc__DOT__s_awready) 
                                                       >> 
                                                       (7U 
                                                        & ((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16) 
                                                           >> 1U))))) 
                                               | (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16)));
    vlSelfRef.has_soc__DOT__m_wready = (1U & (((5U 
                                                >= 
                                                (7U 
                                                 & ((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16) 
                                                    >> 1U))) 
                                               && (1U 
                                                   & ((IData)(vlSelfRef.has_soc__DOT__s_wready) 
                                                      >> 
                                                      (7U 
                                                       & ((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16) 
                                                          >> 1U))))) 
                                              | (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16)));
    vlSelfRef.has_soc__DOT__m_arready = (1U & (((5U 
                                                 >= 
                                                 (7U 
                                                  & ((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16) 
                                                     >> 1U))) 
                                                && (1U 
                                                    & ((IData)(vlSelfRef.has_soc__DOT__s_arready) 
                                                       >> 
                                                       (7U 
                                                        & ((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16) 
                                                           >> 1U))))) 
                                               | (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16)));
    vlSelfRef.has_soc__DOT____Vcellinp__clint_inst__wvalid 
        = (IData)(((0x0aU == (0x0eU & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                   & (IData)(vlSelfRef.has_soc__DOT__m_wvalid)));
    vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__wvalid 
        = (IData)(((4U == (0x0eU & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                   & (IData)(vlSelfRef.has_soc__DOT__m_wvalid)));
    vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__wvalid 
        = (IData)(((2U == (0x0eU & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                   & (IData)(vlSelfRef.has_soc__DOT__m_wvalid)));
    vlSelfRef.has_soc__DOT__rom_inst__DOT__req_q = 
        ((IData)(vlSelfRef.reset_n) && ((0x00004000U 
                                         > vlSelfRef.has_soc__DOT__core__DOT__pc) 
                                        & (0U == (IData)(vlSelfRef.has_soc__DOT__core__DOT__state))));
    __VdfgRegularize_h6e95ff9d_0_7 = 0U;
    __VdfgRegularize_h6e95ff9d_0_26 = (0x0000f000U 
                                       & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                          & (- (IData)(
                                                       (3U 
                                                        == 
                                                        (3U 
                                                         & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))))));
    vlSelfRef.__VdfgRegularize_h6e95ff9d_0_1 = ((3U 
                                                 == 
                                                 (0x0000007fU 
                                                  & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)) 
                                                | (0x23U 
                                                   == 
                                                   (0x0000007fU 
                                                    & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)));
    vlSelfRef.has_soc__DOT__core__DOT__pc = vlSelfRef.__Vdly__has_soc__DOT__core__DOT__pc;
    has_soc__DOT__core__DOT__imm = ((0x00000040U & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                                     ? ((- (IData)(
                                                   (1U 
                                                    & (~ 
                                                       (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                        >> 4U))))) 
                                        & (((8U & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                                             ? (0x0000f000U 
                                                & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                   & (- (IData)(
                                                                (7U 
                                                                 == 
                                                                 (7U 
                                                                  & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))))))
                                             : ((4U 
                                                 & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                                                 ? __VdfgRegularize_h6e95ff9d_0_7
                                                 : 
                                                (((0x00000800U 
                                                   & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                      << 4U)) 
                                                  | (0x0000001eU 
                                                     & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                        >> 7U))) 
                                                 & (- (IData)(
                                                              (3U 
                                                               == 
                                                               (3U 
                                                                & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))))))) 
                                           & (- (IData)(
                                                        (1U 
                                                         & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                            >> 5U))))))
                                     : ((0x00000020U 
                                         & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                                         ? ((0x00000010U 
                                             & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                                             ? ((- (IData)((IData)(
                                                                   (4U 
                                                                    == 
                                                                    (0x0000000cU 
                                                                     & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))))) 
                                                & __VdfgRegularize_h6e95ff9d_0_26)
                                             : (0x0000001fU 
                                                & ((- (IData)((IData)(
                                                                      (3U 
                                                                       == 
                                                                       (0x0000000fU 
                                                                        & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))))) 
                                                   & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                      >> 7U))))
                                         : ((0x00000010U 
                                             & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                                             ? (((4U 
                                                  & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                                                  ? __VdfgRegularize_h6e95ff9d_0_26
                                                  : __VdfgRegularize_h6e95ff9d_0_7) 
                                                & (- (IData)(
                                                             (1U 
                                                              & (~ 
                                                                 (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                                  >> 3U))))))
                                             : (__VdfgRegularize_h6e95ff9d_0_7 
                                                & ((- (IData)(
                                                              (1U 
                                                               & (~ 
                                                                  (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                                   >> 3U))))) 
                                                   & (- (IData)(
                                                                (1U 
                                                                 & (~ 
                                                                    (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                                     >> 2U))))))))));
    vlSelfRef.__VdfgRegularize_h6e95ff9d_0_24 = ((IData)(vlSelfRef.has_soc__DOT__core__DOT__state) 
                                                 & ((~ (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_1)) 
                                                    & (0x73U 
                                                       != 
                                                       (0x0000007fU 
                                                        & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))));
    vlSelfRef.has_soc__DOT__data_req = (IData)(((1U 
                                                 == (IData)(vlSelfRef.has_soc__DOT__core__DOT__state)) 
                                                & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_1)));
    vlSelfRef.__VdfgRegularize_h6e95ff9d_0_15 = (vlSelfRef.has_soc__DOT__core__DOT__pc 
                                                 + has_soc__DOT__core__DOT__imm);
    vlSelfRef.has_soc__DOT__core__DOT__alu_b = (has_soc__DOT__core__DOT__imm 
                                                & (- (IData)(
                                                             ((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_1) 
                                                              | ((0x13U 
                                                                  == 
                                                                  (0x0000007fU 
                                                                   & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)) 
                                                                 | (0x67U 
                                                                    == 
                                                                    (0x0000007fU 
                                                                     & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)))))));
    vlSelfRef.has_soc__DOT__data_wstrb = (0x0000000fU 
                                          & (((0U == 
                                               (7U 
                                                & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                   >> 0x0000000cU)))
                                               ? 1U
                                               : (3U 
                                                  | (- (IData)(
                                                               (1U 
                                                                != 
                                                                (7U 
                                                                 & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                                    >> 0x0000000cU))))))) 
                                             & (- (IData)((IData)(vlSelfRef.has_soc__DOT__data_req)))));
    vlSelfRef.has_soc__DOT__m_arvalid = ((1U == (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__state)) 
                                         & ((~ (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__is_write_q)) 
                                            & (IData)(vlSelfRef.has_soc__DOT__data_req)));
    vlSelfRef.has_soc__DOT__m_awvalid = ((1U == (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__state)) 
                                         & ((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__is_write_q) 
                                            & (IData)(vlSelfRef.has_soc__DOT__data_req)));
    vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__arvalid 
        = (IData)(((4U == (0x0eU & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                   & (IData)(vlSelfRef.has_soc__DOT__m_arvalid)));
    vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__arvalid 
        = (IData)(((2U == (0x0eU & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                   & (IData)(vlSelfRef.has_soc__DOT__m_arvalid)));
    vlSelfRef.has_soc__DOT__s_rvalid = ((0x37U & (IData)(vlSelfRef.has_soc__DOT__s_rvalid)) 
                                        | ((IData)(
                                                   ((6U 
                                                     == 
                                                     (0x0eU 
                                                      & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                                                    & (IData)(vlSelfRef.has_soc__DOT__m_arvalid))) 
                                           << 3U));
    __VdfgRegularize_h6e95ff9d_0_18 = (IData)(((0x0aU 
                                                == 
                                                (0x0eU 
                                                 & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                                               & (IData)(vlSelfRef.has_soc__DOT__m_arvalid)));
    vlSelfRef.has_soc__DOT____Vcellinp__apb_bridge__s_awvalid 
        = (IData)(((8U == (0x0eU & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                   & (IData)(vlSelfRef.has_soc__DOT__m_awvalid)));
    vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__awvalid 
        = (IData)(((4U == (0x0eU & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                   & (IData)(vlSelfRef.has_soc__DOT__m_awvalid)));
    vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__awvalid 
        = (IData)(((2U == (0x0eU & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                   & (IData)(vlSelfRef.has_soc__DOT__m_awvalid)));
    vlSelfRef.__VdfgRegularize_h6e95ff9d_0_5 = (IData)(
                                                       ((0x0aU 
                                                         == 
                                                         (0x0eU 
                                                          & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                                                        & (IData)(vlSelfRef.has_soc__DOT__m_awvalid)));
    vlSelfRef.has_soc__DOT__s_rvalid = ((0x1fU & (IData)(vlSelfRef.has_soc__DOT__s_rvalid)) 
                                        | (((~ (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                >> 0x0000000cU)) 
                                            & (IData)(__VdfgRegularize_h6e95ff9d_0_18)) 
                                           << 5U));
    has_soc__DOT____Vcellinp__plic_inst__arvalid = 
        ((vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
          >> 0x0000000cU) & (IData)(__VdfgRegularize_h6e95ff9d_0_18));
    vlSelfRef.has_soc__DOT____Vcellinp__clint_inst__awvalid 
        = ((~ (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
               >> 0x0000000cU)) & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_5));
    __VdfgRegularize_h6e95ff9d_0_19 = (((((IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_5) 
                                          << 5U) | 
                                         (((IData)(vlSelfRef.has_soc__DOT____Vcellinp__apb_bridge__s_awvalid) 
                                           << 4U) | 
                                          ((IData)(
                                                   ((6U 
                                                     == 
                                                     (0x0eU 
                                                      & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                                                    & (IData)(vlSelfRef.has_soc__DOT__m_awvalid))) 
                                           << 3U))) 
                                        | (((IData)(vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__awvalid) 
                                            << 2U) 
                                           | (((IData)(vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__awvalid) 
                                               << 1U) 
                                              | (IData)(
                                                        ((0U 
                                                          == 
                                                          (0x0eU 
                                                           & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                                                         & (IData)(vlSelfRef.has_soc__DOT__m_awvalid)))))) 
                                       & ((((IData)(vlSelfRef.has_soc__DOT____Vcellinp__clint_inst__wvalid) 
                                            << 5U) 
                                           | (((IData)(
                                                       ((8U 
                                                         == 
                                                         (0x0eU 
                                                          & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                                                        & (IData)(vlSelfRef.has_soc__DOT__m_wvalid))) 
                                               << 4U) 
                                              | ((IData)(
                                                         ((6U 
                                                           == 
                                                           (0x0eU 
                                                            & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                                                          & (IData)(vlSelfRef.has_soc__DOT__m_wvalid))) 
                                                 << 3U))) 
                                          | (((IData)(vlSelfRef.has_soc__DOT____Vcellinp__sram_inst__wvalid) 
                                              << 2U) 
                                             | (((IData)(vlSelfRef.has_soc__DOT____Vcellinp__tcm_inst__wvalid) 
                                                 << 1U) 
                                                | (IData)(
                                                          ((0U 
                                                            == 
                                                            (0x0eU 
                                                             & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                                                           & (IData)(vlSelfRef.has_soc__DOT__m_wvalid)))))));
    vlSelfRef.has_soc__DOT__s_rvalid = ((0x1fU & (IData)(vlSelfRef.has_soc__DOT__s_rvalid)) 
                                        | ((IData)(has_soc__DOT____Vcellinp__plic_inst__arvalid) 
                                           << 5U));
    vlSelfRef.has_soc__DOT__s_rdata[5U] = (((0U == 
                                             (0x00003fffU 
                                              & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                 >> 2U)))
                                             ? (IData)(vlSelfRef.has_soc__DOT__plic_inst__DOT__priority0)
                                             : ((1U 
                                                 == 
                                                 (0x00003fffU 
                                                  & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                     >> 2U)))
                                                 ? (IData)(vlSelfRef.has_soc__DOT__plic_inst__DOT__priority1)
                                                 : 
                                                ((2U 
                                                  == 
                                                  (0x00003fffU 
                                                   & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                      >> 2U)))
                                                  ? (IData)(vlSelfRef.has_soc__DOT__plic_inst__DOT__priority2)
                                                  : 
                                                 ((3U 
                                                   == 
                                                   (0x00003fffU 
                                                    & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                       >> 2U)))
                                                   ? (IData)(vlSelfRef.has_soc__DOT__plic_inst__DOT__priority3)
                                                   : 
                                                  ((0x0800U 
                                                    == 
                                                    (0x00003fffU 
                                                     & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                        >> 2U)))
                                                    ? (IData)(vlSelfRef.has_soc__DOT__plic_inst__DOT__enable)
                                                    : 
                                                   ((0x0801U 
                                                     == 
                                                     (0x00003fffU 
                                                      & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                         >> 2U)))
                                                     ? (IData)(vlSelfRef.has_soc__DOT__plic_inst__DOT__threshold)
                                                     : 
                                                    ((- (IData)(
                                                                (0x0802U 
                                                                 == 
                                                                 (0x00003fffU 
                                                                  & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                                     >> 2U))))) 
                                                     & (IData)(vlSelfRef.has_soc__DOT__plic_inst__DOT__pending)))))))) 
                                           & (- (IData)((IData)(has_soc__DOT____Vcellinp__plic_inst__arvalid))));
    vlSelfRef.has_soc__DOT__s_bvalid = ((0x37U & (IData)(vlSelfRef.has_soc__DOT__s_bvalid)) 
                                        | (8U & (IData)(__VdfgRegularize_h6e95ff9d_0_19)));
    vlSelfRef.has_soc__DOT__s_bvalid = ((0x1fU & (IData)(vlSelfRef.has_soc__DOT__s_bvalid)) 
                                        | (((~ (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                                >> 0x0000000cU)) 
                                            & ((IData)(__VdfgRegularize_h6e95ff9d_0_19) 
                                               >> 5U)) 
                                           << 5U));
    vlSelfRef.has_soc__DOT__s_bvalid = ((0x1fU & (IData)(vlSelfRef.has_soc__DOT__s_bvalid)) 
                                        | (((vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                                             >> 0x0000000cU) 
                                            & ((IData)(__VdfgRegularize_h6e95ff9d_0_19) 
                                               >> 5U)) 
                                           << 5U));
}

void Vhas_soc___024root___nba_comb__TOP__0(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___nba_comb__TOP__0\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ has_soc__DOT__core__DOT__alu_cmp;
    has_soc__DOT__core__DOT__alu_cmp = 0;
    CData/*0:0*/ __VdfgRegularize_h6e95ff9d_0_11;
    __VdfgRegularize_h6e95ff9d_0_11 = 0;
    CData/*0:0*/ __VdfgRegularize_h6e95ff9d_0_12;
    __VdfgRegularize_h6e95ff9d_0_12 = 0;
    CData/*0:0*/ __VdfgRegularize_h6e95ff9d_0_13;
    __VdfgRegularize_h6e95ff9d_0_13 = 0;
    // Body
    vlSelfRef.has_soc__DOT__s_rdata[1U] = vlSelfRef.has_soc__DOT__tcm_inst__DOT__mem
        [(0x00001fffU & ((IData)(vlSelfRef.has_soc__DOT__tcm_inst__DOT__raddr_q) 
                         >> 2U))];
    vlSelfRef.has_soc__DOT__s_rdata[2U] = vlSelfRef.has_soc__DOT__sram_inst__DOT__mem
        [(0x0000ffffU & (vlSelfRef.has_soc__DOT__sram_inst__DOT__raddr_q 
                         >> 2U))];
    vlSelfRef.has_soc__DOT__core__DOT__rs1_val = ((0U 
                                                   == 
                                                   (1U 
                                                    & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                       >> 0x0000000fU)))
                                                   ? 0U
                                                   : vlSelfRef.has_soc__DOT__core__DOT__rf
                                                  [
                                                  (1U 
                                                   & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                      >> 0x0000000fU))]);
    __VdfgRegularize_h6e95ff9d_0_11 = (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                                       < vlSelfRef.has_soc__DOT__core__DOT__alu_b);
    __VdfgRegularize_h6e95ff9d_0_12 = VL_LTS_III(32, vlSelfRef.has_soc__DOT__core__DOT__rs1_val, vlSelfRef.has_soc__DOT__core__DOT__alu_b);
    __VdfgRegularize_h6e95ff9d_0_13 = ((0x00002000U 
                                        & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                                        ? ((0x00001000U 
                                            & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                                            ? (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                                               >= vlSelfRef.has_soc__DOT__core__DOT__alu_b)
                                            : (IData)(__VdfgRegularize_h6e95ff9d_0_11))
                                        : ((0x00001000U 
                                            & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                                            ? VL_GTES_III(32, vlSelfRef.has_soc__DOT__core__DOT__rs1_val, vlSelfRef.has_soc__DOT__core__DOT__alu_b)
                                            : (IData)(__VdfgRegularize_h6e95ff9d_0_12)));
    if ((0x00004000U & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)) {
        vlSelfRef.has_soc__DOT__core__DOT__alu_out 
            = ((0x00002000U & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                ? ((0x00001000U & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                    ? (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                       & vlSelfRef.has_soc__DOT__core__DOT__alu_b)
                    : (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                       | vlSelfRef.has_soc__DOT__core__DOT__alu_b))
                : ((0x00001000U & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                    ? (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                       >> (0x0000001fU & vlSelfRef.has_soc__DOT__core__DOT__alu_b))
                    : (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                       ^ vlSelfRef.has_soc__DOT__core__DOT__alu_b)));
        has_soc__DOT__core__DOT__alu_cmp = __VdfgRegularize_h6e95ff9d_0_13;
    } else {
        vlSelfRef.has_soc__DOT__core__DOT__alu_out 
            = ((0x00002000U & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                ? ((0x00001000U & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                    ? (1U & (- (IData)((IData)(__VdfgRegularize_h6e95ff9d_0_11))))
                    : (1U & (- (IData)((IData)(__VdfgRegularize_h6e95ff9d_0_12)))))
                : ((0x00001000U & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                    ? (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                       << (0x0000001fU & vlSelfRef.has_soc__DOT__core__DOT__alu_b))
                    : (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                       + vlSelfRef.has_soc__DOT__core__DOT__alu_b)));
        has_soc__DOT__core__DOT__alu_cmp = ((~ (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                >> 0x0000000dU)) 
                                            & ((0x00001000U 
                                                & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                                                ? (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                                                   != vlSelfRef.has_soc__DOT__core__DOT__alu_b)
                                                : (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                                                   == vlSelfRef.has_soc__DOT__core__DOT__alu_b)));
    }
    vlSelfRef.has_soc__DOT__core__DOT__next_pc = ((0x6fU 
                                                   == 
                                                   (0x0000007fU 
                                                    & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))
                                                   ? vlSelfRef.__VdfgRegularize_h6e95ff9d_0_15
                                                   : 
                                                  ((0x67U 
                                                    == 
                                                    (0x0000007fU 
                                                     & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))
                                                    ? 
                                                   (0xfffffffeU 
                                                    & vlSelfRef.has_soc__DOT__core__DOT__alu_out)
                                                    : 
                                                   (((0x63U 
                                                      == 
                                                      (0x0000007fU 
                                                       & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)) 
                                                     & ((0x00004000U 
                                                         & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                                                         ? (IData)(__VdfgRegularize_h6e95ff9d_0_13)
                                                         : 
                                                        ((~ 
                                                          (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                                           >> 0x0000000dU)) 
                                                         & ((0x00001000U 
                                                             & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)
                                                             ? 
                                                            (~ (IData)(has_soc__DOT__core__DOT__alu_cmp))
                                                             : (IData)(has_soc__DOT__core__DOT__alu_cmp)))))
                                                     ? vlSelfRef.__VdfgRegularize_h6e95ff9d_0_15
                                                     : 
                                                    ((IData)(4U) 
                                                     + vlSelfRef.has_soc__DOT__core__DOT__pc))));
}

void Vhas_soc___024root___nba_comb__TOP__1(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___nba_comb__TOP__1\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.has_soc__DOT__s_rdata[4U] = ((1U & (IData)(vlSelfRef.has_soc__DOT__apb_sel))
                                            ? ((0U 
                                                == 
                                                (0x000003ffU 
                                                 & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                    >> 2U)))
                                                ? (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__data_out_q)
                                                : (
                                                   (1U 
                                                    == 
                                                    (0x000003ffU 
                                                     & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                        >> 2U)))
                                                    ? (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__gpio_in_sync2)
                                                    : 
                                                   ((2U 
                                                     == 
                                                     (0x000003ffU 
                                                      & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                         >> 2U)))
                                                     ? (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe)
                                                     : 
                                                    ((3U 
                                                      == 
                                                      (0x000003ffU 
                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                          >> 2U)))
                                                      ? (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_en)
                                                      : 
                                                     ((4U 
                                                       == 
                                                       (0x000003ffU 
                                                        & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                           >> 2U)))
                                                       ? (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_rise_en)
                                                       : 
                                                      ((5U 
                                                        == 
                                                        (0x000003ffU 
                                                         & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                            >> 2U)))
                                                        ? (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_fall_en)
                                                        : 
                                                       ((- (IData)(
                                                                   (6U 
                                                                    == 
                                                                    (0x000003ffU 
                                                                     & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                        >> 2U))))) 
                                                        & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__int_pend))))))))
                                            : ((2U 
                                                & (IData)(vlSelfRef.has_soc__DOT__apb_sel))
                                                ? (
                                                   ((0U 
                                                     == 
                                                     (0x000003ffU 
                                                      & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                         >> 2U)))
                                                     ? 
                                                    ((IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__dlab)
                                                      ? 0x0000001bU
                                                      : (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__rbr))
                                                     : 
                                                    ((1U 
                                                      == 
                                                      (0x000003ffU 
                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                          >> 2U)))
                                                      ? 
                                                     ((- (IData)(
                                                                 (1U 
                                                                  & (~ (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__dlab))))) 
                                                      & (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__ier))
                                                      : 
                                                     ((2U 
                                                       == 
                                                       (0x000003ffU 
                                                        & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                           >> 2U)))
                                                       ? (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__iir)
                                                       : 
                                                      ((3U 
                                                        == 
                                                        (0x000003ffU 
                                                         & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                            >> 2U)))
                                                        ? (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__lcr)
                                                        : 
                                                       ((4U 
                                                         == 
                                                         (0x000003ffU 
                                                          & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                             >> 2U)))
                                                         ? (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__mcr)
                                                         : 
                                                        ((5U 
                                                          == 
                                                          (0x000003ffU 
                                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                              >> 2U)))
                                                          ? 
                                                         (((IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__thre) 
                                                           << 3U) 
                                                          | ((IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__rx_data_ready) 
                                                             << 1U))
                                                          : 
                                                         ((- (IData)(
                                                                     (6U 
                                                                      != 
                                                                      (0x000003ffU 
                                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                          >> 2U))))) 
                                                          & (IData)(vlSelfRef.has_soc__DOT__uart_inst__DOT__spr)))))))) 
                                                   & (- (IData)(
                                                                ((0U 
                                                                  == 
                                                                  (0x000003ffU 
                                                                   & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                      >> 2U))) 
                                                                 | ((1U 
                                                                     == 
                                                                     (0x000003ffU 
                                                                      & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                         >> 2U))) 
                                                                    | ((2U 
                                                                        == 
                                                                        (0x000003ffU 
                                                                         & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                            >> 2U))) 
                                                                       | ((3U 
                                                                           == 
                                                                           (0x000003ffU 
                                                                            & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                               >> 2U))) 
                                                                          | ((4U 
                                                                              == 
                                                                              (0x000003ffU 
                                                                               & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                                >> 2U))) 
                                                                             | ((5U 
                                                                                == 
                                                                                (0x000003ffU 
                                                                                & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                                >> 2U))) 
                                                                                | ((6U 
                                                                                == 
                                                                                (0x000003ffU 
                                                                                & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                                >> 2U))) 
                                                                                | (7U 
                                                                                == 
                                                                                (0x000003ffU 
                                                                                & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                                >> 2U)))))))))))))
                                                : (
                                                   (4U 
                                                    & (IData)(vlSelfRef.has_soc__DOT__apb_sel))
                                                    ? 
                                                   ((0U 
                                                     == 
                                                     (0x000003ffU 
                                                      & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                         >> 2U)))
                                                     ? (IData)(vlSelfRef.has_soc__DOT__i2c_inst__DOT__enable)
                                                     : 
                                                    ((1U 
                                                      == 
                                                      (0x000003ffU 
                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                          >> 2U)))
                                                      ? (IData)(vlSelfRef.has_soc__DOT__i2c_inst__DOT__slave_addr)
                                                      : 
                                                     ((2U 
                                                       == 
                                                       (0x000003ffU 
                                                        & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                           >> 2U)))
                                                       ? (IData)(vlSelfRef.has_soc__DOT__i2c_inst__DOT__rx_data)
                                                       : 
                                                      ((- (IData)(
                                                                  (4U 
                                                                   == 
                                                                   (0x000003ffU 
                                                                    & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                       >> 2U))))) 
                                                       & (((IData)(vlSelfRef.has_soc__DOT__i2c_inst__DOT__ack_received) 
                                                           << 3U) 
                                                          | ((IData)(vlSelfRef.has_soc__DOT__i2c_inst__DOT__busy) 
                                                             << 1U))))))
                                                    : 
                                                   ((8U 
                                                     & (IData)(vlSelfRef.has_soc__DOT__apb_sel))
                                                     ? 
                                                    ((0U 
                                                      == 
                                                      (0x000003ffU 
                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                          >> 2U)))
                                                      ? (IData)(vlSelfRef.has_soc__DOT__spi_inst__DOT__enable)
                                                      : 
                                                     ((1U 
                                                       == 
                                                       (0x000003ffU 
                                                        & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                           >> 2U)))
                                                       ? (IData)(vlSelfRef.has_soc__DOT__spi_inst__DOT__rx_data)
                                                       : 
                                                      ((- (IData)(
                                                                  (3U 
                                                                   == 
                                                                   (0x000003ffU 
                                                                    & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                       >> 2U))))) 
                                                       & (IData)(vlSelfRef.has_soc__DOT__spi_inst__DOT__busy))))
                                                     : 
                                                    ((0x00000010U 
                                                      & (IData)(vlSelfRef.has_soc__DOT__apb_sel))
                                                      ? 
                                                     ((- (IData)(
                                                                 ((~ (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans)) 
                                                                  & (2U 
                                                                     == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state))))) 
                                                      & ((8U 
                                                          == 
                                                          (0x000003ffU 
                                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                              >> 2U)))
                                                          ? (IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__enable)
                                                          : 
                                                         ((IData)(vlSelfRef.has_soc__DOT__pwm_inst__DOT__unnamedblk1__DOT__reg_sel)
                                                           ? vlSelfRef.has_soc__DOT__pwm_inst__DOT__duty
                                                          [vlSelfRef.has_soc__DOT__pwm_inst__DOT__unnamedblk1__DOT__ch_idx]
                                                           : vlSelfRef.has_soc__DOT__pwm_inst__DOT__period
                                                          [vlSelfRef.has_soc__DOT__pwm_inst__DOT__unnamedblk1__DOT__ch_idx])))
                                                      : 
                                                     ((0x00000020U 
                                                       & (IData)(vlSelfRef.has_soc__DOT__apb_sel))
                                                       ? 
                                                      ((0U 
                                                        == 
                                                        (0x000003ffU 
                                                         & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                            >> 2U)))
                                                        ? vlSelfRef.has_soc__DOT__timer_inst__DOT__count
                                                        : 
                                                       ((1U 
                                                         == 
                                                         (0x000003ffU 
                                                          & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                             >> 2U)))
                                                         ? vlSelfRef.has_soc__DOT__timer_inst__DOT__compare
                                                         : 
                                                        ((2U 
                                                          == 
                                                          (0x000003ffU 
                                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                              >> 2U)))
                                                          ? 
                                                         (((IData)(vlSelfRef.has_soc__DOT__timer_inst__DOT__int_en) 
                                                           << 1U) 
                                                          | (IData)(vlSelfRef.has_soc__DOT__timer_inst__DOT__enable))
                                                          : 
                                                         ((- (IData)(
                                                                     (3U 
                                                                      == 
                                                                      (0x000003ffU 
                                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                          >> 2U))))) 
                                                          & (IData)(vlSelfRef.has_soc__DOT__timer_inst__DOT__match_pend)))))
                                                       : 
                                                      ((0x00000040U 
                                                        & (IData)(vlSelfRef.has_soc__DOT__apb_sel))
                                                        ? 
                                                       ((0U 
                                                         == 
                                                         (0x000003ffU 
                                                          & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                             >> 2U)))
                                                         ? vlSelfRef.has_soc__DOT__wdog_inst__DOT__load
                                                         : 
                                                        ((1U 
                                                          == 
                                                          (0x000003ffU 
                                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                              >> 2U)))
                                                          ? (IData)(vlSelfRef.has_soc__DOT__wdog_inst__DOT__enable)
                                                          : 
                                                         ((- (IData)(
                                                                     (2U 
                                                                      == 
                                                                      (0x000003ffU 
                                                                       & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                          >> 2U))))) 
                                                          & (IData)(vlSelfRef.has_soc__DOT__wdog_inst__DOT__expired))))
                                                        : 
                                                       ((0x00000080U 
                                                         & (IData)(vlSelfRef.has_soc__DOT__apb_sel))
                                                         ? 
                                                        ((0U 
                                                          == 
                                                          (0x000003ffU 
                                                           & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                              >> 2U)))
                                                          ? (IData)(vlSelfRef.has_soc__DOT__i2s_inst__DOT__enable)
                                                          : 
                                                         (1U 
                                                          & (- (IData)(
                                                                       (2U 
                                                                        == 
                                                                        (0x000003ffU 
                                                                         & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                            >> 2U)))))))
                                                         : 
                                                        (((0U 
                                                           == 
                                                           (0x000003ffU 
                                                            & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                               >> 2U)))
                                                           ? (IData)(vlSelfRef.has_soc__DOT__pwrmgr_inst__DOT__sleep_req)
                                                           : 
                                                          ((1U 
                                                            == 
                                                            (0x000003ffU 
                                                             & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                >> 2U)))
                                                            ? (IData)(vlSelfRef.has_soc__DOT__pwrmgr_inst__DOT__in_sleep)
                                                            : 
                                                           ((- (IData)(
                                                                       (2U 
                                                                        == 
                                                                        (0x000003ffU 
                                                                         & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                                                            >> 2U))))) 
                                                            & (IData)(vlSelfRef.has_soc__DOT__pwrmgr_inst__DOT__wake_en)))) 
                                                         & (- (IData)(
                                                                      (1U 
                                                                       & ((IData)(vlSelfRef.has_soc__DOT__apb_sel) 
                                                                          >> 8U)))))))))))));
}

extern const VlUnpacked<CData/*3:0*/, 32> Vhas_soc__ConstPool__TABLE_h03fb470c_0;

void Vhas_soc___024root___eval_body__nba(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_body__nba\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((0x0000000000000018ULL & vlSelfRef.__VnbaTriggered[0U])) {
        Vhas_soc___024root___nba_sequent__TOP__0(vlSelf);
    }
    if ((3ULL & vlSelfRef.__VnbaTriggered[0U])) {
        Vhas_soc___024root___nba_sequent__TOP__1(vlSelf);
    }
    if ((6ULL & vlSelfRef.__VnbaTriggered[0U])) {
        {
            // Inlined CFunc: _nba_sequent__TOP__2
            CData/*3:0*/ __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__state;
            __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__state = 0;
            IData/*31:0*/ __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__dr;
            __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__dr = 0;
            IData/*31:0*/ __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__ir;
            __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__ir = 0;
            __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__state 
                = vlSelfRef.has_soc__DOT__jtag_inst__DOT__state;
            __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__dr 
                = vlSelfRef.has_soc__DOT__jtag_inst__DOT__dr;
            __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__ir 
                = vlSelfRef.has_soc__DOT__jtag_inst__DOT__ir;
            if (vlSelfRef.reset_n) {
                vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state 
                    = ((0U != (IData)(vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state))
                        ? (((IData)(vlSelfRef.wake_ack)
                             ? 2U : (IData)(vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state)) 
                           & (- (IData)((1U == (IData)(vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state)))))
                        : (IData)(vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state));
                if (vlSelfRef.has_soc__DOT__jtag_inst__DOT__tck_rise) {
                    __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__state 
                        = Vhas_soc__ConstPool__TABLE_h03fb470c_0
                        [(((IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__state) 
                           << 1U) | (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__tms_sync))];
                    if ((3U == (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__state))) {
                        __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__dr = 1U;
                    } else if ((4U == (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__state))) {
                        __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__dr 
                            = (((IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__tdi_sync) 
                                << 0x0000001fU) | (vlSelfRef.has_soc__DOT__jtag_inst__DOT__dr 
                                                   >> 1U));
                    }
                    if ((3U != (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__state))) {
                        if ((4U != (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__state))) {
                            if ((8U != (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__state))) {
                                if ((0x0aU == (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__state))) {
                                    __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__ir = 1U;
                                } else if ((0x0bU == (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__state))) {
                                    __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__ir 
                                        = (((IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__tdi_sync) 
                                            << 0x0000001fU) 
                                           | (vlSelfRef.has_soc__DOT__jtag_inst__DOT__ir 
                                              >> 1U));
                                }
                            }
                        }
                        if ((4U == (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__state))) {
                            vlSelfRef.jtag_tdo = (1U 
                                                  & vlSelfRef.has_soc__DOT__jtag_inst__DOT__dr);
                        } else if ((8U != (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__state))) {
                            if ((0x0aU != (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__state))) {
                                if ((0x0bU == (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__state))) {
                                    vlSelfRef.jtag_tdo 
                                        = (1U & vlSelfRef.has_soc__DOT__jtag_inst__DOT__ir);
                                }
                            }
                        }
                    }
                }
            } else {
                vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state = 0U;
                __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__state = 0U;
                __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__dr = 0U;
                __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__ir = 0U;
                vlSelfRef.jtag_tdo = 0U;
            }
            vlSelfRef.has_soc__DOT__jtag_inst__DOT__tck_sync2 
                = ((IData)(vlSelfRef.reset_n) && (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__tck_sync1));
            vlSelfRef.has_soc__DOT__jtag_inst__DOT__dr 
                = __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__dr;
            vlSelfRef.has_soc__DOT__jtag_inst__DOT__ir 
                = __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__ir;
            vlSelfRef.has_soc__DOT__jtag_inst__DOT__state 
                = __Vinline_0__nba_sequent__TOP__2___Vdly__has_soc__DOT__jtag_inst__DOT__state;
            vlSelfRef.wake_req = ((0U != (IData)(vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state)) 
                                  & ((IData)(vlSelfRef.wake_ack) 
                                     & (1U == (IData)(vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state))));
            vlSelfRef.has_soc__DOT__core_clk = ((IData)(vlSelfRef.clk) 
                                                & (1U 
                                                   != (IData)(vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state)));
            vlSelfRef.has_soc__DOT__jtag_inst__DOT__tms_sync 
                = ((IData)(vlSelfRef.reset_n) && (IData)(vlSelfRef.jtag_tms));
            vlSelfRef.has_soc__DOT__jtag_inst__DOT__tdi_sync 
                = ((IData)(vlSelfRef.reset_n) && (IData)(vlSelfRef.jtag_tdi));
            vlSelfRef.has_soc__DOT__jtag_inst__DOT__tck_sync1 
                = ((IData)(vlSelfRef.reset_n) && (IData)(vlSelfRef.jtag_tck));
            vlSelfRef.has_soc__DOT__pclk = vlSelfRef.has_soc__DOT__core_clk;
            vlSelfRef.i2s_bclk = vlSelfRef.has_soc__DOT__pclk;
            vlSelfRef.has_soc__DOT__jtag_inst__DOT__tck_rise 
                = ((~ (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__tck_sync2)) 
                   & (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__tck_sync1));
        }
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered[0U])) {
        Vhas_soc___024root___nba_sequent__TOP__3(vlSelf);
    }
    if ((0x0000000000000018ULL & vlSelfRef.__VnbaTriggered[0U])) {
        Vhas_soc___024root___nba_sequent__TOP__4(vlSelf);
    }
    if ((3ULL & vlSelfRef.__VnbaTriggered[0U])) {
        Vhas_soc___024root___nba_sequent__TOP__5(vlSelf);
    }
    if ((3ULL & vlSelfRef.__VnbaTriggered[0U])) {
        Vhas_soc___024root___nba_comb__TOP__0(vlSelf);
    }
    if ((0x000000000000001bULL & vlSelfRef.__VnbaTriggered[0U])) {
        Vhas_soc___024root___nba_comb__TOP__1(vlSelf);
    }
}

void Vhas_soc___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___trigger_orInto__act_vec_vec\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((0U >= n));
}

void Vhas_soc___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

#ifdef VL_DEBUG
void Vhas_soc___024root___eval_debug_assertions(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_debug_assertions\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(((vlSelfRef.clk & 0xfeU)))) {
        Verilated::overWidthError("clk");
    }
    if (VL_UNLIKELY(((vlSelfRef.reset_n & 0xfeU)))) {
        Verilated::overWidthError("reset_n");
    }
    if (VL_UNLIKELY(((vlSelfRef.jtag_tck & 0xfeU)))) {
        Verilated::overWidthError("jtag_tck");
    }
    if (VL_UNLIKELY(((vlSelfRef.jtag_tms & 0xfeU)))) {
        Verilated::overWidthError("jtag_tms");
    }
    if (VL_UNLIKELY(((vlSelfRef.jtag_tdi & 0xfeU)))) {
        Verilated::overWidthError("jtag_tdi");
    }
    if (VL_UNLIKELY(((vlSelfRef.jtag_trst_n & 0xfeU)))) {
        Verilated::overWidthError("jtag_trst_n");
    }
    if (VL_UNLIKELY(((vlSelfRef.uart_rx & 0xfeU)))) {
        Verilated::overWidthError("uart_rx");
    }
    if (VL_UNLIKELY(((vlSelfRef.spi_miso & 0xfeU)))) {
        Verilated::overWidthError("spi_miso");
    }
    if (VL_UNLIKELY(((vlSelfRef.i2c_scl & 0xfeU)))) {
        Verilated::overWidthError("i2c_scl");
    }
    if (VL_UNLIKELY(((vlSelfRef.i2c_sda & 0xfeU)))) {
        Verilated::overWidthError("i2c_sda");
    }
    if (VL_UNLIKELY(((vlSelfRef.i2s_din & 0xfeU)))) {
        Verilated::overWidthError("i2s_din");
    }
    if (VL_UNLIKELY(((vlSelfRef.qspi_io & 0xf0U)))) {
        Verilated::overWidthError("qspi_io");
    }
    if (VL_UNLIKELY(((vlSelfRef.wake_ack & 0xfeU)))) {
        Verilated::overWidthError("wake_ack");
    }
}
#endif  // VL_DEBUG
