
# check-PsLocalRepoRegistration

## SYNOPSIS
check-PsLocalRepoRegistration - Check for PSRepository for $localPSRepo, register if missing

## SYNTAX

```
check-PsLocalRepoRegistration [-Repository] <Object> [-showDebug] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
check-PsLocalRepoRegistration - Check for PSRepository for $localPSRepo, register if missing

## EXAMPLES

### EXAMPLE 1
```
$bRet = check-PsLocalRepoRegistration -Repository $localPSRepo
```

Check registration on the repo defined by variable $localPSRepo

## PARAMETERS

### -Repository
Local Repository \[-Repository repoName\]

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: $localPSRepo
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
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Version     : 1.0.0
Author: Todd Kadrie
Website:	http://toddomation.com
Twitter:	http://twitter.com/tostka
CreatedDate : 2020-03-29
FileName    : check-PsLocalRepoRegistration
License     : MIT License
Copyright   : (c) 2020 Todd Kadrie
Github      : https://github.com/tostka
Tags        : Powershell,Git,Repository
REVISIONS
* 7:00 PM 3/29/2020 init

## RELATED LINKS
