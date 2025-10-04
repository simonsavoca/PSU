# Script contents
Param($Domain)
$ADSI = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$OUPath", $cred.UserName, $cred.GetNetworkCredential().Password)