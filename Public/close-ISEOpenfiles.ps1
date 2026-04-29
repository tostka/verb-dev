# close-ISEOpenfiles.ps1

Function close-ISEOpenfiles {
    <#
    .SYNOPSIS
    close-ISEOpenfiles - Close all _saved_ open tabs in ISE
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : close-ISEOpenfiles.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : jdhitsolutions
    AddedWebsite: https://github.com/jdhitsolutions/ISEScriptingGeek/
    AddedTwitter: URL
    REVISIONS
    * 3:03 PM 4/29/2026 added -path, optional fullname spec for tabs to target (vs all tabs)
    * 12:15 PM 4/9/2026 added -force; init, added psie check
    * Jul 3, 2023 jdh posted vers
    .DESCRIPTION
    close-ISEOpenfiles - Close all _saved_ open tabs in ISE
    .PARAMETER Force
    Bypasses prompt
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    System.Boolean
    .EXAMPLE
    PS> close-ISEOpenfiles
    EXSAMPLEOUTPUT
    Run with whatif & verbose
    .EXAMPLE
    PS> write-verbose 'dump listing of fullpath of all open tabs, from which to pick -Path array targets' ; 
    PS> show-ISEOpenTabPaths | sort | ?{$_ -match '_func\.ps1'} | close-ISEOpenFiles ; 
    Demo use of the -Path spec (via pipeline) to close a list/subset of open files
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://github.com/jdhitsolutions/ISEScriptingGeek/
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(HelpMessage="Force (Confirm-override switch[-force]")]
            [switch]$Force,
        [Parameter(ValueFromPipeline=$true,HelpMessage="Optional Path to filter against the ISE .files Fullname string (for direct ISE console use)[-Path ' D:\scripts\show-ISEOpenTab_func.ps1']")]
            [string[]]$Path,
        [switch]$whatif
    )
    BEGIN{
        if ($psISE) {
            $smsg = "Closing all Tabs in this ISE!" ;
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
            } ; 
            $saved = $psISE.CurrentPowerShellTab.Files.Where( { $_.isSaved })
        } else {
            Write-Warning 'This function requires the Windows PowerShell ISE.'
            return  ; 
        }
        $aggpath = @() ; 
    }
    PROCESS{
        $aggPath += $path ; 
    }
    END{
        #$saved = $saved | ?{$Path -contains $_.Fullpath  } ; 
        if($aggPath){
            $saved = $saved | ?{$aggPath -contains $_.Fullpath  } ;
        }  ; 
        foreach ($file in $saved) {
            Write-Verbose "closing $($file.FullPath)"
            if(-not $whatif){
                [void]$psISE.CurrentPowerShellTab.files.Remove($file)
            }else{
                write-host "-whatif:`$psISE.CurrentPowerShellTab.files.Remove($($file.fullpath))" ; 
            } ; 
        }   
    } ;      
} #end function