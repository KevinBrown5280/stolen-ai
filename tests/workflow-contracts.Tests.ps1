$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$scriptsRoot = Join-Path $PSScriptRoot "..\plugins\stolen-ai\scripts"
$pwsh = (Get-Command pwsh -ErrorAction Stop).Source
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "stolenai-contract-tests-$([guid]::NewGuid())"
$failures = @()
$caseCount = 0

function Invoke-WorkflowScript {
    param(
        [string]$Script,
        [hashtable]$Parameters,
        [string]$Directory
    )

    $scriptPath = (Join-Path $scriptsRoot $Script).Replace("'", "''")
    $workingDirectory = $Directory.Replace("'", "''")
    $callLog = (Join-Path $Directory "external-calls.txt").Replace("'", "''")
    $parameterJson = ($Parameters | ConvertTo-Json -Compress).Replace("'", "''")
    $wrapper = @"
`$ErrorActionPreference = 'Stop'
function global:git {
    Add-Content -LiteralPath '$callLog' -Value 'git'
    throw 'Unexpected git invocation'
}
function global:az {
    Add-Content -LiteralPath '$callLog' -Value 'az'
    throw 'Unexpected az invocation'
}
function global:Invoke-RestMethod {
    Add-Content -LiteralPath '$callLog' -Value 'REST'
    throw 'Unexpected REST invocation'
}
Set-Location -LiteralPath '$workingDirectory'
`$parameters = '$parameterJson' | ConvertFrom-Json -AsHashtable
& '$scriptPath' @parameters
exit `$LASTEXITCODE
"@
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($wrapper))
    $output = & $pwsh -NoProfile -NonInteractive -OutputFormat Text -EncodedCommand $encodedCommand 2>&1

    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = $output -join "`n"
    }
}

function Assert-RejectedBeforeWrites {
    param($Result, [string]$Directory)

    if ($Result.ExitCode -ne 2) {
        throw "Invalid input should exit 2 (caller-fixable contract failure), got $($Result.ExitCode): $($Result.Output)"
    }
    if ($Result.Output -notmatch "schema") {
        throw "Input failed for a reason other than contract validation: $($Result.Output)"
    }
    $contractError = $Result.Output -split "`n" | Where-Object { $_ -match '^\{"error"' } | Select-Object -First 1
    if (-not $contractError -or -not ($contractError | ConvertFrom-Json).repairHint) {
        throw "Contract failure did not emit a JSON repairHint: $($Result.Output)"
    }
    foreach ($path in @("external-calls.txt", "stories-review.md", "specs")) {
        if (Test-Path -LiteralPath (Join-Path $Directory $path)) {
            throw "Invalid input produced a side effect: $path"
        }
    }
}

function Invoke-TestCase {
    param([string]$Name, [scriptblock]$Body)

    $script:caseCount++
    $directory = Join-Path $testRoot "case-$caseCount"
    New-Item -ItemType Directory -Path $directory | Out-Null
    try {
        & $Body $directory
        Write-Host "PASS: $Name"
    } catch {
        $script:failures += "${Name}: $_"
        Write-Host "FAIL: ${Name}: $_"
    }
}

$storyJson = '{"title":"View documents","description":"<p>List visible documents.</p>","acceptanceCriteria":"<p>Only visible documents appear.</p>","briefMarkdown":"# Documents\nExisting interface only."}'
$specJson = '{"storyId":"123","storyTitle":"View documents","decisions":[],"tasks":[{"id":"list-documents","title":"List documents","description":"Use the existing list interface.","testStrategy":"Manual: Verify only visible documents appear.","files":["src\\Documents.cs"],"dependsOn":[]}]}'

