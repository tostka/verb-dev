# export-OpenNotepads.ps1

#*------v export-OpenNotepads v------
function export-OpenNotepads {
    <#
    .SYNOPSIS
    export-OpenNotepads - Export a list of all currently open Notepad* variant (notepad2/3 curr) windows, to CU \WindowsPowershell\Scripts\data\NotePdSavedSession-....psXML file (uses -Tag if specified, otherwise timestamps the file)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2025-07-02
    FileName    : export-OpenNotepads.ps1
    License     : MIT License
    Copyright   : (c) 2025 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 1:53 PM 7/2/2025 converted to func;  init
    .DESCRIPTION
    export-OpenNotepads - Export a list of all currently open Notepad* variant (notepad2/3 curr) windows, to CU \WindowsPowershell\Scripts\data\NotePdSavedSession-....

    Goal is to quickest productive work state after a reboot (get all the open files back open for continued review and work)

    Exports are in psXML files (xml) to the 'CurrentUserProfile\WindowsPowershell\Scripts\data\' directory:

    - If a -Tag is specified, the exported summary is named  'NotePdSavedSession-$($Tag).psXML'

    - If NO -Tag is specified, the exported summary is named with a timestamp in form: NotePdSavedSession-yyyyMMdd-HHmmtt.psXML

    .PARAMETER Tag
    Optional Tag to apply to as filename suffix (otherwise appends a timestamp)[-tag 'label']
    .PARAMETER rgxExclTitles
    Regex filter reflecting window MainWindowTitle strings to be excluded from exports (defaults to a stock filter)[-rgxExclTitles '^((\*\s)*)(Untitled|input\.txt|tmp\.ps1|tmpL\.ps1)\s-\s']
    .PARAMETER rgxNPAppNames
    Regex filter reflecting window MainWindowTitle Notepad* variant suffix strings to be targeted for exports (defaults to a stock filter)[rgxNPAppNames '\s-\s(Notepad\s2e\sx64|Notepad3)']
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    PS> export-OpenNotepads -verbose -whatif
    Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif
    .EXAMPLE
    PS> export-OpenNotepads -Tag 'mfa' -verbose -whatif
    Export with Tag 'mfa' applied to filename (e.g. "ISESavedSession-MFA.psXML")
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('epNpOpen')]
    PARAM(
        [Parameter(Position=0,HelpMessage="Optional Tag to apply to as filename suffix (otherwise appends a timestamp)[-tag 'label']")]
            [string]$Tag,
        [Parameter(HelpMessage="Regex filter reflecting window MainWindowTitle strings to be excluded from exports (defaults to a stock filter)[-rgxExclTitles '^((\*\s)*)(Untitled|input\.txt|tmp\.ps1|tmpL\.ps1)\s-\s']")]
            [regex]$rgxExclTitles =  '^((\*\s)*)(Untitled|input\.txt|tmp\.ps1|tmpL\.ps1)\s-\s',
        [Parameter(HelpMessage="Regex filter reflecting window MainWindowTitle Notepad* variant suffix strings to be targeted for exports (defaults to a stock filter)[rgxNPAppNames '\s-\s(Notepad\s2e\sx64|Notepad3)']")]
            [regex]$rgxNPAppNames = "\s-\s(Notepad\s2e\sx64|Notepad3)",
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
            [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
        $prPS = 'Name', 'Id', 'Path', 'Description', 'MainWindowHandle', 'MainWindowTitle', 'ProcessName', 'StartTime', 'ExitCode', 'HasExited', 'ExitTime' ;
        #$rgxExclTitles =  '^((\*\s)*)(Untitled|input\.txt|tmp\.ps1|tmpL\.ps1)\s-\s';
        #$rgxNPAppNames = "\s-\s(Notepad\s2e\sx64|Notepad3)"

        [string[]]$chkpaths = @() ;
        $chkpaths += @('c:\usr\work\incid\','c:\usr\work\ps\scripts\','c:\usr\work\exch\scripts\','C:\usr\work\o365\scripts\')
        $chkpaths += @($(resolve-path c:\sc\verb-*\public))

        $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
        # CREATE new WindowsPowershell\Scripts\data folder if nonexist, use it to park data .xml & jsons etc for script processing/output (should prob shift the ise export/import code to use it)
        $npExpDir = join-path -path $CUScripts -ChildPath 'data' ;
        if(-not(test-path $npExpDir)){
            mkdir $npExpDir -verbose ;
        }

        if($Tag){
            $txmlf = join-path -path $npExpDir -ChildPath "NotePdSavedSession-$($Tag).psXML" ;
        } else {
            $txmlf = join-path -path $npExpDir -ChildPath "NotePdSavedSession-$(get-date -format 'yyyyMMdd-HHmmtt').psXML" ;
        } ;
    } # BEG-E
    PROCESS {

        $npProc = get-process notepad* | ? { $_.MainWindowTitle -notmatch $rgxExclTitles } | select $prPS ;


        $npExports = @() ;
        $prcd = 0 ;
        $ttl = $npProc |  measure | select -expand count ;
        foreach ($npp in $npProc) {
            $prcd++ ;
            write-verbose "Processing:($($prcd)/$($ttl)):$($npp.MainWindowHandle)"
            $fname = $null ;
            $fsummary = [ordered]@{
                Name             = $null ;
                Id               = $null ;
                Path             = $null ;
                Description      = $null ;
                MainWindowHandle = $null ;
                MainWindowTitle  = $null ;
                ProcessName      = $null ;
                StartTime        = $null ;
                ExitCode         = $null ;
                HasExited        = $null ;
                ExitTime         = $null ;
                FilePath         = $null ;
                Resolved         = $false ;
                NPAppPath        = $null ;
            }
            if ($fname =[regex]::match($npp.MainWindowTitle,"^((\*\s)*)[\w\-. ]+(?=(\s-\sNotepad\s2e\sx64|\s-\sNotepad3))").groups[0].value){
                $chkpaths |%{
                    $testpath = (join-path $_ $fname);
                    if($hit = gci -path $testpath -ea 0){
                        write-verbose "HIT:$($testpath)"
                        $fsummary.Name = $npp.Name ;
                        $fsummary.Id               = $npp.Id ;
                        $fsummary.Path             = $npp.Path ;
                        $fsummary.Description      = $npp.Description ;
                        $fsummary.MainWindowHandle = $npp.MainWindowHandle ;
                        $fsummary.MainWindowTitle  = $npp.MainWindowTitle ;
                        $fsummary.ProcessName      = $npp.ProcessName ;
                        $fsummary.StartTime        = $npp.StartTime ;
                        $fsummary.ExitCode         = $npp.ExitCode ;
                        $fsummary.HasExited        = $npp.HasExited ;
                        $fsummary.ExitTime         = $npp.ExitTime ;
                        $fsummary.FilePath         = $hit.fullname ;
                        $fsummary.Resolved         = $true ;
                        $fsummary.NPAppPath        = $npp.Path ;
                        #break
                        $npExports += [PSCustomObject]$fsummary
                    } else {
                        write-verbose "no hit:$($testpath)"
                    }
                } ;
                #$hit ;
            } else {
                $smsg = "Unable to resolve a usable filename from:" ;
                $smsg += "`n$(($npp | ft -a |out-string).trim())" ;
                write-warning $smsg ;
            }
        } ; # loop-E
    } #  # PROC-E
    END{
        if ($npExports ){
            $smsg = "Exporting $(($npExports|measure).count) Open Notepad* session summaries to:`n"
            $smsg += "`n$($txmlf)" ;
            write-host -foregroundcolor green $smsg ;
            $npExports | sort StartTime | Export-Clixml -Path $txmlf -whatif:$($whatif);

        }else{
            write-warning "No matched notepad* file-related matches completed. `nSkipping exports"
        };
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}
#*------^ export-OpenNotepads ^------