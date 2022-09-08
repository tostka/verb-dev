#*------v confirm-ModuleBuildSync.ps1 v------
function confirm-ModuleBuildSync {
    <#
    .SYNOPSIS
    confirm-ModuleBuildSync - Enforce expected Module Build Version/Guid-sync in Module .psm1 [modname]\[modname]\[modname].psm1|psd1 & Pester Test .ps1 files.
    .NOTES
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
    * 11:48 AM 6/2/2022 same typo as before, splat named pltcmbs, call uses pltcmpv. $objReport also needed .pester populated, as part of validation testing;
        CBH: added broader example; added -NoTest for use during convertTo-ModuleMergedTDO phase (vs final test of all components in prod build, pre pkg build).
    * 9:59 AM 6/1/2022 init
    .DESCRIPTION
   confirm-ModuleBuildSync - Enforce expected Module Build Version/Guid-sync in Module .psm1 [modname]\[modname]\[modname].psm1|psd1 & Pester Test .ps1 files.
   Wraps functions:
      confirm-ModulePsd1Version.ps1
      confirm-ModulePsm1Version.ps1
      confirm-ModuleTestPs1Guid.ps1
    .PARAMETER  ModPsdPath
    Path to target module Manfest (.psd1-or analog file)[-ModPsdPath C:\sc\verb-IO\verb-IO\verb-IO.psd1_TMP]
    .PARAMETER RequiredVersion
    Explicit 3-digit Version to be enforced[-Version 2.0.3]
    .PARAMETER NoTest
    Switch parameter that skips Pester Test script GUID-sync
    .PARAMETER scRoot
    Path to git root folder[-scRoot c:\sc\]
    .PARAMETER whatIf
    Whatif Flag  [-whatIf]
    .EXAMPLE
    PS> $pltCMBS=[ordered]@{   ModPsdPath = 'C:\sc\verb-IO\verb-IO\verb-IO.psd1_TMP' ;   RequiredVersion = '2.0.3' ;   whatif = $($whatif) ;   verbose = $($verbose) ; } ;
    PS> $smsg = "confirm-ModuleBuildSync w`n$(($pltCMBS|out-string).trim())" ;
    PS> if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    PS> else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS> $bRet = confirm-ModuleBuildSync @pltCMPV ;
    PS> #if ($bRet.valid -AND $bRet.Version){
    PS> if($bRet.Manifest -AND $bRet.Module -AND $bRet.Pester -AND $bRet.Guid -AND $bRet.Version -AND $bRet.Valid){
    PS>     $smsg = "(confirm-ModuleBuildSync:Success)" ;
    PS>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS> } else {
    PS>     $smsg = "confirm-ModuleBuildSync:FAIL! Aborting!" ;
    PS>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>     Break ;
    PS> } ;       
    Splatted demo, running full pass confirm
    .EXAMPLE
    PS> $pltCMBS=[ordered]@{   ModPsdPath = 'C:\sc\verb-IO\verb-IO\verb-IO.psd1_TMP' ;   RequiredVersion = '2.0.3' ; NoTest = $true ;  whatif = $($whatif) ;   verbose = $($verbose) ; } ;
    PS> $smsg = "confirm-ModuleBuildSync w`n$(($pltCMBS|out-string).trim())" ;
    PS> if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    PS> else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS> $bRet = confirm-ModuleBuildSync @pltCMPV ;
    PS> #if ($bRet.valid -AND $bRet.Version){
    PS> if($bRet.Manifest -AND $bRet.Module -AND $bRet.Pester -AND $bRet.Guid -AND $bRet.Version -AND $bRet.Valid){
    PS>     $smsg = "(confirm-ModuleBuildSync:Success)" ;
    PS>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS> } else {
    PS>     $smsg = "confirm-ModuleBuildSync:FAIL! Aborting!" ;
    PS>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>     Break ;
    PS> } ;   
    Splatted demo with -NoTest to skip Pester test .ps1 guid-sync confirmation
    .LINK
    https://github.com/tostka/verb-dev
    #>
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    [CmdletBinding()]
    #[Alias('iIseBpAll')]
    PARAM(
        [Parameter(Mandatory=$True, ValueFromPipeline=$true, HelpMessage="Array of Paths to target modules Manfests (.psd1-or equiv temp file)[-ModPsdPath C:\sc\verb-IO\verb-IO\verb-IO.psd1_TMP]")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [system.io.fileinfo[]]$ModPsdPath,
        [Parameter(HelpMessage="Explicit 3-digit Version specification[-Version 2.0.3]")]
        [version]$RequiredVersion,
        [Parameter(HelpMessage="Switch parameter that skips Pester Test script GUID-sync [-NoTest]")]
        [switch] $NoTest,
        [Parameter(HelpMessage="path to git root folder[-scRoot c:\sc\]")]
        [string]$scRoot = 'c:\sc\',
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
     BEGIN {
        #region CONSTANTS-AND-ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        write-verbose "`$PSBoundParameters:`n$(($PSBoundParameters|out-string).trim())" ;
        $Verbose = ($VerbosePreference -eq 'Continue') ;
        <#
        $rgxTestScriptNOGuid = "Please\sPaste\shere\syour\smodule\sGuid\s-\sTest-ModuleManifest\s'<ModulePath>'\s\|\sSelect-Object\s-ExpandProperty\sGuid" ;
        $rgxTestScriptGuid = '\.Guid((\s)*)\|((\s)*)Should((\s)*)-Be((\s)*)"([0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12})"'
        $rgxGuid = "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}" ;
        #>
        #$rgxPsM1Version='Version((\s*)*):((\s*)*)(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?' ;
        $sBnr = "#*======v $($CmdletName): $(($Path) -join ',') v======" ;
        $smsg = $sBnr ;
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;

        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ;
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ;
            write-verbose "(non-pipeline - param - input)" ;
        } ;

    } ;  # BEGIN-E
    PROCESS {
        $Error.Clear() ;
        # - Pipeline support will iterate the entire PROCESS{} BLOCK, with the bound - $array -
        #   param, iterated as $array=[pipe element n] through the entire inbound stack.
        # $_ within PROCESS{}  is also the pipeline element (though it's safer to declare and foreach a bound $array param).

        # - foreach() below alternatively handles _named parameter_ calls: -array $objectArray
        # which, when a pipeline input is in use, means the foreach only iterates *once* per
        #   Process{} iteration (as process only brings in a single element of the pipe per pass)

        foreach($ModPsd1 in $ModPsdPath){
            $objReport=[ordered]@{
                Manifest=$null ;
                Module = $null ;
                Pester = $null ;
                Guid = $null ;
                Version = $null ;
                Valid = $false ;
            } ;

            TRY{
                $ModuleName = (split-path $ModPsd1 -leaf).split('.')[0] ;
                [system.io.fileinfo]$ModRoot = join-path -path $scRoot -child $ModuleName ;
                [system.io.fileinfo]$ModPsm1 = $ModPsd1.fullname.tostring().replace('.psd1','.psm1') ;
                [system.io.fileinfo]$ModTestPs1 = "$($ModRoot)\Tests\$($ModuleName).tests.ps1" ;

                if ( (Test-Path -path $ModPsm1) -AND (Test-Path -path $ModTestPs1) ){
                    $smsg = "(test-path confirms `$ModPsm1 & `$ModTestPs1)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } else {
                    $smsg = "(Test-Path -path $($ModPsm1)) -AND (Test-Path -path $($ModTestPs1)):FAIL! Aborting!" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    throw $smsg ;
                    Break ;
                } ;

                $pltIPSDF=[ordered]@{
                    Path            = $ModPsd1.fullname.tostring() ;
                    ErrorAction = 'Stop' ;
                    verbose = $($verbose) ;
                } ;
                $smsg = "Import-PowerShellDataFile w`n$(($pltIPSDF|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $psd1Profile = Import-PowerShellDataFile @pltIPSDF ;

                $psd1Vers = $psd1Profile.ModuleVersion.tostring() ;
                $psd1guid = $psd1Profile.Guid.tostring() ;

                $smsg = "(resolved Module attributes:" ;
                $smsg += "`n`$ModuleName:`t$($ModuleName)"
                $smsg += "`n`$ModRoot:`t$($ModRoot.fullname.tostring())"
                $smsg += "`n`$ModPsd1:`t$($ModPsd1.fullname.tostring())"
                $smsg += "`n`$ModPsm1:`t$($ModPsm1.fullname.tostring())"
                $smsg += "`n`$ModTestPs1:`t$($ModTestPs1.fullname.tostring())"
                $smsg += "`n`$psd1Vers:`t$($psd1Vers)"
                $smsg += "`n`$psd1guid:`t$($psd1guid))"
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } CATCH {
                $ErrTrapd = $Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } 
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                Break ;
            } ;

            # 4:48 PM 5/31/2022 getting mismatch/revert in revision to prior spec, confirm/force set it here:
            # $bRet = confirm-ModulePsd1Version -Path 'C:\sc\verb-IO\verb-IO\verb-IO.psd1_TMP' -RequiredVersion '2.0.3' -whatif  -verbose
            # [Parameter(HelpMessage="Optional Explicit 3-digit RequiredVersion specification (as contrasts with using current Manifest .psd1 ModuleVersion value)[-Version 2.0.3]")]
            #        [version]$RequiredVersion,
            $pltCMPV=[ordered]@{
                Path = $ModPsd1.fullname.tostring() ;
                RequiredVersion = $RequiredVersion ;
                whatif = $($whatif) ;
                verbose = $($verbose) ;
            } ;
            $smsg = "confirm-ModulePsd1Version w`n$(($pltCMPV|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $bRet = confirm-ModulePsd1Version @pltCMPV ;
            if ($bRet.valid -AND $bRet.Version){
                $smsg = "(confirm-ModulePsd1Version:Success)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $objReport.Manifest = $ModPsd1 ;
            } else {
                $smsg = "confirm-ModulePsd1Version:FAIL! Aborting!" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Break ;
            } ;

            # do the psm1 too
            #$bRet = confirm-ModulePsm1Version -Path 'C:\sc\verb-IO\verb-IO\verb-io.psm1_TMP' -RequiredVersion '2.0.3' -whatif:$($whatif) -verbose:$($verbose) ;
            $pltCMPMV=[ordered]@{
                Path = $ModPsm1.fullname.tostring() ; ;
                RequiredVersion = $RequiredVersion ;
                whatif = $($whatif) ;
                verbose = $($verbose) ;
            } ;
            $smsg = "confirm-ModulePsm1Version w`n$(($pltCMPMV|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $bRet = confirm-ModulePsm1Version @pltCMPMV ;
            if ($bRet.valid -AND $bRet.Version){
                $smsg = "(confirm-ModulePsm1Version:Success)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $objReport.Module = $ModPsm1 ;
                $objReport.Version = $RequiredVersion ;
            } else {
                $smsg = "confirm-ModulePsm1Version:FAIL! Aborting!" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Break ;
            } ;

            if(-not $NoTest){
                $smsg = "Checking sync of Psd1 module guid to the Pester Test Script: $($ModTestPs1)" ; ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else { write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $pltCMTPG=[ordered]@{
                    Path = $ModTestPs1.fullname.tostring() ;
                    RequiredGuid = $psd1guid ;
                    whatif = $($whatif) ;
                    verbose = $($verbose) ;
                } ;
                $smsg = "confirm-ModuleTestPs1Guid w`n$(($pltCMTPG|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $bRet = confirm-ModuleTestPs1Guid @pltCMTPG ;
                if ($bRet.valid -AND $bRet.GUID){
                    $smsg = "(confirm-ModuleTestPs1Guid:Success)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $objReport.Pester = $ModTestPs1.fullname.tostring()
                    $objReport.Guid = $psd1guid ;
                } else {
                    $smsg = "confirm-ModuleTestPs1Guid:FAIL! Aborting!" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    Break ;
                } ;
            } else { 
                $smsg = "(-NoTest: skipping confirm-ModuleTestPs1Guid)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $objReport.Guid  = '(SKIPPED)' ; 
                $objReport.Pester  = '(SKIPPED)' ; 
            } ; 

            <#$objReport=[ordered]@{
                Manifest=$null ;
                Module = $null ;
                Pester = $null ;
                Guid = $null ;
                Version = $null ;
                Valid = $false ;
            } ;#>
            $smsg = "`$objReport`n$(($objReport|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            if ($objReport.Version -AND $objReport.Manifest -AND $objReport.Module -AND $objReport.Version -AND $objReport.Pester -AND $objReport.Guid) {
                $smsg = "(SET:`$objReport.Valid = `$true ;)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $objReport.Valid = $true ;
            } else {
                $smsg = "FAILED VALIDATION:valid: FALSE!`n(each should be populated)" ; 
                $smsg += "`n`$objReport.Version:$($objReport.Version)" ; 
                $smsg += "`n`$objReport.Manifest:$($objReport.Manifest)" ; 
                $smsg += "`n`$objReport.Module:$($objReport.Module)" ; 
                $smsg += "`n`$objReport.Pester:$($objReport.Pester)" ; 
                $smsg += "`n`$objReport.Guid:$($objReport.Guid)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } 
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                throw $smsg 
            } ; 
            $smsg = "(PIPELINE:New-Object PSObject -Property `$objReport | write-output)" ;
            $smsg += "`n`$objReport`n$(($objReport|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            New-Object PSObject -Property $objReport | write-output ;
        } ;  # loop-E

    } ;  # PROC-E
    END {
        $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else { write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;  # END-E
}
#*------^ confirm-ModuleBuildSync.ps1 ^------
