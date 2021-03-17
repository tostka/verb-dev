#*------v import-ISEConsoleColors.ps1 v------
Function import-ISEConsoleColors {
    <#
    .SYNOPSIS
    import-ISEConsoleColors - Import stored $psise.options from a "`$(split-path $profile)\IseColors-XXX.csv" file
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
    * 7:29 AM 3/17/2021 init
    .DESCRIPTION
    import-ISEConsoleColors - Import stored $psise.options from a "`$(split-path $profile)\IseColors-XXX.csv" file
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    import-ISEConsoleColors;
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
                #$ifile = "$(split-path $profile)\IseColorsDefault.csv" ; 
                get-childitem  "$(split-path $profile)\IseColors*.csv" | out-gridview -Title "Pick IseColors-XXX.csv file of Font/Color settings to be imported into ISE:" -passthru | foreach-object {
                    $ifile = $_.fullname ; 
                    if(test-path $ifile){
                        (import-csv $ifile ).psobject.properties | foreach { $psise.options.$($_.name) = $_.Value} ; 
                    } else { 
                        throw "Missing $($ifile), skipping import-ISEConsoleColors.ps1`nCan be created via:`n`$psise.options | Select ConsolePane*,Font* | Export-CSV '`$(split-path $profile)\IseColorsDefault.csv'"
                    } ;
                } ;
            } 
            "ConsoleHost" {
                #[console]::ResetColor()  # reset console colorscheme to default
                throw "This command is intended to import ISE settings (`$psie.options object). PS `$host is not supported" ; 
            }
            default {
                write-warning "Unrecognized `$Host.name:$($Host.name), skipping $($MyInvocation.MyCommand.Name)" ; 
            } ; 
        } ; 
    } ; 
}
#*------^ import-ISEConsoleColors.ps1 ^------
