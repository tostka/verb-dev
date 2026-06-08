
# get-CodeProfileAST

## SYNOPSIS
get-CodeProfileAST - Parse and return script/module/function compoonents, Module using Language.FunctionDefinitionAst parser

## SYNTAX

```
get-CodeProfileAST [[-Path] <FileInfo>] [[-scriptblock] <Object>] [-Functions] [-Parameters] [-Variables]
 [-Aliases] [-GenericCommands] [-All] [-showDebug] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
get-CodeProfileAST - Parse and return script/module/function compoonents, Module using Language.FunctionDefinitionAst parser

## EXAMPLES

### EXAMPLE 1
```
$ASTProfile = get-CodeProfileAST -File c:\pathto\script.ps1 -All -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
```

Profile a file, and return the raw $ASTProfile object to the piepline (default behavior)
PS\> $ASTProfile = get-CodeProfileAST -File c:\pathto\script.ps1 -All -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
PS\> $sb = \[scriptblock\]::Create((gc 'c:\pathto\script.ps1' -raw))  ; 
PS\> $ASTProfile = get-CodeProfileAST  = get-CodeProfileAST -scriptblock $sb -All ;     
Profile a scriptblock (created by loading a file into a scriptblock variable )

### EXAMPLE 2
```
$FunctionNames = (get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -Functions).functions.name ;
```

Return the Functions within the specified script, and select the name properties of the functions object returned.

### EXAMPLE 3
```
$AliasAssignments = (get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -Aliases).Aliases.extent.text;
```

Return the set/new-Alias commands from the specified script, selecting the full syntax of the command

### EXAMPLE 4
```
$WhatifLines = ((get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -GenericCommands).GenericCommands | ?{$_.extent -like '*whatif*' } | select -expand extent).text
```

Return any GenericCommands from the specified script, that have whatif within the line

### EXAMPLE 5
```
$cmdlets = @() ;
```

PS\> $rgxVNfilter = "\w+-mg\w+" ; 
PS\> (((get-CodeProfileAST -File D:\scripts\new-MGDomainRegTDO.ps1  -GenericCommands).GenericCommands |?{$_.extent -match "-mg"}).extent.text).Split(\[Environment\]::NewLine) |%{
PS\>     $thisLine = $_ ; 
PS\>     if($thisLine -match $rgxVNfilter){
PS\>         $cmdlets += $matches\[0\] ; 
PS\>     } ; 
PS\> } ; 
PS\> write-verbose "Normalize & unique names"; 
PS\> $cmdlets = $cmdlets | %{get-command -name $_| select -expand name } | select -unique ; ; 
PS\> $cmdlets ; 
PS\> $PermsRqd = @() ; 
PS\> $cmdlets |%{
PS\>     write-host -NoNewline '.' ; 
PS\>     $PermsRqd += Find-MgGraphCommand -command $_ -ea STOP| Select -First 1 -ExpandProperty Permissions | Select -Unique name ; 
PS\> } ; 
PS\> write-host -foregroundcolor yellow "\]" ; 
PS\> $PermsRqd = $PermsRqd.name | select -unique ;
PS\> $smsg = "Connect-mgGraph -scope\`n\`n$(($PermsRqd|out-string).trim())" ;
PS\> $smsg += "\`n\`n(Perms reflects Cmdlets:$($Cmdlets -join ','))" ;
PS\> write-host $smsg ;
PS\> $ccResults = Connect-mgGraph -scope $PermsRqd -ea STOP ;    
Demo processing a script file for \[verb\]-MG\[noun\] cmdlets (e.g.
that are part of Microsoft.Graph module), 
    - normalize the names via gcm, and select uniques, 
    - Then use MG module's Find-MgGraphCommand to resolve required Permissions, 
    - Then run Connect-mgGraph dynamically scoped to the necessary permissions.

### EXAMPLE 6
```
$bRet = (get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -All) ;
```

PS\> $bRet.functions.name ;
PS\> $bret.variables.extent.text
PS\> $bret.aliases.extent.text
Return ALL variant objects - Functions, Parameters, Variables, aliases, GenericCommands - from the specified script, and output the function names, variable names, and alias assignement commands

### EXAMPLE 7
```
$GCmds = (get-CodeProfileAST -File .\new-MGDomainRegTDO.ps1 -GenericCommands).GenericCommands ;
```

PS\> $rgxverbNounNames = "\b\w+\-\w+\b" ;
PS\> # match extents with verb-noun substrings
PS\> $CmdletNames = @() ;
PS\> ($GCmds|?{$_.extent -match $rgxverbNounNames}) | %{
PS\>   $isolatedlines = $_ ;
PS\>   # isolate the actual verb-noun substrings
PS\>   $CmdletNames += $isolatedlines.extent.text | %{if($_ -match $rgxverbNounNames){ $matches\[0\]}}
PS\> } ; 
PS\> # unique the list
PS\> #$CmdletNames = $CmdletNames | select -unique | sort ; # isn't unbiqueing for some reason (passes dupes), use group
PS\> $CmdletNames = $CmdletNames | group | select -expand  name | sort ;
PS\> # resolve each to a source (and properly case the name), or default source to 'unresolved' if fails gcm (note function \[Alias()\] names in use will come back with $null source: they gcm, but there's no source to return)
PS\> $ResolvedCmds = $CmdletNames | %{    
PS\>     $thiscmd = $_ ;
PS\>     $hsCmdSummary = \[ordered\]@{'name'=$null;'source'=$null;'verb'=$null;'noun'=$null; CommandType=$null} ;
PS\>     if($rvGcm = gcm $thiscmd  -ea 0){
PS\>         $hsCmdSummary.name = $rvGcm.name ; $hsCmdSummary.source = $rvGcm.source ;;
PS\>         $hsCmdSummary.verb = $rvGcm.verb ; $hsCmdSummary.noun = $rvGcm.noun ; $hsCmdSummary.CommandType=$rvGcm.CommandType ;
PS\>     }else {
PS\>         # fake it from what we know
PS\>         $hsCmdSummary.name = $thiscmd  ; $hsCmdSummary.source = 'UNRESOLVED' ;
PS\>         $hsCmdSummary.verb,$hsCmdSummary.noun = $thiscmd.split('-');
PS\>         $hsCmdSummary.CommandType="UNRESOLVED" ;
PS\>     };
PS\>     \[pscustomobject\]$hsCmdSummary ;
PS\> } | sort source,name ;
PS\> $ResolvedCmds| ft -a ;

    name                         source                                       verb        noun                  CommandType
    ----                         ------                                       ----        ----                  -----------
    Out-Clipboard                                                                                                     Alias
    Resolve-DnsName              DnsClient                                    Resolve     DnsName                    Cmdlet
    New-MgDomain                 Microsoft.Graph.Identity.DirectoryManagement New         MgDomain                 Function
    ForEach-Object               Microsoft.PowerShell.Core                    ForEach     Object                     Cmdlet
    Write-Degug                  UNRESOLVED                                   Write       Degug                  UNRESOLVED
    ...

PS\> $ResolvedCmds | ?
verb -ne 'get' | ft -a  ; 
AST parse out all verb-noun format generic commands from a source (regex demarced on word boundaries) ; unique the returned strings, then resolve each against a source/module, w verb,noun,source & commandtype. 
Goal is to profile code for updates around source modules, and types of verb (action/change verbs, for adding shouldproceses support, etc). 
Trailing command outputs the non-'Get' verb items.

## PARAMETERS

### -Path
Path to script\[-File path-to\script.ps1\]

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases: PSPath, File

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -scriptblock
Scriptblock of code\[-scriptblock \`$sbcode\]

```yaml
Type: Object
Parameter Sets: (All)
Aliases: code

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Functions
Flag to return Functions-only \[-Functions\]

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Parameters
Flag to return Parameters-only \[-Functions\]

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Variables
Flag to return Variables-only \[-Variables\]

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Aliases
Flag to return Aliases-only \[-Aliases\]

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -GenericCommands
Flag to return GenericCommands-only \[-GenericCommands\]

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Flag to return All \[-All\]

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -showDebug
Parameter to display Debugging messages \[-ShowDebug switch\]

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -whatIf
Parameter to run a Test no-change pass \[-Whatif switch\]

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### Outputs a system.object containing:
### * Parameters : Details on all Parameters in the file
### * Functions : Details on all Functions in the file
### * VariableAssignments : Details on all Variables assigned in the file
## NOTES
Version     : 1.1.0
Author      : Todd Kadrie
Website     : https://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 3:56 PM 12/8/2019
FileName    : get-CodeProfileAST.ps1
License     : MIT License
Copyright   : (c) 2025 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
AddedCredit :
AddedWebsite:
AddedTwitter:
REVISIONS
* 10:57 AM 5/19/2025 add: CBH for more extensive code profiling demo (for targeting action-verb cmds in code, from specific modules); fixed some missing CBH info.
* 4:11 PM 5/15/2025 add psv2-ordered compat
* 10:43 AM 5/14/2025 added SSP-suppressing -whatif:/-confirm:$false to nv's
* 12:10 PM 5/6/2025 added -ScriptBlock, and logic to process either file or scriptblock; added examples demoing resolve Microsoft.Graph module cmdlet permissions from a file, 
    and connect-MGGraph with the resolved dynamic permissions scope. 
    Added try/catch
* 8:44 AM 5/20/2022 flip output hash -\> obj; renamed $fileparam -\> $path; fliped $path from string to sys.fileinfo; 
    flipped AST call to include asttokens in returns; added verbose echos - runs 3m on big .psm1's (125 funcs)
# 12:30 PM 4/28/2022 ren get-ScriptProfileAST -\> get-CodeProfileAST, aliased original name (more descriptive, as covers .ps1|.psm1), add extension validator for -File; ren'd -File -\> Path, aliased: 'PSPath','File', strongly typed \[string\] (per BP).
# 1:01 PM 5/27/2020 moved alias: profile-FileAST win func
# 5:25 PM 2/29/2020 ren profile-FileASt -\> get-ScriptProfileAST (aliased orig name)
# * 7:50 AM 1/29/2020 added Cmdletbinding
* 9:04 AM 12/30/2019 profile-FileAST: updated CBH: added .INPUTS & OUTPUTS, including hash properties returned
* 3:56 PM 12/8/2019 INIT

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

