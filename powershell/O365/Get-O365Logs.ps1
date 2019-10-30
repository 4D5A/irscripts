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
$AdminAuditLogEnabled = Get-AdminAuditLogConfig | Select-Object -ExpandProperty UnifiedAuditLogIngestionEnabled
$Dehydrated = Get-OrganizationConfig | Select-Object -ExpandProperty IsDehydrated
$EndDate = (Get-Date)
$StartDate = (Get-Date).Adddays(-14)
$UPN = Read-Host "Enter the User Principal Name of the account for which you want to obtain logs"

If ($Dehydrated -eq $True) {
  Write-Host "Organization Customization is disabled in this tenant. Enabling Organization Customization in this tenant."
  Enable-OrganizationCustomization
  Write-Host "Enabling the Admin Audit Log."
  Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $True
}
If ($Dehydrated -eq $False) {
  If ($AdminAuditLogEnabled -eq $True) {
    Write-Host "Running Get-MessageTrace."
    Get-MessageTrace -StartDate $StartDate -EndDate $EndDate -RecipientAddress $UPN | Select-Object MessageId, Organization, Received, SenderAddress, RecipientAddress, Subject, Status, FromIP, ToIP, PSComputerName, RunspaceId, MessageTraceId | Export-Csv "$($env:USERPROFILE)\Desktop\Get-MessageTrace Report $UPN.csv" –NoTypeInformation -Encoding UTF8
    Write-Host "Running Search-UnifiedAuditLog."
    Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate | Select-Object -ExpandProperty AuditData | ConvertFrom-Json | Select-Object CreationTime, Operation, ResultStatus, ClientIP, UserId, RequestType, ResultStatusDetail, ActorIpAddress | Where-Object {($_.ActorIpAddress -ne $null)} | Export-Csv "$($env:USERPROFILE)\Desktop\Search-UnifiedAuditLog Report $UPN.csv" –NoTypeInformation -Encoding UTF8
  }
  If ($AdminAuditLogEnabled -eq $False) {
    Write-Host "Enabling the Admin Audit Log."
    Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $True
  }
}
$AccountTakeover = Read-Host "Based on the information included in the log files, do you believe this account is compromised? (Yes/No)"
If ($AccountTakeover -like "y") {
  Get-MsolUser -UserPrincipalName $UPN | Set-AzureADUser -AccountEnabled $false
  Get-MsolUser -UserPrincipalName $UPN | Revoke-AzureADUserAllRefreshToken
}
If ($AccountTakeover -like "n") {
  exit
}
