# WinPurge v1.0.0 — Production Release Notes

> *Copy and paste the markdown below directly into your GitHub Release description when publishing `v1.0.0`.*

---

```markdown
# WinPurge v1.0.0 (Initial Production Release)

WinPurge v1.0.0 is an open-source, high-performance, standalone system cleaning utility for Windows 10 and 11. Designed with complete transparency and zero external dependencies, it operates strictly via native Windows Batch.

---

### Core Highlights

- **Native Windows Batch Architecture:** Requires zero compilers, runtimes, or background daemons. Inspectable plaintext code throughout.
- **Real Before/After File Counting Engine:** Computes exact file deletion counts (`CNT_B`, `CNT_A`, `CNT_DEL`) and identifies locked/in-use files held open by running applications.
- **Target Drive Free Space Delta:** Measures volume free space before and after execution to calculate real megabytes reclaimed.
- **Live DISM Telemetry Streaming:** Displays the live, unsuppressed DISM progress indicator directly in the console.
- **Automated UAC Elevation:** Incorporates an internal elevation trampoline targeting `conhost.exe` via VBScript `Shell.Application` `runas` to ensure verified administrator privileges on launch.
- **ANSI VT100 Terminal Interface:** Clean, high-contrast dark theme console interface with cyan headers, green status badges, and distinctive colored prompts.
- **Strict Safety Defaults:**
  - Initial startup confirmation prompt defaults to Proceed `[Y]`.
  - Recycle Bin purge prompt defaults to Protect `[N]`, preventing accidental data loss.
- **Environment & Argument Customization:** Native support for `.env` configuration files and command-line arguments (`/y`, `/norecycle`, `/noprefetch`, `/nocolor`).
- **Zero Telemetry Guarantee:** 100% offline functionality with zero outbound network calls.

---

### Cleaning Operations

1. **User Temporary Files:** Purges `%TEMP%\*` files and subfolders with live file counting and active lock detection.
2. **System Temporary Files:** Cleans `%SystemRoot%\Temp\*` and installer staging dumps with locked-file tracking.
3. **Windows Prefetch Cache:** Flushes stale application launch traces.
4. **Windows Update Download Cache:** Safely stops `wuauserv` and `bits`, cleans `SoftwareDistribution\Download`, and restarts background update services.
5. **DISM Component Store:** Executes `dism.exe /Online /Cleanup-Image /StartComponentCleanup` with live progress bars to compress and purge superseded Windows update components.
6. **Recycle Bin:** Empties the system drive's recycle bin via Windows Shell API after explicit confirmation.

---

### Verification & Checksums

| File | Type | Integrity SHA-256 |
|---|---|---|
| `winpurge.bat` | Windows Batch Script | `1F268C29A2BF26A4E755582E9CA785DDD1CB86038BAFEAC9396E7B8D51B71AE5` |
| `.env.example` | Configuration Template | `CB1A050F0576E6EEF7F831F78427912E228682CA3B082755ACCBAD71ACC98D17` |
```
