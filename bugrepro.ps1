
$json = Get-Content $PSScriptRoot\test\good.params.json -Raw
$schemaUri = ($json | ConvertFrom-Json).'$schema' -replace "#.*"
[string]$schema = Invoke-WebRequest $schemaUri
Write-Host "Validating JSON"
Write-Host "JSON"
$json
Write-Host "Schema"
$schema
Test-Json -Json $json -Schema $schema
