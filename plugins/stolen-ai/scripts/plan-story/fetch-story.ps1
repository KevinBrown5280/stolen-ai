#requires -Version 7.0

# Fetch Story from ADO (with attachments)
# Usage: .\fetch-story.ps1 -StoryId 12345 -Org "myorg" -Project "myproject"
#        .\fetch-story.ps1 -WorkItemId 12345 -Org "myorg" -Project "myproject"
# Output: JSON with Story fields, discussions, downloaded images, and .md brief content

param(
    [Parameter(Mandatory)]
    [Alias('WorkItemId')]
    [string]$StoryId,

    [Parameter(Mandatory)]
    [string]$Org,

    [Parameter(Mandatory)]
    [string]$Project,

    [string]$OutputDirectory,

    [ValidateRange(1, 200)]
    [int]$MaxDiscussionComments = 50
)

$ErrorActionPreference = "Stop"
$orgUrl = "https://dev.azure.com/$Org"
$adoResource = "499b84ac-1321-427f-aa17-267ca6975798"
$schemaPath = Join-Path $PSScriptRoot "../../schemas/fetch-story-output.schema.json"

if (-not $OutputDirectory) {
    $defaultFolder = [Environment]::GetFolderPath("MyDocuments")
    $OutputDirectory = Join-Path -Path $defaultFolder -ChildPath "UserStoryOutput/$StoryId/attachments"
}

$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$outputParent = Split-Path $OutputDirectory -Parent
$outputName = Split-Path $OutputDirectory -Leaf
$stagingDirectory = Join-Path $outputParent ".$outputName.staging-$([guid]::NewGuid())"

function Get-AdoAccessToken {
    if (-not $script:adoAccessToken) {
        $result = & az account get-access-token --resource $adoResource --query accessToken -o tsv --only-show-errors 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Azure CLI token request failed: $(($result | Out-String).Trim())"
        }

        $script:adoAccessToken = ($result | Out-String).Trim()
    }

    return $script:adoAccessToken
}

function Get-StoryWorkItem {
    $result = & az boards work-item show --id $StoryId --org $orgUrl --expand relations --output json --only-show-errors 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Could not fetch ADO work item $StoryId`: $(($result | Out-String).Trim())"
    }

    try {
        return ($result | Out-String) | ConvertFrom-Json
    }
    catch {
        throw "ADO returned invalid JSON for work item $StoryId`: $($_.Exception.Message)"
    }
}

function Get-ParentId {
    param($Item)

    $relationsProperty = $Item.PSObject.Properties['relations']
    if ($null -eq $relationsProperty) {
        return $null
    }

    $parentRelation = @($relationsProperty.Value | Where-Object { $_.rel -eq "System.LinkTypes.Hierarchy-Reverse" } | Select-Object -First 1)
    if ($parentRelation.Count -eq 0) {
        return $null
    }

    $parentIdMatch = [regex]::Match([string]$parentRelation[0].url, '/(?<id>\d+)(?:\?.*)?$')
    if (-not $parentIdMatch.Success) {
        return $null
    }

    return [int]$parentIdMatch.Groups['id'].Value
}

function ConvertTo-SafeFileName {
    param([string]$FileName)

    if (-not $FileName) {
        return "file"
    }

    $invalidFileNameChars = [IO.Path]::GetInvalidFileNameChars()
    return -join ($FileName.ToCharArray() | ForEach-Object {
        if ($invalidFileNameChars -contains $_) { '_' } else { $_ }
    })
}

function ConvertTo-IsoDateString {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    try {
        return ([DateTimeOffset]$Value).ToString("o")
    }
    catch {
        return [string]$Value
    }
}

function Get-InlineImageReferences {
    param(
        [AllowEmptyString()]
        [string]$Html
    )

    if ([string]::IsNullOrEmpty($Html)) {
        return @()
    }

    return @([regex]::Matches($Html, '<img\b[^>]*?\bsrc\s*=\s*["''](?<url>[^"'']+)["'']', [Text.RegularExpressions.RegexOptions]::IgnoreCase) |
        ForEach-Object { [Net.WebUtility]::HtmlDecode($_.Groups['url'].Value) })
}

