// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vhas_soc.h for the primary calling header

#include "Vhas_soc__pch.h"

VL_ATTR_COLD void Vhas_soc___024root___eval_static(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_static\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    {
        // Inlined CFunc: _eval_static__TOP
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__unnamedblk1__DOT__ch_idx 
            = (3U & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                     >> 3U));
        vlSelfRef.has_soc__DOT__pwm_inst__DOT__unnamedblk1__DOT__reg_sel 
            = (1U & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                     >> 2U));
        vlSelfRef.has_soc__DOT__apb_bridge__DOT__aw_fire 
            = ((IData)(vlSelfRef.has_soc__DOT____Vcellinp__apb_bridge__s_awvalid) 
               & (0U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)));
        vlSelfRef.has_soc__DOT__apb_bridge__DOT__ar_fire 
            = (IData)((((8U == (0x0eU & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_16))) 
                        & (IData)(vlSelfRef.has_soc__DOT__m_arvalid)) 
                       & (0U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state))));
        vlSelfRef.has_soc__DOT__sram_inst__DOT__unnamedblk1__DOT__word_idx 
            = (0x0000ffffU & (vlSelfRef.has_soc__DOT__sram_inst__DOT__waddr_q 
                              >> 2U));
        vlSelfRef.has_soc__DOT__tcm_inst__DOT__unnamedblk1__DOT__word_idx 
            = (0x00001fffU & ((IData)(vlSelfRef.has_soc__DOT__tcm_inst__DOT__waddr_q) 
                              >> 2U));
        vlSelfRef.has_soc__DOT__data_adapter__DOT__aw_fire 
            = ((IData)(vlSelfRef.has_soc__DOT__m_awvalid) 
               & (IData)(vlSelfRef.has_soc__DOT__m_awready));
        vlSelfRef.has_soc__DOT__data_adapter__DOT__w_fire 
            = ((IData)(vlSelfRef.has_soc__DOT__m_wvalid) 
               & (IData)(vlSelfRef.has_soc__DOT__m_wready));
        vlSelfRef.has_soc__DOT__data_adapter__DOT__ar_fire 
            = ((IData)(vlSelfRef.has_soc__DOT__m_arvalid) 
               & (IData)(vlSelfRef.has_soc__DOT__m_arready));
        vlSelfRef.has_soc__DOT__data_adapter__DOT__r_fire 
            = (((IData)(vlSelfRef.has_soc__DOT__axi_ic__DOT__r_decode_err) 
                | ((5U >= (IData)(vlSelfRef.has_soc__DOT__axi_ic__DOT__r_src)) 
                   && (1U & ((IData)(vlSelfRef.has_soc__DOT__s_rvalid) 
                             >> (IData)(vlSelfRef.has_soc__DOT__axi_ic__DOT__r_src))))) 
               & ((~ (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__is_write_q)) 
                  & (3U == (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__state))));
        vlSelfRef.has_soc__DOT__data_adapter__DOT__b_fire 
            = (((IData)(vlSelfRef.has_soc__DOT__axi_ic__DOT__b_decode_err) 
                | ((5U >= (IData)(vlSelfRef.has_soc__DOT__axi_ic__DOT__b_src)) 
                   && (1U & ((IData)(vlSelfRef.has_soc__DOT__s_bvalid) 
                             >> (IData)(vlSelfRef.has_soc__DOT__axi_ic__DOT__b_src))))) 
               & ((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__is_write_q) 
                  & (3U == (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__state))));
    }
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
    vlSelfRef.__Vtrigprevexpr___TOP__has_soc__DOT__core_clk__0 
        = vlSelfRef.has_soc__DOT__core_clk;
    vlSelfRef.__Vtrigprevexpr___TOP__reset_n__1 = vlSelfRef.reset_n;
    vlSelfRef.__Vtrigprevexpr___TOP__clk__1 = vlSelfRef.clk;
    vlSelfRef.__Vtrigprevexpr___TOP__has_soc__DOT__pclk__0 
        = vlSelfRef.has_soc__DOT__pclk;
    vlSelfRef.__Vtrigprevexpr___TOP__has_soc__DOT__presetn__0 
        = vlSelfRef.has_soc__DOT__presetn;
}

