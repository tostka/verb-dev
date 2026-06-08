
# get-ISEBreakPointsThisTab

## SYNOPSIS
get-ISEBreakPointsThisTab - Get-PSBreakPoint for solely the current focused ISE Open Tab (fltered on -script param)

## SYNTAX

```
get-ISEBreakPointsThisTab [<CommonParameters>]
```

## DESCRIPTION
get-ISEBreakPointsThisTab - Get-PSBreakPoint for solely the current focused ISE Open Tab (fltered on -script param)

## EXAMPLES

### EXAMPLE 1
```
get-ISEBreakPointsThisTab | ft -a ;
```

ID Script                        Line Command Variable Action
    -- ------                        ---- ------- -------- ------
    70 test-ExoDnsRecordTDO_func.ps1  237                        
    71 test-ExoDnsRecordTDO_func.ps1  256                        
    ... 
 

Export all 'line'-type breakpoints on the current open ISE tab, to a matching xml file

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Version     : 1.0.0
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2024-07-11
FileName    : get-ISEBreakPointsThisTab
License     : MIT License
Copyright   : (c) 2024 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging
REVISIONS
* 7:41 AM 4/13/2026 ren get-ISEBreakPoints-\> get-ISEBreakPointThisTab; add alias get-PSBreakPointThisTab
* 2:27 PM 7/11/2024 init

## RELATED LINKS

[Github      : https://github.com/tostka]()

