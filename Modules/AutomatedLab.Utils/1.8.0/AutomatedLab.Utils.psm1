#Region '.\public\Get-AllLabConfigurations.ps1' -1

#EndRegion '.\public\Get-AllLabConfigurations.ps1' 1
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
#Region '.\public\Get-PSULabConfigurations.ps1' -1

function Get-PSULabConfiguration {
    <#
    .SYNOPSIS
    Returns lab configuration objects
    
    .DESCRIPTION
    Returns all lab configurations when no Name is specified, or a specific configuration when Name is provided.
       
    .PARAMETER Name
    The name of the specific configuration to return. If not specified, all configurations are returned.
    
    .EXAMPLE
    Get-AllLabConfigurations
    
    Returns all available lab configurations.
    
    .EXAMPLE
    Get-AllLabConfigurations -Name Example
    
    Returns the specific configuration named 'Example'.
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]
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
        if ($Name) {
            Import-Configuration -Name $Name -CompanyName $env:USERNAME
        } else {
            $configPath = Join-Path $env:LocalAppData -ChildPath "powershell\$env:USERNAME"
            if (Test-Path $configPath) {
                Get-ChildItem -Path $configPath -Directory | ForEach-Object {
                    $config = Import-Configuration -Name $_.Name -CompanyName $env:USERNAME
                    $config.Name = $_.Name
                    $config
                }
            }
        }
    }
}
#EndRegion '.\public\Get-PSULabConfigurations.ps1' 56
#Region '.\public\Get-PSULabInfo.ps1' -1

function Get-PSULabInfo {
    <#
    .SYNOPSIS
    Imports a lab by name and returns basic information about the lab machines.
    
    .DESCRIPTION
    This function imports an AutomatedLab by name and returns information about each machine
    including the name, processor count, memory, and operating system.
    
    .PARAMETER LabName
    The name of the lab to import and analyze.
    
    .EXAMPLE
    Get-LabInfo -LabName "MyTestLab"
    
    .EXAMPLE
    Get-LabInfo "MyTestLab" | Format-Table -AutoSize
    
    .NOTES
    This function requires the AutomatedLab module to be installed and available.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $availableLabs = Get-Lab -List
                $availableLabs | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                }
            }
            catch {
                # Return empty array if Get-Lab fails
                @()
            }
        })]
        [string]$LabName
    )
    
    try {
        # Import the specified lab
        Write-Verbose "Importing lab: $LabName"
        Import-Lab -Name $LabName -NoValidation | Out-Null
        
        # Get all machines in the lab
        $machines = Get-LabVM
        $status = Get-LabVMStatus -AsHashTable
        if (-not $machines) {
            Write-Warning "No machines found in lab '$LabName'"
            return
        }
        
        # Create custom objects with the requested information
        $labInfo = foreach ($machine in $machines) {
            [PSCustomObject]@{
                Name = $machine.Name
                ProcessorCount = $machine.Processors
                Memory = $machine.Memory
                OperatingSystem = $machine.OperatingSystem.OperatingSystemName
                MemoryGB = [Math]::Round($machine.Memory / 1GB, 2)
                Status = $status[$machine.Name]
            }
        }
        
        Write-Verbose "Retrieved information for $($labInfo.Count) machines"
        return $labInfo
    }
    catch {
        Write-Error "Failed to import lab '$LabName': $($_.Exception.Message)"
        throw
    }
}

# Example usage and testing function
function Test-GetLabInfo {
    <#
    .SYNOPSIS
    Test function to demonstrate Get-LabInfo usage.
    #>
    
    # Get list of available labs
    Write-Host "Available labs:" -ForegroundColor Green
    $availableLabs = Get-Lab -List
    
    if ($availableLabs) {
        $availableLabs | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        
        # Example of how to use the function
        Write-Host "`nExample usage:" -ForegroundColor Green
        Write-Host "Get-LabInfo -LabName '$($availableLabs[0])'" -ForegroundColor Cyan
        Write-Host "Get-LabInfo '$($availableLabs[0])' | Format-Table -AutoSize" -ForegroundColor Cyan
        Write-Host "Get-LabInfo '$($availableLabs[0])' | Where-Object { `$_.ProcessorCount -gt 2 }" -ForegroundColor Cyan
    }
    else {
        Write-Host "No labs found. Create a lab first using AutomatedLab." -ForegroundColor Red
    }
}
#EndRegion '.\public\Get-PSULabInfo.ps1' 100
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
    
    .PARAMETER ScriptBlock
    A PowerShell script block that will be saved as the definition
    
    .EXAMPLE
    $conf = @{
        Name = 'MyDomainLab'
        Definition = 'C:\Labs\DomainController.ps1'
        Parameters = @{
            DomainName = 'contoso.com'
            AdminPassword = 'P@ssw0rd123!'
        }
    }

    New-LabConfiguration @conf
    
    .EXAMPLE
    $conf = @{
        Name = 'SQLServerLab'
        Url = 'https://raw.githubusercontent.com/AutomatedLab/AutomatedLab/main/LabSources/SampleScripts/Introduction/03%20SQL%20Server%20and%20client,%20domain%20joined.ps1'
        Parameters = @{
            SQLServiceAccount = 'CONTOSO\SQLService'
            DatabaseName = 'ProductionDB'
        }
    }

    New-LabConfiguration @conf

    .EXAMPLE
    $scriptBlock = {
        New-LabDefinition -Name $Parameters.LabName -DefaultVirtualizationEngine HyperV
        Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword P@ssw0rd123!
        Add-LabMachineDefinition -Name DC01 -Memory 2GB -Roles RootDC -DomainName contoso.com
        Add-LabMachineDefinition -Name Client01 -Memory 1GB -OperatingSystem 'Windows 10 Enterprise' -DomainName contoso.com
        Install-Lab
    }

    New-LabConfiguration -Name 'BasicDomainLab' -ScriptBlock $scriptBlock -Parameters @{ LabName = 'TestDomain' }


    #>
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'default')]
        [Parameter(Mandatory, ParameterSetName = 'Git')]
        [Parameter(Mandatory, ParameterSetName = 'ScriptBlock')]
        [String]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'default')]
        [String]
        $Definition,

        [Parameter(ParameterSetName = 'Git')]
        [Parameter(ParameterSetName = 'default')]
        [Parameter(ParameterSetName = 'ScriptBlock')]
        [Hashtable]
        $Parameters,

        [Parameter(Mandatory, ParameterSetName = 'Git')]
        [String]
        $Url,

        [Parameter(Mandatory, ParameterSetName = 'ScriptBlock')]
        [ScriptBlock]
        $ScriptBlock
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
            'ScriptBlock' {
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
        # where the definition will be saved when downloading from a Url or saving a ScriptBlock.
        # So we postpone processing until we have exported the configuration with the correct
        # value, and then just drop the file there.
        if ($url) {
            [System.Net.WebClient]::new().DownloadFile($Url, $Definition)       
        }
        
        if ($ScriptBlock) {
            $ScriptBlock.ToString() | Out-File -FilePath $Definition -Encoding UTF8
        }         

    }
}
#EndRegion '.\public\New-LabConfiguration.ps1' 133
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
