# Script contents
$Database = "C:\ProgramData\UniversalAutomation\ActiveDirectory.db"
$Query = "CREATE TABLE Domains (
    distinguishedName VARCHAR(50) PRIMARY KEY,
    NetBIOS VARCHAR(50))"

#SQLite will create Names.SQLite for us
Invoke-SqliteQuery -Query $Query -DataSource $Database