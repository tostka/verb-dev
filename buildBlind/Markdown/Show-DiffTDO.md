
# Show-DiffTDO

## SYNOPSIS
Show-DiffTDO() - Produces a git-diff-like output for file comparison (wraps CompareFilesTDO, & Writed-DiffTDO)

## SYNTAX

```
Show-DiffTDO [-Ref] <FileInfo[]> [-Diff] <FileInfo[]> [-ContextLines <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Show-DiffTDO() - Produces a git-diff-like output for file comparison (wraps CompareFilesTDO, & Writed-DiffTDO)

## EXAMPLES

### EXAMPLE 1
```
Show-DiffTDO -Ref C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_catapult_20221019vers.ps1 -Diff C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_KADRITS.ps1
```

## PARAMETERS

### -Ref
The first file to compare

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
The second file to compare

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

### -ContextLines
Lines of context to compare

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 3
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
FileName    : Show-DiffTDO.ps1
License     : (none asserted)
Copyright   : (none asserted)
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,Git,SourceControl,Diff,format
AddedCredit : Doug Finke
AddedWebsite: https://dfinke.github.io/powershell,%20ai,%20chatgpt,%20codegen/2024/09/03/git-diff-tool-in-powershell.html
AddedTwitter: URL
REVISIONS
* 9:09 AM 5/28/2026 init, minor formatting tweaks, updated CBH, added proc{}; added -DiffStyle, to flip from added/deleted -\> +/-; added == support which prefixes \s.
* 9/3/2024 Doug Finke's blog post example (code generated via ChatGPT)

## RELATED LINKS

[AddedWebsite: https://dfinke.github.io/powershell,%20ai,%20chatgpt,%20codegen/2024/09/03/git-diff-tool-in-powershell.html](AddedWebsite: https://dfinke.github.io/powershell,%20ai,%20chatgpt,%20codegen/2024/09/03/git-diff-tool-in-powershell.html)

[https://github.com/tostka/verb-dev

[CmdletBinding(DefaultParameterSetName="NoExpectation")]]()

