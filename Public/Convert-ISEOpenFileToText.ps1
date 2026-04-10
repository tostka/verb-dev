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
    * 9:30 AM 4/10/2026 added traytip/msgbox notif of the update
    * 10:13 AM 4/9/2026 init
    * Jul 3, 2023 jdh posted vers
    .DESCRIPTION
    Convert-ISEOpenFileToText.ps1 - Save current tab file to .txt extension
    .PARAMETER Reload
    Switch to reload the original .ps1 file (vs leave .txt copy open)[-Reload]
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
    https://github.com/jdhitsolutions/ISEScriptingGeek/    
    #>
    [CmdletBinding()]
    Param (
        [Parameter(HelpMessage="Switch to reload the original .ps1 file (vs leave .txt copy open)[-Reload]")]
            [Switch]$Reload
    )
    BEGIN{
        $TipTimeSecs = 5        
    }PROCESS{
        if ($psISE) {                    
            #get the current file name and path and change the extension
            $PSVersion = $psISE.CurrentFile.FullPath
            $textVersion = $PSVersion -replace '.ps1', '-ps1.txt'
            #save the file.
            $psISE.CurrentFile.SaveAs($textVersion)
            # traytip the update status
            $tipTitle = "ISE update";
            $tipText =  "ISE: current tab saved as .txt";
            if(gcm show-traytip -ea 0){
                 show-traytip -Type info -Text $tipText -Title $tipTitle  -ShowTime $TipTimeSecs ; 
            }elseif(gcm show-MsgBox -ea 0){
                 show-traytip -Type info -Text $tipText -Title $tipTitle  -ShowTime $TipTimeSecs ; 
                 Show-MsgBox -Prompt $tipText -Title $tipTitle -Icon Information -BoxType OkOnly
            }else{
                $shell = New-Object -ComObject WScript.Shell
                $shell.Popup($tipText, 5,  $tipTitle , 64) ; 
            }
            #if -Reload then reload the PowerShell file into the ISE
            if ($Reload) {
                $psISE.CurrentPowerShellTab.Files.Add($PSVersion)
            }
        } else {
            Write-Warning 'This function requires the Windows PowerShell ISE.'
        }
    }
    END{
        if(gcm show-traytip -ea 0){
            # Recommended: Clean up the icon after use to avoid it lingering in the tray
            Wait-Event -Timeout 5 # Optional delay
            TRY{$notification.Dispose()}CATCH{} # eat error, after tray closes
        } ; 
    }
} #end function