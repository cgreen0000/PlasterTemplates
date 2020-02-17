# Build tasks for Invoke-Build.

task InstallDependencies

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

task InstallDependencies {
    if (!(Get-Module -Name Pester -ListAvailable)) { # Required for Test task.
        Install-Module -Name Pester -Scope CurrentUser
    }

    if (!(Get-Module -Name PSScriptAnalyzer -ListAvailable)) { # Required for Analyze task.
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
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

task UpdateVersionMajor {
    $ManifestPath = "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\<%=$PLASTER_PARAM_ModuleName%>.psd1"

    #Get the current manifest version.
    $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
    [version]$CurrentManifestVersion = $ManifestData.ModuleVersion

    # Construction a new version number and update the manifest.
    [version]$NewManifestVersion = "{0}.{1}.{2}.{3}" -f ($CurrentManifestVersion.Major + 1), $CurrentManifestVersion.Minor, $CurrentManifestVersion.Build, $CurrentManifestVersion.Revision
    Update-ModuleManifest -Path $ManifestPath -ModuleVersion $NewManifestVersion
}

task UpdateVersionMinor {
    $ManifestPath = "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\<%=$PLASTER_PARAM_ModuleName%>.psd1"

    #Get the current manifest version.
    $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
    [version]$CurrentManifestVersion = $ManifestData.ModuleVersion

    # Construction a new version number and update the manifest.
    [version]$NewManifestVersion = "{0}.{1}.{2}.{3}" -f $CurrentManifestVersion.Major, ($CurrentManifestVersion.Minor + 1), $CurrentManifestVersion.Build, $CurrentManifestVersion.Revision
    Update-ModuleManifest -Path $ManifestPath -ModuleVersion $NewManifestVersion
}

task UpdateVersionBuild {
    $ManifestPath = "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\<%=$PLASTER_PARAM_ModuleName%>.psd1"

    #Get the current manifest version.
    $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
    [version]$CurrentManifestVersion = $ManifestData.ModuleVersion

    # Construction a new version number and update the manifest.
    [version]$NewManifestVersion = "{0}.{1}.{2}.{3}" -f $CurrentManifestVersion.Major, $CurrentManifestVersion.Minor, ($CurrentManifestVersion.Build + 1), $CurrentManifestVersion.Revision
    Update-ModuleManifest -Path $ManifestPath -ModuleVersion $NewManifestVersion
}

task UpdateVersionRevision {
    $ManifestPath = "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\<%=$PLASTER_PARAM_ModuleName%>.psd1"

    #Get the current manifest version.
    $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
    [version]$CurrentManifestVersion = $ManifestData.ModuleVersion

    # Construction a new version number and update the manifest.
    [version]$NewManifestVersion = "{0}.{1}.{2}.{3}" -f $CurrentManifestVersion.Major, $CurrentManifestVersion.Minor, $CurrentManifestVersion.Build, ($CurrentManifestVersion.Revision + 1)
    Update-ModuleManifest -Path $ManifestPath -ModuleVersion $NewManifestVersion
}