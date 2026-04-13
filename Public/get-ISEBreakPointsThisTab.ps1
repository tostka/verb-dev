# get-ISEBreakPointsThisTab.ps1 

#*------v get-ISEBreakPointsThisTab.ps1 v------
function get-ISEBreakPointsThisTab {
    <#
    .SYNOPSIS
    get-ISEBreakPointsThisTab - Get-PSBreakPoint for solely the current focused ISE Open Tab (fltered on -script param)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2024-07-11
    FileName    : get-ISEBreakPointsThisTab
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 7:41 AM 4/13/2026 ren get-ISEBreakPoints-> get-ISEBreakPointThisTab; add alias get-PSBreakPointThisTab
    * 2:27 PM 7/11/2024 init
    .DESCRIPTION
    get-ISEBreakPointsThisTab - Get-PSBreakPoint for solely the current focused ISE Open Tab (fltered on -script param)
    .EXAMPLE
    PS> get-ISEBreakPointsThisTab | ft -a ; 

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
    [Alias('gIseBp','gbptt','get-isebreakpoint','get-isebreakpoints','get-PSBreakPointThisTab')]
    PARAM() ;
    BEGIN{
        $prpSloPsb = 'ID','Script','Line','Enabled' ; 
    }
    PROCESS {
        if ($psise){
            if($psise.CurrentFile.FullPath){
                get-psbreakpoint -script $psise.CurrentFile.FullPath | select-object $prpSloPsb | write-output ; 
            } else { throw "ISE has no current file open. Open a file before using this script" } ; 
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
}
#*------^ get-ISEBreakPointsThisTab.ps1 ^------
