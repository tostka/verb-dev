
# get-ISEOpenFilesExported

## SYNOPSIS
get-ISEOpenFilesExported - List CU profile .\Documents\WindowsPowerShell\Scripts\*.psXML files, reflecting prior exports via export-ISEOpenFiles, as targets for import via import-ISEOpenFiles

## SYNTAX

```
get-ISEOpenFilesExported [[-Tag] <String>] [<CommonParameters>]
```

## DESCRIPTION
get-ISEOpenFilesExported - List CU profile .\Documents\WindowsPowerShell\Scripts\*.psXML files, reflecting prior exports via export-ISEOpenFiles, as targets for import via import-ISEOpenFiles
Returns list of string filepaths to pipeline, for further filtering, and passage to import-ISEOpenFiles

## EXAMPLES

### EXAMPLE 1
```
get-ISEOpenFilesExported -verbose
```

Find any pre-existing exported ISESavedSession*.psXML files (those exported via export-ISEOpenFiles)

### EXAMPLE 2
```
get-ISEOpenFilesExported -Tag MFA -verbose
```

Find any pre-existing exported ISESavedSession*MFA*.psXML files (those exported with -Tag MFA)

### EXAMPLE 3
```
get-ISEOpenFilesExported -Tag MFA | import-ISEOpenFiles ;
```

Example pipelining the outputs into import-ISEOPenFiles() (via pipeline support for it's -FilePath param)

### EXAMPLE 4
```
get-ISEOpenFilesExported | %{gci $_} | sort LastWriteTime | ft -a fullname,lastwritetime ;
```

Example finding the 'latest' (newest LastWritTime) and echoing for review

### EXAMPLE 5
```
get-ISEOpenFilesExported | %{gci $_} | sort LastWriteTime | select -last 1 | select -expand fullname | import-ISEOpenFiles ;
```

Example finding the 'latest' (newest LastWritTime), and then importing into ISE.

### EXAMPLE 6
```
get-ISEOpenFilesExported | %{gci $_} | sort LastWriteTime | ? LastWriteTime -gt (get-date '5/11/2025')  | %{[xml]$xml = gc $_.fullname ; write-host -foregroundcolor green "`n====$($_.name)`n$(($xml.Objs.S|out-string).trim())`n===" ; }
```

Dump summary of names & files contained, in most recent after spec'd time, sorted on LastWriteTime

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
FileName    : get-ISEOpenFilesExported.ps1
License     : MIT License
Copyright   : (c) 2022 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging
REVISIONS
* 12:25 PM 4/9/2026 rem'd $psise test - it's not required, no calls to the psies obj occurs
* 1:55 PM 5/29/2025 add expl dumping report of name & the constituent files in most recent exports
* 9:24 AM 9/14/2023 CBH add:demo of pulling lastwritetime and using to make automatd decisions, or comparison reporting (as this returns a fullname, not a file object)
* 1:55 PM 3/29/2023 flipped alias (clashed) iIseOpen -\> gIseOpen
* 8:51 AM 3/8/2023 init

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

