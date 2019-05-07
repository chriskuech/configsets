
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

function getType($v) {
  if ($null -eq $v) { "null" } else { $v.GetType() }
}

function merge($a, $b, [scriptblock]$strategy) {
  Write-Debug "a is pscustomobject: $($a -is [pscustomobject])"
  Write-Debug "merge $a`: $(getType $a), $b`: $(getType $b)"
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
  if ($a -is [pscustomobject] -and $b -is [pscustomobject]) {
    Write-Debug "a is pscustomobject: $($a -is [pscustomobject])"
    Write-Debug "merge objects '$a' '$b'"
    Write-Debug "merge objects $(getType $a) $(getType $b)"
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

