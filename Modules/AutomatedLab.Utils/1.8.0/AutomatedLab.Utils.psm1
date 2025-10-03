#Region '.\public\Get-AvailableLab.ps1' -1

#EndRegion '.\public\Get-AvailableLab.ps1' 1
#Region '.\public\Get-CustomRole.ps1' -1

function Get-CustomRole {
    <#
    .SYNOPSIS
    List available custom roles
    
    .EXAMPLE
    Get-CustomRole
    #>
    [CmdletBinding()]
    Param()

    end {
        $LabSource = Get-LabSourcesLocation
        $RolePath = Join-Path $LabSource -ChildPath 'CustomRoles'

        (Get-ChildItem $RolePath -Directory).Name
    }
}
#EndRegion '.\public\Get-CustomRole.ps1' 19
#Region '.\public\Get-LabConfiguration.ps1' -1

function Get-LabConfiguration {
    <#
    .SYNOPSIS
    Returns a configuration object
       
    .PARAMETER Name
    The name of the configuration to return
    
    .EXAMPLE
    Get-LabConfiguration -Name Example
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

            $configPath = Join-Path $env:LocalAppData -ChildPath "powershell\$env:USERNAME"
            if (Test-Path $configPath) {
                Get-ChildItem -Path $configPath -Directory | Where-Object {
                    $_.Name -like "$wordToComplete*"
                } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
                }
            }
        })]
        [String]
        $Name
    )

    end {
        Import-Configuration -Name $Name -CompanyName $env:USERNAME
    }
}
#EndRegion '.\public\Get-LabConfiguration.ps1' 35
#Region '.\public\Get-LabConfigurationPath.ps1' -1

function Get-LabConfigurationPath {
    <#
    .SYNOPSIS
    Returns the path to the lab configuration
        
    .PARAMETER Name
    The lab to return
    
    .EXAMPLE
    Get-LabCOnfiguration -Name MyLab
    
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $Name
    )

    end {
        Get-ConfigurationPath -Name $Name -CompanyName $env:USERNAME -Scope User
    }
}
#EndRegion '.\public\Get-LabConfigurationPath.ps1' 24
#Region '.\public\New-CustomRole.ps1' -1

function New-CustomRole {
    <#
    .SYNOPSIS
    Creates a new Custom Role in AutomatedLab
    
    .PARAMETER Name
    The name of the custom role
    
    .PARAMETER InitScript
    If you already have the role script written, provide it with -InitScript
    
    .PARAMETER AdditionalFiles
    Provide the file path of any additional files the role requires to function
    
    .PARAMETER InitUrl
    This is a url to a PowerShell hosted online, e.g a gist or repository.

    .EXAMPLE
    New-CustomRole -Name SampleRole

    Create a new role called SampleRole. It will be bootstrapped for you.

    .EXAMPLE
    New-CustomRole -Name SampleRole -InitScript C:\scripts\role_scripts\SampleRole.ps1

    Create a new role called SampleRole, and use an existing InitScript

    .EXAMPLE
    New-CustomRole -Name SampleRole -AdditionalFiles C:\temp\cert.pfx,C:\temp\my.lic

    Create a new role called SampleRole and provide some additonal files it requires

    .EXAMPLE
    New-CustomRole -Name SampleRole -InitUrl https://fabrikam.com/roles/SampleRole/role.ps1

    Creates a new role called SampleRole and downloads the role script from a url and saves it as SampleRole.ps1
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter()]
        [ValidateScript({ 
                if ((Test-Path $_) -and ((Get-Item $_).Extension -eq ".ps1")) {
                    $true
                } 
                else {
                    throw "The init script either doesn't exist or must be a .ps1 file!"
                }
            })]
        [String]
        $InitScript,

        [Parameter()]
        [string]
        $InitUrl,

        [Parameter()]
        [ValidateScript({
                $af = $_
                $af | ForEach-Object { Test-Path $_ }
            })]
        [String[]]
        $AdditionalFiles
    )

    end {

        $LabSourcesLocation = Get-LabSourcesLocation
        $rolePath = Join-Path (Join-Path $LabSourcesLocation -ChildPath 'CustomRoles') -ChildPath $Name
        
        if (-not (Test-Path $rolePath)) {
            $null = New-Item $rolePath -ItemType Directory

           
            if ($InitScript) {
                # If user provides an init script, put it in the role folder
                Copy-Item $InitScript -Destination "$rolePath\$Name.ps1"
            }

            elseif($InitUrl) {
                # When provided a url it downloads the scipt contents and saves it as the role script
                $Script = Join-Path $rolePath -ChildPath "$($Name).ps1"
                $contents = [System.Net.WebClient]::New().DownloadString($InitUrl)
                $contents | Out-File $Script
            }

            else {
                # Otherwise we just create a blank role script
                $null = New-Item -Path $rolePath -Name "$($Name).ps1" -ItemType File
            }
            
            # Copy any additional files to the role
            if ($AdditionalFiles) {
                Copy-Item (Resolve-Path $AdditionalFiles) -Destination $rolePath
            }
        }

        else {
            throw 'Role already exists. Please choose a different name.'
        }
    }
}
#EndRegion '.\public\New-CustomRole.ps1' 106
#Region '.\public\New-HostsFileEntry.ps1' -1