function Save-InlineImages {
    param(
        [AllowEmptyString()]
        [string]$Html,

        [string]$FilePrefix,

        [hashtable]$ImageCache
    )

    $downloadedImages = @()
    $sourceUrls = @(Get-InlineImageReferences -Html $Html)
    $imageIndex = 0

    foreach ($sourceUrl in $sourceUrls) {
        if ($ImageCache.ContainsKey($sourceUrl)) {
            $downloadedImages += $ImageCache[$sourceUrl]
            continue
        }

        $imageIndex++
        $sourceUri = $null
        if (-not [Uri]::TryCreate($sourceUrl, [UriKind]::Absolute, [ref]$sourceUri)) {
            $metadata = [PSCustomObject]@{
                sourceUrl  = $sourceUrl
                path       = $null
                status     = "skipped"
                skipReason = "invalidUrl"
            }
            $ImageCache[$sourceUrl] = $metadata
            $downloadedImages += $metadata
            continue
        }

        $isAdoHost = $sourceUri.Host -eq "dev.azure.com" -or $sourceUri.Host -like "*.visualstudio.com"
        if ($sourceUri.Scheme -ne "https" -or -not $isAdoHost) {
            $metadata = [PSCustomObject]@{
                sourceUrl  = $sourceUrl
                path       = $null
                status     = "skipped"
                skipReason = "externalUrl"
            }
            $ImageCache[$sourceUrl] = $metadata
            $downloadedImages += $metadata
            continue
        }

        $fileNameMatch = [regex]::Match($sourceUri.Query, '(?:^|[?&])fileName=(?<name>[^&]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($fileNameMatch.Success) {
            $fileName = [Uri]::UnescapeDataString($fileNameMatch.Groups['name'].Value)
        }
        else {
            $fileName = [IO.Path]::GetFileName($sourceUri.LocalPath)
        }

        if (-not $fileName) {
            $fileName = "image.png"
        }

        $safeFileName = ConvertTo-SafeFileName -FileName $fileName
        $relativeName = "{0}-{1:D2}-{2}" -f $FilePrefix, $imageIndex, $safeFileName
        $stagingPath = Join-Path $stagingDirectory $relativeName
        $finalPath = Join-Path $OutputDirectory $relativeName
        Invoke-WebRequest -Uri $sourceUrl -Headers @{ Authorization = "Bearer $(Get-AdoAccessToken)" } -OutFile $stagingPath | Out-Null

        $metadata = [PSCustomObject]@{
            sourceUrl  = $sourceUrl
            path       = $finalPath
            status     = "downloaded"
            skipReason = $null
        }
        $ImageCache[$sourceUrl] = $metadata
        $downloadedImages += $metadata
    }

    return $downloadedImages
}

function Publish-StagedDirectory {
    $backupDirectory = Join-Path $outputParent ".$outputName.backup-$([guid]::NewGuid())"
    $hasBackup = $false

    try {
        if (Test-Path -LiteralPath $OutputDirectory) {
            Move-Item -LiteralPath $OutputDirectory -Destination $backupDirectory
            $hasBackup = $true
        }

        Move-Item -LiteralPath $stagingDirectory -Destination $OutputDirectory

        if ($hasBackup) {
            Remove-Item -LiteralPath $backupDirectory -Recurse -Force
        }
    }
    catch {
        if (-not (Test-Path -LiteralPath $OutputDirectory) -and $hasBackup) {
            Move-Item -LiteralPath $backupDirectory -Destination $OutputDirectory -ErrorAction SilentlyContinue
        }

        throw
    }
}

$item = Get-StoryWorkItem

if ($item.fields.'System.WorkItemType' -ne 'User Story') {
    throw "Work item $StoryId is not a User Story (found: $($item.fields.'System.WorkItemType'))"
}

New-Item -ItemType Directory -Path $outputParent -Force | Out-Null
New-Item -ItemType Directory -Path $stagingDirectory -Force | Out-Null

