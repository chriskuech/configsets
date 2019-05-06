
New-Alias -Name Sort -Value Sort-Object

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

function merge($a, $b, $strategy) {
  Write-host "a $a : $($a.GetType()), b $b : $($b.GetType())"
  if ($a -is [psobject] -and $b -is [psobject]) { 
    $merged = @{ }
    $props = $a.psobject.Properties.Name + $b.psobject.Properties.Name
    $a.psobject.Properties.Name + $b.psobject.Properties.Name `
    | Sort -Unique `
    | % { $merged[$_] = merge $a.$_ $b.$_ $strategy }
    return [PSCustomObject]$merged
  }
  if ($a -is [array] -and $b -is [array]) {
    return $a + $b | Sort -Unique
  }
  return &$strategy $a $b
}

$strategyFn = @{
  Override = {
    Param($a, $b)
    @{ $true = $a; $false = $b }[$null -eq $b]
  }
  Fail     = {
    Param($a, $b)
    $err = "Cannot merge type '$($a.GetType())' and '$($b.GetType())'"
    $lazy = @{ $true = { $a }; $false = { throw $err } }[$null -eq $b -or $a -eq $b]
    &$lazy
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
    [array] $Configs,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [MergeStrategy] $Strategy
  )
  
  $accum = $input | Select -First 1
  foreach ($config in $input | Select -Skip 1) {
    $accum = merge $accum $config $strategyFn[$Strategy]
  }
  return $accum
}

