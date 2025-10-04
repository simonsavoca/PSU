New-PSUEndpoint -Url "/inactiveusers/:domain" -Description "Get Inactive Users of a domain" -Method @('GET') -Endpoint {
    # Enter your script to process requests.
    "Hello world"
} -Authentication -Documentation "Docs" 
New-PSUEndpoint -Url "/psm" -Description "Fake CyberArk API" -Method @('GET') -Endpoint {
    # Enter your script to process requests.
    @{
        content = "Somepass1"
    } | ConvertTo-Json
} -Authentication -Documentation "Docs"