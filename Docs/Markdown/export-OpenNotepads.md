
# export-OpenNotepads

## SYNOPSIS
export-OpenNotepads - Export a list of all currently open Notepad* variant (notepad2/3 curr) windows, to CU \WindowsPowershell\Scripts\data\NotePdSavedSession-....psXML file (uses -Tag if specified, otherwise timestamps the file)

## SYNTAX

```
export-OpenNotepads [[-Tag] <String>] [-rgxExclTitles <Regex>] [-rgxNPAppNames <Regex>] [-whatIf]
 [<CommonParameters>]
```

## DESCRIPTION
export-OpenNotepads - Export a list of all currently open Notepad* variant (notepad2/3 curr) windows, to CU \WindowsPowershell\Scripts\data\NotePdSavedSession-....

Goal is to quickest productive work state after a reboot (get all the open files back open for continued review and work)

Exports are in psXML files (xml) to the 'CurrentUserProfile\WindowsPowershell\Scripts\data\' directory:

- If a -Tag is specified, the exported summary is named  'NotePdSavedSession-$($Tag).psXML'

- If NO -Tag is specified, the exported summary is named with a timestamp in form: NotePdSavedSession-yyyyMMdd-HHmmtt.psXML

## EXAMPLES

### EXAMPLE 1
```
export-OpenNotepads -verbose -whatif
```

Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif

### EXAMPLE 2
```
export-OpenNotepads -Tag 'mfa' -verbose -whatif
```

Export with Tag 'mfa' applied to filename (e.g.
"ISESavedSession-MFA.psXML")

## PARAMETERS

### -Tag
Optional Tag to apply to as filename suffix (otherwise appends a timestamp)\[-tag 'label'\]

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

### -rgxExclTitles
Regex filter reflecting window MainWindowTitle strings to be excluded from exports (defaults to a stock filter)\[-rgxExclTitles '^((\*\s)*)(Untitled|input\.txt|tmp\.ps1|tmpL\.ps1)\s-\s'\]

```yaml
Type: Regex
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: ^((\*\s)*)(Untitled|input\.txt|tmp\.ps1|tmpL\.ps1)\s-\s
Accept pipeline input: False
Accept wildcard characters: False
```

### -rgxNPAppNames
Regex filter reflecting window MainWindowTitle Notepad* variant suffix strings to be targeted for exports (defaults to a stock filter)\[rgxNPAppNames '\s-\s(Notepad\s2e\sx64|Notepad3)'\]

```yaml
Type: Regex
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: \s-\s(Notepad\s2e\sx64|Notepad3)
Accept pipeline input: False
Accept wildcard characters: False
```

### -whatIf
Parameter to run a Test no-change pass \[-Whatif switch\]

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

## OUTPUTS

## NOTES
Version     : 1.0.0
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2025-07-02
FileName    : export-OpenNotepads.ps1
License     : MIT License
Copyright   : (c) 2025 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging
REVISIONS
* 1:53 PM 7/2/2025 converted to func;  init

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

