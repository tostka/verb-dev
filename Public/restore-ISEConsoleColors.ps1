#*------v restore-ISEConsoleColors.ps1 v------
Function restore-ISEConsoleColors {
    <#
    .SYNOPSIS
    restore-ISEConsoleColors - Restore default $psise.options from "`$(split-path $profile)\IseColorsDefault.csv" file
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
    * 12:46 PM 6/2/2022 typo: remove spurious }
    * 7:29 AM 3/17/2021 init
    .DESCRIPTION
    restore-ISEConsoleColors - Restore default $psise.options from "`$(split-path $profile)\IseColorsDefault.csv" file
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    restore-ISEConsoleColors;
    .LINK
    https://github.com/tostka/verb-IO
    #>
    
    [CmdletBinding()]
    Param() 
    $verbose = ($VerbosePreference -eq "Continue") ; 
    switch($host.name){
        "Windows PowerShell ISE Host" {
            ##$psISE.Options.RestoreDefaultTokenColors()
            <#$sFileTag=Read-Host "Enter 'Name' for saved color scheme" ;
            $ofile = "$(split-path $profile)\IseColors-$($sFileTag).csv" ; 
            write-host -fore green "Saving current Colors & Fonts to file: $($ofile)" ; 
            $psise.options | Select ConsolePane*,Font* | Export-CSV "$($ofile)" ;
            #>
            $ifile = "$(split-path $profile)\IseColorsDefault.csv" ; 
            if(test-path $ifile){
                (import-csv $ifile ).psobject.properties | foreach { $psise.options.$($_.name) = $_.Value} ; 
            } else { 
                throw "Missing $($ifile), skipping restore-ISEConsoleColors.ps1`nCan be created via:`n`$psise.options | Select ConsolePane*,Font* | Export-CSV '`$(split-path $profile)\IseColorsDefault.csv'"
            } ;
        } 
        "ConsoleHost" {
            #[console]::ResetColor()  # reset console colorscheme to default
            throw "This command is intended to backup ISE (`$psie.options object). PS `$host is not supported" ; 
        }
        default {
            write-warning "Unrecognized `$Host.name:$($Host.name), skipping $($MyInvocation.MyCommand.Name)" ; 
        } ; 
    } ; 
}
#*------^ restore-ISEConsoleColors.ps1 ^------
