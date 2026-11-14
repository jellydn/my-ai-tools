#Requires -Version 5.1
# Native command-resolution regression: never execute the npm PowerShell shim.
$ErrorActionPreference = 'Stop'
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $PSScriptRoot '..\install.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
foreach ($definition in $ast.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $false)) {
    . ([scriptblock]::Create($definition.Extent.Text))
}

$originalPath = $env:Path
$originalAmpHome = $env:AMP_HOME
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('Amp regression ' + [IO.Path]::GetRandomFileName())
$script:messages = @()
$script:persistentEntries = @()
# The persistent PATH is a registry value, so the fixture controls it.
function Get-PersistentPathEntries { return $script:persistentEntries }
function Write-Host {
    param($Object, $ForegroundColor)
    $script:messages += [string]$Object
}
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}
try {
    $env:AMP_HOME = Join-Path $fixture 'official amp'
    $bin = Join-Path $env:AMP_HOME 'bin'
    $npm = Join-Path $fixture 'AppData\Roaming\npm'
    New-Item -ItemType Directory -Path $bin, $npm -Force | Out-Null
    $exe = Join-Path $bin 'amp.exe'
    Add-Type -OutputAssembly $exe -OutputType ConsoleApplication -TypeDefinition @'
using System;
public class AmpInstallerFixture {
    public static int Main(string[] args) {
        if (args.Length != 1 || args[0] != "version") return 7;
        Console.WriteLine("fixture-version");
        return Environment.GetEnvironmentVariable("AMP_FIXTURE_FAIL") == "1" ? 9 : 0;
    }
}
'@
    $env:Path = "$bin;$originalPath"
    $script:persistentEntries = @($bin)
    Assert-True (Test-AmpCommand) 'Official binary must pass version verification'
    foreach ($extension in @('ps1', 'cmd')) {
        $shim = Join-Path $npm "amp.$extension"
        'throw "The stale npm shim must never run"' | Set-Content $shim -Encoding ASCII
        # The session PATH and the persistent PATH still have the stale shim first.
        $env:Path = "$npm;$bin;$originalPath"
        $script:persistentEntries = @($npm, $bin)
        $script:messages = @()
# The official binary is promoted ahead of the stale shim.
        Assert-True (Test-AmpCommand) "Official Amp must be promoted ahead of amp.$extension"
        Assert-True ((Get-Command amp).Source -ieq $exe) 'PowerShell must now select the official binary'
        Assert-True (($env:Path -split ';')[0] -ieq $bin) 'The official directory must be first in this process'
        Assert-True (($env:Path -split ';') -contains $npm) 'npm must remain available for other tools'
        Assert-True ((amp version) -eq 'fixture-version') 'The selected command must return the official version'
        # A priority conflict is a warning, not a failed setup.
        $text = $script:messages -join "`n"
        Assert-True ($text.Contains($shim)) 'Diagnostic must name the command taking priority'
        Assert-True ($text.Contains('Get-Command amp -All')) 'Diagnostic must show command discovery'
        Assert-True ($text.Contains('No installation was removed')) 'Diagnostic must explain safe recovery'
        Assert-True (Test-Path $shim) 'The existing installation must not be removed'
        Remove-Item $shim
    }
    Assert-True ([Environment]::GetEnvironmentVariable('Path', 'User') -ceq $userPath) 'User PATH must not change'
    Assert-True ([Environment]::GetEnvironmentVariable('Path', 'Machine') -ceq $machinePath) 'Machine PATH must not change'
    # An alias needs manual review, but it does not fail the rest of the setup.
    Set-Alias -Name amp -Value Write-Output -Scope Script
    $script:messages = @()
    Assert-True (Test-AmpCommand) 'A higher-priority alias must not fail the setup'
    Assert-True (($script:messages -join "`n").Contains('Get-Command amp -All')) 'Alias diagnostic must show command discovery'
    Remove-Item Alias:amp
    $env:Path = "$bin;$originalPath"
    $script:persistentEntries = @($bin)
    $script:messages = @()
    Assert-True (Test-AmpCommand) 'The official binary must verify without a conflict'
    Assert-True (-not (($script:messages -join "`n").Contains('A new terminal will select'))) 'No conflict must be reported'
    $env:AMP_FIXTURE_FAIL = '1'
    Assert-True (-not (Test-AmpCommand)) 'Nonzero amp version must fail verification'
    Remove-Item Env:AMP_FIXTURE_FAIL
    Remove-Item $exe
    Assert-True (-not (Test-AmpCommand)) 'Missing official binary must fail verification'
    [Console]::WriteLine('PASS: official Amp, npm ps1/cmd PATH promotion, persistent PATH unchanged, alias detection, failing version, missing binary')
}
finally {
    $env:Path = $originalPath
    $env:AMP_HOME = $originalAmpHome
    Remove-Item Env:AMP_FIXTURE_FAIL -ErrorAction SilentlyContinue
    if (Test-Path $fixture) { Remove-Item $fixture -Recurse -Force }
}
$global:LASTEXITCODE = 0
