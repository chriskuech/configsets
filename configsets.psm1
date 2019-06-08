
Import-Module Functional

$ErrorActionPreference = "Stop"

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
  [CmdletBinding()]
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
  [CmdletBinding()]
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
  Selects appropriate configs based on the selector
.DESCRIPTION
  Selects all configs that match the selector with wildcards
.OUTPUTS
  The selected config files
#>
function Select-Config {
  [CmdletBinding()]
  [OutputType([System.IO.FileSystemInfo])]
  Param(
    # String identifier for the set
    [Parameter(Mandatory, ParameterSetName = "Id")]
    [ValidatePattern("^[^-]+(-[^-]+)*$")]
    [string] $Id,
    # An array of individual type instances for the set
    [Parameter(Mandatory, ParameterSetName = "Vector")]
    [ValidateCount(1, 255)]
    [string[]] $Vector,
    # Path to the folder containing the configs
    [Parameter(Mandatory, ParameterSetName = "Id")]
    [Parameter(Mandatory, ParameterSetName = "Vector")]
    [ValidateScript( { Test-Path $_ -PathType Container } )]
    [string] $Container
  )
  
  if (-not $Id) {
    $Id = $Vector -join "-"
  }

  $globPattern = $Id -replace "_", "*"
  Get-ChildItem $Container | ? { $_.BaseName -replace "_", "*" -like $globPattern }
}
