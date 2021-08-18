#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'TestHelper.psm1') -Force
}

Describe 'NetscapeBookmarkLink' {

    BeforeAll {
        $InvokeDscGet = @{
            Name       = 'NetscapeBookmarkLink'
            Method     = 'Get'
            ModuleName = 'DSCR_NetscapeBookmark'
        }

        $InvokeDscTest = @{
            Name       = 'NetscapeBookmarkLink'
            Method     = 'Test'
            ModuleName = 'DSCR_NetscapeBookmark'
        }

        $InvokeDscSet = @{
            Name       = 'NetscapeBookmarkLink'
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
                Path   = 'C:\notexist\missing.html'
                Folder = 'TestFolder'
                Title  = 'TestTitle'
                Url    = 'http://example.com/'
            }
            $GetResource = Invoke-DscResource @InvokeDscGet -Property $DscProps
            $GetResource.Ensure | Should -Be 'Absent'
        }

        It 'The bookmark file is invalid' {
            $DscProps = @{
                Path   = Join-Path $TestDrive 'invalid.html'
                Folder = 'TestFolder'
                Title  = 'TestTitle'
                Url    = 'http://example.com/'
            }
            $GetResource = Invoke-DscResource @InvokeDscGet -Property $DscProps
            $GetResource.Ensure | Should -Be 'Absent'
        }

        It 'The bookmark exist' {
            $DscProps = @{
                Path   = Join-Path $TestDrive 'bookmark.html'
                Folder = 'お気に入りバー'
                Title  = 'Google'
                Url    = 'https://www.google.co.jp/'
            }
            $GetResource = Invoke-DscResource @InvokeDscGet -Property $DscProps
            $GetResource.Ensure | Should -Be 'Present'
            $GetResource.Folder | Should -Be 'お気に入りバー'
            $GetResource.Title | Should -Be 'Google'
            $GetResource.Url | Should -Be 'https://www.google.co.jp/'
            $GetResource.AddDate.ToUniversalTime() | Should -Be ([datetime]::new(2021, 8, 6, 15, 23, 31, [DateTimeKind]::Utc))
            $GetResource.IconData | Should -Match 'data:image/png;base64'
        }

    }

    Context 'Test-TargetResource' {

        It '[<Ensure>] The bookmark file does not exist' -Foreach @(
            @{ Ensure = 'Present'; Expected = $false }
            @{ Ensure = 'Absent'; Expected = $true }
        ) {
            $DscProps = @{
                Path   = 'C:\notexist\missing.html'
                Folder = 'TestFolder'
                Title  = 'TestTitle'
                Url    = 'http://example.com/'
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
                Path   = Join-Path $TestDrive 'invalid.html'
                Folder = 'TestFolder'
                Title  = 'TestTitle'
                Url    = 'http://example.com/'
                Ensure = $Ensure
            }
            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $Expected
        }

        It '[<Correctness>] Test for Url' -Foreach @(
            @{ Correctness = 'Correct'; Url = 'https://www.google.co.jp/' ; Expected = $true }
            @{ Correctness = 'InCorrect'; Url = 'https://www.google.com/' ; Expected = $false }
        ) {
            $DscProps = @{
                Path   = Join-Path $TestDrive 'bookmark.html'
                Folder = 'お気に入りバー'
                Title  = 'Google'
                Url    = $Url
            }
            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $Expected
        }

        It '[<Correctness>] Test for ADD_DATE' -Foreach @(
            @{ Correctness = 'Correct'; Date = ([datetime]::new(2021, 8, 6, 15, 23, 31, [DateTimeKind]::Utc)) ; Expected = $true }
            @{ Correctness = 'InCorrect'; Date = ([datetime]::now) ; Expected = $false }
        ) {
            $DscProps = @{
                Path    = Join-Path $TestDrive 'bookmark.html'
                Folder  = 'お気に入りバー'
                Title   = 'Google'
                Url     = 'https://www.google.co.jp/'
                AddDate = $Date
            }
            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $Expected
        }

        It '[<Correctness>] Test for IconData' -Foreach @(
            @{ Correctness = 'Correct'; IconData = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABy0lEQVQ4jY2TP2hTURjFf09zM1UbcGmID9xEFEyyCTo1b6uLxuCS1e4Fg4tuIlhczMMti0NwadOho9DNf7wpCCYdDEL7njWgiU87NOBxeGmavryKB+5wv8t3vnPuuRdJaUnPJO3o/7Ez7klbkp4AD5jC9vY2jUaDz70elmVxc2mJarVKAlaRFExTe56n08YoFVu1Wi1JSYCkwXTl3vKyUsao5DjqdDqT/XnbTiIYWJIGwPyhpiAI8H2f4XDIzzCk2WzSarUAGB0cxC0MZxR0u13li8UZCyljEhXMENypVJQyRvliUb7vq+66/yQ4Fdd0KLdcLpPNZmm325OzMAxnc4gryBcKk4klxzmWSN11T7Dw259UPM9TzraVMkY521bddVWuVLToOAq/B/rTeSl9WInWJIXNy/NcX4fMxaTHcoSt2zB3AdIZ+PQI7mqcwu5r6RXS+xUp9OMyj/BrV+qtST860tq52Dv40oJ3t6JJmRuw4IA5CwIsC/a2YG8Drq1H9f4buPpwaEkKgAUA+h58fAzfNqJGxv0Ac5eg8BxyJRiN0zBnvlqSngL3j3kddKH/FkbDiCFzBXKLSbeyiqLv/ELS/snmZ7A/7kn/BXFbL8ajtAhKAAAAAElFTkSuQmCC' ; Expected = $true }
            @{ Correctness = 'InCorrect'; IconData = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACMUlEQVQ4jY2TO09UURSFv73PnYfzQlEKAROjIRbaaYE2xtjZj7UWZrSh8geMGq1RY0wMBEi0wcRWQ4Gxwl8gBTExMIBGzQAzwzzuvWdbzIyhYBJWuR9r7XPW3nAUlE35bAGL5gYXmcmAzKD4Ick+iYgdDI/N/r2qQeKGON1cT2bfAm60WitslQp/AoCx+fpNdXJtQ+QJAMVFx4lzypsr4fh8bUqSiWkJUoLBeLt5Hx9VSeoL4FMAoBJf0KHC4zMLe2fjVvRoqzS8DsSFmd1hxJ7hTXyz3sZMNZ2btE5jL3by+v8TxudaE7hoRTPZk75e+y3CB/OyhJM05hcA1yuOJJNT36jPVe4U7lE2DQCIomOoX7NWO4/qiKSzJcJ2yaJOBKiAGJghpiLOVH70vqdLYEGcUQ0mzTxmPvbNmnUbJQCj2wxiPvCdEDH71iPwCiabd4e+evMPxAW/RNQABcQwMzABEcQTpLCwtd1o5ZcBKIvXvlXeBR8tbHlNZYK+h93G7viYxZpOKaLT1ZLsUjalq9T1fDuRrojIUws7qyouBjDEG8RAqLl80jfqy5Wd7HMwoSy+RwDMWZoRZGMnN0MUvjPRliCRmUdcwmk2n7Tm/tIudpspafdFAQKA037/kq77h3Jcbmkhl7cYCD3SaQKs+WbzVeV75mVf9dBVPjXbGE0muCxE59Usg1E151Yr1Z8rTE20e7suB9WPjuLiwCs8cEwmFN8rF4vCdeALAP6wsQ/iHwyf/mrLM8vhAAAAAElFTkSuQmCC' ; Expected = $false }
        ) {
            $DscProps = @{
                Path     = Join-Path $TestDrive 'bookmark.html'
                Folder   = 'お気に入りバー'
                Title    = 'Amazon'
                Url      = 'https://www.amazon.co.jp/'
                IconData = $IconData
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
                Folder  = 'お気に入りバー'
                Title   = 'Amazon'
                Url     = 'https://www.amazon.co.jp/'
                AddDate = $AddDate
            }
            { Invoke-DscResource @InvokeDscTest -Property $DscProps -ErrorAction Stop } | Should -Throw -Not:$Not
        }
    }

    Context 'Set-TargetResource' {

        It '[Absent] The bookmark file does not exist' {
            $DscProps = @{
                Path   = Join-Path $TestDrive '\notexist\missing.html'
                Folder = 'TestFolder'
                Title  = 'TestTitle'
                Url    = 'https://example.com/'
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
                Folder = 'TestFolder'
                Title  = 'TestTitle'
                Url    = 'https://example.com/'
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
    <DT><H3>TestFolder</H3>
    <DL><p>
        <DT><A HREF="https://example.com/">TestTitle</A>
    </DL><p>
</DL><p>

'@)

            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $true
        }

        It '[Absent] Remove Link' {
            $DscProps = @{
                Path   = Join-Path $TestDrive 'bookmark2.html'
                Folder = 'お気に入りバー'
                Title  = 'Twitter'
                Url    = 'https://twitter.com/'
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
    <DT><H3 ADD_DATE="1628263379" LAST_MODIFIED="1628263424" PERSONAL_TOOLBAR_FOLDER="true">お気に入りバー</H3>
    <DL><p>
    </DL><p>
</DL><p>

'@)

            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $true
        }

        It '[Present] Add Link and folder' {
            $DscProps = @{
                Path   = Join-Path $TestDrive 'bookmark2.html'
                Folder = 'NewFolder'
                Title  = 'TestTitle'
                Url    = 'https://example.com/'
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
        <DT><A HREF="https://example.com/">TestTitle</A>
    </DL><p>
</DL><p>

'@)

            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $true
        }

        It '[Present] Add Link to folder' {
            $DscProps = @{
                Path   = Join-Path $TestDrive 'bookmark2.html'
                Folder = 'お気に入りバー'
                Title  = 'TestTitle'
                Url    = 'https://example.com/'
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
        <DT><A HREF="https://example.com/">TestTitle</A>
    </DL><p>
</DL><p>

'@)

            $TestResource = Invoke-DscResource @InvokeDscTest -Property $DscProps
            $TestResource.InDesiredState | Should -Be $true
        }

        It '[Present] Change Link properties' {
            $date = ([datetime]::new(2039, 1, 1, 0, 0, 0, [DateTimeKind]::Utc))
            $DscProps = @{
                Path         = Join-Path $TestDrive 'bookmark2.html'
                Folder       = 'お気に入りバー'
                Title        = 'Twitter'
                Url          = 'https://example.com/'
                AddDate      = $date
                ModifiedDate = $date
                IconData     = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACIklEQVQ4jYWSS0iUURTHf/fe8RvHooE2VlT2FNqUGWmNEYUR9lhEEVJhUIsoXOQuap1Rq6KHNQt3LaPAIOxhlNTChUwLMU3NR1CklUzg6xvPd1ro2KhTHjjcA/e8/uf/hzmmqsUiEheRLhHxp/2TiDxQ1aK5+ZmFeSJSrwuYiMRVNZKuMxnFz51zu9T3GX/6iPGmRqS/F5WAUMEawuUVRI5UYjwPEWl2zlUYY8YMgIjUW2vPBkPfSV6uYbKvJ+uW3rZSojfuABAEQdw5d96oajHQqr7P8IUqpL8X43lEjp3EK4mBtfgt75l4+4po7U3cytWZPbcyjUlTidv642ipDu7foX7bh2zgs92jDhHpUlWdbNmuEw15OvqweqE7ZjboCAEFADrSjs1LkRM7NAt3+bWRebfYudFx9XguwFqbwePs9z/mT/6NLdAHMBpex28W0/C1Y1Zy05VFM75nUwiAZVGT/v5sgdcA3UurOPUrxvXOFhJD7fOmdn4LeNc5NbpkfWimv5mWZ8KXFKdfXqInOYBnc6gsPEjZ8mKssbQOtvEkMczYl0oK8z3un4lgppbYkhZS3Fp7bnD0Jxeba+lODmTFviFcxq29NeRHDUEQ1DnnqtNSjohIo3Nutx+keNz9gmf9zfQkB0ChYMkK9q2KcaLwMJFQGFV9Y4w5YIwZzyBBI2lRLcD9PVXN/SdFqlokInUi0iEiE9P+UUTuqurmufl/AKTzsFGmvUNUAAAAAElFTkSuQmCC'
                Ensure       = 'Present'
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
        <DT><A HREF="https://example.com/" ADD_DATE="2177452800" LAST_MODIFIED="2177452800" ICON="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACIklEQVQ4jYWSS0iUURTHf/fe8RvHooE2VlT2FNqUGWmNEYUR9lhEEVJhUIsoXOQuap1Rq6KHNQt3LaPAIOxhlNTChUwLMU3NR1CklUzg6xvPd1ro2KhTHjjcA/e8/uf/hzmmqsUiEheRLhHxp/2TiDxQ1aK5+ZmFeSJSrwuYiMRVNZKuMxnFz51zu9T3GX/6iPGmRqS/F5WAUMEawuUVRI5UYjwPEWl2zlUYY8YMgIjUW2vPBkPfSV6uYbKvJ+uW3rZSojfuABAEQdw5d96oajHQqr7P8IUqpL8X43lEjp3EK4mBtfgt75l4+4po7U3cytWZPbcyjUlTidv642ipDu7foX7bh2zgs92jDhHpUlWdbNmuEw15OvqweqE7ZjboCAEFADrSjs1LkRM7NAt3+bWRebfYudFx9XguwFqbwePs9z/mT/6NLdAHMBpex28W0/C1Y1Zy05VFM75nUwiAZVGT/v5sgdcA3UurOPUrxvXOFhJD7fOmdn4LeNc5NbpkfWimv5mWZ8KXFKdfXqInOYBnc6gsPEjZ8mKssbQOtvEkMczYl0oK8z3un4lgppbYkhZS3Fp7bnD0Jxeba+lODmTFviFcxq29NeRHDUEQ1DnnqtNSjohIo3Nutx+keNz9gmf9zfQkB0ChYMkK9q2KcaLwMJFQGFV9Y4w5YIwZzyBBI2lRLcD9PVXN/SdFqlokInUi0iEiE9P+UUTuqurmufl/AKTzsFGmvUNUAAAAAElFTkSuQmCC">Twitter</A>
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
                Folder  = 'お気に入りバー'
                Title   = 'Twitter'
                Url     = 'https://example.com/'
                AddDate = $AddDate
            }
            { Invoke-DscResource @InvokeDscSet -Property $DscProps -ErrorAction Stop } | Should -Throw -Not:$Not
        }
    }
}
