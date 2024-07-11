# get-ISEBreakPoints.ps1 

#*------v get-ISEBreakPoints.ps1 v------
function get-ISEBreakPoints {
    <#
    .SYNOPSIS
    get-ISEBreakPoints - Get-PSBreakPoints for solely the current focused ISE Open Tab
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2024-07-11
    FileName    : get-ISEBreakPoints
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 2:27 PM 7/11/2024 init
    .DESCRIPTION
    get-ISEBreakPoints - Get-PSBreakPoints for solely the current focused ISE Open Tab (fltered on -script param)
    .EXAMPLE
    PS> get-isebreakpoints | ft -a ; 

        ID Script                        Line Command Variable Action
        -- ------                        ---- ------- -------- ------
        70 test-ExoDnsRecordTDO_func.ps1  237                        
        71 test-ExoDnsRecordTDO_func.ps1  256                        
        ...                       

    Export all 'line'-type breakpoints on the current open ISE tab, to a matching xml file
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('gIseBp')]
    PARAM() ;
    PROCESS {
        if ($psise){
            if($psise.CurrentFile.FullPath){
                get-psbreakpoint -script $psise.CurrentFile.FullPath | write-output ; 
            } else { throw "ISE has no current file open. Open a file before using this script" } ; 
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
}
#*------^ get-ISEBreakPoints.ps1 ^------
