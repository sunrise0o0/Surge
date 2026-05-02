param(
  [string]$RulesDir,
  [string]$SourcesPath,
  [int]$TimeoutSeconds = 30,
  [switch]$AllowFileSources
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

if (-not $RulesDir) {
  $repoRoot = Split-Path -Parent $PSScriptRoot
  $RulesDir = Join-Path $repoRoot "Rules"
}
if (-not $SourcesPath) {
  $SourcesPath = Join-Path $RulesDir "sources.json"
}

if (-not (Test-Path -LiteralPath $SourcesPath)) {
  throw "Missing source manifest: $SourcesPath"
}

$manifest = Get-Content -LiteralPath $SourcesPath -Raw -Encoding UTF8 | ConvertFrom-Json
$errors = New-Object System.Collections.Generic.List[string]
$client = [System.Net.Http.HttpClient]::new()
$client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)
$client.DefaultRequestHeaders.UserAgent.ParseAdd("Rabbit-Spec-Surge-Source-Health/1.0")

function Add-HealthError {
  param([string]$Message)
  $errors.Add($Message) | Out-Null
}

function Test-LocalSource {
  param([string]$Url)

  if ($Url -match "^file://") {
    $uri = [System.Uri]$Url
    return (Test-Path -LiteralPath $uri.LocalPath)
  }

  return (Test-Path -LiteralPath $Url)
}

try {
  foreach ($rule in $manifest.rules) {
    foreach ($source in $rule.sources) {
      $url = [string]$source.url

      if ($AllowFileSources -and (Test-LocalSource -Url $url)) {
        Write-Host "OK local $($rule.target) <- $url"
        continue
      }

      if ($url -notmatch "^https://") {
        Add-HealthError "$($rule.target) source is not https://: $url"
        continue
      }

      try {
        $request = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Head, $url)
        $response = $client.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()

        if (-not $response.IsSuccessStatusCode) {
          $response.Dispose()
          $response = $client.GetAsync($url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        }

        if ($response.IsSuccessStatusCode) {
          Write-Host "OK $($rule.target) <- $url"
        }
        else {
          Add-HealthError "$($rule.target) source returned HTTP $([int]$response.StatusCode): $url"
        }
      }
      catch {
        Add-HealthError "$($rule.target) source failed: $url ($($_.Exception.Message))"
      }
      finally {
        if ($response) {
          $response.Dispose()
          $response = $null
        }
        if ($request) {
          $request.Dispose()
          $request = $null
        }
      }
    }
  }
}
finally {
  $client.Dispose()
}

if ($errors.Count -gt 0) {
  Write-Error ("Rule source health check failed:`n" + ($errors -join "`n"))
  exit 1
}

Write-Host "Rule source health check passed."
