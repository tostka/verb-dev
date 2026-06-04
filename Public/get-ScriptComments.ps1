# get-ScriptComments.ps1

#region GET_SCRIPTCOMMENTS ; #*------v get-ScriptComments v------
Function Get-ScriptComments {
    <#
    .SYNOPSIS
    get-ScriptComments - parse a script file for comments only
    .NOTES
    Version     : 0.0.
    .NOTES
    Author: Jeffery Hicks
    Website:	https://jdhitsolutions.com/blog/powershell/5410/creating-a-github-gist-with-powershell/
    Twitter:	@tostka, http://twitter.com/tostka
    Additional Credits: REFERENCE
    Website:	URL
    Twitter:	URL
    CreatedDate : 2026-
    FileName    : get-ScriptComments.ps1
    License     : (non asserted)
    Copyright   : (non asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Git,SourceControl
    AddedCredit : 
    AddedWebsite: 
    AddedTwitter: URL
    REVISIONS
    * 10:07 AM 6/4/2026 added CBH, minor tweaks
    * 3.5.0, isescriptinggeek posted copy from psg
    .DESCRIPTION
    get-ScriptComments - parse a script file for comments only
    
    Simple wrapper of the [math]::ieeeremainder( $number,$devisor) function
    
    Although the moduls operator '%' : ($number % $divisor) should work, I find the ieeeremainder() to be more dependable. 
    Unfortunately it's an ugly/long command to contruct. 
    So wrap it with get-reminder -number 20 -divisor 5, 
    or even better use the gRmdr alias with positional params:
    
    if((gRmdr $xdots $dcLen) -eq 0){write-host -fore yellow "`n."}
    
    .PARAMETER number
    The number to be divided by the divisor
    .PARAMETER divisor
    The number to divide the number by
    .INPUTS
    Does not accept pipeline input.
    .OUTPUTS
    returns the parsed comments to the pipeline
    .EXAMPLE
    PS> get-ScriptComments -Path C:\sc\verb-dev\Public\get-ScriptComments.ps1
    
        #*------v AST-PARSED COMMENTS : C:\sc\verb-dev\Public\get-ScriptComments.ps1 v------
        # get-ScriptComments.ps1
        ...
        #endregion GET_SCRIPTCOMMENTS ; #*------^ END get-ScriptComments ^------
        10:04:34:
        #*------^ AST-PARSED COMMENTS : C:\sc\verb-dev\Public\get-ScriptComments.ps1 ^------    
        
    demo
    .LINK
    https://www.powershellgallery.com/packages/ISEScriptingGeek/3.5.0/Content/functions%5CGet-ScriptComments.ps1
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Position = 0, Mandatory, HelpMessage = 'Enter the path of a PS1 file',ValueFromPipeline, ValueFromPipelineByPropertyName)]
          [Alias('PSPath', 'Name')]
          [ValidateScript( { Test-Path $_ })]
          [ValidatePattern('\.ps(1|m1)$')]
          [String]$Path
    )
    BEGIN {
        #Begin scriptblock
        Write-Verbose -Message "Starting $($MyInvocation.MyCommand)"
        #initialization commands
        #explicitly define some AST variables
        New-Variable $AstTokens -Force
        New-Variable astErr -Force
    } #close begin
    PROCESS {
        #Process scriptblock
        #convert each path to a nice filesystem path
        $Path = Convert-Path -Path $Path

        Write-Verbose -Message "Parsing $Path"
        #Parse the file
        $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$AstTokens, [ref]$astErr)

        #filter tokens for comments and display text
        $AstTokens.where( { $_.kind -eq 'comment' }) |
        Select-Object -ExpandProperty Text
    } #close process
    END {
        Write-Verbose -Message "Ending $($MyInvocation.MyCommand)"
    } #close end
}
#endregion GET_SCRIPTCOMMENTS ; #*------^ END get-ScriptComments ^------
