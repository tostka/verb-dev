# Get-PSBreakpointSorted.ps1

#*------v Get-PSBreakpointSorted.ps1 v------
function Get-PSBreakpointSorted {
<#
    .SYNOPSIS
    Get-PSBreakpointSorted.ps1 - Simple Get-PSBreakpoint wrapper function (gbps alias), force Script,Line sort order on gbp output - wtf wants it's default bp# sort order?!
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2022-07-26
    FileName    : Get-PSBreakpointSorted.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Development,Debugging,BreakPoints
    REVISIONS
    * 10:55 AM 7/26/2022 init
    .DESCRIPTION
    Get-PSBreakpointSorted.ps1 - Simple Get-PSBreakpoint wrapper function (gbps alias), force Script,Line sort order on gbp output - wtf wants it's default bp# sort order?!
    Also uses abbreviated, more condensed 'format-table -a ID,Script,Line' output.
    .EXAMPLE
    Get-PSBreakpointSorted
    Stock call
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    #>
    [CmdletBinding()]
    [Alias('gbps')]
    Param() ;
    get-psbreakpoint | sort script,line | format-table -a ID,Script,Line ; 
}
#*------^ END Function Get-PSBreakpointSorted ^------