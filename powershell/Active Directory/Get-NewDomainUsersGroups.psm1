#    Copyright (c) Micro Systems Management 2018, 2019. All rights reserved.
#    
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    Licensed under the GNU-3.0-or-later license. A copy of the
#    GNU General Public License is available in the LICENSE file
#    located in the root of this repository. If not, see
#    <https://www.gnu.org/licenses/>.
#
Function Get-NewDomainUsersGroups()
{
    <#
        .Synopsis
            Enumerate recently created domain user or group accounts.
        
        .Description
            Enumerate recently created domain user or group accounts. Depending on which switches are passed to the script, the enumeration may be domain users that are members of the domain admins group that were created in the last n days, domain users that are not members of the domain admins group that were created in the last n days, or groups that were crated in the last n days.
        .Example
            # Enumerate all domain users that were created in the last 30 days
            Get-NewDomainUsersGroups -age 30 -type user
        
        .Example
            # Enumerate all domain groups that were created in the last 30 days
            Get-NewDomainUsersGroups -age 30 -type group
        
        .Example
            # Enumerate all domain administrators that were created in the last 30 days.
            Get-NewDomainUsersGroups -age 30 -type user -accessslevel admin
    #>

    param(
        # Use switch m to only display the name for each active administrator account
        [Parameter(Mandatory=$True,Position=1)]
        [string]$age,
        [Parameter(Mandatory=$False)]
        [string]$type,
        [Parameter(Mandatory=$False)]
        [string]$accesslevel
    )

Import-Module ActiveDirectory

    $When = ((Get-Date).AddDays(-$age)).Date
    $DomainAdminsDn = (Get-ADGroup 'Domain Admins').DistinguishedName
    $EnterpriseAdminsDn = (Get-ADGroup 'Enterprise Admins').DistinguishedName
    $DomainUsersDn = (Get-ADGroup 'Domain Users').DistinguishedName
    If (($type -ne $null) -AND ($accesslevel -ne $null)) {
        If (($type -like 'user*') -AND ($accesslevel -like 'admin*')) {
            Get-ADUser -Filter { ((memberof -eq $DomainAdminsDn) -and (whenCreated -ge $When))}
            Get-ADUser -Filter { ((memberof -eq $EnterpriseAdminsDn) -and (whenCreated -ge $When))}
        }
        If (($type -like 'user*') -AND ($accesslevel -like 'user*')) {
            Get-ADUser -Filter { ((-not (memberof -eq $DomainUsersDn)) -and (whenCreated -ge $When))}
        }
    }
    If ($accesslevel -eq $null) {
        If ($type -like 'user*') {
            Get-ADUser -Filter {whenCreated -ge $When}
        }
        If ($type -like 'group*') {
            Get-ADGroup -Filter {whenCreated -ge $When}
        }
    }
}