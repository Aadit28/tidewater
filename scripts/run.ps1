param([ValidateSet('install','dev','build','preview','typecheck','lint','test','test:browser','test:database')][string]$Task = 'dev')
$ErrorActionPreference = 'Stop'
$bundledNode = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe'
$nodeRuntime = if (Test-Path -LiteralPath $bundledNode) { $bundledNode } else { (Get-Command node).Source }
$nodeVersion = & $nodeRuntime -p 'process.versions.node.split(".")[0]'
if ([int]$nodeVersion -ne 24) { throw 'Use Node.js 24 for this project.' }
$npmDirectory = Split-Path (Get-Command npm.cmd).Source
$npmScript = Join-Path $npmDirectory 'node_modules\npm\bin\npm-cli.js'
if (!(Test-Path -LiteralPath $npmScript)) { throw 'npm CLI not found. Install Node.js 24 with npm.' }
$env:PATH = (Split-Path $nodeRuntime) + ';' + $env:PATH
Push-Location (Split-Path $PSScriptRoot)
try {
 if ($Task -eq 'install') { & $nodeRuntime $npmScript ci } else { & $nodeRuntime $npmScript run $Task }
 exit $LASTEXITCODE
} finally { Pop-Location }
