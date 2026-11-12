/*------------------------------------------------------------------------------
 * Home-Automation-SoC — Bare-Metal Firmware Main
 * Stage 3 Firmware
 *
 * Minimal example: blink GPIO LED, respond to UART commands.
 * Built with: riscv32-unknown-elf-gcc -march=rv32im -mabi=ilp32
 * (rv32im: the in-tree core implements no compressed instructions)
 *----------------------------------------------------------------------------*/

#include <stdint.h>

/* APB peripheral base addresses (from has_addr_map_pkg) */
#define GPIO_BASE 0x50000000
#define UART_BASE 0x50001000
#define TIMER_BASE 0x50005000
#define WDOG_BASE 0x50006000
#define PWRMGR_BASE 0x50008000
#define PWM_BASE    0x50004000

/* GPIO registers */
#define REG_GPIO_DATA_OUT   (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define REG_GPIO_DATA_IN    (*(volatile uint32_t *)(GPIO_BASE + 0x04))
#define REG_GPIO_OE         (*(volatile uint32_t *)(GPIO_BASE + 0x08))
#define REG_GPIO_INT_EN     (*(volatile uint32_t *)(GPIO_BASE + 0x0C))
#define REG_GPIO_INT_RISE   (*(volatile uint32_t *)(GPIO_BASE + 0x10))
#define REG_GPIO_INT_FALL   (*(volatile uint32_t *)(GPIO_BASE + 0x14))
#define REG_GPIO_INT_PEND   (*(volatile uint32_t *)(GPIO_BASE + 0x18))

/* UART registers */
#define REG_UART_THR        (*(volatile uint32_t *)(UART_BASE + 0x00))
#define REG_UART_RBR        (*(volatile uint32_t *)(UART_BASE + 0x00))
#define REG_UART_IER        (*(volatile uint32_t *)(UART_BASE + 0x04))
#define REG_UART_LCR        (*(volatile uint32_t *)(UART_BASE + 0x0C))
#define REG_UART_LSR        (*(volatile uint32_t *)(UART_BASE + 0x14))

/* Timer registers */
#define REG_TIMER_COUNT     (*(volatile uint32_t *)(TIMER_BASE + 0x00))
#define REG_TIMER_COMPARE   (*(volatile uint32_t *)(TIMER_BASE + 0x04))
#define REG_TIMER_CTRL      (*(volatile uint32_t *)(TIMER_BASE + 0x08))
#define REG_TIMER_STATUS    (*(volatile uint32_t *)(TIMER_BASE + 0x0C))

/* Watchdog registers */
#define REG_WDOG_LOAD       (*(volatile uint32_t *)(WDOG_BASE + 0x00))
#define REG_WDOG_CTRL       (*(volatile uint32_t *)(WDOG_BASE + 0x04))
#define REG_WDOG_STATUS     (*(volatile uint32_t *)(WDOG_BASE + 0x08))

/* Watchdog period in cycles (1,000,000 = 20 ms at 50 MHz).  This is the
 * firmware's only value: the same constant is used to reload and to pet. */
#define WDOG_RELOAD         1000000u
/* CTRL bits: bit0 enable, bit1 route the timeout to the reset output.
 * Both bits are needed: enabling the counter alone only raises irq, and a
 * watchdog that cannot reset the SoC is not a watchdog. */
#define WDOG_CTRL_ENABLE    (1u << 0)
#define WDOG_CTRL_RESET_EN  (1u << 1)
#define WDOG_CTRL_ARMED     (WDOG_CTRL_ENABLE | WDOG_CTRL_RESET_EN)

/* Power manager registers */
#define REG_PM_CTRL         (*(volatile uint32_t *)(PWRMGR_BASE + 0x00))
#define REG_PM_STATUS       (*(volatile uint32_t *)(PWRMGR_BASE + 0x04))
#define REG_PM_WAKE_EN      (*(volatile uint32_t *)(PWRMGR_BASE + 0x08))

/*------------------------------------------------------------------------------
 * UART putchar — polling TX
 *----------------------------------------------------------------------------*/
static void uart_putc(char c)
{
    /* Wait for THRE (bit 5 of LSR) */
    while (!(REG_UART_LSR & 0x20))
        ;
    REG_UART_THR = (uint32_t)c;
}

/*------------------------------------------------------------------------------
 * UART getchar — polling RX
 *----------------------------------------------------------------------------*/
static char uart_getc(void)
{
    /* Wait for RDR (bit 0 of LSR) */
    while (!(REG_UART_LSR & 0x01))
        ;
    return (char)(REG_UART_RBR & 0xFF);
}

/*------------------------------------------------------------------------------
 * Print a null-terminated string
 *----------------------------------------------------------------------------*/
