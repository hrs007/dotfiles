[CmdletBinding()]
param(
    [switch] $Unregister
)

$ErrorActionPreference = 'Stop'
$extensions = @(
    '.py', '.pyw', '.js', '.jsx', '.mjs', '.cjs', '.ts', '.tsx', '.json',
    '.html', '.css', '.scss', '.less', '.vue', '.svelte', '.c', '.h', '.cc',
    '.cpp', '.cxx', '.hpp', '.hxx', '.cs', '.xaml', '.lua', '.sh', '.yaml',
    '.yml', '.toml', '.rs', '.go', '.xml', '.sql'
)

$appKey = 'HKCU:\Software\Classes\Applications\neovide.exe'
$openWithProgId = 'Neovide.SourceFile'
$progIdKey = "HKCU:\Software\Classes\$openWithProgId"

if ($Unregister) {
    foreach ($extension in $extensions) {
        $key = "HKCU:\Software\Classes\$extension\OpenWithProgids"
        if (Test-Path $key) {
            Remove-ItemProperty -Path $key -Name $openWithProgId -ErrorAction SilentlyContinue
        }
    }
    Remove-Item $appKey -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $progIdKey -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host 'Removed Neovide Open with registration.'
    exit 0
}

$neovide = (Get-Command neovide.exe -ErrorAction SilentlyContinue).Source
if (-not $neovide) {
    $candidates = @(
        "$env:USERPROFILE\scoop\apps\neovide\current\neovide.exe",
        "$env:LOCALAPPDATA\Programs\Neovide\neovide.exe"
    )
    $neovide = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $neovide) {
    throw 'Could not find neovide.exe. Install Neovide or add it to PATH, then retry.'
}

$nvim = (Get-Command nvim.exe -ErrorAction SilentlyContinue).Source
if (-not $nvim) {
    $nvimCandidates = @(
        "$env:USERPROFILE\scoop\apps\neovim\current\bin\nvim.exe",
        "$env:LOCALAPPDATA\Programs\Neovim\bin\nvim.exe"
    )
    $nvim = $nvimCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $nvim) {
    throw 'Could not find nvim.exe. Install Neovim or add it to PATH, then retry.'
}

$configDirectory = Join-Path $env:APPDATA 'neovide'
$configPath = Join-Path $configDirectory 'config.toml'
New-Item -Path $configDirectory -ItemType Directory -Force | Out-Null
$configLines = if (Test-Path $configPath) { @(Get-Content $configPath) } else { @() }
$neovimBinLine = 'neovim-bin = "{0}"' -f ($nvim -replace '\\', '\\\\')
$settingIndex = -1
for ($index = 0; $index -lt $configLines.Count; $index++) {
    if ($configLines[$index] -match '^\s*neovim-bin\s*=') {
        $settingIndex = $index
        break
    }
}
if ($settingIndex -ge 0) {
    $configLines[$settingIndex] = $neovimBinLine
} else {
    $configLines += $neovimBinLine
}
Set-Content -Path $configPath -Value $configLines -Encoding utf8

$command = '"{0}" --reuse-instance "%1"' -f $neovide
New-Item -Path "$appKey\shell\open\command" -Force | Out-Null
Set-Item -Path "$appKey\shell\open\command" -Value $command
New-Item -Path "$progIdKey\shell\open\command" -Force | Out-Null
Set-Item -Path "$progIdKey\shell\open\command" -Value $command

foreach ($extension in $extensions) {
    $key = "HKCU:\Software\Classes\$extension\OpenWithProgids"
    New-Item -Path $key -Force | Out-Null
    New-ItemProperty -Path $key -Name $openWithProgId -PropertyType None -Value ([byte[]]@()) -Force | Out-Null
}

Write-Host "Registered Neovide ($neovide) in Open with for source and config file extensions."
Write-Host 'Choose Neovide as the default for selected extensions in Windows Settings > Apps > Default apps.'
Start-Process 'ms-settings:defaultapps'
