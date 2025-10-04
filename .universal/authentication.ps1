Set-PSUAuthenticationMethod -Type "Form" -ScriptBlock {
    param(
        [PSCredential]$Credential
    )

    #
    #   You can call whatever cmdlets you like to conduct authentication here.
    #   Just make sure to return the $Result with the Success property set to $true
    #

    New-PSUAuthenticationResult -ErrorMessage 'Bad username or password2'
} 
Set-PSUAuthenticationMethod -Type "Windows" -Disabled