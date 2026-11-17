#Requires -Version 5.1
# Exercise prerequisite setup without installing software or running cli.sh.
param([string]$Installer = (Join-Path $PSScriptRoot '..\install.ps1'))

$ErrorActionPreference = 'Stop'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path $Installer), [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
foreach ($definition in $ast.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $false)) {
    . ([scriptblock]::Create($definition.Extent.Text))
}

$originalPath = $env:Path
$originalLocalAppData = $env:LOCALAPPDATA
$originalProgramFiles = $env:ProgramFiles
$originalProgramFilesX86 = ${env:ProgramFiles(x86)}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function New-ExecutableFixture {
    param([string]$Path)
    New-Item -ItemType Directory -Path (Split-Path $Path -Parent) -Force | Out-Null
    New-Item -ItemType File -Path $Path -Force | Out-Null
}

function Reset-Fixture {
    $script:caseRoot = Join-Path $fixture ([IO.Path]::GetRandomFileName())
    $env:LOCALAPPDATA = Join-Path $caseRoot 'Local AppData'
    $env:ProgramFiles = Join-Path $caseRoot 'Program Files'
    ${env:ProgramFiles(x86)} = Join-Path $caseRoot 'Program Files (x86)'
    $env:Path = 'C:\process-only;C:\PROCESS-ONLY'
    $script:DryRun = $false
    $script:wingetAvailable = $true
    $script:wingetExitCode = 0
    $script:createInstalledFiles = $true
    $script:installedPackages = @()
    $script:commands = @{}
    $script:registryRoot = $null
    $script:messages = @()
}

# Deliberately keep command lookup stale after winget: discovery must use the disk.
function Get-Command {
    param($Name, $CommandType, $ErrorAction)
    if ($Name -in @('winget', 'winget.exe') -and $script:wingetAvailable) {
        return [pscustomobject]@{ Source = 'Invoke-FixtureWinget' }
    }
    if ($script:commands.ContainsKey($Name)) {
        return [pscustomobject]@{ Source = $script:commands[$Name] }
    }
}

function Get-ItemProperty {
    param($Path, $ErrorAction)
    if ($script:registryRoot -and $Path -eq 'HKCU:\SOFTWARE\GitForWindows') {
        return [pscustomobject]@{ InstallPath = $script:registryRoot }
    }
}

function Write-Host {
    param($Object, $ForegroundColor)
    $script:messages += [string]$Object
}

