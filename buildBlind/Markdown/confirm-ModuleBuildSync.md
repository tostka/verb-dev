schema: 2.0.0
---

# confirm-ModuleBuildSync

## SYNOPSIS
confirm-ModuleBuildSync - Enforce expected Module Build Version/Guid-sync in Module .psm1 \[modname\]\\\[modname\]\\\[modname\].psm1|psd1 & Pester Test .ps1 files.

## SYNTAX

```
confirm-ModuleBuildSync [-ModPsdPath] <FileInfo[]> [[-RequiredVersion] <Version>] [-NoTest]
 [[-scRoot] <String>] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
confirm-ModuleBuildSync - Enforce expected Module Build Version/Guid-sync in Module .psm1 \[modname\]\\\[modname\]\\\[modname\].psm1|psd1 & Pester Test .ps1 files.
Wraps functions:
   confirm-ModulePsd1Version.ps1
   confirm-ModulePsm1Version.ps1
   confirm-ModuleTestPs1Guid.ps1

## EXAMPLES

### EXAMPLE 1
```
$pltCMBS=[ordered]@{   ModPsdPath = 'C:\sc\verb-IO\verb-IO\verb-IO.psd1_TMP' ;   RequiredVersion = '2.0.3' ;   whatif = $($whatif) ;   verbose = $($verbose) ; } ;
```

PS\> $smsg = "confirm-ModuleBuildSync w\`n$(($pltCMBS|out-string).trim())" ;
PS\> if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
PS\> else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
PS\> $bRet = confirm-ModuleBuildSync @pltCMPV ;
PS\> #if ($bRet.valid -AND $bRet.Version){
PS\> if($bRet.Manifest -AND $bRet.Module -AND $bRet.Pester -AND $bRet.Guid -AND $bRet.Version -AND $bRet.Valid){
PS\>     $smsg = "(confirm-ModuleBuildSync:Success)" ;
PS\>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
PS\>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
PS\> } else {
PS\>     $smsg = "confirm-ModuleBuildSync:FAIL!
Aborting!" ;
PS\>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
PS\>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
PS\>     Break ;
PS\> } ;       
Splatted demo, running full pass confirm

### EXAMPLE 2
```
$pltCMBS=[ordered]@{   ModPsdPath = 'C:\sc\verb-IO\verb-IO\verb-IO.psd1_TMP' ;   RequiredVersion = '2.0.3' ; NoTest = $true ;  whatif = $($whatif) ;   verbose = $($verbose) ; } ;
```

PS\> $smsg = "confirm-ModuleBuildSync w\`n$(($pltCMBS|out-string).trim())" ;
PS\> if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
PS\> else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
PS\> $bRet = confirm-ModuleBuildSync @pltCMPV ;
PS\> #if ($bRet.valid -AND $bRet.Version){
PS\> if($bRet.Manifest -AND $bRet.Module -AND $bRet.Pester -AND $bRet.Guid -AND $bRet.Version -AND $bRet.Valid){
PS\>     $smsg = "(confirm-ModuleBuildSync:Success)" ;
PS\>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
PS\>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
PS\> } else {
PS\>     $smsg = "confirm-ModuleBuildSync:FAIL!
Aborting!" ;
PS\>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
PS\>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
PS\>     Break ;
PS\> } ;   
Splatted demo with -NoTest to skip Pester test .ps1 guid-sync confirmation

## PARAMETERS

### -ModPsdPath
Path to target module Manfest (.psd1-or analog file)\[-ModPsdPath C:\sc\verb-IO\verb-IO\verb-IO.psd1_TMP\]

```yaml
Type: FileInfo[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -RequiredVersion
Explicit 3-digit Version to be enforced\[-Version 2.0.3\]

```yaml
Type: Version
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoTest
Switch parameter that skips Pester Test script GUID-sync

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

### -scRoot
Path to git root folder\[-scRoot c:\sc\\\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: C:\sc\
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
CreatedDate : 2022-05-31
FileName    : confirm-ModuleBuildSync
License     : MIT License
Copyright   : (c) 2022 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging,Pester
REVISIONS
* 11:48 AM 6/2/2022 same typo as before, splat named pltcmbs, call uses pltcmpv.
$objReport also needed .pester populated, as part of validation testing;
    CBH: added broader example; added -NoTest for use during convertTo-ModuleMergedTDO phase (vs final test of all components in prod build, pre pkg build).
* 9:59 AM 6/1/2022 init

## RELATED LINKS

[https://github.com/tostka/verb-dev

VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]](https://github.com/tostka/verb-dev

VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)])

[https://github.com/tostka/verb-dev

VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]]()

