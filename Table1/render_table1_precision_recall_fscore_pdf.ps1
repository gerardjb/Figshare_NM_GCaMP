param(
    [string]$SnaPath = "figure4/sna_matching_trials.csv",
    [string]$MatchedPath = "figure4/matched_bias_uncert.csv",
    [string]$CsvPath = "Table1/table1_precision_recall_fscore.csv",
    [string]$TablePath = "Table1/table1_precision_recall_fscore.tex",
    [string]$OutputPdf = "Table1/table1_precision_recall_fscore.pdf",
    [string]$PythonExe = "python",
    [switch]$KeepBuildDir,
    [switch]$ShowCompilerOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Get-Command $PythonExe -ErrorAction SilentlyContinue)) {
    throw "python not found at '$PythonExe'. Activate the project environment or pass -PythonExe."
}
if (-not (Get-Command pdflatex -ErrorAction SilentlyContinue)) {
    throw "pdflatex not found. Install MiKTeX/TeX Live to render PDF."
}

$makeCsvScript = Join-Path $PSScriptRoot "make_table1_precision_recall_fscore_csv.py"
$makeTexScript = Join-Path $PSScriptRoot "make_table1_precision_recall_fscore_tex.py"
if (-not (Test-Path -LiteralPath $makeCsvScript)) {
    throw "Missing statistics generator script: $makeCsvScript"
}
if (-not (Test-Path -LiteralPath $makeTexScript)) {
    throw "Missing TeX generator script: $makeTexScript"
}

# Always regenerate the summary CSV from the Figure 4 artifacts, then use that
# CSV to regenerate the TeX so every downstream representation stays in sync.
& $PythonExe $makeCsvScript --sna $SnaPath --matched $MatchedPath --output-csv $CsvPath | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Failed to calculate Table 1 statistics from the Figure 4 artifacts."
}

& $PythonExe $makeTexScript --csv $CsvPath --output-tex $TablePath | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Failed to generate Table 1 TeX from CSV."
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

$buildDir = Join-Path $outputDir (".latex_build_table1_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $buildDir | Out-Null

$pdflatexCombinedLog = Join-Path $outputDir ($outputStem + ".pdflatex.log")
$latexEngineLog = Join-Path $outputDir ($outputStem + ".latex.log")

$wrapperTex = Join-Path $buildDir "table1_precision_recall_fscore.tex"
Copy-Item -LiteralPath $tableFull -Destination $wrapperTex -Force

function Remove-BuildDir {
    if (-not $KeepBuildDir -and (Test-Path -LiteralPath $buildDir)) {
        try {
            Remove-Item -LiteralPath $buildDir -Recurse -Force -ErrorAction Stop
        }
        catch {
            Write-Warning "Could not remove build directory: $buildDir"
        }
    }
}

try {
Push-Location $buildDir
try {
    $pass1Out = Join-Path $buildDir "pdflatex_pass1.stdout.log"
    $pass2Out = Join-Path $buildDir "pdflatex_pass2.stdout.log"
    $texLogPath = Join-Path $buildDir "table1_precision_recall_fscore.log"

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

    function Invoke-PdflatexPass {
        param(
            [string]$TexFile,
            [string]$StdoutLog
        )

        $oldErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            if ($ShowCompilerOutput) {
                & pdflatex -file-line-error -interaction=nonstopmode -halt-on-error $TexFile 2>&1 | Tee-Object -FilePath $StdoutLog
            }
            else {
                & pdflatex -file-line-error -interaction=batchmode -halt-on-error $TexFile *> $StdoutLog
            }
            return $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $oldErrorActionPreference
        }
    }

    $pass1ExitCode = Invoke-PdflatexPass -TexFile "table1_precision_recall_fscore.tex" -StdoutLog $pass1Out
    if ($pass1ExitCode -ne 0) {
        Publish-Logs -Pass1Path $pass1Out -Pass2Path $pass2Out -TexLogSource $texLogPath -PdflatexCombinedDest $pdflatexCombinedLog -LatexLogDest $latexEngineLog
        $fatalSummary = (Get-FatalLatexLines -LogPath $texLogPath) -join [Environment]::NewLine
        throw "pdflatex failed on pass 1 with exit code $pass1ExitCode.`n$fatalSummary`nFull logs: $latexEngineLog ; $pdflatexCombinedLog"
    }

    $pass2ExitCode = Invoke-PdflatexPass -TexFile "table1_precision_recall_fscore.tex" -StdoutLog $pass2Out
    if ($pass2ExitCode -ne 0) {
        Publish-Logs -Pass1Path $pass1Out -Pass2Path $pass2Out -TexLogSource $texLogPath -PdflatexCombinedDest $pdflatexCombinedLog -LatexLogDest $latexEngineLog
        $fatalSummary = (Get-FatalLatexLines -LogPath $texLogPath) -join [Environment]::NewLine
        throw "pdflatex failed on pass 2 with exit code $pass2ExitCode.`n$fatalSummary`nFull logs: $latexEngineLog ; $pdflatexCombinedLog"
    }

    Publish-Logs -Pass1Path $pass1Out -Pass2Path $pass2Out -TexLogSource $texLogPath -PdflatexCombinedDest $pdflatexCombinedLog -LatexLogDest $latexEngineLog

    $builtPdf = Join-Path $buildDir "table1_precision_recall_fscore.pdf"
    if (-not (Test-Path -LiteralPath $builtPdf)) {
        throw "Compilation completed but PDF was not produced. Logs: $latexEngineLog ; $pdflatexCombinedLog"
    }

    Copy-Item -LiteralPath $builtPdf -Destination $outputFull -Force
}
finally {
    Pop-Location
}
}
finally {
    Remove-BuildDir
}

Write-Output "Wrote PDF: $outputFull"
Write-Output "Saved logs: $latexEngineLog ; $pdflatexCombinedLog"
