param(
    [string]$CsvPath = "Table2/Table2_cell_parameters.csv",
    [string]$OutputTex = "Table2/Table2_cell_parameters.tex",
    [string]$Caption = "Single-cell model parameter values.",
    [string]$Label = "tab:single-cell-parameters"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $CsvPath)) {
    throw "CSV not found: $CsvPath"
}

$rows = @(Import-Csv -LiteralPath $CsvPath)
$requiredHeaders = @('RowType', 'Parameter (units)', 'Cell Type', 'Value', 'References')
foreach ($header in $requiredHeaders) {
    if ($rows.Count -eq 0 -or $null -eq $rows[0].PSObject.Properties[$header]) {
        throw "CSV is missing required column: $header"
    }
}

$outFull = [System.IO.Path]::GetFullPath($OutputTex)
$outDir = Split-Path -Parent $outFull
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

function Convert-NewlinesToLatexLinebreaks {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return "" }

    $t = $Text -replace '\\n', "`n"
    if ($t -notmatch "(`r`n|`n|`r)") {
        return $t.Trim()
    }

    $parts = $t -split "`r`n|`n|`r"
    $parts = @($parts | ForEach-Object { $_.TrimEnd() } | Where-Object { $_ -ne "" })
    if ($parts.Count -eq 0) {
        return ""
    }

    $joined = $parts -join "\\\\[-0.3ex]"
    return "\shortstack[c]{$joined}"
}

function Escape-LatexText {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return "" }

    $escaped = $Text
    $escaped = $escaped.Replace('\', '\textbackslash{}')
    $escaped = $escaped.Replace('&', '\&')
    $escaped = $escaped.Replace('%', '\%')
    $escaped = $escaped.Replace('#', '\#')
    $escaped = $escaped.Replace('_', '\_')
    return $escaped
}

function Format-PlainTextCell {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return "" }

    $t = $Text -replace '\\n', "`n"
    $lines = @($t -split "`r`n|`n|`r")
    $lines = @($lines | ForEach-Object { Escape-LatexText -Text $_.TrimEnd() } | Where-Object { $_ -ne "" })
    if ($lines.Count -eq 0) {
        return ""
    }
    if ($lines.Count -eq 1) {
        return $lines[0]
    }

    $joined = $lines -join "\\\\[-0.3ex]"
    return "\shortstack[c]{$joined}"
}

function Format-SectionTitle {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return "" }

    $title = Format-PlainTextCell -Text $Text
    $title = $title.Replace('Ca^{2+}', '$Ca^{2+}$')
    $title = $title.Replace('Mg^{2+}', '$Mg^{2+}$')
    return $title
}

function Format-UnitsForLatex {
    param([AllowNull()][string]$Units)
    if ($null -eq $Units) { return "" }

    $u = $Units.Trim()
    $uCompact = ($u -replace '\s+', '')
    $uLower = $uCompact.ToLower()

    if ($uLower -eq 'microm' -or $uLower -eq 'um') { return '$\mu M$' }
    if ($uLower -eq 's^-1') { return '$s^{-1}$' }
    if ($uLower -eq 'unitless') { return 'unitless' }
    if ($uLower -eq 'microm^-1*s^-1' -or $uLower -eq 'um^-1*s^-1') { return '$\mu M^{-1}\,s^{-1}$' }

    return $u
}

function Split-ParameterAndUnits {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) {
        return @{
            Parameter = ""
            Units = ""
        }
    }

    $t = $Text.Trim()
    if ($t -match '^(?<param>.+?)\s*\((?<units>[^)]*)\)\s*$') {
        return @{
            Parameter = $Matches['param'].Trim()
            Units = $Matches['units'].Trim()
        }
    }

    return @{
        Parameter = $t
        Units = ""
    }
}

function Format-ParameterUnitsCell {
    param([AllowNull()][string]$Text)

    $parts = Split-ParameterAndUnits -Text $Text
    $param = $parts.Parameter
    $units = $parts.Units
    if ($param -eq "") { return "" }

    if ($units -eq "") {
        return '$' + $param + '$'
    }

    $unitsLatex = Format-UnitsForLatex -Units $units
    return '$' + $param + '$ (' + $unitsLatex + ')'
}

function Get-ParameterKey {
    param([AllowNull()][string]$Text)
    $parts = Split-ParameterAndUnits -Text $Text
    return $parts.Parameter
}

function Format-DescriptionLabel {
    param([string]$ParameterKey)
    $label = $ParameterKey.Trim()
    $label = $label.Replace('[', '\lbrack ')
    $label = $label.Replace(']', '\rbrack')
    return '$' + $label + '$'
}

