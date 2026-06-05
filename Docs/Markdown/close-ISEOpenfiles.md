
# close-ISEOpenfiles

## SYNOPSIS
close-ISEOpenfiles - Close all _saved_ open tabs in ISE

## SYNTAX

```
close-ISEOpenfiles [-Force] [[-Path] <String[]>] [-whatif] [<CommonParameters>]
```

## DESCRIPTION
close-ISEOpenfiles - Close all _saved_ open tabs in ISE

## EXAMPLES

### EXAMPLE 1
```
close-ISEOpenfiles
```

EXSAMPLEOUTPUT
Run with whatif & verbose

### EXAMPLE 2
```
write-verbose 'dump listing of fullpath of all open tabs, from which to pick -Path array targets' ;
```

PS\> show-ISEOpenTabPaths | sort | ?{$_ -match '_func\.ps1'} | close-ISEOpenFiles ; 
Demo use of the -Path spec (via pipeline) to close a list/subset of open files

### EXAMPLE 3
```
if ((gcm close-ISEOpenfiles -ea 0) -AND -not($psISE.CurrentPowerShellTab.AddOnsMenu.Submenus | Where-Object { $_.DisplayName -eq "Close All" })){
```

PS\>    $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Close All",{close-ISEOpenfiles},"")
PS\> } ;

## PARAMETERS

### -Force
Bypasses prompt

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

### -Path
Optional Path to filter against the ISE .files Fullname string (for direct ISE console use)\[-Path ' D:\scripts\show-ISEOpenTab_func.ps1'\]

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -whatif
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

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

### None. Does not accepted piped input.(.NET types, can add description)
## OUTPUTS

### None. Returns no objects or output (.NET types)
### System.Boolean
## NOTES
Version     : 0.0.
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2026-
FileName    : close-ISEOpenfiles.ps1
License     : MIT License
Copyright   : (c) 2026 Todd Kadrie
Github      : https://github.com/tostka/verb-XXX
Tags        : Powershell
AddedCredit : jdhitsolutions
AddedWebsite: https://github.com/jdhitsolutions/ISEScriptingGeek/
AddedTwitter: URL
REVISIONS
* 3:03 PM 4/29/2026 added -path, optional fullname spec for tabs to target (vs all tabs)
* 12:15 PM 4/9/2026 added -force; init, added psie check
* Jul 3, 2023 jdh posted vers

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

[https://github.com/jdhitsolutions/ISEScriptingGeek/](https://github.com/jdhitsolutions/ISEScriptingGeek/)

