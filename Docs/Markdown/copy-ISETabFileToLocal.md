
# copy-ISETabFileToLocal

## SYNOPSIS
copy-ISETabFileToLocal - Copy the currently open ISE tab file, to local machine (RDP remote only), prompting for local path.
The filename copied is either the intact local name, or, if -stripFunc is used, the filename with any _func substring removed.

## SYNTAX

```
copy-ISETabFileToLocal [[-Path] <FileInfo>] [-LocalDestination] <String> [-noFunc] [-whatIf]
 [<CommonParameters>]
```

## DESCRIPTION
copy-ISETabFileToLocal - Copy the currently open ISE tab file, to local machine (RDP remote only), prompting for local path.
The filename copied is either the intact local name, or, if -stripFunc is used, the filename with any _func substring removed. 
This also checks for a matching exported breakpoint file (name matches target script .ps1, with trailing name ...-ps1-BP.xml), and prompts to also move that file along with the .ps1.

## EXAMPLES

### EXAMPLE 1
```
copy-ISETabFileToLocal -verbose -whatif
```

Copy the current tab file to prompted local destination, whatif, with verbose output

### EXAMPLE 2
```
copy-ISETabFileToLocal -verbose -localdest C:\sc\verb-dev\public\ -noFunc -whatif
```

Copy the current tab file to explicit specified -LocalDesetination, replacing any _func substring from filename, with whatif, with verbose output

### EXAMPLE 3
```
copy-ISETabFileToLocal -Path d:\scripts\get-LastEvent_func.ps1 -LocalDestination C:\sc\verb-logging\public\ -noFunc -whatif
```

Copy specified -path source file to explicit specified -LocalDesetination, replacing any _func substring from filename, with whatif, with verbose output (used for debugging, when current tab file switch to be another file)

## PARAMETERS

### -Path
Path to source file (defaults to \`$psise.CurrentFile.FullPath)\[-Path 'D:\scripts\copy-ISETabFileToLocal_func.ps1'\]

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $psise.CurrentFile.FullPath
Accept pipeline input: False
Accept wildcard characters: False
```

### -LocalDestination
Localized destination directory path\[-path c:\pathto\\\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -noFunc
Switch to remove any '_func' substring from the original file name, while copying (used for copying to final module .\Public directory for publishing\[-noFunc\]

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
Whatif switch \[-whatIf\]

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
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2024-05-22
FileName    : copy-ISETabFileToLocal
License     : MIT License
Copyright   : (c) 2024 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging,backup
REVISIONS
* 2:17 PM 1/29/2026 add: test for nofunc into \public; added validates to try to prevent specifying leaf-path in the -LocalDestination, and a -Leaf in the -Path (burned trying to backup to a leaf, which bounced wo comment, leaving the file uncopied)
* 9:20 AM 2/10/2025 tweaked to permit non-tsclient-spanning use: supports copying from a separate generic debugging copy to local repo; 
    fixed inaccurate CBH expl (was rote copy from copy-iselocalsourcetotab()); fixed swapped error msgs at bottom of PROC{}
* 3:55 PM 10/25/2024 added cbh demo using -path ; pulled -path container validator (should always be a file) ;  fixed unupdated -nofunc else echo
* 2:15 PM 5/29/2024 add: c:\sc dev repo dest test, prompt for optional -nofunc use (avoid mistakes copying into repo with _func.ps1 source name intact)
* 1:22 PM 5/22/2024init

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