function New-HostsFileEntry {
    <#
    .SYNOPSIS
    Adds an entry to the HOSTS file for the given ip address and hostname
        
    .PARAMETER IPAddress
    The ip address to add
    
    .PARAMETER Hostname
    The hostname to add
    
    .PARAMETER Note
    An optional note about the entry

    .EXAMPLE
    New-HostsFileEntry -IpAddress 127.0.0.1 -Hostname widget.fabrikam.com
    
    .EXAMPLE
    New-HostsFileEntry -IpAddress 10.10.10.100 -Hostname widget.fabrikam.com -Note 'this is my fancy widget server'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $IPAddress,

        [Parameter(Mandatory)]
        [String]
        $Hostname,

        [Parameter()]
        [String]
        $Note
    )
begin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This function requires administrator privileges. Please elevate your terminal, and try this command again."
    }
}
    end {
        $entry = '{0}  {1}' -f $IPAddress, $Hostname

        if ($Note) {
            $entry = "$entry #{0}" -f $Note
        }

        $hostFile = 'C:\Windows\system32\drivers\etc\hosts'
        $entry | Out-File -FilePath $hostFile -Encoding utf8 -Append
    }
}

#EndRegion '.\public\New-HostsFileEntry.ps1' 52
#Region '.\public\New-LabConfiguration.ps1' -1

function New-LabConfiguration {
    <#
    .SYNOPSIS
    Creates a new lab configuration
    
    .DESCRIPTION
    Long description
    
    .PARAMETER Name
    The name for the configuration
    
    .PARAMETER Definition
    A .ps1 file you wish to save with the configuration
    
    .PARAMETER Parameters
    A hashtable of Parameters that will be passed to the Definition when executed
    
    .PARAMETER Url
    A url to a PowerShell script you wish to include as the definition
    
    .EXAMPLE
    $conf = @{
    Name = 'Example'
    Definition = 'C:\temp\sample.ps1'
    Parameters = @{
        Animal = 'Dog'
        Breed = 'Lab'
        }
    }

    New-LabConfiguration @conf
    
    .EXAMPLE
    $conf = @{
    Name = 'Example'
    Url = 'https://files.fabrikam.com/myscript.ps1'
    Parameters = @{
        Animal = 'Dog'
        Breed = 'Lab'
       }
    }

    New-LabConfiguration @conf


    #>
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'default')]
        [Parameter(Mandatory, ParameterSetName = 'Git')]
        [String]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'default')]
        [String]
        $Definition,

        [Parameter(ParameterSetName = 'Git')]
        [Parameter(ParameterSetName = 'default')]
        [Hashtable]
        $Parameters,

        [Parameter(Mandatory, ParameterSetName = 'Git')]
        [String]
        $Url
    )

    end {

        $ConfigurationBase = Join-Path $env:LOCALAPPDATA -ChildPath 'PowerShell'
        $slug = Join-Path $env:USERNAME -ChildPath $Name

        $Configuration = Join-Path $ConfigurationBase -ChildPath $slug

        if (-not $Parameters) {
            $Parameters = @{}
        }

        #Add the name
        $Parameters.Add('Name', $Name)
        
        switch ($PSCmdlet.ParameterSetName) {
            'Git' {
                $Definition = Join-Path $Configuration -ChildPath 'Definition.ps1' 
            }
            default {
                $Definition = Resolve-Path $Definition
            }
        }

        @{
            Definition = $Definition
            Parameters = $Parameters
        } | Export-Configuration -CompanyName $env:USERNAME -Name $Name -Scope User

        # The configuration has to exist on disk before we can use it to build the path
        # where the definition will be saved when downloading from a Url.
        # So we postpone processing until we have exported the configuration with the correct
        # value, and then just drop the file there.
        if ($url) {
            [System.Net.WebClient]::new().DownloadFile($Url, $Definition)       
        }         

    }
}
#EndRegion '.\public\New-LabConfiguration.ps1' 106
#Region '.\public\New-OptionSet.ps1' -1

