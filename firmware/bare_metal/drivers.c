/*------------------------------------------------------------------------------
 * Home-Automation-SoC — Peripheral Drivers
 * Stage 3 Firmware
 *----------------------------------------------------------------------------*/

#include "drivers.h"

/* GPIO register offsets */
#define REG_GPIO_DATA_OUT   (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define REG_GPIO_DATA_IN    (*(volatile uint32_t *)(GPIO_BASE + 0x04))
#define REG_GPIO_OE         (*(volatile uint32_t *)(GPIO_BASE + 0x08))

void gpio_set_mode(uint32_t pin, uint32_t output)
{
    if (output)
        REG_GPIO_OE |= (1u << pin);
    else
        REG_GPIO_OE &= ~(1u << pin);
}

void gpio_write(uint32_t pin, uint32_t val)
{
    if (val)
        REG_GPIO_DATA_OUT |= (1u << pin);
    else
        REG_GPIO_DATA_OUT &= ~(1u << pin);
}

uint32_t gpio_read(uint32_t pin)
{
    return (REG_GPIO_DATA_IN >> pin) & 1u;
}

/* UART register offsets */
#define REG_UART_THR   (*(volatile uint32_t *)(UART_BASE + 0x00))
#define REG_UART_RBR   (*(volatile uint32_t *)(UART_BASE + 0x00))
#define REG_UART_IER   (*(volatile uint32_t *)(UART_BASE + 0x04))
#define REG_UART_LCR   (*(volatile uint32_t *)(UART_BASE + 0x0C))
#define REG_UART_LSR   (*(volatile uint32_t *)(UART_BASE + 0x14))

void uart_init(void)
{
    REG_UART_LCR = 0x03;   /* 8N1 */
    REG_UART_IER = 0x00;   /* polling */
}

void uart_putc(char c)
{
    while (!(REG_UART_LSR & 0x20))
        ;
    REG_UART_THR = (uint32_t)c;
}

char uart_getc(void)
{
    while (!(REG_UART_LSR & 0x01))
        ;
    return (char)(REG_UART_RBR & 0xFF);
}

void uart_puts(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

/* Timer */
#define REG_TIMER_COUNT   (*(volatile uint32_t *)(TIMER_BASE + 0x00))
#define REG_TIMER_COMPARE (*(volatile uint32_t *)(TIMER_BASE + 0x04))
#define REG_TIMER_CTRL    (*(volatile uint32_t *)(TIMER_BASE + 0x08))

void timer_init(uint32_t compare_val)
{
    REG_TIMER_COMPARE = compare_val;
}

void timer_enable(void)
{
    REG_TIMER_CTRL = 0x03;   /* enable + int enable */
}

void timer_disable(void)
{
    REG_TIMER_CTRL = 0x00;
}

/* Watchdog */
#define REG_WDOG_LOAD  (*(volatile uint32_t *)(WDOG_BASE + 0x00))
#define REG_WDOG_CTRL  (*(volatile uint32_t *)(WDOG_BASE + 0x04))

void wdog_init(uint32_t load_val)
{
    REG_WDOG_LOAD = load_val;
    REG_WDOG_CTRL = 0x01;
}

void wdog_kick(void)
{
    REG_WDOG_LOAD = 1000000u;
}

/* Power management */
#define REG_PM_CTRL  (*(volatile uint32_t *)(PWRMGR_BASE + 0x00))

void pm_sleep_request(void)
{
    REG_PM_CTRL |= 0x01;
}

void pm_wake_enable(void)
{
    REG_PM_CTRL |= 0x04;   /* bit 2: wake enable */
}

void uart_print_hex(uint32_t v)
{
    int i;
    uart_puts("0x");
    for (i = 28; i >= 0; i -= 4) {
        char c = "0123456789ABCDEF"[(v >> i) & 0xF];
        uart_putc(c);
    }
}
