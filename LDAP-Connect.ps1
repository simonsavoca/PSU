# Script contents
#Param([String]$Domain)

#$DomainObj = Get-ADDomain -Server 192.168.11.10 -Credential $Secret:DuckAdmin

#$ADSI = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$($DomainObj.DistinguishedName)", $Secret:DuckAdmin.UserName, $Secret:DuckAdmin.Password)

$Connection = [adsi]"LDAP://192.168.11.10:389"
Write-Output $Connection