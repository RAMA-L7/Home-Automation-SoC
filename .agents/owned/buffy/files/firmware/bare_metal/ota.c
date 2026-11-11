/*------------------------------------------------------------------------------
 * Home-Automation-SoC — OTA (Over-The-Air) Firmware Update
 * Stage 3 Firmware
 *
 * STATUS: NOT IMPLEMENTED.  This function is an explicit, fail-closed stub.
 *
 * The previous revision accepted a full "update" over UART, discarded every
 * payload byte, printed "signature verified" without verifying anything, and
 * then marked the partition bootable.  That sequence could brick a device while
 * reporting success, so it has been removed rather than left half-working.
 *
 * Requirements before this can return 0 (see reports/INDEPENDENT_REVIEW...):
 *   1. QSPI flash identification, write-enable, page program, erase, busy
 *      polling with timeouts, and read-back verification.  The current
 *      qspi_flash_ctrl implements single-line READ only and rejects writes.
 *   2. A bounded transport with flow control; every length checked against the
 *      partition size; every timeout propagated to the caller.
 *   3. Program only the inactive slot; keep the running slot intact across
 *      interruption or power loss.
 *   4. Authenticate the image BEFORE activating it, then update power-loss-safe
 *      boot metadata with trial boot, health confirmation, bounded retries and
 *      fallback when both slots fail.
 *----------------------------------------------------------------------------*/

#include "boot.h"
#include "drivers.h"

/* Returns 0 on success, nonzero on any failure.  Always nonzero today. */
int ota_receive_image(uint32_t target_partition)
{
    (void)target_partition;

    uart_puts("ER OTA unsupported: flash programming is not implemented\r\n");
    uart_puts("   no bytes consumed, boot flag unchanged\r\n");

    return -1;
}
