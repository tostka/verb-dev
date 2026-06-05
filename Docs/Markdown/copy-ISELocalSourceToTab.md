
# copy-ISELocalSourceToTab

## SYNOPSIS
copy-ISELocalSourceToTab - From a remote RDP session running ISE, copy a file (and any matching -PS-BP.XML) from specified admin client machine to remote ISE host (renaming function sources to _func.ps1) and open the copied file in the remot ISE.

## SYNTAX

```
copy-ISELocalSourceToTab [[-Path] <FileInfo>] [-LocalSource] <DirectoryInfo> [-Func] [-whatIf]
 [<CommonParameters>]
```

## DESCRIPTION
copy-ISELocalSourceToTab - From a remote RDP session running ISE, copy a file (and any matching -PS-BP.XML) from specified admin client machine to remote ISE host (renaming function sources to _func.ps1) and open the copied file in the remot ISE.

This also checks for a matching exported breakpoint file (name matches target script .ps1, with trailing name ...-ps1-BP.xml), and prompts to also COPY that file along with the .ps1.

## EXAMPLES

### EXAMPLE 1
```
copy-ISELocalSourceToTab -LocalSource C:\sc\verb-Exo\public\Connect-EXO.ps1 -func  -Verbose -whatif ;
```

Copy the specified local path on the RDP session, to the default destination path, whatif, with verbose output

### EXAMPLE 2
```
copy-ISELocalSourceToTab -LocalSource C:\usr\work\o365\scripts\New-CMWTempMailContact.ps1 -Verbose -whatif ;
```

Copy the current tab file to explicit specified -LocalDesetination, replacing any _func substring from filename, with whatif, with verbose output

## PARAMETERS

### -Path
Path to source file (defaults to \`$psise.CurrentFile.FullPath)\[-Path 'D:\scripts\copy-ISELocalSourceToTab_func.ps1'\]

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LocalSource
Localized destination directory path\[-path c:\pathto\\\]

```yaml
Type: DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Func
Switch to append '_func' substring to the original file name, while copying (used for copying module functions from .\Public directory to ensure no local name clash for debugging\[-Func\]

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
Version     : 1.0.1
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2024-05-22
FileName    : copy-ISELocalSourceToTab
License     : MIT License
Copyright   : (c) 2024 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging,backup
REVISIONS
* 9:20 AM 2/10/2025 tweaked to permit non-tsclient-spanning use: supports copying from local repo to a separate generic debugging copy; fixed swapped error msgs at bottom of PROC{}
* 3:30 PM 10/25/2024 appears to work for bp, non-func as well;  inital non-BP.xml func copy working ; port from copy-ISETabFileToLocal(), to do the reverse
* 2:15 PM 5/29/2024 add: c:\sc dev repo dest test, prompt for optional -nofunc use (avoid mistakes copying into repo with _func.ps1 source name intact)
* 1:22 PM 5/22/2024init

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

