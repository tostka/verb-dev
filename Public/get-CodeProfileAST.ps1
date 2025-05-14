# get-CodeProfileAST.ps1

#region get_CodeProfileAST ; #*------v get-CodeProfileAST v------
#if(-not (get-childitem function:get-CodeProfileAST -ea 0)){
    function get-CodeProfileAST {
        <#
        .SYNOPSIS
        get-CodeProfileAST - Parse and return script/module/function compoonents, Module using Language.FunctionDefinitionAst parser
        .NOTES
        Version     : 1.1.0
        Author      : Todd Kadrie
        Website     : https://www.toddomation.com
        Twitter     : @tostka / http://twitter.com/tostka
        CreatedDate : 3:56 PM 12/8/2019
        FileName    : get-CodeProfileAST.ps1
        License     : MIT License
        Copyright   : (c) 2019 Todd Kadrie
        Github      : https://github.com/tostka
        AddedCredit :
        AddedWebsite:
        AddedTwitter:
        REVISIONS
        * 10:43 AM 5/14/2025 added SSP-suppressing -whatif:/-confirm:$false to nv's
        * 12:10 PM 5/6/2025 added -ScriptBlock, and logic to process either file or scriptblock; added examples demoing resolve Microsoft.Graph module cmdlet permissions from a file, 
            and connect-MGGraph with the resolved dynamic permissions scope. 
            Added try/catch
        * 8:44 AM 5/20/2022 flip output hash -> obj; renamed $fileparam -> $path; fliped $path from string to sys.fileinfo; 
            flipped AST call to include asttokens in returns; added verbose echos - runs 3m on big .psm1's (125 funcs)
        # 12:30 PM 4/28/2022 ren get-ScriptProfileAST -> get-CodeProfileAST, aliased original name (more descriptive, as covers .ps1|.psm1), add extension validator for -File; ren'd -File -> Path, aliased: 'PSPath','File', strongly typed [string] (per BP).
        # 1:01 PM 5/27/2020 moved alias: profile-FileAST win func
        # 5:25 PM 2/29/2020 ren profile-FileASt -> get-ScriptProfileAST (aliased orig name)
        # * 7:50 AM 1/29/2020 added Cmdletbinding
        * 9:04 AM 12/30/2019 profile-FileAST: updated CBH: added .INPUTS & OUTPUTS, including hash properties returned
        * 3:56 PM 12/8/2019 INIT
        .DESCRIPTION
        get-CodeProfileAST - Parse and return script/module/function compoonents, Module using Language.FunctionDefinitionAst parser
        .PARAMETER  File
        Path to script/module file
        .PARAMETER scriptblock
        Scriptblock of code[-scriptblock `$sbcode]
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
        Outputs a system.object containing:
        * Parameters : Details on all Parameters in the file
        * Functions : Details on all Functions in the file
        * VariableAssignments : Details on all Variables assigned in the file
        .EXAMPLE
        PS> $ASTProfile = get-CodeProfileAST -File c:\pathto\script.ps1 -All -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
        Profile a file, and return the raw $ASTProfile object to the piepline (default behavior)
        PS> $ASTProfile = get-CodeProfileAST -File c:\pathto\script.ps1 -All -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
        PS> $sb = [scriptblock]::Create((gc 'c:\pathto\script.ps1' -raw))  ; 
        PS> $ASTProfile = get-CodeProfileAST  = get-CodeProfileAST -scriptblock $sb -All ;     
        Profile a scriptblock (created by loading a file into a scriptblock variable )
        .EXAMPLE
        PS> $FunctionNames = (get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -Functions).functions.name ;
        Return the Functions within the specified script, and select the name properties of the functions object returned.
        .EXAMPLE
        PS> $AliasAssignments = (get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -Aliases).Aliases.extent.text;
        Return the set/new-Alias commands from the specified script, selecting the full syntax of the command
        .EXAMPLE
        PS> $WhatifLines = ((get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -GenericCommands).GenericCommands | ?{$_.extent -like '*whatif*' } | select -expand extent).text
        Return any GenericCommands from the specified script, that have whatif within the line
        .EXAMPLE
        PS> $cmdlets = @() ; 
        PS> $rgxVNfilter = "\w+-mg\w+" ; 
        PS> (((get-CodeProfileAST -File D:\scripts\new-MGDomainRegTDO.ps1  -GenericCommands).GenericCommands |?{$_.extent -match "-mg"}).extent.text).Split([Environment]::NewLine) |%{
        PS>     $thisLine = $_ ; 
        PS>     if($thisLine -match $rgxVNfilter){
        PS>         $cmdlets += $matches[0] ; 
        PS>     } ; 
        PS> } ; 
        PS> write-verbose "Normalize & unique names"; 
        PS> $cmdlets = $cmdlets | %{get-command -name $_| select -expand name } | select -unique ; ; 
        PS> $cmdlets ; 
        PS> $PermsRqd = @() ; 
        PS> $cmdlets |%{
        PS>     write-host -NoNewline '.' ; 
        PS>     $PermsRqd += Find-MgGraphCommand -command $_ -ea STOP| Select -First 1 -ExpandProperty Permissions | Select -Unique name ; 
        PS> } ; 
        PS> write-host -foregroundcolor yellow "]" ; 
        PS> $PermsRqd = $PermsRqd.name | select -unique ;
        PS> $smsg = "Connect-mgGraph -scope`n`n$(($PermsRqd|out-string).trim())" ;
        PS> $smsg += "`n`n(Perms reflects Cmdlets:$($Cmdlets -join ','))" ;
        PS> write-host $smsg ;
        PS> $ccResults = Connect-mgGraph -scope $PermsRqd -ea STOP ;    
        Demo processing a script file for [verb]-MG[noun] cmdlets (e.g. that are part of Microsoft.Graph module), 
            - normalize the names via gcm, and select uniques, 
            - Then use MG module's Find-MgGraphCommand to resolve required Permissions, 
            - Then run Connect-mgGraph dynamically scoped to the necessary permissions. 
        .EXAMPLE
        PS> $bRet = (get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -All) ;
        PS> $bRet.functions.name ;
        PS> $bret.variables.extent.text
        PS> $bret.aliases.extent.text
        Return ALL variant objects - Functions, Parameters, Variables, aliases, GenericCommands - from the specified script, and output the function names, variable names, and alias assignement commands
        .LINK
        #>
        [CmdletBinding()]
        [Alias('get-ScriptProfileAST')]
        PARAM(
            [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Path to script[-File path-to\script.ps1]")]
                [ValidateScript( {Test-Path $_})][ValidatePattern( "\.(ps1|psm1|txt)$")]
                [Alias('PSPath','File')]
                [system.io.fileinfo]$Path,
            [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Scriptblock of code[-scriptblock `$sbcode]")]
                [Alias('code')]
                $scriptblock,
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
            TRY{
                $Verbose = ($VerbosePreference -eq "Continue") ;
                if(-NOT ($path -OR $scriptblock)){
                    throw "neither -Path or -Scriptblock specified: Please specify one or the other when running" ; 
                    break ; 
                } elseif($path -AND $scriptblock){
                    throw "BOTH -Path AND -Scriptblock specified: Please specify EITHER one or the other when running" ; 
                    break ; 
                } ;  
                if ($Path -AND $Path.GetType().FullName -ne 'System.IO.FileInfo') {
                    write-verbose "(convert path to gci)" ; 
                    $Path = get-childitem -path $Path ; 
                } ;
                if ($scriptblock -AND $scriptblock.GetType().FullName -ne 'System.Management.Automation.ScriptBlock') {
                    write-verbose "(recast -scriptblock to [scriptblock])" ; 
                    $scriptblock= [scriptblock]::Create($scriptblock) ; 
                } ;
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ; 
        } ;
        PROCESS {
            $sw = [Diagnostics.Stopwatch]::StartNew();
            TRY{
                write-verbose "$((get-date).ToString('HH:mm:ss')):(running AST parse...)" ; 
                New-Variable astTokens -Force -whatif:$false -confirm:$false ; New-Variable astErr -Force -whatif:$false -confirm:$false ; 
                if($Path){            
                    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$astTokens, [ref]$astErr) ; 
                }elseif($scriptblock){
                    $AST = [System.Management.Automation.Language.Parser]::ParseInput($scriptblock, [ref]$astTokens, [ref]$astErr) ; 
                } ;     
                $objReturn = [ordered]@{ } ;
                if ($Functions -OR $All) {
                    write-verbose "$((get-date).ToString('HH:mm:ss')):(parsing Functions from AST...)" ; 
                    $ASTFunctions = $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
                    $objReturn.add('Functions', $ASTFunctions) ;
                } ;
                if ($Parameters -OR $All) {
                    write-verbose "$((get-date).ToString('HH:mm:ss')):(parsing Parameters from AST...)" ; 
                    $ASTParameters = $ast.ParamBlock.Parameters.Name.variablepath.userpath ;
                    $objReturn.add('Parameters', $ASTParameters) ;
                } ;
                if ($Variables -OR $All) {
                    write-verbose "$((get-date).ToString('HH:mm:ss')):(parsing Variables from AST...)" ; 
                    $AstVariableAssignments = $ast.FindAll( { $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true) ;
                    $objReturn.add('Variables', $AstVariableAssignments) ;
                } ;
                if ($($Aliases -OR $GenericCommands) -OR $All) {
                    write-verbose "$((get-date).ToString('HH:mm:ss')):(parsing ASTGenericCommands from AST...)" ; 
                    $ASTGenericCommands = $ast.FindAll( { $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) ;
                    if ($Aliases -OR $All) {
                        write-verbose "$((get-date).ToString('HH:mm:ss')):(post-filtering (set|new)-Alias from AST...)" ; 
                        $ASTAliasAssigns = ($ASTGenericCommands | ? { $_.extent.text -match '(set|new)-alias' }) ;
                        $objReturn.add('Aliases', $ASTAliasAssigns) ;
                    } ;
                    if ($GenericCommands -OR $All) {
                        $objReturn.add('GenericCommands', $ASTGenericCommands) ;
                    } ;
                } ;
                #$objReturn | Write-Output ;
                New-Object PSObject -Property $objReturn | Write-Output ;
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ; 
        } ;
        END {
            $sw.Stop() ;
            $smsg = ("Elapsed Time: {0:dd}d {0:hh}h {0:mm}m {0:ss}s {0:fff}ms" -f $sw.Elapsed) ; 
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ;
    } ; 
#} ; 
#endregion get_CodeProfileAST ; #*------^ END get-CodeProfileAST ^------