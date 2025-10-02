New-PSUEndpoint -Url "/hello-world" -Description "test" -Method @('GET') -Endpoint {
    <# 
.SYNOPSIS
This is an endpoint to get computer info

.DESCRIPTION
Get detailed computer info
#>

    # Enter your script to process requests.
    Get-ComputerInfo
} -Documentation "Hello-World"