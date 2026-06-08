
# Test-ModuleTMPFiles

## SYNOPSIS
Test-ModuleTMPFiles.ps1 - Test the tempoary C:\sc\\\[\[mod\]\]\\\[mod\]\\\[mod\].psd1_TMP & \[mod\].psm1_TMP files with Test-ModuleManifest  & import-module -force, to ensure the files will function at a basic level, before overwriting the current .psm1 & .psd1 files for the module.

## SYNTAX

```
Test-ModuleTMPFiles [[-ModuleNamePSM1Path] <FileInfo[]>] [<CommonParameters>]
```

## DESCRIPTION
Test-ModuleTMPFiles.ps1 - Test the tempoary C:\sc\\\[\[mod\]\]\\\[mod\]\\\[mod\].psd1_TMP & \[mod\].psm1_TMP files with Test-ModuleManifest  & import-module -force, to ensure the files will function at a basic level, before overwriting the current .psm1 & .psd1 files for the module.

## EXAMPLES

### EXAMPLE 1
```
$bRet = Test-ModuleTMPFiles -ModuleNamePSM1Path $PsmNameTmp -whatif:$($whatif) -verbose:$(verbose) ;
```

PS\> if ($bRet.valid -AND $bRet.Manifest -AND $bRet.Module){
PS\>     $pltCpyPsm1 = @{ Path=$PsmNameTmp ; Destination=$PsmName ; whatif=$whatif; ErrorAction="STOP" ; } ;
PS\>     $smsg = "Processing error free: Overwriting temp .psm1 with temp copy\`ncopy-item w\`n$(($pltCppltCpyPsm1y|out-string).trim())" ;
PS\>     if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
PS\>     else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
PS\>     $pltCpyPsd1 = @{ Path=$PsmNameTmp ; Destination=$PsmName ; whatif=$whatif; ErrorAction="STOP" ; } ;
PS\>     $error.clear() ;
PS\>     TRY {
PS\>         copy-Item  @pltCpyPsm1 ;
PS\>         $PassStatus += ";copy-Item:UPDATE";
PS\>         $smsg = "Processing error free: Overwriting temp .psd1 with temp copy\`ncopy-item w\`n$(($pltCpyPsd1|out-string).trim())" ;
PS\>         if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
PS\>         else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
PS\>         copy-Item @pltCpyPsd1 ;
PS\>     } CATCH {
PS\>         Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName).
\`nError Message: $($_.Exception.Message)\`nError Details: $($_)" ;
PS\>         $PassStatus += ";copy-Item:ERROR";
PS\>         Break  ;
PS\>     } ;
PS\>
PS\> } else {
PS\>     $smsg = "Test-ModuleTMPFiles:FAIL!
Aborting!" ;
PS\>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
PS\>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
PS\>     Break ;
PS\> } ;
Demo that displays running with a splat, and parsing the return'd object to approve final update to production .psd1|.psm1

## PARAMETERS

### -ModuleNamePSM1Path
Path to the temp file to be tested \[-ModuleNamePSM1Path 'C:\sc\verb-IO\verb-IO\verb-io.psm1_TMP'\]

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Version     : 0.0.
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2022-05-10
FileName    : Test-ModuleTMPFiles.ps1
License     : MIT License
Copyright   : (c) 2022 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,Module,Management,Lifecycle
REVISIONS
* 2:08 PM 3/22/2023 expanded catch's they were coming up blank; fixed spurious 'Unable to Add-ContentFixEncoding' error (completely offbase)
* 2:27 PM 5/12/2022 fix typo #217 & 220, added w-v echoes; expanded #218 echo
* 2:08 PM 5/11/2022 move the module test code out to a portable func

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

