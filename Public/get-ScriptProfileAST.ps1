#*------v Function get-ScriptProfileAST() v------
function get-ScriptProfileAST {
    <#
    .SYNOPSIS
    get-ScriptProfileAST - Parse specified Script/Module using Language.FunctionDefinitionAst
    .NOTES
    Version     : 1.1.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 3:56 PM 12/8/2019
    FileName    :
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit :
    AddedWebsite:
    AddedTwitter:
    REVISIONS
    # 5:25 PM 2/29/2020 ren profile-FileASt -> get-ScriptProfileAST (aliased orig name)
    # * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:04 AM 12/30/2019 profile-FileAST: updated CBH: added .INPUTS & OUTPUTS, including hash properties returned
    * 3:56 PM 12/8/2019 INIT
    .DESCRIPTION
    profile-FileAST - Parse specified Script/Module using Language.FunctionDefinitionAst
    .PARAMETER  File
    Path to script/module file
    .PARAMETER Functions
    Flag to return Functions-only [-Functions]
    .PARAMETER Parameter
    Flag to return Parameter-only [-Functions]
    .PARAMETER Variables
    Flag to return Variables-only [-Variables]
    .PARAMETER Aliases
    Flag to return Aliases-only [-Aliases]
    .PARAMETER GenericCommands
    Flag to return GenericCommands-only [-GenericCommands]
    .PARAMETER All
    Flag to return All [-All]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Outputs a hashtable object containing:
    * Parameters : Details on all Parameters in the file
    * Functions : Details on all Functions in the file
    * VariableAssignments : Details on all Variables assigned in the file
    .EXAMPLE
    $ASTProfile = profile-FileAST -File c:\pathto\script.ps1 -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
    Return the raw $ASTProfile object to the piepline (default behavior)
    .EXAMPLE
    $FunctionNames = (get-scriptprofileast -File c:\usr\work\exch\scripts\verb-dev.ps1 -Functions).functions.name ;
    Return the Functions within the specified script, and select the name properties of the functions object returned.
    .EXAMPLE
    $AliasAssignments = (get-scriptprofileast -File c:\usr\work\exch\scripts\verb-dev.ps1 -Aliases).Aliases.extent.text;
    Return the set/new-Alias commands from the specified script, selecting the full syntax of the command
    .EXAMPLE
    $WhatifLines = ((get-scriptprofileast -File c:\usr\work\exch\scripts\verb-dev.ps1 -GenericCommands).GenericCommands | ?{$_.extent -like '*whatif*' } | select -expand extent).text
    Return any GenericCommands from the specified script, that have whatif within the line
    .EXAMPLE
    $bRet = ((get-scriptprofileast -File c:\usr\work\exch\scripts\verb-dev.ps1 -All) ;
    $bRet.functions.name ;
    $bret.variables.extent.text
    $bret.aliases.extent.text

    Return ALL variant objects - Functions, Parameters, Variables, aliases, GenericCommands - from the specified script, and output the function names, variable names, and alias assignement commands
    .LINK
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to script[-File path-to\script.ps1]")]
        [ValidateScript( { Test-Path $_ })]$File,
        [Parameter(HelpMessage = "Flag to return Functions-only [-Functions]")]
        [switch] $Functions,
        [Parameter(HelpMessage = "Flag to return Parameters-only [-Functions]")]
        [switch] $Parameters,
        [Parameter(HelpMessage = "Flag to return Variables-only [-Variables]")]
        [switch] $Variables,
        [Parameter(HelpMessage = "Flag to return Aliases-only [-Aliases]")]
        [switch] $Aliases,
        [Parameter(HelpMessage = "Flag to return GenericCommands-only [-GenericCommands]")]
        [switch] $GenericCommands,
        [Parameter(HelpMessage = "Flag to return All [-All]")]
        [switch] $All,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        $Verbose = ($VerbosePreference -eq "Continue") ;
        if ($File.GetType().FullName -ne 'System.IO.FileInfo') {
            $File = get-childitem -path $File ;
        } ;
    } ;
    PROCESS {
        $AST = [System.Management.Automation.Language.Parser]::ParseFile($File.fullname, [ref]$null, [ref]$Null ) ;

        $objReturn = [ordered]@{ } ;

        if ($Functions -OR $All) {
            $ASTFunctions = $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
            $objReturn.add('Functions', $ASTFunctions) ;
        } ;
        if ($Parameters -OR $All) {
            $ASTParameters = $ast.ParamBlock.Parameters.Name.variablepath.userpath ;
            $objReturn.add('Parameters', $ASTParameters) ;
        } ;
        if ($Variables -OR $All) {
            $AstVariableAssignments = $ast.FindAll( { $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true) ;
            $objReturn.add('Variables', $AstVariableAssignments) ;
        } ;
        if ($($Aliases -OR $GenericCommands) -OR $All) {
            $ASTGenericCommands = $ast.FindAll( { $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) ;
            if ($Aliases -OR $All) {
                $ASTAliasAssigns = ($ASTGenericCommands | ? { $_.extent.text -match '(set|new)-alias' }) ;
                $objReturn.add('Aliases', $ASTAliasAssigns) ;
            } ;
            if ($GenericCommands -OR $All) {
                $objReturn.add('GenericCommands', $ASTGenericCommands) ;
            } ;
        } ;
        $objReturn | Write-Output ;
    } ;
    END { } ;
} ; #*------^ END Function get-ScriptProfileAST ^------
if (!(get-alias -name "profile-FileAST" -ea 0 )) { Set-Alias -Name 'profile-FileAST' -Value 'get-ScriptProfileAST' ; } ;

#*------v Function get-FunctionBlock v------