VL_ATTR_COLD void Vhas_soc___024root___eval_initial(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_initial\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    {
        // Inlined CFunc: _eval_initial__TOP
        IData/*31:0*/ __Vinline_0__eval_initial__TOP_has_soc__DOT__rom_inst__DOT__unnamedblk1__DOT__i;
        __Vinline_0__eval_initial__TOP_has_soc__DOT__rom_inst__DOT__unnamedblk1__DOT__i = 0;
        vlSelfRef.has_soc__DOT__s_awready = (1U | (IData)(vlSelfRef.has_soc__DOT__s_awready));
        vlSelfRef.has_soc__DOT__s_wready = (1U | (IData)(vlSelfRef.has_soc__DOT__s_wready));
        vlSelfRef.has_soc__DOT__s_bvalid = (0x3eU & (IData)(vlSelfRef.has_soc__DOT__s_bvalid));
        vlSelfRef.has_soc__DOT__s_arready = (0x3eU 
                                             & (IData)(vlSelfRef.has_soc__DOT__s_arready));
        vlSelfRef.has_soc__DOT__s_rvalid = (0x3eU & (IData)(vlSelfRef.has_soc__DOT__s_rvalid));
        vlSelfRef.has_soc__DOT__s_rdata[0U] = 0U;
        vlSelfRef.has_soc__DOT__s_arready = (8U | (IData)(vlSelfRef.has_soc__DOT__s_arready));
        vlSelfRef.has_soc__DOT__s_wready = (8U | (IData)(vlSelfRef.has_soc__DOT__s_wready));
        vlSelfRef.has_soc__DOT__s_awready = (8U | (IData)(vlSelfRef.has_soc__DOT__s_awready));
        vlSelfRef.has_soc__DOT__s_arready = (0x00000020U 
                                             | (IData)(vlSelfRef.has_soc__DOT__s_arready));
        vlSelfRef.has_soc__DOT__s_wready = (0x00000020U 
                                            | (IData)(vlSelfRef.has_soc__DOT__s_wready));
        vlSelfRef.has_soc__DOT__s_awready = (0x00000020U 
                                             | (IData)(vlSelfRef.has_soc__DOT__s_awready));
        vlSelfRef.has_soc__DOT__s_arready = (0x00000020U 
                                             | (IData)(vlSelfRef.has_soc__DOT__s_arready));
        vlSelfRef.has_soc__DOT__s_wready = (0x00000020U 
                                            | (IData)(vlSelfRef.has_soc__DOT__s_wready));
        vlSelfRef.has_soc__DOT__s_awready = (0x00000020U 
                                             | (IData)(vlSelfRef.has_soc__DOT__s_awready));
        vlSelfRef.i2c_scl = 0U;
        vlSelfRef.i2c_sda = 0U;
        vlSelfRef.qspi_io = 0U;
        vlSelfRef.i2s_lrclk = 0U;
        vlSelfRef.qspi_sck = 0U;
        vlSelfRef.qspi_cs_n = 1U;
        vlSelfRef.has_soc__DOT__rom_inst__DOT__mem[0U] = 0x0010006fU;
        vlSelfRef.has_soc__DOT__rom_inst__DOT__mem[1U] = 0x00000013U;
        __Vinline_0__eval_initial__TOP_has_soc__DOT__rom_inst__DOT__unnamedblk1__DOT__i = 2U;
        while (VL_GTS_III(32, 0x00004000U, __Vinline_0__eval_initial__TOP_has_soc__DOT__rom_inst__DOT__unnamedblk1__DOT__i)) {
            vlSelfRef.has_soc__DOT__rom_inst__DOT__mem[(0x00003fffU 
                                                        & __Vinline_0__eval_initial__TOP_has_soc__DOT__rom_inst__DOT__unnamedblk1__DOT__i)] = 0x00000013U;
            __Vinline_0__eval_initial__TOP_has_soc__DOT__rom_inst__DOT__unnamedblk1__DOT__i 
                = ((IData)(1U) + __Vinline_0__eval_initial__TOP_has_soc__DOT__rom_inst__DOT__unnamedblk1__DOT__i);
        }
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vhas_soc___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vhas_soc___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in);
VL_ATTR_COLD void Vhas_soc___024root___stl_sequent__TOP__0(Vhas_soc___024root* vlSelf);

VL_ATTR_COLD bool Vhas_soc___024root___eval_stl(Vhas_soc___024root* vlSelf, CData/*0:0*/ firstIteration) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_stl\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VstlExecute;
    // Body
    vlSelfRef.__VstlTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VstlTriggered[0U]) 
                                     | (IData)((IData)(firstIteration)));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vhas_soc___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
    }
#endif
    __VstlExecute = Vhas_soc___024root___trigger_anySet__stl(vlSelfRef.__VstlTriggered);
    if (__VstlExecute) {
        {
            // Inlined CFunc: _eval_body__stl
            if ((1ULL & vlSelfRef.__VstlTriggered[0U])) {
                Vhas_soc___024root___stl_sequent__TOP__0(vlSelf);
            }
        }
    }
    return (__VstlExecute);
}

