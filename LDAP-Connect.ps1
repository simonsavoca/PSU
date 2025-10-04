# Script contents
#Param([String]$Domain)

$DomainObj = Get-ADDomain -Server 192.168.11.10 -Credential $Secret:DuckAdmin
$DomainDn = $DomainObj.distinguishedName
Write-Output $DomainObj.distinguishedName
#$ADSI = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$DomainDn", $Secret:DuckAdmin.UserName, $Secret:DuckAdmin.Password)

$credentials = new-object "System.Net.NetworkCredential" -ArgumentList "cn=adminUser","password"
$OIDConnection = New-Object System.DirectoryServices.Protocols.LdapConnection "servername:636"
$OIDConnection.SessionOptions.SecureSocketLayer = $true
$OIDConnection.SessionOptions.ProtocolVersion = 3
$OIDConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic
$OIDConnection.Bind($credentials)
$groupSearchFilter = "(&(objectclass=groupOfUniqueNames)(cn=$groupCN))"
$baseDN = "dc=youreomain,dc=com"
$scope = [System.DirectoryServices.Protocols.SearchScope]::Subtree
$SearchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest -ArgumentList $baseDN,$groupSearchFilter,$scope,$null
$SearchRequest.Attributes.Add("uniquemember") | Out-Null
$groupSearchResult = $OIDConnection.SendRequest($SearchRequest)
if ($groupSearchResult.Entries.count -gt 1) {
    "Found more than one group with the same CN"
    Break
}
$groupDN = $groupSearchResult.Entries.DistinguishedName

foreach ($user in $userUIDs) {
    $userSearchFilter = "(&(uid=$user))"
    $baseDN = "dc=users,dc=yourdomain,dc=com"
    $scope = [System.DirectoryServices.Protocols.SearchScope]::Subtree
    $SearchRequest.Filter = "(&(uid=$user))"
    $SearchRequest.Attributes.Remove("uniquemember")
    $SearchRequest.Attributes.Add("memberof") | Out-Null
    $userSearchResult = $OIDConnection.SendRequest($SearchRequest)
    if ($userSearchResult.Entries.Count -gt 0) { 
        $groupMembership = $userSearchResult.Entries.attributes.memberof.GetValues("string")
        if ($groupMembership -contains $groupDN) { "$user is already a member of $groupCN" }
        else {
            $modifyRequestOperation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Add
            $modifyField = "uniquemember"
            $modifyValue = $userSearchResult.Entries.DistinguishedName
            $modifyRequest = New-Object "System.DirectoryServices.Protocols.ModifyRequest" -ArgumentList $groupDN,$modifyRequestOperation,$modifyField,$modifyValue
            $OIDModify = $OIDConnection.SendRequest($modifyRequest)
            if ($OIDModify) {
                Write-Host "$user added to $groupCN" -BackgroundColor "green" -ForegroundColor "Black"
            }
        }
    }
    else { Write-Host "$user not found in OID" -BackgroundColor "Yellow" -ForegroundColor "Black" }
}


