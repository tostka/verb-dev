
# new-CBH

## SYNOPSIS
new-CBH - Parse Script and prepend new Comment-based-Help keyed to existing contents

## SYNTAX

```
new-CBH [-Path] <Object> [-showDebug] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
new-CBH - Parse Script and prepend new Comment-based-Help keyed to existing contents

## EXAMPLES

### EXAMPLE 1
```
$updatedContent = new-CBH -Path $oSrc.fullname -showdebug:$($showdebug) -whatif:$($whatif) ;
```

## PARAMETERS

### -Path
Path to script

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
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
Website     : https://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 3:45 PM 11/16/2019
FileName    :
License     : MIT License
Copyright   : (c) 2019 Todd Kadrie
Github      : https://github.com/tostka
Tags        : Powershell,Development,Scripts
REVISIONS
* 11:38 AM 4/14/2020 flipped filename from fullname to name
* 4:42 PM 4/9/2020 ren NewCBH-\> new-CBH shift into verb-Dev.psm1
* 9:12 PM 11/25/2019 new-CBH: added dummy parameter name fields - drop them and you get no CBH function
* 6:47 PM 11/24/2019 new-CBH: got revision of through a full pass of adding a new CBH addition to a non-compliant file.
* 3:48 PM 11/16/2019 INIT

## RELATED LINKS
