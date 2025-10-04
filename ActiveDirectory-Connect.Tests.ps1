# Script contents
Describe 'ActiveDirectory-Connect' {
    It 'Job' {
        Invoke-PSUScript -Script 'ActiveDirectory-Connect.ps1' | Tee-Object -Variable job | Wait-PSUJob
        $Output = Get-PSUJobPipelineOutput -Job $Job
        $Output | Should -Not -BeNullOrEmpty
    }
    It 'Test' {
        1 | Should -BeExactly 1
    }
}
