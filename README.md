# RevividorPC

One click, in Spanish, no snake oil. Revives a slow Windows PC:

1. **Creates a restore point** first (so everything can be undone).
2. **Removes bloatware** — factory apps nobody asked for (games, TikTok, trials…).
3. **Disables startup programs** that slow down boot.
4. **Turns off telemetry, Copilot and ads.**
5. **Enables performance mode** — minimal visual effects, faster menus.

It asks for confirmation before doing anything, shows an honest summary at the
end, and never deletes your files, never closes your programs, never asks for
money.

## How it works

`RevividorPC.exe` is a small Go launcher: it requests administrator rights
(UAC), extracts the embedded PowerShell script to a temp folder, runs it, and
waits. All the actual work lives in `revividor.ps1`, using curated safe lists:

| List | What it covers |
|---|---|
| `$bloat` | AppX packages safe to remove (Bing apps, Solitaire, Spotify/TikTok trials, Candy Crush…) |
| `$startupKill` | Startup entries to disable (OneDrive, Teams, Cortana, updaters…) |
| `$servicios` | Services to stop & disable (`DiagTrack`, `dmwappushservice`, `SysMain`) |
| `$tareasPath` / `$tareasNombre` | Scheduled telemetry tasks to disable |

Registry tweaks: telemetry policies, ad ID, Copilot off, visual effects to
"best performance", Storage Sense on.

## Requirements

- Windows 10/11 (x86-64)
- Administrator rights (it asks via UAC on launch)

## Usage

1. Double-click `RevividorPC.exe`.
2. Click **Yes** on the Windows admin prompt.
3. Read what it found, confirm with `S`, and let it work.
4. Restart your PC to feel the difference.

If anything goes wrong, restore from the checkpoint it created
(*Control Panel → Recovery*).

## Build from source

```powershell
# requires Go 1.21+
go build -o RevividorPC.exe .
```

> Note: the Go source uses `import _ "embed"` to bundle `revividor.ps1`
> inside the executable.

## License

MIT — see [LICENSE](LICENSE).
