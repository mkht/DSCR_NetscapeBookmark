#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'TestHelper.psm1') -Force
}

Describe 'NetscapeBookmarkFolder' {

    BeforeAll {
        $InvokeDscGet = @{
            Name       = 'NetscapeBookmarkFolder'
            Method     = 'Get'
            ModuleName = 'DSCR_NetscapeBookmark'
        }

        $InvokeDscTest = @{
            Name       = 'NetscapeBookmarkFolder'
            Method     = 'Test'
            ModuleName = 'DSCR_NetscapeBookmark'
        }

        $InvokeDscSet = @{
            Name       = 'NetscapeBookmarkFolder'
            Method     = 'Set'
            ModuleName = 'DSCR_NetscapeBookmark'
        }
    }

    BeforeEach {
        $sample = Join-Path $PSScriptRoot 'samples'
        Get-ChildItem -Path $sample -Recurse | Copy-Item -Destination 'TestDrive:\' -Force
    }

    Context 'Get-TargetResource' {

        It 'The bookmark file does not exist' {
            $DscProps = @{
                Path  = 'C:\notexist\missing.html'
                Title = 'TestTitle'
            }
            $GetResource = Invoke-DscResource @InvokeDscGet -Property $DscProps
            $GetResource.Ensure | Should -Be 'Absent'
        }

        It 'The bookmark file is invalid' {
            $DscProps = @{
                Path  = (Join-Path $TestDrive 'invalid.html')
                Title = 'TestTitle'
            }
            $GetResource = Invoke-DscResource @InvokeDscGet -Property $DscProps
            $GetResource.Ensure | Should -Be 'Absent'
        }

        It 'The bookmark exist' {
            $DscProps = @{
                Path  = (Join-Path $TestDrive 'bookmark.html')
                Title = 'お気に入りバー'
            }
            $GetResource = Invoke-DscResource @InvokeDscGet -Property $DscProps
            $GetResource.Ensure | Should -Be 'Present'
            $GetResource.Title | Should -Be 'お気に入りバー'
            $GetResource.AddDate.ToUniversalTime() | Should -Be ([datetime]::new(2021, 8, 6, 15, 22, 59, [DateTimeKind]::Utc))
            $GetResource.ModifiedDate.ToUniversalTime() | Should -Be ([datetime]::new(2021, 8, 6, 15, 23, 44, [DateTimeKind]::Utc))
        }

    }

    Context 'Test-TargetResource' {

        It '[<Ensure>] The bookmark file does not exist' -Foreach @(
            @{ Ensure = 'Present'; Expected = $false }
            @{ Ensure = 'Absent'; Expected = $true }
        ) {
            $DscProps = @{
                Path   = 'C:\notexist\missing.html'
                Title  = 'TestTitle'
                Ensure = $Ensure
            }
            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $Expected
        }

        It '[<Ensure>] The bookmark file is invalid' -Foreach @(
            @{ Ensure = 'Present'; Expected = $false }
            @{ Ensure = 'Absent'; Expected = $true }
        ) {
            $DscProps = @{
                Path   = (Join-Path $TestDrive 'invalid.html')
                Title  = 'TestTitle'
                Ensure = $Ensure
            }
            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $Expected
        }

        It '[<Correctness>] Test for ADD_DATE' -Foreach @(
            @{ Correctness = 'Correct'; Date = ([datetime]::new(2021, 8, 6, 15, 22, 59, [DateTimeKind]::Utc)) ; Expected = $true }
            @{ Correctness = 'InCorrect'; Date = ([datetime]::now) ; Expected = $false }
        ) {
            $DscProps = @{
                Path    = (Join-Path $TestDrive 'bookmark.html')
                Title   = 'お気に入りバー'
                AddDate = $Date
            }
            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $Expected
        }

        It '[<Correctness>] Test for LAST_MODIFIED' -Foreach @(
            @{ Correctness = 'Correct'; Date = ([datetime]::new(2021, 8, 6, 15, 23, 44, [DateTimeKind]::Utc)) ; Expected = $true }
            @{ Correctness = 'InCorrect'; Date = ([datetime]::now) ; Expected = $false }
        ) {
            $DscProps = @{
                Path         = (Join-Path $TestDrive 'bookmark.html')
                Title        = 'お気に入りバー'
                ModifiedDate = $Date
            }
            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $Expected
        }

        It '[<Correctness>] Test for Attributes' -Foreach @(
            @{ Correctness = 'Correct'; Attributes = @{PERSONAL_TOOLBAR_FOLDER = 'true' } ; Expected = $true }
            @{ Correctness = 'InCorrect1'; Attributes = @{PERSONAL_TOOLBAR_FOLDER = 'false' } ; Expected = $false }
            @{ Correctness = 'InCorrect2'; Attributes = @{SOMEONE_ELSE = 'John' } ; Expected = $false }
        ) {
            $DscProps = @{
                Path       = (Join-Path $TestDrive 'bookmark.html')
                Title      = 'お気に入りバー'
                Attributes = $Attributes
            }
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $DscProps.Attributes = ConvertTo-CimInstance -Hashtable $Attributes
            }

            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $Expected
        }

        It 'DateTime boundary test [<AddDate>]' -Foreach @(
            @{ AddDate = [datetime]::MinValue; Not = $false }
            @{ AddDate = [datetime]::MaxValue; Not = $true }
            @{ AddDate = [datetime]::new(1969, 12, 31, 23, 59, 59, [DateTimeKind]::Utc); Not = $false }
            @{ AddDate = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc); Not = $true }
        ) {
            $DscProps = @{
                Path    = (Join-Path $TestDrive 'bookmark.html')
                Title   = 'お気に入りバー'
                AddDate = $AddDate
            }
            { Invoke-DscResource @InvokeDscTest -Property $DscProps -ErrorAction Stop } | Should -Throw -Not:$Not
        }
    }

    Context 'Set-TargetResource' {

        It '[Absent] The bookmark file does not exist' {
            $DscProps = @{
                Path   = Join-Path $TestDrive '\notexist\missing.html'
                Title  = 'TestTitle'
                Ensure = 'Absent'
            }
            Invoke-DscResource @InvokeDscSet -Property $DscProps
            $DscProps.Path | Should -Not -Exist

            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $true
        }

        It '[Present] The bookmark file does not exist' {
            $DscProps = @{
                Path   = Join-Path $TestDrive 'missing.html'
                Title  = 'TestTitle'
                Ensure = 'Present'
            }
            Invoke-DscResource @InvokeDscSet -Property $DscProps
            $DscProps.Path | Should -Exist
            Get-Content $DscProps.Path -Raw -Encoding utf8 | Should -BeExactly (@'
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!-- This is an automatically generated file.
     It will be read and overwritten.
     DO NOT EDIT! -->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
    <DT><H3>TestTitle</H3>
    <DL><p>
    </DL><p>
</DL><p>

'@)

            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $true
        }

        It '[Absent] Remove folder' {
            $DscProps = @{
                Path   = (Join-Path $TestDrive 'bookmark.html')
                Title  = 'お気に入りバー'
                Ensure = 'Absent'
            }
            Invoke-DscResource @InvokeDscSet -Property $DscProps
            $DscProps.Path | Should -Exist
            Get-Content $DscProps.Path -Raw -Encoding utf8 | Should -BeExactly (@'
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!-- This is an automatically generated file.
     It will be read and overwritten.
     DO NOT EDIT! -->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
</DL><p>

'@)

            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $true
        }

        It '[Present] Add folder' {
            $DscProps = @{
                Path   = Join-Path $TestDrive 'bookmark2.html'
                Title  = 'NewFolder'
                Ensure = 'Present'
            }
            Invoke-DscResource @InvokeDscSet -Property $DscProps
            $DscProps.Path | Should -Exist
            Get-Content $DscProps.Path -Raw -Encoding utf8 | Should -BeExactly (@'
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!-- This is an automatically generated file.
     It will be read and overwritten.
     DO NOT EDIT! -->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
    <DT><H3 ADD_DATE="1628263379" LAST_MODIFIED="1628263424" PERSONAL_TOOLBAR_FOLDER="true">お気に入りバー</H3>
    <DL><p>
        <DT><A HREF="https://twitter.com/">Twitter</A>
    </DL><p>
    <DT><H3>NewFolder</H3>
    <DL><p>
    </DL><p>
</DL><p>

'@)

            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $true
        }


        It '[Present] Change folder properties' {
            $date = ([datetime]::new(2039, 1, 1, 0, 0, 0, [DateTimeKind]::Utc))
            $DscProps = @{
                Path         = Join-Path $TestDrive 'bookmark2.html'
                Title        = 'お気に入りバー'
                AddDate      = $date
                ModifiedDate = $date
                Attributes   = @{PERSONAL_TOOLBAR_FOLDER = 'test' }
                Ensure       = 'Present'
            }
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $DscProps.Attributes = ConvertTo-CimInstance -Hashtable $DscProps.Attributes
            }

            Invoke-DscResource @InvokeDscSet -Property $DscProps
            $DscProps.Path | Should -Exist
            Get-Content $DscProps.Path -Raw -Encoding utf8 | Should -BeExactly (@'
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!-- This is an automatically generated file.
     It will be read and overwritten.
     DO NOT EDIT! -->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
    <DT><H3 ADD_DATE="2177452800" LAST_MODIFIED="2177452800" PERSONAL_TOOLBAR_FOLDER="test">お気に入りバー</H3>
    <DL><p>
        <DT><A HREF="https://twitter.com/">Twitter</A>
    </DL><p>
</DL><p>

'@)

            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $true
        }

        It 'DateTime boundary test [<AddDate>]' -Foreach @(
            @{ AddDate = [datetime]::MinValue; Not = $false }
            @{ AddDate = [datetime]::MaxValue; Not = $true }
            @{ AddDate = [datetime]::new(1969, 12, 31, 23, 59, 59, [DateTimeKind]::Utc); Not = $false }
            @{ AddDate = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc); Not = $true }
        ) {
            $DscProps = @{
                Path    = (Join-Path $TestDrive 'bookmark.html')
                Title   = 'お気に入りバー'
                AddDate = $AddDate
            }
            { Invoke-DscResource @InvokeDscSet -Property $DscProps -ErrorAction Stop } | Should -Throw -Not:$Not
        }
    }
}
