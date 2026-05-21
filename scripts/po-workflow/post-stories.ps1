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

foreach ($story in $stories) {
    # Create the User Story
    $item = az boards work-item create `
        --type "User Story" `
        --title $story.title `
        --description $story.description `
        --org $orgUrl `
        --project $Project `
        --fields "Microsoft.VSTS.Common.AcceptanceCriteria=$($story.acceptanceCriteria)" `
        --output json | ConvertFrom-Json

    # Link to parent Feature
    az boards work-item relation add `
        --id $item.id `
        --relation-type "parent" `
        --target-id $ParentId `
        --org $orgUrl `
        --output none

    # Attach the .md brief
    $briefPath = [System.IO.Path]::GetTempPath() + "$($item.id)-brief.md"
    $story.briefMarkdown | Out-File -FilePath $briefPath -Encoding utf8

    az boards work-item relation add `
        --id $item.id `
        --relation-type "AttachedFile" `
        --target-url $briefPath `
        --org $orgUrl `
        --output none

    Remove-Item $briefPath -ErrorAction SilentlyContinue

    $results += @{
        id    = $item.id
        title = $story.title
        url   = $item.url
    }

    Write-Host "Created Story #$($item.id): $($story.title)"
}

$results | ConvertTo-Json -Depth 3 | Write-Output
