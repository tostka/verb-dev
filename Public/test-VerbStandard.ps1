# test-VerbStandard.ps1 

# #*------v test-VerbStandard.ps1 v------
Function test-VerbStandard {
    <#
    .SYNOPSIS
    test-VerbStandard.ps1 - Test specified verb for presense in the PS get-verb list.
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-01-20
    FileName    : test-VerbStandard.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,verbs
    REVISION
    * 3:00 PM 7/20/2022 init
    .DESCRIPTION
    test-VerbStandard.ps1 - Test specified verb for presense in the PS get-verb list.
    .PARAMETER Verb
    Verb string to be tested[-verb report]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    Boolean
    .EXAMPLE
    'New' | test-VerbStandard ;
    Test the string as a standard verb
    .EXAMPLE
    gcm -mod verb-io | ? commandType -eq 'Function' | select -expand verb -unique | test-verbstandard -verbo
    Collect all unique verbs for functions in the verb-io module, and test against MS verb standard
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('test-verb')]
    [OutputType([boolean])]
    PARAM (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Verb string to be tested[-verb report]")]
        [string] $Verb
    ) ;
    BEGIN {
        $verbose = ($VerbosePreference -eq "Continue") ; 
    } ;
    PROCESS {
        foreach($item in $verb){
            write-verbose "(checking: $($item))" ; 
            [boolean]((Get-Verb).Verb -match $item) | write-output ;
        } ; 
    } ;  # PROC-E
    END {} ; # END-E
}
#*------^ test-VerbStandard.ps1 ^------
