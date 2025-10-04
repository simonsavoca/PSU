# Script contents
#Param([String]$Domain)

$DomainObj = Get-ADDomain -Server 192.168.11.10 -Credential $Secret:DuckAdmin
$DomainDn = $DomainObj.distinguishedName
Write-Output $DomainObj.distinguishedName
$ADSI = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$DomainDn", $Secret:DuckAdmin.UserName, $Secret:DuckAdmin.Password)


