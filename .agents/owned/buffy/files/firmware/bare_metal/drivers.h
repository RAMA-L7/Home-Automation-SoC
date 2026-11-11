/*------------------------------------------------------------------------------
 * Home-Automation-SoC — Driver Header
 * Stage 3 Firmware
 *----------------------------------------------------------------------------*/

#ifndef DRIVERS_H
#define DRIVERS_H

#include <stdint.h>

/* Peripheral base addresses */
#define GPIO_BASE  0x50000000
#define UART_BASE  0x50001000
#define I2C_BASE   0x50002000
#define SPI_BASE   0x50003000
#define PWM_BASE   0x50004000
#define TIMER_BASE 0x50005000
#define WDOG_BASE  0x50006000
#define I2S_BASE   0x50007000
#define PWRMGR_BASE 0x50008000

/* GPIO registers */
#define REG_GPIO_DATA_OUT   (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define REG_GPIO_DATA_IN    (*(volatile uint32_t *)(GPIO_BASE + 0x04))
#define REG_GPIO_OE         (*(volatile uint32_t *)(GPIO_BASE + 0x08))
#define REG_GPIO_INT_EN     (*(volatile uint32_t *)(GPIO_BASE + 0x0C))
#define REG_GPIO_INT_RISE   (*(volatile uint32_t *)(GPIO_BASE + 0x10))
#define REG_GPIO_INT_FALL   (*(volatile uint32_t *)(GPIO_BASE + 0x14))
#define REG_GPIO_INT_PEND   (*(volatile uint32_t *)(GPIO_BASE + 0x18))

/* UART registers */
#define REG_UART_THR   (*(volatile uint32_t *)(UART_BASE + 0x00))
#define REG_UART_RBR   (*(volatile uint32_t *)(UART_BASE + 0x00))
#define REG_UART_IER   (*(volatile uint32_t *)(UART_BASE + 0x04))
#define REG_UART_LCR   (*(volatile uint32_t *)(UART_BASE + 0x0C))
#define REG_UART_LSR   (*(volatile uint32_t *)(UART_BASE + 0x14))

/* Timer registers */
#define REG_TIMER_COUNT   (*(volatile uint32_t *)(TIMER_BASE + 0x00))
#define REG_TIMER_COMPARE (*(volatile uint32_t *)(TIMER_BASE + 0x04))
#define REG_TIMER_CTRL    (*(volatile uint32_t *)(TIMER_BASE + 0x08))

/* Watchdog registers */
#define REG_WDOG_LOAD  (*(volatile uint32_t *)(WDOG_BASE + 0x00))
#define REG_WDOG_CTRL  (*(volatile uint32_t *)(WDOG_BASE + 0x04))

/* Power manager registers */
#define REG_PM_CTRL  (*(volatile uint32_t *)(PWRMGR_BASE + 0x00))

/* GPIO */
void gpio_set_mode(uint32_t pin, uint32_t output);
void gpio_write(uint32_t pin, uint32_t val);
uint32_t gpio_read(uint32_t pin);

/* UART */
void uart_init(void);
void uart_putc(char c);
char uart_getc(void);
void uart_puts(const char *s);
void uart_print_hex(uint32_t v);

/* Timer */
void timer_init(uint32_t compare_val);
void timer_enable(void);
void timer_disable(void);

/* Watchdog */
void wdog_init(uint32_t load_val);
void wdog_kick(void);

/* Power management */
void pm_sleep_request(void);
void pm_wake_enable(void);

#endif /* DRIVERS_H */