New-Item -ItemType Directory -Path $testRoot | Out-Null
try {
    Invoke-TestCase "Reject more than eight stories before any write" {
        param($directory)
        $inputFile = Join-Path $directory "input.json"
        $json = "[" + ((1..9 | ForEach-Object { $storyJson }) -join ",") + "]"
        Set-Content -LiteralPath $inputFile -Value $json
        $result = Invoke-WorkflowScript -Script "plan-feature\post-stories.ps1" -Directory $directory -Parameters @{
            InputFile = $inputFile
            ParentId = "123"
            Org = "test-org"
            Project = "test-project"
            DryRun = $true
        }
        Assert-RejectedBeforeWrites $result $directory
    }

    Invoke-TestCase "Reject a wrapped stories object instead of silently rewriting it" {
        param($directory)
        $inputFile = Join-Path $directory "input.json"
        Set-Content -LiteralPath $inputFile -Value ('{"stories":[' + $storyJson + ']}')
        $result = Invoke-WorkflowScript -Script "plan-feature\post-stories.ps1" -Directory $directory -Parameters @{
            InputFile = $inputFile
            ParentId = "123"
            Org = "test-org"
            Project = "test-project"
            DryRun = $true
        }
        Assert-RejectedBeforeWrites $result $directory
    }

    Invoke-TestCase "Reject invalid constraint types before invoking ADO" {
        param($directory)
        $inputFile = Join-Path $directory "input.json"
        $story = $storyJson | ConvertFrom-Json -AsHashtable
        $story.negativeConstraints = @(42)
        Set-Content -LiteralPath $inputFile -Value (ConvertTo-Json -InputObject @($story) -Depth 5)
        $result = Invoke-WorkflowScript -Script "plan-feature\post-stories.ps1" -Directory $directory -Parameters @{
            InputFile = $inputFile
            ParentId = "123"
            Org = "test-org"
            Project = "test-project"
        }
        Assert-RejectedBeforeWrites $result $directory
    }

    foreach ($storyCount in @(1, 8)) {
        Invoke-TestCase "Render a review for $storyCount valid stories without external writes" {
            param($directory)
            $inputFile = Join-Path $directory "input.json"
            $json = "[" + ((1..$storyCount | ForEach-Object { $storyJson }) -join ",") + "]"
            Set-Content -LiteralPath $inputFile -Value $json
            $result = Invoke-WorkflowScript -Script "plan-feature\post-stories.ps1" -Directory $directory -Parameters @{
                InputFile = $inputFile
                ParentId = "123"
                Org = "test-org"
                Project = "test-project"
                DryRun = $true
            }
            if ($result.ExitCode -ne 0) { throw $result.Output }
            $review = Get-Content -LiteralPath (Join-Path $directory "stories-review.md") -Raw
            if (-not $review.Contains("**Stories:** $storyCount") -or -not $review.Contains("## [$storyCount] View documents")) {
                throw "The review did not show the submitted story count and title."
            }
            if (Test-Path -LiteralPath (Join-Path $directory "external-calls.txt")) {
                throw "DryRun invoked an external operation."
            }
        }
    }

    Invoke-TestCase "Post stories when Azure CLI emits diagnostics alongside JSON" {
        param($directory)
        $inputFile = Join-Path $directory "input.json"
        Set-Content -LiteralPath $inputFile -Value "[$storyJson]"
        $scriptPath = (Join-Path $scriptsRoot "plan-feature\post-stories.ps1").Replace("'", "''")
        $testDirectory = $directory.Replace("'", "''")
        $inputPath = $inputFile.Replace("'", "''")
        $wrapper = @"
`$ErrorActionPreference = 'Stop'
`$env:TEMP = '$testDirectory'
function global:az {
    `$global:LASTEXITCODE = 0
    if (`$args[0] -eq 'account') { return 'fake-token' }
    if (`$args[0] -eq 'boards' -and `$args[2] -eq 'show') {
        return 'WARNING: Unable to encode the output', '{"id":123}'
    }
    if (`$args[0] -eq 'boards' -and `$args[2] -eq 'create') {
        if (`$args -notcontains '--query') { throw 'Create response is not narrowed' }
        Write-Error -Message 'CLI diagnostic' -ErrorAction Continue
        return '{"id":98765432,"url":"https://example.test/workitems/98765432"}'
    }
    if (`$args[0] -eq 'boards' -and `$args[2] -eq 'relation') { return }
    throw 'Unexpected Azure CLI invocation'
}
function global:Invoke-RestMethod {
    param(`$Uri, `$Method, `$Headers, `$Body)
    if (`$Uri -like '*/workitems/123?*' -and -not `$Method) {
        return [pscustomobject]@{ fields = [pscustomobject]@{
            'System.AreaPath' = 'Area'
            'System.IterationPath' = 'Iteration'
            'Tas.ServiceLine' = 'Service'
        } }
    }
    if (`$Uri -like '*/attachments?*') { return @{ url = 'https://example.test/attachment' } }
    if (`$Method -in @('Patch', 'Post')) { return @{} }
    throw 'Unexpected REST invocation'
}
& '$scriptPath' -InputFile '$inputPath' -ParentId 123 -Org test-org -Project test-project
exit `$LASTEXITCODE
"@
        $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($wrapper))
        $output = & $pwsh -NoProfile -NonInteractive -OutputFormat Text -EncodedCommand $encodedCommand 2>&1
        if ($LASTEXITCODE -ne 0 -or ($output -join "`n") -notmatch 'Created Story #98765432') {
            throw "Posting failed on mixed CLI output: $($output -join "`n")"
        }
    }

    Invoke-TestCase "Reject an incomplete spec before creating files" {
        param($directory)
        $inputFile = Join-Path $directory "input.json"
        Set-Content -LiteralPath $inputFile -Value '{"storyId":"123","storyTitle":"View documents","tasks":[{"id":"list-documents","title":"List documents"}],"decisions":[]}'
        $result = Invoke-WorkflowScript -Script "plan-story\persist-spec.ps1" -Directory $directory -Parameters @{
            InputFile = $inputFile
            Org = "test-org"
            Project = "test-project"
            DryRun = $true
            SkipPost = $true
        }
        Assert-RejectedBeforeWrites $result $directory
    }

    Invoke-TestCase "Reject invalid dependency types before committing or posting" {
        param($directory)
        $inputFile = Join-Path $directory "input.json"
        $spec = $specJson | ConvertFrom-Json -AsHashtable
        $spec.tasks[0].dependsOn = "not-an-array"
        Set-Content -LiteralPath $inputFile -Value ($spec | ConvertTo-Json -Depth 5)
        $result = Invoke-WorkflowScript -Script "plan-story\persist-spec.ps1" -Directory $directory -Parameters @{
            InputFile = $inputFile
            Org = "test-org"
            Project = "test-project"
        }
        Assert-RejectedBeforeWrites $result $directory
    }

    Invoke-TestCase "Persist a valid spec and readable view without committing or posting" {
        param($directory)
        $inputFile = Join-Path $directory "input.json"
        Set-Content -LiteralPath $inputFile -Value $specJson
        $parameters = @{
            InputFile = $inputFile
            Org = "test-org"
            Project = "test-project"
            DryRun = $true
        }
        $result = Invoke-WorkflowScript -Script "plan-story\persist-spec.ps1" -Directory $directory -Parameters $parameters
        if ($result.ExitCode -ne 0) { throw $result.Output }
        $specFile = Join-Path $directory "specs\123\spec.json"
        $saved = Get-Content -LiteralPath $specFile -Raw
        $readme = Get-Content -LiteralPath (Join-Path $directory "specs\123\spec.readme.md") -Raw
        if ($saved.Trim() -ne $specJson -or -not $readme.Contains("### list-documents: List documents")) {
            throw "Persist did not preserve the approved spec and readable task."
        }
        $parameters.InputFile = $specFile
        $parameters.SkipPost = $true
        $repeat = Invoke-WorkflowScript -Script "plan-story\persist-spec.ps1" -Directory $directory -Parameters $parameters
        if ($repeat.ExitCode -ne 0) { throw $repeat.Output }
        if ((Get-Content -LiteralPath $specFile -Raw).Trim() -ne $specJson) {
            throw "Persisting the existing spec changed its content."
        }
        if (Test-Path -LiteralPath (Join-Path $directory "external-calls.txt")) {
            throw "DryRun invoked an external operation."
        }
    }
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}

if ($failures.Count -gt 0) {
    throw "$($failures.Count) workflow contract test(s) failed."
}
Write-Host "All $caseCount workflow contract tests passed."
