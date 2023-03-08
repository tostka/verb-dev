﻿
#*------v get-ISEOpenFilesExported v------
function get-ISEOpenFilesExported {
    <#
    .SYNOPSIS
    get-ISEOpenFilesExported - List CU profile .\Documents\WindowsPowerShell\Scripts\*.psXML files, reflecting prior exports via export-ISEOpenFiles, as targets for import via import-ISEOpenFiles
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : get-ISEOpenFilesExported.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 8:51 AM 3/8/2023 init
    .DESCRIPTION
    get-ISEOpenFilesExported - List CU profile .\Documents\WindowsPowerShell\Scripts\*.psXML files, reflecting prior exports via export-ISEOpenFiles, as targets for import via import-ISEOpenFiles
    Returns list of string filepaths to pipeline, for further filtering, and passage to import-ISEOpenFiles
    .PARAMETER Tag
    Optional Tag to apply to as filename suffix[-tag 'label']
    .EXAMPLE
    PS> get-ISEOpenFilesExported -verbose
    Find any pre-existing exported ISESavedSession*.psXML files (those exported via export-ISEOpenFiles)
    .EXAMPLE
    PS> get-ISEOpenFilesExported -Tag MFA -verbose  
    Find any pre-existing exported ISESavedSession*MFA*.psXML files (those exported with -Tag MFA)
    .EXAMPLE
    PS> get-ISEOpenFilesExported -Tag MFA | import-ISEOpenFiles ; 
    Example pipelining the outputs into import-ISEOPenFiles() (via pipeline support for it's -FilePath param)
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('iIseOpen')]
    PARAM(
        [Parameter(Position=0,HelpMessage="Optional Tag to check for, within prior-export filename[-Tag MFA]")]
        [string]$Tag
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        $smsg = $sBnr ;
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    }
    PROCESS {
        if ($psise){
            #$AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;
            $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
            if($Tag){
                $txmlf = join-path -path $CUScripts -ChildPath "ISESavedSession-*$($Tag)*.psXML" ;
            } else { 
                $txmlf = join-path -path $CUScripts -ChildPath 'ISESavedSession*.psXML' ;
            } ; 
            #$allISEScripts = $psise.powershelltabs.files.fullpath ;
            $error.clear() ;
            TRY {
                
                if($hits = get-childitem -path $txmlf -ErrorAction SilentlyContinue){
                    $smsg = "(returning matched file fullnames to pipeline for ..."
                    $smsg += "`ngci $($txmlf):" ; 
                    $smsg += "`n)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    $hits | select -expand fullname ; 
                } else { 
                     $smsg = "No matches found for search..."
                    $smsg += "`ngci $($txmlf):" ; 
                    $smsg += "`n)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                write-warning $smsg ;
                Continue ; #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    }
}
#*------^ get-ISEOpenFilesExported ^------
