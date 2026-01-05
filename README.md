# Claude Launcher

A Windows launcher for the [Claude](https://claude.ai) desktop app that automatically cleans up zombie Electron processes and MCP server processes when you close Claude.

## The Problem

Claude's desktop app (built on Electron) often leaves behind zombie processes when you close it:

- **Electron child processes** - renderers, GPU process, utilities that don't exit cleanly
- **MCP server processes** - Python and Node.js processes for Model Context Protocol integrations

These pile up over time, eating memory and CPU.

## The Solution

This launcher:

1. Starts Claude
2. Monitors for the window to close
3. Kills zombie Claude processes
4. Kills MCP processes (Python/Node) that were spawned from your workspace

## Installation

1. Clone or download this repo
2. Edit `claude-launcher.ps1` and adjust these variables if needed:
   ```powershell
   $claudePath = "$env:LOCALAPPDATA\AnthropicClaude\Claude.exe"
   $mcpPattern = "ClaudeWorkspace"  # Change to match your MCP project folder
   ```
3. Double-click `Claude.bat` to launch

## Pin to Taskbar

Windows won't pin `.bat` files directly. Here's the workaround:

1. Right-click `Claude.bat` → **Create shortcut**
2. Right-click the shortcut → **Properties**
3. Change **Target** to:
   ```
   powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\path\to\claude-launcher.ps1"
   ```
4. Change **Start in** to the folder containing the script
5. Click **Change Icon** → browse to:
   ```
   C:\Users\<you>\AppData\Local\AnthropicClaude\Claude.exe
   ```
6. Apply, then right-click the shortcut → **Pin to taskbar**

The `-WindowStyle Hidden` flag runs the monitor silently in the background.

## How It Works

### Window Detection

The script uses PowerShell's `Get-Process` with `MainWindowTitle` to detect when Claude's window opens and closes. It waits for 3 consecutive checks (9 seconds) with no window before triggering cleanup — this prevents false exits from brief UI flickers.

### Process Cleanup

After the window closes:

1. **Claude zombies** - All remaining `Claude.exe` processes are force-killed
2. **MCP Python/Node** - Processes with your workspace path in their command line are killed
3. **MCP bridges** - Node processes with "claude" or "mcp" in their command line are killed

The script only kills processes matching your workspace pattern, so other Python/Node work (like VS Code) is untouched.

## Configuration

| Variable | Description |
|----------|-------------|
| `$claudePath` | Path to Claude.exe (usually in AppData\Local\AnthropicClaude) |
| `$mcpPattern` | String to match in MCP process command lines (your project folder name) |

## Troubleshooting

### Script exits immediately after starting

The window detection might be flaky. Increase the grace period by changing `3` to `5` in this line:
```powershell
if ($noWindowCount -ge 3) {
```

### Claude not found

Find your Claude install path:
```powershell
Get-ChildItem "$env:LOCALAPPDATA" -Filter "Claude.exe" -Recurse
```

### MCP processes not being killed

Check what pattern matches your MCP processes:
```powershell
Get-WmiObject Win32_Process -Filter "name='python.exe'" | Select ProcessId, CommandLine
```

Adjust `$mcpPattern` to match.

## License

MIT
