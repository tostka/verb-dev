#*------v Function profile-FileAST() v------
function profile-FileAST {
    <#
    .SYNOPSIS
    profile-FileAST - Parse specified Script/Module using Language.FunctionDefinitionAst
    .NOTES
    Version     : 1.0.0
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
    * 3:56 PM 12/8/2019 INIT
    .DESCRIPTION
    profile-FileAST - Parse specified Script/Module using Language.FunctionDefinitionAst
    .PARAMETER  File
    Path to script/module file
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    $ASTProfile = profile-FileAST -File $oSrc.fullname -showdebug:$($showdebug) -whatif:$($whatif) ;
    .LINK
    #>
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to script[-File path-to\script.ps1]")]
        [ValidateScript( { Test-Path $_ })]$File,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    if ($File.GetType().FullName -ne 'System.IO.FileInfo') {
        $File = get-childitem -path $File ;
    } ;

    $sQot = [char]34 ; $sQotS = [char]39 ;
    $NewCBH = $null ; $NewCBH = @() ;

    $AST = [System.Management.Automation.Language.Parser]::ParseFile($File.fullname, [ref]$null, [ref]$Null ) ;

    # parameters declared in the AST PARAM() Block
    $ASTParameters = $ast.ParamBlock.Parameters.Name.variablepath.userpath ;
    $ASTFunctions =  $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
    $AstVariableAssignments = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.VariableExpressionAst]},$true) ;

    $objReturn = [ordered]@{
        Parameters       = $ASTParameters  ;
        Functions        = $ASTFunctions ;
        VariableAssignments       = $AstVariableAssignments ;
    } ;
    $objReturn | Write-Output

} ; #*------^ END Function profile-FileAST ^------
