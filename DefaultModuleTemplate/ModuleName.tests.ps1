# General tests for the module.

Describe "General module tests for: <%=$PLASTER_PARAM_ModuleName%>" {
    It "Module '<%=$PLASTER_PARAM_ModuleName%>' can import cleanly" {
        {Import-Module "$BuildRoot\<%=$PLASTER_PARAM_ModuleName%>\<%=$PLASTER_PARAM_ModuleName%>.psm1" -force } | Should Not Throw
    }
}