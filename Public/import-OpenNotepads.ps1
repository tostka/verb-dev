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
    Github      : https://github.com/tostka
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
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
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
            [switch] $whatIf
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

    } ;
    PROCESS {
        # for debugging, -Script permits targeting another script *not* being currently debugged


            if($txmlf){
                write-host "*Importing exported file:$($txmlf) and setting specified files for open file`n$($tScript)" ;
                
                # set apps & files in found .xml file
                $ipFiles = Import-Clixml -path $txmlf ;

                # patch over empty existing file (file w no specs, happens)
                if($ipFiles){


                    if($whatif){
                        foreach($ipFile in $ipFiles){
                            write-host "-whatif:set-PSBreakpoint -script $($setPs1) -line $($ipFile.line)"
                        } ;
                    } else {
                        foreach($ipFile in $ipFiles){
                            #$null = set-PSBreakpoint -script $setPs1 -line $ipFile.line ;
                            # $process = start-process ping.exe -windowstyle Hidden -ArgumentList "-n 1 -w 127.0.0.1" -PassThru –Wait ;
                            # $process.ExitCode
                            $pltSaPS = [ordered]@{
                                FilePath = $null ;
                                ArgumentList = $null ;
                                PassThru = $true
                            } ;
                            if($ipFile.Path){$pltSaPS.FilePath = $ipFile.Path }else{throw "missing FilePath!"} 
                            if($ipFile.FilePath){$pltSaPS.ArgumentList = $ipFile.FilePath }else{throw "missing notepad app Path!"}
                            $smsg = "start-process w`n$(($pltSaPS|out-string).trim())" ; 
                            write-verbose $smsg ; 
                            TRY{
                                $process = start-process @pltSaPS ;
                            } CATCH {
                                $ErrTrapd=$Error[0] ;
                                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                                write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                            } ;
                            write-verbose  "$($pltSaPS.Path ) $($pltSaPS.FilePath): $(($process.ExitCode|out-string).trim())" ;
                        } ;
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
