
# Show-ObjectTDO

## SYNOPSIS
Show-ObjectTDO() - Displays an object's values and the 'dot' paths to them

## SYNTAX

```
Show-ObjectTDO [-TheObject] <Object> [[-depth] <Int32>] [[-Avoid] <Object[]>] [[-Parent] <String>]
 [[-CurrentDepth] <Int32>] [[-reportNodes] <Int32>] [[-ordered] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Show-ObjectTDO() - Displays an object's values and the 'dot' paths to them
A detailed description of the Display-Object function.

## EXAMPLES

### EXAMPLE 1
```
Show-objectTDO (get-date);
```

Path                Value
    ----                -----
    $.Date              5/28/2026 12:00:00 AM
    $.Day               28
    $.DayOfWeek.value__ 4
    $.DayOfYear         148
    $.Hour              12
    $.Kind.value__      2
    $.Millisecond       58
    $.Minute            21
    $.Month             5
    $.Second            46
    $.Ticks             639155677060581841
    $.TimeOfDay         12:21:46.0581841
    $.Year              2026    

Demo 
PS\> get-date| Show-ObjectTDO ; 
Pipeline Demo (output matches above)
PS\> $current=Dir $pwd; Show-ObjectTDO $current ; 
Demo using a variable

## PARAMETERS

### -TheObject
The object that you wish to display

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -depth
the depth of recursion (keep it low!)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### -Avoid
an array of names of pbjects or arrays you wish to avoid.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: @('#comment')
Accept pipeline input: False
Accept wildcard characters: False
```

### -Parent
For internal use, but you can specify the name of the variable

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: $
Accept pipeline input: False
Accept wildcard characters: False
```

### -CurrentDepth
For internal use

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -reportNodes
Do you wish to report on nodes containing objects as well as values?

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ordered
(doesn't appear to be used in the function??)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Accepts pipeline input.
## OUTPUTS

### System.Array returns array of matched file properties ('Name','FullName','Extension','Length','LastWriteTime','LinkType','PSParentPath','PSPath','Directory')
## NOTES
Version     : 0.0.
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2026-
FileName    : Show-ObjectTDO.ps1
License     : (none asserted)
Copyright   : (none asserted)
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,Git,SourceControl,Diff,format
AddedCredit : Phil-Factor
AddedWebsite: https://www.leeholmes.com/using-powershell-to-compare-diff-files/
AddedTwitter: URL
REVISIONS
* 9:24 AM 5/28/2026 init, ren Diff-Objects -\> Show-Object (use std verb) ; minor formatting tweaks, updated CBH, added proc{}; added -DiffStyle, to flip from added/deleted -\> +/-; added == support which prefixes \s.
* 7/7/21 Phil-Factor blog post example

## RELATED LINKS

[https://www.red-gate.com/simple-talk/blogs/display-object-a-powershell-utility-cmdlet/](https://www.red-gate.com/simple-talk/blogs/display-object-a-powershell-utility-cmdlet/)

[https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/Display-Object/Display-Object.ps1](https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/Display-Object/Display-Object.ps1)

[https://github.com/tostka/verb-io

[CmdletBinding(DefaultParameterSetName="NoExpectation")]]()

