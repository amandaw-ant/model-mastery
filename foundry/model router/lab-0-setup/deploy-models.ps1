#requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [string]$ResourceGroup,

    [Parameter(Mandatory)]
    [string]$AccountName,

    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+/api/projects/.+$')]
    [string]$ProjectEndpoint,

    [ValidateSet('BroadCurrent', 'Gpt54Tier', 'Gpt5Tier')]
    [string]$GptFamilyProfile = 'BroadCurrent',

    [string]$BaselineModelName = 'gpt-5.4',
    [string]$BaselineModelVersion = '2026-03-05',
    [string]$BaselineDeploymentName = 'baseline-gpt',
    [string]$GptRouterDeploymentName = 'router-gpt-family',
    [string]$OpenWeightRouterDeploymentName = 'router-open-weight',

    [ValidateSet('balanced', 'quality', 'cost')]
    [string]$RoutingMode = 'balanced',

    [ValidateRange(1, 1000000)]
    [int]$BaselineCapacity = 1000,

    [ValidateRange(1, 1000000)]
    [int]$RouterCapacity = 1000,

    [string]$EnvFile = (Join-Path (Split-Path $PSScriptRoot -Parent) '.env')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$routerVersion = '2025-11-18'
$deploymentApiVersion = '2025-10-01-preview'

