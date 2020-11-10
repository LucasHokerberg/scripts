<#

This script compares any given local group's member with an array of allowed members.
If a member is not allowed, the script will return the member(s).
If all members are allowed, the script will return Compliant.

This script is built to operate as an Configuration item in SCCM for compliance check.

Author: lucas@hokerberg.com
Created: 2020-11-10

#>

# Define static parameters
$strGroup = "Administratörer"
$allowedMembers = @(
                    "Administratör",
                    "Domain Admins",
                    "G_SCCM_LocalAdmins_SE",
                    "clientadmin"
                    )

# Initiate variables
$computer = [ADSI]("WinNT://.,computer")
$group = $computer.psbase.children.find("Administratörer")
$members = $group.psbase.invoke("Members") | %{$_.GetType().InvokeMember("Name", "GetProperty", $null, $_, $null)}
$illegalMembers = ""

# For each member in group
foreach ($user in $members) {

    # Add illegal members to an array
    if ($allowedMembers -notcontains $user){

        $illegalMembers += "$($user) "
    }
}

# Get result
if ($illegalMembers -eq "") {

    $compliance = "Compliant"

} else {

    $compliance = "Illegal members: $($illegalMembers)"
}

# Return result
return $compliance
