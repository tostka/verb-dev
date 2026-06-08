---

# get-AliasAssignsAST

## SYNOPSIS
get-AliasAssignsAST - All Alias assigns ((set|new)-Alias) from the specified $Parsefile, output them directly to pipeline (capture on far end & parse/display)

## SYNTAX

```
get-AliasAssignsAST [-Path] <FileInfo> [<CommonParameters>]
```

## DESCRIPTION
get-AliasAssignsAST - All Alias assigns ((set|new)-Alias) from the specified $Parsefile, output them directly to pipeline (capture on far end & parse/display)

## EXAMPLES

### EXAMPLE 1
```
$aliasAssigns = get-AliasAssignsAST C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
```

$aliasassigns | ?{$_ -like '*get-ScriptProfileAST*'}
Pull ALL Alias Assignements, and post-filter return for specific Alias Definition/Value.

## PARAMETERS

### -Path
Script to be parsed \[path-to\script.ps1\]

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases: ParseFile

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Accepts piped input.
## OUTPUTS

### None. Returns matched Function block to pipeline.
### get-AliasAssignsAST -Parse C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
### Pull/display the Add-EMSRemote function from the specified .ps1, using named params
## NOTES
Author: Todd Kadrie
Based on Code by: Philip Giuliani (broken example), functional AST code & example by Bartek Bielawski
Website:	http://tinstoys.blogspot.com
Twitter:	http://twitter.com/tostka
REVISIONS   :
# 9:55 AM 5/18/2022 add ported variant of get-functionblocks()

## RELATED LINKS

[https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/](https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/)

