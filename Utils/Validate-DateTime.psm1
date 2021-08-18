function Validate-DateTime {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)]
        [Nullable[System.DateTime]]
        $DateTime
    )

    process {
        if ($null -eq $DateTime -or $DateTime -ge [datetime]::UnixEpoch) {
            return $true
        }
        else {
            Write-Error -Message 'DateTime must be greater than or equal to the unix epoch.'
            return $false
        }
    }
}

Export-ModuleMember -Name 'Validate-DateTime'
