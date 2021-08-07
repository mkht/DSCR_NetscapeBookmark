Enum Ensure {
    Present
    Absent
}

# Import helper functions
$UtilPath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Utils'
Import-Module (Join-Path $UtilPath 'ConvertTo-HashTable.psm1')

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

        # The title of the bookmark folder
        [Parameter(Mandatory = $true)]
        [System.String]
        $Title
    )

    $GetObject = @{
        Ensure = [Ensure]::Present
        Path   = $Path
        Title  = $Title
    }

    # Test if the bookmark file exists
    if ([string]::IsNullOrWhiteSpace($Path) -or (-not (Test-Path -LiteralPath $Path -PathType Leaf))) {
        Write-Verbose -Message 'The bookmark file does not exist.'
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
        Write-Warning -Message 'Failed to parse the bookmark file.'
        $GetObject.Ensure = [Ensure]::Absent
        return $GetObject
    }

    # Test if the folder exists in the bookmark file
    $Folder = $Bookmark.AllFolders | ? { $_.Title -eq $Title } | select -first 1
    if ($null -eq $Folder) {
        # Folder does not exist
        $GetObject.Ensure = [Ensure]::Absent
        return $GetObject
    }
    else {
        # Folder exists
        $GetObject.Ensure = [Ensure]::Present
    }

    # Get ADD_DATE property
    $GetObject.AddDate = $Folder.Added

    # Get LAST_MODIFIED property
    $GetObject.ModifiedDate = $Folder.LastModified

    # Get ATTRIBUTES property
    $GetObject.Attributes = $Folder.Attributes

    return $GetObject
}


