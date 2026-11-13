#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Windows PowerShell installer for my-ai-tools
.DESCRIPTION
    This script sets up the environment and runs the bash-based installer on Windows.
    It handles:
    - Git for Windows, jq, and Node.js LTS installation via winget
    - Current-process PATH setup and executable discovery
    - Proper bash invocation with Windows paths
.NOTES
    File Name      : install.ps1
    Author         : my-ai-tools
    Prerequisite   : PowerShell 5.1 or later, winget or preinstalled Git, jq, and Node.js/npm
.LINK
    https://github.com/jellydn/my-ai-tools
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Backup,
    [switch]$NoBackup,
    [switch]$Yes,
    [ValidatePattern('^$|^[a-zA-Z0-9_-]+(,[a-zA-Z0-9_-]+)*$')]
    [string]$WithTools = "",
    [switch]$WithIntegrations,
    [switch]$WithoutIntegrations,
    [switch]$Rollback
)

# Error action preference
$ErrorActionPreference = "Stop"

# Logging functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Keep process-only entries (for example Bun) when picking up installer PATH changes.
function Update-ProcessPath {
    param([string[]]$Prepend = @())

    $paths = @()
    $sources = @($Prepend) + @(
        $env:Path
        [Environment]::GetEnvironmentVariable("Path", "Machine")
        [Environment]::GetEnvironmentVariable("Path", "User")
    )
    foreach ($source in $sources) {
        foreach ($entry in ($source -split ';')) {
            $entry = [Environment]::ExpandEnvironmentVariables($entry).Trim().Trim('"')
            if ($entry -and $paths -notcontains $entry) { $paths += $entry }
        }
    }
    $env:Path = $paths -join ';'
}

function Get-GitRoots {
    $git = Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue
    if ($git) { Split-Path (Split-Path $git.Source -Parent) -Parent }
    foreach ($key in @('HKCU:\SOFTWARE\GitForWindows', 'HKLM:\SOFTWARE\GitForWindows',
            'HKLM:\SOFTWARE\WOW6432Node\GitForWindows')) {
        $install = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
        if ($install.InstallPath) { $install.InstallPath }
    }
    if ($env:ProgramFiles) { "${env:ProgramFiles}\Git" }
    if (${env:ProgramFiles(x86)}) { "${env:ProgramFiles(x86)}\Git" }
    if ($env:LOCALAPPDATA) { "${env:LOCALAPPDATA}\Programs\Git" }
}

# Only accept Git Bash, not the Windows WSL bash.exe launcher.
function Find-GitBash {
    foreach ($root in (Get-GitRoots | Select-Object -Unique)) {
        $gitPath = Join-Path $root 'cmd\git.exe'
        $bashPath = Join-Path $root 'bin\bash.exe'
        if ((Test-Path $gitPath -PathType Leaf) -and (Test-Path $bashPath -PathType Leaf)) {
            Update-ProcessPath -Prepend @((Split-Path $gitPath -Parent), (Split-Path $bashPath -Parent))
            return $bashPath
        }
    }
    return $null
}

function Find-Jq {
    $jq = Get-Command jq.exe -CommandType Application -ErrorAction SilentlyContinue
    if ($jq) { return $jq.Source }

    $candidates = @()
    if ($env:LOCALAPPDATA) {
        $candidates += "$env:LOCALAPPDATA\Microsoft\WinGet\Links\jq.exe"
    }
    if ($env:ProgramFiles) {
        $candidates += "$env:ProgramFiles\WinGet\Links\jq.exe", "$env:ProgramFiles\jq\jq.exe"
    }
    # WinGet's portable package directory suffix can change with the source.
    foreach ($packages in @("$env:LOCALAPPDATA\Microsoft\WinGet\Packages",
            "$env:ProgramFiles\WinGet\Packages")) {
        $candidates += Get-ChildItem -Path "$packages\jqlang.jq_*\jq.exe" -File -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName
    }
    foreach ($path in $candidates) {
        if (Test-Path $path -PathType Leaf) {
            Update-ProcessPath -Prepend @((Split-Path $path -Parent))
            return $path
        }
    }
    return $null
}

# Node lifecycle scripts must resolve a real node.exe, even when Bun is installed.
function Find-Node {
    $roots = @()
    $node = Get-Command node.exe -CommandType Application -ErrorAction SilentlyContinue
    if ($node) { $roots += Split-Path $node.Source -Parent }
    $roots += "$env:ProgramFiles\nodejs", "${env:ProgramFiles(x86)}\nodejs",
        "$env:LOCALAPPDATA\Programs\nodejs"
    foreach ($root in ($roots | Select-Object -Unique)) {
        if ((Test-Path "$root\node.exe" -PathType Leaf) -and
            (Test-Path "$root\npm.cmd" -PathType Leaf)) {
            Update-ProcessPath -Prepend @($root)
            return "$root\node.exe"
        }
    }
    return $null
}

