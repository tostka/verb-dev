#*------v ConvertTo-Breakpoint.ps1 v------
Function ConvertTo-Breakpoint {
    <#
    .SYNOPSIS
    ConvertTo-Breakpoint - Converts an errorrecord to a breakpoint
    .NOTES
    Version     : 2.1.0
    Author      : KevinMarquette
    Website     :	https://github.com/KevinMarquette
    Twitter     :	@KevinMarquette
    CreatedDate : 2022-12-15
    FileName    : ConvertTo-Breakpoint.ps1
    License     : https://github.com/KevinMarquette/ConvertTo-Breakpoint/blob/master/LICENSE
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,debugging
    AddedCredit : Todd Kadrie
    AddedWebsite:	http://www.toddomation.com
    AddedTwitter:	@tostka / http://twitter.com/tostka
    REVISIONS
    * 12:20 PM 12/22/2022 distilled into freestanding function .ps1: shifted priv func into internal, and added to verb-dev, OTB formatting. 
    * 4/18/18 KM's posted git version
    .DESCRIPTION
    ConvertTo-Breakpoint - Converts an errorrecord to a breakpoint 
    
    This works the best in the ISE
    VSCode requires the debugger to be running for Set-PSBreakpoint to work
    
    Comments from linked blog post:
    
    [Powershell: ConvertTo-Breakpoint - powershellexplained.com/](https://powershellexplained.com/2018-04-18-Powershell-ConvertTo-Breakpoint/)
   
    # The Idea

    I often check the `$error[0].ScriptStackTrace` for the source of an error and then go place a breakpoint where the error was raised. I realized that I could parse the `ScriptStackTrace` and call `Set-PSBreakPoint` directly. It is a fairly simple idea and it turned out to be just as easy to write.

    # Putting it all together

    If you ever looked at a `ScriptStackTrace` on an error, you would see something like this:

    ```powershell
    PS> $error[0].ScriptStackTrace
        at New-Error, C:\workspace\ConvertTo-Breakpoint\testing.ps1: line 2
        at Get-Error, C:\workspace\ConvertTo-Breakpoint\testing.ps1: line 6
        at <ScriptBlock>, C:\workspace\ConvertTo-Breakpoint\testing.ps1: line 9
    ```

    While the data is just a string, it is very consistent and easy to parse with regex. Here is the regex pattern that I used to match each line: `at .+, (?<Script>.+): line (?<Line>\d+)`

    I was a little fancy and used [named sub-expression matches](https://powershellexplained.com/2016-11-06-powershell-hashtable-everything-you-wanted-to-know-about/?utm_source=blog&utm_medium=blog#regex-matches). I do this so I can access them by name with `$matches.Script` and `$matches.Line`.

    Once I had the data that I needed, it was a quick call to `Set-PSBreakPoint` to set the breakpoint.

    ```powershell
    Set-PSBreakPoint -Script $matches.Script -Line $matches.Line
    ```

    I put a bit more polish on it and called it `ConvertTo-Breakpoint`.

    I do a full step by step walk of the entire function in this video: [ConvertTo-Breakpoint: Writing the cmdlet](https://youtu.be/2tsA1zsIwGE?t=27m26s).

    # How to use

    This is the cool part. I can now take any `$error` and pipe it to `ConvertTo-Breakpoint`. Then a breakpoint will be created where the error was thrown.

    ```powershell
    $error[0] | ConvertTo-BreakPoint
    ```

    I added proper pipeline support so you can give it all your errors.

    ```powershell
    $error | ConvertTo-BreakPoint
    ```

    I even added `-All` as a switch to create a breakpoint at each point in the callstack instead of just the source of the error.

    ```powershell
    $error[0] | ConvertTo-BreakPoint -All
    ```

    ## VSCode debugger

    In my experimentation with VSCode and `Set-PSBreakpoint`; I discovered that you have to have the debugger running for `Set-PSBreakpoint` to set breakpoints. There is an issue on github about this already. This is why I did the demo video in the ISE.

    # Where do I find it?

    This is already published in the PSGallery. You can install it and start experimenting with it right away.

    ```powershell
    Install-Module -Name ConvertTo-Breakpoint -Scope CurrentUser
    ```

    If you would like to checkout the source, I published it on github with all my other tools:

    -   [https://github.com/KevinMarquette/ConvertTo-Breakpoint](https://github.com/KevinMarquette/ConvertTo-Breakpoint/blob/master/module/public/ConvertTo-Breakpoint.ps1)
    
    .EXAMPLE
    PS> $error[0] | ConvertTo-Breakpoint ;
    The various values returned will be Version 1, Version 2, or Off.
    .EXAMPLE
    PS> $error[0] | ConvertTo-Breakpoint -All
     
    .LINK
    https://github.com/tostka/verb-dev
    https://github.com/KevinMarquette/ConvertTo-Breakpoint
    https://powershellexplained.com/2018-04-18-Powershell-ConvertTo-Breakpoint/
    #>
    [CmdletBinding(SupportsShouldProcess)]
    PARAM(
        [parameter(Mandatory,Position = 0,ValueFromPipeline,HelpMessage='The Error Record[-ErrorRecord `$Error[0]]')]
        [Alias('InputObject')]
        $ErrorRecord,   
        [parameter(HelpMessage='Switch that sets breakpoints on the entire stack[-ALL]')] 
        [switch]$All
    )  ; 
    BEGIN{
        #*------v Function _extractBreakpoint v------
        function _extractBreakpoint {
            <#
            .DESCRIPTION
            Parses a script stack trace for breakpoints
            .EXAMPLE
            $error[0].ScriptStackTrace | _extractBreakpoint
            #>
            [OutputType('System.Collections.Hashtable')]
            [cmdletbinding()]
            PARAM(
                # The ScriptStackTrace
                [parameter(
                    ValueFromPipeline
                )]
                [AllowNull()]
                [AllowEmptyString()]
                [Alias('InputObject')]
                [string]
                $ScriptStackTrace
            )
            BEGIN{$breakpointPattern = 'at .+, (?<Script>.+): line (?<Line>\d+)'} ;
            PROCESS{
                if (-not [string]::IsNullOrEmpty($ScriptStackTrace)){
                    $lineList = $ScriptStackTrace -split [System.Environment]::NewLine
                    foreach($line in $lineList){
                        if ($line -match $breakpointPattern){
                            if ($matches.Script -ne '<No file>' -and (Test-Path $matches.Script)){  
                                @{
                                    Script = $matches.Script
                                    Line   = $matches.Line ; 
                                } ;                           
                            } ; 
                        } ; 
                    } ;  # loop-E
                } ; 
            } ;  # PROC-E
        } ;   
        #*------^ END Function _extractBreakpoint ^------      
    } ;
    PROCESS{
        foreach ($node in $ErrorRecord){
            $breakpointList = $node.ScriptStackTrace | _extractBreakpoint ; 
            foreach ($breakpoint in $breakpointList){
                $message = '{0}:{1}' -f $breakpoint.Script,$breakpoint.Line ; 
                if($PSCmdlet.ShouldProcess($message)){
                    Set-PSBreakpoint @breakpoint ; 
                    if (-Not $PSBoundParameters.All){
                        break ; 
                    } ; 
                } ; 
            } ; 
        } ; 
    }  ; # PROC-E
} ; 
#*------^ ConvertTo-Breakpoint.ps1 ^------
