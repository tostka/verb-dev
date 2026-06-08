
# import-ISEBreakPoints

## SYNOPSIS
import-ISEBreakPoints - Import the 'Line' ise breakpoints previously cached to an XML file

## SYNTAX

```
import-ISEBreakPoints [[-PathDefault] <String>] [[-Script] <String>] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
import-ISEBreakPoints - Import the 'Line' ise breakpoints previously cached to an XML file
By default, attempts to save to the same directory as the script, but if the directory specified doesn't exist, it redirects the save to the c:\scripts dir.

## EXAMPLES

### EXAMPLE 1
```
import-ISEBreakPoints -verbose -whatif
```

Import all 'line'-type breakpoints into the current open ISE tab, from matching xml file, , with verbose output, and whatif

### EXAMPLE 2
```
Import-ISEBreakPoints -Script c:\path-to\script.ps1
```

Import all 'line'-type breakpoints into the specified script, from matching xml file

## PARAMETERS

### -PathDefault
Default Path for export (when \`$Script directory is unavailable)\[-PathDefault c:\path-to\\\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: C:\scripts
Accept pipeline input: False
Accept wildcard characters: False
```

### -Script
Path to target Script file (defaults to Current ISE Tab fullpath)\[-Script c:\path-to\file.ext\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
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
Version     : 1.0.0.
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2020-08-25
FileName    : import-ISEBreakPoints
License     : MIT License
Copyright   : (c) 2020 Todd Kadrie
Github      : https://github.com/tostka
Tags        : Powershell,ISE,development,debugging
REVISIONS
* 8:28 AM 3/26/2024 chg iIseBp -\> ipIseBP
* 10:20 AM 5/11/2022 added whatif support
* 8:58 AM 5/9/2022 err suppress: test for bps before importing (emtpy bp xml files happen)
* 8:43 AM 8/26/2020 fixed typo $ibp\[0\]-\>$ibps\[0\]
* 1:45 PM 8/25/2020 fix bug in import code ; init, added to verb-dev module

## RELATED LINKS

[Github      : https://github.com/tostka]()

