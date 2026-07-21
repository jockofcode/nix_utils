/* nix_utils/sp_proc_ext.c -- Process-related native functions for the Spinel runtime.
 *
 * Provides sethostname and exec_shell — operations not available through
 * Spinel's built-in Ruby runtime.  Bound to Ruby via native_func declarations
 * in nix_utils/proc_ext.rb and passed to Spinel with `--link nix_utils/sp_proc_ext.c`.
 */

#include "spinel/runtime.h"
#include <unistd.h>
#include <string.h>
#include <errno.h>

/* ---------------------------------------------------------------------------
 * ProcExt.sethostname(name) -> Integer  (0 = success, errno on failure)
 *
 * Wraps sethostname(2). Requires root on most systems.
 * --------------------------------------------------------------------------- */
mrb_int sp_sethostname_c(const char *name) {
    int len = (int)strlen(name);
    if (sethostname(name, len) == 0) return 0;
    return (mrb_int)errno;
}

/* ---------------------------------------------------------------------------
 * ProcExt.exec_shell(cmd) -> Integer  (errno on failure; never returns on success)
 *
 * Replaces the current process with /bin/sh -c cmd via execl(3).
 * On success the process image is replaced and this function does not return.
 * On failure (e.g. /bin/sh not found) returns errno.
 * --------------------------------------------------------------------------- */
mrb_int sp_exec_shell_c(const char *cmd) {
    execl("/bin/sh", "sh", "-c", cmd, (char *)NULL);
    return (mrb_int)errno;
}
