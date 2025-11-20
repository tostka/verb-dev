# import-OpenNotepads.ps1
#*------v import-OpenNotepads.ps1 v------
function import-OpenNotepads {
    <#
    .SYNOPSIS
     import-OpenNotepads - Import & open a previously-exported list of  Notepad* variant (notepad2/3 curr) sessions
    .NOTES
    Version     : 1.0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2025-07-02
    FileName    : import-OpenNotepads.ps1
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 1:00 PM 11/20/2025 added support for edit flags (*\s), optional, as part of dupe suppress
        added dupe-suppression, both retroactively - searches launched process.mainwindowtitle for array status, closes all but oldest id - and proactively - 
        runs a collection of processname-filtered existing processes, and appends the newly opened to the list, then builds and checks for each filename in the MainWindowTitle list, skipping open dupes.
    * 2:21 PM 7/2/2025 works init
    .DESCRIPTION
    import-OpenNotepads - Import & open a previously-exported list of  Notepad* variant (notepad2/3 curr) sessions
    .PARAMETER File
    Path to an exported .psxml file reflecting previously opened Notepad* variant windows & documents, to be reopened.
    .PARAMETER Tag
    Variant to specify targeting a Tag (filename suffix - portion after the std 'NotePdSavedSession-' of filename, wo .psxml extension, which by default is a timestamp, if no export -Tag was specified)[-tag 'label']
    .EXAMPLE
    PS> import-opennotepads -File 'C:\Users\kadrits\OneDrive - The Toro Company\Documents\WindowsPowershell\Scripts\data\NotePdSavedSession-20250702-1120AM.psXML' -verbose
    Demo using a full path specification to the target import file
    .EXAMPLE
    PS> import-opennotepads -Tag '20250702-1120AM'   -verbose
    Demo targeting an exported file based on the trailing Tag suffix
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('ipNpOpen')]

    #[ValidateScript({Test-Path $_})]
    PARAM(
        [Parameter(Mandatory = $False, Position = 0, ValueFromPipeline = $True, HelpMessage = 'File paths[-path c:\pathto\file.ext]')]
            [Alias('PsPath')]
            #[ValidateScript({Test-Path $_ -PathType 'Container'})]
            #[System.IO.DirectoryInfo[]]$File,
            [ValidateScript({ Test-Path $_ })]
            [system.io.fileinfo[]]$File,
            #[string[]]$File
        [Parameter(Position=0,HelpMessage="Variant to specify targeting a Tag (filename suffix - portion after the std 'NotePdSavedSession-' of filename, wo .psxml extension, which by default is a timestamp, if no export -Tag was specified)[-tag 'label']")]
            [string]$Tag,
        [Parameter(Position=0,HelpMessage="ProcessName (as returned by get-process) for the default associated app for .txt files (defaults to notepad2, used to pre-collect existing open files for dupe suppression)[-DefaultProcessName 'notepad3']")]
            [string]$DefaultProcessName = 'notepad2'
        
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue") ;
        $prPS = 'Name', 'Id', 'Path', 'Description', 'MainWindowHandle', 'MainWindowTitle', 'ProcessName', 'StartTime', 'ExitCode', 'HasExited', 'ExitTime' ;
        $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
        # CREATE new WindowsPowershell\Scripts\data folder if nonexist, use it to park data .xml & jsons etc for script processing/output (should prob shift the ise export/import code to use it)
        $npExpDir = join-path -path $CUScripts -ChildPath 'data' ;
        if (-not(test-path $npExpDir)) {
            mkdir $npExpDir -verbose ;
        }

        if ($Tag) {
            $txmlf = join-path -path $npExpDir -ChildPath "NotePdSavedSession-$($Tag).psXML" ;
        } elseif($File) {
            if ($File -match '\\|\/'){
                write-verbose "File appears to be fully pathed (has /\ chars)"
                $txmlf = $File ;
            } ;
        }else{
            write-verbose "unpathed -File, building target default path"
            $txmlf = join-path -path $npExpDir -ChildPath $File ;
        }
        $openedProcesses = @() ; 
        $openedProcesses += (get-process -ProcessName $DefaultProcessName) ; 
        $appTag = $null ; 
    } ;
    PROCESS {
        # for debugging, -Script permits targeting another script *not* being currently debugged


            if($txmlf){
                write-host "*Importing exported file:$($txmlf) and setting specified files for open file`n$($tScript)" ;
                
                # set apps & files in found .xml file
                $ipFiles = Import-Clixml -path $txmlf ;
                
                # patch over empty existing file (file w no specs, happens)
                if($ipFiles){

                    foreach($ipFile in $ipFiles){                        
                        # $process = start-process ping.exe -windowstyle Hidden -ArgumentList "-n 1 -w 127.0.0.1" -PassThru –Wait ;
                        # $process.ExitCode
                        $pltSaPS = [ordered]@{
                            FilePath = $null ;
                            ArgumentList = $null ;
                            PassThru = $true
                        } ;
                        if($ipFile.Path){$pltSaPS.FilePath = $ipFile.Path }else{throw "missing FilePath!"} 
                        if($ipFile.FilePath){$pltSaPS.ArgumentList = $ipFile.FilePath }else{throw "missing notepad app Path!"}
                        if($thisfile = get-childitem -path $ipFile.FilePath -ea STOP){
                            if ($thisfile.name -eq 'Ex16-Build-ExInstall-20250707-0138PM.txt'){
                                write-verbose "gotcha!" ; 
                            } ; 
                            $filename = split-path -leaf -path $ipFile.FilePath ; 
                            #$rgxtitleString = [regex]::Escape($filename) ; 
                            $titlestring = "$($filename)$($appTag)" ; 
                            #$titlestringEdit = "* $($filename)$($appTag)" ; 
                            # cover both base filename, and optional leading *\s when editing
                            $rgxtitlestring = "^((\*\s)*)$([regex]::Escape($titlestring))" ; 
                            #if($openedProcesses.mainwindowtitle -contains $titlestring){
                            # issue: edits have '\s*\s' prefix, can't do -contains against a regex, need to loop them out and compare
                            $openedProcesses.mainwindowtitle |foreach-object{
                                    $thistitle = $_ ; 
                                    if($thistitle -match $rgxtitlestring){
                                        $smsg = "(Window already open: dupe suppress: $($titlestring))" ; 
                                        if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                                        Continue ; 
                                    } 
                                }                                
                        } ELSE { 
                            $smsg = "MISSING SPECIFIED FILE: $($ipFile.FilePath) (skipping)" ; 
                            write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" ; 
                            continue 
                        } 
                        # existing open copies have file name in MainWindowTitle: Ex16-Build-ExInstall-20250707-0138PM.txt
                        $smsg = "start-process w`n$(($pltSaPS|out-string).trim())" ; 
                        write-verbose $smsg ; 
                        TRY{
                            $process = start-process @pltSaPS ;
                            # popu apptag if unpop'd
                            if($appTag -eq $null){
                                # resolve the locally associated app's tag, based on the trailing non-filename string in the spawned mainwindowtitle.
                                $appTag = $process.mainwindowtitle -replace (split-path -leaf $ipFile.FilePath -ea STOP),'' ; 
                            } ; 
                            # remedially close dupes (1st pass will miss them, apptag is unpopulated until below)
                            $matchingprocesses = get-process -ProcessName $process.processname |?{$_.MainWindowTitle -eq $Process.MainWindowTitle} | sort id ; 
                            $edits = $matchingprocesses |?{$_.MainWindowTitle -match '$\*\s'}  | sort id ; 
                            $nonEdits = $matchingprocesses | ?{$edits.id -notcontains $_.id} ; 
                            if($matchingprocesses -is [array]){
                                if($edits){
                                    $nonEdits | stop-process -Force -Verbose:($VerbosePreference -eq 'Continue') ;
                                } else {
                                    # close all but oldest copy, sorted on highest ID ; edits will have non-matching title, as they get '*' markers
                                    write-host "Dupe MainWindowTitle found: Closing all but oldest copy: $($matchingprocesses[-1].id)" ; 
                                    $matchingprocesses | select-object -Skip 1  | stop-process -Force -Verbose:($VerbosePreference -eq 'Continue') ; 
                                } ; 
                            } else{
                                $openedProcesses += @($process) ;                                 
                            } ; 
                            
                        } CATCH {
                            $ErrTrapd=$Error[0] ;
                            $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                            write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                        } ;
                        write-verbose  "$($pltSaPS.Path ) $($pltSaPS.FilePath): $(($process.ExitCode|out-string).trim())" ;
                    } ;
                    
                    $smsg = "$(($ipFile|measure).count) Files restored per $($txmlf)`n$(($ipFiles|sort line|ft -a Path,FilePath|out-string).trim())" ;
                    if($whatif){$smsg = "-whatif:$($smsg)" }
                    write-host $smsg ;
                } else {
                    write-warning "EMPTY/Spec .xml file for reopening" ;
                }
             } else { write-warning "Missing .xml exported file for open file $($tScript)" } ;

    } # PROC-E
}
#*------^ import-OpenNotepads.ps1 ^------
