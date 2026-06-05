
# save-ISEOpenfiles

## SYNOPSIS
save-ISEOpenfiles - Save all open tabs in ISE

## SYNTAX

```
save-ISEOpenfiles [<CommonParameters>]
```

## DESCRIPTION
save-ISEOpenfiles - Save all open tabs in ISE

## EXAMPLES

### EXAMPLE 1
```
save-ISEOpenfiles
```

EXSAMPLEOUTPUT
Run with whatif & verbose

### EXAMPLE 2
```
# updated, precheck existing before blindly adding
```

PS\> if ((gcm save-ISEOpenfiles --ea 0) -AND -not($psISE.CurrentPowerShellTab.AddOnsMenu.Submenus | Where-Object { $_.DisplayName -eq "Save All" })){
PS\>    $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Save All",{save-ISEOpenfiles},"Ctrl+Shift+S")
PS\> } ;

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Does not accepted piped input.(.NET types, can add description)
## OUTPUTS

### None. Returns no objects or output (.NET types)
## NOTES
Version     : 0.0.
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2026-
FileName    : save-ISEOpenfiles.ps1
License     : MIT License
Copyright   : (c) 2026 Todd Kadrie
Github      : https://github.com/tostka/verb-XXX
Tags        : Powershell
AddedCredit : jdhitsolutions
AddedWebsite: https://github.com/jdhitsolutions/ISEScriptingGeek/
AddedTwitter: URL
REVISIONS
* 1:12 PM 5/4/2026 added demo mnu add
* 3:00 PM 4/14/2026 the presave portion of close-iseopenfiles

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

[https://github.com/jdhitsolutions/ISEScriptingGeek/](https://github.com/jdhitsolutions/ISEScriptingGeek/)

