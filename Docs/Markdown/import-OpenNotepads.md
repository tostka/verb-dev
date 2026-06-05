
# import-OpenNotepads

## SYNOPSIS
import-OpenNotepads - Import & open a previously-exported list of  Notepad* variant (notepad2/3 curr) sessions

## SYNTAX

```
import-OpenNotepads [[-File] <FileInfo[]>] [[-Tag] <String>] [[-DefaultProcessName] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
import-OpenNotepads - Import & open a previously-exported list of  Notepad* variant (notepad2/3 curr) sessions

## EXAMPLES

### EXAMPLE 1
```
import-opennotepads -File 'C:\Users\kadrits\OneDrive - The Toro Company\Documents\WindowsPowershell\Scripts\data\NotePdSavedSession-20250702-1120AM.psXML' -verbose
```

Demo using a full path specification to the target import file

### EXAMPLE 2
```
import-opennotepads -Tag '20250702-1120AM'   -verbose
```

Demo targeting an exported file based on the trailing Tag suffix

## PARAMETERS

### -File
Path to an exported .psxml file reflecting previously opened Notepad* variant windows & documents, to be reopened.

```yaml
Type: FileInfo[]
Parameter Sets: (All)
Aliases: PsPath

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Tag
Variant to specify targeting a Tag (filename suffix - portion after the std 'NotePdSavedSession-' of filename, wo .psxml extension, which by default is a timestamp, if no export -Tag was specified)\[-tag 'label'\]

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

### -DefaultProcessName
ProcessName (as returned by get-process) for the default associated app for .txt files (defaults to notepad2, used to pre-collect existing open files for dupe suppression)\[-DefaultProcessName 'notepad3'\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Notepad2
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Version     : 1.0.0.
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2025-07-02
FileName    : import-OpenNotepads.ps1
License     : MIT License
Copyright   : (c) 2020 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging
REVISIONS
* 1:00 PM 11/20/2025 added support for edit flags (*\s), optional, as part of dupe suppress
    added dupe-suppression, both retroactively - searches launched process.mainwindowtitle for array status, closes all but oldest id - and proactively - 
    runs a collection of processname-filtered existing processes, and appends the newly opened to the list, then builds and checks for each filename in the MainWindowTitle list, skipping open dupes.
* 2:21 PM 7/2/2025 works init

## RELATED LINKS

[Github      : https://github.com/tostka]()

