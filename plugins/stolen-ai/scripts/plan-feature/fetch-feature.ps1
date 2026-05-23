# Fetch Feature from ADO
# Usage: .\fetch-feature.ps1 -FeatureId 12345 -Org "myorg" -Project "myproject"
# Output: JSON with Feature fields written to stdout

param(
    [Parameter(Mandatory)]
    [string]$FeatureId,

    [Parameter(Mandatory)]
    [string]$Org,

    [Parameter(Mandatory)]
    [string]$Project
)

$ErrorActionPreference = "Stop"

$item = az boards work-item show --id $FeatureId --org "https://dev.azure.com/$Org" --output json | ConvertFrom-Json

if ($item.fields.'System.WorkItemType' -ne 'Feature') {
    Write-Error "Work item $FeatureId is not a Feature (found: $($item.fields.'System.WorkItemType'))"
    exit 1
}

$output = @{
    id          = $item.id
    title       = $item.fields.'System.Title'
    description = $item.fields.'System.Description'
    acceptanceCriteria = $item.fields.'Microsoft.VSTS.Common.AcceptanceCriteria'
    state       = $item.fields.'System.State'
    areaPath    = $item.fields.'System.AreaPath'
    iterationPath = $item.fields.'System.IterationPath'
} | ConvertTo-Json -Depth 5

Write-Output $output