function Install-WingetPackage {
    param([string]$Id)

    $winget = Get-Command winget.exe -CommandType Application -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Err "winget is unavailable. Install or update App Installer: https://aka.ms/getwinget"
        return
    }
    try {
        Write-Info "Installing $Id via winget..."
        & $winget.Source install --exact --id $Id --source winget --silent --disable-interactivity --no-upgrade --accept-package-agreements --accept-source-agreements | Out-Host
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "winget returned exit code $LASTEXITCODE for $Id. Checking whether the tools are available."
        }
    }
    catch {
        Write-Warn "Could not install ${Id}: $_"
    }
    Update-ProcessPath
}

function Install-Jq {
    param([bool]$InstallIfMissing = $true)

    $jqPath = Find-Jq
    if (-not $jqPath) {
        if (-not $InstallIfMissing) {
            Write-Warn "jq not found. Dry-run mode will not install it."
            return $true
        }
        Install-WingetPackage -Id 'jqlang.jq'
        $jqPath = Find-Jq
    }
    if ($jqPath) {
        Write-Success "jq found at: $jqPath"
        return $true
    }
    Write-Err "jq is still unavailable. Install with: winget install --exact --id jqlang.jq --source winget"
    Write-Info "Or install jq.exe in PATH from https://jqlang.org/download/"
    return $false
}

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."

    $issues = @()
    Update-ProcessPath
    $bashPath = Find-GitBash
    if (-not $bashPath -and -not $DryRun) {
        Install-WingetPackage -Id 'Git.Git'
        $bashPath = Find-GitBash
    }
    if (-not $bashPath) {
        if ($DryRun) { Write-Warn "Git for Windows not found. Dry-run mode will not install it." }
        $issues += "Git for Windows (including Git Bash) is required to run cli.sh."
        Write-Info "Install with: winget install --exact --id Git.Git --source winget"
        Write-Info "Or use https://git-scm.com/download/win (include Git Bash and command-line Git)."
    } else {
        Write-Success "Git Bash found at: $bashPath"
    }

    # Check/Install jq
    $jqInstalled = Install-Jq -InstallIfMissing:(-not $DryRun)
    if (-not $jqInstalled) {
        $issues += "jq is required but could not be located."
    }

    $nodePath = Find-Node
    if (-not $nodePath -and -not $DryRun) {
        Install-WingetPackage -Id 'OpenJS.NodeJS.LTS'
        $nodePath = Find-Node
    }
    if ($nodePath) {
        Write-Success "Node.js and npm found at: $nodePath"
    } else {
        if ($DryRun) { Write-Warn "Node.js/npm not found. Dry-run mode will not install them." }
        $issues += "Node.js LTS with npm is required for native Windows package installation."
        Write-Info "Install with: winget install --exact --id OpenJS.NodeJS.LTS --source winget"
        Write-Info "Or install Node.js LTS (including npm): https://nodejs.org/"
    }

    if ($issues.Count -gt 0) {
        Write-Err "Prerequisites check failed:"
        foreach ($issue in $issues) {
            Write-Err "  - $issue"
        }
        if (-not $DryRun) {
            Write-Info "If installation succeeded but a tool is still unavailable, close all terminal windows and open PowerShell again."
            Write-Info "Then re-run your saved install.ps1 command with the same options, or run:"
            Write-Info "  Invoke-RestMethod https://ai-tools.itman.fyi/install.ps1 | Invoke-Expression"
            Write-Info "If winget failed, resolve the error above or install the missing tool manually before re-running."
        }
        return $false
    }

    Write-Success "All prerequisites met"
    return $true
}

function Test-NonInteractiveInstall {
    $isInputRedirected = $false

    try {
        $isInputRedirected = [Console]::IsInputRedirected
    }
    catch {
        $isInputRedirected = $false
    }

    return $isInputRedirected -or [string]::IsNullOrEmpty($PSCommandPath)
}

