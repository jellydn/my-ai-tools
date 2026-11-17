#Requires -Version 5.1
# Test the wrapper's Amp participation check without installing software.
param([ValidateSet('', 'selected-missing', 'selected-unicode', 'selected-literal', 'selected-stale-drive', 'declined-broken', 'declined-shadowed')][string]$Case = '')

$ErrorActionPreference = 'Stop'
if (-not $Case) {
    $powershell = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    foreach ($scenario in @('selected-missing', 'selected-unicode', 'selected-literal', 'selected-stale-drive', 'declined-broken', 'declined-shadowed')) {
        $output = & $powershell -NoProfile -File $PSCommandPath -Case $scenario 2>&1
        $result = $LASTEXITCODE
        $expected = if ($scenario -eq 'selected-missing') { 1 } else { 0 }
        if ($result -ne $expected) { throw "$scenario returned $result, expected ${expected}: $output" }
        [Console]::WriteLine("PASS: $scenario returned $expected")
    }
    exit 0
}

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

$fixture = Join-Path ([IO.Path]::GetTempPath()) ('Amp handoff ' + [IO.Path]::GetRandomFileName())
$originalAmpHome = $env:AMP_HOME
function Find-GitBash { return 'Invoke-FixtureBash' }
function Test-NonInteractiveInstall { return $false }
function git {
    if ($args[0] -ne 'clone') { throw 'Unexpected Git invocation' }
    $global:LASTEXITCODE = 0
}
function Invoke-FixtureBash {
    if ($Case -eq 'selected-missing' -and $env:MY_AI_TOOLS_AMP_STATUS_FILE) {
        'selected' | Set-Content $env:MY_AI_TOOLS_AMP_STATUS_FILE -Encoding ASCII
    }
    if ($Case -in @('selected-unicode', 'selected-literal', 'selected-stale-drive')) {
        [IO.File]::WriteAllText($env:MY_AI_TOOLS_AMP_STATUS_FILE,
            "selected`n$expectedAmpHome`n", (New-Object Text.UTF8Encoding($false)))
    }
    $global:LASTEXITCODE = 0
}
try {
    New-Item -ItemType Directory -Path $fixture | Out-Null
    $env:AMP_HOME = Join-Path $fixture 'official amp'
    if ($Case -eq 'selected-literal') { $env:AMP_HOME = Join-Path $fixture 'Amp[stable]' }
    $expectedAmpHome = $env:AMP_HOME
    if ($Case -eq 'selected-unicode') {
        $expectedAmpHome = Join-Path $fixture ('Jos' + [char]0x00E9 + ' official amp')
        # Model a legacy ANSI default, including on PowerShell 7 where UTF-8 is now the default.
        $PSDefaultParameterValues['Get-Content:Encoding'] = if ($PSVersionTable.PSVersion.Major -ge 7) { 1252 } else { 'Default' }
        function Test-AmpCommand {
            if ($env:AMP_HOME -cne $expectedAmpHome) { throw 'Unicode AMP_HOME was corrupted during handoff' }
            return $true
        }
    }
    elseif ($Case -in @('selected-literal', 'selected-stale-drive')) {
        $bin = Join-Path $env:AMP_HOME 'bin'
        New-Item -ItemType Directory -Path $bin -Force | Out-Null
        $exe = Join-Path $bin 'amp.exe'
        if ($env:OS -eq 'Windows_NT') {
            # Add-Type in Windows PowerShell treats brackets in OutputAssembly as wildcards.
            $compiledExe = Join-Path $fixture 'amp-fixture.exe'
            Add-Type -OutputAssembly $compiledExe -OutputType ConsoleApplication -TypeDefinition @'
using System;
public class AmpHandoffFixture {
    public static int Main(string[] args) {
        if (args.Length != 1 || args[0] != "version") return 7;
        Console.WriteLine("handoff-fixture-version");
        return 0;
    }
}
'@
            [IO.File]::Move($compiledExe, $exe)
        }
        else {
            [IO.File]::WriteAllText($exe, "#!/bin/sh`necho handoff-fixture-version`n")
            & /bin/chmod +x $exe
        }
        function Get-PersistentPathEntries { return @('AmpUnavailableDrive:\retired-tools', $bin) }
    }
    elseif ($Case -ne 'selected-missing') {
        $bin = Join-Path $env:AMP_HOME 'bin'
        New-Item -ItemType Directory -Path $bin -Force | Out-Null
        New-Item -ItemType File -Path (Join-Path $bin 'amp.exe') | Out-Null
        # The check must not run at all when Amp was declined, whatever it reports.
        function Test-AmpCommand { return $false }
    }
    $Yes = $Case -like 'selected-*'
    Start-Installation
}
finally {
    $env:AMP_HOME = $originalAmpHome
    if (Test-Path $fixture) { Remove-Item $fixture -Recurse -Force }
}
