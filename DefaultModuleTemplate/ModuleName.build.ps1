# Build tasks for Invoke-Build.

task InstallDependencies

task InstallDependencies {
    if (!(Get-Module -Name Pester -ListAvailable)) { # Required for Test task.
        Install-Module -Name Pester -Scope CurrentUser
    }

    if (!(Get-Module -Name PSScriptAnalyzer -ListAvailable)) { # Required for Analyze task.
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
    }
}

task Analyze {
    $scriptAnalyzerParameters = @{
        Path = "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>"
        Severity = @('Error', 'Warning')
        Recurse = $true
        Verbose = $false
    }

    $saResults = Invoke-ScriptAnalyzer @scriptAnalyzerParameters

    if ($saResults) {
        $saResults | Format-Table
        throw "PSScriptAnalyzer errors or warnings were found."
    }
}

task Test {
    $pesterParameters = @{
        Strict = $true
        PassThru = $true
        Verbose = $false
        EnableExit = $false
    }

    $pesterResults = Invoke-Pester @pesterParameters

    Assert ($pesterResults.FailedCount -eq 0) ("Failed {0} tests." -f $pesterResults.FailedCount)
}