# The PATH a new terminal uses: the Machine value followed by the User value.
function Get-PersistentPathEntries {
    $entries = @()
    foreach ($source in @([Environment]::GetEnvironmentVariable("Path", "Machine"),
            [Environment]::GetEnvironmentVariable("Path", "User"))) {
        foreach ($entry in ($source -split ';')) {
            $entry = [Environment]::ExpandEnvironmentVariables($entry).Trim().Trim('"')
            if ($entry -and $entries -notcontains $entry) { $entries += $entry }
        }
    }
    return $entries
}

# The first amp command a shell finds in the given PATH entries.
function Get-AmpCommandInPath {
    param([string[]]$Entries)

    foreach ($entry in @($Entries)) {
        foreach ($pattern in @('amp.ps1', 'amp.cmd', 'amp.bat', 'amp.exe')) {
            $candidate = Join-Path $entry $pattern
            if (Test-Path $candidate -PathType Leaf) { return $candidate }
        }
    }
    return $null
}

# Git Bash exports a POSIX path; Windows tooling needs a drive-letter path.
function ConvertTo-WindowsPath {
    param([string]$Path)

    if ($Path -match '^/([A-Za-z])/(.*)$') {
        return "$($Matches[1]):\$($Matches[2] -replace '/', '\')"
    }
    return $Path
}

# Git Bash cannot check which command the parent PowerShell will select.
function Test-AmpCommand {
    $ampHome = if ($env:AMP_HOME) { ConvertTo-WindowsPath $env:AMP_HOME } else { Join-Path $env:USERPROFILE '.amp' }
    $ampExe = Join-Path $ampHome 'bin\amp.exe'
    if (-not (Test-Path $ampExe -PathType Leaf)) {
        Write-Err "Official Amp binary not found at $ampExe. See https://ampcode.com/docs/cli"
        return $false
    }
    try {
        $version = & $ampExe version 2>&1
        if ($LASTEXITCODE -ne 0 -or -not ($version -join '').Trim()) {
            throw 'amp version did not succeed with version output'
        }
    }
    catch {
        Write-Err "Could not verify official Amp at ${ampExe}: $_"
        return $false
    }

    # This session: prefer the official binary over a stale shim on PATH.
    $ampBin = Split-Path $ampExe -Parent
    Update-ProcessPath -Prepend @($ampBin)
    $selected = Get-Command amp -ErrorAction SilentlyContinue
    $sessionConflict = $false
    if (-not $selected) {
        Write-Warn "PowerShell does not find an amp command, although the official binary works at $ampExe."
        $sessionConflict = $true
    }
    elseif ($selected.Source -ine $ampExe) {
        Write-Warn "This session selects $($selected.Source) ($($selected.CommandType)) instead of $ampExe."
        $sessionConflict = $true
    }

    # A new terminal composes PATH from the Machine and User values, not from this session.
    $future = Get-AmpCommandInPath -Entries (Get-PersistentPathEntries)
    $futureConflict = $false
    if ($future -and ($future -ine $ampExe)) {
        Write-Warn "A new terminal will select $future before the official Amp binary."
        $futureConflict = $true
    }
    elseif (-not $future) {
        Write-Warn "The official Amp bin directory is not on the persistent PATH, so a new terminal will not find amp."
        $futureConflict = $true
    }

    if ($sessionConflict) {
        Write-Info 'An alias or function must be reviewed separately.'
    }
    if ($sessionConflict -or $futureConflict) {
        Write-Info 'Inspect all commands with: Get-Command amp -All'
        Write-Info "Run the binary directly: & '$($ampExe.Replace("'", "''"))' version"
        Write-Info 'No installation was removed and no execution policy was changed.'
    }
    if ($futureConflict) {
        Write-Info 'For future sessions, use Windows Environment Variables to place the official bin directory before npm, then reopen PowerShell.'
    }
    Write-Success "Amp verified in PowerShell: $($version -join ' ')"
    return $true
}

