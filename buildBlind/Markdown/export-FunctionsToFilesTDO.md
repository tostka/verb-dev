
# export-FunctionsToFilesTDO

## SYNOPSIS
export-FunctionsToFilesTDO - Parse out all functions from the specified -Path (via AST Parser), and output each to _func.ps1 files in specified destination dir

## SYNTAX

```
export-FunctionsToFilesTDO [-Path] <FileInfo[]> [-Destination] <DirectoryInfo> [-NoFunc] [-Include <String[]>]
 [-Exclude <String[]>] [-IncludeInternalFunctions <String[]>] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
export-FunctionsToFilesTDO - Parse out all functions from the specified -Path (via AST Parser), and output each to _func.ps1 files in specified destination dir

Automatically skips 'internal functions', those by convention tagged with an underscore as the first letter of the function name, unless 
-IncludeInternalFunctions is specified (which would cause the internal function to export both within it's parent function, and as a separate freestanding function file).

## EXAMPLES

### EXAMPLE 1
```
$results = export-FunctionsToFilesTDO -Path C:\sc\powershell\PSScripts\build\xopBuildLibrary.psm1 -Destination "C:\sc\powershell\PSScripts\build\epFuncs" -verbose  ;
```

Parse and export all items in the specified file, to the destination directory

### EXAMPLE 2
```
$results = export-FunctionsToFilesTDO -Path C:\sc\powershell\PSScripts\build\xopBuildLibrary.psm1 -Destination "C:\sc\powershell\PSScripts\build\epFuncs2" -verbose -NoFunc ;
```

Demo exports with -Nofunc to suppress _func.ps1 suffix on exported filemames.

### EXAMPLE 3
```
gci C:\sc\powershell\PSScripts\build\modslist20251007-1147AM.txt | sls '^\w+' | %{
```

PS\>     $hit = $_ ;
PS\>     $tfunc = $hit.line.trim() ;
PS\>     write-host $tfunc ;
PS\>     if($found = gci "c:\sc\$($tfunc).ps1" -recur){
PS\>         $epspec = (join-path (split-path $hit.Path) "epFuncs\$($tfunc)_func.ps1")
PS\>         if($epfile = gci $epspec){
PS\>             @($found.fullname,$epfile.fullname) | gci | ft -a fullname,length,LastWriteTime ;
PS\>             (windiff $found.fullname $epfile.fullname) ;
PS\>             Read-Host "Press any key to continue .
. ." | Out-Null ;
PS\>         }else{write-host -foregroundcolor gray "(no match epspec:$($epspec))" } ; ;
PS\>     }else{write-host -foregroundcolor gray "(no match $($tfunc))" } ;
PS\> } ; 
Demo reviewing diffs between exported .ps1 files, and repo-tree c:\sc\* content, for commiting back as updates to the repo: 
Works from a text file with the updated function names (which are sls rgx matched as unindented lines in the file),
each of which are searched as filenames within the repositories root; 
on any match, the matching file is windif'd against the exported file for the function, and the loop is paused. 
This permits reviewing updates against the repo, and where material, the updated .ps1 can be copied back to the repo tree, for commit.
The appropriate copy-item -path & -dest values are part of the echo (as fullname properties).

## PARAMETERS

### -Path
Script/Module file(s) to be parsed \[path-to\script.ps1\]

```yaml
Type: FileInfo[]
Parameter Sets: (All)
Aliases: ParseFile

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Destination
Directory into which new \[functionname\]_func.ps1 files should be written\[-Destination path-to\\\]

```yaml
Type: DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoFunc
Switch to output exported functions without standard _func.ps1 suffix.\[-NoFunc\]

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

### -Include
String Array of function names to be included in export - the only functions found, that will be exported - from specified Path file.\[-Include @('func1','func2')\]

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Exclude
String Array of function names to be excluded from export, in specified Path file (defaults to '2b4','2b4c','fb4').\[-Exclude @('2b4','2b4c','fb4')\]

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: @('2b4','2b4c','fb4')
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeInternalFunctions
Switch to override default behavior - skip internal functions (as indicated by underscore prefix in function naame) - and instead export internal functions BOTH as part of their parent function, and as a separate function file\[-IncludeInternalFunctions)\]

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -whatIf
Whatif Flag  \[-whatIf\]

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

### system.io.fileinfo[] Accepts piped input for Path variable Array
## OUTPUTS

### System.String outputs count summary to pipeline
## NOTES
Version     : 0.0.1
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2025-10-07
FileName    : export-FunctionsToFilesTDO.ps1
License     : MIT License
Copyright   : (c) 2025 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,development,function,export
AddedCredit : REFERENCE
AddedWebsite: URL
AddedTwitter: URL
REVISIONS   :
* 12:26 PM 10/7/2025 add autocreate missing dest dir; cbh demo diffing exports against the repo tree for commit updates back;  port from get-FunctionBlocks(), works, add to vdev
* 2:53 PM 5/18/2022 $parsefile -\> $path, strong typed
# 5:55 PM 3/15/2020 fix corrupt ABC typo
# 10:21 AM 9/27/2019 just pull the functions in a file and pipeline them, nothing more.

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

