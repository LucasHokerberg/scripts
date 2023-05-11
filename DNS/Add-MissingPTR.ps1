<#

Script to search for and add missing PTR records for all static A records in a given zone.
If a reverse lookup zone does not exist for an A record, the script will throw an error and simply skip that record.
Create missing reverse zones and re-run the script to create the missing PTR records.

Author: lucas@hokerberg.com
Date: 2023-05-11

#>

# Define parameters
$domain = "domain.local"
$dc = "dc1.domain.local"

# Get and loop through all DNS record
$records = Get-DnsServerResourceRecord -ZoneName $domain -RRType A -ComputerName $dc | Where-Object {$_.TimeStamp -eq $null}

foreach ($record in $records) {

    # Prepare the PTR data
    $data = $record.HostName + "." + $domain

    # Parse the PTR name (last octet)
    $name = ($record.RecordData.IPv4Address.ToString() -replace '^(\d+)\.(\d+)\.(\d+).(\d+)$','$4');
    
    # Parse the zone name (first 3 octets in reverse)
    $zoneName = ($record.RecordData.IPv4Address.ToString() -replace '^(\d+)\.(\d+)\.(\d+).(\d+)$','$3.$2.$1') + '.in-addr.arpa';

    # Try to find existing PTR record
    $find = Get-DnsServerResourceRecord -Name $name -ZoneName $zoneName -RRType PTR -ComputerName $dc -ErrorAction SilentlyContinue
    
    # PTR record missing - try to create one
    if ($null -eq $find) {

        Write-Host "[MISSING] Data: $($data) | Name: $($name) Zone: $($zoneName)"
        Add-DnsServerResourceRecordPtr -Name $name -ZoneName $zoneName -ComputerName $dc -PtrDomainName $data
    
    # PTR record found - just inform
    } else {

        Write-Host "[OK] Data: $($data) | Name: $($name) Zone: $($zoneName)"
    }
}
