# OSM Diagnostics Context

You are diagnosing an issue with the AC_OSM (OpenSource Manager) PowerShell automation framework. Use the architecture, execution flow, and log locations below to efficiently identify root causes.

## Execution Flow

**Logon auto-run** triggers via two mechanisms registered by `src/Local-Install.ps1`:

1. **Registry Run key**: `HKLM:\Software\Microsoft\Windows\CurrentVersion\Run\OSM-Configure`
   - Command: `pwsh -ExecutionPolicy Bypass -File "C:\osm\configurator\src\Configure.ps1" -IsLogon -LoggingLevel INFO`
   - Registration function: `Invoke-ScriptRegistration` (Local-Install.ps1)

2. **Scheduled task**: `OSM-Configurator-Logon` (task path `\`)
   - Trigger: AtLogOn (per-user), RunLevel Highest, Interactive logon
   - Action: `pwsh.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File "...\Configure.ps1" -IsLogon -LoggingLevel INFO`
   - Registration function: `Invoke-RegisterLogonTask` (src/features/ScheduledTasks.ps1)

**Configure.ps1 startup sequence** (lines 403-476):
1. Dot-sources 21 feature modules (Logging, Runtime, Exception, Display, Applications, Types, Application, Actions, Elevated, Git, Github, Network, Powershell, ProfileActions, Registry, ScheduledTasks, Shortcuts, Utilities, Validation, XPipe, OSMApplication)
2. Asserts PowerShell 7+ (`Assert-PowershellVersion7`)
3. Sets globals: `$global:IsLogon`, `$global:IsElevated`, `$global:LogLevel`, `$global:IsOnline`
4. **Aborts if offline** and non-interactive (line 464-468)
5. **Elevates via UAC** if not admin and non-interactive (line 471-474) — calls `Invoke-ElevatePowershell` which uses `Start-Process -Verb RunAs`
6. `Assert-RunningAsAdministrator` — if still not elevated, relaunches via `Start-Script -Elevated -Relaunch` (Runtime.ps1:401-413)
7. Imports Spectre Console if online
8. Loads master data, applies profile actions, manages applications

## Log Locations

Check these paths when diagnosing failures:

| Log Type | Path Pattern | Notes |
|----------|-------------|-------|
| Application log | `C:\osm\logs\OSMPC\OSMPC-Configurator-{yyyyMMddHHmmss}.log` | Add `-elevated` suffix for admin runs |
| Installer log | `C:\osm\logs\OSMPC\OSMPC-Installer-{yyyyMMddHHmmss}.log` | From Local-Install.ps1 |
| Transcript | `C:\osm\logs\OSMPC\OSMPC-Transcript-{username}-{yyyyMMdd}[-Admin].transcript` | Full PowerShell transcript |
| Fallback log dir | `%TEMP%\OSMPC\` | Used when `C:\osm\logs` is unavailable |

Log retention: 14 days (configurable via `$global:LogRetentionDays`).

Log levels in order: TRACE, DEBUG, INFO, WARNING, ERROR, CRITICAL.

## Common Failure Points

1. **Missing function call** — Installer calls a function that doesn't exist (e.g., typo or renamed). Check the call site in Local-Install.ps1 against actual function definitions in `src/features/`.
2. **Invalid pwsh.exe arguments** — Registry Run key command must only contain valid `pwsh.exe` flags and valid `Configure.ps1` parameters. Configure.ps1 uses `[cmdletbinding()]` so unrecognized params cause a terminating error.
3. **UAC elevation at logon** — `Start-Process -Verb RunAs` triggers a UAC prompt. At logon without user interaction the process may hang or fail silently. The scheduled task with `RunLevel Highest` avoids this.
4. **Offline abort** — Configure.ps1:464-468 exits if `Get-IsOnline` returns false and not interactive.
5. **PowerShell 7 not found** — `Assert-PowershellVersion7` (Configure.ps1) and Elevated.ps1 check `c:\program files\PowerShell\7\pwsh.exe`; fall back to Windows PowerShell 5.1.
6. **Invoke restriction** — `Assert-InvokeRestriction` checks registry at `HKCU:\Software\OPBTA\CustomUserProfile\LastInvoked` to throttle re-runs.
7. **Registry ACL/elevation errors** — Some HKLM keys require elevation. Tracked in `$global:RegistryKeysRequiringElevatedPrivileges` and `$global:RegistryKeysBrokenACLs`.
8. **JSON schema validation** — Invalid action files in `assets/actions/all/` are silently skipped with a warning log.

## Key Files for Diagnostics

| File | Purpose |
|------|---------|
| `src/Configure.ps1` | Main orchestrator, parameter definitions, startup sequence |
| `src/Local-Install.ps1` | Installer: `Invoke-ScriptRegistration`, `Invoke-PostInstallationVerification`, `OSMApplication` class (installer copy) |
| `src/features/OSMApplication.ps1` | Runtime `OSMApplication` class: `LaunchPath`, `WindowsRunRegistryPath`, `Errors[]` |
| `src/features/Elevated.ps1` | `Invoke-ElevatePowershell` — UAC elevation via `Start-Process -Verb RunAs` |
| `src/features/Runtime.ps1` | `Assert-RunningAsAdministrator`, `Start-Script`, `Assert-InvokeRestriction`, `Get-IsRunningAsAdministrator` |
| `src/features/ScheduledTasks.ps1` | `Invoke-RegisterLogonTask`, `Invoke-DisableScheduledTask` |
| `src/features/Logging.ps1` | `New-LogEvent`, `Initialize-Logging`, log sinks (Configurator, Launcher, Installer) |
| `src/features/Exception.ps1` | `Set-Exception` — sets `$global:ExceptionDetected`, accumulates `$global:Exceptions` |
| `src/features/Registry.ps1` | `Set-RegistryKeyNamedValue`, registry cache (`$global:RegistryCache`) |
| `src/features/Network.ps1` | `Get-IsOnline` — checks `Get-NetConnectionProfile` IPv4Connectivity |
| `assets/actions/all/*.json` | Action definitions (RegistryAction, MethodAction, IOAction, ScheduledTaskAction) |

## Diagnostic Steps

1. **Read the most recent logs** in `C:\osm\logs\OSMPC\` — check both the `.log` and `.transcript` files sorted by date.
2. **Check registry** — verify `HKLM:\Software\Microsoft\Windows\CurrentVersion\Run\OSM-Configure` exists and has a valid command.
3. **Check scheduled task** — verify `OSM-Configurator-Logon` exists via `Get-ScheduledTask -TaskName "OSM-Configurator-Logon"`.
4. **Check elevation** — if the process must run elevated, confirm the scheduled task has `RunLevel Highest` or that UAC is not blocking.
5. **Check network** — offline detection at startup will abort non-interactive runs.
6. **Check PowerShell version** — `pwsh.exe` must be available for the registered commands to work.
7. **Review exception globals** — `$global:Exceptions` array and `$global:ExceptionDetected` flag track runtime errors.

---

Now diagnose the user's issue. Start by reading the most recent log files and checking the registry Run key and scheduled task state. Ask the user to describe the symptom if not already provided.
