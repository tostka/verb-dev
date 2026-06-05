---

# get-FunctionBlocks

## SYNOPSIS
get-FunctionBlocks - All functions from the specified $Parsefile, output them directly to pipeline (capture on far end & parse/display)

## SYNTAX

```
get-FunctionBlocks [-Path] <FileInfo> [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
get-FunctionBlocks -Parse C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
```

Pull/display the Add-EMSRemote function from the specified .ps1, using named params

### EXAMPLE 2
```
$funcs = get-FunctionBlocks C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
```

$funcs |?{$_.name -eq 'get-lastwake'} | format-list name,body
Pull ALL functions, and post-filter return for specific function, and dump the name & body to console.

### EXAMPLE 3
```
$funcs = get-FunctionBlocks C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
```

($funcs |?{$_.name -eq 'get-lastwake'}).Extent.text
Pull ALL functions, and post-filter return for specific function, and dump the extent.text (body) to console.

### EXAMPLE 4
```
$funcs = get-FunctionBlocks C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
```

foreach($func in $funcs){
  $sPre="$("=" * 50)\`n#*------v Function $($func.name) from Script:$($ParseFile) v------" ;
  $sPost="#*------^ END Function $($func.name) from Script:$($ParseFile) ^------ ;\`n$("=" * 50)" ;
  $sOut = $null ;
  $sOut += "$($sPre)\`nFunction $($func.name) " ;
  $sOut += "$($func.Body) $($sPost)" ;
  write-host $sOut
} ;
Output a formatted block of Name & Bodies (approx the get-FunctionBlock())

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
## NOTES
Author: Todd Kadrie
Based on Code by: Philip Giuliani (broken example), functional AST code & example by Bartek Bielawski
Website:	http://tinstoys.blogspot.com
Twitter:	http://twitter.com/tostka
REVISIONS   :
* 9:38 AM 10/7/2025 CBH added leading tag for 1st demo
* 2:53 PM 5/18/2022 $parsefile -\> $path, strong typed
# 5:55 PM 3/15/2020 fix corrupt ABC typo
# 10:21 AM 9/27/2019 just pull the functions in a file and pipeline them, nothing more.

## RELATED LINKS

[https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/](https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/)

