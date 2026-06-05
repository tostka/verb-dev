
# convertTo-UnwrappedPS

## SYNOPSIS
convertTo-UnwrappedPS - Unwrap a a Powershell ScriptBlock at _preexisting_ semi-colon (;) delimiters (does not add semicolons or otherwise attempt to parse the scriptblock into definited lines; just adds CrLF's following the semicolons).

## SYNTAX

```
convertTo-UnwrappedPS [[-ScriptBlock] <String>] [<CommonParameters>]
```

## DESCRIPTION
convertTo-UnwrappedPS - Unwrap a a Powershell ScriptBlock at _preexisting_ semi-colon (;) delimiters (does not add semicolons or otherwise attempt to parse the scriptblock into definited lines; just adds CrLF's following the semicolons).

## EXAMPLES

### EXAMPLE 1
```
$text=convertTo-UnwrappedPS -ScriptBlock "write-host 'yea';`ngci 'c:\somefile.txt';" ;
```

Unwrap the specified scriptblock at the semicolons.

## PARAMETERS

### -ScriptBlock
Semi-colon-delimited ScriptBlock of powershell to be wrapped at

```yaml
Type: String
Parameter Sets: (All)
Aliases: Code

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Version     : 1.0.0
Author      : Todd Kadrie
Website     :	http://www.toddomation.com
Twitter     :	@tostka / http://twitter.com/tostka
CreatedDate : 2021-11-08
FileName    : convertTo-UnwrappedPS.ps1
License     : MIT License
Copyright   : (c) 2020 Todd Kadrie
Github      : https://github.com/tostka/verb-text
Tags        : Powershell,Text
AddedCredit : REFERENCE
AddedWebsite:	URL
AddedTwitter:	URL
REVISIONS
* 12:44 PM 6/17/2022 update CBH; move verb-text -\> verb-dev
* 9:38 AM 11/22/2021 ren unwrap-ps -\> convertTo-UnwrappedPS 
* 11:09 AM 11/8/2021 init

## RELATED LINKS

[https://github.com/tostka/verb-Text](https://github.com/tostka/verb-Text)

