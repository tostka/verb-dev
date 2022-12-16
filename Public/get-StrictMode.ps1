#*------v get-StrictMode.ps1 v------
Function get-StrictMode {
    <#
    .SYNOPSIS
    get-StrictMode - A very simple function to retrieve the Set-StrictMode setting of the user
session. 
    .NOTES
    Version     : 2.1.0
    Author      : Sea Star Development
    Website     :	https://www.powershellgallery.com/packages/strictmode/2.1/Content/strictmode.ps1
    Twitter     :	
    CreatedDate : 2022-12-15
    FileName    : get-StrictMode.ps1
    License     : (none asserted)
    Copyright   : Sea Star Development
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,debugging
    AddedCredit : Todd Kadrie
    AddedWebsite:	http://www.toddomation.com
    AddedTwitter:	@tostka / http://twitter.com/tostka
    REVISIONS
    * 1:10 PM 12/15/2022 added vers 3 test/triggers (existing only went to v2); updated CBH; added to verb-dev
    * 11/17/2017 (posted psg version) "V2.1 Incorporate Version() and ToString() ScriptMethods, 4 Jan 2013."
    .DESCRIPTION
    get-StrictMode - A very simple function to retrieve the Set-StrictMode setting of the user
session. 
    Retrieve the Set-StrictMode setting for the current session.
This procedure is necessary as there is, apparently, no equivalent PowerShell
variable for this and it enables the setting to be returned to its original
state after possibly being changed within a script. Add this function
to your $profile. 

    [Set-StrictMode (Microsoft.PowerShell.Core) - PowerShell | Microsoft Learn - learn.microsoft.com/](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode?view=powershell-7.2)

    ## -Version

    ### `1.0`

    -   Prohibits references to uninitialized variables, except for uninitialized variables in strings.

    ### `2.0`

    -   Prohibits references to uninitialized variables. This includes uninitialized variables in strings.
    -   Prohibits references to non-existent properties of an object.
    -   Prohibits function calls that use the syntax for calling methods.

    ### `3.0`

    -   Prohibits references to uninitialized variables. This includes uninitialized variables in strings.
    -   Prohibits references to non-existent properties of an object.
    -   Prohibits function calls that use the syntax for calling methods.
    -   Prohibit out of bounds or unresolvable array indexes.

    .EXAMPLE
    PS> Get-StrictMode
    The various values returned will be Version 1, Version 2, or Off.
    .EXAMPLE
    PS> $a = (Get-StrictMode).Version()
    This will allow the environment to be restored just by entering the commmand
    Invoke-Expression "Set-StrictMode $a" 
    .LINK
    https://github.com/tostka/verb-Text
    https://www.powershellgallery.com/packages/strictmode/2.1
    #>
    [CmdletBinding()]
    PARAM()  ; 
    $errorActionPreference = 'Stop' ; 
    $version = '0' ; 
    try {
        $version = '3' ; 
        #V3 will catch on these
        $a = @(1) ; 
        $null -eq $a[2] | out-null ; 
        $null -eq $a['abc'] | out-null ; 
        $version = '2' ; 
        #V2 will catch this
        $z = "2 * $nil"       
        $version = '1' ; 
        #V1 will catch this.
        $z = 2 * $nil ;
        $version = 'Off' ; 
    } catch {} ; 
    $errorActionPreference = 'Continue' ; 
    New-Module -ArgumentList $version -AsCustomObject -ScriptBlock {
        param ([String]$version) ; 
        function Version() {
            if ($version -eq 'Off') {
                [String]$output = '-Off' ; 
            } else {
                [String]$output = "-Version $version" ; 
            } ; 
            #(Get-StrictMode).Version() ; 
            "$output" | write-output ;
        } ; 
        function ToString() {
            if ($version -ne 'Off') {
              $version = "Version $version" ; 
            } ; 
            #Get-StrictMode will output string.
            "StrictMode: $version" | write-output  ;
        }  ; 
        Export-ModuleMember -function Version,ToString  ; 
    }  ; 
} ; 
#*------^ get-StrictMode.ps1 ^------
