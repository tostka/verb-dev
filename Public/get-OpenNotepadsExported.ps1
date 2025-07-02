
#*------v get-OpenNotepadsExported v------
function get-OpenNotepadsExported {
    <#
    .SYNOPSIS
    get-OpenNotepadsExported - List CU profile .\Documents\WindowsPowerShell\Scripts\data\NotePdSavedSession*.psXML files, reflecting prior exports via export-OpenNotepads, as targets for import via import-OpenNotepads
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : get-OpenNotepadsExported.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 1:46 PM 7/2/2025 init, works
    .DESCRIPTION
    get-OpenNotepadsExported - List CU profile .\Documents\WindowsPowerShell\Scripts\data\NotePdSavedSession*.psXML files, reflecting prior exports via export-OpenNotepads, as targets for import via import-OpenNotepads

    Returns list of string filepaths to pipeline, for further filtering, and passage to import-OpenNotepads
    .PARAMETER Tag
    Optional Tag to apply to as filename suffix[-tag 'label']
    .EXAMPLE
    PS> get-OpenNotepadsExported -verbose
    Find any pre-existing exported ISESavedSession*.psXML files (those exported via export-OpenNotepads)
    .EXAMPLE
    PS> get-OpenNotepadsExported -Tag MFA -verbose  
    Find any pre-existing exported ISESavedSession*MFA*.psXML files (those exported with -Tag MFA)
    .EXAMPLE
    PS> get-OpenNotepadsExported -Tag MFA | import-OpenNotepads ; 
    Example pipelining the outputs into import-OpenNotepads() (via pipeline support for it's -FilePath param)
    .EXAMPLE
    PS> get-OpenNotepadsExported | %{gci $_} | sort LastWriteTime | ft -a fullname,lastwritetime ; 
    Example finding the 'latest' (newest LastWritTime) and echoing for review
    .EXAMPLE
    get-OpenNotepadsExported | %{gci $_} | sort LastWriteTime | select -last 1 | select -expand fullname | import-OpenNotepads ; 
    Example finding the 'latest' (newest LastWritTime), and then importing into ISE.
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('gIseOpen')]
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
        
        #$AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;
        $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
        # CREATE new WindowsPowershell\Scripts\data folder if nonexist, use it to park data .xml & jsons etc for script processing/output (should prob shift the ise export/import code to use it)
        $npExpDir = join-path -path $CUScripts -ChildPath 'data' ;
        if(-not(test-path $npExpDir)){
            mkdir $npExpDir -verbose ;
        }

        if($Tag){
            $txmlf = join-path -path $npExpDir -ChildPath "NotePdSavedSession-$($Tag)*.psXML" ;
        } else {
            $txmlf = join-path -path $npExpDir -ChildPath "NotePdSavedSession-*.psXML" ;
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
        
    } # PROC-E
    END{
        $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    }
}
#*------^ get-OpenNotepadsExported ^------
