$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("surge-rule-tests-" + [System.Guid]::NewGuid().ToString("N"))
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-Utf8File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Content
  )

  $parent = Split-Path -Parent $Path
  if ($parent) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }

  [System.IO.File]::WriteAllText($Path, (($Content -replace "`r?`n", "`n").TrimEnd() + "`n"), $utf8NoBom)
}

function Assert-True {
  param(
    [bool]$Condition,
    [string]$Message
  )

  if (-not $Condition) {
    throw "Assertion failed: $Message"
  }
}

function Assert-Equal {
  param(
    $Expected,
    $Actual,
    [string]$Message
  )

  if ($Expected -ne $Actual) {
    throw "Assertion failed: $Message. Expected=[$Expected] Actual=[$Actual]"
  }
}

function Assert-ValidationFails {
  param(
    [Parameter(Mandatory)][string]$ProfilesDir,
    [Parameter(Mandatory)][string]$Message
  )

  $powerShellExe = [System.Diagnostics.Process]::GetCurrentProcess().Path
  $stdoutPath = Join-Path $testRoot ("validation-stdout-" + [System.Guid]::NewGuid().ToString("N") + ".log")
  $stderrPath = Join-Path $testRoot ("validation-stderr-" + [System.Guid]::NewGuid().ToString("N") + ".log")
  $arguments = @(
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    (Join-Path $repoRoot "scripts/validate-rules.ps1"),
    "-RepoRoot",
    $testRoot,
    "-RulesDir",
    $rulesDir,
    "-SourcesPath",
    $sourcesPath,
    "-ProfilesDir",
    $ProfilesDir,
    "-AllowFileSources",
    "-StrictDuplicates"
  )

  $process = Start-Process -FilePath $powerShellExe -ArgumentList $arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
  Assert-True ($process.ExitCode -ne 0) $Message
}

function Assert-ReportFails {
  param([Parameter(Mandatory)][string]$Message)

  $powerShellExe = [System.Diagnostics.Process]::GetCurrentProcess().Path
  $stdoutPath = Join-Path $testRoot ("report-stdout-" + [System.Guid]::NewGuid().ToString("N") + ".log")
  $stderrPath = Join-Path $testRoot ("report-stderr-" + [System.Guid]::NewGuid().ToString("N") + ".log")
  $arguments = @(
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    (Join-Path $repoRoot "scripts/report-rule-changes.ps1"),
    "-RepoRoot",
    $testRoot,
    "-RulesDir",
    $rulesDir,
    "-SourcesPath",
    $sourcesPath,
    "-BaselineDir",
    $baselineDir,
    "-FailOnHighRisk"
  )

  $process = Start-Process -FilePath $powerShellExe -ArgumentList $arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
  Assert-True ($process.ExitCode -ne 0) $Message
}

