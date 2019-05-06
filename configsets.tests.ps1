
Import-Module $PSScriptRoot -Force

Describe "Assert-HomogenousConfig" {

  $NonHomogenousConfigContainer = "$PSScriptRoot\test\non-homogenous"
  $HomogenousConfigContainer = "$PSScriptRoot\test\homogenous"

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

Describe "Merge-Object" {

  $arraysWithoutDuplicates = (1..5), (6..10)
  $arraysWithoutDuplicatesMerged = 1..10
  $arraysWithDuplicates = (1..7), (4..12)
  $arraysWithDuplicatesMerged = 1..12
  $objectsWithoutDuplicates = [PSCustomObject]@{ a = 1 }, [PSCustomObject]@{ b = 2 }
  $objectsWithoutDuplicatesMerged = [PSCustomObject]@{a = 1; b = 2 }
  $objectsWithDuplicates = [PSCustomObject]@{ a = 1; b = 2 }, [PSCustomObject]@{ b = 3; c = 4 }
  $objectsWithDuplicatesMerged = [PSCustomObject]@{ a = 1; b = 3; c = 4 }
  $inequalValues = "cat", 14
  $inequalValuesMerged = 14
  $equalValues = "bear", "bear"
  $equalValuesMerged = "bear"

  Context "Given an 'Override' merge strategy" {
    It "Should merge arrays without duplicates" {
      $merged = $arraysWithoutDuplicates | Merge-Object -Strategy Override
      $merged | Should -HaveCount $arraysWithoutDuplicatesMerged.Count
    }
    It "Should merge arrays with duplicates" {
      $merged = $arraysWithDuplicates | Merge-Object -Strategy Override
      $merged | Should -HaveCount $arraysWithDuplicatesMerged.Count
    }
    It "Should merge objects without duplicates" {
      $merged = $objectsWithoutDuplicates | Merge-Object -Strategy Override
      $merged | Should -Be $objectsWithoutDuplicatesMerged
    }
    It "Should merge objects with duplicates" {
      $merged = $objectsWithDuplicates | Merge-Object -Strategy Override
      $merged | Should -Be $objectsWithDuplicatesMerged
    }
    It "Should override inequal values" {
      $merged = $inequalValues | Merge-Object -Strategy Override
      $merged | Should -Be $inequalValuesMerged
    }
    It "Should override equal values" {
      $merged = $equalValues | Merge-Object -Strategy Override
      $merged | Should -Be $equalValuesMerged
    }
  }

  Context "Given a 'Fail' merge strategy" {
    It "Should merge arrays without duplicates" {
      $arraysWithoutDuplicates `
      | Merge-Object -Strategy Fail `
      | Should -Be $arraysWithoutDuplicatesMerged
    }
    It "Should fail to merge arrays with duplicates" {
      $arraysWithDuplicates `
      | Merge-Object -Strategy Fail `
      | Should -Throw
    }
    It "Should merge objects without duplicates" {
      $objectsWithoutDuplicates `
      | Merge-Object -Strategy Fail `
      | Should -Be $objectsWithoutDuplicatesMerged
    }
    It "Should fail to merge objects with duplicates" {
      $objectsWithDuplicates `
      | Merge-Object -Strategy Fail `
      | Should -Throw
    }
    It "Should fail to merge inequal values" {
      $inequalValues `
      | Merge-Object -Strategy Fail `
      | Should -Be $inequalValuesMerged
    }
    It "Should merge equal values" {
      $equalValues `
      | Merge-Object -Strategy Fail `
      | Should -Be $equalValuesMerged
    }
  }

}
