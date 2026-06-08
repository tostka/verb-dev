
# pop-FunctionDev

## SYNOPSIS
pop-FunctionDev.ps1 - Copy a given c:\sc\\\[repo\]\Public\function.ps1 file from prod editing dir (as function_func.ps1) back to source function .ps1 file

## SYNTAX

```
pop-FunctionDev [[-Path] <FileInfo[]>] [-force] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
pop-FunctionDev.ps1 - Copy a given c:\sc\\\[repo\]\Public\function.ps1 file from prod editing dir (as function_func.ps1) back to source function .ps1 file

Concept is to use this to quickly 'pop' a debugging module source _func.ps1 back to the dev dir, de-suffixed from _func.ps1, so that it can be commited & rebuilt into the module. 

On iniital debugging the matching function push-FunctionDev() would be used to push the .\public\function.ps1 file to the c:\usr\work\ps\scripts\ default dev destnation (or wherever it's -destination param specifies on run).

## EXAMPLES

### EXAMPLE 1
```
pop-FunctionDev -Path "C:\sc\powershell\PSScripts\export-ISEBreakPoints_func.ps1" -Verbose -whatIf ;
```

Demo duping uwps\xxx_func.ps1 debugging code back to source discovered module \public dir

### EXAMPLE 2
```
$psise.powershelltabs.files.fullpath |?{$_ -match '_func\.ps1$'} | %{pop-FunctionDev -path $_ -whatif:$true -verbose } ;
```

Push back *all* _func.ps1 tabs currently open in ISE

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

### -force
\[string\[\]\]$Path,
\[Parameter(Mandatory = $true,HelpMessage="Path the destination 'editing' directory (defaults to uwps)\[-Path c:\pathto\\\]")\]
    \[ValidateScript({Test-Path $_ -PathType 'Container'})\]
    \[System.IO.DirectoryInfo\]$Destination = 'C:\sc\powershell\PSScripts\',

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
FileName    : pop-FunctionDev.ps1
License     : (None Asserted)
Copyright   : (None Asserted)
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell, development, html, markdown, conversion
AddedCredit : Øyvind Kallstad @okallstad
AddedWebsite: https://communary.net/
AddedTwitter: @okallstad / https://twitter.com/okallstad
REVISIONS
* 3:09 PM 11/29/2023 added missing test on $sMod - gcm comes back with empty mod, when the item has been iflv'd in console, so prompt for a dest mod
* 8:27 AM 11/28/2023 updated CBH; tested, works; add: fixed mod discovery typo; a few echo details, confirmed -ea stop on all cmds
* 12:30 PM 11/22/2023 init

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

