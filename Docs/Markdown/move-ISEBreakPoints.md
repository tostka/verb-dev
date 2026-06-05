
# move-ISEBreakPoints

## SYNOPSIS
move-ISEBreakPoints - Offset current ISE tab's existing breakpoints by lines specified

## SYNTAX

```
move-ISEBreakPoints [-lines] <Int32> [<CommonParameters>]
```

## DESCRIPTION
move-ISEBreakPoints - Offset current ISE tab's existing breakpoints by lines specified

## EXAMPLES

### EXAMPLE 1
```
move-ISEBreakPoints -lines -4
```

Shift all existing PSBreakpoints UP 4 lines

### EXAMPLE 2
```
move-ISEBreakPoints -lines 5
```

Shift all existing PSBreakpoints DOWN 5 lines

## PARAMETERS

### -lines
Enter lines +/- to shift breakpoints on current script\[-lines -3\]

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Version     : 1.0.0.
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2020-08-25
FileName    : move-ISEBreakPoints
License     : MIT License
Copyright   : (c) 2022 Todd Kadrie
Github      : https://github.com/tostka
Tags        : Powershell,ISE,development,debugging
REVISIONS
* 3:29 PM 12/4/2023 new alias using proper std suffix for move == 'm': mIseBP.
Technically it should be mbp (like sbp), but that's too short to be safe; too likely to accidentlaly trigger on console.
* 3:05 PM 9/7/2022 ren & alias orig name shift-ISEBreakPoints -\> move-ISEBreakPoints
* 10:49 AM 8/25/2020 init, added to verb-dev module

## RELATED LINKS

[Github      : https://github.com/tostka]()

