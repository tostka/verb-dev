
# Write-DiffTDO

## SYNOPSIS
Write-DiffTDO() - Outputs the results of Compare-FilesTDO as formatted console text

## SYNTAX

```
Write-DiffTDO [-Diffs] <PSObject[]> [-Ref] <String[]> [-Diff] <String[]> [[-ContextLines] <Int32>]
 [<CommonParameters>]
```

## DESCRIPTION
Write-DiffTDO() - Outputs the results of Compare-FilesTDO as formatted console text

## EXAMPLES

### EXAMPLE 1
```
$oldFile = Get-Content -Path $OldFilePath ;
```

PS\> $newFile = Get-Content -Path $NewFilePath ; 
PS\> $diffs = Compare-FilesTDO -Ref $OldFilePath -Diff $NewFilePath -ContextLines $ContextLines ; 
PS\> Write-DiffTDO -Diffs $diffs -OldFile $oldFile -NewFile $newFile -ContextLines 3 ;

## PARAMETERS

### -Diffs
Diffs result of a Compare-FilesTDO() pass on a pair of files

```yaml
Type: PSObject[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Ref
The first file to compare

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Diff
The second file to compare

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
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
Position: 4
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
FileName    : Write-DiffTDO.ps1
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

