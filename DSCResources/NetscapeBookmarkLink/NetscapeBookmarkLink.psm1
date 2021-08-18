Enum Ensure {
    Present
    Absent
}

# Import helper functions
$UtilPath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Utils'
# Import-Module (Join-Path $UtilPath 'ConvertTo-HashTable.psm1')
Import-Module (Join-Path $UtilPath 'Validate-DateTime.psm1')

# Import parser libraries
$LibPath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Libs'
if (-not ('BookmarksManager.NetscapeBookmarksReader' -as [type])) {
    Add-Type -Path (Join-Path $LibPath '\BookmarksManager\netstandard1.6\BookmarksManager.dll')
}

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        # The path to the bookmark file
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        # The title of the bookmark folder that the target link should be belonging to
        [Parameter(Mandatory = $true)]
        [System.String]
        $Folder,

        # The title of the target link
        [Parameter(Mandatory = $true)]
        [System.String]
        $Title,

        # The URL of the link
        [Parameter(Mandatory = $true)]
        [System.String]
        $Url
    )

    $GetObject = @{
        Ensure = [Ensure]::Present
        Path   = $Path
        Folder = ''
        Title  = ''
    }

    # Test if the bookmarks file exists
    if ([string]::IsNullOrWhiteSpace($Path) -or (-not (Test-Path -LiteralPath $Path -PathType Leaf))) {
        $GetObject.Ensure = [Ensure]::Absent
        return $GetObject
    }

    # Read and parse the bookmark file
    $BookmarkContent = Get-Content -LiteralPath $Path -Raw -Encoding utf8
    $Reader = [BookmarksManager.NetscapeBookmarksReader]::new()
    try {
        $Bookmark = $Reader.Read($BookmarkContent)
    }
    catch {
        # Failed to parse the bookmark file
        Write-Verbose -Message 'Failed to parse the bookmark file'
        $GetObject.Ensure = [Ensure]::Absent
        return $GetObject
    }

    # Test if the folder exists in the bookmark file
    $TargetFolder = $Bookmark.AllFolders | ? { $_.Title -eq $Folder } | select -First 1
    if ($null -eq $TargetFolder) {
        # Folder does not exist
        $GetObject.Ensure = [Ensure]::Absent
        return $GetObject
    }
    else {
        $GetObject.Folder = $TargetFolder.Title
    }

    # Test if the link exists in the folder
    $TargetItem = $TargetFolder.AllLinks | ? { $_.Title -eq $Title } | select -First 1
    if ($null -eq $TargetItem) {
        # Link does not exist
        $GetObject.Ensure = [Ensure]::Absent
        return $GetObject
    }
    else {
        # Link exists
        $GetObject.Ensure = [Ensure]::Present
        $GetObject.Title = $TargetItem.Title
    }

    # URL
    $GetObject.Url = $TargetItem.Url

    # ADD_DATE
    $GetObject.AddDate = $TargetItem.Added

    # LAST_MODIFIED
    $GetObject.ModifiedDate = $TargetItem.LastModified

    # IconData
    $GetObject.IconData = $TargetItem.Attributes.'icon'

    # IconUrl
    $GetObject.IconUrl = $TargetItem.IconUrl

    return $GetObject
}


