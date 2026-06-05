
# get-VersionInfo

## SYNOPSIS
get-VersionInfo.ps1 - get-VersionInfo.ps1 - Extract comment-help .NOTES block into a hashtable, key-value split on colons, to provide portable metadata (for New/Update-ScriptFileInfo inputs).

## SYNTAX

```
get-VersionInfo [[-Path] <Object>] [-showDebug] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
get-VersionInfo.ps1 - Extract comment-help .NOTES block into a hashtable, key-value split on colons, to provide portable metadata (for New/Update-ScriptFileInfo inputs).

## EXAMPLES

### EXAMPLE 1
```
.\get-VersionInfo
```

Default process from $PSCommandPath

### EXAMPLE 2
```
.\get-VersionInfo -Path .\path-to\script.ps1 -verbose:$VerbosePreference
```

Explicit file via -Path

## PARAMETERS

### -Path
Path to target script (defaults to $PSCommandPath)

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -showDebug
Parameter to display Debugging messages \[-ShowDebug switch\]

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

### -whatIf
Whatif Flag  \[-whatIf\]

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

### None
## OUTPUTS

### Returns a hashtable of key-value pairs for each of the entries in the .NOTES CBH block in a given file.
## NOTES
Version     : 0.2.0
Author      : Todd Kadrie
Website     :	https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
CreatedDate : 02/07/2019
License     : MIT License
Copyright   : (c) 2019 Todd Kadrie
AddedCredit : Based on code & concept by Alek Davis
AddedWebsite:	https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
AddedTwitter:
REVISIONS
* 3:47 PM 4/14/2020 substantially shifted role to parseHelp(), which is less brittle and less likely to fail the critical get-help call that underlies the parsing. 
* 7:50 AM 1/29/2020 added Cmdletbinding
* 9:36 AM 12/30/2019 added CBH .INPUTS & OUTPUTS, including description of the hashtable of key/value pairs returned, for existing CBH .NOTES block
* added explicit -path param to get-help
* 8:39 PM 11/21/2019 added test for returned get-help
* 8:27 AM 11/5/2019 Todd rework: Added Path param, parsed to REVISIONS: block, & return the top rev as LastRevision key in returned object.
* 02/07/2019 Posted version

## RELATED LINKS

[https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number](https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number)

