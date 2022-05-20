#*------v export-ISEBreakPointsALL.ps1 v------
function export-ISEBreakPointsALL {
    <#
    .SYNOPSIS
    export-ISEBreakPointsALL - Loop open tabs in ISE, and foreach: Export all 'Line' ise breakpoints to XML file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : export-ISEBreakPointsALL
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 9:19 AM 5/20/2022 add: eIseBpAll alias (using these a lot lately)
    * 12:14 PM 5/11/2022 init
    .DESCRIPTION
    export-ISEBreakPointsALL - Loop open tabs in ISE, and foreach: Export all 'Line' ise breakpoints to XML file
    Quick bulk dump, when ISE ineveitbly stops properly echo'ing variable values to terminal (and need to close and re-open all open files, with BPs intact)
    By default, attempts to save to the same directory as the script, but if the directory specified doesn't exist, it redirects the save to the c:\scripts dir.
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    export-ISEBreakPointsALL -verbose -whatif
    Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('eIseBpAll')]
    PARAM(
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ; 
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
    }
    PROCESS {
        if ($psise){
            write-host "Exporting PSBreakPoints for ALL TABS of currently open ISE"
            $allISEScripts = $psise.powershelltabs.files.fullpath ;
            foreach($ISES in $allISEScripts){
                $sBnrS="`n#*------v PROCESSING : $($ISES) v------" ; 
                write-host -foregroundcolor white "$((get-date).ToString('HH:mm:ss')):$($sBnrS)" ;
                write-host "==exporting $($ISES):" ;
                $pltEISEBP=@{Script= $ISES ;whatif=$($whatif) ;verbose=$($verbose) ; } ;
                $smsg  = "export-ISEBreakPoints w`n$(($pltEISEBP|out-string).trim())" ;
                write-verbose $smsg ;
                export-ISEBreakPoints @pltEISEBP ;
                write-host -foregroundcolor white "$((get-date).ToString('HH:mm:ss')):$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            } ;
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}
#*------^ export-ISEBreakPointsALL.ps1 ^------