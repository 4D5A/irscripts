$StartDate = (Get-Date).Adddays(-14)
$EndDate = (Get-Date)
$UPN = Read-Host "Enter the User Principal Name of the account for which you want to obtain logs"
$Dehydrated = Get-OrganizationConfig | Select -ExpandProperty IsDehydrated
If ($Dehydrated -eq $True) {
  Write-Host "It is Dehydrated."
  Enable-OrganizationCustomization
  Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
}
If ($Dehydrated -eq $False) {
  Write-Host "It is not Dehydrated."
  Get-MessageTrace -StartDate $StartDate -EndDate $EndDate -RecipientAddress $UPN | Select MessageId, Organization, Received, SenderAddress, RecipientAddress, Subject, Status, FromIP, ToIP, PSComputerName, RunspaceId, MessageTraceId | Export-Csv "$($env:USERPROFILE)\Desktop\Get-MessageTrace Report $UPN.csv" –NoTypeInformation -Encoding UTF8
  Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate | Select-Object -ExpandProperty AuditData | ConvertFrom-Json | Select CreationTime, Operation, ResultStatus, ClientIP, UserId, RequestType, ResultStatusDetail, ActorIpAddress | Where {($_.ActorIpAddress -ne $null)} | Export-Csv "$($env:USERPROFILE)\Desktop\Search-UnifiedAuditLog Report $UPN.csv" –NoTypeInformation -Encoding UTF8
}
$AccountTakeover = Read-Host "Based on the information included in the log files, do you believe this account is compromised? (Yes/No)"
If ($AccountTakeover -like "y") {Write-Host "The answer is yes."}
  Get-MsolUser $UPN | Set-AzureADUser -AccountEnabled $false
  Get-MsolUser $UPN | Revoke-AzureADUserAllRefreshToken
  Get-MsolUser $UPN | Set-AzureADUser -AccountEnabled $true
}
If ($AccountTakeover -like "n") {
  exit
}
