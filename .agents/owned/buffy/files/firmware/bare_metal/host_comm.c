/*------------------------------------------------------------------------------
 * Home-Automation-SoC — Host Communication (UART to Home Assistant)
 * Stage 3 Firmware
 *
 * Communicates with external host running Home Assistant + Claude voice
 * assistant over UART. Simple JSON-ish telemetry protocol.
 *----------------------------------------------------------------------------*/

#include "drivers.h"

/* Command frame format: <CMD> <ARG>\n */
/* Responses: OK <DATA>\n or ERR <CODE>\n */

#define CMD_GET_TEMP    't'
#define CMD_GET_HUMID   'h'
#define CMD_SET_LED     'l'
#define CMD_GET_STATUS  's'
#define CMD_REBOOT      'r'
#define CMD_SLEEP       'S'

static void send_ok_hex(uint32_t val)
{
    uart_puts("OK ");
    uart_print_hex(val);
    uart_putc('\r');
    uart_putc('\n');
}

static void send_err(uint32_t code)
{
    uart_puts("ERR ");
    uart_print_hex(code);
    uart_putc('\r');
    uart_putc('\n');
}

void host_comm_poll(void)
{
    char cmd;
    uint32_t arg;

    if (!(REG_UART_LSR & 0x01))
        return;   /* no data */

    cmd = (char)(REG_UART_RBR & 0xFF);

    /* Read optional argument (hex) */
    arg = 0;
    /* Simple: skip to next char (in real impl, parse hex) */

    switch (cmd) {
    case CMD_GET_TEMP:
        /* Placeholder: read temperature sensor via I2C */
        send_ok_hex(0x0019);   /* 25.0 C * 100 */
        break;
    case CMD_GET_HUMID:
        send_ok_hex(0x0032);   /* 50% * 100 */
        break;
    case CMD_SET_LED:
        gpio_write(0, arg ? 1 : 0);
        uart_puts("OK\r\n");
        break;
    case CMD_GET_STATUS:
        send_ok_hex(REG_GPIO_DATA_OUT);
        break;
    case CMD_REBOOT:
        uart_puts("OK rebooting\r\n");
        /* Trigger watchdog reset */
        REG_WDOG_LOAD = 1;
        while (1)
            ;
        break;
    case CMD_SLEEP:
        pm_sleep_request();
        uart_puts("OK sleeping\r\n");
        break;
    default:
        send_err(0x01);   /* unknown command */
        break;
    }
}
