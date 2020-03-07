# Build tasks for Invoke-Build.

# Synopsis: Default task. Runs tests, updates build number, signs and build an artifact.
task . Prerequisites,Analyze,Test,UpdateVersionBuild,Clean,Stage,Sign,Archive

# Synopsis: Default task. Runs tests, updates build number, signs and build an artifact.
task NewBuildVerison Prerequisites,Analyze,Test,UpdateVersionBuild,Clean,Stage,Sign,Archive

# Synopsis: Run PSScriptAnalyzer.
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

# Synopsis: Package the module as a zip file.
task Archive {
    $ArtifactsArchive = "$BuildRoot\Artifacts\<%=$PLASTER_PARAM_ModuleName%>.zip"
    $StagedModule = "$BuildRoot\Staging\<%=$PLASTER_PARAM_ModuleName%>"

    Compress-Archive -Path $StagedModule -DestinationPath $ArtifactsArchive -Force
}

# Synopsis: Remove the Artifacts and Staging directories.
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

# Synopsis: Copy artifact to a network share.
task Deploy {
    Copy-Item -Path "$BuildRoot\Artifacts\<%=$PLASTER_PARAM_ModuleName%>.zip" -Destination "<%=$PLASTER_PARAM_ModuleDeploySMB%>" -Force
}

# Synopsis: Install modules required for testing.
task Prerequisites {
    if (!(Get-Module -Name Pester -ListAvailable)) { # Required for Test task.
        Install-Module -Name Pester -Scope CurrentUser
    }

    if (!(Get-Module -Name PSScriptAnalyzer -ListAvailable)) { # Required for Analyze task.
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
    }

    if (Get-Module -Name "<%=$PLASTER_PARAM_ModuleName%>") {
        Remove-Module -Name "<%=$PLASTER_PARAM_ModuleName%>"
    }
    Import-Module "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\<%=$PLASTER_PARAM_ModuleName%>.psd1"
}

# Synopsis: Sign the module scripts with the current user's code signing certificate.
task Sign {
    $StagingFolder = "$BuildRoot\Staging\"
    $SigningCert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
    Get-ChildItem -Path "$StagingFolder\*.ps1" -Recurse | Set-AuthenticodeSignature -Certificate $SigningCert
}

# Synopsis: Copy the module to the staging folder for signing.
task Stage {
    $StagingFolder = "$BuildRoot\Staging\"
    Copy-Item -Path "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\" -Destination $StagingFolder -Recurse -Force
}

# Synopsis: Run unit tests.
task Test {
    $PesterParameters = @{
        Strict = $true
        PassThru = $true
        Verbose = $false
        EnableExit = $false
        CodeCoverage = (Get-ChildItem -Path "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\*.ps1" -Recurse).FullName
    }

    $PesterResults = Invoke-Pester @PesterParameters

    Assert ($PesterResults.FailedCount -eq 0) ("Failed {0} tests." -f $PesterResults.FailedCount)
}

# Synopsis: Set module version to the next major version.
task UpdateVersionMajor {
    $ManifestPath = "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\<%=$PLASTER_PARAM_ModuleName%>.psd1"

    #Get the current manifest version.
    $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
    [version]$CurrentManifestVersion = $ManifestData.ModuleVersion

    # Construction a new version number and update the manifest.
    [version]$NewManifestVersion = "{0}.{1}.{2}.{3}" -f ($CurrentManifestVersion.Major + 1), 0, 0, 0
    Update-ModuleManifest -Path $ManifestPath -ModuleVersion $NewManifestVersion
}

# Synopsis: Set module version to the next minor version.
task UpdateVersionMinor {
    $ManifestPath = "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\<%=$PLASTER_PARAM_ModuleName%>.psd1"

    #Get the current manifest version.
    $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
    [version]$CurrentManifestVersion = $ManifestData.ModuleVersion

    # Construction a new version number and update the manifest.
    [version]$NewManifestVersion = "{0}.{1}.{2}.{3}" -f $CurrentManifestVersion.Major, ($CurrentManifestVersion.Minor + 1), 0, 0
    Update-ModuleManifest -Path $ManifestPath -ModuleVersion $NewManifestVersion
}

# Synopsis: Set module version to the next build verison.
task UpdateVersionBuild {
    $ManifestPath = "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\<%=$PLASTER_PARAM_ModuleName%>.psd1"

    #Get the current manifest version.
    $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
    [version]$CurrentManifestVersion = $ManifestData.ModuleVersion

    # Construction a new version number and update the manifest.
    [version]$NewManifestVersion = "{0}.{1}.{2}.{3}" -f $CurrentManifestVersion.Major, $CurrentManifestVersion.Minor, ($CurrentManifestVersion.Build + 1), 0
    Update-ModuleManifest -Path $ManifestPath -ModuleVersion $NewManifestVersion
}

# Synopsis: Set module version to the next revision.
task UpdateVersionRevision {
    $ManifestPath = "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\<%=$PLASTER_PARAM_ModuleName%>.psd1"

    #Get the current manifest version.
    $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
    [version]$CurrentManifestVersion = $ManifestData.ModuleVersion

    # Construction a new version number and update the manifest.
    [version]$NewManifestVersion = "{0}.{1}.{2}.{3}" -f $CurrentManifestVersion.Major, $CurrentManifestVersion.Minor, $CurrentManifestVersion.Build, ($CurrentManifestVersion.Revision + 1)
    Update-ModuleManifest -Path $ManifestPath -ModuleVersion $NewManifestVersion
}