# General tests for the module.

Describe "General module tests for: <%=$PLASTER_PARAM_ModuleName%>" {
    It "Module '<%=$PLASTER_PARAM_ModuleName%>' can import cleanly" {
        {Import-Module "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\<%=$PLASTER_PARAM_ModuleName%>.psd1" -force } | Should Not Throw
    }
}

Describe "Public functions are listed in functions to export." {
    $ModuleManifest = Import-PowerShellDataFile -Path "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\<%=$PLASTER_PARAM_ModuleName%>.psd1"
    $PublicFunctions = (Get-ChildItem -Path "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\Public" -Filter '*.ps1').BaseName

    foreach ($Command in $PublicFunctions) {
        Context "$Command" {
            It "Should be exported." {
                $ModuleManifest.FunctionsToExport | Should -Contain $Command
            }
        }
    }
}

Describe "Public functions have Pester tests." {
    $Commands = Get-Command -Module "<%=$PLASTER_PARAM_ModuleName%>"

    foreach ($Command in $Commands) {
        $file = Get-ChildItem -Path "$BuildRoot\Tests" -Include "$command.Tests.ps1" -Recurse

        It "Should have a Pester test for [$command]" {
            $file.FullName | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Public functions have comment-based or external help." {   
    $Commands = Get-Command -Module "<%=$PLASTER_PARAM_ModuleName%>"

    $help = foreach ($Command in $Commands) {
        Get-Help -Name $Command.Name
    }

    foreach ($node in $help) {
        Context $node.Name {
            It "Should have a description." {
                $node.Description | Should -Not -BeNullOrEmpty
            }
            It "Should have an example." {
                $node.Examples | Should -Not -BeNullOrEmpty
            }

            foreach ($helpExample in $node.Examples.Example) {
                $title = $helpExample.Title
                It "$title should include the function being demonstrated." {
                    $helpExample | Out-String | Should -Match ($node.Name)
                }
            }

            foreach ($parameter in $node.Parameters.Parameter) {
                if ($parameter -notmatch 'WhatIf|Confirm') {
                    It "Should have a description for Parameter [$($parameter.Name)]" {
                        $parameter.Description.Text | Should -Not -BeNullOrEmpty
                    }
                }
            }
        }
    }
}