function Get-ParameterDescription {
    param([string]$ParameterKey)

    switch ($ParameterKey) {
        '[GCaMP]' { return 'Total intracellular indicator concentration used in the model.' }
        'R_f' { return 'Apparent fluorescence dynamic range (scaling factor mapping indicator state to measured $\Delta F/F$).' }
        '\Delta Ca_{spike}' { return 'Per-spike calcium increment delivered to the modeled compartment.' }
        'ca_0' { return 'Basal intracellular calcium concentration.' }
        '\gamma' { return 'Effective first-order calcium clearance rate constant.' }
        'Buffer_{Endo}' { return 'Total endogenous calcium buffer concentration.' }
        'k_{on, Endo}' { return 'Calcium binding on-rate to the endogenous buffer.' }
        'k_{off, Endo}' { return 'Calcium unbinding off-rate from the endogenous buffer.' }
        '[ATP]' { return 'Total ATP concentration.' }
        'k_{on, ATP}' { return 'Calcium binding on-rate to the ATP buffer.' }
        'k_{off, ATP}' { return 'Calcium unbinding off-rate from the ATP buffer.' }
        '[Parv]' { return 'Total parvalbumin concentration.' }
        'k_{on, Parv, Ca^{2+}}' { return 'Calcium binding on-rate to the parvalbumin buffer.' }
        'k_{off, Parv, Ca^{2+}}' { return 'Calcium unbinding off-rate from the parvalbumin buffer.' }
        'k_{on, Parv, Mg^{2+}}' { return 'Magnesium binding on-rate to the parvalbumin buffer.' }
        'k_{off, Parv, Mg^{2+}}' { return 'Magnesium unbinding off-rate from the parvalbumin buffer.' }
        default { return '' }
        'mg_0' { return 'Basal intracellular magnesium concentration.' }
    }
}

$entryRows = @($rows | Where-Object { ([string]$_.RowType).Trim().ToLower() -eq 'entry' })
if ($entryRows.Count -eq 0) {
    throw "CSV did not contain any entry rows."
}

$orderedParameterKeys = New-Object System.Collections.Generic.List[string]
foreach ($row in $entryRows) {
    $parameterKey = Get-ParameterKey -Text $row.'Parameter (units)'
    if ($parameterKey -ne "" -and -not $orderedParameterKeys.Contains($parameterKey)) {
        $orderedParameterKeys.Add($parameterKey)
    }
}

$missingDescriptions = @(
    $orderedParameterKeys | Where-Object { (Get-ParameterDescription -ParameterKey $_) -eq "" }
)
if ($missingDescriptions.Count -gt 0) {
    $joined = $missingDescriptions -join ', '
    throw "Missing parameter descriptions for: $joined"
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("% Auto-generated from: $CsvPath")
$lines.Add("% Requires: \\usepackage{booktabs}")
$lines.Add("% Requires: \\usepackage{xcolor}")
$lines.Add("% Requires: \\usepackage{array}")
$lines.Add("\begin{table}[htbp]")
$lines.Add("\centering")
$lines.Add("\small")
$lines.Add("\setlength{\tabcolsep}{6pt}")
$lines.Add("\renewcommand{\arraystretch}{1.35}")
$lines.Add("\caption{$Caption}")
$lines.Add("\label{$Label}")
$lines.Add("\newcolumntype{L}[1]{>{\raggedright\arraybackslash}p{#1}}")
$lines.Add("\newcolumntype{C}[1]{>{\centering\arraybackslash}p{#1}}")
$lines.Add("\begin{tabular}{L{0.30\linewidth} C{0.14\linewidth} C{0.14\linewidth} L{0.34\linewidth}}")
$lines.Add("\toprule")
$lines.Add("\textbf{Parameter (units)} & \textbf{Cell Type} & \textbf{Value} & \textbf{References} \\")
$lines.Add("\midrule")

foreach ($row in $rows) {
    $rowType = ([string]$row.RowType).Trim().ToLower()
    if ($rowType -eq 'section') {
        $sectionTitle = Format-SectionTitle -Text $row.'Parameter (units)'
        if ($sectionTitle -ne "") {
            $lines.Add("\addlinespace[0.45em]")
            $lines.Add("\multicolumn{4}{c}{\textbf{$sectionTitle}} \\")
            $lines.Add("\addlinespace[0.15em]")
        }
        continue
    }

    if ($rowType -ne 'entry') {
        throw "Unsupported RowType '$($row.RowType)' in CSV."
    }

    $paramCell = Format-ParameterUnitsCell -Text $row.'Parameter (units)'
    $cellTypeCell = Format-PlainTextCell -Text $row.'Cell Type'
    $valueCell = Format-PlainTextCell -Text $row.Value
    $refCell = Format-PlainTextCell -Text $row.References

    $lines.Add("$paramCell & $cellTypeCell & $valueCell & $refCell \\")
}

$lines.Add("\bottomrule")
$lines.Add("\end{tabular}")
$lines.Add("\end{table}")
$lines.Add("")
$lines.Add('% Bracket commands for description labels (avoids `]` inside \item[...] optional args).')
$lines.Add('\providecommand{\lbrack}{[}')
$lines.Add('\providecommand{\rbrack}{]}')
$lines.Add("")
$lines.Add('\noindent\textbf{Parameter definitions.}')
$lines.Add('\begin{description}')
$lines.Add('\setlength{\itemsep}{0.25em}')
foreach ($parameterKey in $orderedParameterKeys) {
    $label = Format-DescriptionLabel -ParameterKey $parameterKey
    $description = Get-ParameterDescription -ParameterKey $parameterKey
    $lines.Add('\item[' + $label + '] ' + $description)
}
$lines.Add('\end{description}')
$lines.Add("")

Set-Content -LiteralPath $outFull -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
Write-Output "Wrote LaTeX table: $outFull"
