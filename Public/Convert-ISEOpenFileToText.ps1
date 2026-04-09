# Convert-ISEOpenFileToText.ps1

Function Convert-ISEOpenFileToText {
    <#
    .SYNOPSIS
    Convert-ISEOpenFileToText.ps1 - Save current tab file to .txt extension
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : Convert-ISEOpenFileToText.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : jdhitsolutions
    AddedWebsite: https://github.com/jdhitsolutions/ISEScriptingGeek/
    AddedTwitter: URL
    REVISIONS
    * 10:13 AM 4/9/2026 init
    * Jul 3, 2023 jdh posted vers
    .DESCRIPTION
    Convert-ISEOpenFileToText.ps1 - Save current tab file to .txt extension
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    System.Boolean
    .EXAMPLE
    PS> Convert-ISEOpenFileToText
    EXSAMPLEOUTPUT
    Run with whatif & verbose
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://github.com/jdhitsolutions/ISEScriptingGeek/    #>
    [CmdletBinding()]
    Param (
        [Switch]$Reload
    )
    #verify we are in the ISE
    if ($psISE) {        
        #get the current file name and path and change the extension
        $PSVersion = $psISE.CurrentFile.FullPath
        $textVersion = $PSVersion -replace '.ps1', '-ps1.txt'
        #save the file.
        $psISE.CurrentFile.SaveAs($textVersion)
        #if -Reload then reload the PowerShell file into the ISE
        if ($Reload) {
            $psISE.CurrentPowerShellTab.Files.Add($PSVersion)
        }
    } #if $psISE
    else {
        Write-Warning 'This function requires the Windows PowerShell ISE.'
    }
} #end function