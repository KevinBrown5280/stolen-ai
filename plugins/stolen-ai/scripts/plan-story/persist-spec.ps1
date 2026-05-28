# Persist Spec - writes spec.json + generated spec.readme.md, commits to branch, posts to ADO discussion
# Usage: .\persist-spec.ps1 -InputFile "spec.json" -Org "myorg" -Project "myproject"

param(
    [Parameter(Mandatory)]
    [string]$InputFile,

    [Parameter(Mandatory)]
    [string]$Org,

    [Parameter(Mandatory)]
    [string]$Project,

    [switch]$DryRun,

    [switch]$SkipPost
)

$ErrorActionPreference = "Stop"
$orgUrl = "https://dev.azure.com/$Org"

$plan = Get-Content $InputFile -Raw | ConvertFrom-Json

# --- 1. Write spec files ---
$specDir = "specs/$($plan.storyId)"
if (-not (Test-Path $specDir)) { New-Item -ItemType Directory -Path $specDir -Force | Out-Null }

# Authoritative implementation spec (full JSON for code-story + micro-review)
$specFile = "$specDir/spec.json"
$inputFullPath = (Resolve-Path $InputFile).Path
$specFullPath = (Resolve-Path -LiteralPath $specDir).Path + [IO.Path]::DirectorySeparatorChar + "spec.json"
if ($inputFullPath -ieq $specFullPath) {
    Write-Host "InputFile is already $specFile — skipping copy."
} else {
    Copy-Item -Path $InputFile -Destination $specFile -Force
}
Write-Host "Wrote spec: $specFile"

# Generated human-readable view (DO NOT EDIT — regenerated from spec.json)
$readmeFile = "$specDir/spec.readme.md"

$specContent = @"
> **⚠️ GENERATED FILE — DO NOT EDIT**
> This is a human-readable view of ``spec.json``. Edits here are discarded on next persist.
> To revise: edit ``spec.json`` directly and re-run ``persist-spec.ps1 -SkipPost``, or ask the orchestrator to revise the plan.

# $($plan.storyTitle)

## Decisions
$($plan.decisions | ForEach-Object { "- **$($_.decision)**: $($_.rationale)" } | Out-String)

## Tasks
$($plan.tasks | ForEach-Object {
    $deps = if ($_.dependsOn) { " (depends on: $($_.dependsOn -join ', '))" } else { "" }
    "### $($_.id): $($_.title)$deps`n$($_.description)`n"
} | Out-String)
"@

$specContent | Out-File -FilePath $readmeFile -Encoding utf8
Write-Host "Wrote spec.readme.md: $readmeFile"

# --- 2. Auto-commit to feature branch ---
if ($DryRun) {
    Write-Host "[DryRun] Would commit: $specFile, $readmeFile (spec.readme.md)"
} else {
    git add $specFile $readmeFile
    git commit -m "docs: add implementation spec for $($plan.storyTitle) AB#$($plan.storyId)" --quiet -- "$specFile" "$readmeFile"
    Write-Host "Committed to current branch"
}

# --- 3. Post summary to ADO Story discussion ---
if (-not $SkipPost) {
    $discussionBody = "## Implementation Spec`n`n"
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
    # Convert to HTML for ADO rendering
    $html = $discussionBody `
        -replace '(?m)^## (.+)', '<h3>$1</h3>' `
        -replace '\*\*(.+?)\*\*', '<strong>$1</strong>' `
        -replace '(?m)^- \[ \] (.+)', '<li>☐ $1</li>' `
        -replace '(?m)^- (.+)', '<li>$1</li>' `
        -replace '(<li>.*</li>(\r?\n)?)+', '<ul>$0</ul>' `
        -replace "`r`n", "<br>" -replace "`n", "<br>"

    $html += "<br><p><em>Posted by plan-story • $(Get-Date -Format 'yyyy-MM-dd HH:mm')</em></p>"

    if ($DryRun) {
        Write-Host "[DryRun] Would post to Story #$($plan.storyId) discussion:"
        Write-Host $discussionBody
    } else {
        $token = az account get-access-token --query accessToken -o tsv
        $headers = @{
            Authorization  = "Bearer $token"
            "Content-Type" = "application/json"
        }
        $body = @{ text = $html } | ConvertTo-Json
        $uri = "$orgUrl/$Project/_apis/wit/workItems/$($plan.storyId)/comments?api-version=7.1-preview.3"

        Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body | Out-Null
        Write-Host "Posted spec to Story #$($plan.storyId) discussion"
    }
} else {
    Write-Host "Skipping ADO post (-SkipPost specified). Spec written and committed locally."
}

Write-Host "Done."
