# Post a markdown file as a Discussion comment on an ADO work item
# Usage: .\post-comment.ps1 -WorkItemId 12345 -File "grill-summary.md" -Org "myorg" -Project "myproject"
#        .\post-comment.ps1 -WorkItemId 12345 -File "grill-summary.md" -Org "myorg" -Project "myproject" -Label "refine-feature"

param(
    [Parameter(Mandatory)]
    [string]$WorkItemId,

    [Parameter(Mandatory)]
    [string]$File,

    [Parameter(Mandatory)]
    [string]$Org,

    [Parameter(Mandatory)]
    [string]$Project,

    [string]$Label = "plan-feature"
)

$ErrorActionPreference = "Stop"
$orgUrl = "https://dev.azure.com/$Org"

if (-not (Test-Path $File)) {
    Write-Error "File not found: $File"
    exit 1
}

$markdown = Get-Content $File -Raw

# Convert markdown to basic HTML for ADO comment rendering
$html = $markdown `
    -replace '(?m)^### (.+)', '<h4>$1</h4>' `
    -replace '(?m)^## (.+)', '<h3>$1</h3>' `
    -replace '(?m)^# (.+)', '<h2>$1</h2>' `
    -replace '\*\*(.+?)\*\*', '<strong>$1</strong>' `
    -replace '(?m)^- (.+)', '<li>$1</li>' `
    -replace '(<li>.*</li>(\r?\n)?)+', '<ul>$0</ul>' `
    -replace "`r`n", "<br>" -replace "`n", "<br>"

$html += "<br><p><em>Posted by $Label • $(Get-Date -Format 'yyyy-MM-dd HH:mm')</em></p>"

$token = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query accessToken -o tsv
$headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
$body = @{ text = $html } | ConvertTo-Json -Depth 2

$response = Invoke-RestMethod `
    -Uri "$orgUrl/$Project/_apis/wit/workItems/$WorkItemId/comments?api-version=7.1-preview.4" `
    -Method Post `
    -Headers $headers `
    -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

Write-Host "Posted comment #$($response.id) on work item #$WorkItemId"
