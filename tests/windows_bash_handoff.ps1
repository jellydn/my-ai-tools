#Requires -Version 5.1
# Run the public wrapper with real Windows prerequisites and Git Bash, but no tool installs.
param([string]$Installer = (Join-Path $PSScriptRoot '..\install.ps1'))

$ErrorActionPreference = 'Stop'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('Windows handoff ' + [IO.Path]::GetRandomFileName())
$originalPath = $env:Path
$originalBashPath = $env:ORIGINAL_PATH
try {
    New-Item -ItemType Directory -Path $fixture | Out-Null
    Copy-Item $Installer (Join-Path $fixture 'install.ps1')
    # This replaces only cli.sh: the wrapper must discover real tools and pass them to Bash.
    @'
#!/bin/bash
set -e
case " $* " in *" --yes "*) ;; *) echo 'Missing --yes'; exit 21 ;; esac
command -v node
command -v npm
command -v git
command -v jq
node --version
npm --version
test "$(node -p '6 * 7')" = 42
echo 'PASS: real Git Bash received Node and npm'
'@ | Set-Content (Join-Path $fixture 'cli.sh') -Encoding ASCII

    # Model a terminal opened before installation, including an older Git Bash login PATH.
    $env:Path = "$env:SystemRoot\System32;$env:SystemRoot"
    $env:ORIGINAL_PATH = '/usr/bin:/c/Windows/System32'
    foreach ($mode in @('saved-yes', 'one-line-default')) {
        if ($mode -eq 'saved-yes') {
            $output = & "$PSHOME\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File (
                Join-Path $fixture 'install.ps1') -DryRun -Yes 2>&1
        }
        else {
            # IEX defaults to --yes. Replace only the network clone with the safe cli.sh fixture.
            $path = $fixture.Replace("'", "''")
            $code = @"
function git {
    if (`$args[0] -ne 'clone') { throw 'Unexpected Git invocation' }
    Copy-Item '$path\cli.sh' (Join-Path `$args[-1] 'cli.sh')
    `$global:LASTEXITCODE = 0
}
Get-Content -Raw '$path\install.ps1' | Invoke-Expression
"@
            $output = & "$PSHOME\powershell.exe" -NoProfile -Command $code 2>&1
        }
        $result = $LASTEXITCODE
        $output | Out-Host
        if ($result -ne 0 -or ($output -join "`n") -notmatch 'PASS: real Git Bash received Node and npm') {
            throw "Bash handoff failed for $mode (exit $result)"
        }
        [Console]::WriteLine("PASS: $mode with stale Windows and Git Bash PATH")
    }
}
finally {
    $env:Path = $originalPath
    $env:ORIGINAL_PATH = $originalBashPath
    if (Test-Path $fixture) { Remove-Item $fixture -Recurse -Force }
}
$global:LASTEXITCODE = 0
