$modulePath = $PSScriptRoot
$subModulePath = @(
    '\DSCResources\NetscapeBookmarkFolder\NetscapeBookmarkFolder.psm1'
    '\DSCResources\NetscapeBookmarkLink\NetscapeBookmarkLink.psm1'
)

$subModulePath.ForEach( {
        Import-Module (Join-Path $modulePath $_)
    })
