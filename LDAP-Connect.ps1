# Script contents
#Param([String]$Domain)

$DomainObj = Get-ADDomain -Server 192.168.11.10 -Credential $Secret:DuckAdmin
Write-Output $DomainObj.distinguishedName


