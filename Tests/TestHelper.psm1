<#
Original code: https://github.com/dsccommunity/DscResource.Common/blob/8d7f8d66ee8b369478ba2d4eb14dbc4aa853b352/source/Public/ConvertTo-CimInstance.ps1
#>

<#
    .SYNOPSIS
        Converts a hashtable into a CimInstance array.

    .DESCRIPTION
        This function is used to convert a hashtable into MSFT_KeyValuePair objects.
        These are stored as an CimInstance array. DSC cannot handle hashtables but
        CimInstances arrays storing MSFT_KeyValuePair.

    .PARAMETER Hashtable
        A hashtable with the values to convert.

    .OUTPUTS
        An object array with CimInstance objects.

    .EXAMPLE
        ConvertTo-CimInstance -Hashtable @{
            String = 'a string'
            Bool   = $true
            Int    = 99
            Array  = 'a, b, c'
        }

        This example returns an CimInstance with the provided hashtable values.
#>
function ConvertTo-CimInstance {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Hashtable')]
        [System.Collections.Hashtable]
        $Hashtable
    )

    process {
        foreach ($item in $Hashtable.GetEnumerator()) {
            New-CimInstance -ClassName 'MSFT_KeyValuePair' -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' -Property @{
                Key   = $item.Key
                Value = if ($item.Value -is [array]) {
                    $item.Value -join ','
                }
                else {
                    $item.Value
                }
            } -ClientOnly
        }
    }
}

Export-ModuleMember -Function ConvertTo-CimInstance