function New-OptionSet {
    <#
    .SYNOPSIS
    Creates a numbered list of options for display or selection purposes.
    
    .DESCRIPTION
    The New-OptionSet function takes an array of options and formats them as a numbered list, 
    starting from 1. This is useful for creating menus, displaying choices, or formatting 
    options for user selection.
    
    .PARAMETER Options
    An array of strings representing the options to be numbered and displayed.
    
    .EXAMPLE
    New-OptionSet -Options @('Red', 'Blue', 'Green')
    
    Output:
    1. Red
    2. Blue
    3. Green
    
    .EXAMPLE
    $colors = @('Red', 'Blue', 'Green', 'Yellow')
    New-OptionSet -Options $colors
    
    Output:
    1. Red
    2. Blue
    3. Green
    4. Yellow
    
    .EXAMPLE
    New-OptionSet -Options 'Option A', 'Option B', 'Option C'
    
    Output:
    1. Option A
    2. Option B
    3. Option C
    
    .OUTPUTS
    System.String
    Returns formatted strings with numbered options.
    
    .NOTES
    This function is useful for creating interactive menus or displaying choices 
    in a consistent numbered format.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String[]]
        $Options
    )
        end {
            $x = 1 
            foreach ($o in $Options) {
                '{0}. {1}' -f $x, $o
                $x++
            }
        }
    }
#EndRegion '.\public\New-OptionSet.ps1' 62
#Region '.\public\New-UserPrompt.ps1' -1

function New-UserPrompt {
    <#
    .SYNOPSIS
    Creates an interactive user prompt with numbered options for selection.
    
    .DESCRIPTION
    The New-UserPrompt function displays a numbered list of options to the user and prompts 
    them to select one by entering the corresponding number. It validates the user's input 
    and returns the selected option. This is useful for creating interactive menus and 
    user choice scenarios in PowerShell scripts.
    
    .PARAMETER Options
    An array of strings representing the choices available to the user. Each option will 
    be displayed with a number starting from 1.
    
    .PARAMETER Prompt
    The text to display when prompting the user for their selection. 
    Default value is 'Select option'.
    
    .EXAMPLE
    New-UserPrompt -Options 'Larry','Curly','Moe'
    
    Output:
    1. Larry
    2. Curly
    3. Moe
    Select option (1-3): 2
    
    Returns: Curly
    
    .EXAMPLE
    $environments = @('Development', 'Testing', 'Production')
    $selected = New-UserPrompt -Options $environments -Prompt 'Choose deployment environment'
    
    Output:
    1. Development
    2. Testing
    3. Production
    Choose deployment environment (1-3): 1
    
    Returns: Development
    
    .EXAMPLE
    New-UserPrompt -Options @('Yes', 'No') -Prompt 'Continue with operation?'
    
    Output:
    1. Yes
    2. No
    Continue with operation? (1-2): 1
    
    Returns: Yes
    
    .OUTPUTS
    System.String
    Returns the selected option as a string.
    
    .NOTES
    - The function throws an error if the user enters an invalid option number
    - Input validation ensures only numbers within the valid range are accepted
    - This function is useful for creating interactive scripts that require user input
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]
        [String[]]
        $Options,

        [Parameter()]
        [String]
        $Prompt = 'Select option'
    )

    end {

        $x = 1 
        foreach($o in $Options){
            '{0}. {1}' -f $x,$o
            $x++
        }

        [int]$choiceCount = $x -1
        $choice = Read-Host -Prompt "$Prompt (1-$choiceCount)"

        if([int]$choice -gt $choiceCount){
            throw "Invalid option. Please choose between 1 and $choiceCount!"
        } else {
           $Options[($choice - 1)]
        }
    }
}
#EndRegion '.\public\New-UserPrompt.ps1' 91
#Region '.\public\Remove-LabConfiguration.ps1' -1