try {
    $imageCache = @{}
    $parentId = Get-ParentId -Item $item
    $encodedProject = [Uri]::EscapeDataString($Project)
    $commentsUrl = "$orgUrl/$encodedProject/_apis/wit/workItems/$StoryId/comments?api-version=7.1-preview.4&%24top=$MaxDiscussionComments&order=desc"
    $commentsResponse = Invoke-RestMethod -Uri $commentsUrl -Headers @{ Authorization = "Bearer $(Get-AdoAccessToken)" }
    $comments = @($commentsResponse.comments)
    $discussions = @($comments | Sort-Object createdDate | ForEach-Object {
        [PSCustomObject]@{
            id           = [int]$_.id
            author       = [string]$_.createdBy.displayName
            createdDate  = ConvertTo-IsoDateString -Value $_.createdDate
            modifiedDate = ConvertTo-IsoDateString -Value $_.modifiedDate
            text         = [string]$_.text
            inlineImages = @(Save-InlineImages -Html ([string]$_.text) -FilePrefix "discussion-$($_.id)" -ImageCache $imageCache)
        }
    })
    $discussionsTruncated = -not [string]::IsNullOrEmpty([string]$commentsResponse.continuationToken)

    $attachmentRelations = @($item.relations | Where-Object { $_.rel -eq "AttachedFile" })
    $markdownAttachments = @($attachmentRelations |
        Where-Object { $_.attributes.name -like "*.md" } |
        Sort-Object { $_.attributes.resourceCreatedDate } -Descending)
    $briefRelation = $markdownAttachments | Select-Object -First 1
    if ($markdownAttachments.Count -gt 1) {
        Write-Warning "Story has multiple .md attachments. Using the most recent as briefMarkdown."
    }

    $briefContent = ""
    $downloadedAttachments = @()
    $attachmentIndex = 0
    foreach ($attachmentRelation in $attachmentRelations) {
        $attachmentIndex++
        $safeFileName = ConvertTo-SafeFileName -FileName ([string]$attachmentRelation.attributes.name)
        $relativeName = "attachment-{0:D2}-{1}" -f $attachmentIndex, $safeFileName
        $stagingPath = Join-Path $stagingDirectory $relativeName
        $finalPath = Join-Path $OutputDirectory $relativeName
        Invoke-WebRequest -Uri $attachmentRelation.url -Headers @{ Authorization = "Bearer $(Get-AdoAccessToken)" } -OutFile $stagingPath | Out-Null
        $downloadedFile = Get-Item -LiteralPath $stagingPath
        $downloadedAttachments += [PSCustomObject]@{
            name                = [string]$attachmentRelation.attributes.name
            path                = $finalPath
            size                = $downloadedFile.Length
            resourceCreatedDate = ConvertTo-IsoDateString -Value $attachmentRelation.attributes.resourceCreatedDate
        }

        if ($briefRelation -and $attachmentRelation.url -eq $briefRelation.url) {
            $briefContent = Get-Content -LiteralPath $stagingPath -Raw
        }
    }

    $description = [string]$item.fields.'System.Description'
    $outputObject = [PSCustomObject]@{
        id                   = [int]$item.id
        title                = [string]$item.fields.'System.Title'
        description          = $description
        acceptanceCriteria   = ([string]$item.fields.'Microsoft.VSTS.Common.AcceptanceCriteria') -replace '<br\s*/?>', "`n"
        state                = [string]$item.fields.'System.State'
        parentId             = $parentId
        briefMarkdown        = $briefContent
        attachments          = $downloadedAttachments
        inlineImages         = @(Save-InlineImages -Html $description -FilePrefix "description" -ImageCache $imageCache)
        discussions          = $discussions
        discussionsTruncated = $discussionsTruncated
    }
    $outputJson = $outputObject | ConvertTo-Json -Depth 8
    if (-not ($outputJson | Test-Json -SchemaFile $schemaPath)) {
        throw "Fetch output did not match schema: $schemaPath"
    }

    Publish-StagedDirectory

    $storyJsonPath = Join-Path $outputParent "story.json"
    $storyJsonStaging = "$storyJsonPath.staging-$([guid]::NewGuid())"
    Set-Content -LiteralPath $storyJsonStaging -Value $outputJson -Encoding utf8
    Move-Item -LiteralPath $storyJsonStaging -Destination $storyJsonPath -Force

    Write-Output $outputJson
}
catch {
    if (Test-Path -LiteralPath $stagingDirectory) {
        Remove-Item -LiteralPath $stagingDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }

    throw "Failed to fetch Story $StoryId`: $($_.Exception.Message)"
}
