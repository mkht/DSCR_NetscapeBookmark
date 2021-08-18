#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

BeforeAll {
    $Root = (Split-Path $PSScriptRoot -Parent)
    Import-Module (Join-Path $Root 'Utils\Validate-DateTime.psm1') -Force -DisableNameChecking
}

Describe 'Validate-DateTime' {

    BeforeEach {
        $script:out = $null
    }

    It 'Input:$null => Output:$true' {
        $in = $null
        { $script:out = Validate-DateTime $in } | Should -Not -Throw
        $script:out | Should -Be $true
    }

    It 'Input:Greater than UnixEpochTime => Output:$true' {
        $in = [datetime]::new(2021, 1, 1, 0, 0, 0, 0, [System.DateTimeKind]::utc)
        { $script:out = Validate-DateTime $in } | Should -Not -Throw
        $script:out | Should -Be $true
    }

    It 'Input:UnixEpochTime => Output:$true' {
        $in = [datetime]::new(1970, 1, 1, 0, 0, 0, 0, [System.DateTimeKind]::utc)
        { $script:out = Validate-DateTime $in } | Should -Not -Throw
        $script:out | Should -Be $true
    }

    It 'Input:Less than UnixEpochTime => throw ArgumentOutOfRangeException' {
        $in = [datetime]::new(1969, 12, 31, 23, 59, 59, [System.DateTimeKind]::utc)
        { $script:out = Validate-DateTime $in } | Should -Throw -ExceptionType ([System.ArgumentOutOfRangeException])
        $script:out | Should -Be $null
    }
}
