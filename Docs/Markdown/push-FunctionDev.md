
# push-FunctionDev

## SYNOPSIS
push-FunctionDev.ps1 - Stage a given c:\sc\\\[repo\]\Public\function.ps1 file to prod editing dir as function_func.ps1

## SYNTAX

```
push-FunctionDev [[-Path] <FileInfo[]>] [-Destination <DirectoryInfo>] [-force] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
push-FunctionDev.ps1 - Stage a given c:\sc\\\[repo\]\Public\function.ps1 file to prod editing dir as function_func.ps1

Concept is to use this to quickly 'push' a module source .ps1 into the dev dir, suffixed as _func.ps1, so that it can be ipmo -fo -verb'd and debugged/edited for updates. 
On completion the matching function pop-FunctionDev.ps1 would be used to pull the updated file back into place, overwriting the original source.

## EXAMPLES

### EXAMPLE 1
```
push-functiondev -Path 'C:\sc\verb-dev\Public\export-ISEBreakPoints.ps1' -verbose -whatif ;
```

Typical run

## PARAMETERS

### -Path
Source module funciton .ps1 file to be staged for editing (to uwps\Name_func.ps1)\[-path 'C:\sc\verb-dev\Public\export-ISEBreakPoints.ps1'\]

```yaml
Type: FileInfo[]
Parameter Sets: (All)
Aliases: PsPath

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Destination
Directoy into which 'genericly-named output files should be written, or the full path to a specified output file\[-Destination c:\pathto\MyModuleHelp.html\]

```yaml
Type: DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: C:\sc\powershell\PSScripts\
Accept pipeline input: False
Accept wildcard characters: False
```

### -force
Force (overwrite conflict)\[-force\]

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
Whatif Flag  \[-whatIf\]

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Does not accepted piped input.
## OUTPUTS

### None. Does not return output to pipeline.
## NOTES
Version     : 1.2.1
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2023-10-02
FileName    : push-FunctionDev.ps1
License     : (None Asserted)
Copyright   : (None Asserted)
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell, development, html, markdown, conversion
AddedCredit : Øyvind Kallstad @okallstad
AddedWebsite: https://communary.net/
AddedTwitter: @okallstad / https://twitter.com/okallstad
REVISIONS
* 3:09 PM 11/29/2023 added missing test on $sMod - gcm comes back with empty mod, when the item has been iflv'd in console, so prompt for a dest mod
* 8:27 AM 11/28/2023 updated CBH; tested, works; add: a few echo details, confirmed -ea stop on all cmds
* 12:30 PM 11/22/2023 init

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