function Invoke-AzJson {
    param([Parameter(Mandatory)][string[]]$AzArguments)

    $output = & az @AzArguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI failed: az $($AzArguments -join ' ')`n$($output -join [Environment]::NewLine)"
    }

    if (-not $output) {
        return $null
    }

    ($output -join [Environment]::NewLine) | ConvertFrom-Json
}

function Get-GptFamilyModels {
    param([Parameter(Mandatory)][string]$Profile)

    switch ($Profile) {
        'Gpt54Tier' {
            @(
                @{ name = 'gpt-5.4'; version = '2026-03-05' }
                @{ name = 'gpt-5.4-mini'; version = '2026-03-17' }
                @{ name = 'gpt-5.4-nano'; version = '2026-03-17' }
            )
        }
        'Gpt5Tier' {
            @(
                @{ name = 'gpt-5'; version = '2025-08-07' }
                @{ name = 'gpt-5-mini'; version = '2025-08-07' }
                @{ name = 'gpt-5-nano'; version = '2025-08-07' }
            )
        }
        default {
            @(
                @{ name = 'gpt-5.6-sol'; version = '2026-07-09' }
                @{ name = 'gpt-5.6-terra'; version = '2026-07-09' }
                @{ name = 'gpt-5.6-luna'; version = '2026-07-09' }
                @{ name = 'gpt-5.5'; version = '2026-04-24' }
                @{ name = 'gpt-5.4'; version = '2026-03-05' }
                @{ name = 'gpt-5.4-mini'; version = '2026-03-17' }
                @{ name = 'gpt-5.4-nano'; version = '2026-03-17' }
                @{ name = 'gpt-5.2'; version = '2025-12-11' }
                @{ name = 'gpt-5'; version = '2025-08-07' }
                @{ name = 'gpt-5-mini'; version = '2025-08-07' }
                @{ name = 'gpt-5-nano'; version = '2025-08-07' }
            )
        }
    }
}

function Resolve-CatalogModel {
    param(
        [Parameter(Mandatory)][object[]]$Catalog,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Version
    )

    $match = $Catalog |
        Where-Object {
            $_.model.name -eq $Name -and
            $_.model.version -eq $Version -and
            @($_.model.skus.name) -contains 'GlobalStandard'
        } |
        Select-Object -First 1

    if (-not $match) {
        throw "Model '$Name' version '$Version' is not available with GlobalStandard in the account region."
    }

    [ordered]@{
        format = $match.model.format
        name = $Name
        version = $Version
    }
}

function Set-FoundryDeployment {
    param(
        [Parameter(Mandatory)][string]$DeploymentName,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Model,
        [Parameter(Mandatory)][int]$Capacity,
        [object[]]$RoutingModels = @()
    )

    $properties = [ordered]@{ model = $Model }
    if ($RoutingModels.Count -gt 0) {
        $properties['routing'] = [ordered]@{
            mode = $RoutingMode
            models = $RoutingModels
        }
    }

    $payload = [ordered]@{
        sku = [ordered]@{ name = 'GlobalStandard'; capacity = $Capacity }
        properties = $properties
    }

    if (-not $PSCmdlet.ShouldProcess("$AccountName/$DeploymentName", 'Create or update Foundry model deployment')) {
        return
    }

    $url = "https://management.azure.com$($script:FoundryAccount.id)/deployments/$DeploymentName`?api-version=$deploymentApiVersion"
    $tempFile = [IO.Path]::GetTempFileName()

    try {
        $json = $payload | ConvertTo-Json -Depth 10
        [IO.File]::WriteAllText($tempFile, $json, [Text.UTF8Encoding]::new($false))
        $output = & az rest --method put --url $url --headers 'Content-Type=application/json' --body "@$tempFile" --only-show-errors --output none 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Deployment '$DeploymentName' failed.`n$($output -join [Environment]::NewLine)"
        }
    }
    finally {
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }

    $deployment = Invoke-AzJson @(
        'cognitiveservices', 'account', 'deployment', 'show',
        '--resource-group', $ResourceGroup,
        '--name', $AccountName,
        '--deployment-name', $DeploymentName,
        '--subscription', $SubscriptionId,
        '--only-show-errors',
        '--output', 'json'
    )

    if ($deployment.properties.provisioningState -ne 'Succeeded') {
        throw "Deployment '$DeploymentName' finished with state '$($deployment.properties.provisioningState)'."
    }

    if (
        $deployment.properties.model.format -ne $Model.format -or
        $deployment.properties.model.name -ne $Model.name -or
        $deployment.properties.model.version -ne $Model.version
    ) {
        throw "Deployment '$DeploymentName' does not contain the requested model and version."
    }

    if ($deployment.sku.name -ne 'GlobalStandard' -or $deployment.sku.capacity -ne $Capacity) {
        throw "Deployment '$DeploymentName' does not contain the requested GlobalStandard capacity $Capacity."
    }

    if ($RoutingModels.Count -gt 0) {
        $expected = @($RoutingModels | ForEach-Object { "$($_.format)/$($_.name)/$($_.version)" } | Sort-Object)
        $actual = @($deployment.properties.routing.models | ForEach-Object { "$($_.format)/$($_.name)/$($_.version)" } | Sort-Object)
        if (@(Compare-Object $expected $actual).Count -gt 0) {
            throw "Deployment '$DeploymentName' does not contain the requested routing subset."
        }
    }

    Write-Host "Validated $DeploymentName -> $($deployment.properties.model.name) ($($deployment.properties.provisioningState))"
}

function Set-DotEnvValue {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Lines,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    $pattern = '^\s*' + [regex]::Escape($Name) + '\s*='
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $pattern) {
            $Lines[$index] = "$Name=$Value"
            return
        }
    }

    $Lines.Add("$Name=$Value")
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI is required. Install it, then run az login before this script.'
}

Invoke-AzJson @('account', 'show', '--only-show-errors', '--output', 'json') | Out-Null
& az account set --subscription $SubscriptionId --only-show-errors
if ($LASTEXITCODE -ne 0) {
    throw "Unable to select subscription '$SubscriptionId'."
}

$script:FoundryAccount = Invoke-AzJson @(
    'cognitiveservices', 'account', 'show',
    '--resource-group', $ResourceGroup,
    '--name', $AccountName,
    '--subscription', $SubscriptionId,
    '--only-show-errors',
    '--output', 'json'
)

$catalog = @(Invoke-AzJson @(
    'cognitiveservices', 'model', 'list',
    '--location', $script:FoundryAccount.location,
    '--subscription', $SubscriptionId,
    '--only-show-errors',
    '--output', 'json'
))

$routerModel = Resolve-CatalogModel -Catalog $catalog -Name 'model-router' -Version $routerVersion
$baselineModel = Resolve-CatalogModel -Catalog $catalog -Name $BaselineModelName -Version $BaselineModelVersion
$gptModels = @(Get-GptFamilyModels -Profile $GptFamilyProfile | ForEach-Object {
    Resolve-CatalogModel -Catalog $catalog -Name $_.name -Version $_.version
})
$openWeightModels = @(
    Resolve-CatalogModel -Catalog $catalog -Name 'gpt-oss-120b' -Version '1'
    Resolve-CatalogModel -Catalog $catalog -Name 'Llama-4-Maverick-17B-128E-Instruct-FP8' -Version '1'
    Resolve-CatalogModel -Catalog $catalog -Name 'DeepSeek-V3.2' -Version '1'
)

Write-Host "Target: $AccountName ($($script:FoundryAccount.location)), subscription $SubscriptionId"
Write-Host "GPT router profile: $GptFamilyProfile ($($gptModels.Count) models)"

Set-FoundryDeployment -DeploymentName $BaselineDeploymentName -Model $baselineModel -Capacity $BaselineCapacity
Set-FoundryDeployment -DeploymentName $GptRouterDeploymentName -Model $routerModel -Capacity $RouterCapacity -RoutingModels $gptModels
Set-FoundryDeployment -DeploymentName $OpenWeightRouterDeploymentName -Model $routerModel -Capacity $RouterCapacity -RoutingModels $openWeightModels

if ($PSCmdlet.ShouldProcess($EnvFile, 'Update workshop deployment environment settings')) {
    $lines = [System.Collections.Generic.List[string]]::new()
    if (Test-Path $EnvFile) {
        Get-Content $EnvFile | ForEach-Object { $lines.Add($_) }
    }

    Set-DotEnvValue -Lines $lines -Name 'AZURE_AI_PROJECT_ENDPOINT' -Value $ProjectEndpoint.TrimEnd('/')
    Set-DotEnvValue -Lines $lines -Name 'BASELINE_GPT_DEPLOYMENT' -Value $BaselineDeploymentName
    Set-DotEnvValue -Lines $lines -Name 'GPT_FAMILY_ROUTER_DEPLOYMENT' -Value $GptRouterDeploymentName
    Set-DotEnvValue -Lines $lines -Name 'OPEN_WEIGHT_ROUTER_DEPLOYMENT' -Value $OpenWeightRouterDeploymentName
    Set-DotEnvValue -Lines $lines -Name 'MODEL_ROUTER_DEPLOYMENT' -Value $OpenWeightRouterDeploymentName
    Set-DotEnvValue -Lines $lines -Name 'AZURE_TOKEN_CREDENTIALS' -Value 'AzureCliCredential'

    [IO.File]::WriteAllLines($EnvFile, $lines, [Text.UTF8Encoding]::new($false))
    Write-Host "Updated $EnvFile. The active notebook deployment is $OpenWeightRouterDeploymentName."
}

if ($WhatIfPreference) {
    Write-Host 'Preview complete. No deployments or environment files were changed.'
}
else {
    Write-Host 'All three comparison deployments are ready.'
}
