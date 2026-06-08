
# import-ISEOpenFiles

## SYNOPSIS
import-ISEOpenFiles - Import/Re-Open a list of all ISE tab files, from CU Documents\WindowsPowershell\Scripts\ISESavedSession.psXML file

## SYNTAX

```
import-ISEOpenFiles [[-Tag] <String>] [-FilePath <FileInfo[]>] [<CommonParameters>]
```

## DESCRIPTION
import-ISEOpenFiles - Import/Re-Open a list of all ISE tab files, from CU Documents\WindowsPowershell\Scripts\ISESavedSession.psXML file
Quick bulk dump, when ISE ineveitbly stops properly echo'ing variable values to terminal (and need to close and re-open all open files)

## EXAMPLES

### EXAMPLE 1
```
import-ISEOpenFiles -verbose
```

Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif

### EXAMPLE 2
```
import-ISEOpenFiles -Tag 2 -verbose
```

Export with Tag '2' applied to filename (e.g.
"ISESavedSession2.psXML")

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

### -FilePath
Optional FullName path to prior export-ISEOpenFiles pass\[-FilePath \`$env:userprofile\Documents\WindowsPowershell\Scripts\ISESavedSession-DEV.psXML

```yaml
Type: FileInfo[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
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
FileName    : import-ISEOpenFiles
License     : MIT License
Copyright   : (c) 2022 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging
REVISIONS
* 9:06 PM 8/12/2025 added code to create CUScripts if missing
* 8:30 AM 3/26/2024 chg iIseOpen -\> ipIseOpen
* 3:31 PM 1/17/2024 typo fix: lacking $ on () (dumping $ISES obj into pipeline/console)
* 1:20 PM 3/27/2023 bugfix: coerce $txmlf into \[system.io.fileinfo\], to make it match $fileinfo's type.
* 9:35 AM 3/8/2023 added -filepath (with pipeline support), explicit pathed file support (to pipeline in from get-IseOpenFilesExported()).
* 3:28 PM 6/23/2022 add -Tag param to permit running interger-suffixed variants (ie.
mult ise sessions open & stored from same desktop). 
* 9:19 AM 5/20/2022 add: iIseOpen alias (using these a lot lately; w freq crashouts of ise, and need to recover all files open & BPs to quickly get back to function)
* 12:12 PM 5/11/2022 init

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

