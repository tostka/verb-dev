---

# get-FunctionBlock

## SYNOPSIS
get-FunctionBlock - Retrieve the specified $functionname function block from the specified $Parsefile.

## SYNTAX

```
get-FunctionBlock [-Path] <FileInfo> [-functionName] <Object> [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
get-FunctionBlock C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 Add-EMSRemote ;
```

Pull/display the Add-EMSRemote function from the specified .ps1, using positional params

### EXAMPLE 2
```
get-FunctionBlock -Parse C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 -Func Add-EMSRemote ;
```

Pull/display the Add-EMSRemote function from the specified .ps1, using named params

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

### -functionName
Function name to be found and displayed from ParseFile

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Does not accepted piped input.
## OUTPUTS

### None. Returns matched Function block to pipeline.
## NOTES
Author: Todd Kadrie
Based on Code by: Philip Giuliani (broken example), functional AST code & example by Bartek Bielawski
Website:	http://tinstoys.blogspot.com
Twitter:	http://twitter.com/tostka
REVISIONS   :
* 2:51 PM 5/18/2022 updated parsefile -\> path, and strong typed
# 10:07 AM 9/27/2019 ren'd GetFuncBlock -\> get-FunctionBlock & tighted up, added named param expl
3:19 PM 8/31/2016 - initial version, functional

## RELATED LINKS

[https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/](https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/)

