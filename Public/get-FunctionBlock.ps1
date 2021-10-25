#*------v Function get-FunctionBlock v------
function get-FunctionBlock {
    <#
    .SYNOPSIS
    get-FunctionBlock - Retrieve the specified $functionname function block from the specified $Parsefile.
    .NOTES
    Author: Todd Kadrie
    Based on Code by: Philip Giuliani (broken example), functional AST code & example by Bartek Bielawski
    Website:	http://tinstoys.blogspot.com
    Twitter:	http://twitter.com/tostka
    REVISIONS   :
    # 10:07 AM 9/27/2019 ren'd GetFuncBlock -> get-FunctionBlock & tighted up, added named param expl
    3:19 PM 8/31/2016 - initial version, functional
    .DESCRIPTION
    .PARAMETER  ParseFile
    Script to be parsed [path-to\script.ps1]
    .PARAMETER  functionName
    Function name to be found and displayed from ParseFile
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns matched Function block to pipeline.
    .EXAMPLE
    get-FunctionBlock C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 Add-EMSRemote ;
    Pull/display the Add-EMSRemote function from the specified .ps1, using positional params
    .EXAMPLE
    get-FunctionBlock -Parse C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 -Func Add-EMSRemote ;
    Pull/display the Add-EMSRemote function from the specified .ps1, using named params
    .LINK
    https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
    https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/
    #>

    Param(
        [Parameter(Position=0,MandaTory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Script to be parsed [path-to\script.ps1]")][ValidateNotNullOrEmpty()]
        $ParseFile
        ,[Parameter(Position=1,MandaTory=$True,HelpMessage="Function name to be found and displayed from ParseFile")]
        $functionName
    )  ;


    # 2:07 PM 8/31/2016 alt code:
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($ParseFile,[ref]$null,[ref]$Null ) ;
    $funcsInFile = $AST.FindAll({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true) ;
    # this variant pulls commands v functions
    #$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)

    $matchfunc = $null ;
    foreach($func in $funcsInFile) {
        if($func.Name -eq $functionName) {
            $matchfunc = $func ;
            break ;
        } ;
    } ;
    if($matchfunc -eq $null){ return 0 } ;
    $matchfuncBody = $matchfunc.Body ;

    # dumping the last line# for the targeted funct to pipeline
    #return $matchfuncBody.Extent.EndLineNumber ;

    # 2:20 PM 8/31/2016 return the function with bracketing

    $sPre="$("=" * 50)`n#*------v Function $($matchfunc.name) from Script:$($ParseFile) v------" ;
    $sPost="#*------^ END Function $($matchfunc.name) from Script:$($ParseFile) ^------ ;`n$("=" * 50)" ;

    # here string seems to make it crap out, just append together
    $sOut = $null ;
    $sOut += "$($sPre)`nFunction $($matchfunc.name) " ;
    $sOut += "$($matchfunc.Body) $($sPost)" ;

    write-verbose -verbose:$true "Script:$($ParseFile): Matched Function:$($functionName) " ;
    $sOut | write-output ;

} ; #*------^ END Function get-FunctionBlock ^------