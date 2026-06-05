
# converto-VSCConfig

## SYNOPSIS
converto-VSCConfig - Process a sample ISE debugging command line, and convert it to a VSC launch.json 'configurations' entry

## SYNTAX

```
converto-VSCConfig [-CommandLine] <Object> [-OneArgument] [-showDebug] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
converto-VSCConfig - Process a sample ISE debugging command line, and convert it to a VSC launch.json 'configurations' entry

## EXAMPLES

### EXAMPLE 1
```
$bRet = converto-VSCConfig -CommandLine $updatedContent -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
```

if (!$bRet) {Continue } ;

## PARAMETERS

### -CommandLine
CommandLine to be converted into a launch.json configuration

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

### -OneArgument
Flag to specify all arguments should be in a single unparsed entry\[-OneArgument\]

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

### None
## OUTPUTS

### Console dump & copy to clipboard, of model launch.json conversion of ISE Breakpoints xml file.
## NOTES
Version     : 1.1.0
Author      : Todd Kadrie
Website     : https://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2:58 PM 12/15/2019
FileName    :
License     : MIT License
Copyright   : (c) 2019 Todd Kadrie
Github      : https://github.com/tostka
AddedCredit :
AddedWebsite:
AddedTwitter:
REVISIONS
* 12:50 PM 6/17/2022 ren build-VSCConfig -\> converto-VSCConfig, alias orig name
* 7:50 AM 1/29/2020 added Cmdletbinding
* 9:14 AM 12/30/2019 added CBH .INPUTS & .OUTPUTS, including specific material returned.
* 5:51 PM 12/16/2019 added OneArgument param
* 2:58 PM 12/15/2019 INIT

## RELATED LINKS
