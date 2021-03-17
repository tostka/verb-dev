#*------v save-ISEConsoleColors.ps1 v------
Function save-ISEConsoleColors {
    <#
    .SYNOPSIS
    save-ISEConsoleColors - Save $psise.options | Select ConsolePane*,Font* to prompted csv file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-03-17
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Copyright   : 
    Github      : https://github.com/tostka
    Tags        : Powershell,ExchangeOnline,Exchange,RemotePowershell,Connection,MFA
    REVISIONS   :
    * 1:25 PM 3/5/2021 init ; added support for both ISE & powershell console
    .DESCRIPTION
    save-ISEConsoleColors - Save $psise.options | Select ConsolePane*,Font* to prompted csv file
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    save-ISEConsoleColors;
    .LINK
    https://github.com/tostka/verb-IO
    #>
    [CmdletBinding()]
    #[Alias('dxo')]
    Param() 
    $verbose = ($VerbosePreference -eq "Continue") ; 
        switch($host.name){
            "Windows PowerShell ISE Host" {
                ##$psISE.Options.RestoreDefaultTokenColors()
                $sFileTag=Read-Host "Enter 'Name' for saved color scheme" ;
                $ofile = "$(split-path $profile)\IseColors-$($sFileTag).csv" ; 
                write-host -fore green "Saving current Colors & Fonts to file: $($ofile)" ; 
                $psise.options | Select ConsolePane*,Font* | Export-CSV "$($ofile)" ;
            } 
            "ConsoleHost" {
                #[console]::ResetColor()  # reset console colorscheme to default
                throw "This command is intended to backup ISE (`$psie.options object). PS `$host is not supported" ; 
            }
            default {
                write-warning "Unrecognized `$Host.name:$($Host.name), skipping save-ISEConsoleColors" ; 
            } ; 
        } ; 
    } ; 
}
#*------^ save-ISEConsoleColors.ps1 ^------
