# Script contents
$DomainObj = Get-ADDomain -Server 192.168.11.10 -Credential $Secret:DuckAdmin
$Database = "C:\ProgramData\UniversalAutomation\ActiveDirectory.db"
$dN = $DomainObj.distinguishedName
$NetBIOSName = $DomainObj.NetBIOSName
$query = "INSERT INTO Domains (distinguishedName, NetBIOS) VALUES (""$dN"", ""$NetBIOSName"");"
Write-Output $query
Invoke-SqliteQuery -DataSource $Database -Query $query
#>
