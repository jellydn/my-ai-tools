#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Windows PowerShell installer for my-ai-tools
.DESCRIPTION
    This script sets up the environment and runs the bash-based installer on Windows.
    It mirrors install.sh while handling Git Bash discovery and PowerShell invocation.
.NOTES
    File Name      : install.ps1
    Author         : my-ai-tools
    Prerequisite   : PowerShell 5.1 or later, Git for Windows
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
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# Find Git Bash
function Find-GitBash {
    $possiblePaths = @(
        "${env:ProgramFiles}\Git\bin\bash.exe"
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe"
        "${env:LOCALAPPDATA}\Programs\Git\bin\bash.exe"
        "C:\Program Files\Git\bin\bash.exe"
        "C:\Program Files (x86)\Git\bin\bash.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    # Try to find in PATH
    $bashInPath = Get-Command bash -ErrorAction SilentlyContinue
    if ($bashInPath) {
        return $bashInPath.Source
    }

    return $null
}

# Check prerequisites
function Test-Prerequisites {
    $missingTools = @()

    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        $missingTools += "git"
    } else {
        Write-Success "Git found at: $($git.Source)"
    }

    $bashPath = Find-GitBash
    if (-not $bashPath) {
        $missingTools += "bash"
    } else {
        Write-Success "Git Bash found at: $bashPath"
    }

    $python3 = Get-Command python3 -ErrorAction SilentlyContinue
    if (-not $python3) {
        Write-Warn "Python 3 not found - MemPalace AI memory will not be available"
        Write-Info "Install Python 3.9+ for MemPalace: https://python.org/downloads"
    }
    else {
        & $python3.Source -m pip --version *> $null
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "pip not found - you may need to install pip for MemPalace"
            Write-Info "Run: python3 -m ensurepip --upgrade"
        }

        & $python3.Source -c "import jsonschema" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Info "python-jsonschema not installed - some config validations will be skipped"
            Write-Info "Install with: pip3 install jsonschema"
        }
    }

    if ($missingTools.Count -gt 0) {
        Write-Err "Missing required tools: $($missingTools -join ' ')"
        Write-Info "Please install the missing tools and try again"
        return $false
    }

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

    $bashPath = Find-GitBash
    if (-not $bashPath) {
        Write-Err "Missing required tools: bash"
        Write-Info "Please install the missing tools and try again"
        exit 1
    }

    $tmpRoot = Join-Path $HOME ".claude\tmp"
    New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null
    $env:TMPDIR = $tmpRoot

    $tempDir = Join-Path $tmpRoot ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    try {
        Write-Info "Cloning repository to temporary directory..."
        & git clone --depth 1 https://github.com/jellydn/my-ai-tools.git $tempDir

        if ($LASTEXITCODE -ne 0) {
            Write-Err "Failed to clone repository"
            Write-Info "Please check your internet connection and try again"
            Write-Info "If the problem persists, the repository URL may have changed"
            exit 1
        }

        Write-Success "Repository cloned successfully"
        Write-Info "Running installation script..."

        Push-Location $tempDir
        try {
            if ($isNonInteractive) {
                $bashCommandParts = @("bash", "cli.sh", "--yes")
                $bashCommandParts += $arguments
                $bashCommand = ($bashCommandParts | ForEach-Object {
                    if ($_ -match '[\s"]') {
                        '"' + ($_ -replace '"', '\"') + '"'
                    }
                    else {
                        $_
                    }
                }) -join ' '
                & $bashPath -lc "$bashCommand </dev/null"
            }
            else {
                & $bashPath "cli.sh" @arguments
            }
        }
        finally {
            Pop-Location
        }
    }
    finally {
        if (Test-Path $tempDir) {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }

    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Success "Installation complete!"
    } else {
        Write-Err "Installation failed with exit code: $exitCode"
        exit $exitCode
    }
}

# Main
Write-Info "Starting my-ai-tools installation..."

# Check prerequisites
if (-not (Test-Prerequisites)) {
    Write-Err "Prerequisites check failed. Please install the required tools and try again."
    exit 1
}

Write-Host ""

# Start installation
Start-Installation
