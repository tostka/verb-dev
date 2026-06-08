
# export-ISEOpenFiles

## SYNOPSIS
export-ISEOpenFiles - Export a list of all currently open ISE tab files, to CU \WindowsPowershell\Scripts\ISESavedSession.psXML file

## SYNTAX

```
export-ISEOpenFiles [[-Tag] <String>] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
export-ISEOpenFiles - Export a list of all currently open ISE tab files, to CU \WindowsPowershell\Scripts\ISESavedSession.psXML file
Quick bulk dump, when ISE ineveitbly stops properly echo'ing variable values to terminal (and need to close and re-open all open files)

## EXAMPLES

### EXAMPLE 1
```
export-ISEOpenFiles -verbose -whatif
```

Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif

### EXAMPLE 2
```
export-ISEOpenFiles -Tag 'mfa' -verbose -whatif
```

Export with Tag 'mfa' applied to filename (e.g.
"ISESavedSession-MFA.psXML")

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
CreatedDate : 2022-05-11
FileName    : export-ISEOpenFiles
License     : MIT License
Copyright   : (c) 2022 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging
REVISIONS
* 9:06 PM 8/12/2025 added code to create CUScripts if missing
* 8:31 AM 3/26/2024 chg eIseOpen -\> epIseOpen
* 3:28 PM 6/23/2022 add -Tag param to permit running interger-suffixed variants (ie.
mult ise sessions open & stored from same desktop). 
* 9:19 AM 5/20/2022 add: eIseOpen alias (using these a lot lately; w freq crashouts of ise, and need to recover all files open & BPs to quickly get back to function)
* 12:12 PM 5/11/2022 init

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