try {
  $rulesDir = Join-Path $testRoot "Rules"
  $manualDir = Join-Path $rulesDir "Manual"
  $profilesDir = Join-Path $testRoot "Conf/Spec"
  $upstreamDir = Join-Path $testRoot "Upstream"
  $sourceA = Join-Path $upstreamDir "source-a.list"
  $sourceB = Join-Path $upstreamDir "source-b.list"
  $sourcesPath = Join-Path $rulesDir "sources.json"

  New-Item -ItemType Directory -Force -Path $rulesDir, $manualDir, $profilesDir, $upstreamDir | Out-Null

  Write-Utf8File -Path (Join-Path $manualDir "Test.txt") -Content @"
# Local pinned patch
DOMAIN-SUFFIX,manual.example
DOMAIN-SUFFIX,duplicate.example
"@

  Write-Utf8File -Path (Join-Path $manualDir "Test.exclude.txt") -Content @"
excluded.example
"@

  Write-Utf8File -Path $sourceA -Content @"
# Upstream comment should be ignored
DOMAIN-SUFFIX,duplicate.example
DOMAIN-SUFFIX,example.com
DOMAIN-SUFFIX,excluded.example
IP-CIDR,192.0.2.0/24
"@

  Write-Utf8File -Path $sourceB -Content @"
DOMAIN-SUFFIX,second.example
DOMAIN-SUFFIX,EXAMPLE.COM
"@

  $manifest = [ordered]@{
    schema = 1
    generatedBy = "scripts/update-rules.ps1"
    repository = "https://example.com/rabbit-spec/surge-test"
    manualSection = "Manual Rules"
    rules = @(
      [ordered]@{
        target = "Test.list"
        displayName = "Test Rules"
        type = "mixed"
        upstream = "local-fixture"
        license = "test-fixture"
        outputs = [ordered]@{
          domainSet = "DomainSet/Test.conf"
          nonIp = "NonIP/Test.list"
          ip = "IP/Test.list"
        }
        sources = @(
          [ordered]@{
            section = "Source A"
            url = $sourceA
          },
          [ordered]@{
            section = "Source B"
            url = $sourceB
          }
        )
      }
    )
  }
  Write-Utf8File -Path $sourcesPath -Content ($manifest | ConvertTo-Json -Depth 10)

  Write-Utf8File -Path (Join-Path $profilesDir "Test.conf") -Content @"
[Rule]
RULE-SET,https://example.com/Test.list,Proxy
DOMAIN-SET,https://example.com/TestDomain.list,Proxy
RULE-SET,LAN,DIRECT
FINAL,DIRECT
"@

  & (Join-Path $repoRoot "scripts/update-rules.ps1") `
    -RepoRoot $testRoot `
    -RulesDir $rulesDir `
    -ManualDir $manualDir `
    -SourcesPath $sourcesPath `
    -Timestamp "2026.05.02 04:00:00" `
    -AllowFileSources

  & (Join-Path $repoRoot "scripts/check-rule-sources.ps1") `
    -RulesDir $rulesDir `
    -SourcesPath $sourcesPath `
    -AllowFileSources

  & (Join-Path $repoRoot "scripts/validate-rules.ps1") `
    -RepoRoot $testRoot `
    -RulesDir $rulesDir `
    -SourcesPath $sourcesPath `
    -ProfilesDir $profilesDir `
    -AllowFileSources `
    -StrictDuplicates

  $badFinalDir = Join-Path $testRoot "BadProfiles/Final"
  Write-Utf8File -Path (Join-Path $badFinalDir "BadFinal.conf") -Content @"
[Proxy Group]
Proxy = select, DIRECT
[Rule]
FINAL,Proxy
DOMAIN-SUFFIX,late.example,DIRECT
"@
  Assert-ValidationFails -ProfilesDir $badFinalDir -Message "validation rejects rules after FINAL"

  $badRulePolicyDir = Join-Path $testRoot "BadProfiles/RulePolicy"
  Write-Utf8File -Path (Join-Path $badRulePolicyDir "BadRulePolicy.conf") -Content @"
[Proxy Group]
Proxy = select, DIRECT
[Rule]
DOMAIN-SUFFIX,missing.example,MissingPolicy
FINAL,Proxy
"@
  Assert-ValidationFails -ProfilesDir $badRulePolicyDir -Message "validation rejects missing rule policy target"

  $badGroupPolicyDir = Join-Path $testRoot "BadProfiles/GroupPolicy"
  Write-Utf8File -Path (Join-Path $badGroupPolicyDir "BadGroupPolicy.conf") -Content @"
[Proxy Group]
Proxy = select, MissingGroup
[Rule]
FINAL,Proxy
"@
  Assert-ValidationFails -ProfilesDir $badGroupPolicyDir -Message "validation rejects missing group policy target"

  $outputPath = Join-Path $rulesDir "Test.list"
  $domainSetPath = Join-Path $rulesDir "DomainSet/Test.conf"
  $nonIpPath = Join-Path $rulesDir "NonIP/Test.list"
  $ipPath = Join-Path $rulesDir "IP/Test.list"
  $baselineDir = Join-Path $testRoot "Baseline"
  $reportPath = Join-Path $testRoot "rule-report.md"
  $output = Get-Content -LiteralPath $outputPath -Encoding UTF8
  $ruleLines = @($output | Where-Object { $_ -and $_ -notmatch "^#" })

  Assert-True ($output -contains "# UPDATED: 2026.05.02 04:00:00") "fixed timestamp is written"
  Assert-True ($output -contains "# TOTAL: 5") "TOTAL header reflects generated rule count"
  Assert-True ($output -contains "# Local pinned patch") "manual comments are preserved"
  Assert-True (-not ($output -contains "DOMAIN-SUFFIX,excluded.example")) "exclude file removes upstream rule"
  Assert-Equal 5 $ruleLines.Count "dedupe leaves five unique rules"
  Assert-True (Test-Path -LiteralPath $domainSetPath) "domain-set split output is generated"
  Assert-True (Test-Path -LiteralPath $nonIpPath) "non-ip split output is generated"
  Assert-True (Test-Path -LiteralPath $ipPath) "ip split output is generated"
  Assert-True ((Get-Content -LiteralPath $domainSetPath -Encoding UTF8) -contains ".manual.example") "DOMAIN-SUFFIX is converted for DOMAIN-SET"
  Assert-True ((Get-Content -LiteralPath $ipPath -Encoding UTF8) -contains "IP-CIDR,192.0.2.0/24,no-resolve") "IP split output preserves no-resolve"

  $expectedRules = @(
    "DOMAIN-SUFFIX,manual.example",
    "DOMAIN-SUFFIX,duplicate.example",
    "DOMAIN-SUFFIX,example.com",
    "IP-CIDR,192.0.2.0/24,no-resolve",
    "DOMAIN-SUFFIX,second.example"
  )

  for ($index = 0; $index -lt $expectedRules.Count; $index++) {
    Assert-Equal $expectedRules[$index] $ruleLines[$index] "rule order at index $index"
  }

  $manualIndex = [array]::IndexOf($output, "# ======= Manual Rules ========")
  $sourceAIndex = [array]::IndexOf($output, "# ======= Source A ========")
  $sourceBIndex = [array]::IndexOf($output, "# ======= Source B ========")

  Assert-True ($manualIndex -ge 0) "manual section exists"
  Assert-True ($sourceAIndex -gt $manualIndex) "Source A follows manual rules"
  Assert-True ($sourceBIndex -gt $sourceAIndex) "Source B follows Source A"

  Write-Utf8File -Path (Join-Path $baselineDir "Test.list") -Content @"
# TOTAL: 2
DOMAIN-SUFFIX,manual.example
DOMAIN-SUFFIX,old.example
"@

  $report = & (Join-Path $repoRoot "scripts/report-rule-changes.ps1") `
    -RepoRoot $testRoot `
    -RulesDir $rulesDir `
    -SourcesPath $sourcesPath `
    -BaselineDir $baselineDir `
    -OutputPath $reportPath

  $reportText = $report -join "`n"
  Assert-True ($reportText.Contains("| Test.list | 4 | 1 | 1 |")) "change report counts added, removed, and high-risk rules"
  Assert-True (Test-Path -LiteralPath $reportPath) "change report writes output file"
  Assert-ReportFails -Message "high-risk change report exits non-zero when FailOnHighRisk is set"

  Write-Host "Rule script tests passed."
}
finally {
  if (Test-Path -LiteralPath $testRoot) {
    Remove-Item -LiteralPath $testRoot -Recurse -Force
  }
}
