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
$pythonOpenWithProgId = 'Neovide.PythonSourceFile'
$pythonProgIdKey = "HKCU:\Software\Classes\$pythonOpenWithProgId"
$capabilitiesKey = 'HKCU:\Software\Neovide\Capabilities'
$registeredApplicationsKey = 'HKCU:\Software\RegisteredApplications'
$appPathKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\neovide.exe'
$startMenuShortcut = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Neovide.lnk'

function Get-NeovideProgId([string] $extension) {
    if ($extension -in @('.py', '.pyw')) {
        return $pythonOpenWithProgId
    }
    return 'Neovide.SourceFile.' + $extension.TrimStart('.')
}

if ($Unregister) {
    foreach ($extension in $extensions) {
        $extensionProgId = Get-NeovideProgId $extension
        $key = "HKCU:\Software\Classes\$extension\OpenWithProgids"
        if (Test-Path $key) {
            Remove-ItemProperty -Path $key -Name $openWithProgId -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $key -Name $pythonOpenWithProgId -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $key -Name $extensionProgId -ErrorAction SilentlyContinue
        }

        $fileExtKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$extension"
        $fileExtProgIds = Join-Path $fileExtKey 'OpenWithProgids'
        Remove-ItemProperty -Path $fileExtProgIds -Name $openWithProgId -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $fileExtProgIds -Name $pythonOpenWithProgId -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $fileExtProgIds -Name $extensionProgId -ErrorAction SilentlyContinue
        Remove-Item "HKCU:\Software\Classes\$extensionProgId" -Recurse -Force -ErrorAction SilentlyContinue

        $openWithList = Join-Path $fileExtKey 'OpenWithList'
        if (Test-Path $openWithList) {
            $list = Get-Item $openWithList
            $slots = @($list.GetValueNames() | Where-Object { $_ -match '^[a-z]$' })
            foreach ($slot in $slots) {
                if ($list.GetValue($slot) -ieq 'neovide.exe') {
                    Remove-ItemProperty -Path $openWithList -Name $slot -ErrorAction SilentlyContinue
                    $mru = [string] $list.GetValue('MRUList', '')
                    Set-ItemProperty -Path $openWithList -Name 'MRUList' -Value ($mru.Replace($slot, '')) -ErrorAction SilentlyContinue
                }
            }
        }
    }
    Remove-Item $appKey -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $progIdKey -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $pythonProgIdKey -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item 'HKCU:\Software\Neovide' -Recurse -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $registeredApplicationsKey -Name 'Neovide' -ErrorAction SilentlyContinue
    Remove-Item $appPathKey -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $startMenuShortcut -Force -ErrorAction SilentlyContinue
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
$escapedNvim = $nvim.Replace('\', '\\')
$configLines = @($configLines | Where-Object { $_ -notmatch '^\s*neovim-bin\s*=' })
$configLines = @($configLines | Where-Object { $_ -notmatch '^\s*\[font\]\s*$' -and $_ -notmatch '^\s*(normal|size)\s*=' })
$configLines += @(
    ('neovim-bin = "{0}"' -f $escapedNvim),
    'tabs = false',
    '',
    '[font]',
    'normal = ["JetBrainsMonoNL NF"]',
    'size = 10.0'
)
[System.IO.File]::WriteAllText($configPath, (($configLines -join "`r`n") + "`r`n"), [System.Text.UTF8Encoding]::new($false))

$command = '"{0}" --reuse-instance "%1"' -f $neovide
New-Item -Path $appKey -Force | Out-Null
New-ItemProperty -Path $appKey -Name 'FriendlyAppName' -PropertyType String -Value 'Neovide' -Force | Out-Null
New-Item -Path "$appKey\shell\open\command" -Force | Out-Null
Set-Item -Path "$appKey\shell\open\command" -Value $command
New-Item -Path "$appKey\SupportedTypes" -Force | Out-Null
$neovideIcon = Join-Path (Split-Path $neovide -Parent) 'neovide.ico'
if (Test-Path $neovideIcon) {
    New-Item -Path "$appKey\DefaultIcon" -Force | Out-Null
    Set-Item -Path "$appKey\DefaultIcon" -Value ('"{0}",0' -f $neovideIcon)
}
New-Item -Path "$progIdKey\shell\open\command" -Force | Out-Null
Set-Item -Path "$progIdKey\shell\open\command" -Value $command
# Register Neovide as a Windows app so it can be found in the Start menu and
# the modern Default apps picker, which does not rely only on OpenWithProgids.
New-Item -Path $capabilitiesKey -Force | Out-Null
New-ItemProperty -Path $capabilitiesKey -Name 'ApplicationName' -PropertyType String -Value 'Neovide' -Force | Out-Null
New-ItemProperty -Path $capabilitiesKey -Name 'ApplicationDescription' -PropertyType String -Value 'Neovide GUI for Neovim' -Force | Out-Null
New-Item -Path "$capabilitiesKey\FileAssociations" -Force | Out-Null
New-Item -Path $registeredApplicationsKey -Force | Out-Null
New-ItemProperty -Path $registeredApplicationsKey -Name 'Neovide' -PropertyType String -Value 'Software\Neovide\Capabilities' -Force | Out-Null
New-Item -Path $appPathKey -Force | Out-Null
Set-Item -Path $appPathKey -Value $neovide
Set-ItemProperty -Path $appPathKey -Name 'Path' -Value (Split-Path $neovide -Parent)

$startMenuDirectory = Split-Path $startMenuShortcut -Parent
New-Item -Path $startMenuDirectory -ItemType Directory -Force | Out-Null
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($startMenuShortcut)
$shortcut.TargetPath = $neovide
$shortcut.Arguments = '--reuse-instance'
$shortcut.IconLocation = if (Test-Path $neovideIcon) { '{0},0' -f $neovideIcon } else { '{0},0' -f $neovide }
$shortcut.Save()

foreach ($extension in $extensions) {
    New-ItemProperty -Path "$appKey\SupportedTypes" -Name $extension -PropertyType String -Value '' -Force | Out-Null
    $extensionProgId = Get-NeovideProgId $extension
    $extensionProgIdKey = "HKCU:\Software\Classes\$extensionProgId"
    New-Item -Path $extensionProgIdKey -Force | Out-Null
    New-Item -Path "$extensionProgIdKey\shell\open\command" -Force | Out-Null
    Set-Item -Path "$extensionProgIdKey\shell\open\command" -Value $command

    $originalIcon = $null
    if ($extension -in @('.py', '.pyw')) {
        $pythonIconKey = Get-Item 'Registry::HKEY_CLASSES_ROOT\Python.File\DefaultIcon' -ErrorAction SilentlyContinue
        $originalIcon = if ($pythonIconKey) { [string] $pythonIconKey.GetValue('') } else { '"C:\WINDOWS\py.exe",1' }
    } else {
        $extensionClass = Get-Item "Registry::HKEY_CLASSES_ROOT\$extension" -ErrorAction SilentlyContinue
        $originalProgId = if ($extensionClass) { [string] $extensionClass.GetValue('') } else { '' }
        if ($originalProgId -and $originalProgId -notlike 'Neovide.*') {
            $originalIconKey = Get-Item "Registry::HKEY_CLASSES_ROOT\$originalProgId\DefaultIcon" -ErrorAction SilentlyContinue
            if ($originalIconKey) {
                $originalIcon = [string] $originalIconKey.GetValue('')
            }
        }
    }
    # Always assign a per-file-type icon. If the current Windows association has
    # no explicit icon, use the neutral generic document icon so Explorer does
    # not fall back to the Neovide application icon for the associated file.
    if (-not $originalIcon) {
        $originalIcon = ('"{0}\System32\imageres.dll",-102' -f $env:SystemRoot)
    }
    New-Item -Path "$extensionProgIdKey\DefaultIcon" -Force | Out-Null
    Set-Item -Path "$extensionProgIdKey\DefaultIcon" -Value $originalIcon
    New-ItemProperty -Path $extensionProgIdKey -Name 'FriendlyTypeName' -PropertyType String -Value ("{0} source file" -f $extension.TrimStart('.').ToUpperInvariant()) -Force | Out-Null

    New-ItemProperty -Path "$capabilitiesKey\FileAssociations" -Name $extension -PropertyType String -Value $extensionProgId -Force | Out-Null
    $key = "HKCU:\Software\Classes\$extension\OpenWithProgids"
    New-Item -Path $key -Force | Out-Null
    New-ItemProperty -Path $key -Name $extensionProgId -PropertyType None -Value ([byte[]]@()) -Force | Out-Null

    # Windows Explorer also keeps an explicit per-extension Open with list.
    # Add Neovide there so it appears in the picker for existing file types.
    $fileExtKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$extension"
    $fileExtProgIds = Join-Path $fileExtKey 'OpenWithProgids'
    if (-not (Test-Path $fileExtProgIds)) {
        New-Item -Path $fileExtProgIds -Force | Out-Null
    }
    New-ItemProperty -Path $fileExtProgIds -Name $extensionProgId -PropertyType None -Value ([byte[]]@()) -Force | Out-Null

    $openWithList = Join-Path $fileExtKey 'OpenWithList'
    if (-not (Test-Path $openWithList)) {
        New-Item -Path $openWithList -Force | Out-Null
    }
    $list = Get-Item $openWithList
    $hasNeovide = @($list.GetValueNames() | Where-Object { $_ -match '^[a-z]$' -and $list.GetValue($_) -ieq 'neovide.exe' }).Count -gt 0
    if (-not $hasNeovide) {
        $usedSlots = @($list.GetValueNames() | Where-Object { $_ -match '^[a-z]$' })
        $slot = @('a'..'z' | Where-Object { $_ -notin $usedSlots } | Select-Object -First 1)[0]
        if ($slot) {
            New-ItemProperty -Path $openWithList -Name $slot -PropertyType String -Value 'neovide.exe' -Force | Out-Null
            $mru = [string] $list.GetValue('MRUList', '')
            Set-ItemProperty -Path $openWithList -Name 'MRUList' -Value ($mru + $slot)
        }
    }
}

Write-Host "Registered Neovide ($neovide) in Open with for source and config file extensions."
Write-Host 'Choose Neovide as the default for selected extensions in Windows Settings > Apps > Default apps.'
Start-Process 'ms-settings:defaultapps'