static void uart_puts(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

/*------------------------------------------------------------------------------
 * Print a hex32 value
 *----------------------------------------------------------------------------*/
static void uart_print_hex(uint32_t v)
{
    int i;
    uart_puts("0x");
    for (i = 28; i >= 0; i -= 4) {
        char c = "0123456789ABCDEF"[(v >> i) & 0xF];
        uart_putc(c);
    }
}

/*------------------------------------------------------------------------------
 * Delay loop (blocking)
 *
 * Pets the watchdog periodically: a long delay can exceed one timeout period,
 * and the previous version let the dog fire in the middle of its own blink
 * delay (1,000,000 cycles ~ 20 ms at 50 MHz), so the firmware reset itself
 * in a loop instead of running.
 *----------------------------------------------------------------------------*/
static void delay(volatile uint32_t cycles)
{
    while (cycles--) {
        /* Pet every 4,096 cycles: well inside the WDOG_RELOAD window and
         * reachable even for delays shorter than the old 65,536 mask. */
        if ((cycles & 0x0FFFu) == 0u)
            REG_WDOG_LOAD = WDOG_RELOAD;
    }
}

/*------------------------------------------------------------------------------
 * main — firmware entry after startup.S
 *----------------------------------------------------------------------------*/
int main(void)
{
    uint32_t led_state = 0;
    uint32_t blink_count = 0;
    uint32_t sensor_value = 0;

    /* Configure GPIO[0] as output (LED) */
    REG_GPIO_OE |= (1u << 0);
    REG_GPIO_DATA_OUT &= ~(1u << 0);   /* LED off initially */

    /* Configure UART: 8N1, DLAB=0 */
    REG_UART_LCR = 0x03;               /* 8 bits, no parity, 1 stop */
    REG_UART_IER = 0x00;               /* no interrupts (polling) */

    /* Arm the watchdog: counting + timeout drives the reset output. */
    REG_WDOG_LOAD = WDOG_RELOAD;
    REG_WDOG_CTRL = WDOG_CTRL_ARMED;

    /* Sensor acquisition (simulation input): read the free-running timer
     * counter as a stand-in for a physical sensor.  The value is validated
     * (non-zero) and stored in `sensor_value` for the host. */
    REG_TIMER_CTRL = 0x01;          /* enable counter */
    {
        uint32_t s = REG_TIMER_COUNT;
        if (s == 0u) s = 1u;       /* never report an uninitialised sample */
        sensor_value = s;
        uart_puts("Sensor: ");
        uart_print_hex(sensor_value);
        uart_puts("\r\n");
    }

    /* Announce boot */
    uart_puts("\r\n=== Home-Automation-SoC Firmware ===\r\n");
    uart_puts("Core: RV32IM\r\n");
    uart_puts("SRAM: 128 KB @ 0x2000_0000\r\n");
    uart_puts("Boot: Complete\r\n");
    uart_puts("Ready for commands.\r\n");

    /* Main loop */
    for (;;) {
        /* Blink LED every ~250K cycles (well inside the watchdog period) */
        led_state = !led_state;
        if (led_state)
            REG_GPIO_DATA_OUT |= (1u << 0);
        else
            REG_GPIO_DATA_OUT &= ~(1u << 0);

        blink_count++;
        uart_puts("Blink #");
        uart_print_hex(blink_count);
        uart_puts("\r\n");

        /* Pet the watchdog */
        REG_WDOG_LOAD = WDOG_RELOAD;

        /* Check for UART command (non-blocking poll via LSR) */
        if (REG_UART_LSR & 0x01) {
            char c = (char)(REG_UART_RBR & 0xFF);
            uart_puts("Cmd: ");
            uart_putc(c);
            uart_puts("\r\n");

            if (c == 'r' || c == 'R') {
                uart_puts("Reboot requested\r\n");
                /* Trigger watchdog reset by not feeding */
                while (1)
                    ;
            } else if (c == 's' || c == 'S') {
                uart_puts("Sleep requested\r\n");
                REG_PM_CTRL |= 0x01;   /* request sleep */
            } else if (c == 'l' || c == 'L') {
                /* GPIO/PWM response: toggle LED */
                led_state = !led_state;
                if (led_state)
                    REG_GPIO_DATA_OUT |= (1u << 0);
                else
                    REG_GPIO_DATA_OUT &= ~(1u << 0);
                uart_puts("LED toggled\r\n");
            } else if (c == 'p' || c == 'P') {
                /* PWM response: configure channel 0, 50% duty */
                (*(volatile uint32_t *)(PWM_BASE + 0x00)) = 999u;   /* PERIOD */
                (*(volatile uint32_t *)(PWM_BASE + 0x04)) = 500u;   /* DUTY  */
                (*(volatile uint32_t *)(PWM_BASE + 0x20)) = 0x01u;  /* enable */
                uart_puts("PWM set\r\n");
            } else {
                uart_puts("ERR unknown command\r\n");
            }
        }

        delay(50000u);
    }

    return 0;
}
