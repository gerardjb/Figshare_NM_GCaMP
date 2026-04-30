param(
    [string]$CsvPath = "Table4/Table4_cell_parameter_priors.csv",
    [string]$OutputTex = "Table4/Table4_cell_parameter_priors.tex",
    [string]$Caption = "Cell-parameter prior means and approximate ranges.",
    [string]$Label = "tab:cell-parameter-priors"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $CsvPath)) {
    throw "CSV not found: $CsvPath"
}

$outFull = [System.IO.Path]::GetFullPath($OutputTex)
$outDir = Split-Path -Parent $outFull
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

function Convert-NewlinesToLatexLinebreaks {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return "" }
    # Preserve author-provided two-line cells (e.g. R_f values) as explicit line breaks.
    # Note: Import-Csv does not reliably support literal newlines inside quoted CSV fields,
    # so we also interpret "\n" sequences as intended line breaks.
    $t = $Text -replace '\\n', "`n"
    if ($t -notmatch "(`r`n|`n|`r)") {
        return $t
    }

    $parts = $t -split "`r`n|`n|`r"
    $parts = $parts | ForEach-Object { $_.TrimEnd() } | Where-Object { $_ -ne "" }

    # Slightly tighten inter-line spacing within multi-line cells.
    $joined = $parts -join "\\\\[-0.3ex]"
    return "\shortstack[c]{$joined}"
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

function Format-ParameterUnitsCell {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return "" }

    $t = $Text.Trim()
    # Expected: "<param> (<units>)"
    if ($t -match '^(?<param>.+?)\s*\((?<units>[^)]*)\)\s*$') {
        $param = $Matches['param'].Trim()
        $units = $Matches['units'].Trim()
        $unitsLatex = Format-UnitsForLatex -Units $units
        return ('$' + $param + '$ (' + $unitsLatex + ')')
    }

    # Fallback: keep as-is.
    return $t
}

$rows = Import-Csv -LiteralPath $CsvPath

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("% Auto-generated from: $CsvPath")
$lines.Add("% Requires: \\usepackage{booktabs}")
$lines.Add("% Requires: \\usepackage{xcolor}  % for colored sensor labels in cells")
$lines.Add("% Requires: \\usepackage{array}   % for column formatting")
$lines.Add("\begin{table}[htbp]")
$lines.Add("\centering")
$lines.Add("\small")
$lines.Add("\setlength{\tabcolsep}{6pt}")
$lines.Add("\renewcommand{\arraystretch}{1.35}")
$lines.Add("\caption{$Caption}")
$lines.Add("\label{$Label}")
$lines.Add("\newcolumntype{L}[1]{>{\raggedright\arraybackslash}p{#1}}")
$lines.Add("\newcolumntype{C}[1]{>{\centering\arraybackslash}p{#1}}")
$lines.Add("\begin{tabular}{L{0.24\linewidth} C{0.10\linewidth} C{0.14\linewidth} C{0.18\linewidth} L{0.34\linewidth}}")
$lines.Add("\toprule")
$lines.Add("\textbf{Parameter (units)} & \textbf{Fixed/Free} & \textbf{Mean} & \textbf{Approximate range} & \textbf{References} \\")
$lines.Add("\midrule")

foreach ($row in $rows) {
    $rowType = ""
    if ($null -ne $row.PSObject.Properties['RowType']) {
        $rowType = [string]$row.RowType
    }
    $rowType = $rowType.Trim().ToLower()

    if ($rowType -eq 'section') {
        $sectionTitle = Convert-NewlinesToLatexLinebreaks -Text $row.'Parameter (units)'
        if ($sectionTitle -ne "") {
            $lines.Add("\addlinespace[0.45em]")
            $lines.Add("\multicolumn{5}{c}{\textbf{$sectionTitle}} \\")
            $lines.Add("\addlinespace[0.15em]")
        }
        continue
    }

    $paramCell = Format-ParameterUnitsCell -Text $row.'Parameter (units)'
    $fixedFreeCell = Convert-NewlinesToLatexLinebreaks -Text $row.'Fixed/Free'
    $meanCell = Convert-NewlinesToLatexLinebreaks -Text $row.Mean
    $rangeCell = Convert-NewlinesToLatexLinebreaks -Text $row.'Approximate Range'
    $refCell = Convert-NewlinesToLatexLinebreaks -Text $row.References

    $lines.Add("$paramCell & $fixedFreeCell & $meanCell & $rangeCell & $refCell \\")
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
$lines.Add('\item[$\lbrack GCaMP\rbrack$] Total intracellular indicator concentration used in the model.')
$lines.Add('\item[$R_f$] Apparent fluorescence dynamic range (scaling factor mapping indicator state to measured $\Delta F/F$).')
$lines.Add('\item[$\Delta Ca_{spike}$] Per-spike calcium increment delivered to the modeled compartment.')
$lines.Add('\item[$ca_0$] Basal intracellular calcium concentration.')
$lines.Add('\item[$\gamma$] Effective first-order calcium clearance rate constant.')
$lines.Add('\item[$\gamma_{in}$] Rate constant governing calcium influx/exchange into the modeled intracellular compartment.')
$lines.Add('\item[$\gamma_{out}$] Rate constant governing calcium efflux/exchange out of the modeled intracellular compartment.')
$lines.Add('\item[$\kappa_{B}$] Linearized endogenous buffering factor applied to intracellular calcium dynamics.')
$lines.Add('\end{description}')
$lines.Add("")

Set-Content -LiteralPath $outFull -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
Write-Output "Wrote LaTeX table: $outFull"
