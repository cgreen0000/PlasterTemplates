[CmdletBinding()]
param(
    [parameter(Position=0)]
    $Task = 'NewBuildVerison'
)

Get-PackageProvider -Name 'NuGet' -ForceBootstrap | Out-Null

if (!(Get-Module -Name InvokeBuild -ListAvailable)) { # Because the egg can't come before the chicken... or was it the chicken before the egg?
    Install-Module -Name InvokeBuild -Scope CurrentUser -Force -SkipPublisherCheck
}

$Error.Clear()

Invoke-Build -Task $Task -Result 'Result'
if ($Result.Error) {
    $Error[-1].ScriptStackTrace | Out-String
    exit 1
}

exit 0