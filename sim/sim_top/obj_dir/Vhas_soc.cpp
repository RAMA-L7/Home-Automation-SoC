// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vhas_soc__pch.h"

//============================================================
// Constructors

Vhas_soc::Vhas_soc(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vhas_soc__Syms(contextp(), _vcname__, this)}
    , m_evalLoop{*this, /*convergeLimit:*/ 10000}
    , clk{vlSymsp->TOP.clk}
    , reset_n{vlSymsp->TOP.reset_n}
    , jtag_tck{vlSymsp->TOP.jtag_tck}
    , jtag_tms{vlSymsp->TOP.jtag_tms}
    , jtag_tdi{vlSymsp->TOP.jtag_tdi}
    , jtag_tdo{vlSymsp->TOP.jtag_tdo}
    , jtag_trst_n{vlSymsp->TOP.jtag_trst_n}
    , uart_tx{vlSymsp->TOP.uart_tx}
    , uart_rx{vlSymsp->TOP.uart_rx}
    , spi_sck{vlSymsp->TOP.spi_sck}
    , spi_mosi{vlSymsp->TOP.spi_mosi}
    , spi_miso{vlSymsp->TOP.spi_miso}
    , spi_cs_n{vlSymsp->TOP.spi_cs_n}
    , i2c_scl{vlSymsp->TOP.i2c_scl}
    , i2c_sda{vlSymsp->TOP.i2c_sda}
    , pwm_out{vlSymsp->TOP.pwm_out}
    , i2s_bclk{vlSymsp->TOP.i2s_bclk}
    , i2s_lrclk{vlSymsp->TOP.i2s_lrclk}
    , i2s_dout{vlSymsp->TOP.i2s_dout}
    , i2s_din{vlSymsp->TOP.i2s_din}
    , qspi_sck{vlSymsp->TOP.qspi_sck}
    , qspi_cs_n{vlSymsp->TOP.qspi_cs_n}
    , qspi_io{vlSymsp->TOP.qspi_io}
    , wdog_reset_n_out{vlSymsp->TOP.wdog_reset_n_out}
    , wake_req{vlSymsp->TOP.wake_req}
    , wake_ack{vlSymsp->TOP.wake_ack}
    , gpio{vlSymsp->TOP.gpio}
    , ext_irq{vlSymsp->TOP.ext_irq}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vhas_soc::Vhas_soc(const char* _vcname__)
    : Vhas_soc(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vhas_soc::~Vhas_soc() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vhas_soc___024root___eval_debug_assertions(Vhas_soc___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD void Vhas_soc___024root___eval_static(Vhas_soc___024root* vlSelf);
VL_ATTR_COLD void Vhas_soc___024root___eval_initial(Vhas_soc___024root* vlSelf);
VL_ATTR_COLD bool Vhas_soc___024root___eval_stl(Vhas_soc___024root* vlSelf, CData/*0:0*/ firstIteration);
void Vhas_soc___024root___eval_sample(Vhas_soc___024root* vlSelf);
bool Vhas_soc___024root___eval_ico(Vhas_soc___024root* vlSelf, CData/*0:0*/ firstIteration);
bool Vhas_soc___024root___eval_act(Vhas_soc___024root* vlSelf);
bool Vhas_soc___024root___eval_inact(Vhas_soc___024root* vlSelf);
bool Vhas_soc___024root___eval_nba(Vhas_soc___024root* vlSelf);
bool Vhas_soc___024root___eval_obs(Vhas_soc___024root* vlSelf);
bool Vhas_soc___024root___eval_react(Vhas_soc___024root* vlSelf);
void Vhas_soc___024root___eval_postponed(Vhas_soc___024root* vlSelf);
VL_ATTR_COLD void Vhas_soc___024root___eval_final(Vhas_soc___024root* vlSelf);
VL_ATTR_COLD void Vhas_soc___024root___eval_dump_triggers__stl(Vhas_soc___024root* vlSelf);
VL_ATTR_COLD void Vhas_soc___024root___eval_dump_triggers__ico(Vhas_soc___024root* vlSelf);
VL_ATTR_COLD void Vhas_soc___024root___eval_dump_triggers__act(Vhas_soc___024root* vlSelf);
VL_ATTR_COLD void Vhas_soc___024root___eval_dump_triggers__nba(Vhas_soc___024root* vlSelf);
VL_ATTR_COLD void Vhas_soc___024root___eval_dump_triggers__obs(Vhas_soc___024root* vlSelf);
VL_ATTR_COLD void Vhas_soc___024root___eval_dump_triggers__react(Vhas_soc___024root* vlSelf);

void Vhas_soc::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vhas_soc::eval_step\n"); );
    m_evalLoop.eval();
}

void Vhas_soc::evalBegin() {
#ifdef VL_DEBUG
    // Debug assertions
    Vhas_soc___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
}

void Vhas_soc::evalEnd() {
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

void Vhas_soc::evalStatic() {
    Vhas_soc___024root___eval_static(&(vlSymsp->TOP));
}

void Vhas_soc::evalInitial() {
    Vhas_soc___024root___eval_initial(&(vlSymsp->TOP));
}

bool Vhas_soc::evalStl(bool firstIteration) {
    return Vhas_soc___024root___eval_stl(&(vlSymsp->TOP), firstIteration);
}

void Vhas_soc::evalSample() {
    Vhas_soc___024root___eval_sample(&(vlSymsp->TOP));
}

bool Vhas_soc::evalIco(bool firstIteration) {
    return Vhas_soc___024root___eval_ico(&(vlSymsp->TOP), firstIteration);
}

bool Vhas_soc::evalAct() {
    return Vhas_soc___024root___eval_act(&(vlSymsp->TOP));
}

bool Vhas_soc::evalInact() {
    return Vhas_soc___024root___eval_inact(&(vlSymsp->TOP));
}

bool Vhas_soc::evalNba() {
    return Vhas_soc___024root___eval_nba(&(vlSymsp->TOP));
}

bool Vhas_soc::evalObs() {
    return Vhas_soc___024root___eval_obs(&(vlSymsp->TOP));
}

bool Vhas_soc::evalReact() {
    return Vhas_soc___024root___eval_react(&(vlSymsp->TOP));
}

void Vhas_soc::evalPostponed() {
    Vhas_soc___024root___eval_postponed(&(vlSymsp->TOP));
}

void Vhas_soc::evalFinal() {
    Vhas_soc___024root___eval_final(&(vlSymsp->TOP));
}

VL_ATTR_COLD void Vhas_soc::dumpTriggersStl() {
    Vhas_soc___024root___eval_dump_triggers__stl(&(vlSymsp->TOP));
}

VL_ATTR_COLD void Vhas_soc::dumpTriggersIco() {
    Vhas_soc___024root___eval_dump_triggers__ico(&(vlSymsp->TOP));
}

VL_ATTR_COLD void Vhas_soc::dumpTriggersAct() {
    Vhas_soc___024root___eval_dump_triggers__act(&(vlSymsp->TOP));
}

VL_ATTR_COLD void Vhas_soc::dumpTriggersNba() {
    Vhas_soc___024root___eval_dump_triggers__nba(&(vlSymsp->TOP));
}

VL_ATTR_COLD void Vhas_soc::dumpTriggersObs() {
    Vhas_soc___024root___eval_dump_triggers__obs(&(vlSymsp->TOP));
}

VL_ATTR_COLD void Vhas_soc::dumpTriggersReact() {
    Vhas_soc___024root___eval_dump_triggers__react(&(vlSymsp->TOP));
}

//============================================================
// Events and timing
bool Vhas_soc::eventsPending() { return false; }

uint64_t Vhas_soc::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vhas_soc::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

VL_ATTR_COLD void Vhas_soc::final() {
    contextp()->executingFinal(true);
    evalFinal();
    contextp()->executingFinal(false);
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vhas_soc::hierName() const { return vlSymsp->name(); }
const char* Vhas_soc::modelName() const { return "Vhas_soc"; }
unsigned Vhas_soc::threads() const { return 1; }
void Vhas_soc::prepareClone() const { contextp()->prepareClone(); }
void Vhas_soc::atClone() const {
    contextp()->threadPoolpOnClone();
}
