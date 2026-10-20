param(
    [string]$TablePath = "build/tables/supplementary/table1/table2_sing_cell_param.tex",
    [string]$OutputPdf = "build/tables/supplementary/table1/table2_sing_cell_param.pdf",
    [switch]$KeepBuildDir,
    [switch]$ShowCompilerOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Get-Command pdflatex -ErrorAction SilentlyContinue)) {
    throw "pdflatex not found. Install MiKTeX/TeX Live to render PDF."
}

if (-not (Test-Path -LiteralPath $TablePath)) {
    throw "Table file not found: $TablePath"
}

$tableFull = (Resolve-Path -LiteralPath $TablePath).Path
$sourceDir = Split-Path -Parent $tableFull
$sourceFile = Split-Path -Leaf $tableFull

$outputFull = [System.IO.Path]::GetFullPath($OutputPdf)
$outputDir = Split-Path -Parent $outputFull
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}
$outputStem = [System.IO.Path]::GetFileNameWithoutExtension($outputFull)

$buildDir = Join-Path $outputDir (".latex_build_Table2_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $buildDir | Out-Null

$pdflatexCombinedLog = Join-Path $outputDir ($outputStem + ".pdflatex.log")
$latexEngineLog = Join-Path $outputDir ($outputStem + ".latex.log")
$builtPdf = Join-Path $buildDir ($outputStem + ".pdf")
$texLogPath = Join-Path $buildDir ($outputStem + ".log")

function Get-FatalLatexLines {
    param([string]$LogPath)
    if (-not (Test-Path -LiteralPath $LogPath)) {
        return @("No LaTeX .log file was created.")
    }

    $lines = Get-Content -LiteralPath $LogPath
    $fatal = @($lines | Where-Object {
        $_ -match '^!' -or
        $_ -match 'LaTeX Error:' -or
        $_ -match 'Emergency stop' -or
        $_ -match 'Fatal error'
    })

    if ($fatal.Count -gt 0) {
        return $fatal | Select-Object -First 12
    }

    return @("No explicit fatal line matched; last 20 log lines:") + ($lines | Select-Object -Last 20)
}

function Publish-Logs {
    param(
        [string]$Pass1Path,
        [string]$Pass2Path,
        [string]$TexLogSource,
        [string]$PdflatexCombinedDest,
        [string]$LatexLogDest
    )

    $pass1Text = if (Test-Path -LiteralPath $Pass1Path) { Get-Content -LiteralPath $Pass1Path -Raw } else { "" }
    $pass2Text = if (Test-Path -LiteralPath $Pass2Path) { Get-Content -LiteralPath $Pass2Path -Raw } else { "" }
    $combined = @(
        "=== pdflatex pass 1 stdout/stderr ==="
        $pass1Text
        ""
        "=== pdflatex pass 2 stdout/stderr ==="
        $pass2Text
    ) -join [Environment]::NewLine
    Set-Content -LiteralPath $PdflatexCombinedDest -Value $combined -Encoding UTF8

    if (Test-Path -LiteralPath $TexLogSource) {
        Copy-Item -LiteralPath $TexLogSource -Destination $LatexLogDest -Force
    }
}

$pass1Out = Join-Path $buildDir "pdflatex_pass1.stdout.log"
$pass2Out = Join-Path $buildDir "pdflatex_pass2.stdout.log"

Push-Location $sourceDir
try {
    if ($ShowCompilerOutput) {
        & pdflatex -file-line-error -interaction=nonstopmode -halt-on-error "-output-directory=$buildDir" $sourceFile 2>&1 | Tee-Object -FilePath $pass1Out
    }
    else {
        & pdflatex -file-line-error -interaction=batchmode -halt-on-error "-output-directory=$buildDir" $sourceFile *> $pass1Out
    }
    if ($LASTEXITCODE -ne 0) {
        Publish-Logs -Pass1Path $pass1Out -Pass2Path $pass2Out -TexLogSource $texLogPath -PdflatexCombinedDest $pdflatexCombinedLog -LatexLogDest $latexEngineLog
        $fatalSummary = (Get-FatalLatexLines -LogPath $texLogPath) -join [Environment]::NewLine
        throw "pdflatex failed on pass 1 with exit code $LASTEXITCODE.`n$fatalSummary`nFull logs: $latexEngineLog ; $pdflatexCombinedLog"
    }

    if ($ShowCompilerOutput) {
        & pdflatex -file-line-error -interaction=nonstopmode -halt-on-error "-output-directory=$buildDir" $sourceFile 2>&1 | Tee-Object -FilePath $pass2Out
    }
    else {
        & pdflatex -file-line-error -interaction=batchmode -halt-on-error "-output-directory=$buildDir" $sourceFile *> $pass2Out
    }
    if ($LASTEXITCODE -ne 0) {
        Publish-Logs -Pass1Path $pass1Out -Pass2Path $pass2Out -TexLogSource $texLogPath -PdflatexCombinedDest $pdflatexCombinedLog -LatexLogDest $latexEngineLog
        $fatalSummary = (Get-FatalLatexLines -LogPath $texLogPath) -join [Environment]::NewLine
        throw "pdflatex failed on pass 2 with exit code $LASTEXITCODE.`n$fatalSummary`nFull logs: $latexEngineLog ; $pdflatexCombinedLog"
    }

    if (-not (Test-Path -LiteralPath $builtPdf)) {
        throw "Compilation completed but PDF was not produced. Logs: $latexEngineLog ; $pdflatexCombinedLog"
    }

    Copy-Item -LiteralPath $builtPdf -Destination $outputFull -Force
}
finally {
    Pop-Location
}

if (-not $KeepBuildDir) {
    try {
        Remove-Item -LiteralPath $buildDir -Recurse -Force -ErrorAction Stop
    }
    catch {
        Write-Warning "Could not remove build directory: $buildDir"
    }
}

Write-Output "Wrote PDF: $outputFull"
