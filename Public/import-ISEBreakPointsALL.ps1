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
    * 1:21 PM 2/28/2024 add ipbpAll alias
    * 12:23 PM 5/23/2022 added try/catch: failed out hard on Untitled.ps1's
    * 9:19 AM 5/20/2022 add: iIseBpAll alias (using these a lot lately; w freq crashouts of ise, and need to recover all files open & BPs to quickly get back to function)
    * 1:58 PM 5/16/2022 rem'd whatif (not supported in child func)
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
    [Alias('iIseBpAll','ipbpAll')]
    PARAM(
        #[Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        #[switch] $whatIf
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
                $pltEISEBP=@{Script= $ISES ;verbose=$($verbose) ; } ; # whatif=$($whatif) ;
                $smsg  = "import-ISEBreakPoints w`n$(($pltEISEBP|out-string).trim())" ;
                write-verbose $smsg ;
                try{
                    import-ISEBreakPoints @pltEISEBP ;
                } catch {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    CONTINUE ; 
                } ; 
                write-host -foregroundcolor white "$((get-date).ToString('HH:mm:ss')):$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            } ;
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    } ;
}
#*------^ import-ISEBreakPointsALL.ps1 ^------
