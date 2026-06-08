
# test-VerbStandard

## SYNOPSIS
test-VerbStandard.ps1 - Test specified verb for presense in the PS get-verb list.

## SYNTAX

```
test-VerbStandard [-Verb] <String> [<CommonParameters>]
```

## DESCRIPTION
test-VerbStandard.ps1 - Test specified verb for presense in the PS get-verb list.

## EXAMPLES

### EXAMPLE 1
```
'New' | test-VerbStandard ;
```

Test the string as a standard verb

### EXAMPLE 2
```
gcm -mod verb-io | ? commandType -eq 'Function' | select -expand verb -unique | test-verbstandard -verbo
```

Collect all unique verbs for functions in the verb-io module, and test against MS verb standard

## PARAMETERS

### -Verb
Verb string to be tested\[-verb report\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Accepts piped input.
## OUTPUTS

### Boolean
## NOTES
Version     : 1.0.0
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2021-01-20
FileName    : test-VerbStandard.ps1
License     : MIT License
Copyright   : (c) 2022 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,development,verbs
REVISION
* 3:00 PM 7/20/2022 init

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

