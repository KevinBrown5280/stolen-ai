# Persist Plan - writes spec file, commits to branch, posts to ADO discussion
# Usage: .\persist-plan.ps1 -InputFile "plan.json" -Feature "password-reset" -Org "myorg" -Project "myproject"

param(
    [Parameter(Mandatory)]
    [string]$InputFile,

    [Parameter(Mandatory)]
    [string]$Feature,

    [Parameter(Mandatory)]
    [string]$Org,

    [Parameter(Mandatory)]
    [string]$Project
)

$ErrorActionPreference = "Stop"
$orgUrl = "https://dev.azure.com/$Org"

$plan = Get-Content $InputFile -Raw | ConvertFrom-Json

# --- 1. Write spec file ---
$specDir = "specs/$Feature"
if (-not (Test-Path $specDir)) { New-Item -ItemType Directory -Path $specDir -Force | Out-Null }

$storySlug = $plan.storyTitle -replace '[^a-zA-Z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''
$specFile = "$specDir/$($storySlug.ToLower()).md"

$specContent = @"
# $($plan.storyTitle)

## Decisions
$($plan.decisions | ForEach-Object { "- **$($_.decision)**: $($_.rationale)" } | Out-String)

## Tasks
$($plan.tasks | ForEach-Object {
    $deps = if ($_.dependsOn) { " (depends on: $($_.dependsOn -join ', '))" } else { "" }
    "### $($_.id): $($_.title)$deps`n$($_.description)`n"
} | Out-String)
"@

$specContent | Out-File -FilePath $specFile -Encoding utf8
Write-Host "Wrote spec: $specFile"

# --- 2. Auto-commit to feature branch ---
git add $specFile
git commit -m "docs: add implementation spec for $($plan.storyTitle)" --quiet

Write-Host "Committed to current branch"

# --- 3. Post summary to ADO Story discussion ---
$discussionBody = "## Implementation Plan`n`n"
$discussionBody += "**Tasks ($($plan.tasks.Count)):**`n"
foreach ($task in $plan.tasks) {
    $deps = if ($task.dependsOn) { " → after: $($task.dependsOn -join ', ')" } else { "" }
    $discussionBody += "- [ ] $($task.title)$deps`n"
}
$discussionBody += "`n**Key Decisions:**`n"
foreach ($d in $plan.decisions) {
    $discussionBody += "- $($d.decision)`n"
}

# Post as comment via REST API (az boards doesn't have a discussion command)
$token = az account get-access-token --query accessToken -o tsv
$headers = @{
    Authorization  = "Bearer $token"
    "Content-Type" = "application/json"
}
$body = @{ text = $discussionBody } | ConvertTo-Json
$uri = "$orgUrl/$Project/_apis/wit/workItems/$($plan.storyId)/comments?api-version=7.1-preview.3"

Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body | Out-Null
Write-Host "Posted plan to Story #$($plan.storyId) discussion"

Write-Host "Done."
