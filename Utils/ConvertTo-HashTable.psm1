<#
Original code: https://github.com/dsccommunity/DscResource.Common/blob/8d7f8d66ee8b369478ba2d4eb14dbc4aa853b352/source/Public/ConvertTo-HashTable.ps1
#>

<#
    .SYNOPSIS
        Converts CimInstances into a hashtable.
    .DESCRIPTION
        This function is used to convert a CimInstance array containing
        MSFT_KeyValuePair objects into a hashtable.
    .PARAMETER CimInstance
        An array of CimInstances or a single CimInstance object to convert.
    .OUTPUTS
        Hashtable
    .EXAMPLE
        $newInstanceParameters = @{
            ClassName = 'MSFT_KeyValuePair'
            Namespace = 'root/microsoft/Windows/DesiredStateConfiguration'
            ClientOnly = $true
        }
        $cimInstance = [Microsoft.Management.Infrastructure.CimInstance[]] (
            (New-CimInstance @newInstanceParameters -Property @{
                Key   = 'FirstName'
                Value = 'John'
            }),
            (New-CimInstance @newInstanceParameters -Property @{
                Key   = 'LastName'
                Value = 'Smith'
            })
        )
        ConvertTo-HashTable -CimInstance $cimInstance
        This creates a array om CimInstances of the class name MSFT_KeyValuePair
        and passes it to ConvertTo-HashTable which returns a hashtable.
#>
function ConvertTo-HashTable {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'CimInstance')]
        [AllowEmptyCollection()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $CimInstance
    )

    begin {
        $result = @{ }
    }

    process {
        foreach ($ci in $CimInstance) {
            $result.Add($ci.Key, $ci.Value)
        }
    }

    end {
        $result
    }
}

Export-ModuleMember -Function 'ConvertTo-HashTable'