function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $Ensure = [Ensure]::Present,

        # Path to the bookmark file
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        # Title of the bookmark folder
        [Parameter(Mandatory = $true)]
        [System.String]
        $Title,

        # ADD_DATE attribute
        [Parameter()]
        [Nullable[System.DateTime]]
        $AddDate,

        # LAST_MODIFIED attribute
        [Parameter()]
        [Nullable[System.DateTime]]
        $ModifiedDate,

        # Other attributes
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Attributes
    )

    if ($Ensure -eq [Ensure]::Absent) {
        # The bookmark file does not exist
        if ([string]::IsNullOrWhiteSpace($Path) -or (-not (Test-Path -LiteralPath $Path -PathType Leaf))) {
            Write-Verbose -Message 'The bookmark file does not exist. No action taken.'
            return
        }
        else {
            # Read and parse the bookmark file
            $BookmarkContent = Get-Content -LiteralPath $Path -Raw -Encoding utf8
            $Reader = [BookmarksManager.NetscapeBookmarksReader]::new()
            $Bookmark = $Reader.Read($BookmarkContent)

            # Create new bookmark folders without target folder
            $NewBookmarkParent = [BookmarksManager.BookmarkFolder]::new()
            $Bookmark.AllFolders | ? { $_.Title -ne $Title } | % {
                $NewBookmarkParent.Add($_)
            }

            # Save the bookmark file
            Write-Verbose -Message 'Saving the bookmark file...'
            $Writer = [BookmarksManager.NetscapeBookmarksWriter]::new($NewBookmarkParent)
            $ParentFolder = Split-Path -Path $Path -Parent
            if (-not (Test-Path -LiteralPath $ParentFolder -PathType Container)) {
                $null = New-item -Itemtype Directory -Path $ParentFolder -Force
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
        $Target = $NewBookmarkParent.AllFolders | ? { $_.Title -eq $Title } | select -First 1
        if ($null -eq $Target) {
            # if that does not exist, create it
            Write-Verbose -Message 'The target folder does not exist. Creating it...'
            $Target = [BookmarksManager.BookmarkFolder]::new()
            $NewBookmarkParent.Add($Target)
        }

        # Set title
        Write-Verbose -Message "Set the title to $Title"
        $Target.Title = $Title

        # Set ADD_DATE
        if ($null -ne $AddDate) {
            Write-Verbose -Message ('Set the ADD_DATE to {0}' -f $AddDate.ToString("yyyy-MM-dd'T'HH:mm:sszzz"))
            $Target.Added = $AddDate.ToUniversalTime()
        }

        # Set LAST_MODIFIED
        if ($null -ne $ModifiedDate) {
            Write-Verbose -Message ('Set the LAST_MODIFIED to {0}' -f $ModifiedDate.ToString("yyyy-MM-dd'T'HH:mm:sszzz"))
            $Target.LastModified = $ModifiedDate.ToUniversalTime()
        }

        # Set other attributes
        if ($null -ne $Attributes) {
            # Convert CimInstance[] to Generic.Dictionary<string, string>
            $HashTableAttributes = ConvertTo-HashTable -CimInstance $Attributes
            $StringAttributes = [System.Collections.Generic.Dictionary[[string], [string]]]::new()
            foreach ($key in $HashTableAttributes.Keys) {
                $StringAttributes.Add($key.ToString().ToLower(), $HashTableAttributes[$key].ToString())
            }

            # if the target folder has no attributes, add them
            if ($null -eq $Target.Attributes) {
                Write-Verbose -Message 'Set attributes'
                $Target.Attributes = $StringAttributes
            }
            else {
                # Add desired attributes to the target folder
                foreach ($key in $StringAttributes.Keys) {
                    Write-Verbose -Message ('Set the value of the {0} to {1}' -f $Key, $StringAttributes[$key])
                    if ($Target.Attributes.ContainsKey($key)) {
                        $Target.Attributes[$key] = $StringAttributes[$key]
                    }
                    else {
                        $Target.Attributes.Add($key, $StringAttributes[$key])
                    }
                }
            }
        }

        # Save the bookmark file
        Write-Verbose -Message 'Saving the bookmark file...'
        $Writer = [BookmarksManager.NetscapeBookmarksWriter]::new($NewBookmarkParent)
        $ParentFolder = Split-Path -Path $Path -Parent
        if (-not (Test-Path -LiteralPath $ParentFolder -PathType Container)) {
            $null = New-item -Itemtype Directory -Path $ParentFolder -Force
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

        # Path to the bookmark file
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        # Title of the bookmark folder
        [Parameter(Mandatory = $true)]
        [System.String]
        $Title,

        # ADD_DATE attribute
        [Parameter()]
        [Nullable[System.DateTime]]
        $AddDate,

        # LAST_MODIFIED attribute
        [Parameter()]
        [Nullable[System.DateTime]]
        $ModifiedDate,

        # Other attributes
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Attributes
    )

    # Get current state
    $CurrentState = Get-TargetResource -Path $Path -Title $Title

    if ($CurrentState.Ensure -ne $Ensure) {
        Write-Verbose -Message ('The target resource is not in the expected state. Expected:{0}, but got {1}.' -f $Ensure, $CurrentState.Ensure)
        return $false
    }

    # The title of the bookmark folder is different, return False
    if ($Title -ne $CurrentState.Title) {
        Write-Verbose -Message ('The title of bookmark folder is different. Expected:{0}, but got {1}.' -f $Title, $CurrentState.Title)
        return $false
    }

    if ($null -ne $AddDate) {
        # The ADD_DATE attribute is different, return False
        if (($CurrentState.AddDate -isnot [datetime]) -or ($AddDate.ToUniversalTime() -ne $CurrentState.AddDate.ToUniversalTime())) {
            Write-Verbose -Message ('The ADD_DATE attribute is different. Expected:{0}, but got {1}.' -f $AddDate.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:sszzz"), $CurrentState.AddDate.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:sszzz"))
            return $false
        }
    }

    if ($null -ne $ModifiedDate) {
        # The LAST_MODIFIED attribute is different, return False
        if (($CurrentState.ModifiedDate -isnot [datetime]) -or ($ModifiedDate.ToUniversalTime() -ne $CurrentState.ModifiedDate.ToUniversalTime())) {
            Write-Verbose -Message ('The LAST_MODIFIED attribute is different. Expected:{0}, but got {1}.' -f $ModifiedDate.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:sszzz"), $CurrentState.ModifiedDate.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:sszzz"))
            return $false
        }
    }

    if ($null -ne $Attributes) {
        # Convert CimInstance[] to Generic.Dictionary<string, string>
        $HashTableAttributes = ConvertTo-HashTable -CimInstance $Attributes
        $StringAttributes = [System.Collections.Generic.Dictionary[[string], [string]]]::new()
        foreach ($key in $HashTableAttributes.Keys) {
            $StringAttributes.Add($key.ToString().ToLower(), $HashTableAttributes[$key].ToString())
        }

        foreach ($key in $StringAttributes.Keys) {
            # Some attributes are different, return False
            if (-not [object]::Equals($StringAttributes[$key], $CurrentState.Attributes[$key])) {
                Write-Verbose -Message ('The value of the {0} attribute is different. Expected:{1}, but got {2}.' -f $key, $StringAttributes[$key], $CurrentState.Attributes[$key])
                return $false
            }
        }
    }

    Write-Verbose -Message 'The target resource is in the expected state.'
    return $true
}


Export-ModuleMember -Function *-TargetResource
