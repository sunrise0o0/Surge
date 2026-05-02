param(
  [string]$RepoRoot,
  [string]$RulesDir,
  [string]$SourcesPath,
  [string]$ProfilesDir,
  [switch]$AllowFileSources,
  [switch]$StrictDuplicates
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
if (-not $ProfilesDir) {
  $ProfilesDir = Join-Path $RepoRoot "Conf/Spec"
}

$errors = New-Object System.Collections.Generic.List[string]

function Add-ValidationError {
  param([string]$Message)
  $errors.Add($Message) | Out-Null
}

function Test-IsAllowedSourceUrl {
  param([string]$Url)

  if ($Url -match "^https://") {
    return $true
  }

  if (-not $AllowFileSources) {
    return $false
  }

  if ($Url -match "^file://") {
    return $true
  }

  return (Test-Path -LiteralPath $Url)
}

function Get-SourceManifest {
  if (-not (Test-Path -LiteralPath $SourcesPath)) {
    Add-ValidationError "Missing source manifest: $SourcesPath"
    return $null
  }

  try {
    return Get-Content -LiteralPath $SourcesPath -Raw -Encoding UTF8 | ConvertFrom-Json
  }
  catch {
    Add-ValidationError "Invalid source manifest JSON: $($_.Exception.Message)"
    return $null
  }
}

function Test-SourceManifest {
  param($Manifest)

  if (-not $Manifest) {
    return
  }

  if (-not $Manifest.schema) {
    Add-ValidationError "Rules/sources.json must declare a schema version."
  }

  if (-not $Manifest.generatedBy) {
    Add-ValidationError "Rules/sources.json must declare generatedBy."
  }

  if (-not $Manifest.repository -or $Manifest.repository -notmatch "^https://") {
    Add-ValidationError "Rules/sources.json repository must use https://."
  }

  if (-not $Manifest.rules -or $Manifest.rules.Count -eq 0) {
    Add-ValidationError "Rules/sources.json must contain at least one rule source."
    return
  }

  $targets = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

  foreach ($rule in $Manifest.rules) {
    if (-not $rule.target -or $rule.target -notmatch "^[A-Za-z0-9._-]+\.list$") {
      Add-ValidationError "Invalid target in Rules/sources.json: $($rule.target)"
    }
    elseif (-not $targets.Add($rule.target)) {
      Add-ValidationError "Duplicate target in Rules/sources.json: $($rule.target)"
    }

    if (-not $rule.displayName) {
      Add-ValidationError "Missing displayName for target $($rule.target)"
    }

    if (-not $rule.type -or $rule.type -notin @("domain", "ip", "mixed")) {
      Add-ValidationError "Invalid type for target $($rule.target): $($rule.type)"
    }

    if (-not $rule.upstream) {
      Add-ValidationError "Missing upstream for target $($rule.target)"
    }

    if (-not $rule.license) {
      Add-ValidationError "Missing license for target $($rule.target)"
    }

    if ($rule.outputs) {
      foreach ($outputField in @("domainSet", "nonIp", "ip")) {
        $outputPath = $rule.outputs.$outputField
        if ($outputPath -and $outputPath -notmatch "^[A-Za-z0-9._/-]+\.(conf|list)$") {
          Add-ValidationError "Invalid $outputField output for target $($rule.target): $outputPath"
        }
      }
    }

    if (-not $rule.sources -or $rule.sources.Count -eq 0) {
      Add-ValidationError "Missing sources for target $($rule.target)"
      continue
    }

    foreach ($source in $rule.sources) {
      if (-not $source.section) {
        Add-ValidationError "Missing source section for target $($rule.target)"
      }
      if (-not $source.url -or -not (Test-IsAllowedSourceUrl -Url $source.url)) {
        Add-ValidationError "Source URL must use https:// for target $($rule.target): $($source.url)"
      }
    }
  }
}

function Get-GeneratedRuleFiles {
  if (-not (Test-Path -LiteralPath $RulesDir)) {
    return @()
  }

  return @(Get-ChildItem -Path $RulesDir -File -Recurse | Where-Object {
    $_.Extension -in @(".list", ".conf") -and
    $_.FullName -notmatch "[\\/](Manual)[\\/]" -and
    $_.Name -notin @("sources.json", "sources.schema.json")
  })
}

function Test-ProfileLinks {
  if (-not (Test-Path -LiteralPath $ProfilesDir)) {
    Add-ValidationError "Missing profile directory: $ProfilesDir"
    return
  }

  $profiles = Get-ChildItem -Path $ProfilesDir -Filter "*.conf" -File

  foreach ($profile in $profiles) {
    $lines = Get-Content -LiteralPath $profile.FullName -Encoding UTF8

    for ($index = 0; $index -lt $lines.Count; $index++) {
      $lineNumber = $index + 1
      $line = $lines[$index].Trim()

      if ($line -match "^RULE-SET," -and $line -notmatch "^RULE-SET,(https?://|LAN,|SYSTEM,)") {
        Add-ValidationError "$($profile.FullName):$lineNumber invalid RULE-SET target: $line"
      }

      if ($line -match "^DOMAIN-SET," -and $line -notmatch "^DOMAIN-SET,https?://") {
        Add-ValidationError "$($profile.FullName):$lineNumber invalid DOMAIN-SET target: $line"
      }

      if ($line -match "icon-url=([^,\s]+)") {
        $iconUrl = $Matches[1]
        if ($iconUrl -notmatch "^https://") {
          Add-ValidationError "$($profile.FullName):$lineNumber icon-url must use https://: $iconUrl"
        }
      }
    }
  }
}

function Get-ProfileSections {
  param([string[]]$Lines)

  $sections = @{}
  $currentSection = ""

  for ($index = 0; $index -lt $Lines.Count; $index++) {
    $line = $Lines[$index].Trim()

    if ($line -match "^\[(.+)\]$") {
      $currentSection = $Matches[1]
      if (-not $sections.ContainsKey($currentSection)) {
        $sections[$currentSection] = [System.Collections.Generic.List[object]]::new()
      }
      continue
    }

    if (-not $sections.ContainsKey($currentSection)) {
      $sections[$currentSection] = [System.Collections.Generic.List[object]]::new()
    }

    $sections[$currentSection].Add([pscustomobject]@{
      Number = $index + 1
      Text = $Lines[$index]
    }) | Out-Null
  }

  return ,$sections
}

function Get-CleanPolicyName {
  param([string]$Value)

  if (-not $Value) {
    return ""
  }

  return (($Value -replace "\s+//.*$", "").Trim())
}

function Get-ProfilePolicyNames {
  param($Sections)

  $policies = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  $builtinPolicies = @(
    "DIRECT",
    "REJECT",
    "REJECT-DROP",
    "REJECT-NO-DROP",
    "REJECT-TINYGIF",
    "PROXY"
  )

  foreach ($builtinPolicy in $builtinPolicies) {
    $policies.Add($builtinPolicy) | Out-Null
  }

  foreach ($sectionName in @("Proxy", "Proxy Group")) {
    if (-not $Sections.ContainsKey($sectionName)) {
      continue
    }

    foreach ($entry in $Sections[$sectionName]) {
      $line = $entry.Text.Trim()
      if (-not $line -or $line.StartsWith("#") -or $line.StartsWith(";")) {
        continue
      }

      if ($line -match "^([^=]+?)\s*=") {
        $policies.Add($Matches[1].Trim()) | Out-Null
      }
    }
  }

  return ,$policies
}

function Test-PolicyExists {
  param(
    [System.Collections.Generic.HashSet[string]]$Policies,
    [string]$Policy,
    [string]$Location
  )

  $cleanPolicy = Get-CleanPolicyName -Value $Policy
  if (-not $cleanPolicy) {
    Add-ValidationError "$Location missing policy target"
    return
  }

  if (-not $Policies.Contains($cleanPolicy)) {
    Add-ValidationError "$Location unknown policy target: $cleanPolicy"
  }
}

function Get-RulePolicyIndex {
  param([string]$RuleType)

  switch ($RuleType) {
    "FINAL" { return 1 }
    "RULE-SET" { return 2 }
    "DOMAIN-SET" { return 2 }
    "DOMAIN" { return 2 }
    "DOMAIN-SUFFIX" { return 2 }
    "DOMAIN-KEYWORD" { return 2 }
    "IP-CIDR" { return 2 }
    "IP-CIDR6" { return 2 }
    "IP-ASN" { return 2 }
    "GEOIP" { return 2 }
    "PROCESS-NAME" { return 2 }
    "URL-REGEX" { return 2 }
    "USER-AGENT" { return 2 }
    default { return -1 }
  }
}

function Test-ProfileRuleStructure {
  param(
    [string]$ProfilePath,
    $Sections,
    [System.Collections.Generic.HashSet[string]]$Policies
  )

  if (-not $Sections.ContainsKey("Rule")) {
    return
  }

  $effectiveRules = @()

  foreach ($entry in $Sections["Rule"]) {
    $line = $entry.Text.Trim()
    if (-not $line -or $line.StartsWith("#") -or $line.StartsWith(";")) {
      continue
    }

    if ($line -match "^[A-Z-]+,") {
      $effectiveRules += [pscustomobject]@{
        Number = $entry.Number
        Text = $line
      }
    }
  }

  $finalRules = @($effectiveRules | Where-Object { $_.Text -match "^FINAL," })
  if ($finalRules.Count -gt 1) {
    Add-ValidationError "$ProfilePath`: multiple FINAL rules detected: $($finalRules.Count)"
  }

  if ($finalRules.Count -gt 0) {
    $lastRule = $effectiveRules[$effectiveRules.Count - 1]
    $lastFinal = $finalRules[$finalRules.Count - 1]
    if ($lastRule.Number -ne $lastFinal.Number) {
      Add-ValidationError "$ProfilePath`:$($lastFinal.Number) FINAL must be the last effective rule"
    }
  }

  foreach ($rule in $effectiveRules) {
    $parts = $rule.Text -split ","
    $ruleType = $parts[0].Trim()
    $policyIndex = Get-RulePolicyIndex -RuleType $ruleType

    if ($policyIndex -lt 0) {
      continue
    }

    if ($parts.Count -le $policyIndex) {
      Add-ValidationError "$ProfilePath`:$($rule.Number) missing policy target: $($rule.Text)"
      continue
    }

    Test-PolicyExists -Policies $Policies -Policy $parts[$policyIndex] -Location "$ProfilePath`:$($rule.Number)"
  }
}

function Test-ProfileGroupReferences {
  param(
    [string]$ProfilePath,
    $Sections,
    [System.Collections.Generic.HashSet[string]]$Policies
  )

  if (-not $Sections.ContainsKey("Proxy Group")) {
    return
  }

  $groupTypes = @(
    "select",
    "url-test",
    "fallback",
    "load-balance",
    "ssid",
    "smart",
    "subnet",
    "available",
    "benchmark"
  )

  foreach ($entry in $Sections["Proxy Group"]) {
    $line = $entry.Text.Trim()
    if (-not $line -or $line.StartsWith("#") -or $line.StartsWith(";") -or $line -notmatch "^([^=]+?)\s*=\s*(.+)$") {
      continue
    }

    $groupName = $Matches[1].Trim()
    $tokens = @($Matches[2] -split "," | ForEach-Object { $_.Trim() })
    if ($tokens.Count -eq 0) {
      continue
    }

    $startIndex = if ($groupTypes -contains $tokens[0].ToLowerInvariant()) { 1 } else { 0 }

    for ($index = $startIndex; $index -lt $tokens.Count; $index++) {
      $token = $tokens[$index]
      if (-not $token) {
        continue
      }

      if ($token -match "^include-other-group=(.+)$") {
        Test-PolicyExists -Policies $Policies -Policy $Matches[1] -Location "$ProfilePath`:$($entry.Number) group $groupName include-other-group"
        continue
      }

      if ($token -match "^[A-Za-z0-9_-]+=") {
        continue
      }

      Test-PolicyExists -Policies $Policies -Policy $token -Location "$ProfilePath`:$($entry.Number) group $groupName"
    }
  }
}

function Test-ProfilePolicyReferences {
  if (-not (Test-Path -LiteralPath $ProfilesDir)) {
    return
  }

  $profiles = Get-ChildItem -Path $ProfilesDir -Filter "*.conf" -File

  foreach ($profile in $profiles) {
    $lines = Get-Content -LiteralPath $profile.FullName -Encoding UTF8
    $sections = Get-ProfileSections -Lines $lines
    $policies = Get-ProfilePolicyNames -Sections $sections

    Test-ProfileRuleStructure -ProfilePath $profile.FullName -Sections $sections -Policies $policies
    Test-ProfileGroupReferences -ProfilePath $profile.FullName -Sections $sections -Policies $policies
  }
}

function Test-RuleTotals {
  if (-not (Test-Path -LiteralPath $RulesDir)) {
    Add-ValidationError "Missing rules directory: $RulesDir"
    return
  }

  $ruleFiles = Get-GeneratedRuleFiles
  $requiredHeaders = @(
    "NAME",
    "AUTHOR",
    "REPO",
    "UPDATED",
    "TOTAL",
    "SOURCE",
    "GENERATED-BY"
  )

  foreach ($ruleFile in $ruleFiles) {
    $content = Get-Content -LiteralPath $ruleFile.FullName -Encoding UTF8

    foreach ($requiredHeader in $requiredHeaders) {
      if (-not ($content | Select-String "^# ${requiredHeader}:" | Select-Object -First 1)) {
        Add-ValidationError "$($ruleFile.FullName): missing # $requiredHeader header"
      }
    }

    $header = $content | Select-String "^# TOTAL:\s*(\d+)" | Select-Object -First 1

    if (-not $header) {
      Add-ValidationError "$($ruleFile.FullName): missing # TOTAL header"
      continue
    }

    $expected = [int]$header.Matches[0].Groups[1].Value
    $actual = ($content | Where-Object { $_ -and $_ -notmatch "^#" }).Count

    if ($expected -ne $actual) {
      Add-ValidationError "$($ruleFile.FullName): # TOTAL mismatch, expected=$expected actual=$actual"
    }
  }
}

function Test-RuleDuplicates {
  if (-not (Test-Path -LiteralPath $RulesDir)) {
    return
  }

  $ruleFiles = @(Get-GeneratedRuleFiles | Where-Object { $_.Extension -eq ".list" })

  foreach ($ruleFile in $ruleFiles) {
    $rules = Get-Content -LiteralPath $ruleFile.FullName -Encoding UTF8 | Where-Object { $_ -and $_ -notmatch "^#" }
    $duplicates = $rules | Group-Object | Where-Object { $_.Count -gt 1 }

    if ($duplicates.Count -gt 0) {
      $message = "$($ruleFile.FullName): duplicate rules detected: $($duplicates.Count)"
      if ($StrictDuplicates) {
        Add-ValidationError $message
      }
      else {
        Write-Warning $message
      }
    }
  }
}

function Get-RuleTypeByTarget {
  param($Manifest)

  $ruleTypes = @{}

  if (-not $Manifest -or -not $Manifest.rules) {
    return $ruleTypes
  }

  foreach ($rule in $Manifest.rules) {
    if ($rule.target -and $rule.type) {
      $ruleTypes[$rule.target] = $rule.type
    }

    if ($rule.outputs) {
      if ($rule.outputs.domainSet) {
        $ruleTypes[$rule.outputs.domainSet -replace "/", [System.IO.Path]::DirectorySeparatorChar] = "domain-set"
      }
      if ($rule.outputs.nonIp) {
        $ruleTypes[$rule.outputs.nonIp -replace "/", [System.IO.Path]::DirectorySeparatorChar] = "non-ip"
      }
      if ($rule.outputs.ip) {
        $ruleTypes[$rule.outputs.ip -replace "/", [System.IO.Path]::DirectorySeparatorChar] = "ip"
      }
    }
  }

  return $ruleTypes
}

function Test-RuleSemantics {
  param($Manifest)

  if (-not (Test-Path -LiteralPath $RulesDir)) {
    return
  }

  $ruleTypes = Get-RuleTypeByTarget -Manifest $Manifest
  $knownPrefixes = @(
    "DOMAIN",
    "DOMAIN-KEYWORD",
    "DOMAIN-SUFFIX",
    "IP-ASN",
    "IP-CIDR",
    "IP-CIDR6",
    "PROCESS-NAME",
    "URL-REGEX",
    "USER-AGENT"
  )
  $domainPrefixes = @(
    "DOMAIN",
    "DOMAIN-KEYWORD",
    "DOMAIN-SUFFIX",
    "PROCESS-NAME",
    "URL-REGEX",
    "USER-AGENT"
  )
  $ipPrefixes = @(
    "IP-ASN",
    "IP-CIDR",
    "IP-CIDR6"
  )

  $ruleFiles = Get-GeneratedRuleFiles

  foreach ($ruleFile in $ruleFiles) {
    $rulesRoot = (Resolve-Path -LiteralPath $RulesDir).Path.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $relativeName = $ruleFile.FullName.Substring($rulesRoot.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $manifestType = $ruleTypes[$ruleFile.Name]
    if (-not $manifestType) {
      $manifestType = $ruleTypes[$relativeName]
    }

    if (-not $manifestType) {
      Add-ValidationError "$($ruleFile.FullName): missing entry in Rules/sources.json"
      continue
    }

    if ($manifestType -eq "domain-set") {
      $lines = Get-Content -LiteralPath $ruleFile.FullName -Encoding UTF8
      for ($index = 0; $index -lt $lines.Count; $index++) {
        $lineNumber = $index + 1
        $line = $lines[$index].Trim()

        if (-not $line -or $line.StartsWith("#")) {
          continue
        }

        if ($line -match "," -or $line -notmatch "^\.?[A-Za-z0-9*_-]+(\.[A-Za-z0-9*_-]+)*$") {
          Add-ValidationError "$($ruleFile.FullName):$lineNumber invalid DOMAIN-SET entry: $line"
        }
      }
      continue
    }

    $lines = Get-Content -LiteralPath $ruleFile.FullName -Encoding UTF8

    for ($index = 0; $index -lt $lines.Count; $index++) {
      $lineNumber = $index + 1
      $line = $lines[$index].Trim()

      if (-not $line -or $line.StartsWith("#")) {
        continue
      }

      $prefix = ($line -split ",", 2)[0].Trim()

      if ($knownPrefixes -notcontains $prefix) {
        Add-ValidationError "$($ruleFile.FullName):$lineNumber unknown rule prefix: $prefix"
        continue
      }

      if ($manifestType -eq "ip" -and $ipPrefixes -notcontains $prefix) {
        Add-ValidationError "$($ruleFile.FullName):$lineNumber type=ip cannot contain $prefix"
      }

      if ($manifestType -eq "domain" -and $domainPrefixes -notcontains $prefix) {
        Add-ValidationError "$($ruleFile.FullName):$lineNumber type=domain cannot contain $prefix"
      }

      if ($manifestType -eq "non-ip" -and $ipPrefixes -contains $prefix) {
        Add-ValidationError "$($ruleFile.FullName):$lineNumber type=non-ip cannot contain $prefix"
      }

      if (($prefix -eq "IP-CIDR" -or $prefix -eq "IP-CIDR6" -or $prefix -eq "IP-ASN") -and $line -notmatch "(^|,)no-resolve(\s|,|$|//)") {
        Add-ValidationError "$($ruleFile.FullName):$lineNumber $prefix must include no-resolve"
      }
    }
  }
}

$manifest = Get-SourceManifest
Test-SourceManifest -Manifest $manifest
Test-ProfileLinks
Test-ProfilePolicyReferences
Test-RuleTotals
Test-RuleDuplicates
Test-RuleSemantics -Manifest $manifest

if ($errors.Count -gt 0) {
  Write-Error ("Rule validation failed:`n" + ($errors -join "`n"))
  exit 1
}

Write-Host "Rule validation passed."
