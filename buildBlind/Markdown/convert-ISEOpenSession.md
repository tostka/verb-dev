
# convert-ISEOpenSession

## SYNOPSIS
convert-ISEOpenSession - Converts remote devbox ISE debugging session (CU\documents\windowspowershell\scripts\ISESavedSession.psXML), and associated Breakpoint files (-ps1-BP.xml) to local use, converting stored paths.

## SYNTAX

```
convert-ISEOpenSession [[-FileName] <String>] [-devbox <String>] [-Rfolder <String>] [-Lfolder <String>]
 [-SID <Object>] [-Push] [-Pull] [-whatif] [<CommonParameters>]
```

## DESCRIPTION
convert-ISEOpenSession - Converts remote devbox ISE debugging session (CU\documents\windowspowershell\scripts\ISESavedSession.psXML), and associated Breakpoint files (-ps1-BP.xml) to local use, converting stored paths.

## EXAMPLES

### EXAMPLE 1
```
convert-ISEOpenSession -pull -verbose ;
```

Demo -pull: remote $devbox C:\Users\ACCT\Documents\WindowsPowerShell\Scripts\ISESavedSession.psXML, of files, copy to local machine, along with any matching -ps1-BP.xml files, then post-conversion of the .psxmls and BP.xml files to translating remote $rpath paths to local $lpath paths, with verbose output

### EXAMPLE 2
```
convert-ISEOpenSession -push -verbose ;
```

Demo -push: from local workstation to remote $devbox, C:\Users\ACCT\Documents\WindowsPowerShell\Scripts\ISESavedSession.psXML of files, copy to $devbox, along with any matching -ps1-BP.xml files, then post-conversion of the .psxmls and BP.xml files to translating local $lpath paths to remote $rpath paths, with verbose output

## PARAMETERS

### -FileName
Filename for ISESadSession.psxml file to be processed (SID CU\docs\winPS\Scripts assumed))\[-FileName ISESavedSession.psXML

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: ISESavedSession.psXML
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -devbox
Remote dev box computername \[-devbox c:\pathto\file\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $AdminJumpBox
Accept pipeline input: False
Accept wildcard characters: False
```

### -Rfolder
Remote dev box stock script storage path \[-Rfolder c:\pathto\\\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: D:\scripts\
Accept pipeline input: False
Accept wildcard characters: False
```

### -Lfolder
Local stock script storage path \[-Lfolder c:\pathto\\\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: C:\usr\work\o365\scripts\
Accept pipeline input: False
Accept wildcard characters: False
```

### -SID
Account from Remote devbox, to be copied from\[-SID logonid

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $TorMeta.logon_SID.split('\')[1]
Accept pipeline input: False
Accept wildcard characters: False
```

### -Push
Switch to Pull content FROM -DevBox\[-Push\]

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

### -Pull
Switch to Push content TO -Devbbox\[-Pull\]

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

### -whatif
Switch to suppress explicit resolution of share (e.g.
wrote conversion wo validation converted share exists on host)\[-NoValidate\]

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

### Accepts piped input.
## OUTPUTS

### System.String
## NOTES
Author      : Todd Kadrie
Website     :	http://www.toddomation.com
Twitter     :	@tostka / http://twitter.com/tostka
CreatedDate : 2022-07-26
FileName    : convert-ISEOpenSession.ps1
License     : MIT License
Copyright   : (c) 2022 Todd Kadrie
Tags        : Powershell,FileSystem,Network
REVISIONS   :
* 5:02 PM 9/7/2022 fully debugged both push & pull, looks done ; debugged push fully; updated push/pull logic on rfile & lfiles; fixed bug in destfile gen code for push; added END block (largely for tailing bp target);  debugged Pull fully; added exemption for CU/AU/System installed modules/scripts, to avoid improper copy back (should be manually pulled over at the include file level).
Need to debug Push.
* 4:43 PM 8/30/2022 debugged(?)
* 2:02 PM 8/25/2022 init

## RELATED LINKS

[https://github.com/tostka/verb-IO\](https://github.com/tostka/verb-IO\)

