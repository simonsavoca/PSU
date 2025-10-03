New-PSUVariable -Name "Domains" -Value @('duckplatform.local') -Type "System.Collections.ArrayList" 
New-PSUVariable -Name "Duckplatform" -Vault "Database" 
New-PSUVariable -Name "Labsources" -Value 'c:\Labsources' 
New-PSUVariable -Name "MyVariable" -Value 'sdsqdsqdqd' -Description "sdqsdqsd" 
New-PSUVariable -Name "Variable" -Vault "Database" -Type "PSCredential"