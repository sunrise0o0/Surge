param(
  [string]$RepoRoot,
  [string]$RulesDir,
  [string]$ManualDir,
  [string]$SourcesPath,
  [string]$Timestamp,
  [switch]$AllowFileSources
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

if (-not $RepoRoot) {
  $RepoRoot = Split-Path -Parent $PSScriptRoot
}
if (-not $RulesDir) {
  $RulesDir = Join-Path $RepoRoot "Rules"
}
if (-not $ManualDir) {
  $ManualDir = Join-Path $RulesDir "Manual"
}
if (-not $SourcesPath) {
  $SourcesPath = Join-Path $RulesDir "sources.json"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-ShanghaiTimestamp {
  try {
    $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById("China Standard Time")
  }
  catch {
    $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById("Asia/Shanghai")
  }

  return [System.TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz).ToString("yyyy.MM.dd HH:mm:ss")
}

function Get-RemoteText {
  param([Parameter(Mandatory)][string]$Url)

  if ($AllowFileSources -and $Url -match "^file://") {
    $uri = [System.Uri]$Url
    return [System.IO.File]::ReadAllText($uri.LocalPath, [System.Text.Encoding]::UTF8)
  }

  if ($AllowFileSources -and (Test-Path -LiteralPath $Url)) {
    $path = (Resolve-Path -LiteralPath $Url).Path
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
  }

  if ($Url -notmatch "^https://") {
    throw "Source URL must use https:// unless -AllowFileSources points to a local file: $Url"
  }

  $client = [System.Net.Http.HttpClient]::new()
  $client.Timeout = [TimeSpan]::FromSeconds(90)
  $client.DefaultRequestHeaders.UserAgent.ParseAdd("Rabbit-Spec-Surge-Rules/1.0")

  try {
    return $client.GetStringAsync($Url).GetAwaiter().GetResult()
  }
  finally {
    $client.Dispose()
  }
}

function Get-TextLines {
  param([Parameter(Mandatory)][string]$Text)

  return $Text -replace "^\uFEFF", "" -split "\r?\n"
}

function Get-ExcludePatterns {
  param([Parameter(Mandatory)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    return @()
  }

  return Get-Content -LiteralPath $Path -Encoding UTF8 |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and $_ -notmatch "^#" }
}

function Test-IsExcluded {
  param(
    [Parameter(Mandatory)][string]$Line,
    [string[]]$Patterns
  )

  foreach ($pattern in $Patterns) {
    if ($Line.Contains($pattern)) {
      return $true
    }
  }

  return $false
}

function Normalize-RuleLine {
  param([Parameter(Mandatory)][string]$Line)

  if ($Line -notmatch "^(IP-CIDR|IP-CIDR6|IP-ASN),") {
    return $Line
  }

  if ($Line -match "(^|,)no-resolve(\s|,|$|//)") {
    return $Line
  }

  $parts = $Line -split "\s+//", 2
  if ($parts.Count -eq 2) {
    $comment = $parts[1].Trim()
    if ($comment) {
      return "$($parts[0]),no-resolve // $comment"
    }
    return "$($parts[0]),no-resolve"
  }

  return "$Line,no-resolve"
}

function ConvertTo-DomainSetLine {
  param([Parameter(Mandatory)][string]$Line)

  $parts = $Line -split ",", 3
  if ($parts.Count -lt 2) {
    return $null
  }

  $prefix = $parts[0].Trim()
  $domain = $parts[1].Trim()

  if (-not $domain) {
    return $null
  }

  if ($prefix -eq "DOMAIN") {
    return $domain
  }

  if ($prefix -eq "DOMAIN-SUFFIX") {
    return ".$domain"
  }

  return $null
}

function Write-GeneratedFile {
  param(
    [Parameter(Mandatory)][string]$RelativePath,
    [Parameter(Mandatory)][string]$DisplayName,
    [Parameter(Mandatory)][string]$Timestamp,
    [string[]]$Lines
  )

  $targetPath = Join-Path $RulesDir $RelativePath
  $parent = Split-Path -Parent $targetPath
  if ($parent) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }

  $body = @($Lines | Where-Object { $_ })
  $header = @(
    "# NAME: $DisplayName",
    "# AUTHOR: Rabbit-Spec",
    "# REPO: $($manifest.repository)",
    "# UPDATED: $Timestamp",
    "# TOTAL: $($body.Count)",
    "# SOURCE: Rules/sources.json",
    "# GENERATED-BY: scripts/update-rules.ps1",
    ""
  )

  $output = @($header + $body)
  [System.IO.File]::WriteAllText($targetPath, (($output -join "`n") + "`n"), $utf8NoBom)
}

function Write-SplitOutputs {
  param(
    [Parameter(Mandatory)]$Rule,
    [Parameter(Mandatory)][string]$Timestamp,
    [string[]]$Body
  )

  if (-not $Rule.outputs) {
    return
  }

  $rules = @($Body | Where-Object { $_ -and $_ -notmatch "^#" })
  $domainSetLines = [System.Collections.Generic.List[string]]::new()
  $nonIpLines = [System.Collections.Generic.List[string]]::new()
  $ipLines = [System.Collections.Generic.List[string]]::new()

  foreach ($line in $rules) {
    $prefix = ($line -split ",", 2)[0].Trim()

    if ($prefix -eq "IP-CIDR" -or $prefix -eq "IP-CIDR6" -or $prefix -eq "IP-ASN") {
      $ipLines.Add($line) | Out-Null
      continue
    }

    $domainSetLine = ConvertTo-DomainSetLine -Line $line
    if ($domainSetLine) {
      $domainSetLines.Add($domainSetLine) | Out-Null
      continue
    }

    $nonIpLines.Add($line) | Out-Null
  }

  if ($Rule.outputs.domainSet) {
    Write-GeneratedFile -RelativePath $Rule.outputs.domainSet -DisplayName "$($Rule.displayName) DomainSet" -Timestamp $Timestamp -Lines $domainSetLines
  }

  if ($Rule.outputs.nonIp) {
    Write-GeneratedFile -RelativePath $Rule.outputs.nonIp -DisplayName "$($Rule.displayName) Non-IP" -Timestamp $Timestamp -Lines $nonIpLines
  }

  if ($Rule.outputs.ip) {
    Write-GeneratedFile -RelativePath $Rule.outputs.ip -DisplayName "$($Rule.displayName) IP" -Timestamp $Timestamp -Lines $ipLines
  }
}

function Add-RuleSection {
  param(
    [System.Collections.Generic.List[string]]$Body,
    [System.Collections.Generic.HashSet[string]]$Seen,
    [Parameter(Mandatory)][ref]$RuleCount,
    [Parameter(Mandatory)][ref]$DuplicateCount,
    [Parameter(Mandatory)][string]$Section,
    [string[]]$Lines,
    [string[]]$ExcludePatterns,
    [switch]$PreserveComments
  )

  $sectionStarted = $false

  foreach ($rawLine in $Lines) {
    $line = ($rawLine -replace "`r", "").Trim()

    if (-not $line) {
      continue
    }

    if ($line.StartsWith("#")) {
      if ($PreserveComments) {
        if (-not $sectionStarted) {
          $Body.Add("# ======= $Section ========") | Out-Null
          $sectionStarted = $true
        }
        $Body.Add($line) | Out-Null
      }
      continue
    }

    if (Test-IsExcluded -Line $line -Patterns $ExcludePatterns) {
      continue
    }

    $line = Normalize-RuleLine -Line $line

    if (-not $sectionStarted) {
      $Body.Add("# ======= $Section ========") | Out-Null
      $sectionStarted = $true
    }

    if ($Seen.Add($line)) {
      $Body.Add($line) | Out-Null
      $RuleCount.Value++
    }
    else {
      $DuplicateCount.Value++
    }
  }

  if ($sectionStarted) {
    $Body.Add("") | Out-Null
  }
}

function Write-RuleFile {
  param(
    [Parameter(Mandatory)]$Manifest,
    [Parameter(Mandatory)]$Rule,
    [Parameter(Mandatory)][string]$Timestamp
  )

  $targetPath = Join-Path $RulesDir $Rule.target
  $nameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($Rule.target)
  $manualPath = Join-Path $ManualDir "$nameWithoutExtension.txt"
  $excludePath = Join-Path $ManualDir "$nameWithoutExtension.exclude.txt"
  $excludePatterns = Get-ExcludePatterns -Path $excludePath
  $body = [System.Collections.Generic.List[string]]::new()
  $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  $ruleCount = 0
  $duplicateCount = 0

  if (Test-Path -LiteralPath $manualPath) {
    $manualLines = Get-Content -LiteralPath $manualPath -Encoding UTF8
    $manualSection = if ($Manifest.manualSection) { $Manifest.manualSection } else { "Manual Rules" }
    Add-RuleSection -Body $body -Seen $seen -RuleCount ([ref]$ruleCount) -DuplicateCount ([ref]$duplicateCount) -Section $manualSection -Lines $manualLines -ExcludePatterns @() -PreserveComments
  }

  foreach ($source in $Rule.sources) {
    Write-Host "Downloading $($Rule.target) <- $($source.url)"
    $remoteText = Get-RemoteText -Url $source.url
    $remoteLines = Get-TextLines -Text $remoteText
    Add-RuleSection -Body $body -Seen $seen -RuleCount ([ref]$ruleCount) -DuplicateCount ([ref]$duplicateCount) -Section $source.section -Lines $remoteLines -ExcludePatterns $excludePatterns
  }

  while ($body.Count -gt 0 -and -not $body[$body.Count - 1]) {
    $body.RemoveAt($body.Count - 1)
  }

  $finalRuleCount = ($body | Where-Object { $_ -and $_ -notmatch "^#" }).Count

  $header = @(
    "# NAME: $($Rule.displayName)",
    "# AUTHOR: Rabbit-Spec",
    "# REPO: $($Manifest.repository)",
    "# UPDATED: $Timestamp",
    "# TOTAL: $finalRuleCount",
    "# SOURCE: Rules/sources.json",
    "# GENERATED-BY: scripts/update-rules.ps1",
    ""
  )

  $output = @($header + $body)
  [System.IO.File]::WriteAllText($targetPath, (($output -join "`n") + "`n"), $utf8NoBom)
  Write-SplitOutputs -Rule $Rule -Timestamp $Timestamp -Body $body

  if ($duplicateCount -gt 0) {
    Write-Host "Deduped $duplicateCount duplicate rule(s) in $($Rule.target)."
  }
}

if (-not (Test-Path -LiteralPath $SourcesPath)) {
  throw "Missing source manifest: $SourcesPath"
}

New-Item -ItemType Directory -Force -Path $RulesDir | Out-Null
New-Item -ItemType Directory -Force -Path $ManualDir | Out-Null

$manifest = Get-Content -LiteralPath $SourcesPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $Timestamp) {
  $Timestamp = Get-ShanghaiTimestamp
}

foreach ($rule in $manifest.rules) {
  Write-RuleFile -Manifest $manifest -Rule $rule -Timestamp $Timestamp
}

Write-Host "Rule generation completed."
