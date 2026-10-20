param(
    [string]$CsvPath = "tables/supplementary/table2/source_data/01_ST2_existing_values.csv",
    [string]$OutputPrefix = "build/tables/supplementary/table2/gcamp_parameter_table",
    [string]$TablePath = "build/tables/supplementary/table2/gcamp_parameter_table.tex",
    [string]$OutputPdf = "build/tables/supplementary/table2/gcamp_parameter_table.pdf",
    [string]$PythonExe = "python",
    [switch]$KeepBuildDir,
    [switch]$ShowCompilerOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Get-Command pdflatex -ErrorAction SilentlyContinue)) {
    throw "pdflatex not found. Install MiKTeX/TeX Live to render PDF."
}

if (-not (Get-Command $PythonExe -ErrorAction SilentlyContinue)) {
    throw "python not found at '$PythonExe'. Activate the project environment or pass -PythonExe."
}

# Render the reviewed canonical CSV; JSON analysis inputs remain an explicit upstream option.
$makeScript = Join-Path $PSScriptRoot "make_gcamp_params_table.py"
if (-not (Test-Path -LiteralPath $makeScript)) {
    throw "Missing table generator script: $makeScript"
}
& $PythonExe $makeScript --input-csv $CsvPath --output-prefix $OutputPrefix | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Failed to generate Table 3 CSV and TeX from the canonical source-data CSV."
}

if (-not (Test-Path -LiteralPath $TablePath)) {
    throw "Table file not found: $TablePath"
}

$tableFull = (Resolve-Path -LiteralPath $TablePath).Path
$outputFull = [System.IO.Path]::GetFullPath($OutputPdf)
$outputDir = Split-Path -Parent $outputFull
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}
$outputStem = [System.IO.Path]::GetFileNameWithoutExtension($outputFull)

$buildDir = Join-Path $outputDir (".latex_build_gcamp_table_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $buildDir | Out-Null

$pdflatexCombinedLog = Join-Path $outputDir ($outputStem + ".pdflatex.log")
$latexEngineLog = Join-Path $outputDir ($outputStem + ".latex.log")

$wrapperTex = Join-Path $buildDir "gcamp_parameter_table_wrapper.tex"
$tableForTex = $tableFull.Replace("\", "/")
$doc = @"
\documentclass[10pt]{article}
\usepackage[margin=0.75in]{geometry}
\usepackage{booktabs}
\usepackage{xcolor}
\begin{document}
\pagestyle{empty}
\setcounter{table}{2}
\input{$tableForTex}
\end{document}
"@
Set-Content -LiteralPath $wrapperTex -Value $doc -Encoding UTF8

Push-Location $buildDir
try {
    $pass1Out = Join-Path $buildDir "pdflatex_pass1.stdout.log"
    $pass2Out = Join-Path $buildDir "pdflatex_pass2.stdout.log"
    $texLogPath = Join-Path $buildDir "gcamp_parameter_table_wrapper.log"

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

    # Run pdflatex directly to avoid latexmk's Perl dependency.
    if ($ShowCompilerOutput) {
        & pdflatex -file-line-error -interaction=nonstopmode -halt-on-error "gcamp_parameter_table_wrapper.tex" 2>&1 | Tee-Object -FilePath $pass1Out
    }
    else {
        & pdflatex -file-line-error -interaction=batchmode -halt-on-error "gcamp_parameter_table_wrapper.tex" *> $pass1Out
    }
    if ($LASTEXITCODE -ne 0) {
        Publish-Logs -Pass1Path $pass1Out -Pass2Path $pass2Out -TexLogSource $texLogPath -PdflatexCombinedDest $pdflatexCombinedLog -LatexLogDest $latexEngineLog
        $fatalSummary = (Get-FatalLatexLines -LogPath $texLogPath) -join [Environment]::NewLine
        throw "pdflatex failed on pass 1 with exit code $LASTEXITCODE.`n$fatalSummary`nFull logs: $latexEngineLog ; $pdflatexCombinedLog"
    }

    # Second pass to resolve table numbering/labels consistently.
    if ($ShowCompilerOutput) {
        & pdflatex -file-line-error -interaction=nonstopmode -halt-on-error "gcamp_parameter_table_wrapper.tex" 2>&1 | Tee-Object -FilePath $pass2Out
    }
    else {
        & pdflatex -file-line-error -interaction=batchmode -halt-on-error "gcamp_parameter_table_wrapper.tex" *> $pass2Out
    }
    if ($LASTEXITCODE -ne 0) {
        Publish-Logs -Pass1Path $pass1Out -Pass2Path $pass2Out -TexLogSource $texLogPath -PdflatexCombinedDest $pdflatexCombinedLog -LatexLogDest $latexEngineLog
        $fatalSummary = (Get-FatalLatexLines -LogPath $texLogPath) -join [Environment]::NewLine
        throw "pdflatex failed on pass 2 with exit code $LASTEXITCODE.`n$fatalSummary`nFull logs: $latexEngineLog ; $pdflatexCombinedLog"
    }

    $builtPdf = Join-Path $buildDir "gcamp_parameter_table_wrapper.pdf"
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
