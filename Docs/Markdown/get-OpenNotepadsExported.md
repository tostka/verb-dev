
# get-OpenNotepadsExported

## SYNOPSIS
get-OpenNotepadsExported - List CU profile .\Documents\WindowsPowerShell\Scripts\data\NotePdSavedSession*.psXML files, reflecting prior exports via export-OpenNotepads, as targets for import via import-OpenNotepads

## SYNTAX

```
get-OpenNotepadsExported [[-Tag] <String>] [<CommonParameters>]
```

## DESCRIPTION
get-OpenNotepadsExported - List CU profile .\Documents\WindowsPowerShell\Scripts\data\NotePdSavedSession*.psXML files, reflecting prior exports via export-OpenNotepads, as targets for import via import-OpenNotepads

Returns list of string filepaths to pipeline, for further filtering, and passage to import-OpenNotepads

## EXAMPLES

### EXAMPLE 1
```
get-OpenNotepadsExported -verbose
```

Find any pre-existing exported ISESavedSession*.psXML files (those exported via export-OpenNotepads)

### EXAMPLE 2
```
get-OpenNotepadsExported -Tag MFA -verbose
```

Find any pre-existing exported ISESavedSession*MFA*.psXML files (those exported with -Tag MFA)

### EXAMPLE 3
```
get-OpenNotepadsExported -Tag MFA | import-OpenNotepads ;
```

Example pipelining the outputs into import-OpenNotepads() (via pipeline support for it's -FilePath param)

### EXAMPLE 4
```
get-OpenNotepadsExported | %{gci $_} | sort LastWriteTime | ft -a fullname,lastwritetime ;
```

Example finding the 'latest' (newest LastWritTime) and echoing for review

### EXAMPLE 5
```
get-OpenNotepadsExported | %{gci $_} | sort LastWriteTime | select -last 1 | select -expand fullname | import-OpenNotepads ;
```

Example finding the 'latest' (newest LastWritTime), and then importing into ISE.

## PARAMETERS

### -Tag
Optional Tag to apply to as filename suffix\[-tag 'label'\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

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
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2022-05-11
FileName    : get-OpenNotepadsExported.ps1
License     : MIT License
Copyright   : (c) 2022 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging
REVISIONS
* 1:46 PM 7/2/2025 init, works

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

