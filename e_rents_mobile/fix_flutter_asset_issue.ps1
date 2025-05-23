# Set your project path
$projectPath = "D:\MIS\eRents\e_rents_mobile"
$assetPath = "$projectPath\assets\images\appartment.jpg"
$buildPath = "$projectPath\build"

# 1. Try to close any open handles (requires Sysinternals Handle utility)
$handleExe = "$env:USERPROFILE\Downloads\handle.exe"
if (Test-Path $handleExe) {
    Write-Host "Closing open handles to $assetPath (if any)..."
    & $handleExe $assetPath /accepteula | ForEach-Object {
        if ($_ -match "pid: (\d+)") {
            $pid = $matches[1]
            Write-Host "Killing process with PID $pid"
            Stop-Process -Id $pid -Force
        }
    }
} else {
    Write-Host "handle.exe not found. Skipping handle close step."
    Write-Host "You can download it from https://docs.microsoft.com/en-us/sysinternals/downloads/handle"
}

# 2. Fix permissions on the asset and its parent directories
Write-Host "Setting permissions on $assetPath and parent folders..."
icacls $assetPath /grant "$($env:USERNAME):(F)" /T
icacls "$projectPath\assets\images" /grant "$($env:USERNAME):(F)" /T
icacls "$projectPath\assets" /grant "$($env:USERNAME):(F)" /T
icacls $projectPath /grant "$($env:USERNAME):(F)" /T

# 3. Delete the build directory
if (Test-Path $buildPath) {
    Write-Host "Deleting build directory..."
    Remove-Item -Recurse -Force $buildPath
} else {
    Write-Host "Build directory not found, skipping delete."
}

Write-Host "Done. Now try running 'flutter run' again."
