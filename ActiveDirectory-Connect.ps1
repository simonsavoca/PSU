# Script contents
Get-ADUser -Filter * -Server 192.168.11.10 -Credential $Secret:DuckAdmin
#Get-ADGroup -Filter * -Server 192.168.11.10 -Credential $Secret:DuckAdmin
#Write-Output $Secret:DuckAdmin.Username
#Get-ADUser -Filter * -Server 192.168.11.10
