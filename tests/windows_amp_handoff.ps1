#Requires -Version 5.1
# Test the wrapper's Amp participation check without installing software.
param([ValidateSet('', 'selected-missing', 'declined-broken', 'declined-shadowed')][string]$Case = '')

$ErrorActionPreference = 'Stop'
if (-not $Case) {
    $powershell = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    foreach ($scenario in @('selected-missing', 'declined-broken', 'declined-shadowed')) {
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
    $global:LASTEXITCODE = 0
}
try {
    New-Item -ItemType Directory -Path $fixture | Out-Null
    $env:AMP_HOME = Join-Path $fixture 'official amp'
    if ($Case -ne 'selected-missing') {
        $bin = Join-Path $env:AMP_HOME 'bin'
        New-Item -ItemType Directory -Path $bin -Force | Out-Null
        New-Item -ItemType File -Path (Join-Path $bin 'amp.exe') | Out-Null
        # Either a failing version or a higher-priority command would fail this check.
        function Test-AmpCommand { return $false }
    }
    $Yes = $Case -eq 'selected-missing'
    Start-Installation
}
finally {
    $env:AMP_HOME = $originalAmpHome
    if (Test-Path $fixture) { Remove-Item $fixture -Recurse -Force }
}
