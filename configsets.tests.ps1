
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

Describe "Select-Config" {
  
  $container = "$PSScriptRoot\test\many"
  
  Context "Given an ID" {
    It "Should select all configs that match the selector with wildcards" {
      $selector = "a-_-c"
      $found = Select-Config -Id $selector -Container $container | % BaseName
      $expected = "a-_-c", "a-b-_", "a-b-c"
      @($found), @($expected) | Test-Equality | Should -BeTrue
    }
    It "Should select a single config with non-wildcard selector" {
      $selector = "a-b-c"
      $found = Select-Config -Id $selector -Container $container | % BaseName
      $expected = "a-_-c", "a-b-_", "a-b-c"
      @($found), @($expected) | Test-Equality | Should -BeTrue
    }
    It "Should fail to select a non-existent config" {
      $selector = "x-y-z"
      $found = Select-Config -Id $selector -Container $container | % BaseName
      $found | Should -BeNullOrEmpty
    }
  }
  
  Context "Given a Vector" {
    It "Should select all configs that match the selector with wildcards" {
      $selector = @("a", "_", "c")
      $found = Select-Config -Vector $selector -Container $container | % BaseName
      $expected = "a-_-c", "a-b-_", "a-b-c"
      @($found), @($expected) | Test-Equality | Should -BeTrue
    }
    It "Should select a single config with non-wildcard selector" {
      $selector = @("a", "b", "c")
      $found = Select-Config -Vector $selector -Container $container | % BaseName
      $expected = "a-_-c", "a-b-_", "a-b-c"
      @($found), @($expected) | Test-Equality | Should -BeTrue
    }
    It "Should fail to select a non-existent config" {
      $selector = @("x", "y", "z")
      $found = Select-Config -Vector $selector -Container $container | % BaseName
      $found | Should -BeNullOrEmpty
    }
  }
  
}