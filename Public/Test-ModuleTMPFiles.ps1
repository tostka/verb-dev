# Test-ModuleTMPFiles.ps1
#*------v Function Test-ModuleTMPFiles v------
Function Test-ModuleTMPFiles {
    <#
    .SYNOPSIS
    Test-ModuleTMPFiles.ps1 - Test the tempoary C:\sc\[[mod]]\[mod]\[mod].psd1_TMP & [mod].psm1_TMP files with Test-ModuleManifest  & import-module -force, to ensure the files will function at a basic level, before overwriting the current .psm1 & .psd1 files for the module.
    .NOTES
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
    * 2:27 PM 5/12/2022 fix typo #217 & 220, added w-v echoes; expanded #218 echo
    * 2:08 PM 5/11/2022 move the module test code out to a portable func
    .DESCRIPTION
    Test-ModuleTMPFiles.ps1 - Test the tempoary C:\sc\[[mod]]\[mod]\[mod].psd1_TMP & [mod].psm1_TMP files with Test-ModuleManifest  & import-module -force, to ensure the files will function at a basic level, before overwriting the current .psm1 & .psd1 files for the module.
    .PARAMETER ModuleNamePSM1Path
    Path to the temp file to be tested [-ModuleNamePSM1Path 'C:\sc\verb-IO\verb-IO\verb-io.psm1_TMP']
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    PS> $bRet = Test-ModuleTMPFiles -ModuleNamePSM1Path $PsmNameTmp -whatif:$($whatif) -verbose:$(verbose) ;
    PS> if ($bRet.valid -AND $bRet.Manifest -AND $bRet.Module){
    PS>     $pltCpyPsm1 = @{ Path=$PsmNameTmp ; Destination=$PsmName ; whatif=$whatif; ErrorAction="STOP" ; } ;
    PS>     $smsg = "Processing error free: Overwriting temp .psm1 with temp copy`ncopy-item w`n$(($pltCppltCpyPsm1y|out-string).trim())" ;
    PS>     if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    PS>     else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    PS>     $pltCpyPsd1 = @{ Path=$PsmNameTmp ; Destination=$PsmName ; whatif=$whatif; ErrorAction="STOP" ; } ;
    PS>     $error.clear() ;
    PS>     TRY {
    PS>         copy-Item  @pltCpyPsm1 ;
    PS>         $PassStatus += ";copy-Item:UPDATE";
    PS>         $smsg = "Processing error free: Overwriting temp .psd1 with temp copy`ncopy-item w`n$(($pltCpyPsd1|out-string).trim())" ;
    PS>         if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>         else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    PS>         copy-Item @pltCpyPsd1 ;
    PS>     } CATCH {
    PS>         Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
    PS>         $PassStatus += ";copy-Item:ERROR";
    PS>         Break  ;
    PS>     } ;
    PS>
    PS> } else {
    PS>     $smsg = "Test-ModuleTMPFiles:FAIL! Aborting!" ;
    PS>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>     Break ;
    PS> } ;
    Demo that displays running with a splat, and parsing the return'd object to approve final update to production .psd1|.psm1
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $False, Position = 0, ValueFromPipeline = $True, HelpMessage = 'Path to the temp file to be tested [-ModuleNamePSM1Path C:\sc\verb-IO\verb-IO\verb-io.psm1_TMP]')]
        #[Alias('PsPath')]
        [ValidateScript({Test-Path $_})]
        [system.io.fileinfo[]]$ModuleNamePSM1Path
    )
    BEGIN {
        #region CONSTANTS-AND-ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        write-verbose "`$PSBoundParameters:`n$(($PSBoundParameters|out-string).trim())" ;
        $Verbose = ($VerbosePreference -eq 'Continue') ;
        $sBnr = "#*======v $($CmdletName): $(($ModuleNamePSM1Path) -join ',') v======" ;
        $smsg = $sBnr ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else { write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

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

        foreach($Psm1 in $ModuleNamePSM1Path){
            $objReport=[ordered]@{
                Manifest=$null ;
                Module = $null ;
                Valid = $false ;
            }
            [system.io.fileinfo]$psd1 = $Psm1.fullname.replace('.psm1', '.psd1') ;

            <# it's throwing errors trying to ipmo from the temp dir, so lets create a local file, named a guid:
            $testpsm1 = [System.IO.Path]::GetTempFileName().replace(".tmp",".psm1") ;
            #>
            #$testpsm1 = join-path -path (split-path $PsmNameTmp) -ChildPath "$(new-guid).psm1"
            # build a local dummy name [guid] for testing .psm1|psd1
            [system.io.fileinfo]$testpsm1 = join-path -path (split-path $Psm1) -ChildPath "$(new-guid).psm1" ;
            [system.io.fileinfo]$testpsd1 = $testpsm1.fullname.replace('.psm1', '.psd1') ;

            $smsg = "`nPsm1:$($Psm1)" ;
            $smsg += "`nPsd1:$($psd1 )"
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else { write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            # 4:37 PM 5/10/2022 new pretests before fully overwriting everything and tearing out local functional mod copy in CU
            # should test-modulemanifest the updated .psd1, berfore continuing

            $pltCpy = @{ Path = $psd1 ; Destination = $testpsd1 ; whatif = $($whatif); ErrorAction="STOP" ; verbose=$($verbose)} ;
            $smsg = "Creating Testable $($pltCpy.Destination)`n to validate $($pltCpy.path) will Test-ModuleManifest"
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;

            $pltTMM = @{ Path = $testpsd1.fullname ; ErrorVariable = 'vManiErr'; ErrorAction="STOP" ; verbose=$($verbose)} ;

            TRY {
                copy-Item @pltCpy ;
                #$smsg = "Test-ModuleManifest -path $($testpsd1.fullname) " ;
                $smsg = "Test-ModuleManifest w`n$(($pltTMM|out-string).trim())" ; 
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;} ; 
                $psd1Profile = Test-ModuleManifest -path $testpsd1.fullname -ErrorVariable vManiErr ;
                if($? ){
                    $smsg= "Test-ModuleManifest:PASSED" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                    $objReport.Manifest = $psd1Profile ;

                } ;
            } CATCH {
                $PassStatus += ";ERROR";
                write-warning  "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                $objReport.Manifest = $null ;
                Break ;
            } ;

            # should also ipmo -for the .psm1 before commiting
            $pltCpy = @{ Path = $Psm1 ; Destination = $testpsm1 ; whatif = $($whatif); ErrorAction = "STOP" ; verbose = $($verbose) } ;
            $smsg = "Creating Testable $($pltCpy.Destination)`n to validate $($pltCpy.path) will Import-Module"
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 

            $pltIpmo = [ordered]@{ Name=$testpsm1 ;Force=$true ;verbose=$($VerbosePreference -eq "Continue") ; ErrorAction="STOP" ; ErrorVariable = 'vIpMoErr' ; PassThru=$true } ;
            $error.clear() ;
            TRY {
                copy-Item @pltCpy ;

                $smsg = "n import-module w`n$(($pltIpmo|out-string).trim())" ;
                if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;

                $ModResult = import-module @pltIpmo ;

                $smsg = "Ipmo: PASSED" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                $objReport.Module = $ModResult ;

                # - leave in memory, otherwise removal below could leave a non-func module in place.
                # no, since we're using a dummy, remove the $testPsm1 from mem
                $smsg = "(remove-module -name $($pltIpmo.name) -force)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                remove-module -name $pltIpmo.name -force -verbose:$($verbose) -ErrorAction SilentlyContinue;

                $smsg = "(remove-item -path $($testpsm1) -ErrorAction SilentlyContinue ; " ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                remove-item -path $testpsm1 -ErrorAction SilentlyContinue ;
                $smsg = "(remove-item -path $($testpsd1) -ErrorAction SilentlyContinue ; " ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                remove-item -path $testpsd1 -ErrorAction SilentlyContinue ;

            }CATCH{
                #Write-Error -Message $_.Exception.Message ;
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #-=-record a STATUSWARN=-=-=-=-=-=-=
                $statusdelta = ";ERROR"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
                Write-Warning "Unable to Add-ContentFixEncoding:$($Path.FullName)" ;
                #$false | write-output ;
                start-sleep -s $RetrySleep ;
                #Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;

            <#$objReport=[ordered]@{
                Manifest=$null ;
                Module = $null ;
                Valid = $false ;
            }#>
            $smsg = "`$objReport`n$(($objReport|out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            if($objReport.Manifest -AND $objReport.Module){
                $smsg = "(SET:`$objReport.Valid = `$true ;)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $objReport.Valid = $true ;
            }
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
} ;
#*------^ END Function Test-ModuleTMPFiles  ^------
