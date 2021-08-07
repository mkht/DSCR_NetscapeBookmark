@{
    # Script module or binary module file associated with this manifest.
    RootModule           = 'DSCR_NetscapeBookmark.psm1'

    DscResourcesToExport = @(
        'NetscapeBookmarkFolder',
        'NetscapeBookmarkLink'
    )

    RequiredAssemblies   = @(
        'Libs\BookmarksManager\netstandard1.6\BookmarksManager.dll'
    )

    # Version number of this module.
    ModuleVersion        = '1.0.0'

    # ID used to uniquely identify this module
    GUID                 = 'd779527b-9497-48b5-b996-f237a325e80d'

    # Author of this module
    Author               = 'mkht'

    # Company or vendor of this module
    CompanyName          = ''

    # Copyright statement for this module
    Copyright            = '(c) 2021 mkht All rights reserved.'

    # Description of the functionality provided by this module
    # Description = ''

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '5.1'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''
}
