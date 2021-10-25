#*------v Function get-FunctionBlocks v------
function get-FunctionBlocks {
    <#
    .SYNOPSIS
    get-FunctionBlocks - All functions from the specified $Parsefile, output them directly to pipeline (capture on far end & parse/display)
    .NOTES
    Author: Todd Kadrie
    Based on Code by: Philip Giuliani (broken example), functional AST code & example by Bartek Bielawski
    Website:	http://tinstoys.blogspot.com
    Twitter:	http://twitter.com/tostka
    REVISIONS   :
    # 5:55 PM 3/15/2020 fix corrupt ABC typo
    # 10:21 AM 9/27/2019 just pull the functions in a file and pipeline them, nothing more.
    .DESCRIPTION
    .PARAMETER  ParseFile
    Script to be parsed [path-to\script.ps1]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    None. Returns matched Function block to pipeline.
    get-FunctionBlocks -Parse C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    Pull/display the Add-EMSRemote function from the specified .ps1, using named params
    .EXAMPLE
    $funcs = get-FunctionBlocks C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    $funcs |?{$_.name -eq 'get-lastwake'} | format-list name,body
    Pull ALL functions, and post-filter return for specific function, and dump the name & body to console.
    .EXAMPLE
    $funcs = get-FunctionBlocks C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    ($funcs |?{$_.name -eq 'get-lastwake'}).Extent.text
    Pull ALL functions, and post-filter return for specific function, and dump the extent.text (body) to console.
    .EXAMPLE
    $funcs = get-FunctionBlocks C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    foreach($func in $funcs){
      $sPre="$("=" * 50)`n#*------v Function $($func.name) from Script:$($ParseFile) v------" ;
      $sPost="#*------^ END Function $($func.name) from Script:$($ParseFile) ^------ ;`n$("=" * 50)" ;
      $sOut = $null ;
      $sOut += "$($sPre)`nFunction $($func.name) " ;
      $sOut += "$($func.Body) $($sPost)" ;
      write-host $sOut
    } ;
    Output a formatted block of Name & Bodies (approx the get-FunctionBlock())
    .LINK
    https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
    https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/
    #>

    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Script to be parsed [path-to\script.ps1]")][ValidateNotNullOrEmpty()]
        $ParseFile
    )  ;

    # 2:07 PM 8/31/2016 alt code:
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($ParseFile, [ref]$null, [ref]$Null ) ;
    $funcsInFile = $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
    # this variant pulls commands v functions
    #$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)

    foreach ($func in $funcsInFile) {
        $func | write-output ;
    } ;
} ; #*------^ END Function get-FunctionBlocks ^------