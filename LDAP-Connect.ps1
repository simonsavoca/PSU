# Script contents
Param([String]$Domain)

Get-ADDomain -Server $Domain

#$ADSI = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$OUPath", $cred.UserName, $cred.GetNetworkCredential().Password)
#Write-Output $ADSI