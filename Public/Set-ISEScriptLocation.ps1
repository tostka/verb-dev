# Set-ISEScriptLocation.ps1

Function Set-ISEScriptLocation {
    <#
    .SYNOPSIS
    Set-ISEScriptLocation - cd to parent directory of current File Tab
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : Set-ISEScriptLocation.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : jdhitsolutions
    AddedWebsite: https://github.com/jdhitsolutions/ISEScriptingGeek/
    AddedTwitter: URL
    REVISIONS
    * 10:13 AM 4/9/2026 init, added psie check
    * Jul 3, 2023 jdh posted vers
    .DESCRIPTION
    Set-ISEScriptLocation - cd to parent directory of current File Tab
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    System.Boolean
    .EXAMPLE
    PS> Set-ISEScriptLocation
    EXSAMPLEOUTPUT
    Run with whatif & verbose
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://github.com/jdhitsolutions/ISEScriptingGeek/
    #>
    [cmdletbinding()]
    [alias("sd")]
    Param()
    if ($psISE) {
        $path = Split-Path -Path $psISE.CurrentFile.FullPath
        set-location -path $path
        clear-host
    } else {
        Write-Warning 'This function requires the Windows PowerShell ISE.'
    }
}
