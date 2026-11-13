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
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('Amp regression ' + [IO.Path]::GetRandomFileName())
$script:messages = @()
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
    Assert-True (Test-AmpCommand) 'Official binary must pass version verification'
    foreach ($extension in @('ps1', 'cmd')) {
        $shim = Join-Path $npm "amp.$extension"
        'throw "The stale npm shim must never run"' | Set-Content $shim -Encoding ASCII
        $env:Path = "$npm;$bin;$originalPath"
        $script:messages = @()
        Assert-True (-not (Test-AmpCommand)) "Shadowing amp.$extension must not report success"
        $text = $script:messages -join "`n"
        Assert-True ($text.Contains($shim)) 'Diagnostic must name the command taking priority'
        Assert-True ($text.Contains('Get-Command amp -All')) 'Diagnostic must show command discovery'
        Assert-True ($text.Contains('No installation was removed')) 'Diagnostic must explain safe recovery'
        Assert-True (Test-Path $shim) 'The existing installation must not be removed'
        Remove-Item $shim
    }
    $env:Path = "$bin;$originalPath"
    $env:AMP_FIXTURE_FAIL = '1'
    Assert-True (-not (Test-AmpCommand)) 'Nonzero amp version must fail verification'
    Remove-Item Env:AMP_FIXTURE_FAIL
    Remove-Item $exe
    Assert-True (-not (Test-AmpCommand)) 'Missing official binary must fail verification'
    [Console]::WriteLine('PASS: official Amp, npm ps1/cmd shadowing, failing version, missing binary')
}
finally {
    $env:Path = $originalPath
    $env:AMP_HOME = $originalAmpHome
    Remove-Item Env:AMP_FIXTURE_FAIL -ErrorAction SilentlyContinue
    if (Test-Path $fixture) { Remove-Item $fixture -Recurse -Force }
}
$global:LASTEXITCODE = 0
