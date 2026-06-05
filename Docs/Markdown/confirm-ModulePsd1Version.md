schema: 2.0.0
---

# confirm-ModulePsd1Version

## SYNOPSIS
confirm-ModulePsd1Version - Enforce expected Module Build Version in Manifest .psd1 \[modname\]\\\[modname\]\\\[modname\].psd1 file (unlike test-modulemanifest/update-modulemanifest/update-MetaData, works with renamed temp files like xxx.psd1_TMP files)

## SYNTAX

```
confirm-ModulePsd1Version [[-Path] <FileInfo[]>] [-RequiredVersion <Version>] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
confirm-ModulePsd1Version - Enforce expected Module Build Version in Manifest .psd1 \[modname\]\\\[modname\]\\\[modname\].psd1 file (unlike test-modulemanifest/update-modulemanifest/update-MetaData, works with renamed temp files like xxx.psd1_TMP files)

## EXAMPLES

### EXAMPLE 1
```
$pltCMPV=[ordered]@{ Path = 'C:\sc\verb-IO\verb-IO\verb-IO.psd1' ; RequiredVersion = '2.0.3' ; whatif = $($whatif) ; verbose = $($verbose) ; } ;
```

PS\> $smsg = "confirm-ModulePsd1Version w\`n$(($pltCMPV|out-string).trim())" ;
PS\> if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
PS\> else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
PS\> $bRet = confirm-ModulePsd1Version @pltCMPV ;
PS\> if ($bRet.valid -AND $bRet.Version){
PS\>     $smsg = "(confirm-ModulePsd1Version:Success)" ;
PS\>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
PS\>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
PS\> } else {
PS\>     $smsg = "confirm-ModulePsd1Version:FAIL!
Aborting!" ;
PS\>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
PS\>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
PS\>     Break ;
PS\> } ;
Splatted call demo, confirming psd1 specified has Version properly set to '2.0.3', or the existing Version will be updated to comply.

## PARAMETERS

### -Path
Path to the temp file to be tested \[-Path 'C:\sc\verb-IO\verb-IO\verb-io.psm1_TMP'\]

```yaml
Type: FileInfo[]
Parameter Sets: (All)
Aliases:

Required: False
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
Position: Named
Default value: None
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
FileName    : confirm-ModulePsd1Version
License     : MIT License
Copyright   : (c) 2022 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging,Pester
REVISIONS
* 12:06 PM 6/1/2022 updated CBH example; rem'd unused hash properties on report
* 4:03 PM 5/31/2022 init

## RELATED LINKS

[https://github.com/tostka/verb-dev

VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]](https://github.com/tostka/verb-dev

VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)])

[https://github.com/tostka/verb-dev

VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]]()

