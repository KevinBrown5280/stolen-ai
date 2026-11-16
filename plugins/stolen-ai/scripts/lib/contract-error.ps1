# Shared failure reporting for scripts whose input comes from an AI step or user-supplied IDs.
# Exit codes: 0 = success, 1 = runtime/external failure (stop and report),
# 2 = caller-fixable contract failure (stderr carries one JSON line with a repairHint).

function Exit-ContractError {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory)]
        [string]$RepairHint,

        [string[]]$AllowedValues
    )

    $payload = [ordered]@{ error = $Message; repairHint = $RepairHint }
    if ($AllowedValues) { $payload.allowedValues = $AllowedValues }
    [Console]::Error.WriteLine(($payload | ConvertTo-Json -Compress))
    exit 2
}

function Assert-JsonMatchesSchema {
    param(
        [Parameter(Mandatory)]
        [string]$Json,

        [Parameter(Mandatory)]
        [string]$SchemaPath,

        [Parameter(Mandatory)]
        [string]$RepairHint
    )

    $schemaErrors = $null
    $isValid = $Json | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue -ErrorVariable schemaErrors
    if (-not $isValid) {
        $details = ($schemaErrors | ForEach-Object { $_.Exception.Message } | Select-Object -First 5) -join '; '
        Exit-ContractError -Message "Schema validation failed against $(Split-Path $SchemaPath -Leaf): $details" -RepairHint $RepairHint
    }
}
