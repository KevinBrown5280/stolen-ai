# Post Stories to ADO
# Usage: .\post-stories.ps1 -InputFile "stories.json" -ParentId 12345 -Org "myorg" -Project "myproject"
#        .\post-stories.ps1 -InputFile "stories.json" -ParentId 12345 -Org "myorg" -Project "myproject" -DryRun
# Reads JSON matching schemas/stories-output.schema.json, creates User Stories under the parent Feature.

param(
    [Parameter(Mandatory)]
    [string]$InputFile,

    [Parameter(Mandatory)]
    [string]$ParentId,

    [Parameter(Mandatory)]
    [string]$Org,

    [Parameter(Mandatory)]
    [string]$Project,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$orgUrl = "https://dev.azure.com/$Org"

# --- Schema validation ---
$rawJson = Get-Content $InputFile -Raw

# Detect duplicate keys (common LLM output defect)
# Split into individual story objects and check for repeated keys within each
$storyBlocks = [regex]::Matches($rawJson, '\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}')
foreach ($block in $storyBlocks) {
    $keys = [regex]::Matches($block.Value, '"(\w+)"\s*:') | ForEach-Object { $_.Groups[1].Value }
    $dupes = $keys | Group-Object | Where-Object { $_.Count -gt 1 }
    if ($dupes) {
        Write-Error "Schema validation failed: duplicate JSON key '$($dupes[0].Name)' detected in a story object. Regenerate the stories JSON."
        exit 1
    }
}

$stories = @($rawJson | ConvertFrom-Json)

if ($stories.Count -eq 0) {
    Write-Error "Schema validation failed: input must be a non-empty JSON array of story objects."
    exit 1
}

$requiredFields = @('title', 'description', 'acceptanceCriteria', 'briefMarkdown')
for ($i = 0; $i -lt $stories.Count; $i++) {
    $story = $stories[$i]
    foreach ($field in $requiredFields) {
        if (-not $story.PSObject.Properties[$field] -or [string]::IsNullOrWhiteSpace($story.$field)) {
            Write-Error "Schema validation failed: story[$i] is missing required field '$field'."
            exit 1
        }
    }
}

Write-Host "Schema validation passed: $($stories.Count) stories, all required fields present."
# --- End schema validation ---

if ($DryRun) {
    $outputDir = Split-Path $InputFile -Parent
    if (-not $outputDir) { $outputDir = "." }
    $reviewFile = Join-Path $outputDir "stories-review.md"

    $md = @()
    $md += "# Stories Review — Feature $ParentId"
    $md += ""
    $md += "**Org:** $orgUrl  "
    $md += "**Project:** $Project  "
    $md += "**Stories:** $($stories.Count)"
    $md += ""
    $md += "---"

    for ($i = 0; $i -lt $stories.Count; $i++) {
        $s = $stories[$i]
        $md += ""
        $md += "## [$($i + 1)] $($s.title)"
        $md += ""
        $md += "**Description:** $($s.description)"
        $md += ""
        $md += "### Acceptance Criteria"
        $md += '```'
        $md += $s.acceptanceCriteria
        $md += '```'
        $md += ""

        # Negative Constraints (optional field)
        if ($s.PSObject.Properties['negativeConstraints'] -and $s.negativeConstraints.Count -gt 0) {
            $md += "### Negative Constraints"
            $md += ""
            foreach ($nc in $s.negativeConstraints) {
                $md += "- $nc"
            }
            $md += ""
        }

        $md += "### Implementation Brief"
        $md += $s.briefMarkdown
        $md += ""
        $md += "---"
    }

    $md -join "`n" | Out-File -FilePath $reviewFile -Encoding utf8
    Write-Host "Schema validation passed: $($stories.Count) stories."
    Write-Host "Review file written: $reviewFile"
    exit 0
}

$results = @()

# Get access token for REST attachment upload
$token = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query accessToken -o tsv
$uploadHeaders = @{ Authorization = "Bearer $token"; "Content-Type" = "application/octet-stream" }

# Inherit area/iteration/service line from parent Feature
$parent = az boards work-item show --id $ParentId --org $orgUrl --output json | ConvertFrom-Json
$areaPath = $parent.fields.'System.AreaPath'
$iterationPath = $parent.fields.'System.IterationPath'
$serviceLine = $parent.fields.'Tas.ServiceLine'

foreach ($story in $stories) {
    # Build description with negative constraints appended
    $fullDescription = $story.description
    if ($story.PSObject.Properties['negativeConstraints'] -and $story.negativeConstraints.Count -gt 0) {
        $ncList = ($story.negativeConstraints | ForEach-Object { "• $_" }) -join "`n"
        $fullDescription += "`n`n**Negative Constraints:**`n$ncList"
    }

    # Create the User Story (without multiline AC field to avoid argument parsing issues)
    $item = $null
    try {
        $item = az boards work-item create `
            --type "User Story" `
            --title $story.title `
            --description $fullDescription `
            --org $orgUrl `
            --project $Project `
            --fields "System.AreaPath=$areaPath" `
                     "System.IterationPath=$iterationPath" `
                     "Tas.ServiceLine=$serviceLine" `
                     "Tas.UserStoryType=User Story" `
            --output json | ConvertFrom-Json
    } catch {
        Write-Warning "Failed to create story: $($story.title)"
        Write-Warning "$_"
        continue
    }
    if (-not $item -or -not $item.id) {
        Write-Warning "Failed to create story (no id returned): $($story.title)"
        continue
    }

    # Update with multiline Acceptance Criteria via REST API
    # AC is an HTML field — convert newlines to <br> so they render correctly
    try {
        $acHtml = $story.acceptanceCriteria -replace "`r`n", "<br>" -replace "`n", "<br>"
        $patchBody = ConvertTo-Json -Depth 3 -InputObject @(
            @{ op = "add"; path = "/fields/Microsoft.VSTS.Common.AcceptanceCriteria"; value = $acHtml }
        )
        $patchHeaders = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json-patch+json" }
        Invoke-RestMethod -Uri "$orgUrl/_apis/wit/workitems/$($item.id)?api-version=7.1" -Method Patch -Headers $patchHeaders -Body ([System.Text.Encoding]::UTF8.GetBytes($patchBody)) | Out-Null
    } catch {
        Write-Warning "Failed to set AC for Story #$($item.id): $_"
    }

    # Link to parent Feature
    az boards work-item relation add `
        --id $item.id `
        --relation-type "parent" `
        --target-id $ParentId `
        --org $orgUrl `
        --output none

    # Attach the .md brief (two-step: upload file via REST, then link)
    $briefPath = [System.IO.Path]::GetTempPath() + "$($item.id)-brief.md"
    $story.briefMarkdown | Out-File -FilePath $briefPath -Encoding utf8

    $briefBytes = [System.IO.File]::ReadAllBytes($briefPath)
    $uploadUrl = "$orgUrl/$Project/_apis/wit/attachments?fileName=$($item.id)-brief.md&api-version=7.1"
    try {
        $uploadResponse = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $uploadHeaders -Body $briefBytes
        $attachmentUrl = $uploadResponse.url

        az boards work-item relation add `
            --id $item.id `
            --relation-type "Attached File" `
            --target-url $attachmentUrl `
            --org $orgUrl `
            --output none
    } catch {
        Write-Warning "Failed to upload/attach brief for Story #$($item.id): $_"
    }

    Remove-Item $briefPath -ErrorAction SilentlyContinue

    $results += @{
        id    = $item.id
        title = $story.title
        url   = $item.url
    }

    Write-Host "Created Story #$($item.id): $($story.title)"
}

# Post slice summary as a Discussion comment on the parent Feature
$commentHtml = "<h3>&#x1F4CB; Stories sliced from this Feature</h3><ul>"
foreach ($r in $results) {
    $commentHtml += "<li><a href=`"$orgUrl/$Project/_workitems/edit/$($r.id)`">#$($r.id)</a> — $($r.title)</li>"
}
$commentHtml += "</ul><p><em>Posted by plan-feature • $(Get-Date -Format 'yyyy-MM-dd HH:mm')</em></p>"

try {
    $commentBody = @{ text = $commentHtml } | ConvertTo-Json -Depth 2
    $commentHeaders = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
    Invoke-RestMethod -Uri "$orgUrl/$Project/_apis/wit/workItems/$ParentId/comments?api-version=7.1-preview.4" -Method Post -Headers $commentHeaders -Body ([System.Text.Encoding]::UTF8.GetBytes($commentBody)) | Out-Null
    Write-Host "Posted slice summary comment on Feature #$ParentId"
} catch {
    Write-Warning "Failed to post summary comment on Feature #$ParentId`: $_"
}

$results | ConvertTo-Json -Depth 3 | Write-Output
