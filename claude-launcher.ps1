# Claude Launcher with MCP Cleanup
$claudePath = "$env:LOCALAPPDATA\AnthropicClaude\Claude.exe"
$mcpPattern = "ClaudeWorkspace"

Write-Host "Starting Claude..." -ForegroundColor Cyan
Start-Process $claudePath

Write-Host "Waiting for Claude window..." -ForegroundColor Gray

# Wait until a Claude process has a window
$timeout = 60
$waited = 0
while ($waited -lt $timeout) {
    Start-Sleep -Seconds 1
    $waited++
    $withWindow = Get-Process Claude -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle}
    if ($withWindow) {
        Write-Host "Claude window detected." -ForegroundColor Green
        break
    }
}

if ($waited -ge $timeout) {
    Write-Host "Timeout waiting for Claude. Exiting." -ForegroundColor Red
    exit
}

Write-Host "Monitoring. Will clean up on exit." -ForegroundColor Green

# Watch for window to disappear
$noWindowCount = 0
while ($true) {
    Start-Sleep -Seconds 3
    $withWindow = Get-Process Claude -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle}
    
    if (-not $withWindow) {
        $noWindowCount++
        Write-Host "No window detected ($noWindowCount/3)..." -ForegroundColor Gray
        if ($noWindowCount -ge 3) {
            Write-Host "Window closed. Cleaning up..." -ForegroundColor Yellow
            break
        }
    } else {
        $noWindowCount = 0
    }
}

# Kill Claude zombies
Get-Process Claude -ErrorAction SilentlyContinue | Stop-Process -Force

# Kill MCP processes from ClaudeWorkspace
$killed = 0
Get-WmiObject Win32_Process | Where-Object { 
    $_.CommandLine -like "*$mcpPattern*" 
} | ForEach-Object { 
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    Write-Host "  Killed PID $($_.ProcessId)" -ForegroundColor Red
    $killed++
}

Get-WmiObject Win32_Process -Filter "name='node.exe'" | Where-Object {
    $_.CommandLine -like "*claude*" -or $_.CommandLine -like "*mcp*"
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    Write-Host "  Killed node PID $($_.ProcessId)" -ForegroundColor Red
    $killed++
}

Write-Host "Done. Killed $killed processes." -ForegroundColor Green
