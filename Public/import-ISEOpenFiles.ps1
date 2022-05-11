#*------v import-ISEOpenFiles.ps1 v------
function import-ISEOpenFiles {
    <#
    .SYNOPSIS
    import-ISEOpenFiles - Import/Re-Open a list of all ISE tab files, from CU Documents\WindowsPowershell\Scripts\ISESavedSession.psXML file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : import-ISEOpenFiles
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 12:12 PM 5/11/2022 init
    .DESCRIPTION
    import-ISEOpenFiles - Import/Re-Open a list of all ISE tab files, from CU Documents\WindowsPowershell\Scripts\ISESavedSession.psXML file
    Quick bulk dump, when ISE ineveitbly stops properly echo'ing variable values to terminal (and need to close and re-open all open files)
    .EXAMPLE
    import-ISEOpenFiles -verbose
    Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    #[Alias('eIseBp')]
    PARAM() ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
    }
    PROCESS {
        if ($psise){
            #$AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;
            $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
            $txmlf = join-path -path $CUScripts -ChildPath 'ISESavedSession.psXML' ;
            #$allISEScripts = $psise.powershelltabs.files.fullpath ;
            $error.clear() ;
            TRY {
                $allISEScripts = import-Clixml -Path $txmlf ;
                if($tTabs){
                    #if($psise.powershelltabs.files.count -eq 1){
                    foreach($ISES in $allISEScripts){
                        if($psise.powershelltabs.files.fullpath -contains $ISES){
                            write-host "($ISES) is already OPEN in Current ISE tab list (skipping)" ; 
                        } else { 
                            if(test-path $ISES){
                                <# #New tab & open in new tab: - no we want them all in one tab
                                write-verbose "(adding tab, opening:$($ISES))"
                                $tab = $psISE.PowerShellTabs.Add() ;
                                $tab.Files.Add($ISES) ;
                                #>
                                #open in current tab
                                write-verbose "(opening:$($ISES))"
                                $psISE.CurrentPowerShellTab.Files.Add($ISES) ;  ; 
                            } else {  write-warning "Unable to Open missing orig file:`n$($ISES)" };
                        } ; 
                    }; 
                }
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                write-warning $smsg ;
                Continue ; #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}
#*------^ import-ISEOpenFiles.ps1 ^------