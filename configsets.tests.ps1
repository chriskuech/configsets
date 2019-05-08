
Import-Module $PSScriptRoot -Force

Describe "Assert-HomogenousConfig" {

  $NonHomogenousConfigContainer = "$PSScriptRoot\test\bad"
  $HomogenousConfigContainer = "$PSScriptRoot\test\good"

  Context "Given non-homogenous configs" {
    It "Should throw" {
      { Assert-HomogenousConfig $NonHomogenousConfigContainer } | Should -Throw
    }
  }

  Context "Given homogenous configs" {
    It "Should not throw" {
      { Assert-HomogenousConfig $HomogenousConfigContainer } | Should -Not -Throw
    }
  }

}

Describe "Assert-ParseableJson" {

  $InvalidJsonContainer = "$PSScriptRoot\test\bad"
  $ValidJsonContainer = "$PSScriptRoot\test\good"
  
  Context "Given invalid JSONs" {
    It "Should throw" {
      { Assert-ParseableJson $InvalidJsonContainer } | Should -Throw
    }
  }

  Context "Given valid JSONs" {
    It "Should not throw" {
      { Assert-ParseableJson $ValidJsonContainer } | Should -Not -Throw
    }
  }

}

Describe "Merge-Object" {

  Context "Given an 'Override' merge strategy" {
    It "Should merge arrays without duplicates" {
      $merged = (1..5), (6..10) | Merge-Object -Strategy Override
      $merged | Should -BeOfType [int]
      $merged | Should -HaveCount 10
    }
    It "Should merge arrays with duplicates" {
      $merged = (1..7), (4..12) | Merge-Object -Strategy Override
      $merged | Should -BeOfType [int]
      $merged | Should -HaveCount 12
    }
    It "Should merge hashtables without duplicates" {
      $merged = @{ a = 1 }, @{ b = 2 } `
      | Merge-Object -Strategy Override
      $merged | Should -BeOfType [hashtable]
      $merged.Keys | Should -HaveCount 2
    }
    It "Should merge hashtables with duplicates" {
      $merged = @{ a = 1; b = 2 }, @{ b = 3; c = 4 } `
      | Merge-Object -Strategy Override
      $merged | Should -BeOfType [hashtable]
      $merged.Keys | Should -HaveCount 3
      $merged["b"] | Should -Be 3
    }
    It "Should merge objects without duplicates" {
      $merged = @{ a = 1 }, @{ b = 2 } `
      | % { [PSCustomObject]$_ } `
      | Merge-Object -Strategy Override
      $merged | Should -BeOfType [PSCustomObject]
      $merged.psobject.Properties | Should -HaveCount 2
    }
    It "Should merge objects with duplicates" {
      $merged = @{ a = 1; b = 2 }, @{ b = 3; c = 4 } `
      | % { [PSCustomObject]$_ } `
      | Merge-Object -Strategy Override
      $merged | Should -BeOfType [PSCustomObject]
      $merged.psobject.Properties | Should -HaveCount 3
      $merged.b | Should -Be 3
    }
    It "Should override inequal values" {
      $merged = "cat", 42 | Merge-Object -Strategy Override
      $merged | Should -Be 42
    }
    It "Should override equal values" {
      $merged = "cat", "cat" | Merge-Object -Strategy Override
      $merged | Should -Be "cat"
    }
  }

  Context "Given a 'Fail' merge strategy" {
    It "Should merge arrays without duplicates" {
      $merged = (1..5), (6..10) | Merge-Object -Strategy Fail
      $merged | Should -BeOfType [int]
      $merged | Should -HaveCount 10
    }
    It "Should merge arrays with duplicates" {
      $merged = (1..7), (4..12) | Merge-Object -Strategy Fail
      $merged | Should -BeOfType [int]
      $merged | Should -HaveCount 12
    }
    It "Should merge hashtables without duplicates" {
      $merged = @{ a = 1 }, @{ b = 2 } `
      | Merge-Object -Strategy Fail
      $merged | Should -BeOfType [hashtable]
      $merged.Keys | Should -HaveCount 2
    }
    It "Should fail to merge hashtables with duplicates" {
      {
        @{ a = 1; b = 2 }, @{ b = 3; c = 4 } `
        | Merge-Object -Strategy Fail
      } | Should -Throw
    }
    It "Should merge objects without duplicates" {
      $merged = @{ a = 1 }, @{ b = 2 } `
      | % { [PSCustomObject]$_ } `
      | Merge-Object -Strategy Fail
      $merged | Should -BeOfType [PSCustomObject]
      $merged.psobject.Properties | Should -HaveCount 2
    }
    It "Should fail to merge objects with duplicates" {
      {
        @{ a = 1; b = 2 }, @{ b = 3; c = 4 } `
        | % { [PSCustomObject]$_ } `
        | Merge-Object -Strategy Fail
      } | Should -Throw
    }
    It "Should fail to merge inequal values" {
      { "cat", 42 | Merge-Object -Strategy Fail } `
      | Should -Throw
    }
    It "Should merge equal values" {
      $merged = "cat", "cat" | Merge-Object -Strategy Fail
      $merged | Should -Be "cat"
    }
  }

}