VL_ATTR_COLD void Vhas_soc___024root___eval_dump_triggers__stl(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_dump_triggers__stl\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    Vhas_soc___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vhas_soc___024root___dump_triggers__ico(const VlUnpacked<QData/*63:0*/, 2> &triggers, const std::string &tag);
#endif  // VL_DEBUG

VL_ATTR_COLD void Vhas_soc___024root___eval_dump_triggers__ico(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_dump_triggers__ico\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    Vhas_soc___024root___dump_triggers__ico(vlSelfRef.__VicoTriggered, "ico"s);
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vhas_soc___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

VL_ATTR_COLD void Vhas_soc___024root___eval_dump_triggers__act(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_dump_triggers__act\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    Vhas_soc___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
}

VL_ATTR_COLD void Vhas_soc___024root___eval_dump_triggers__nba(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_dump_triggers__nba\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    Vhas_soc___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
}

VL_ATTR_COLD void Vhas_soc___024root___eval_dump_triggers__obs(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_dump_triggers__obs\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vhas_soc___024root___eval_dump_triggers__react(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_dump_triggers__react\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vhas_soc___024root___eval_final(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___eval_final\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vhas_soc___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(Vhas_soc___024root___trigger_anySet__stl(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD bool Vhas_soc___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___trigger_anySet__stl\n"); );
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

extern const VlWide<1024>/*32767:0*/ Vhas_soc__ConstPool__CONST_hfe1b4521_0;
extern const VlWide<14>/*447:0*/ Vhas_soc__ConstPool__CONST_ha8f4385c_0;
extern const VlUnpacked<CData/*3:0*/, 7> Vhas_soc__ConstPool__TABLE_h13faa646_0;

VL_ATTR_COLD void Vhas_soc___024root___stl_sequent__TOP__0(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___stl_sequent__TOP__0\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ has_soc__DOT____Vcellinp__plic_inst__arvalid;
    has_soc__DOT____Vcellinp__plic_inst__arvalid = 0;
    IData/*31:0*/ has_soc__DOT__core__DOT__imm;
    has_soc__DOT__core__DOT__imm = 0;
    CData/*0:0*/ has_soc__DOT__core__DOT__alu_cmp;
    has_soc__DOT__core__DOT__alu_cmp = 0;
    VlUnpacked<CData/*7:0*/, 4> has_soc__DOT__plic_inst__DOT__priority_arr;
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        has_soc__DOT__plic_inst__DOT__priority_arr[__Vi0] = 0;
    }
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
    SData/*15:0*/ __VdfgRegularize_h6e95ff9d_0_0;
    __VdfgRegularize_h6e95ff9d_0_0 = 0;
    IData/*31:0*/ __VdfgRegularize_h6e95ff9d_0_7;
    __VdfgRegularize_h6e95ff9d_0_7 = 0;
    CData/*0:0*/ __VdfgRegularize_h6e95ff9d_0_9;
    __VdfgRegularize_h6e95ff9d_0_9 = 0;
    CData/*0:0*/ __VdfgRegularize_h6e95ff9d_0_11;
    __VdfgRegularize_h6e95ff9d_0_11 = 0;
    CData/*0:0*/ __VdfgRegularize_h6e95ff9d_0_12;
    __VdfgRegularize_h6e95ff9d_0_12 = 0;
    CData/*0:0*/ __VdfgRegularize_h6e95ff9d_0_13;
    __VdfgRegularize_h6e95ff9d_0_13 = 0;
    CData/*0:0*/ __VdfgRegularize_h6e95ff9d_0_18;
    __VdfgRegularize_h6e95ff9d_0_18 = 0;
    CData/*5:0*/ __VdfgRegularize_h6e95ff9d_0_19;
    __VdfgRegularize_h6e95ff9d_0_19 = 0;
    IData/*31:0*/ __VdfgRegularize_h6e95ff9d_0_26;
    __VdfgRegularize_h6e95ff9d_0_26 = 0;
    IData/*31:0*/ __Vtemp_1;
    // Body
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
    vlSelfRef.wdog_reset_n_out = (1U & (~ (IData)(vlSelfRef.has_soc__DOT__wdog_inst__DOT__expired)));
    vlSelfRef.has_soc__DOT__presetn = vlSelfRef.reset_n;
    vlSelfRef.wake_req = ((0U != (IData)(vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state)) 
                          & ((IData)(vlSelfRef.wake_ack) 
                             & (1U == (IData)(vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state))));
    vlSelfRef.spi_mosi = ((IData)(vlSelfRef.has_soc__DOT__spi_inst__DOT__enable) 
                          & ((IData)(vlSelfRef.has_soc__DOT__spi_inst__DOT__tx_data) 
                             >> 7U));
    vlSelfRef.i2s_dout = ((IData)(vlSelfRef.has_soc__DOT__i2s_inst__DOT__enable) 
                          & ((IData)(vlSelfRef.has_soc__DOT__i2s_inst__DOT__tx_sample) 
                             >> 0x0000000fU));
    vlSelfRef.has_soc__DOT__jtag_inst__DOT__tck_rise 
        = ((~ (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__tck_sync2)) 
           & (IData)(vlSelfRef.has_soc__DOT__jtag_inst__DOT__tck_sync1));
    vlSelfRef.__VdfgRegularize_h6e95ff9d_0_2 = ((IData)(vlSelfRef.has_soc__DOT__data_gnt) 
                                                & (IData)(vlSelfRef.has_soc__DOT__data_rvalid));
    has_soc__DOT__plic_inst__DOT__priority_arr[0U] 
        = vlSelfRef.has_soc__DOT__plic_inst__DOT__priority0;
    has_soc__DOT__plic_inst__DOT__priority_arr[1U] 
        = vlSelfRef.has_soc__DOT__plic_inst__DOT__priority1;
    has_soc__DOT__plic_inst__DOT__priority_arr[2U] 
        = vlSelfRef.has_soc__DOT__plic_inst__DOT__priority2;
    has_soc__DOT__plic_inst__DOT__priority_arr[3U] 
        = vlSelfRef.has_soc__DOT__plic_inst__DOT__priority3;
    vlSelfRef.spi_sck = (1U & (~ (IData)(vlSelfRef.has_soc__DOT__spi_inst__DOT__enable)));
    vlSelfRef.has_soc__DOT__s_rvalid = ((0x3dU & (IData)(vlSelfRef.has_soc__DOT__s_rvalid)) 
                                        | ((IData)(vlSelfRef.has_soc__DOT__tcm_inst__DOT__read_d) 
                                           << 1U));
    vlSelfRef.has_soc__DOT__s_bvalid = ((0x3dU & (IData)(vlSelfRef.has_soc__DOT__s_bvalid)) 
                                        | ((IData)(vlSelfRef.has_soc__DOT__tcm_inst__DOT__write_d) 
                                           << 1U));
    vlSelfRef.has_soc__DOT__s_rvalid = ((0x3bU & (IData)(vlSelfRef.has_soc__DOT__s_rvalid)) 
                                        | ((IData)(vlSelfRef.has_soc__DOT__sram_inst__DOT__read_d) 
                                           << 2U));
    vlSelfRef.has_soc__DOT__s_bvalid = ((0x3bU & (IData)(vlSelfRef.has_soc__DOT__s_bvalid)) 
                                        | ((IData)(vlSelfRef.has_soc__DOT__sram_inst__DOT__write_d) 
                                           << 2U));
    vlSelfRef.has_soc__DOT__s_rdata[1U] = vlSelfRef.has_soc__DOT__tcm_inst__DOT__mem
        [(0x00001fffU & ((IData)(vlSelfRef.has_soc__DOT__tcm_inst__DOT__raddr_q) 
                         >> 2U))];
    vlSelfRef.has_soc__DOT__s_arready = ((0x3dU & (IData)(vlSelfRef.has_soc__DOT__s_arready)) 
                                         | ((IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__arready) 
                                            << 1U));
    vlSelfRef.has_soc__DOT__s_wready = ((0x3dU & (IData)(vlSelfRef.has_soc__DOT__s_wready)) 
                                        | ((IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__wready) 
                                           << 1U));
    vlSelfRef.has_soc__DOT__s_awready = ((0x3dU & (IData)(vlSelfRef.has_soc__DOT__s_awready)) 
                                         | ((IData)(vlSelfRef.has_soc__DOT____Vcellout__tcm_inst__awready) 
                                            << 1U));
    vlSelfRef.has_soc__DOT__s_rdata[2U] = vlSelfRef.has_soc__DOT__sram_inst__DOT__mem
        [(0x0000ffffU & (vlSelfRef.has_soc__DOT__sram_inst__DOT__raddr_q 
                         >> 2U))];
    vlSelfRef.has_soc__DOT__s_arready = ((0x3bU & (IData)(vlSelfRef.has_soc__DOT__s_arready)) 
                                         | ((IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__arready) 
                                            << 2U));
    vlSelfRef.has_soc__DOT__s_wready = ((0x3bU & (IData)(vlSelfRef.has_soc__DOT__s_wready)) 
                                        | ((IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__wready) 
                                           << 2U));
    vlSelfRef.has_soc__DOT__s_awready = ((0x3bU & (IData)(vlSelfRef.has_soc__DOT__s_awready)) 
                                         | ((IData)(vlSelfRef.has_soc__DOT____Vcellout__sram_inst__awready) 
                                            << 2U));
    vlSelfRef.has_soc__DOT__s_rdata[3U] = vlSelfRef.has_soc__DOT__qspi_ctrl__DOT__flash_mem
        [(0x000003ffU & (vlSelfRef.has_soc__DOT__data_adapter__DOT__addr_q 
                         >> 2U))];
    vlSelfRef.has_soc__DOT__s_arready = ((0x2fU & (IData)(vlSelfRef.has_soc__DOT__s_arready)) 
                                         | ((0U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
                                            << 4U));
    vlSelfRef.has_soc__DOT__s_wready = ((0x2fU & (IData)(vlSelfRef.has_soc__DOT__s_wready)) 
                                        | ((0U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
                                           << 4U));
    vlSelfRef.has_soc__DOT__s_awready = ((0x2fU & (IData)(vlSelfRef.has_soc__DOT__s_awready)) 
                                         | ((0U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)) 
                                            << 4U));
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
    vlSelfRef.has_soc__DOT__core_clk = ((IData)(vlSelfRef.clk) 
                                        & (1U != (IData)(vlSelfRef.has_soc__DOT__pwr_mgr__DOT__state)));
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
    vlSelfRef.has_soc__DOT__apb_sel = (0x000003ffU 
                                       & Vhas_soc__ConstPool__CONST_hfe1b4521_0
                                       [(0x000003ffU 
                                         & (vlSelfRef.has_soc__DOT__apb_bridge__DOT__trans_addr 
                                            >> 2U))]);
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
    vlSelfRef.has_soc__DOT__m_wvalid = ((IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__is_write_q) 
                                        & (2U == (IData)(vlSelfRef.has_soc__DOT__data_adapter__DOT__state)));
    __VdfgRegularize_h6e95ff9d_0_7 = 0U;
    __VdfgRegularize_h6e95ff9d_0_26 = (0x0000f000U 
                                       & (vlSelfRef.has_soc__DOT__core__DOT__fetch_instr 
                                          & (- (IData)(
                                                       (3U 
                                                        == 
                                                        (3U 
                                                         & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))))));
    __VdfgRegularize_h6e95ff9d_0_0 = ((IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__oe) 
                                      & (IData)(vlSelfRef.has_soc__DOT__gpio_inst__DOT__data_out_q));
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
    vlSelfRef.__VdfgRegularize_h6e95ff9d_0_1 = ((3U 
                                                 == 
                                                 (0x0000007fU 
                                                  & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)) 
                                                | (0x23U 
                                                   == 
                                                   (0x0000007fU 
                                                    & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr)));
    vlSelfRef.spi_cs_n = vlSelfRef.spi_sck;
    vlSelfRef.has_soc__DOT__pclk = vlSelfRef.has_soc__DOT__core_clk;
    __VdfgRegularize_h6e95ff9d_0_9 = ((0U != (IData)(vlSelfRef.has_soc__DOT__apb_sel)) 
                                      & (2U == (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__state)));
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
    vlSelfRef.__VdfgRegularize_h6e95ff9d_0_24 = ((IData)(vlSelfRef.has_soc__DOT__core__DOT__state) 
                                                 & ((~ (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_1)) 
                                                    & (0x73U 
                                                       != 
                                                       (0x0000007fU 
                                                        & vlSelfRef.has_soc__DOT__core__DOT__fetch_instr))));
    vlSelfRef.has_soc__DOT__data_req = (IData)(((1U 
                                                 == (IData)(vlSelfRef.has_soc__DOT__core__DOT__state)) 
                                                & (IData)(vlSelfRef.__VdfgRegularize_h6e95ff9d_0_1)));
    vlSelfRef.i2s_bclk = vlSelfRef.has_soc__DOT__pclk;
    vlSelfRef.has_soc__DOT__s_rvalid = ((0x2fU & (IData)(vlSelfRef.has_soc__DOT__s_rvalid)) 
                                        | (((~ (IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans)) 
                                            & (IData)(__VdfgRegularize_h6e95ff9d_0_9)) 
                                           << 4U));
    vlSelfRef.has_soc__DOT__s_bvalid = ((0x2fU & (IData)(vlSelfRef.has_soc__DOT__s_bvalid)) 
                                        | (((IData)(vlSelfRef.has_soc__DOT__apb_bridge__DOT__wr_trans) 
                                            & (IData)(__VdfgRegularize_h6e95ff9d_0_9)) 
                                           << 4U));
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
    __VdfgRegularize_h6e95ff9d_0_11 = (vlSelfRef.has_soc__DOT__core__DOT__rs1_val 
                                       < vlSelfRef.has_soc__DOT__core__DOT__alu_b);
    __VdfgRegularize_h6e95ff9d_0_12 = VL_LTS_III(32, vlSelfRef.has_soc__DOT__core__DOT__rs1_val, vlSelfRef.has_soc__DOT__core__DOT__alu_b);
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

bool Vhas_soc___024root___trigger_anySet__ico(const VlUnpacked<QData/*63:0*/, 2> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vhas_soc___024root___dump_triggers__ico(const VlUnpacked<QData/*63:0*/, 2> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___dump_triggers__ico\n"); );
    // Body
    if ((1U & (~ (IData)(Vhas_soc___024root___trigger_anySet__ico(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @( clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @( reset_n)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 2U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 2 is active: @( jtag_tck)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 3U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 3 is active: @( jtag_tms)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 4U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 4 is active: @( jtag_tdi)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 5U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 5 is active: @( jtag_trst_n)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 6U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 6 is active: @( ext_irq)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 7U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 7 is active: @( uart_rx)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 8U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 8 is active: @( spi_miso)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 9U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 9 is active: @( i2s_din)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 0x0000000aU)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 10 is active: @( wake_ack)\n");
    }
    if ((1U & (IData)(triggers[1U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 64 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

bool Vhas_soc___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vhas_soc___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(Vhas_soc___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge has_soc.core_clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @(negedge reset_n)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 2U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 2 is active: @(posedge clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 3U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 3 is active: @(posedge has_soc.pclk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 4U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 4 is active: @(negedge has_soc.presetn)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vhas_soc___024root___ctor_var_reset(Vhas_soc___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhas_soc___024root___ctor_var_reset\n"); );
    Vhas_soc__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->clk = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16707436170211756652ull);
    vlSelf->reset_n = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14129604614540204776ull);
    vlSelf->jtag_tck = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10500983681776930247ull);
    vlSelf->jtag_tms = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16224335879666074583ull);
    vlSelf->jtag_tdi = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5289790260552907825ull);
    vlSelf->jtag_tdo = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 293125711922884863ull);
    vlSelf->jtag_trst_n = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7909924195223090299ull);
    vlSelf->ext_irq = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17156595761613661369ull);
    vlSelf->uart_tx = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1761512799854230840ull);
    vlSelf->uart_rx = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2399467654730215438ull);
    vlSelf->spi_sck = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7598659639805510901ull);
    vlSelf->spi_mosi = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 852284730959930751ull);
    vlSelf->spi_miso = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12140560756394917646ull);
    vlSelf->spi_cs_n = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5466454749172535206ull);
    vlSelf->i2c_scl = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12803641497217470577ull);
    vlSelf->i2c_sda = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10535531422985904959ull);
    vlSelf->gpio = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 14831338748372935636ull);
    vlSelf->pwm_out = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 17193619615457380819ull);
    vlSelf->i2s_bclk = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4984582466163917203ull);
    vlSelf->i2s_lrclk = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 116247492118875813ull);
    vlSelf->i2s_dout = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14525765118510705802ull);
    vlSelf->i2s_din = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12677483783963981359ull);
    vlSelf->qspi_sck = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4916472880189591759ull);
    vlSelf->qspi_cs_n = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2870108039950035310ull);
    vlSelf->qspi_io = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 13041632200081595583ull);
    vlSelf->wdog_reset_n_out = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13189871002203104909ull);
    vlSelf->wake_req = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7916502253499355122ull);
    vlSelf->wake_ack = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10047965811302743252ull);
    vlSelf->has_soc__DOT__core_clk = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7441674365462022772ull);
    vlSelf->has_soc__DOT__data_req = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2438584949111503833ull);
    vlSelf->has_soc__DOT__data_gnt = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12495564185965951632ull);
    vlSelf->has_soc__DOT__data_rvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17019540467243531998ull);
    vlSelf->has_soc__DOT__data_rdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14672538071012189166ull);
    vlSelf->has_soc__DOT__data_wstrb = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 15086809193125040202ull);
    vlSelf->has_soc__DOT__m_awvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13433547917981448542ull);
    vlSelf->has_soc__DOT__m_awready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4047671469730183955ull);
    vlSelf->has_soc__DOT__m_wvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9829480519054030969ull);
    vlSelf->has_soc__DOT__m_wready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5763899741667715513ull);
    vlSelf->has_soc__DOT__m_arvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9207989655587261644ull);
    vlSelf->has_soc__DOT__m_arready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17298734714765506201ull);
    vlSelf->has_soc__DOT__s_awready = VL_SCOPED_RAND_RESET_I(6, __VscopeHash, 143798632493935716ull);
    vlSelf->has_soc__DOT__s_wready = VL_SCOPED_RAND_RESET_I(6, __VscopeHash, 6073565106823008065ull);
    vlSelf->has_soc__DOT__s_bvalid = VL_SCOPED_RAND_RESET_I(6, __VscopeHash, 8503625246365227781ull);
    vlSelf->has_soc__DOT__s_arready = VL_SCOPED_RAND_RESET_I(6, __VscopeHash, 696297866175244699ull);
    vlSelf->has_soc__DOT__s_rvalid = VL_SCOPED_RAND_RESET_I(6, __VscopeHash, 17740317053051755859ull);
    for (int __Vi0 = 0; __Vi0 < 6; ++__Vi0) {
        vlSelf->has_soc__DOT__s_rdata[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 13017963738682523466ull);
    }
    vlSelf->has_soc__DOT__pclk = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12948013756831116377ull);
    vlSelf->has_soc__DOT__presetn = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2549800455244068984ull);
    vlSelf->has_soc__DOT____Vcellout__tcm_inst__arready = 0;
    vlSelf->has_soc__DOT____Vcellinp__tcm_inst__arvalid = 0;
    vlSelf->has_soc__DOT____Vcellout__tcm_inst__wready = 0;
    vlSelf->has_soc__DOT____Vcellinp__tcm_inst__wvalid = 0;
    vlSelf->has_soc__DOT____Vcellout__tcm_inst__awready = 0;
    vlSelf->has_soc__DOT____Vcellinp__tcm_inst__awvalid = 0;
    vlSelf->has_soc__DOT____Vcellout__sram_inst__arready = 0;
    vlSelf->has_soc__DOT____Vcellinp__sram_inst__arvalid = 0;
    vlSelf->has_soc__DOT____Vcellout__sram_inst__wready = 0;
    vlSelf->has_soc__DOT____Vcellinp__sram_inst__wvalid = 0;
    vlSelf->has_soc__DOT____Vcellout__sram_inst__awready = 0;
    vlSelf->has_soc__DOT____Vcellinp__sram_inst__awvalid = 0;
    vlSelf->has_soc__DOT____Vcellinp__apb_bridge__s_awvalid = 0;
    vlSelf->has_soc__DOT____Vcellinp__clint_inst__wvalid = 0;
    vlSelf->has_soc__DOT____Vcellinp__clint_inst__awvalid = 0;
    vlSelf->has_soc__DOT__apb_sel = VL_SCOPED_RAND_RESET_I(10, __VscopeHash, 15524593784208974699ull);
    vlSelf->has_soc__DOT__core__DOT__pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10106933122049171281ull);
    vlSelf->has_soc__DOT__core__DOT__fetch_instr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 633706052903714094ull);
    vlSelf->has_soc__DOT__core__DOT__fetch_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7427661575117931598ull);
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->has_soc__DOT__core__DOT__rf[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3055632219547923052ull);
    }
    vlSelf->has_soc__DOT__core__DOT__rs1_val = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16508003520101177506ull);
    vlSelf->has_soc__DOT__core__DOT__alu_b = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11959168652414694204ull);
    vlSelf->has_soc__DOT__core__DOT__alu_out = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2579835019270421902ull);
    vlSelf->has_soc__DOT__core__DOT__csr_mcycle = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15450044315620568011ull);
    vlSelf->has_soc__DOT__core__DOT__csr_minstret = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1667043122951975508ull);
    vlSelf->has_soc__DOT__core__DOT__state = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 16292159913833553980ull);
    vlSelf->has_soc__DOT__core__DOT__next_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17489400226457572405ull);
    vlSelf->has_soc__DOT__jtag_inst__DOT__tck_sync1 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2029411849644723279ull);
    vlSelf->has_soc__DOT__jtag_inst__DOT__tck_sync2 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1681258442627455923ull);
    vlSelf->has_soc__DOT__jtag_inst__DOT__tms_sync = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16355157927558585820ull);
    vlSelf->has_soc__DOT__jtag_inst__DOT__tdi_sync = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7134652832170759149ull);
    vlSelf->has_soc__DOT__jtag_inst__DOT__tck_rise = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8413902807999384323ull);
    vlSelf->has_soc__DOT__jtag_inst__DOT__state = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 5288787897080970363ull);
    vlSelf->has_soc__DOT__jtag_inst__DOT__dr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1024388930869763310ull);
    vlSelf->has_soc__DOT__jtag_inst__DOT__ir = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16802149382047904542ull);
    vlSelf->has_soc__DOT__pwrmgr_inst__DOT__sleep_req = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16950296042828239375ull);
    vlSelf->has_soc__DOT__pwrmgr_inst__DOT__wake_en = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6148621932306471360ull);
    vlSelf->has_soc__DOT__pwrmgr_inst__DOT__in_sleep = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2546249180408986864ull);
    vlSelf->has_soc__DOT__i2s_inst__DOT__enable = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2149922630185477730ull);
    vlSelf->has_soc__DOT__i2s_inst__DOT__tx_sample = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 10061246200354291659ull);
    vlSelf->has_soc__DOT__wdog_inst__DOT__load = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7120088723991189298ull);
    vlSelf->has_soc__DOT__wdog_inst__DOT__count = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10310247038151470016ull);
    vlSelf->has_soc__DOT__wdog_inst__DOT__enable = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5161960183394493905ull);
    vlSelf->has_soc__DOT__wdog_inst__DOT__expired = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6303962454254732133ull);
    vlSelf->has_soc__DOT__timer_inst__DOT__count = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7025442672445541578ull);
    vlSelf->has_soc__DOT__timer_inst__DOT__compare = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7566297666099137198ull);
    vlSelf->has_soc__DOT__timer_inst__DOT__enable = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9936906202931361254ull);
    vlSelf->has_soc__DOT__timer_inst__DOT__int_en = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6522763894562333625ull);
    vlSelf->has_soc__DOT__timer_inst__DOT__match_pend = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13358185431505719852ull);
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->has_soc__DOT__pwm_inst__DOT__period[__Vi0] = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 2053775671025540063ull);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->has_soc__DOT__pwm_inst__DOT__duty[__Vi0] = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 15118927344809320703ull);
    }
    for (int __Vi0 = 0; __Vi0 < 4; ++__Vi0) {
        vlSelf->has_soc__DOT__pwm_inst__DOT__counter[__Vi0] = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 6007307867226388755ull);
    }
    vlSelf->has_soc__DOT__pwm_inst__DOT__enable = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 16645915710821114453ull);
    vlSelf->has_soc__DOT__spi_inst__DOT__enable = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1136140159010114547ull);
    vlSelf->has_soc__DOT__spi_inst__DOT__tx_data = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 17922382141491571540ull);
    vlSelf->has_soc__DOT__spi_inst__DOT__rx_data = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 2379543342968733623ull);
    vlSelf->has_soc__DOT__spi_inst__DOT__busy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3662331430014804102ull);
    vlSelf->has_soc__DOT__i2c_inst__DOT__enable = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8893019460778316760ull);
    vlSelf->has_soc__DOT__i2c_inst__DOT__slave_addr = VL_SCOPED_RAND_RESET_I(7, __VscopeHash, 6264564721506375698ull);
    vlSelf->has_soc__DOT__i2c_inst__DOT__rx_data = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 16139270452217782117ull);
    vlSelf->has_soc__DOT__i2c_inst__DOT__busy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6683147069562477174ull);
    vlSelf->has_soc__DOT__i2c_inst__DOT__ack_received = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10003901027025216081ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__thr = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 14804192544067395060ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__rbr = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 16137265743948110253ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__ier = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 17957177486369046388ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__iir = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 5495786608109571931ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__lcr = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 18276727432384558606ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__mcr = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 3318007389891694811ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__spr = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 5563871918780704801ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__dlab = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11828881760411109008ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__baud_cnt = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 938169597003121662ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__tx_busy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9494874760527861527ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__tx_shift = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 2362095198857742581ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__tx_bits = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 8406141590322521789ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__rx_shift = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 2857743953805528723ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__rx_bits = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 2076182526764228637ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__rx_data_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14815756777510484703ull);
    vlSelf->has_soc__DOT__uart_inst__DOT__thre = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3258082170685754069ull);
    vlSelf->has_soc__DOT__gpio_inst__DOT__data_out_q = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 14308294412494318886ull);
    vlSelf->has_soc__DOT__gpio_inst__DOT__oe = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 12018871721391542290ull);
    vlSelf->has_soc__DOT__gpio_inst__DOT__int_en = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 4686458846780137109ull);
    vlSelf->has_soc__DOT__gpio_inst__DOT__int_rise_en = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 1455694891078645696ull);
    vlSelf->has_soc__DOT__gpio_inst__DOT__int_fall_en = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 10591284254839155360ull);
    vlSelf->has_soc__DOT__gpio_inst__DOT__int_pend = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 13756850444185867612ull);
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio_in_sync1 = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 847225910733374564ull);
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio_in_sync2 = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 10351913837135013159ull);
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio_in_prev = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 1618046409784018955ull);
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out0 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out1 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out2 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out3 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out4 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out5 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out6 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out7 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out8 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out9 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out10 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out11 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out12 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out13 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out14 = 0;
    vlSelf->has_soc__DOT__gpio_inst__DOT__gpio__out__strong__out15 = 0;
    vlSelf->has_soc__DOT__plic_inst__DOT__priority0 = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 2206788268617520898ull);
    vlSelf->has_soc__DOT__plic_inst__DOT__priority1 = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 13559497061124061078ull);
    vlSelf->has_soc__DOT__plic_inst__DOT__priority2 = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 1310247560267319637ull);
    vlSelf->has_soc__DOT__plic_inst__DOT__priority3 = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 4700428352092171529ull);
    vlSelf->has_soc__DOT__plic_inst__DOT__enable = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 3072558313462693980ull);
    vlSelf->has_soc__DOT__plic_inst__DOT__threshold = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 13818296563727284467ull);
    vlSelf->has_soc__DOT__plic_inst__DOT__pending = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 9067362539394815466ull);
    vlSelf->has_soc__DOT__clint_inst__DOT__msip = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3072609463132925412ull);
    vlSelf->has_soc__DOT__clint_inst__DOT__mtime = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 13715831273407369052ull);
    vlSelf->has_soc__DOT__apb_bridge__DOT__state = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 13260416599285655349ull);
    vlSelf->has_soc__DOT__apb_bridge__DOT__wr_trans = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10196390632764298920ull);
    vlSelf->has_soc__DOT__apb_bridge__DOT__trans_addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5276823387025364916ull);
    vlSelf->has_soc__DOT__apb_bridge__DOT__trans_wdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16954396805288266312ull);
    for (int __Vi0 = 0; __Vi0 < 1024; ++__Vi0) {
        vlSelf->has_soc__DOT__qspi_ctrl__DOT__flash_mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1597235800605125448ull);
    }
    vlSelf->has_soc__DOT__qspi_ctrl__DOT__unnamedblk1__DOT__i = 0;
    for (int __Vi0 = 0; __Vi0 < 65536; ++__Vi0) {
        vlSelf->has_soc__DOT__sram_inst__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17809988819897242278ull);
    }
    vlSelf->has_soc__DOT__sram_inst__DOT__waddr_q = VL_SCOPED_RAND_RESET_I(18, __VscopeHash, 5337158753382852453ull);
    vlSelf->has_soc__DOT__sram_inst__DOT__wdata_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9356923052817065887ull);
    vlSelf->has_soc__DOT__sram_inst__DOT__wstrb_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 11544533743601187345ull);
    vlSelf->has_soc__DOT__sram_inst__DOT__write_d = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3139493674973845002ull);
    vlSelf->has_soc__DOT__sram_inst__DOT__raddr_q = VL_SCOPED_RAND_RESET_I(18, __VscopeHash, 11961035913504783360ull);
    vlSelf->has_soc__DOT__sram_inst__DOT__read_d = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17060289914022016176ull);
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->has_soc__DOT__tcm_inst__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15723355759377317183ull);
    }
    vlSelf->has_soc__DOT__tcm_inst__DOT__waddr_q = VL_SCOPED_RAND_RESET_I(15, __VscopeHash, 16473396567543161366ull);
    vlSelf->has_soc__DOT__tcm_inst__DOT__wdata_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17889515736507937678ull);
    vlSelf->has_soc__DOT__tcm_inst__DOT__wstrb_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 17216799024569154994ull);
    vlSelf->has_soc__DOT__tcm_inst__DOT__write_d = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5228536078420015312ull);
    vlSelf->has_soc__DOT__tcm_inst__DOT__raddr_q = VL_SCOPED_RAND_RESET_I(15, __VscopeHash, 4526006055822644678ull);
    vlSelf->has_soc__DOT__tcm_inst__DOT__read_d = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14549627780082707838ull);
    vlSelf->has_soc__DOT__axi_ic__DOT__b_src = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 15755886309923979568ull);
    vlSelf->has_soc__DOT__axi_ic__DOT__b_decode_err = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12227330082873275053ull);
    vlSelf->has_soc__DOT__axi_ic__DOT__r_src = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 8270922791829120583ull);
    vlSelf->has_soc__DOT__axi_ic__DOT__r_decode_err = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4758805922217107779ull);
    for (int __Vi0 = 0; __Vi0 < 16384; ++__Vi0) {
        vlSelf->has_soc__DOT__rom_inst__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9579003077244142351ull);
    }
    vlSelf->has_soc__DOT__rom_inst__DOT__req_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9961595057161297544ull);
    vlSelf->has_soc__DOT__rom_inst__DOT__addr_q = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 2166446155996329361ull);
    vlSelf->has_soc__DOT__data_adapter__DOT__state = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 15719144766572125341ull);
    vlSelf->has_soc__DOT__data_adapter__DOT__is_write_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2963894564917484531ull);
    vlSelf->has_soc__DOT__data_adapter__DOT__addr_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11672535133462892947ull);
    vlSelf->has_soc__DOT__pwr_mgr__DOT__state = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 9925433191031835269ull);
    vlSelf->__Vfunc_addr_region__11__a = 0;
    vlSelf->__Vfunc_addr_region__12__a = 0;
    vlSelf->__Vfunc_addr_region__13__a = 0;
    vlSelf->__Vfunc_addr_region__14__a = 0;
    vlSelf->__Vfunc_addr_region__15__a = 0;
    vlSelf->__Vfunc_addr_region__16__a = 0;
    vlSelf->__Vfunc_addr_region__17__a = 0;
    vlSelf->__Vfunc_addr_region__25__a = 0;
    vlSelf->__Vfunc_addr_region__26__a = 0;
    vlSelf->__Vfunc_addr_region__27__a = 0;
    vlSelf->__Vfunc_addr_region__28__a = 0;
    vlSelf->__Vfunc_addr_region__29__a = 0;
    vlSelf->__Vfunc_addr_region__30__a = 0;
    vlSelf->__Vfunc_addr_region__31__a = 0;
    vlSelf->__VdfgRegularize_h6e95ff9d_0_1 = 0;
    vlSelf->__VdfgRegularize_h6e95ff9d_0_2 = 0;
    vlSelf->__VdfgRegularize_h6e95ff9d_0_5 = 0;
    vlSelf->__VdfgRegularize_h6e95ff9d_0_15 = 0;
    vlSelf->__VdfgRegularize_h6e95ff9d_0_16 = 0;
    vlSelf->__VdfgRegularize_h6e95ff9d_0_24 = 0;
    vlSelf->__Vdly__has_soc__DOT__core__DOT__pc = 0;
    vlSelf->__Vdly__has_soc__DOT____Vcellout__sram_inst__awready = 0;
    vlSelf->__Vdly__has_soc__DOT____Vcellout__sram_inst__wready = 0;
    vlSelf->__Vdly__has_soc__DOT____Vcellout__tcm_inst__awready = 0;
    vlSelf->__Vdly__has_soc__DOT____Vcellout__tcm_inst__wready = 0;
    vlSelf->__Vdly__has_soc__DOT__data_adapter__DOT__state = 0;
    vlSelf->__Vdly__has_soc__DOT__wdog_inst__DOT__count = 0;
    vlSelf->__Vdly__has_soc__DOT__timer_inst__DOT__count = 0;
    vlSelf->__Vdly__has_soc__DOT__timer_inst__DOT__match_pend = 0;
    vlSelf->__Vdly__has_soc__DOT__gpio_inst__DOT__int_pend = 0;
    vlSelf->__Vdly__has_soc__DOT__apb_bridge__DOT__state = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VstlTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->__VicoTriggered[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__reset_n__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__jtag_tck__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__jtag_tms__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__jtag_tdi__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__jtag_trst_n__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__ext_irq__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__uart_rx__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__spi_miso__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__i2s_din__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__wake_ack__0 = 0;
    vlSelf->__VicoDidInit = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__has_soc__DOT__core_clk__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__reset_n__1 = 0;
    vlSelf->__Vtrigprevexpr___TOP__clk__1 = 0;
    vlSelf->__Vtrigprevexpr___TOP__has_soc__DOT__pclk__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__has_soc__DOT__presetn__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
}
