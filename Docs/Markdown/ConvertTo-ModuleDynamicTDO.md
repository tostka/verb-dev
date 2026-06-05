
# ConvertTo-ModuleDynamicTDO

## SYNOPSIS
ConvertTo-ModuleDynamicTDO.ps1 - Revert a monolisthic module.psm1 module file, to dynamic include .psm1.
Returns a hash with status:$true/$false, and PsmNameBU:The name of a backup of the original .psm1 file (for restoring on failures)

## SYNTAX

```
ConvertTo-ModuleDynamicTDO [-ModuleName] <String> [-ModuleSourcePath] <Array> [-ModuleDestinationPath] <String>
 [[-LogSpec] <Object>] [-NoAliasExport] [-showDebug] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
ConvertTo-ModuleDynamicTDO.ps1 - Revert a monolisthic module.psm1 module file, to dynamic include .psm1.
Returns a hash with status:$true/$false, and PsmNameBU:The name of a backup of the original .psm1 file (for restoring on failures)

## EXAMPLES

### EXAMPLE 1
```
.\ConvertTo-ModuleDynamicTDO.ps1 -ModuleName verb-AAD -ModuleSourcePath C:\sc\verb-AAD\Public -ModuleDestinationPath C:\sc\verb-AAD\verb-AAD -showdebug -whatif ;
```

Command line process

### EXAMPLE 2
```
$pltmergeModule=[ordered]@{
```

PS\>     ModuleName="verb-AAD" ;
PS\>     ModuleSourcePath="C:\sc\verb-AAD\Public","C:\sc\verb-AAD\Internal" ;
PS\>     ModuleDestinationPath="C:\sc\verb-AAD\verb-AAD" ;
PS\>     LogSpec = $logspec ;
PS\>     NoAliasExport=$($NoAliasExport) ;
PS\>     ErrorAction="Stop" ;
PS\>     showdebug=$($showdebug);
PS\>     whatif=$($whatif);
PS\> } ;
PS\> $smsg= "ConvertTo-ModuleDynamicTDO w\`n$(($pltmergeModule|out-string).trim())" ;
PS\> if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
PS\> else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
PS\> $ReportObj = ConvertTo-ModuleDynamicTDO @pltmergeModule ;
Splatted example (from process-NewModule.ps1)

## PARAMETERS

### -ModuleName
Module Name (used to name the ModuleName.psm1 file)\[-ModuleName verb-XXX\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleSourcePath
Directory containing .ps1 function files to be combined \[-ModuleSourcePath c:\path-to\module\Public\]

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleDestinationPath
Final monolithic module .psm1 file name to be populated \[-ModuleDestinationPath c:\path-to\module\module.psm1\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogSpec
Logging spec object (output from start-log())\[-LogSpec $LogSpec\]

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoAliasExport
Flag that skips auto-inclusion of 'Export-ModuleMember -Alias * ' in merged file \[-NoAliasExport\]

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

### -showDebug
Parameter to display Debugging messages \[-ShowDebug switch\]

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

### None
## OUTPUTS

### Outputs a hashtable object containing: Status[$true/$false], PsmNameBU [the name of the backup of the original psm1 file]
## NOTES
Version     : 1.0.0
Author      : Todd Kadrie
Website     : https://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2019-12-10
FileName    : ConvertTo-ModuleDynamicTDO.ps1
License     : MIT License
Copyright   : (c) 2019 Todd Kadrie
Github      : https://github.com/tostka
AddedCredit : Przemyslaw Klys
AddedWebsite: https://evotec.xyz/powershell-single-psm1-file-versus-multi-file-modules/
Tags        : Powershell,Module,Development
AddedTwitter:
REVISIONS
* 5:45 PM 8/7/2024 reformat params 
* 2:08 PM 6/29/2022 # scrap the entire $psv2Publine etc block - it's causing corruption, and I won't need it post upgrade off of exop
* 8:34 AM 5/16/2022 typo: used Aliases for Alias
* 3:07 PM 5/13/2022ren unmerge-Module -\> ConvertTo-ModuleDynamicTDO() (use std verb; adopt keyword to unique my work from 3rd-party funcs); added Unmerge-Module to Aliases; 
* 4:06 PM 5/12/2022 merge over latest working updates to merge-module.ps1; *untested*
* 8:08 AM 5/3/2022 WIP init convert of Merge-Module to unmerge-module

## RELATED LINKS

[https://www.toddomation.com](https://www.toddomation.com)

