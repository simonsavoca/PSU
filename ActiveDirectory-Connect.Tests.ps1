# Script contents
Describe 'ActiveDirectory-Connect.' {
    It 'Job' {
        Invoke-PSUScript -Script 'ActiveDirectory-Connect.ps1' -RequiredParameter 'Hello' | Tee-Object -Variable job | Wait-PSUJob
        $Output = Get-PSUJobPipelineOutput -Job $Job
        Write-Output $Output
    }
}