function Remove-LabConfiguration {
    <#
    .SYNOPSIS
    Removes a lab configuration
    
    .PARAMETER Name
    The configuration to remove
    
    .EXAMPLE
    Remove-LabConfiguration -Name TestConfig
    #>
    [CmdletBinding(ConfirmImpact =  'Medium',SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

            $configPath = Join-Path $env:LocalAppData -ChildPath "powershell\$env:USERNAME"
            if (Test-Path $configPath) {
                Get-ChildItem -Path $configPath -Directory | Where-Object {
                    $_.Name -like "$wordToComplete*"
                } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
                }
            }
        })]
        [String]
        $Name
    )

    if($PSCmdlet.ShouldProcess($Name,'Remove the lab configuration')){
        Get-ConfigurationPath -Name $Name -CompanyName $env:USERNAME -Scope User | Remove-Item -Recurse -Force
    }
}
#EndRegion '.\public\Remove-LabConfiguration.ps1' 35
#Region '.\public\Start-Lab.ps1' -1

function Start-Lab {
    <#
    .SYNOPSIS
    Starts a Lab from the configuration
    
    .DESCRIPTION
    
    
    .PARAMETER Name
    The lab to build
    
    .PARAMETER AdditionalParameters
    Any additonal parameter to pass to the lab. Will get added to configuration parameters.
    
    .EXAMPLE
    Start-Lab -Name Example

    .EXAMPLE

    Start-Lab -Name Example -AdditionalParameters @{ Car = 'Corvette'}
    
    #>
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

            $configPath = Join-Path $env:LocalAppData -ChildPath "powershell\$env:USERNAME"
            if (Test-Path $configPath) {
                Get-ChildItem -Path $configPath -Directory | Where-Object {
                    $_.Name -like "$wordToComplete*"
                } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
                }
            }
        })]
        $Name,

        [Parameter()]
        [Hashtable]
        $AdditionalParameters
    )

    end {

        $configuration = Get-LabConfiguration -Name $Name
        $parameters = $configuration['Parameters']

        if ($AdditionalParameters) {
            $AdditionalParameters.GetEnumerator() | ForEach-Object {
                $parameters[$_.Key] = $_.Value
            }
        }

        try {
            Write-Warning "Attempting to start lab: $Name"
            Import-Lab -Name $Name -ErrorAction Stop
            Get-LabVM | Start-LabVM
        }
        catch {
            Write-Warning "Lab $Name doesn't exist, creating and starting..."
            & $configuration['Definition'] @parameters
        }
    }
}
#EndRegion '.\public\Start-Lab.ps1' 67
#Region '.\public\Stop-Lab.ps1' -1

function Stop-Lab {
    <#
    .SYNOPSIS
    Stops a running lab
    
    .DESCRIPTION
    Long description
    
    .PARAMETER Name
    The lab to stop
    
    .EXAMPLE
    Stop-Lab -Name Example

    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

            $configPath = Join-Path $env:LocalAppData -ChildPath "powershell\$env:USERNAME"
            if (Test-Path $configPath) {
                Get-ChildItem -Path $configPath -Directory | Where-Object {
                    $_.Name -like "$wordToComplete*"
                } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
                }
            }
        })]
        [String]
        $Name
    )

    try {

        Import-Lab -Name $Name -ErrorAction Stop
        Get-LabVM | Stop-LabVM
    }
    catch {
        Write-Error -Message 'Lab was not found. Use Start-Lab to start or build first' -Exception ([System.IO.FileNotFoundException]::New())
    }
}
#EndRegion '.\public\Stop-Lab.ps1' 44
#Region '.\Suffix.ps1' -1

# Initialize here
#EndRegion '.\Suffix.ps1' 2
