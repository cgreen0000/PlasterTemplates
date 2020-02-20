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

task Archive {
    $ArtifactsArchive = "$BuildRoot\Artifacts\<%=$PLASTER_PARAM_ModuleName%>.zip"
    $StagedModule = "$BuildRoot\Staging\<%=$PLASTER_PARAM_ModuleName%>"

    Compress-Archive -Path $StagedModule -DestinationPath $ArtifactsArchive -Force
}

task Clean {
    if (Test-Path -Path "$BuildRoot\Artifacts") {
        Remove-Item "$BuildRoot\Artifacts" -Recurse -Force
    }

    if (Test-Path -Path "$BuildRoot\Staging") {
        Remove-Item "$BuildRoot\Staging" -Recurse -Force
    }

    New-Item -ItemType Directory -Path "$BuildRoot\Artifacts" -Force
    New-Item -ItemType Directory -Path "$BuildRoot\Staging" -Force
}

task Deploy {
    $SMBShare = "\\placeholder\share"
    Copy-Item -Path "$BuildRoot\Artifacts\<%=$PLASTER_PARAM_ModuleName%>.zip" -Destination $SMBShare -Force
}

task InstallDependencies {
    if (!(Get-Module -Name Pester -ListAvailable)) { # Required for Test task.
        Install-Module -Name Pester -Scope CurrentUser
    }

    if (!(Get-Module -Name PSScriptAnalyzer -ListAvailable)) { # Required for Analyze task.
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
    }
}

task Sign {
    $StagingFolder = "$BuildRoot\Staging\"
    $SigningCert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
    Get-ChildItem -Path "$BuildRoot\$StagingFolder\*.ps1" -Recurse | Set-AuthenticodeSignature -Certificate $SigningCert
}

task Stage {
    $StagingFolder = "$BuildRoot\Staging\"
    Copy-Item -Path "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\" -Destination $StagingFolder -Recurse -Force
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