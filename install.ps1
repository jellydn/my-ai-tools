#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Windows PowerShell installer for my-ai-tools
.DESCRIPTION
    This script sets up the environment and runs the bash-based installer on Windows.
    It handles:
    - Git Bash detection and PATH setup
    - jq installation via winget
    - Proper bash invocation with Windows paths
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
    [switch]$Verbose,
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

# Check if running on Windows
$IsWindowsOS = $env:OS -eq "Windows_NT" -or $IsWindows

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

# Install jq using winget
function Install-Jq {
    Write-Info "Checking for jq installation..."

    $jqInPath = Get-Command jq -ErrorAction SilentlyContinue
    if ($jqInPath) {
        Write-Success "jq found at: $($jqInPath.Source)"
        return $true
    }

    Write-Warn "jq not found. Attempting to install via winget..."

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Err "winget not found. Please install jq manually:"
        Write-Info "  1. Download from: https://github.com/jqlang/jq/releases"
        Write-Info "  2. Extract jq.exe to a folder in your PATH"
        return $false
    }

    try {
        # Install jq using winget
        Write-Info "Installing jq via winget..."
        & winget install -e --id jqlang.jq --accept-package-agreements --accept-source-agreements

        # Refresh environment variables
        Write-Info "Refreshing PATH environment variable..."
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        # Check if jq is now available
        $jqInPath = Get-Command jq -ErrorAction SilentlyContinue
        if ($jqInPath) {
            Write-Success "jq installed successfully at: $($jqInPath.Source)"
            return $true
        }

        # Try common installation paths
        $jqPaths = @(
            "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe\jq.exe"
            "$env:PROGRAMFILES\jq\jq.exe"
            "$env:PROGRAMFILES\WinGet\Links\jq.exe"
            "$env:LOCALAPPDATA\Microsoft\WinGet\Links\jq.exe"
        )

        foreach ($jqPath in $jqPaths) {
            if (Test-Path $jqPath) {
                $jqDir = Split-Path $jqPath -Parent
                Write-Info "Adding jq directory to PATH: $jqDir"
                $env:Path = "$jqDir;$env:Path"
                Write-Success "jq found at: $jqPath"
                return $true
            }
        }

        Write-Warn "jq was installed but not found in PATH. Please restart your terminal."
        return $false
    }
    catch {
        Write-Err "Failed to install jq: $_"
        Write-Info "Please install jq manually from: https://github.com/jqlang/jq/releases"
        return $false
    }
}

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."

    $issues = @()

    # Check Git
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        $issues += "Git is not installed. Install from: https://git-scm.com/download/win"
    } else {
        Write-Success "Git found at: $($git.Source)"
    }

    # Check Git Bash
    $bashPath = Find-GitBash
    if (-not $bashPath) {
        $issues += "Git Bash not found. Install Git for Windows: https://git-scm.com/download/win"
    } else {
        Write-Success "Git Bash found at: $bashPath"
    }

    # Check/Install jq
    $jqInstalled = Install-Jq
    if (-not $jqInstalled) {
        $issues += "jq installation failed. Some features may not work."
    }

    if ($issues.Count -gt 0) {
        Write-Err "Prerequisites check failed:"
        foreach ($issue in $issues) {
            Write-Err "  - $issue"
        }
        return $false
    }

    Write-Success "All prerequisites met"
    return $true
}

# Main installation function
function Start-Installation {
    # Build argument array for cli.sh
    $arguments = @()
    if ($DryRun) { $arguments += "--dry-run" }
    if ($Backup) { $arguments += "--backup" }
    if ($NoBackup) { $arguments += "--no-backup" }
    if ($Yes) { $arguments += "--yes" }
    if ($Verbose) { $arguments += "--verbose" }
    if ($Rollback) { $arguments += "--rollback" }

    # Find Git Bash
    $bashPath = Find-GitBash
    if (-not $bashPath) {
        Write-Err "Git Bash not found"
        Write-Info "Please install Git for Windows: https://git-scm.com/download/win"
        Write-Info "After installation, add Git\bin to your PATH: C:\Program Files\Git\bin"
        exit 1
    }

    # Check if we're in the repo directory (cli.sh exists)
    $repoDir = $PSScriptRoot
    $cliScript = Join-Path $repoDir "cli.sh"

    if (Test-Path $cliScript) {
        # Local execution - run cli.sh directly
        Write-Info "Running local cli.sh..."
        Write-Info "Bash path: $bashPath"
        Write-Info "Arguments: $($arguments -join ' ')"

        & $bashPath $cliScript @arguments
    } else {
        # Remote execution - clone and run
        Write-Info "Repository not found locally. Cloning from GitHub..."

        $tempDir = [System.IO.Path]::GetTempFileName()
        Remove-Item $tempDir
        New-Item -ItemType Directory -Path $tempDir | Out-Null

        try {
            # Clone repository
            Write-Info "Cloning my-ai-tools repository..."
            & git clone --depth 1 https://github.com/jellydn/my-ai-tools.git $tempDir

            if ($LASTEXITCODE -ne 0) {
                Write-Err "Failed to clone repository"
                exit 1
            }

            Write-Success "Repository cloned successfully"

            # Run the installer
            $cliScript = Join-Path $tempDir "cli.sh"
            Write-Info "Running installer..."

            & $bashPath $cliScript @arguments
        }
        finally {
            # Cleanup
            if (Test-Path $tempDir) {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }
    }

    $exitCode = $LASTEXITCODE

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
╔══════════════════════════════════════════════════════════════════════╗
║                    AI Tools Setup - Windows                          ║
║  PowerShell wrapper for Windows installation                        ║
╚══════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Check prerequisites
if (-not (Test-Prerequisites)) {
    Write-Err "Prerequisites check failed. Please install the required tools and try again."
    exit 1
}

Write-Host ""

# Start installation
Start-Installation
