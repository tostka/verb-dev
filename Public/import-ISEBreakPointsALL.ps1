#*------v import-ISEBreakPointsALL.ps1 v------
function import-ISEBreakPointsALL {
    <#
    .SYNOPSIS
    import-ISEBreakPointsALL - Loop open tabs in ISE, and foreach: Import all 'Line' ise breakpoints from assoc'd XML file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : import-ISEBreakPointsALL
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 12:16 PM 5/11/2022 init
    .DESCRIPTION
    import-ISEBreakPointsALL - Loop open tabs in ISE, and foreach: Import all 'Line' ise breakpoints from assoc'd XML file
    Quick bulk import, when ISE ineveitbly stops properly echo'ing variable values to terminal (and need to close and re-open all open files, with BPs intact)
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    import-ISEBreakPointsALL -verbose -whatif
    Export all 'line'-type breakpoints for all current open ISE tabs, to matching xml files, with verbose & whatif
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    #[Alias('eIseBp')]
    PARAM(
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue") ;
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
                write-host "==importing $($ISES):" ;
                $pltEISEBP=@{Script= $ISES ;whatif=$($whatif) ;verbose=$($verbose) ; } ;
                $smsg  = "import-ISEBreakPoints w`n$(($pltEISEBP|out-string).trim())" ;
                write-verbose $smsg ;
                import-ISEBreakPoints @pltEISEBP ;
                write-host -foregroundcolor white "$((get-date).ToString('HH:mm:ss')):$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            } ;
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}
#*------^ import-ISEBreakPointsALL.ps1 ^------