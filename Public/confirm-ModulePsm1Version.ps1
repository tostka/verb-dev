#*------v confirm-ModulePsm1Version.ps1 v------
function confirm-ModulePsm1Version {
    <#
    .SYNOPSIS
    confirm-ModulePsm1Version - Enforce expected Module Build Version in Module .psm1 [modname]\[modname]\[modname].psm1 file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-31
    FileName    : confirm-ModulePsm1Version
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging,Pester
    REVISIONS
    * 12:06 PM 6/1/2022 updated CBH example; rem'd unused hash properties on report
    * 4:57 PM 5/31/2022 init
    .DESCRIPTION
   confirm-ModulePsm1Version - Enforce expected Module Build Version in Module .psm1 [modname]\[modname]\[modname].psm1 file
    .PARAMETER Path
    Path to the temp file to be tested [-Path 'C:\sc\verb-IO\verb-IO\verb-io.psm1_TMP']
    .PARAMETER RequiredVersion
    Explicit 3-digit Version to be enforced[-Version 2.0.3]
    .PARAMETER whatIf
    Whatif Flag  [-whatIf]
    .EXAMPLE
    PS> $pltCMPMV=[ordered]@{ Path = 'C:\sc\verb-IO\verb-IO\verb-io.psm1_TMP' ; ; RequiredVersion = '2.0.3' ; whatif = $($whatif) ; verbose = $($verbose) ; } ;
    PS> $smsg = "confirm-ModulePsm1Version w`n$(($pltCMPMV|out-string).trim())" ;
    PS> if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    PS> else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS> $bRet = confirm-ModulePsm1Version @pltCMPMV ;
    PS> if ($bRet.valid -AND $bRet.Version){
    PS>     $smsg = "(confirm-ModulePsm1Version:Success)" ;
    PS>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>     objReport.Manifest = $ModPsm1 ;
    PS>     $objReport.Version = $RequiredVersion ;
    PS> } else {
    PS>     $smsg = "confirm-ModulePsm1Version:FAIL! Aborting!" ;
    PS>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>     Break ;
    PS> } ;    
    Splatted call demo, confirming psm1 specified has Version properly set to '2.0.3', or the existing Version will be updated to comply.
    .LINK
    https://github.com/tostka/verb-dev
    #>
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    [CmdletBinding()]
    #[Alias('iIseBpAll')]
    PARAM(
        [Parameter(Mandatory = $False, Position = 0, ValueFromPipeline = $True, HelpMessage = 'Path to the temp file to be tested [-Path C:\sc\verb-IO\verb-IO\verb-io.psm1_TMP]')]
        #[Alias('PsPath')]
        [ValidateScript({Test-Path $_})]
        [system.io.fileinfo[]]$Path,
        [Parameter(HelpMessage="Explicit 3-digit Version specification[-Version 2.0.3]")]
        [version]$RequiredVersion,
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
        #$rgxPsM1Version = "\s*ModuleVersion\s=\s'(\d*.\d*.\d*)'\s*" ;
        $rgxPsM1Version='Version((\s*)*):((\s*)*)(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?' ;
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

        foreach($File in $Path){
            $objReport=[ordered]@{
                #Manifest=$null ;
                #Module = $null ;
                #Guid = $null ;
                Version = $null ;
                Valid = $false ;
            }

            $pltSCFE = [ordered]@{Path = $File ; PassThru = $true ; Verbose = $($verbose) ; whatif = $($whatif) ; }
            if ($RgxMatch = Get-ChildItem $File | select-string -Pattern $rgxPsM1Version ) {
                #$testVersion = $RgxMatch.matches[0].Groups[9].value.tostring() ; # guid match target
                #$testVersion = $RgxMatch.matches[0].Groups[1].value.tostring() ;
                $testVersion = $RgxMatch.matches[0].captures.groups[0].value.split(':')[1].trim() ;
                if ($testVersion -eq $RequiredVersion) {
                    $smsg = "(Version already updated to match)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level INFO } #Error|Warn|Debug
                    else { write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $objReport.Version= $RequiredVersion ;
                } else {
                    $smsg = "In:$($File)`nVersion present:($testVersion)`n*does not* properly match:$($RequiredVersion)`nFORCING MATCHING UPDATE!" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                    else { write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    # generic Version replace: $_ -replace $rgxGuid, "$($RequiredVersion)"

                    $newContent = (Get-Content $File) | Foreach-Object {
                        $_ -replace $testVersion, "$($RequiredVersion)"
                        #$_ -replace $testVersion, "Version     : $($RequiredVersion)"
                    } | out-string ;
                    $bRet = Set-ContentFixEncoding @pltSCFE -Value $newContent ;
                    if (-not $bRet -AND -not $whatif) { throw "Set-ContentFixEncoding $($File)!" } else {
                        $objReport.Version= $RequiredVersion ;
                    } ;
                } ;
            } else {
                $smsg = "UNABLE TO Regex out...`n$($rgxPsM1Version)`n...from $($File)`nTestScript hasn't been UPDATED!" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else { write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $objReport.Version= $null ;
            } ;
            #-=-=-=-=-=-=-=-=


            <#$objReport=[ordered]@{
                Manifest=$null ;
                Module = $null ;
                #Guid = $null ;
                Version = $null ;
                Valid = $false ;
            }#>
            $smsg = "`$objReport`n$(($objReport|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            if($objReport.Version){
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
}
#*------^ confirm-ModulePsm1Version.ps1 ^------
