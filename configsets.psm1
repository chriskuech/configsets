
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
    [ValidateScript( { Test-Path $_ } )]
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

function merge($a, $b, $strategy) {
  if ($a -is [psobject] -and $b -is [psobject]) { 
    $merged = @{ }
    $a.psobject.Properties.Name + $b.psobject.Properties.Name `
    | Sort -Unique `
    | % { $merged[$_] = merge $a.$_ $b.$_ $strategy }
    return [pscustomobject]$merged
  }
  if ($a -is [array] -and $b -is [array]) {
    return $a + $b | Sort -Unique
  }
  return &$strategy $a $b
}

$strategyFn = @{
  Override = {
    Param($a, $b)
    @{$true = $a; $false = $b }[$null -eq $b]
  }
  Fail     = {
    Param($a, $b)
    $err = "Cannot merge type '$($a.GetType())' and '$($b.GetType())'"
    @{$true = $a; $false = (throw $err) }[$null -eq $b]
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
    [PSCustomObject[]]$Configs,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [MergeStrategy]$Strategy
  )

  $accum = [pscustomobject]::new()
  foreach ($config in $Configs) {
    $accum = merge $accum $config $strategyFn[$Strategy]
  }
  return $accum
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
function Assert-HomogenousConfig {
  Param(
    # Path to the folder containing the configs
    [Parameter(Mandatory)]
    [ValidateScript( { Test-Path $_ } )]
    [string] $Container
  )

  $configs = Get-ChildItem $Container
  $dimensions = $configs | Group { ($_.BaseName -split "-").Count }
  $extensions = $configs | Group Extension
  
  if ($dimensions.Count -ne 1) {
    throw "Configs vary in number of dimensions"
  }
  if ($extensions.Count -ne 1) {
    throw "Found multiple different extensions"
  }
}
