
using namespace Newtonsoft.Json.Schema

# I like the Windows PowerShell alias
if (-not (Get-Alias "Sort" -ErrorAction SilentlyContinue)) {
  New-Alias -Name Sort -Value Sort-Object
}

<#
.SYNOPSIS
  Asserts whether the configs in Container are homogenous
.DESCRIPTION
  Throws an error if the files in Container do not share an idententical number of dash-delimeted Types
  (ex: type1-type2-type3 has 3 types) and identical full file extension (ex: .params.json)
.NOTES
  Call this function in a PR build to ensure your configs in Container are all valid
#>
function Assert-HomogenousConfig {
  Param(
    # Path to the folder containing the configs
    [Parameter(Mandatory)]
    [ValidateScript( { Test-Path $_ -PathType Container } )]
    [string] $Container
  )

  $configs = Get-ChildItem $Container
  $dimensions = @($configs | Group { ($_.Name -replace "\..+$" -split "-").Count })
  $extensions = @($configs | Group { $_.Name -replace "^[^.]+" })
  
  if ($dimensions.Count -ne 1) {
    $dimString = ($dimensions.Name | Sort | % { "'$_'" }) -join ", "
    throw "Configs vary in number of dimensions. Found: $dimString"
  }
  if ($extensions.Count -ne 1) {
    $extString = ($extensions.Name | Sort | % { "'$_'" }) -join ", "
    throw "Found multiple different extensions: $extString"
  }
}

<#
.SYNOPSIS
  Assert whether the configs in Container are all valid JSON
.DESCRIPTION
  Reads each file in Container and throws an error if any cannot be parsed as JSON
.NOTES
  Call this function in a PR build to ensure your configs in Container are all valid
#>
function Assert-ParseableJson {
  Param(
    # Path to the folder containing the configs
    [Parameter(Mandatory)]
    [ValidateScript( { Test-Path $_ -PathType Container } )]
    [string] $Container
  )

  $invalidJsons = Get-ChildItem $Container `
  | ? { -not (Get-Content $_ -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue) } `
  | % Name
  if ($invalidJsons) {
    throw "Found invalid JSONs:`n$invalidJsons"
  }
}

<#
.SYNOPSIS
  Short description
.DESCRIPTION
  Long description
.EXAMPLE
  PS C:\> <example usage>
  Explanation of what the example does
.INPUTS
  Inputs (if any)
.OUTPUTS
  Output (if any)
.NOTES
  General notes
#>
function Select-Config {
  [OutputType([object[]])]
  Param(
    # String identifier for the set
    [Parameter(Mandatory, ParameterSetName = "Id")]
    [ValidatePattern("^[^-]+(-[^-]+)*$")]
    [string] $Id,
    # 
    [Parameter(Mandatory, ParameterSetName = "Vector")]
    [ValidateCount(1, 255)]
    [string[]] $Vector,
    # Path to the folder containing the configs
    [Parameter(Mandatory)]
    [ValidateScript( { Test-Path $_ -PathType Container } )]
    [string] $Container
  )
  
  if (-not $Id) {
    $Id = $Vector -join "-" -replace "_", "*"
  }

  Get-ChildItem $Container | ? { $_.BaseName -like $Id }
}

enum MergeStrategy {
  Override
  Fail
}

# don't use `-is [PSCustomObject]`
# https://github.com/PowerShell/PowerShell/issues/9557
function isPsCustomObject($v) {
  $v.PSTypeNames -contains 'System.Management.Automation.PSCustomObject'
}

function merge($a, $b, [scriptblock]$strategy) {
  if ($null -eq $a) {
    Write-Debug "new assignment '$b'"
    return $b
  }
  if ($a -eq $b -or $null -eq $b) {
    Write-Debug "existing assignment '$a'"
    return $a
  }
  if ($a -is [array] -and $b -is [array]) {
    Write-Debug "merge arrays '$a' '$b'"
    return $a + $b | Sort -Unique
  }
  if ($a -is [hashtable] -and $b -is [hashtable]) {
    Write-Debug "merge hashtable '$a' '$b'"
    $merged = @{ }
    $a.Keys + $b.Keys `
    | Sort -Unique `
    | % { $merged[$_] = merge $a[$_] $b[$_] $strategy }
    return $merged
  }
  if ((isPsCustomObject $a) -and (isPsCustomObject $b)) {
    Write-Debug "a is pscustomobject: $($a -is [psobject])"
    Write-Debug "merge objects '$a' '$b'"
    $merged = @{ }
    $a.psobject.Properties + $b.psobject.Properties `
    | % Name `
    | Sort -Unique `
    | % { $merged[$_] = merge $a.$_ $b.$_ $strategy }
    return [PSCustomObject]$merged
  }
  Write-Debug "resolve conflict '$a' '$b'"
  return &$strategy $a $b 
}

$Strategies = @{
  Override = {
    Param($a, $b)
    return $b
  }
  Fail     = {
    Param($a, $b)
    throw "Cannot merge type '$($a.GetType())' and '$($b.GetType())'"
  }
}

<#
.SYNOPSIS
  Short description
.DESCRIPTION
  Long description
.EXAMPLE
  PS C:\> <example usage>
  Explanation of what the example does
.INPUTS
  Inputs (if any)
.OUTPUTS
  Output (if any)
.NOTES
  General notes
#>
function Merge-Object {
  [OutputType([object])]
  Param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [object[]] $Configs,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [MergeStrategy] $Strategy
  )
  
  $accum = $input | Select -First 1
  foreach ($config in $input | Select -Skip 1) {
    Write-Debug "accum is pscustomobject: $($accum -is [pscustomobject])"
    $accum = merge $accum $config $Strategies["$Strategy"]
  }
  return $accum
}

