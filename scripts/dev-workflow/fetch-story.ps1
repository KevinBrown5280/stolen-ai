# Fetch Story from ADO (with attachments)
# Usage: .\fetch-story.ps1 -StoryId 12345 -Org "myorg" -Project "myproject"
# Output: JSON with Story fields + downloaded .md brief content

param(
    [Parameter(Mandatory)]
    [string]$StoryId,

    [Parameter(Mandatory)]
    [string]$Org,

    [Parameter(Mandatory)]
    [string]$Project
)

$ErrorActionPreference = "Stop"
$orgUrl = "https://dev.azure.com/$Org"

$item = az boards work-item show --id $StoryId --org $orgUrl --expand relations --output json | ConvertFrom-Json

if ($item.fields.'System.WorkItemType' -ne 'User Story') {
    Write-Error "Work item $StoryId is not a User Story (found: $($item.fields.'System.WorkItemType'))"
    exit 1
}

# Extract brief from attachments (look for .md files)
$briefContent = ""
if ($item.relations) {
    $attachment = $item.relations | Where-Object { $_.rel -eq "AttachedFile" -and $_.attributes.name -like "*.md" } | Select-Object -First 1
    if ($attachment) {
        $token = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query accessToken -o tsv
        $briefContent = Invoke-RestMethod -Uri $attachment.url -Headers @{ Authorization = "Bearer $token" }
    }
}

$output = @{
    id                 = $item.id
    title              = $item.fields.'System.Title'
    description        = $item.fields.'System.Description'
    acceptanceCriteria = ($item.fields.'Microsoft.VSTS.Common.AcceptanceCriteria') -replace '<br\s*/?>', "`n"
    state              = $item.fields.'System.State'
    briefMarkdown      = $briefContent
} | ConvertTo-Json -Depth 5

Write-Output $output
