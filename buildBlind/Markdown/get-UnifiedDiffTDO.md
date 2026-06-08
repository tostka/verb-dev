
# get-UnifiedDiffTDO

## SYNOPSIS
get-UnifiedDiffTDO() - Produce a UnifiedDiff output of two files, without both being in a git repo (or even same git repo ; leverages: git diff --no-index --unified=3)

## SYNTAX

```
get-UnifiedDiffTDO [-Ref] <FileInfo[]> [-Diff] <FileInfo[]> [-pager] [<CommonParameters>]
```

## DESCRIPTION
get-UnifiedDiffTDO() - Produce a UnifiedDiff file of two files, without both being in a git repo (or even same git repo ; leverages: git diff --no-index --unified=3)

When run without the -pager paramter, outputs a trailing summary of the files, lines count, and added/subtracted lines.


    LastWriteTime         Lines Length Name
    -------------         ----- ------ ----
    5/12/2026 10:52:17 AM  1072  61942 CreateCloudOnlyUsers_catapult_20221019vers.ps1
    5/28/2026 1:51:40 PM   3044 211778 CreateCloudOnlyUsers_KADRITS.ps1

    Action Count
    ------ -----
    ^\+     2904
    ^-       932

Wraps underlying commandline:
git diff --no-index --unified=3 -- $OldFile $NewFile

By default outputs a streamed output to console (for pipeline into variables or postfiltering)
-pager enables underlying git.exe paged onscreen output

## Git Pager Navigation Commands

Command | Action
--- | --- 
k or â†' (Up Arrow) | Move up one line.
j or â†" (Down Arrow) |	Move down one line.
Spacebar or f |	Move forward a full screen/page.
b |	Move backward a full screen/page.
d |	Move forward a half screen.
u |	Move backward a half screen.
G |	Go to the end of the output.
g |	Go to the beginning of the output.
/ |	Search for a specific pattern.

## Exiting the Pager

To exit the git diff display and return to your regular command prompt:

  â€¢ Press the q key (for "quit"). 
  â€¢ If you are on Windows and pressing q alone doesn't work, you may need to press q followed by Enter.

## EXAMPLES

### EXAMPLE 1
```
$results = get-UnifiedDiffTDO -Ref C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_catapult_20221019vers.ps1 -Diff C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_KADRITS.ps1
```

LastWriteTime         Lines Length Name
        -------------         ----- ------ ----
        5/12/2026 10:52:17 AM  1072  61942 CreateCloudOnlyUsers_catapult_20221019vers.ps1
        5/28/2026 1:51:40 PM   3044 211778 CreateCloudOnlyUsers_KADRITS.ps1

        Action Count
        ------ -----
        ^\+     2904
        ^-       932

PS\> write-verbose "filter adds & count " ; 
PS\> $results |?{$_ -match '^\+'} ; 

    +++ "b/C:\\\\sc\\\\powershell\\\\MergerScripts\\\\CreateCloudOnlyUsers_KADRITS.ps1"
    +# C:\usr\work\MergerScripts\CreateCloudOnlyUsers_KADRITS.ps1
    +# D:\scripts\TON\CreateCloudOnlyUsers_KADRITS.ps1
    +        
    ...
    
PS\> write-verbose "filter removes" ; 
PS\> $results |?{$_ -match '^\-'} ; 

    --- "a/C:\\\\sc\\\\powershell\\\\MergerScripts\\\\CreateCloudOnlyUsers_catapult_20221019vers.ps1"
    -âˆ©â•-â"# CreateCloudOnlyUsers_catapult_20221019vers.ps1
    -
    -#Requires -Module AzureAD
    -
    ...
    
PS\> @('+','-') | %{ $rgxthis = \[regex\]"^$(\[regex\]::escape($_))" ; write-host "==$($rgxthis.tostring()) count:\`t" -nonewline ; $results | ?{$_ -match $rgxthis} |  measure | select -expand count } ;

    ==^\+ count:    2904
    ==^- count:     932

Demo eval of object status changes over time, without pager paged ouput (to assign stream to variable), with postfiltering for change types and metrics

### EXAMPLE 2
```
$results = get-UnifiedDiffTDO -Ref C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_catapult_20221019vers.ps1 -Diff C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_KADRITS.ps1 -pager
```

Demo that enables git default pager interface (one page at a time, vs streamed)

## PARAMETERS

### -Ref
The first file to compare(generally the earlier rev)\[-Ref c:\pathto\file1.ps1\]

```yaml
Type: FileInfo[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Diff
The second file to compare(generally the later rev)\[-Diff c:\pathto\file2.ps1\]

```yaml
Type: FileInfo[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -pager
switch to enable git default pager output, dumps one screen at a time to console (disabled by default)\[-pager\]

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

### Does not accept pipeline input.
## OUTPUTS

## NOTES
Version     : 0.0.
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2026-
FileName    : get-UnifiedDiffTDO.ps1
License     : MIT License
Copyright   : (c) 2026 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,Git,SourceControl,Diff,format
AddedCredit : 
AddedWebsite: 
AddedTwitter: URL
REVISIONS
* 8:38 AM 5/29/2026 added trailing reports; flipped -nopager -\> -pager; updated CBH, and demos.
* 2:00 PM 5/28/2026 init

## RELATED LINKS

[https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/Diff-Objects/Diff-Objects.ps1](https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/Diff-Objects/Diff-Objects.ps1)

[https://github.com/tostka/verb-dev

[CmdletBinding(DefaultParameterSetName="NoExpectation")]]()

