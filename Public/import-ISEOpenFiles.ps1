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
    * 9:06 PM 8/12/2025 added code to create CUScripts if missing
    * 8:30 AM 3/26/2024 chg iIseOpen -> ipIseOpen
    * 3:31 PM 1/17/2024 typo fix: lacking $ on () (dumping $ISES obj into pipeline/console)
    * 1:20 PM 3/27/2023 bugfix: coerce $txmlf into [system.io.fileinfo], to make it match $fileinfo's type.
    * 9:35 AM 3/8/2023 added -filepath (with pipeline support), explicit pathed file support (to pipeline in from get-IseOpenFilesExported()).
    * 3:28 PM 6/23/2022 add -Tag param to permit running interger-suffixed variants (ie. mult ise sessions open & stored from same desktop). 
    * 9:19 AM 5/20/2022 add: iIseOpen alias (using these a lot lately; w freq crashouts of ise, and need to recover all files open & BPs to quickly get back to function)
    * 12:12 PM 5/11/2022 init
    .DESCRIPTION
    import-ISEOpenFiles - Import/Re-Open a list of all ISE tab files, from CU Documents\WindowsPowershell\Scripts\ISESavedSession.psXML file
    Quick bulk dump, when ISE ineveitbly stops properly echo'ing variable values to terminal (and need to close and re-open all open files)
    .PARAMETER Tag
    Optional Tag to apply to as filename suffix[-tag 'label']
    .PARAMETER FilePath
    Optional FullName path to prior export-ISEOpenFiles pass[-FilePath `$env:userprofile\Documents\WindowsPowershell\Scripts\ISESavedSession-DEV.psXML
    .EXAMPLE
    PS> import-ISEOpenFiles -verbose
    Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif
    .EXAMPLE
    PS> import-ISEOpenFiles -Tag 2 -verbose  
    Export with Tag '2' applied to filename (e.g. "ISESavedSession2.psXML")
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('ipIseOpen')]
    PARAM(
        [Parameter(Position=0,HelpMessage="Optional Tag to apply to filename[-Tag MFA]")]
        [string]$Tag,
        [Parameter(ValueFromPipeline = $True, HelpMessage="Optional FullName path to prior export-ISEOpenFiles pass[-FilePath `$env:userprofile\Documents\WindowsPowershell\Scripts\ISESavedSession-DEV.psXML]")]
        [system.io.fileinfo[]]$FilePath 
    ) ;

    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
    }
    PROCESS {
        if ($psise){
            if(-not $FilePath){
                #$AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;
                $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
                if(-not (test-path $cuscripts)){mkdir $CUScripts -verbose } ; 
                if($Tag){
                    [array]$txmlf = @( [system.io.fileinfo](join-path -path $CUScripts -ChildPath "ISESavedSession-$($Tag).psXML") ) ;
                } else { 
                    [array]$txmlf = @( [system.io.fileinfo](join-path -path $CUScripts -ChildPath 'ISESavedSession.psXML') ) ;
                } ; 
                #$allISEScripts = $psise.powershelltabs.files.fullpath ;
            } else { 
                foreach($item in $FilePath){
                    [array]$txmlf = @() ; 
                    if($txmlf += @(get-childitem -path $item.fullname -ea continue)){
                        $smsg = "(found specified -FilePath file)" ; 
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    } else { 
                        $smsg = "Unable to locate specified -FilePath:" ; 
                        $smsg += "`n$($item.fullname)" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    } ; 
                } ; 
            } ; 
            $error.clear() ;
            TRY {
                foreach($file in $txmlf){
                    $smsg = "==$($file.fullname)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    $allISEScripts = import-Clixml -Path $file.fullname ;
                    $smsg = "Opening $($allISEScripts| measure | select -expand count) files" ; 
                    write-verbose $smsg ; 
                    if($allISEScripts){
                        foreach($ISES in $allISEScripts){
                            if($psise.powershelltabs.files.fullpath -contains $ISES){
                                write-host "$($ISES) is already OPEN in Current ISE tab list (skipping)" ;
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
                        }; # loop-E
                    } ; 
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                write-warning $smsg ;
                $smsg = $ErrTrapd.Exception.Message ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }
                else{ write-WARNING $smsg } ;
                BREAK ;
                Continue ; #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}

#*------^ import-ISEOpenFiles.ps1 ^------