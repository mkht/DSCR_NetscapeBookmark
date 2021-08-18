function Validate-DateTime {
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)]
        [AllowNull()]
        [Nullable[System.DateTime]]
        $DateTime
    )

    begin {
        $UnixEpoch = [Datetime]::new(1970, 1, 1, 0, 0, 0, 0, [System.DateTimeKind]::Utc)
    }

    process {
        if ($null -eq $DateTime -or $DateTime -ge $UnixEpoch) {
            return $true
        }
        else {
            throw [System.ArgumentOutOfRangeException]::new('DateTime must be greater than or equal to the unix epoch.')
            return $false
        }
    }
}

Export-ModuleMember -Function 'Validate-DateTime'