function Invoke-FixtureWinget {
    $arguments = @($args)
    foreach ($option in @('--exact', '--silent', '--disable-interactivity', '--no-upgrade',
            '--accept-package-agreements', '--accept-source-agreements')) {
        Assert-True ($arguments -contains $option) "Missing safe winget option: $option"
    }
    Assert-True ($arguments[0] -eq 'install') 'Expected winget install'
    Assert-True ($arguments[$arguments.IndexOf('--source') + 1] -eq 'winget') 'Must avoid msstore'
    $id = $arguments[$arguments.IndexOf('--id') + 1]
    $script:installedPackages += $id
    if ($script:createInstalledFiles) {
        switch ($id) {
            'Git.Git' {
                New-ExecutableFixture (Join-Path $env:ProgramFiles 'Git\cmd\git.exe')
                New-ExecutableFixture (Join-Path $env:ProgramFiles 'Git\bin\bash.exe')
            }
            'jqlang.jq' {
                New-ExecutableFixture (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\jqlang.jq_NewSource\jq.exe')
            }
            'OpenJS.NodeJS.LTS' {
                New-ExecutableFixture (Join-Path $env:ProgramFiles 'nodejs\node.exe')
                New-ExecutableFixture (Join-Path $env:ProgramFiles 'nodejs\npm.cmd')
            }
            default { throw "Unexpected package: $id" }
        }
    }
    $global:LASTEXITCODE = $script:wingetExitCode
    # Native output must not leak into the prerequisite boolean result.
    'winget fixture output'
}

function Assert-ProcessPathContains {
    param([string]$Directory)
    Assert-True (($env:Path -split ';') -contains $Directory) "Child process PATH lacks $Directory"
}

try {
    Reset-Fixture
    Assert-True (Test-Prerequisites) 'Fresh install must continue without a terminal restart'
    Assert-ProcessPathContains (Join-Path $env:ProgramFiles 'Git\cmd')
    Assert-ProcessPathContains (Join-Path $env:ProgramFiles 'Git\bin')
    Assert-ProcessPathContains (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\jqlang.jq_NewSource')
    Assert-ProcessPathContains (Join-Path $env:ProgramFiles 'nodejs')
    Assert-ProcessPathContains 'C:\process-only'
    Assert-True ((@($env:Path -split ';' | Where-Object { $_ -ieq 'C:\process-only' })).Count -eq 1) 'PATH must be deduplicated'
    Assert-True (($script:installedPackages -join ',') -eq 'Git.Git,jqlang.jq,OpenJS.NodeJS.LTS') 'All prerequisites must be installed'
    Assert-True (Test-Prerequisites) 'Repeated installation must succeed'
    Assert-True ($script:installedPackages.Count -eq 3) 'Repeated run must not reinstall existing packages'
    Assert-True (-not (($script:messages -join "`n") -match 'close all terminal')) 'Successful discovery must not request a restart'
    [Console]::WriteLine('PASS: fresh install, stale PATH, inherited PATH, idempotence')

    Reset-Fixture
    $script:DryRun = $true
    Assert-True (-not (Test-Prerequisites)) 'Dry-run needs Git Bash to run cli.sh'
    Assert-True ($script:installedPackages.Count -eq 0) 'Dry-run must not install prerequisites'
    Assert-True (-not (Test-Path $caseRoot)) 'Dry-run must not create installation files'
    [Console]::WriteLine('PASS: missing prerequisites in dry-run cause no installation')

    Reset-Fixture
    $script:registryRoot = Join-Path $caseRoot 'Custom Git'
    New-ExecutableFixture (Join-Path $script:registryRoot 'cmd\git.exe')
    New-ExecutableFixture (Join-Path $script:registryRoot 'bin\bash.exe')
    New-ExecutableFixture (Join-Path $env:ProgramFiles 'WinGet\Links\jq.exe')
    New-ExecutableFixture (Join-Path $env:ProgramFiles 'nodejs\node.exe')
    New-ExecutableFixture (Join-Path $env:ProgramFiles 'nodejs\npm.cmd')
    $script:wingetAvailable = $false
    Assert-True (Test-Prerequisites) 'Custom Git and machine jq must work without winget'
    Assert-ProcessPathContains (Join-Path $script:registryRoot 'cmd')
    Assert-ProcessPathContains (Join-Path $env:ProgramFiles 'WinGet\Links')
    [Console]::WriteLine('PASS: registered custom Git and machine-scope jq without winget')

    Reset-Fixture
    $script:commands['bash'] = 'C:\Windows\System32\bash.exe'
    $script:commands['git.exe'] = Join-Path $caseRoot 'Portable Git\cmd\git.exe'
    New-ExecutableFixture $script:commands['git.exe']
    New-ExecutableFixture (Join-Path $caseRoot 'Portable Git\bin\bash.exe')
    $script:commands['jq.exe'] = 'C:\existing\jq.exe'
    $script:commands['node.exe'] = Join-Path $caseRoot 'Portable Node\node.exe'
    New-ExecutableFixture $script:commands['node.exe']
    New-ExecutableFixture (Join-Path $caseRoot 'Portable Node\npm.cmd')
    Assert-True (Test-Prerequisites) 'Git discovered through PATH must work'
    Assert-True ($script:installedPackages.Count -eq 0) 'Existing tools must not be installed again'
    Assert-ProcessPathContains (Join-Path $caseRoot 'Portable Node')
    [Console]::WriteLine('PASS: existing Git on PATH and jq do not trigger installation')

    Reset-Fixture
    New-ExecutableFixture (Join-Path $env:ProgramFiles 'Git\cmd\git.exe')
    New-ExecutableFixture (Join-Path $env:ProgramFiles 'Git\bin\bash.exe')
    $script:commands['jq.exe'] = 'C:\existing\jq.exe'
    New-ExecutableFixture (Join-Path $env:ProgramFiles 'nodejs\node.exe')
    $script:wingetAvailable = $false
    Assert-True (-not (Test-Prerequisites)) 'Node without npm must not pass prerequisites'
    Assert-True (($script:messages -join "`n") -match 'https://nodejs.org/') 'Missing npm needs recovery instructions'
    [Console]::WriteLine('PASS: Node without npm is rejected')

    foreach ($mode in @('missing-winget', 'failed-winget', 'unresolved-install', 'already-installed')) {
        Reset-Fixture
        $script:commands['bash'] = 'C:\Windows\System32\bash.exe'
        $script:wingetAvailable = $mode -ne 'missing-winget'
        $script:createInstalledFiles = $mode -eq 'already-installed'
        $script:wingetExitCode = if ($mode -in @('failed-winget', 'already-installed')) { -1978335189 } else { 0 }
        $result = Test-Prerequisites
        if ($mode -eq 'already-installed') {
            Assert-True $result 'Usable tools must win over a winget already-installed exit code'
        }
        else {
            Assert-True (-not $result) "$mode must not report success or accept WSL bash"
            $output = $script:messages -join "`n"
            Assert-True ($output -match 'https://git-scm.com/download/win') 'Missing Git needs a manual installation path'
            Assert-True ($output -match 'https://jqlang.org/download/') 'Missing jq needs a manual installation path'
            Assert-True ($output -match 'Invoke-RestMethod.*Invoke-Expression') 'Failure needs a re-run command'
            if ($mode -eq 'failed-winget') {
                Assert-True ($output -match 'exit code -1978335189') 'Package failure code must be visible'
            }
        }
        [Console]::WriteLine("PASS: $mode")
    }
}
finally {
    $env:Path = $originalPath
    $env:LOCALAPPDATA = $originalLocalAppData
    $env:ProgramFiles = $originalProgramFiles
    ${env:ProgramFiles(x86)} = $originalProgramFilesX86
    if (Test-Path $fixture) { Remove-Item $fixture -Recurse -Force }
}

# The final fixture simulates a nonzero winget result. Do not let GitHub Actions
# use that mocked native exit code as the result of this successful test suite.
$global:LASTEXITCODE = 0
