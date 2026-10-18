#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Windows PowerShell installer for my-ai-tools
.DESCRIPTION
    This script sets up the environment and runs the bash-based installer on Windows.
    It handles:
    - Git for Windows and jq installation via winget
    - Current-process PATH setup and executable discovery
    - Proper bash invocation with Windows paths
.NOTES
    File Name      : install.ps1
    Author         : my-ai-tools
    Prerequisite   : PowerShell 5.1 or later, winget or preinstalled Git and jq
.LINK
    https://github.com/jellydn/my-ai-tools
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Backup,
    [switch]$NoBackup,
    [switch]$Yes,
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
            if ($isNonInteractive) {
                $bashArguments = if ($arguments.Count -gt 0) { $arguments -join ' ' } else { '' }
                & $bashPath -lc "bash cli.sh $bashArguments </dev/null"
            }
            else {
                & $bashPath "cli.sh" @arguments
            }
            $exitCode = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }
    }
    finally {
        if ($tempDir -and (Test-Path $tempDir)) {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }

    if ($exitCode -eq 0) {
        Write-Success "Installation completed successfully!"
        Write-Info "Next steps:"
        Write-Info "  1. Restart your terminal"
        Write-Info "  2. Run 'claude' to start Claude Code"
        Write-Info "  3. Check the README.md for more information"
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
