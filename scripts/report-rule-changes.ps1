param(
  [string]$RepoRoot,
  [string]$RulesDir,
  [string]$SourcesPath,
  [string]$BaselineDir,
  [string]$BaseRef = "HEAD",
  [string]$OutputPath,
  [switch]$FailOnHighRisk,
  [int]$MaxRemovedPercent = 20,
  [int]$MaxAddedPercent = 50,
  [int]$MaxNetChange = 1000,
  [int]$MaxDomainKeywordAdded = 20,
  [int]$MaxIpRulesAdded = 500
)

$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
  $RepoRoot = Split-Path -Parent $PSScriptRoot
}
if (-not $RulesDir) {
  $RulesDir = Join-Path $RepoRoot "Rules"
}
if (-not $SourcesPath) {
  $SourcesPath = Join-Path $RulesDir "sources.json"
}
if (-not $OutputPath -and $env:GITHUB_STEP_SUMMARY) {
  $OutputPath = $env:GITHUB_STEP_SUMMARY
}

$highRiskPrefixes = @(
  "DOMAIN-KEYWORD",
  "IP-ASN",
  "IP-CIDR",
  "IP-CIDR6",
  "URL-REGEX"
)

function Get-RuleLinesFromText {
  param([string[]]$Lines)

  return @($Lines |
    ForEach-Object { ($_ -replace "`r", "").Trim() } |
    Where-Object { $_ -and $_ -notmatch "^#" })
}

function Get-RuleLinesFromFile {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    return @()
  }

  return Get-RuleLinesFromText -Lines (Get-Content -LiteralPath $Path -Encoding UTF8)
}

function Get-BaselineRuleLines {
  param([string]$Target)

  if ($BaselineDir) {
    return Get-RuleLinesFromFile -Path (Join-Path $BaselineDir $Target)
  }

  $repoPath = "Rules/$Target"
  $raw = & git -C $RepoRoot show "${BaseRef}:$repoPath" 2>$null
  if ($LASTEXITCODE -ne 0) {
    return @()
  }

  return Get-RuleLinesFromText -Lines $raw
}

function Get-HighRiskCount {
  param([string[]]$Rules)

  $count = 0
  foreach ($rule in $Rules) {
    $prefix = ($rule -split ",", 2)[0].Trim()
    if ($highRiskPrefixes -contains $prefix) {
      $count++
    }
  }

  return $count
}

function Get-PrefixCount {
  param(
    [string[]]$Rules,
    [string[]]$Prefixes
  )

  $count = 0
  foreach ($rule in $Rules) {
    $prefix = ($rule -split ",", 2)[0].Trim()
    if ($Prefixes -contains $prefix) {
      $count++
    }
  }

  return $count
}

if (-not (Test-Path -LiteralPath $SourcesPath)) {
  throw "Missing source manifest: $SourcesPath"
}

$manifest = Get-Content -LiteralPath $SourcesPath -Raw -Encoding UTF8 | ConvertFrom-Json
$report = [System.Collections.Generic.List[string]]::new()
$changedFiles = 0
$totalAdded = 0
$totalRemoved = 0
$totalHighRiskAdded = 0
$riskFindings = [System.Collections.Generic.List[string]]::new()
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz")

$report.Add("# Rule Update Report") | Out-Null
$report.Add("") | Out-Null
$report.Add("Generated: $timestamp") | Out-Null
$report.Add("") | Out-Null
$report.Add("| File | Added | Removed | High-risk added | Notes |") | Out-Null
$report.Add("| --- | ---: | ---: | ---: | --- |") | Out-Null

foreach ($rule in $manifest.rules) {
  $target = [string]$rule.target
  $currentRules = Get-RuleLinesFromFile -Path (Join-Path $RulesDir $target)
  $baselineRules = Get-BaselineRuleLines -Target $target

  $added = @(Compare-Object -ReferenceObject $baselineRules -DifferenceObject $currentRules | Where-Object SideIndicator -eq "=>" | Select-Object -ExpandProperty InputObject)
  $removed = @(Compare-Object -ReferenceObject $baselineRules -DifferenceObject $currentRules | Where-Object SideIndicator -eq "<=" | Select-Object -ExpandProperty InputObject)
  $highRiskAdded = Get-HighRiskCount -Rules $added
  $domainKeywordAdded = Get-PrefixCount -Rules $added -Prefixes @("DOMAIN-KEYWORD")
  $ipRulesAdded = Get-PrefixCount -Rules $added -Prefixes @("IP-ASN", "IP-CIDR", "IP-CIDR6")
  $notes = "no semantic rule changes"
  $fileFindings = [System.Collections.Generic.List[string]]::new()

  if ($baselineRules.Count -eq 0 -and $currentRules.Count -gt 0) {
    $notes = "new or missing baseline"
  }
  elseif ($added.Count -or $removed.Count) {
    $notes = "rule content changed"
  }

  if ($baselineRules.Count -gt 0) {
    $removedPercent = [Math]::Round(($removed.Count / [double]$baselineRules.Count) * 100, 2)
    $addedPercent = [Math]::Round(($added.Count / [double]$baselineRules.Count) * 100, 2)
    $netChange = [Math]::Abs($added.Count - $removed.Count)

    if ($removedPercent -gt $MaxRemovedPercent) {
      $fileFindings.Add("removed $removedPercent% > $MaxRemovedPercent%") | Out-Null
    }

    if ($addedPercent -gt $MaxAddedPercent) {
      $fileFindings.Add("added $addedPercent% > $MaxAddedPercent%") | Out-Null
    }

    if ($netChange -gt $MaxNetChange) {
      $fileFindings.Add("net change $netChange > $MaxNetChange") | Out-Null
    }

    if ($domainKeywordAdded -gt $MaxDomainKeywordAdded) {
      $fileFindings.Add("DOMAIN-KEYWORD added $domainKeywordAdded > $MaxDomainKeywordAdded") | Out-Null
    }

    if ($ipRulesAdded -gt $MaxIpRulesAdded) {
      $fileFindings.Add("IP/ASN added $ipRulesAdded > $MaxIpRulesAdded") | Out-Null
    }
  }

  if ($fileFindings.Count -gt 0) {
    $notes = "high risk: " + ($fileFindings -join "; ")
    $riskFindings.Add("${target}: $($fileFindings -join '; ')") | Out-Null
  }

  if ($added.Count -or $removed.Count) {
    $changedFiles++
    $totalAdded += $added.Count
    $totalRemoved += $removed.Count
    $totalHighRiskAdded += $highRiskAdded
  }

  $report.Add("| $target | $($added.Count) | $($removed.Count) | $highRiskAdded | $notes |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("Summary: changed_files=$changedFiles added=$totalAdded removed=$totalRemoved high_risk_added=$totalHighRiskAdded") | Out-Null

if ($riskFindings.Count -gt 0) {
  $report.Add("") | Out-Null
  $report.Add("## High-risk findings") | Out-Null
  $report.Add("") | Out-Null
  foreach ($finding in $riskFindings) {
    $report.Add("- $finding") | Out-Null
  }
}

$text = $report -join "`n"
Write-Output $text

if ($OutputPath) {
  Add-Content -LiteralPath $OutputPath -Value ($text + "`n") -Encoding UTF8
}

if ($FailOnHighRisk -and $riskFindings.Count -gt 0) {
  Write-Error ("High-risk rule changes detected:`n" + ($riskFindings -join "`n"))
  exit 1
}
