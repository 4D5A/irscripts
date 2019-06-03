$AdminAuditLogEnabled = Get-AdminAuditLogConfig | Select -ExpandProperty UnifiedAuditLogIngestionEnabled
$Dehydrated = Get-OrganizationConfig | Select -ExpandProperty IsDehydrated
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
    Get-MessageTrace -StartDate $StartDate -EndDate $EndDate -RecipientAddress $UPN | Select MessageId, Organization, Received, SenderAddress, RecipientAddress, Subject, Status, FromIP, ToIP, PSComputerName, RunspaceId, MessageTraceId | Export-Csv "$($env:USERPROFILE)\Desktop\Get-MessageTrace Report $UPN.csv" –NoTypeInformation -Encoding UTF8
    Write-Host "Running Search-UnifiedAuditLog."
    Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate | Select-Object -ExpandProperty AuditData | ConvertFrom-Json | Select CreationTime, Operation, ResultStatus, ClientIP, UserId, RequestType, ResultStatusDetail, ActorIpAddress | Where {($_.ActorIpAddress -ne $null)} | Export-Csv "$($env:USERPROFILE)\Desktop\Search-UnifiedAuditLog Report $UPN.csv" –NoTypeInformation -Encoding UTF8
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
