# Script contents
Describe 'ActiveDirectory-Connect.' {
    It 'Job' {
        Invoke-PSUScript -Script 'ActiveDirectory-Connect.ps1' | Wait-PSUJob
    }
}