# Main installation function
function Start-Installation {
    # Build argument array for cli.sh
    $arguments = @()
    $isVerboseRequested = $PSBoundParameters.ContainsKey('Verbose')
    $isNonInteractive = Test-NonInteractiveInstall

    if ($DryRun) { $arguments += "--dry-run" }
    if ($Backup) { $arguments += "--backup" }
    if ($NoBackup) { $arguments += "--no-backup" }
    if ($Yes) { $arguments += "--yes" }
    if ($WithTools) { $arguments += "--with-tools=$WithTools" }
    if ($WithIntegrations -and $WithoutIntegrations) { throw 'Choose only one integration switch.' }
    if ($WithIntegrations) { $arguments += "--with-integrations" }
    if ($WithoutIntegrations) { $arguments += "--without-integrations" }
    if ($isVerboseRequested) { $arguments += "--verbose" }
    if ($Rollback) { $arguments += "--rollback" }

    if ($isNonInteractive -and -not $Yes) {
        $arguments = @("--yes") + $arguments
    }

    # Find Git Bash
    $bashPath = Find-GitBash
    if (-not $bashPath) {
        Write-Err "Git Bash not found"
        Write-Info "Please install Git for Windows: https://git-scm.com/download/win"
        Write-Info "After installation, add Git\bin to your PATH: C:\Program Files\Git\bin"
        exit 1
    }

    $sourceDir = $null
    $tempDir = $null
    $exitCode = 1
    $ampSelected = $false
    $ampStatusFile = $null
    $previousAmpStatusFile = $env:MY_AI_TOOLS_AMP_STATUS_FILE

    if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "cli.sh"))) {
        $sourceDir = $PSScriptRoot
        Write-Info "Using local repository: $sourceDir"
    }
    else {
        $tmpRoot = Join-Path $HOME ".claude\tmp"
        New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null
        $env:TMPDIR = $tmpRoot

        $tempDir = Join-Path $tmpRoot ([System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        $sourceDir = $tempDir
    }

    try {
        # A child shell cannot update this process's environment or report a declined prompt.
        if (-not $DryRun -and -not $Rollback) {
            $ampStatusFile = [IO.Path]::GetTempFileName()
            $env:MY_AI_TOOLS_AMP_STATUS_FILE = $ampStatusFile
        }
        if ($tempDir) {
            Write-Info "Cloning repository to temporary directory..."
            & git clone --depth 1 https://github.com/jellydn/my-ai-tools.git $sourceDir

            if ($LASTEXITCODE -ne 0) {
                Write-Err "Failed to clone repository"
                Write-Info "Please check your internet connection and try again"
                Write-Info "If the problem persists, the repository URL may have changed"
                exit 1
            }

            Write-Success "Repository cloned successfully"
        }

        Write-Info "Running installation script..."
        Write-Info "Bash path: $bashPath"
        Write-Info "Arguments: $($arguments -join ' ')"

        Push-Location $sourceDir
        try {
            # Login profiles can restore a stale ORIGINAL_PATH and hide newly installed tools.
            if ($isNonInteractive) {
                $bashArguments = if ($arguments.Count -gt 0) { $arguments -join ' ' } else { '' }
                & $bashPath --noprofile --norc -c "bash cli.sh $bashArguments </dev/null"
            }
            else {
                & $bashPath --noprofile --norc "cli.sh" @arguments
            }
            $exitCode = $LASTEXITCODE
            if ($ampStatusFile) {
                $ampSelected = 'selected' -eq (Get-Content $ampStatusFile -TotalCount 1)
                if ($ampSelected) {
                    # The Bash side reports the directory it verified, so both sides agree.
                    $ampHome = @(Get-Content $ampStatusFile)[1]
                    if ($ampHome) { $env:AMP_HOME = $ampHome }
                }
            }
        }
        finally {
            Pop-Location
        }
    }
    finally {
        if ($tempDir -and (Test-Path $tempDir)) {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
        if ($ampStatusFile) {
            Remove-Item $ampStatusFile -Force -ErrorAction SilentlyContinue
            $env:MY_AI_TOOLS_AMP_STATUS_FILE = $previousAmpStatusFile
        }
    }

    if ($exitCode -eq 0 -and $ampSelected -and -not (Test-AmpCommand)) {
        $exitCode = 1
    }

    if ($exitCode -eq 0) {
        Write-Success "Installation completed successfully!"
        Write-Info "Next steps:"
        Write-Info "  Run amp, pi, codex, opencode, claude, or grok."
        Write-Info "  Shared skills and applicable MCP/plugin configs are included unless -WithoutIntegrations is set."
        Write-Info "  Optional standalone tools: -WithTools 'fx,cursor'."
        Write-Info "  If a new command is not found, reopen your terminal."
        Write-Info "  See README.md for options and troubleshooting."
    } else {
        Write-Err "Installation failed with exit code: $exitCode"
        exit $exitCode
    }
}

# Main
Write-Host @"
----------------------------------------------------------------------
                    AI Tools Setup - Windows
          PowerShell wrapper for Windows installation
----------------------------------------------------------------------
"@ -ForegroundColor Cyan

Write-Info "Starting my-ai-tools installation..."

# Check prerequisites
if (-not (Test-Prerequisites)) {
    Write-Err "Prerequisites check failed. Please install the required tools and try again."
    exit 1
}

Write-Host ""

# Start installation
Start-Installation
