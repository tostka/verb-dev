#*------v Function move-ISEBreakPoints v------
function move-ISEBreakPoints {
    <#
    .SYNOPSIS
    move-ISEBreakPoints - Offset current ISE tab's existing breakpoints by lines specified
    .NOTES
    Version     : 1.0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2020-08-25
    FileName    : move-ISEBreakPoints
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 3:29 PM 12/4/2023 new alias using proper std suffix for move == 'm': mIseBP. Technically it should be mbp (like sbp), but that's too short to be safe; too likely to accidentlaly trigger on console.
    * 3:05 PM 9/7/2022 ren & alias orig name shift-ISEBreakPoints -> move-ISEBreakPoints
    * 10:49 AM 8/25/2020 init, added to verb-dev module
    .DESCRIPTION
    move-ISEBreakPoints - Offset current ISE tab's existing breakpoints by lines specified
    .PARAMETER PathDefault
    Default Path for export (when `$Script directory is unavailable)[-PathDefault c:\path-to\]
    .EXAMPLE
    move-ISEBreakPoints -lines -4
    Shift all existing PSBreakpoints UP 4 lines
    .EXAMPLE
    move-ISEBreakPoints -lines 5
    Shift all existing PSBreakpoints DOWN 5 lines
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('sIseBp','shift-ISEBreakPoints','mIseBp')]
    PARAM(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter lines +/- to shift breakpoints on current script[-lines -3]")]
        [int]$lines
    ) ;
    BEGIN {} ;
    PROCESS {
        if ($psise -AND $psise.CurrentFile.FullPath){
            
            $eBPs = get-psbreakpoint -Script $psise.CurrentFile.fullpath ; 
            # older, mandetory param prompts instead
            #$lines=Read-Host "Enter lines +/- to shift breakpoints on current script:($($psise.CurrentFile.displayname))" ;
            foreach($eBP in $eBPs){
              remove-psbreakpoint -id $eBP.id ; 
              set-PSBreakpoint -script $eBP.script -line ($eBP.line + $lines) ; 
            } ; 
            
        } else {  write-warning 'This script only functions within PS ISE, with a script file open for editing' };

     } # PROC-E
} ; #*------^ END Function move-ISEBreakPoints ^------
