#*------v Function get-AliasAssignsAST v------
function get-AliasAssignsAST {
    <#
    .SYNOPSIS
    get-AliasAssignsAST - All Alias assigns ((set|new)-Alias) from the specified $Parsefile, output them directly to pipeline (capture on far end & parse/display)
    .NOTES
    Author: Todd Kadrie
    Based on Code by: Philip Giuliani (broken example), functional AST code & example by Bartek Bielawski
    Website:	http://tinstoys.blogspot.com
    Twitter:	http://twitter.com/tostka
    REVISIONS   :
    # 9:55 AM 5/18/2022 add ported variant of get-functionblocks()
    .DESCRIPTION
    get-AliasAssignsAST - All Alias assigns ((set|new)-Alias) from the specified $Parsefile, output them directly to pipeline (capture on far end & parse/display)
    .PARAMETER  Path
    Script to be parsed [path-to\script.ps1]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    None. Returns matched Function block to pipeline.
    get-AliasAssignsAST -Parse C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    Pull/display the Add-EMSRemote function from the specified .ps1, using named params
    .EXAMPLE
    $aliasAssigns = get-AliasAssignsAST C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    $aliasassigns | ?{$_ -like '*get-ScriptProfileAST*'}
    Pull ALL Alias Assignements, and post-filter return for specific Alias Definition/Value.
    .LINK
    https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
    https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/
    #>

    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Script to be parsed [path-to\script.ps1]")][ValidateNotNullOrEmpty()]
        [Alias('ParseFile')]
        [system.io.fileinfo]$Path
    )  ;
    $sw = [Diagnostics.Stopwatch]::StartNew();
    New-Variable astTokens -force ; New-Variable astErr -force ;
    write-verbose "$((get-date).ToString('HH:mm:ss')):(running AST parse...)" ; 
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$astTokens, [ref]$astErr) ;
    # use of aliased commands (% for foreach-object etc)
    #$aliases = $astTokens | where {$_.tokenflags -eq 'commandname' -AND $_.kind -eq 'identifier'} ;
    # new|set-alias use
    write-verbose "$((get-date).ToString('HH:mm:ss')):(finding all of the commands references...)" ; 
    $ASTAllCommands = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true) ; 
    write-verbose "$((get-date).ToString('HH:mm:ss')):(pulling set/new-Alias commands out...)" ; 
    $ASTAliasAssigns = ($ASTAllCommands | ?{$_.extent.text -match '(set|new)-alias'}).extent.text
    # dump the .extent.text, if you want the explicit set/new-alias commands 
    # this variant pulls commands v functions
    #$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)

    foreach ($aliasAssign in $ASTAliasAssigns) {
        $aliasAssign | write-output ;
    } ;
    $sw.Stop() ;
    write-verbose ("Elapsed Time: {0:dd}d {0:hh}h {0:mm}m {0:ss}s {0:fff}ms" -f $sw.Elapsed) ; 
} ; #*------^ END Function get-AliasAssignsAST ^------
