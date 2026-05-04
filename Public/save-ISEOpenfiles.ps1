# save-ISEOpenfiles.ps1

#region SAVE_ISEOPENFILES ; #*------v save-ISEOpenfiles v------
Function save-ISEOpenfiles {
    <#
    .SYNOPSIS
    save-ISEOpenfiles - Save all open tabs in ISE
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : save-ISEOpenfiles.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : jdhitsolutions
    AddedWebsite: https://github.com/jdhitsolutions/ISEScriptingGeek/
    AddedTwitter: URL
    REVISIONS
    * 1:12 PM 5/4/2026 added demo mnu add
    * 3:00 PM 4/14/2026 the presave portion of close-iseopenfiles
    .DESCRIPTION
    save-ISEOpenfiles - Save all open tabs in ISE
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    .EXAMPLE
    PS> save-ISEOpenfiles
    EXSAMPLEOUTPUT
    Run with whatif & verbose
    .EXAMPLE
    # updated, precheck existing before blindly adding
    PS> if ((gcm save-ISEOpenfiles --ea 0) -AND -not($psISE.CurrentPowerShellTab.AddOnsMenu.Submenus | Where-Object { $_.DisplayName -eq "Save All" })){
    PS>    $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Save All",{save-ISEOpenfiles},"Ctrl+Shift+S")
    PS> } ; 
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://github.com/jdhitsolutions/ISEScriptingGeek/
    #>
    [CmdletBinding()]
    Param(
        #[Parameter(HelpMessage="Force (Confirm-override switch[-force]")]
        #    [switch]$Force
    )
    if ($psISE) {    
        $smsg = "Saving all previously saved Tabs in ISE" ;
        write-host -foregroundcolor yellow $smsg ; 
        #$unsaved = $psISE.CurrentPowerShellTab.Files.Where( { -not $_.isSaved })
        #$saved = $psISE.CurrentPowerShellTab.Files.Where( { $_.isSaved })
        $psISE.CurrentPowerShellTab.Files | Where-Object { -not $_.IsSaved -and -not $_.IsUntitled } | 
            ForEach-Object { write-host "saving:$($_.fullpath)..." ; $_.Save() }        
    } else {
        Write-Warning 'This function requires the Windows PowerShell ISE.'
    }
} 
#endregion SAVE_ISEOPENFILES ; #*------^ END save-ISEOpenfiles ^------