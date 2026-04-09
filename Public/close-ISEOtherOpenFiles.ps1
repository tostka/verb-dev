# close-ISEOtherOpenFiles.ps1

#close all other saved files except for the active file
Function close-ISEOtherOpenFiles.ps1 {
     <#
    .SYNOPSIS
    close-ISEOtherOpenFiles - Close all _saved_ open tabs in ISE, other than Current Tab\File
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : close-ISEOtherOpenFiles.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : jdhitsolutions
    AddedWebsite: https://github.com/jdhitsolutions/ISEScriptingGeek/
    AddedTwitter: URL
    REVISIONS
    * 12:15 PM 4/9/2026 added -force;init, added psie check
    * Jul 3, 2023 jdh posted vers
    .DESCRIPTION
    close-ISEOtherOpenFiles - Close all _saved_ open tabs in ISE, other than Current Tab\File
    .PARAMETER Force
    Bypasses prompt
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    System.Boolean
    .EXAMPLE
    PS> close-ISEOtherOpenFiles
    EXSAMPLEOUTPUT
    Run with whatif & verbose
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://github.com/jdhitsolutions/ISEScriptingGeek/
    #>
    [CmdletBinding()]
    Param(
        [Parameter(HelpMessage="Force (Confirm-override switch[-force]")]
            [switch]$Force
    )
    if ($psISE) {
        $smsg = "Closing all OTHER Tabs in this ISE!" ;
        write-warning $smsg ;
        if(-not $Force){ 
            $bRet=Read-Host "Enter YYY to continue. Anything else will exit"  ;
            if ($bRet.ToUpper() -eq "YYY") {
                $smsg = "(Moving on)" ;
                write-host -foregroundcolor green $smsg  ;
            } else {
                $smsg = "(*skip* use of -NoFunc)" ;
                write-host -foregroundcolor yellow $smsg  ;
                return; # return (exits script or function); break (exits loop/switch) ; exit 1 (terms context,can close ps)
            } ; 
        }
        $saved = $psISE.CurrentPowerShellTab.Files.Where( { $_.isSaved -AND $_.FullPath -ne $psISE.CurrentFile.FullPath })
        foreach ($file in $saved) {
            Write-Verbose "closing $($file.FullPath)"
            [void]$psISE.CurrentPowerShellTab.files.Remove($file)
        }
     } else {
        Write-Warning 'This function requires the Windows PowerShell ISE.'
    }
} #end function