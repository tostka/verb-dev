
# Out-ISETab

## SYNOPSIS
Out-ISETab.ps1 - Runs specified input (pipeline) into a Tab in ISE (new tab, default, -currenttab if specified)

## SYNTAX

```
Out-ISETab [-InputObject] <Object[]> [-UseCurrentFile] [<CommonParameters>]
```

## DESCRIPTION
Out-ISETab.ps1 - Runs specified input (pipeline) into a Tab in ISE (new tab, default, -currenttab if specified)

## EXAMPLES

### EXAMPLE 1
```
gc d:\scripts\out-iseTab_func.ps1 | Out-ISETab
```

Demo pipeline content from a script file, creates a new tab in current ISE and populates the tab with the inbound content

### EXAMPLE 2
```
gc d:\scripts\out-iseTab_func.ps1 | Out-ISETab -currentfile
```

Demo above but recycles the current open tab/file as the destination

## PARAMETERS

### -InputObject
{{ Fill InputObject Description }}

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -UseCurrentFile
{{ Fill UseCurrentFile Description }}

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

### object[]
### Accepts pipeline input
## OUTPUTS

### None. Returns no objects or output (.NET types)
## NOTES
Version     : 0.0.
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2026-
FileName    : Out-ISETab.ps1
License     : MIT License
Copyright   : (c) 2026 Todd Kadrie
Github      : https://github.com/tostka/verb-XXX
Tags        : Powershell
AddedCredit : jdhitsolutions
AddedWebsite: https://github.com/jdhitsolutions/ISEScriptingGeek/
AddedTwitter: URL
REVISIONS
* 10:13 AM 4/9/2026 init
* Jul 3, 2023 jdh posted vers

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

[https://github.com/jdhitsolutions/ISEScriptingGeek/](https://github.com/jdhitsolutions/ISEScriptingGeek/)

