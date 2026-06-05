
# Compare-FileTDO

## SYNOPSIS
Compare-FileTDO() - Compares two files, displaying differences in a manner similar to traditional console-based diff utilities.

## SYNTAX

```
Compare-FileTDO [-Ref] <FileInfo[]> [-Diff] <FileInfo[]> [-pattern <String>] [-DiffStyle] [<CommonParameters>]
```

## DESCRIPTION
Compare-FileTDO() - Compares two files, displaying differences in a manner similar to traditional console-based diff utilities.

## EXAMPLES

### EXAMPLE 1
```
compare-filetdo -Ref C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_catapult_20221019vers.ps1 -Diff C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_KADRITS.ps1
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
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -pattern
The regex pattern (if any) to use as a -match filter for file

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: .*
Accept pipeline input: False
Accept wildcard characters: False
```

### -DiffStyle
Switch to specify traditional Diff +/-/\s prefix (over add/remove)

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

### Accepts pipeline input.
## OUTPUTS

### System.Array returns array of matched file properties ('Name','FullName','Extension','Length','LastWriteTime','LinkType','PSParentPath','PSPath','Directory')
## NOTES
Version     : 0.0.
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2026-
FileName    : Compare-FileTDO.ps1
License     : (none asserted)
Copyright   : (none asserted)
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,Git,SourceControl,Diff,format
AddedCredit : Lee Holmes
AddedWebsite: https://www.leeholmes.com/using-powershell-to-compare-diff-files/
AddedTwitter: URL
REVISIONS
* 9:09 AM 5/28/2026 init, minor formatting tweaks, updated CBH, added proc{}; added -DiffStyle, to flip from added/deleted -\> +/-; added == support which prefixes \s.
* Nov 30, 2013 Lee Holmes blog post example

## RELATED LINKS

[https://www.leeholmes.com/using-powershell-to-compare-diff-files/](https://www.leeholmes.com/using-powershell-to-compare-diff-files/)

[https://github.com/tostka/verb-dev

[CmdletBinding(DefaultParameterSetName="NoExpectation")]]()