function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $Ensure = [Ensure]::Present,

        # The path to the bookmark file
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        # The title of the bookmark folder that the target link should be belonging to
        [Parameter(Mandatory = $true)]
        [System.String]
        $Folder,

        # The title of the target link
        [Parameter(Mandatory = $true)]
        [System.String]
        $Title,

        # The URL of the link
        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        # The ADD_DATE of the link
        [Parameter()]
        [System.DateTime]
        $AddDate,

        # The LAST_MODIFIED of the link
        [Parameter()]
        [System.DateTime]
        $ModifiedDate,

        # The Data URI of the icon
        [Parameter()]
        [System.String]
        $IconData,

        # The URL of the icon
        [Parameter()]
        [System.String]
        $IconUrl
    )

    # Validate range of datetime
    $AddDate = if (Validate-DateTime $AddDate) { $AddDate }else { $null }
    $ModifiedDate = if (Validate-DateTime $ModifiedDate) { $ModifiedDate }else { $null }

    if ($Ensure -eq [Ensure]::Absent) {
        $GetObject = Get-TargetResource -Path $Path -Title $Title -Url $Url -Folder $Folder
        if ($GetObject.Ensure -eq [Ensure]::Absent) {
            Write-Verbose -Message 'Nothing to do.'
            return
        }
        else {
            # Read and parse the bookmark file
            $BookmarkContent = Get-Content -LiteralPath $Path -Raw -Encoding utf8
            $Reader = [BookmarksManager.NetscapeBookmarksReader]::new()
            $Bookmark = $Reader.Read($BookmarkContent)

            # Remove the link
            $Bookmark.AllFolders | ? { $_.Title -eq $Folder } | % {
                $Target = $_.AllLinks | ? { $_.Title -eq $Title } | select -First 1
                Write-Verbose -Message 'Removing link from folder.'
                $null = $_.Remove($Target)
            }

            # Save the bookmark file
            Write-Verbose -Message 'Saving bookmark file.'
            $Writer = [BookmarksManager.NetscapeBookmarksWriter]::new($Bookmark)
            $ParentFolder = Split-Path -Path $Path -Parent
            if (-not (Test-Path -LiteralPath $ParentFolder -PathType Container)) {
                $null = New-Item -ItemType Directory -Path $ParentFolder -Force
            }
            $Writer.ToString() | Out-File -FilePath $Path -Encoding utf8 -Force -NoNewline
            Write-Verbose -Message 'The bookmark file has been saved.'
        }
    }
    else {
        # if the bookmark file does not exist, create it
        if ([string]::IsNullOrWhiteSpace($Path) -or (-not (Test-Path -LiteralPath $Path -PathType Leaf))) {
            Write-Verbose -Message 'The bookmark file does not exist. Creating it...'
            $NewBookmarkParent = [BookmarksManager.BookmarkFolder]::new()
        }
        else {
            # Read and parse the bookmark file
            $BookmarkContent = Get-Content -LiteralPath $Path -Raw -Encoding utf8
            $Reader = [BookmarksManager.NetscapeBookmarksReader]::new()
            $NewBookmarkParent = $Reader.Read($BookmarkContent)
        }

        # Get target folder
        $TargetFolder = $NewBookmarkParent.AllFolders | ? { $_.Title -eq $Folder } | select -First 1
        if ($null -eq $TargetFolder) {
            # if that does not exist, create it
            Write-Verbose -Message 'The target folder does not exist. Creating it...'
            $TargetFolder = [BookmarksManager.BookmarkFolder]::new()
            $TargetFolder.Title = $Folder
            $NewBookmarkParent.Add($TargetFolder)
        }

        # Get target link
        $TargetLink = $TargetFolder.AllLinks | ? { $_.Title -eq $Title } | select -First 1
        if ($null -eq $TargetLink) {
            # if that does not exist, create it
            Write-Verbose -Message 'The target link does not exist. Creating it...'
            $TargetLink = [BookmarksManager.BookmarkLink]::new($Url, $Title)
            $TargetFolder.Add($TargetLink)
        }

        # Set URL
        Write-Verbose -Message "Set the URL to $Url"
        $TargetLink.Url = $Url

        # Set ADD_DATE
        if ($null -ne $AddDate) {
            Write-Verbose -Message ('Set the ADD_DATE to {0}' -f $AddDate.ToString("yyyy-MM-dd'T'HH:mm:sszzz"))
            $TargetLink.Added = $AddDate.ToUniversalTime()
        }

        # Set LAST_MODIFIED
        if ($null -ne $ModifiedDate) {
            Write-Verbose -Message ('Set the LAST_MODIFIED to {0}' -f $ModifiedDate.ToString("yyyy-MM-dd'T'HH:mm:sszzz"))
            $TargetLink.LastModified = $ModifiedDate.ToUniversalTime()
        }

        # Set IconData
        if (-not [string]::IsNullOrEmpty($IconData)) {
            Write-Verbose -Message 'Set the IconData'
            $tmp = $IconData.Split([char[]](':', ';', ','))
            $TargetLink.IconContentType = $tmp[1]
            $TargetLink.IconData = [System.Convert]::FromBase64String($tmp[3])
        }

        # Set IconUrl
        if (-not [string]::IsNullOrEmpty($IconUrl)) {
            Write-Verbose -Message 'Set the IconUrl'
            $TargetLink.IconUrl = $IconUrl
        }

        # Save the bookmark file
        Write-Verbose -Message 'Saving the bookmark file...'
        $Writer = [BookmarksManager.NetscapeBookmarksWriter]::new($NewBookmarkParent)
        $ParentFolder = Split-Path -Path $Path -Parent
        if (-not (Test-Path -LiteralPath $ParentFolder -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $ParentFolder -Force
        }
        $Writer.ToString() | Out-File -FilePath $Path -Encoding utf8 -Force -NoNewline
        Write-Verbose -Message 'The bookmark file has been saved.'
    }
}


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.String]
        $Ensure = [Ensure]::Present,

        # The path to the bookmark file
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        # The title of the bookmark folder that the target link should be belonging to
        [Parameter(Mandatory = $true)]
        [System.String]
        $Folder,

        # The title of the target link
        [Parameter(Mandatory = $true)]
        [System.String]
        $Title,

        # The URL of the link
        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        # The ADD_DATE of the link
        [Parameter()]
        [System.DateTime]
        $AddDate,

        # The LAST_MODIFIED of the link
        [Parameter()]
        [System.DateTime]
        $ModifiedDate,

        # The Data URI of the icon
        [Parameter()]
        [System.String]
        $IconData,

        # The URL of the icon
        [Parameter()]
        [System.String]
        $IconUrl
    )

    # Validate range of datetime
    $AddDate = if (Validate-DateTime $AddDate) { $AddDate }else { $null }
    $ModifiedDate = if (Validate-DateTime $ModifiedDate) { $ModifiedDate }else { $null }

    # Get current state
    $CurrentState = Get-TargetResource -Path $Path -Title $Title -Url $Url -Folder $Folder

    # Test if the bookmarks file exists
    if ([string]::IsNullOrWhiteSpace($Path) -or (-not (Test-Path -LiteralPath $Path -PathType Leaf))) {
        return ($Ensure -eq [Ensure]::Absent)
    }

    # Read and parse the bookmark file
    try {
        $BookmarkContent = Get-Content -LiteralPath $Path -Raw -Encoding utf8
        $Reader = [BookmarksManager.NetscapeBookmarksReader]::new()
        $null = $Reader.Read($BookmarkContent)
    }
    catch {
        # Failed to parse the bookmark file
        Write-Verbose -Message 'Failed to parse the bookmark file'
        return ($Ensure -eq [Ensure]::Absent)
    }
    finally {
        Remove-Variable -Name BookmarkContent
        Remove-Variable -Name Reader
    }

    if ($CurrentState.Ensure -ne $Ensure) {
        Write-Verbose -Message ('The target resource is not in the expected state. Expected {0}, but got {1}' -f $Ensure, $CurrentState.Ensure)
        return $false
    }

    # The title of the link is different, return False
    if ($Title -ne $CurrentState.Title) {
        Write-Verbose -Message ('The title of the link is not in the expected state. Expected {0}, but got {1}' -f $Title, $CurrentState.Title)
        return ($Ensure -eq [Ensure]::Absent)
    }

    # The URL of the link is different, return False
    if ($Url -ne $CurrentState.Url) {
        Write-Verbose -Message ('The URL of the link is not in the expected state. Expected {0}, but got {1}' -f $Url, $CurrentState.Url)
        return $false
    }

    if ($null -ne $AddDate) {
        # The ADD_DATE of the link is different, return False
        if (($CurrentState.AddDate -isnot [datetime]) -or ($AddDate.ToUniversalTime() -ne $CurrentState.AddDate.ToUniversalTime())) {
            Write-Verbose -Message ('The ADD_DATE attribute is not in the expected state. Expected {0}, but got {1}' -f $AddDate.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:sszzz"), $CurrentState.AddDate.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:sszzz"))
            return $false
        }
    }

    if ($null -ne $ModifiedDate) {
        # The LAST_MODIFIED of the link is different, return False
        if (($CurrentState.ModifiedDate -isnot [datetime]) -or ($ModifiedDate.ToUniversalTime() -ne $CurrentState.ModifiedDate.ToUniversalTime())) {
            Write-Verbose -Message ('The LAST_MODIFIED attribute is not in the expected state. Expected {0}, but got {1}' -f $ModifiedDate.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:sszzz"), $CurrentState.ModifiedDate.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:sszzz"))
            return $false
        }
    }

    if (-not [string]::IsNullOrEmpty($IconData)) {
        # The IconData of the link is different, return False
        if ($IconData -ne $CurrentState.IconData) {
            Write-Verbose -Message ('The IconData attribute is not in the expected state.')
            return $false
        }
    }

    if (-not [string]::IsNullOrEmpty($IconUrl)) {
        # The IconUrl of the link is different, return False
        if ($IconUrl -ne $CurrentState.IconUrl) {
            Write-Verbose -Message ('The IconUrl attribute is not in the expected state. Expected {0}, but got {1}' -f $IconUrl, $CurrentState.IconUrl)
            return $false
        }
    }

    Write-Verbose -Message 'The target resource is in the expected state.'
    return $true
}


Export-ModuleMember -Function *-TargetResource
