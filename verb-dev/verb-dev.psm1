# verb-dev.psm1


<#
.SYNOPSIS
VERB-dev - Development PS Module-related generic functions
.NOTES
Version     : 1.5.82
Author      : Todd Kadrie
Website     :	https://www.toddomation.com
Twitter     :	@tostka
CreatedDate : 1/14/2020
FileName    : VERB-dev.psm1
License     : MIT
Copyright   : (c) 1/14/2020 Todd Kadrie
Github      : https://github.com/tostka
AddedCredit : REFERENCE
AddedWebsite:	REFERENCEURL
AddedTwitter:	@HANDLE / http://twitter.com/HANDLE
REVISIONS
* 3:27 PM 3/15/2020 load-Module: added $PsmNameTmp, $PsdNameTmp and shifted updating to a _TMP file of each, which at end, if error free, overwrites the current functional copy (correcting prior issue with corruption of existing copy, when there were processing errors). 
* 3:00 PM 2/24/2020 1.2.8, pulled #Requires RunAsAdministrator, convertto-module runs as UID, doesn't have it
* 1/14/2020 - 1.2.7, final mod build (updated content file vers to match latest psd1)
# * 10:33 AM 12/30/2019 Merge-Module():951,952 assert sorts into alpha order (make easier to find in the psm1) ; fixed/debugged monolithic build options, now works. Could use some code to autoupdate all .NOTES:Version fields, but that's for future. ;Added code to update against monolithic/non-dyn-incl psm1s. Parses CBH & meta blocks out & constructs a new psm1 from the content. ; dbgd merge-module.ps1 w/in process-NewModule.ps1, functional so far. ; parseHelp(): added CBH .INPUTS & .OUTPUTS, specifying returns hash of get-help parsed output, and presence of CBH in the file ; ; profile-FileAST: updated CBH: added INPUTS & OUTPUTS, including hash properties returned ; Get-CommentBlocks:updated cbh and added .INPUTS/.OUTPUTS cbh entries, detailing the subcompontents of the hashtable returned
# * 12:03 PM 12/29/2019 added else wh on pswls entries
# * 1:54 PM 12/28/2019 added merge-module to verb-dev ; Merge-Module fixed $sBnrSStart/End typo
# * 5:22 PM 12/15/2019initial vers includes Get-CommentBlocks, parseHelp, profile-FileAST, build-VSCConfig, Merge-Module
.DESCRIPTION
VERB-dev - Development PS Module-related generic functions
.INPUTS
None
.OUTPUTS
None
.EXAMPLE
.EXAMPLE
.LINK
https://github.com/tostka/verb-dev
#>


    $script:ModuleRoot = $PSScriptRoot ;
    $script:ModuleVersion = (Import-PowerShellDataFile -Path (get-childitem $script:moduleroot\*.psd1).fullname).moduleversion ;
    $runningInVsCode = $env:TERM_PROGRAM -eq 'vscode' ;

#*======v FUNCTIONS v======




#*------v backup-ModuleBuild.ps1 v------
function backup-ModuleBuild {
    <#
    .SYNOPSIS
    backup-ModuleBuild.ps1 - Backup current Module source fingerprint, Manifest (.psd1) & Module (.psm1) files to deep (c:\scBlind\[modulename]) backup, then creates a summary bufiles-yyyyMMdd-HHmmtt.xml file for the backup, in the deep backup directory.
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-25
    FileName    : backup-ModuleBuild
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    AddedCredit : REFERENCE
    AddedWebsite:	URL
    AddedTwitter:	URL
    REVISIONS
    * 10:35 AM 5/26/2022 minor cleanup
    * 12:11 PM 5/25/2022 init
    .DESCRIPTION
    backup-ModuleBuild.ps1 - Backup current Module source fingerprint, Manifest (.psd1) & Module (.psm1) files to deep (c:\scBlind\[modulename]) backup, then creates a summary bufiles-yyyyMMdd-HHmmtt.xml file for the backup, in the deep backup directory.

    ``text
    C:\SC\VERB-IO
    ├───Internal
    │       [Internal 'non'-exported cmdlet files].ps1 
    ├───Package
    │       verb-io.2.0.3.nupkg # RequiredRevision nupkg file location and name-structure
    ├───Public
    │       [Public exported cmdlet files].ps1
    └───verb-IO
        │   verb-IO.psd1 # module Manifest psd1
        │   verb-IO.psm1 # module .psm1 file
    ```

    .PARAMETER Name
    Module Name to have revised Public source directory import-module'd[-PARAM SAMPLEINPUT]
    .PARAMETER backupRoot
    Destination for extra-git backup files (generally mirrors dir structure of current module, defaults below c:\scBackup)[-backupRoot c:\path-to\backupdir\]
    .PARAMETER whatIf
    Whatif Flag  [-whatIf]
    .OUTPUT
    System.Object[] array reflecting full path to exch backed up module build file
    .EXAMPLE
    PS> backup-ModuleBuild -Name verb-io -verbose -whatif 
    Backup the verb-io module's current build with verbose output, and whatif pass
    .LINK
    https://github.com/tostka/verb-dev
    #>
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    [CmdletBinding()]
    #[Alias('iIseBpAll')]
    PARAM(
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Module Name to have revised Public source directory import-module'd[-PARAM SAMPLEINPUT]")]
        [ValidateNotNullOrEmpty()]
        #[Alias('ALIAS1', 'ALIAS2')]
        [string[]]$Name,
        [Parameter(HelpMessage="Destination for extra-git backup files (generally mirrors dir structure of current module, defaults below c:\scBackup)[-backupRoot c:\path-to\backupdir\]")]
        $backupRoot = 'C:\scblind', 
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue") ;
        $sBnr="#*======v $($CmdletName): v======" ; 
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;

        # files to be targeted for backup (MOD gets replaced with the module name)
        $templateFiles= 'fingerprint','MOD.psm1','MOD.psd1' ; 

        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ; 
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ; 
            write-verbose "(non-pipeline - param - input)" ; 
        } ; 
    }
    PROCESS {
        foreach ($item in $Name){
            $sBnrS="`n#*------v PROCESSING : $($item) v------" ; 
            write-host -foregroundcolor green $sBnrS ;

            $error.clear() ;
            TRY{
                $tmodfiles = gci "c:\sc\$item\*" -Recurse ; # collect all files in the module, then post-filter targets out.
                $targetFiles = $templateFiles|foreach-object{$tmodfiles |where name -eq $_.replace('MOD',$item)} | select -expand fullname ; 
                [system.io.fileinfo[]]$bupath = "$backupRoot\$item" ; 
                if($targetFiles){
                    $pltBUF=[ordered]@{Path = $targetFiles ;verbose=$verbose ;whatif = $($whatif); erroraction = 'STOP'} ; 
                    write-host "backup-fileTDO  w`n$(($pltBUF |out-string).trim())" ; 
                    if($bufiles = backup-fileTDO @pltBUF){
                        $xfiles = @() ;         
                        foreach($sfile in $bufiles){
                            $pltCI=[ordered]@{Path = $sfile ; destination = $sfile.replace('C:\sc',$backupRoot) ; verbose=$verbose ;whatif = $($whatif); erroraction = 'STOP'} ; 
                            if(-not (Test-path (split-path $pltCI.destination))){
                                write-host "(creating missing dest:$(split-path $pltCI.destination)" ; 
                                mkdir (split-path $pltCI.destination) -WhatIf:$($whatif) -erroraction 'STOP'; 
                            } ; 
                            write-host "copy-item w`n$(($pltCI |out-string).trim())" ; 
                            if(-not $whatif){
                                copy-item @pltCI ; 
                                $xfiles += $pltCI.destination ;    
                            } else {
                                write-host "(-whatif, skipping balance)" ; 
                            } ;       
                        } ; 
                        $ofile = "$bupath\bufiles-$(get-date -format 'yyyyMMdd-HHmmtt').xml" ; 
                        $pltXXML=[ordered]@{Path = $ofile ;verbose=$verbose ;whatif = $($whatif); erroraction = 'STOP'} ; 
                        write-host "Creating XML record of module backup:`nxxml w`n$(($pltXXML |out-string).trim())" ; 
                        $xfiles | xxml @pltXXML ; 
                        $xfiles | write-output ; 
                    } ; 
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-warning "$($smsg)" } ;
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;

            write-host -foregroundcolor green $sBnrS.replace('-v','-^').replace('v-','^-') ;
        } ;  # loop-E $items in $item
    } # PROC-E
    END{
        write-host -foregroundcolor green $sBnr.replace('=v','=^').replace('v=','^=') ; 
    } ;
}

#*------^ backup-ModuleBuild.ps1 ^------


#*------v check-PsLocalRepoRegistration.ps1 v------
function check-PsLocalRepoRegistration {
    <#
    .SYNOPSIS
    check-PsLocalRepoRegistration - Check for PSRepository for $localPSRepo, register if missing
    .NOTES
    Version     : 1.0.0
    Author: Todd Kadrie
    Website:	http://toddomation.com
    Twitter:	http://twitter.com/tostka
    CreatedDate : 2020-03-29
    FileName    : check-PsLocalRepoRegistration
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,Git,Repository
    REVISIONS
    * 7:00 PM 3/29/2020 init
    .DESCRIPTION
    check-PsLocalRepoRegistration - Check for PSRepository for $localPSRepo, register if missing
    .PARAMETER  User
    User security principal (defaults to current user)[-User `$SecPrinobj]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    $bRet = check-PsLocalRepoRegistration -Repository $localPSRepo 
    Check registration on the repo defined by variable $localPSRepo
    .LINK
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Local Repository [-Repository repoName]")]
        $Repository = $localPSRepo,
        [Parameter(HelpMessage="Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf=$true
    ) ; 
    $verbose = ($VerbosePreference -eq 'Continue') ; 
    # on cold installs there *is* no repo, precheck
    if($Repository){
        if(!(Get-PSRepository -Name $Repository -ea 0)){
            $repo = @{
                Name = 'lyncRepo' ;
                SourceLocation = $null;
                PublishLocation = $null;
                InstallationPolicy = 'Trusted' ;
            } ;
            if($Repository = 'lyncRepo'){
                $RepoPath = "\\lynmsv10\lync_fs\scripts\sc" ;
                $repo.Name = 'lyncRepo' ; 
                $repo.SourceLocation = $RepoPath ; 
                $repo.PublishLocation = $RepoPath ;
            } elseif($Repository = "tinRepo") {
                #Name = 'tinRepo', Location = '\\SYNNAS\archs\archs\sc'; IsTrusted = 'True'; IsRegistered = 'True'.
                $RepoPath = '\\SYNNAS\archs\archs\sc' ;
                $repo.Name = 'tinRepo' ; 
                $repo.SourceLocation = $RepoPath ; 
                $repo.PublishLocation = $RepoPath ;
            } else { 
                $smsg = "UNRECOGNIZED `$Repository" ; 
                if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warning } #Error|Warn|Debug 
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            }; 
            $smsg = "MISSING REPO REGISTRATION!`nRegister-PSRepository w`n$(($repo|out-string).trim())" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            if(!$whatif){
                $bReturn = Register-PSRepository @repo ;
                $bReturn | write-output ;             
            } else { 
                $smsg = "(whatif detected: skipping execution - Register-PSRepository lacks -whatif support)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            }
        } else {
            $smsg = "($Repository repository is already registered in this profile)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            $true | write-output ;              
        } ;  
    } else {
        $smsg = "MISSING REPO REGISTRATION!`nNO RECOGNIZED `$Repository DEFINED!" ; 
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warning } #Error|Warn|Debug 
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    }; 
}

#*------^ check-PsLocalRepoRegistration.ps1 ^------


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


#*------v confirm-ModulePsd1Version.ps1 v------
function confirm-ModulePsd1Version {
    <#
    .SYNOPSIS
    confirm-ModulePsd1Version - Enforce expected Module Build Version in Manifest .psd1 [modname]\[modname]\[modname].psd1 file (unlike test-modulemanifest/update-modulemanifest/update-MetaData, works with renamed temp files like xxx.psd1_TMP files)
    .NOTES
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
    .DESCRIPTION
   confirm-ModulePsd1Version - Enforce expected Module Build Version in Manifest .psd1 [modname]\[modname]\[modname].psd1 file (unlike test-modulemanifest/update-modulemanifest/update-MetaData, works with renamed temp files like xxx.psd1_TMP files)
    .PARAMETER Path
    Path to the temp file to be tested [-Path 'C:\sc\verb-IO\verb-IO\verb-io.psm1_TMP']
    .PARAMETER RequiredVersion
    Explicit 3-digit Version to be enforced[-Version 2.0.3]
    .PARAMETER whatIf
    Whatif Flag  [-whatIf]
    .EXAMPLE
    PS> $pltCMPV=[ordered]@{ Path = 'C:\sc\verb-IO\verb-IO\verb-IO.psd1' ; RequiredVersion = '2.0.3' ; whatif = $($whatif) ; verbose = $($verbose) ; } ;
    PS> $smsg = "confirm-ModulePsd1Version w`n$(($pltCMPV|out-string).trim())" ;
    PS> if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    PS> else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS> $bRet = confirm-ModulePsd1Version @pltCMPV ;
    PS> if ($bRet.valid -AND $bRet.Version){
    PS>     $smsg = "(confirm-ModulePsd1Version:Success)" ;
    PS>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS> } else {
    PS>     $smsg = "confirm-ModulePsd1Version:FAIL! Aborting!" ;
    PS>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>     Break ;
    PS> } ;
    Splatted call demo, confirming psd1 specified has Version properly set to '2.0.3', or the existing Version will be updated to comply.
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
        $rgxPsd1Version = "\s*ModuleVersion\s=\s'(\d*.\d*.\d*)'\s*" ;
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
            if ($RgxMatch = Get-ChildItem $File | select-string -Pattern $rgxPsd1Version ) {
                #$testVersion = $RgxMatch.matches[0].Groups[9].value.tostring() ; # guid match target
                $testVersion = $RgxMatch.matches[0].Groups[1].value.tostring()
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
                    } | out-string ;
                    $bRet = Set-ContentFixEncoding @pltSCFE -Value $newContent ;
                    if (-not $bRet -AND -not $whatif) { throw "Set-ContentFixEncoding $($File)!" } else {
                        $objReport.Version= $RequiredVersion ;
                    } ;
                } ;
            } else {
                $smsg = "UNABLE TO Regex out...`n$($rgxPsd1Version)`n...from $($File)`nTestScript hasn't been UPDATED!" ;
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

#*------^ confirm-ModulePsd1Version.ps1 ^------


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


#*------v confirm-ModuleTestPs1Guid.ps1 v------
function confirm-ModuleTestPs1Guid {
    <#
    .SYNOPSIS
    confirm-ModuleTestPs1Guid - Enforce expected Module Build Guid in Pester [modname]\Tests\[modname].tests.ps1 file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-31
    FileName    : confirm-ModuleTestPs1Guid
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging,Pester
    REVISIONS
    * 12:06 PM 6/1/2022 updated CBH example; rem'd unused hash properties on report
    * 4:03 PM 5/31/2022 init
    .DESCRIPTION
    confirm-ModuleTestPs1Guid - Enforce expected Module Build Guid in Pester [modname]\Tests\[modname].tests.ps1 file
    .PARAMETER Path
    Path to the temp file to be tested [-Path 'C:\sc\verb-IO\verb-IO\verb-io.psm1_TMP']
    .PARAMETER RequiredGuid
    Psd1 Module Guid[-RequiredGuid `$guid]
    .PARAMETER whatIf
    Whatif Flag  [-whatIf]
    .EXAMPLE
    PS> $pltCMTPG=[ordered]@{ Path = 'C:\sc\verb-IO\Tests\verb-IO.tests.ps1' ; RequiredGuid = '12cb1eb4-ac9c-405e-8711-e80c914a9b32' ; whatif = $($whatif) ; verbose = $($verbose) ; } ;
    PS> $smsg = "confirm-ModuleTestPs1Guid w`n$(($pltCMTPG|out-string).trim())" ;
    PS> if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    PS> else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS> $bRet = confirm-ModuleTestPs1Guid @pltCMTPG ;
    PS> if ($bRet.valid -AND $bRet.GUID){
    PS>     $smsg = "(confirm-ModuleTestPs1Guid:Success)" ;
    PS>     if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>     objReport.Guid = $psd1guid ;
    PS> } else {
    PS>     $smsg = "confirm-ModuleTestPs1Guid:FAIL! Aborting!" ;
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
        #[Parameter(HelpMessage="Explicit 3-digit Version specification[-Version 2.0.3]")]
        #[version]$RequiredVersion,
        [Parameter(HelpMessage="Psd1 Module Guid[-RequiredGuid `$guid]")]
        [guid]$RequiredGuid,
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

        $rgxTestScriptNOGuid = "Please\sPaste\shere\syour\smodule\sGuid\s-\sTest-ModuleManifest\s'<ModulePath>'\s\|\sSelect-Object\s-ExpandProperty\sGuid" ;
        $rgxTestScriptGuid = '\.Guid((\s)*)\|((\s)*)Should((\s)*)-Be((\s)*)"([0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12})"'
        $rgxGuid = "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}" ;

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
                Guid = $null ;
                #Version = $null ; 
                Valid = $false ;
            }

            $pltSCFE = [ordered]@{Path = $File ; PassThru = $true ; Verbose = $($verbose) ; whatif = $($whatif) ; }
            if ($RgxMatch = Get-ChildItem $File | select-string -Pattern $rgxTestScriptNOGuid ) {
                $smsg = "(initial match on `rgxTestScriptNOGuid)" 
                if ($verbose) {
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level INFO } #Error|Warn|Debug
                    else { write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
                $newContent = (Get-Content $File) | Foreach-Object {
                    $_ -replace $rgxTestScriptNOGuid, "$($RequiredGuid)"
                } | out-string ;
                $bRet = Set-ContentFixEncoding @pltSCFE -Value $newContent ;
                if (-not $bRet -AND -not $whatif) { throw "Set-ContentFixEncoding $($File)!" } else {
                    $objReport.Guid = $RequiredGuid ;
                } ;
            } elseif ($RgxMatch = Get-ChildItem $File | select-string -Pattern $rgxTestScriptGuid ) {
                $testGuid = $RgxMatch.matches[0].Groups[9].value.tostring() ; ;
                if ($testGuid -eq $RequiredGuid) {
                    $smsg = "(Guid  already updated to match)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level INFO } #Error|Warn|Debug
                    else { write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $objReport.Guid = $RequiredGuid ;
                } else {
                    $smsg = "In:$($File)`nGuid present:($testGuid)`n*does not* properly match:$($RequiredGuid)`nFORCING MATCHING UPDATE!" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                    else { write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    # generic guid replace: $_ -replace $rgxGuid, "$($RequiredGuid)"

                    $newContent = (Get-Content $File) | Foreach-Object {
                        $_ -replace $testGuid, "$($RequiredGuid)"
                    } | out-string ;
                    $bRet = Set-ContentFixEncoding @pltSCFE -Value $newContent ;
                    if (-not $bRet -AND -not $whatif) { throw "Set-ContentFixEncoding $($File)!" } else {
                        $objReport.Guid = $RequiredGuid ;
                    } ;
                } ;
            } else {
                $smsg = "UNABLE TO Regex out...`n$($rgxTestScriptNOGuid)`n...from $($File)`nTestScript hasn't been UPDATED!" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else { write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $objReport.Guid = $null ;
            } ;
            #-=-=-=-=-=-=-=-=


            <#$objReport=[ordered]@{
                Manifest=$null ;
                Module = $null ;
                Guid = $null ;
                #Version = $null ; 
                Valid = $false ;
            }#>
            $smsg = "`$objReport`n$(($objReport|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            if($objReport.Guid){
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
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    } ;  # END-E
}

#*------^ confirm-ModuleTestPs1Guid.ps1 ^------


#*------v convert-CommandLine2VSCDebugJson.ps1 v------
function convert-CommandLine2VSCDebugJson {
    <#
    .SYNOPSIS
    convert-CommandLine2VSCDebugJson - Process a sample ISE debugging command line, and convert it to a VSC launch.json 'configurations' entry
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2:58 PM 12/15/2019
    FileName    :convert-CommandLine2VSCDebugJson.ps1
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    REVISIONS
    * 9:28 AM 8/3/2020 ren'd build-vscconfir -> convert-CommandLine2VSCDebugJson, and added alias:convert-cmdline2json, porting into verb-dev module ; refactored name & script tag resolution, and accomdates leading dot-source(.), invocation (&), and local dir (.\) 1-2 chars of cmdline ; coerced right side of args assignement into [array](required in launch.json spec)
    * 5:51 PM 12/16/2019 added OneArgument param
    * 2:58 PM 12/15/2019 INIT
    .DESCRIPTION
    convert-CommandLine2VSCDebugJson - Converts a typical 'ISE-style debugging-launch commandline', into a VSC  launch.json-style 'configurations' block. 
    launch.json is in the .vscode subdir of each open folder in VSC's explorer pane
    
    General Launch.json editing notes: (outside of the output of this script, where customization is needed to get VSC debugging to work):
    #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    # Vsc - Debugging Launch.json

    ## Overview 

    -There's one per local workspace, stored in:

    ```C:\sc\powershell\[script dir]\.vscode\launch.json```

    -You can debug a simple application even if you don't have a folder open in VS Code but it is not possible to manage launch configurations and setup advanced debugging. For that, you have to open a folder in your workspace.

    -For advanced debugging, you first have to open a folder and then set up your launch configuration file - `launch.json`. Click on the *Configure gear*  icon on the Debug view top bar and VS Code will generate a `launch.json` file under your workspace's `.vscode` folder. VS Code will try to automatically detect your debug environment, if unsuccessful you will have to choose your debug environment manually.

    -Use IntelliSense if your cursor is located inside the configurations array.

    -The extension handles params, not VSCode. Ext env is config'd via `launch.json` file. Process:

    1.  Click Debug pane icon [not-bug]
    2.  Debug view top bar: Click [gear] icon => Opens launch.json for the workspace's .json folder for editing

    1.  As with all .json's, all but the last line end with comma (`,`), and `//` is the rem command
    2.  Note backslashes have to be doubled:

    ```json
    // Command line arguments passed to the program.
    ```

    ## Debug Arg launch.json entry examples:

    -   **`args` entry:**

    JSON array of command-line arguments to pass to the program when it is launched. Example `["arg1", "arg2"]`. If you are escaping characters, you will need to double escape them. For example, `["{[\\\"arg1\\\](file:///%22arg1/)": true}"]` will send `{"arg1": true}` to your application.<br>
    Example:

    ```json
    "args": [ "-TargetMbxsCSV 'C:\\usr\\work\\incid\\311526-onprem-deliver.csv' -Senders 'Daniel.Breton@sightpathmedical.com' -ExternalSender -Subject 'Quick Review' -logonly:$true -deletecontent:$false -whatif:$true" ],
    ```

    -   **`cwd` entry**

    Sets the working directory of the application launched by the debugger.
    Example:

    ```json
    "cwd": "${workspaceFolder}"
    ```

    -   **`env` 'environment' entry**

    Environment variables to add to the environment for the program. 
    Example: (creates 'name' & 'value' evaris)
    ```json
    "env": "[ { "name": "squid", "value": "clam" } ]",
    ```

    >Also has also support for supplying input to Read-Host via the Debug Console input prompt.

    - Configure Environment Variable support in launch.json:

    1. Use the "configurations": [� "env":  ]section:<br>
    It's in "vari-name":"vari-value" format

    ```json
    "env": {"AWS_REGION":"us-east-1", "SLS_DEBUG":"*"},
    ```

    ## Launch.json Arg cmdline param passing examples

    -   **`args`** - arguments passed to the program to debug. This attribute is of type array and expects individual arguments as array elements.
    -   The rule to translate a command line to the "args" is simple: *every command line argument separated by whitespace needs to become a separate item of the "args" attribute.*
    -   **Exception to the rule above: when you need *key:value*  args:**

    ```text
    $ python main.py --verbose --name Test
    ```

    -   above is coded inside the launch.json args line as:

    ```json
    args:["--verbose","--name=Test"],  
    ```
        
    -   **Watson example shows another variant:**  
        
        ```json
        "program": "${workspaceFolder}/console.py" 
        "args": ["dev", "runserver", "--noreload=True"],
        ```
    
    - Other examples:
    ```json
    // 3 ways to spec the same switch/key-value: (all work)
    "args": ["-Verbose"],
    "args": ["-Verbose:$true"],
    "args": ["-Verbose:", "$true"],
    // separating across lines & array elems
    "args": [   "-arg1 value1",
                "-argname2 value2"],
    ```

    - **These reflect editing the existing empty entry:**

    ```json
    "args": [""],

    // can spread them out on lines too
    "args": [
    "--nolazy"
    ],

    // feed them all on one string (ala cmdline)
    "args": [ "-Param1 foo -Recurse" ],

    "args": ["-Count 55 -DelayMilliseconds 250"],

    // or feed them as an array of params comma-quoted

    // below,will be concatenated to a single string w space delim

    "args": [ "-Path", "C:\\Users\\Keith", "*.ps1", "-Recurse" ],

    // another example, long one:
    "args": [
    "-u",
    "tdd",
    "--compilerOptions",
    "--require",
    "ts-node/register",
    "--require",
    "jsdom-global/register",
    "--timeout",
    "999999",
    "--colors",
    "${file}"
    ],

    /// another with param values
    "args": [
    "${workspaceRoot}/tools/startTest.js",
    "--require", "ts-node/register",
    "--watch-extensions", "ts,tsx",
    "--require", "babel-register",
    "--watch-extensions", "js",
    "tests/**/*.spec.*"
    ],

    /// another
    "args": [  "-arg1 value1",
    "-argname2 value2"],

    //another
    "args": [
    "${command:SpecifyScriptArgs}"
    ],

    // $ python main.py --verbose --name Test
    args:["--verbose","--name=Test"],

    // spaces in parameters

    // need pass the args FIRST ARGUMENT and SECOND ARGUMENT as the first and second argument. But comes through as 4 arguments: 
    FIRST, ARGUMENT, SECOND, ARGUMENT

    // You need to include the quotes in the args strings and escape them:
    "args": ["\"FIRST ARGUMENT\"", "\"SECOND ARGUMENT\""]

    // linux gnome-terminal version
    "program": "/usr/bin/gnome-terminal",
    "args": ["-x", "/usr/bin/powershell", "-NoExit", "-f", "${file}"],
    ```

    Besides ${workspaceRoot} and ${file}, the following variables are available for use in launch.json:
    |variable|Notes|
    |--------|-----|
    |${workspaceRoot}|the path of the folder opened in Visual Studio Code|
    |${workspaceRootFolderName}|the name of the folder opened in Visual Studio Code without any solidus (/)|
    |${file}|the current opened file|
    |${relativeFile}|the current opened file relative to workspaceRoot|
    |${fileBasename}|the current opened file�s basename|
    |${fileBasenameNoExtension}|the current opened file�s basename with no file extension|
    |${fileDirname}|the current opened file�s dirname|
    |${fileExtname}|the current opened file�s extension|
    |${cwd}|the task runner�s current working directory on startup|
    |${env.USERPROFILE}|To reference env varis ; `env` must be all lowercase, and can't be `env[colon]`, must be `env[period]` *(vsc syntax, not powershell)*|
    #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    .PARAMETER  CommandLine
    CommandLine to be converted into a launch.json configuration
    .PARAMETER OneArgument
    Flag to specify all arguments should be in a single unparsed entry[-OneArgument]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    $bRet = convert-CommandLine2VSCDebugJson -CommandLine $updatedContent -showdebug:$($showdebug) -whatif:$($whatif) ;
    if (!$bRet) {Continue } ;
    .LINK
    #>
    [CmdletBinding()]
    [Alias('convert-cmdline2json')]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "CommandLine to be parsed into launch.json config syntax [-CommandLine script.ps1 arguments]")]
        [ValidateNotNullOrEmpty()]$CommandLine,
        [Parameter(HelpMessage = "Flag to specify all arguments should be in a single unparsed entry[-OneArgument]")]
        [switch] $OneArgument = $true
    ) ;
    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
    # Get parameters this function was invoked with
    $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
    $Verbose = ($VerbosePreference -eq 'Continue') ; 

    $parsedCmdLine = Split-CommandLine -CommandLine $CommandLine | Where-Object { $_.length -gt 1 }  ;
    $ttl = ($parsedCmdLine | Measure-Object).count ;
    
    # you *can* build the json object as a hash, you just need to type the args attrib as array @() e.g. args = @("-Count 42 -DelayMillseconds 2000") ;
    $jsonRequest = [ordered]@{
        type    = "PowerShell";
        request = "launch";
        name    = $null ;
        script  = $null 
        args    = $() ;
        cwd     = "`${workspaceRoot}";
    } ;
    if ($OneArgument) {write-verbose "(-OneArgument specified: Generating single-argument output)" } ; 

    $lastConsumeditem = 0 ; 
    $error.clear() ;
    TRY {
        # parse out the name & script values from the first couple of elements
        if($parsedCmdLine[0].length -eq 1 -AND ($parsedCmdLine[0] -match '(&|.)') ){
            # invocation/dot-source char, skip it
            #$1stIsPunc = $true ; 
            $jsonRequest.name = "PS $(split-path $parsedCmdLine[1] -leaf)" ;
            $jsonRequest.script  = (resolve-path -path $parsedCmdLine[1]).path ;
            $lastConsumeditem = 1 ; 
        }elseif( ($parsedCmdLine[0].substring(0,2) -eq '.\') -OR ($parsedCmdLine[0] -match '(\\|\/)') ){ 
            # relative path ref, or apparent path, resolve it
            $jsonRequest.name = "PS $(split-path $parsedCmdLine[0] -leaf)" ;
            $jsonRequest.script  = (resolve-path -path $parsedCmdLine[0]).path ;
        }elseif ($parsedCmdLine[0] -match '(.+?)(\.[^.]*$|$)'){
            # if it's a single word or word with ext, it may be a system pathed OS cmd, use it as it lies
            $jsonRequest.name =  "PS $($parsedCmdLine[0])" ;
            $jsonRequest.script  = $parsedCmdLine[0] ; 
        } else {
            # , use it as it lies
            $jsonRequest.name =  "PS $($parsedCmdLine[0])" ;
            $jsonRequest.script  = $parsedCmdLine[0] ; 
        } ; 
        $lastConsumeditem++ ; 
        if ($ttl -gt 1) {
            if ($OneArgument) {
                write-verbose -verbose:$true "(-OneArgument specified: Generating single-argument output)" ; 
                # isn't coming out an array, so coerce it on the data assignement - that works
                $jsonRequest.args = [array]($parsedCmdLine[$lastConsumeditem..$($ttl)] -join " ") ;
            }
            else {
                # args are from after 'lastConsumeditem' through last elem
                $jsonRequest.args = [array]($parsedCmdLine[$lastConsumeditem..$($ttl)]) ; 
            } ;
        } else { 
            write-verbose -verbose:$true "Only a single parsed item in CommandLine:`n$($CommandLine)" ; ;
        } ; 

        write-verbose "$((get-date).ToString('HH:mm:ss')):ConvertTo-Json w`n$(($jsonRequest|out-string).trim())`nargs:`n$(($jsonRequest.args|out-string).trim())" ;
        $cfg = $jsonRequest | convertto-json ;
    }
    CATCH {
        Write-Error "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        $false | Write-Output ;
        CONTINUE #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
    } ;
    <# thought was having formatting issues, so put through a tmp file at one point
    $cfgTempFile = [System.IO.Path]::GetTempFileName().replace('.tmp', '.json') ;
    Set-FileContent -Text $cfg -Path $cfgTempFile -showDebug:$($showDebug) -whatIf:$($whatIf);
    write-verbose -verbose:$true "Generated launch.json config entry for input:`n w`n$((get-command $cfgTempFile |out-string).trim())" ;
    #>
    write-verbose -verbose:$true "Generated launch.json config entry for input:`n w`n$(($cfg|out-string).trim())`n`n(copied to clipboard)" ;
    $cfg | C:\WINDOWS\System32\clip.exe ;
    $true | write-output ;
}

#*------^ convert-CommandLine2VSCDebugJson.ps1 ^------


#*------v convertFrom-EscapedPSText.ps1 v------
Function convertFrom-EscapedPSText {
    <#
    .SYNOPSIS
    convertFrom-EscapedPSText - convert a previously backtick-escaped scriptblock of Powershell code text, to an un-escaped equivelent - specifically removing backtick-escape found on all special characters [$*\~;(%?.:@/]. 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-11-08
    FileName    : convertFrom-EscapedPSText.ps1
    License     : MIT License
    Copyright   : (c) 2021 Todd Kadrie
    Github      : https://github.com/tostka/verb-text
    Tags        : Powershell,Text
    AddedCredit : REFERENCE
    AddedWebsite:	URL
    AddedTwitter:	URL
    REVISIONS
    * 12:44 PM 6/17/2022 update CBH; move verb-text -> verb-dev
    * 2:10 PM 3/1/2022 updated the ScriptBlock param to string-array [string[]], preserves the multi-line nature of original text (otherwise, ps coerces arrays into single-element strings)
    * 11:09 AM 11/8/2021 init
    .DESCRIPTION
    convertFrom-EscapedPSText - convert a previously backtick-escaped scriptblock of Powershell code text, to an un-escaped equivelent - specifically removing backtick-escape found on all special characters [$*\~;(%?.:@/]. 
    Intent is to run this *after* to running a -replace pass on a given piece of pre-escaped Powershell code as text (parsing & editing scripts with powershell itself), to ensure the special characters in the block are no longer treated as literal text. Prior to doing search and replace, one would typically have escaped the special characters by running convertTo-EscapedPSText() on the block. 
    .PARAMETER  ScriptBlock
    Semi-colon-delimited ScriptBlock of powershell to be wrapped at 
    .EXAMPLE
    PS>  # pre-escape PS special chars
    PS>  $ScriptBlock = get-content c:\path-to\script.ps1 ; 
    PS>  $ScriptBlock=convertTo-EscapedPSText -ScriptBlock $ScriptBlock ; 
    PS>  $splitAt = ";" ; 
    PS>  $replaceWith = ";$([Environment]::NewLine)" ; 
    PS>  # ";`r`n"  ; 
    PS>  $ScriptBlock = $ScriptBlock | Foreach-Object {$_ -replace $splitAt, $replaceWith } ; 
    PS>  $ScriptBlock=convertFrom-EscapedPSText -ScriptBlock $ScriptBlock ; 
    PS>  
    Load a script file into a $ScriptBlock vari, escape special characters in the $Scriptblock, run a wrap on the text at semicolons (replace ';' with ';`n), then unescape the specialcharacters in the scriptblock, back to original functional state. 
    .LINK
    https://github.com/tostka/verb-Text
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$false,HelpMessage="ScriptBlock
    Semi-colon-delimited ScriptBlock of powershell to be wrapped at [-ScriptBlock 'c:\path-to\script.ps1']")]
        [Alias('Code')]
        [string[]]$ScriptBlock
    )  ; 
    if(-not $ScriptBlock){
        $ScriptBlock= (get-clipboard) # .trim().replace("'",'').replace('"','') ;
        if($ScriptBlock){
            write-verbose "No -ScriptBlock specified, detected text on clipboard:`n$($ScriptBlock)" ;
        } else {
            write-warning "No -path specified, nothing suitable found on clipboard. EXITING!" ;
            Break ;
        } ;
    } else {
        write-verbose "ScriptBlock:$($ScriptBlock)" ;
    } ;
    # issue specific to PS, -replace isn't literal, see's $ as variable etc control char
    # to escape them, have to dbl: $password.Replace('$', $$')
    #$ScriptBlock = $ScriptBlock.Replace('$', '$$');
    # rgx replace all special chars, to make them literals, before doing the replace (graveaccent escape ea matched char in the [$*\~;(%?.:@/] range)
    $ScriptBlock = $scriptblock -replace "``([$*\~;(%?.:@/]+)",'$1'; 
    $ScriptBlock | write-output ; 
}

#*------^ convertFrom-EscapedPSText.ps1 ^------


#*------v Convert-HelpToHtmlFile.ps1 v------
function Convert-HelpToHtmlFile {
    <#
    .SYNOPSIS
    Convert-HelpToHtmlFile.ps1 - Create a HTML help file for a PowerShell module.
    .NOTES
    Version     : 1.2.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2023-10-02
    FileName    : Convert-HelpToHtmlFile.ps1
    License     : (None Asserted)
    Copyright   : (None Asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell, development, html, markdown, conversion
    AddedCredit : Øyvind Kallstad @okallstad
    AddedWebsite: https://communary.net/
    AddedTwitter: @okallstad / https://twitter.com/okallstad
    REVISIONS
    * 1:47 PM 10/12/2023 fix typo: #99: $(!) ; add dep chk, defer to $scriptdir, avoids need to run pwd in the module, for loc of resource incl files (which don't actually work; should create a browesr left pane menu for nav, it never appears on modern browsers).
    * 9:50 AM 10/3/2023 add: -markdownhelp echos ; add:CBH expl that demos capture & recycle of output filename through convert-HtmlToMarkdown equivelent markdown .md doc. The CBH -> markdown via PlattyPS New-MarkdownHelp yields decent leaf cmdlet docs, but doesn't create the same holistic module nav-menued .html doc (which can be manually created with convert-htmlToMarkdown, tho the menues don't work)
    * 3:58 PM 10/2/2023 added -MarkdownHelp and simple call branching each commandlet process into plattyps to output quick markdown .md files in the parent dir of -Destination ; 
    Moving this into verb-dev, no reason it should sit in it's own repo (renaming Invoke-CreateModuleHelpFile -> Convert-HelpToHtmlFile) ; 
    ren & alias ModuleName -> CodeObject ;
    Rounded out -script/non-module support by splicing in my verb-dev:get-HelpParsed() which parses the CBH content (via get-help) and returns metadata I routinely populate in the Notes CBH block.
    This provided more details to use in the resulting output html, to make it *closer* to the native module data; 
    Also updated html output - wasn't displaying key:value side by side, so I spliced in prehistoric html tables to force them into adjacency
    And finally fixed the NOTES CBH output, expanding the line return -><br> replacements to cover three different line return variant formats: Notes now comes out as a properly line-returned block, similar to the CBH appearance in the source script.
    * 9:17 AM 9/29/2023 rewrote to support conversion for scripts as well; added 
    -script & -nopreview params (as it now also auto-previews in default browser);  
    ould be to move the html building code into a function, and leave the module /v script logic external to that common process.
    expanded CBH; put into OTB & advanced function format; split trycatch into beg & proc blocks
    10/18/2014 OK's posted rev 1.1
    .DESCRIPTION
    Convert-HelpToHtmlFile.ps1 - Create a HTML help file for a PowerShell module or script.
    
    - For modules, generates a full HTML help file for all commands in the module, with a nav menu at the top.
    - For scripts it generates same for the script's CBH content. 

    Updated variant of Øyvind Kallstad's Invoke-CreateModuleHelpFile() function. 

    Dependancies:
    - Rendered html uses jquery, the bootstrap framework & jasny bootstrap add-on (and following .css files):
            jasny-bootstrap.min.css
            jasny-bootstrap.min.js
            jquery-1.11.1.min.js
            navmenu.css
            bootstrap.min.css
            bootstrap.min.js
    - my verb-dev:get-HelpParsed() (to parse script CBH into rough equivelent's of get-module metadata outputs, drops missing details from output if unavailable).

    .PARAMETER CodeObject
    Name of module or path to script [-CodeObject myMod]
    .PARAMETER Destination
    Directory into which 'genericly-named output files should be written, or the full path to a specified output file[-Destination c:\pathto\MyModuleHelp.html]
    .PARAMETER SkipDependencyCheck
    Skip dependency check[-SkipDependencyCheck] 
    .PARAMETER Script
    Switch for processing target Script files (vs Modules, overrides natural blocks on processing scripts)[-Script]
    .PARAMETER MarkdownHelp
    Switch to use PlatyPS to output markdown help variants[-MarkdownHelp]
    .PARAMETER NoPreview
    Switch to suppress trailing preview of html in default browser[-NoPreview]
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    System.Object.string converted file path(s) returned to pipeline
    System.Boolean
    [| get-member the output to see what .NET obj TypeName is returned, to use here]
    .EXAMPLE
    PS> Convert-HelpToHtmlFile -CodeObject 'verb-text' -Destination 'c:\temp\verb-text_HLP.html' -verbose ; 
    Generate Html Help file for 'verb-text' module and save it as explicit filename 'c:\temp\verb-text_HLP.html' with verbose output.
    .EXAMPLE
    PS> Convert-HelpToHtmlFile -CodeObject 'c:\usr\work\ps\scripts\move-ConvertedVidFiles.ps1' -Script -destination 'c:\temp\'  -verbose ; 
    Generate Html Help file for the 'move-ConvertedVidFiles.ps1' script and save it as with a generated default name (move-ConvertedVidFiles_HELP.html) to the 'c:\temp\' directory with verbose output.
    .EXAMPLE
    PS> Convert-HelpToHtmlFile -CodeObject 'verb-text' -Destination 'c:\temp\' -verbose ; 
    Generate Html Help file for 'verb-text' module and save it as specified directory, with generated xxx_HELP.html filename, and verbose output.
    .EXAMPLE
    PS> write-verbose "convert CBH for the verb-text module into html & assign the returned output path(s) to $ifile" ; 
    PS> $ifile = Convert-HelpToHtmlFile -ModuleName 'verb-text' -destination 'c:\temp\' ; 
    PS> write-verbose "then convert the .html output files to markdown using the convert-html-ToMarkdown module/command (recycling the input file names)" ; 
    PS> $ifile | ?{$_ -match '\.html$'} | %{$ofile = $_.replace('/','\').replace('.html','.md') ; write-host "==$($ifile)->$($ofile):" ; get-content $_ -raw -force | Convert-HtmlToMarkdown -UnknownTags bypass | Set-Content -path $ofile -enc utf8 -force} ; 
    Demo conversion of a module's CBH help to first html, and then the .html to markdown .md equivelent (via Brian Lalonde's seperate convert-HtmlToMarkdown binary module)
    .LINK
    https://github.com/tostka/Invoke-CreateModuleHelpFile
    https://github.com/tostka/verb-dev
    .LINK
    https://github.com/gravejester/Invoke-CreateModuleHelpFile
    .LINK
    #>
    [CmdletBinding()]
    [Alias('Invoke-CreateModuleHelpFile')]
    PARAM(
        # Name of module. Note! The module must be imported before running this function.
        [Parameter(Mandatory = $true,HelpMessage="Name of module or path to script [-CodeObject myMod]")]
            [ValidateNotNullOrEmpty()]
            [Alias('ModuleName','Name')]
            [string] $CodeObject,
        # Full path and filename to the generated html helpfile.
        [Parameter(Mandatory = $true,HelpMessage="Full path and filename to the generated html helpfile[-Path c:\pathto\MyModuleHelp.html]")]
            [ValidateScript({Test-Path $_ })]
            [string] $Destination,
        [Parameter(HelpMessage="Skip dependency check[-SkipDependencyCheck]")]
            [switch] $SkipDependencyCheck,
        [Parameter(HelpMessage="Switch for processing target Script files (vs Modules)[-Script]")]
            [switch] $Script,
        [Parameter(HelpMessage="Switch to use PlatyPS to output markdown help variants[-MarkdownHelp]")]
            [switch]$MarkdownHelp,
        [Parameter(HelpMessage="Switch to suppress trailing preview of html in default browser[-NoPreview]")]
            [switch] $NoPreview
    ) ; 
    BEGIN{
        #region CONSTANTS-AND-ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        write-verbose "`$PSBoundParameters:`n$(($PSBoundParameters|out-string).trim())" ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
        #region ENVIRO_DISCOVER ; #*------v ENVIRO_DISCOVER v------
        #if ($PSScriptRoot -eq "") {
        # 8/29/2023 fix logic break on psv2 ISE (doesn't test PSScriptRoot -eq '' properly, needs $null test).
        #if( -not (get-variable -name PSScriptRoot -ea 0) -OR ($PSScriptRoot -eq '')){
        if( -not (get-variable -name PSScriptRoot -ea 0) -OR ($PSScriptRoot -eq '') -OR ($PSScriptRoot -eq $null)){
            if ($psISE) { $ScriptName = $psISE.CurrentFile.FullPath } 
            elseif($psEditor){
                if ($context = $psEditor.GetEditorContext()) {$ScriptName = $context.CurrentFile.Path } 
            } elseif ($host.version.major -lt 3) {
                $ScriptName = $MyInvocation.MyCommand.Path ;
                $PSScriptRoot = Split-Path $ScriptName -Parent ;
                $PSCommandPath = $ScriptName ;
            } else {
                if ($MyInvocation.MyCommand.Path) {
                    $ScriptName = $MyInvocation.MyCommand.Path ;
                    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent ;
                } else {throw "UNABLE TO POPULATE SCRIPT PATH, EVEN `$MyInvocation IS BLANK!" } ;
            };
            if($ScriptName){
                $ScriptDir = Split-Path -Parent $ScriptName ;
                $ScriptBaseName = split-path -leaf $ScriptName ;
                $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($ScriptName) ;
            } ; 
        } else {
            if($PSScriptRoot){$ScriptDir = $PSScriptRoot ;}
            else{
                write-warning "Unpopulated `$PSScriptRoot!" ; 
                $ScriptDir=(Split-Path -parent $MyInvocation.MyCommand.Definition) + "\" ;
            }
            if ($PSCommandPath) {$ScriptName = $PSCommandPath } 
            else {
                $ScriptName = $myInvocation.ScriptName
                $PSCommandPath = $ScriptName ;
            } ;
            $ScriptBaseName = (Split-Path -Leaf ((& { $myInvocation }).ScriptName))  ;
            $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($MyInvocation.InvocationName) ;
        } ;
        if(-not $ScriptDir){
            write-host "Failed `$ScriptDir resolution on PSv$($host.version.major): Falling back to $MyInvocation parsing..." ; 
            $ScriptDir=(Split-Path -parent $MyInvocation.MyCommand.Definition) + "\" ;
            $ScriptBaseName = (Split-Path -Leaf ((&{$myInvocation}).ScriptName))  ; 
            $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($MyInvocation.InvocationName) ;     
        } else {
            if(-not $PSCommandPath ){
                $PSCommandPath  = $ScriptName ; 
                if($PSCommandPath){ write-host "(Derived missing `$PSCommandPath from `$ScriptName)" ; } ;
            } ; 
            if(-not $PSScriptRoot  ){
                $PSScriptRoot   = $ScriptDir ; 
                if($PSScriptRoot){ write-host "(Derived missing `$PSScriptRoot from `$ScriptDir)" ; } ;
            } ; 
        } ; 
        if(-not ($ScriptDir -AND $ScriptBaseName -AND $ScriptNameNoExt)){ 
            throw "Invalid Invocation. Blank `$ScriptDir/`$ScriptBaseName/`ScriptNameNoExt" ; 
            BREAK ; 
        } ; 

        $smsg = "`$ScriptDir:$($ScriptDir)" ;
        $smsg += "`n`$ScriptBaseName:$($ScriptBaseName)" ;
        $smsg += "`n`$ScriptNameNoExt:$($ScriptNameNoExt)" ;
        $smsg += "`n`$PSScriptRoot:$($PSScriptRoot)" ;
        $smsg += "`n`$PSCommandPath:$($PSCommandPath)" ;  ;
        write-verbose $smsg ; 
        #endregion ENVIRO_DISCOVER ; #*------^ END ENVIRO_DISCOVER ^------

        # jquery filename - remember to update if you update jquery to a newer version
        $jqueryFileName = 'jquery-1.11.1.min.js'

        # define dependencies
        $dependencies = @('bootstrap.min.css','jasny-bootstrap.min.css','navmenu.css',$jqueryFileName,'bootstrap.min.js','jasny-bootstrap.min.js')

        TRY {
            # check dependencies - revise pathing to $ScriptDir (don't have to run pwd the mod dir)
            if($hostedModule = get-command $CmdletName | select -expand ModuleName){
                if($ModGMO = Get-Module -list -name $hostedModule){
                    $deppath = $ModGMO.ModuleBase ; 
                } else { 
                    #$deppath = $scriptdir
                    throw "Unable to Get-Module -list -name $($hostedModule)!" ; 
                    break ; 
                } ;  

            } else { 
                $deppath = $scriptdir
            } ; 
            if (-not($SkipDependencyCheck)) {
                $missingDependency = $false
                foreach($dependency in $dependencies) {
                    #if(-not(Test-Path -Path ".\$($dependency)")) {
                    if(-not(Test-Path -Path (join-path -path $scriptdir -ChildPath $dependency))) {
                        Write-Warning "Missing: $($dependency)"
                        $missingDependency = $true
                    }
                }
                if($missingDependency) { break }
                Write-Verbose 'Dependency check OK'
            } ; 

            # add System.Web - used for html encoding
            Add-Type -AssemblyName System.Web ; 
        } CATCH {
            Write-Warning $_.Exception.Message ; 
        } ; 

        if($MarkdownHelp){
            $smsg = "-MarkdownHelp specified: Loading PlatyPS module & will generate leaf commandlet '[cmdlet name].md' output files in specified destination dir"
            write-host -ForegroundColor yellow $smsg  ;
            write-verbose "Test platyPS dependancy..." ; 
            TRY{Import-Module platyPS -ea STOP} CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
            } ; 
        } ; 
    }  ;  # BEG-E
    PROCESS {
        $Error.Clear() ; 
    
        foreach($ModName in $CodeObject) {
            $smsg = $sBnrS="`n#*------v PROCESSING : $($ModName) v------" ; 
            if($Script){
                $smsg = $smsg.replace(" v------", " (PS1 scriptfile) v------")
            } ; 
            write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;

            # if $modName is pathed, split it to the leaf
            if( (split-path $modName -ea 0) -OR ([uri]$modName).isfile){
                write-verbose "converting pathed $($modname) to leaf..." ; 
                #$leafFilename = split-path $modname -leaf ; 
                $leaffilename = (get-childitem -path $modname).basename ; 
            } else {
                $leafFilename = $modname ; 
            }; 

            #if(test-path -path $Destination -PathType container -ErrorAction SilentlyContinue){
            # test-path has a registry differentiating issue, safer to use gi!
            if( (get-item -path $Destination -ea 0).PSIsContainer){
                $smsg = "-Destination specified - $($Destination) - is a container" ; 
                $smsg += "`nconstructing output file as 'Name' $($leafFilename )_HELP.html..." ; 
                write-host -ForegroundColor Yellow $smsg ; 
                [System.IO.DirectoryInfo[]]$Destination = $Destination ; 
                [system.io.fileinfo]$ofile = join-path -path $Destination.fullname -ChildPath "$($leafFilename)_HELP.html" ; 
                $outMD = split-path $ofile ; 
            }elseif( -not (get-item -path $Destination -ea 0).PSIsContainer){
                [system.io.fileinfo]$Destination = $Destination ; 
                if($Destination.extension -eq '.html'){
                    [system.io.fileinfo]$ofile = $Destination ; 
                    $outMD = split-path $ofile ; 
                } else { 
                    throw "$($Destination) does *not* appear to have a suitable extension (.html):$($Destination.extension)" ; 
                } ; 
            } else{
                # not an existing dir (target) & not an existing file, so treat it as a full path
                if($Destination.extension -eq 'html'){
                    [system.io.fileinfo]$ofile = $Destination ; 
                    $outMD = split-path $ofile ; 
                } else { 
                    throw "$($Destination) does *not* appear to have a suitable extension (.html):$($Destination.extension)" ; 
                } ; 
            } ; 
            write-host -ForegroundColor Yellow "Out-File -FilePath $($Ofile) -Encoding 'UTF8'" ; 

            if($Script){
                TRY{
                    $gcmInfo = get-command -Name $ModName -ea STOP ;
                    # post convert after finished adding keys
                    #$moduleData = [ordered]@{
                    $moduleData = [pscustomobject]@{
                        #Name = $gcminfo.name ; 
                        Name = $gcminfo.Source ; 
                        description = $null ;  
                        ModuleBase = $null ; 
                        # $moduleData.Version is semversion, not something I generally keep updated in CBH
                        Version = $null ; 
                        Author = $null ; 
                        CompanyName = $null ; 
                        Copyright = $null ; 
                    } ; 
                        
                } CATCH {
                    Write-Warning $_.Exception.Message ;
                    Continue ; 
                } ;  

                if(-not (get-command get-HelpParsed -ea STOP)){
                    $smsg = "-Script specified & unable to GCM get-HelpParsed!" ; 
                    $smsg += "`noutput html will lack details that are normally parsed from metadata I store in the CBH NOTES in the target script" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                } else {
                    $CBHParsedHelp = get-HelpParsed -Path $gcminfo.source -verbose:$VerbosePreference ; 
                } ; 
            } else { 
                # 9:51 AM 9/29/2023 silly, try to find & forceload the mod:
                 # try to get module info from imported modules first
                 <# there's a risk of ipmo/import-module'ing scripts, as they execute when run through it. 
                    but gmo checks for a path on the -Name spec and throws:
                    Get-Module : Running the Get-Module cmdlet without ListAvailable parameter is not supported for module names that include a path. Name parameter has this 
                    which prevents running scripts - if most scripts would include a path to their target. 
                    if loading a scripot in the path, how do we detect it's not a functional module?
                    can detect path by running split-path
                #>
                if( (split-path $modName -ea 0) -OR ([uri]$modName).isfile){
                    # pathed module, this will throw an error in gmo and exit
                    # or string that evalutes as a uri IsFile
                    $smsg = "specified -CodeObject $($modname) is a pathed specification,"
                    $smsg += "`nand -Script parameter *has not been specified*!" ;
                    $smsg += "`nget-module will *refuse* to execute against a pathed Module -Name specification, and will abort this script!"
                    $smsg += "`nif the intent is to process a _script_, rather than a module, please include the -script parameter!" ; 
                    write-warning $smsg ; 
                    throw $smsg ; 
                    Continue ; 
                } else {
                    # unpathed spec, doesn't eval as [uri].isfile
                    # check for function def's in the target file?                     
                    <#$rgxFuncDef = 'function\s+\w+\s+\{'
                    if(get-childitem $modName -ea 0 | select-string | -pattern $rgxFuncDef){
                    
                    } ; 
                    #>
                    # of course a lot of scripts have internal functions, and still execute on iflv...
                    # *better! does it have an extension!
                    # insufficient, periods are permitted in module names (MS powershell modules frequently are dot-delimtied fq names).
                    # just in case do a gcm and check for result.source value
                    # test the .psd1, if it's derivable from the gmo, this is a module, not a script
                    
                    if(($xgcm = get-command -Name $modName -ea 0).source){
                        # it's possible to have scripts with same name as modules
                        # and in most cases modules should have .psm1 extension
                        # tho my old back-load module copies were named .ps1
                        # check for path-hosted file with gcm on the name
                        # below false-positives against the uwes back-load module fallbacks. (which are named verb-xxx.ps1). 
                        # then check if the file's extension is .ps1, and hard block any work with it

                        if($LModData = get-Module -Name $ModName -ListAvailable -ErrorAction Stop){
                            if($LModData.path.replace('.psm1','.psd1') | Test-ModuleManifest -ErrorAction STOP ){
                                $smsg = "specified module has a like-named script in the path" ; 
                                $smsg += "`n$($xgcm.source)" ; 
                                $smsg += "`nbut successfully gmo resolves to, and passes, a manifest using Test-ModuleManifest" ; 
                                $smsg += "`nmoving on with conversion..." ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                            }elseif((get-childitem -path $xgcm.source).extension -eq '.ps1'){
                                $smsg = "specified -CodeObject $($modname) resolves to a pathed .ps1 file, and -Script parameter *has not been specified*!" ;
                                $smsg += "`nto avoid risk of ipmo'ing scripts (which will execute them, rather than load a target module), this item is being skipped" ; 
                                $smsg += "`nif the intent is to process a _script_, rather than a module, please include the -script parameter when using this specification!" ; 
                                write-warning $smsg ; 
                                throw $smsg ; 
                                Continue ; 
                            } ;
                        } ; 

                    } ; 
                }
                if($moduleData = Get-Module -Name $ModName -ErrorAction Stop){} else { 
                    write-verbose "unable to gmo $ModName : Attempting ipmo..." ; 
                    if($tmod = Get-Module $modname -ListAvailable){
                        TRY{import-module -force -Name $ModName -ErrorAction Stop
                        } CATCH {
                            Write-Warning $_.Exception.Message ;
                            Continue ; 
                        } ; 
                        if($moduleData = Get-Module -Name $ModName -ErrorAction Stop){} else { 
                            throw "Unable to gmo or ipmo $ModName!" ; 
                        } ; 
                    } else { 
                        throw "Unable to gmo -list $ModName!" ; 
                    } ; 
                } ; 
            }
            TRY{
                # abort if no module data returned
                if(-not ($moduleData)) {
                    Write-Warning "The module '$($ModName)' was not found. Make sure that the module is imported before running this function." ; 
                    break ; 
                } ; 

                # abort if return type is wrong
                #if(($moduleData.GetType()).Name -ne 'PSModuleInfo') {
                if($Script){
                    <# data that is pop'd for a module
                        $([System.Web.HttpUtility]::HtmlEncode($moduleData.Description))<br>
                        $([System.Web.HttpUtility]::HtmlEncode($moduleData.ModuleBase))<br>
                        $([System.Web.HttpUtility]::HtmlEncode($moduleData.Version))<br>
                        $([System.Web.HttpUtility]::HtmlEncode($moduleData.Author))<br>
                        $([System.Web.HttpUtility]::HtmlEncode($moduleData.CompanyName))<br>
                        $([System.Web.HttpUtility]::HtmlEncode($moduleData.Copyright))

                        $MODDATA | FL 'Description','ModuleBase','Version','Author','CompanyName','Copyright'
                        Description : Powershell Input/Output generic functions module
                        ModuleBase  : C:\Users\kadrits\OneDrive - The Toro Company\Documents\WindowsPowerShell\Modules\verb-IO\11.0.1
                        Version     : 11.0.1
                        Author      : Todd Kadrie
                        CompanyName : toddomation.com
                        Copyright   : (c) 2020 Todd Kadrie. All rights reserved.
                        
                        We can harvest a lot out of CBH
                        $ret = get-commentblocks -Path C:\usr\work\ps\scripts\move-ConvertedVidFiles.ps1
                        $ret.cbhblock ; 
                        Need to parse the .[keyword]`ninfor combos 
                    #>
                    if($CBHParsedHelp){
                        if($CBHParsedHelp.HelpParsed.description){$ModuleData.description = $CBHParsedHelp.HelpParsed.description  | out-string } ; 
                        if($gcminfo.Source){$ModuleData.ModuleBase = $gcminfo.Source  | out-string }
                        # $moduleData.Version is semversion, not something I generally keep updated in CBH
                        #Author
                        if($CBHParsedHelp.NotesHash.author){$ModuleData.Author = $CBHParsedHelp.NotesHash.author  | out-string } ; 
                        #CompanyName
                        if($CBHParsedHelp.NotesHash.CompanyName){$ModuleData.CompanyName = $CBHParsedHelp.NotesHash.CompanyName  | out-string } ; 
                        #Copyright
                        if($CBHParsedHelp.NotesHash.Copyright){$ModuleData.Copyright = $CBHParsedHelp.NotesHash.Copyright  | out-string } ; 
                    } ; 
                    if($gcminfo.CommandType -eq 'ExternalScript'){
                        $moduleCommands = $gcminfo.source ; 
                    }else {
                        Write-Warning "The 'Script' specified - '$($ModName)' - did not return an gcm CommandType of 'ExternalScript'." ; 
                        continue ; 
                    } ; 
                } else { 
                    if(($moduleData.GetType()).Name -ne 'PSModuleInfo') {
                        Write-Warning "The module '$($ModName)' did not return an object of type PSModuleInfo." ; 
                        continue ; 
                    } ; 
                    # get module commands
                    $moduleCommands = $moduleData.ExportedCommands | Select-Object -ExpandProperty 'Keys'
                    Write-Verbose 'Got Module Commands OK' ; 
                } ; 

                # start building html
                $html = @"
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="">
    <title>$($ModName)</title>
    <link href="bootstrap.min.css" rel="stylesheet">
    <link href="jasny-bootstrap.min.css" rel="stylesheet">
    <link href="navmenu.css" rel="stylesheet">
    <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
      <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
  </head>
  <body>
    <div class="navmenu navmenu-default navmenu-fixed-left offcanvas-sm hidden-print">
      <nav class="sidebar-nav" role="complementary">
      <a class="navmenu-brand visible-md visible-lg" href="#" data-toggle="tooltip" title="$($ModName)">$($ModName)</a>
      <ul class="nav navmenu-nav">
        <li><a href="#About">About</a></li>

"@ ; 

                # loop through the commands to build the menu structure
                $count = 0 ; 
                foreach($command in $moduleCommands) {
                    $count++ ; 
                    Write-Progress -Activity "Creating HTML for $($command)" -PercentComplete ($count/$moduleCommands.count*100) ; 
                    $html += @"
          <!-- $($command) Menu -->
          <li class="dropdown">
          <a href="#" class="dropdown-toggle" data-toggle="dropdown">$($command) <b class="caret"></b></a>
          <ul class="dropdown-menu navmenu-nav">
            <li><a href="#$($command)-Synopsis">Synopsis</a></li>
            <li><a href="#$($command)-Syntax">Syntax</a></li>
            <li><a href="#$($command)-Description">Description</a></li>
            <li><a href="#$($command)-Parameters">Parameters</a></li>
            <li><a href="#$($command)-Inputs">Inputs</a></li>
            <li><a href="#$($command)-Outputs">Outputs</a></li>
            <li><a href="#$($command)-Examples">Examples</a></li>
            <li><a href="#$($command)-RelatedLinks">RelatedLinks</a></li>
            <li><a href="#$($command)-Notes">Notes</a></li>
          </ul>
        </li>
        <!-- End $($command) Menu -->

"@ ; 
                } ; 

                # finishing up the menu and starting on the main content

                # orig, had no table, the metadata didn't line up with the fields
                # subbed the above into a table that puts them in key:value
                $html += @"
        <li><a class="back-to-top" href="#top"><small>Back to top</small></a></li>
      </ul>
    </nav>
    </div>
    <div class="navbar navbar-default navbar-fixed-top hidden-md hidden-lg hidden-print">
      <button type="button" class="navbar-toggle" data-toggle="offcanvas" data-target=".navmenu">
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </button>
      <a class="navbar-brand" href="#">$($ModName)</a>
    </div>
    <div class="container">
      <div class="page-content">
        <!-- About $($ModName) -->
        <h1 id="About" class="page-header">About $($ModName)</h1>
        <br>
        <table border="0" cellpadding="3" cellspacing="3">
        <tbody>
        <tr><td>Description</td><td>$([System.Web.HttpUtility]::HtmlEncode($moduleData.Description))</td></tr>
        <tr><td>ModuleBase</td><td>$([System.Web.HttpUtility]::HtmlEncode($moduleData.ModuleBase))</td></tr>
        <tr><td>Version</td><td>$([System.Web.HttpUtility]::HtmlEncode($moduleData.Version))</td></tr>
        <tr><td>Author</td><td>$([System.Web.HttpUtility]::HtmlEncode($moduleData.Author))</td></tr>
        <tr><td>CompanyName</td><td>$([System.Web.HttpUtility]::HtmlEncode($moduleData.CompanyName))</td></tr>
        <tr><td>Copyright</td><td>$([System.Web.HttpUtility]::HtmlEncode($moduleData.Copyright))</td></tr>
        </tbody>
        </table>

        <br>
        <!-- End About -->

"@ ; 

                # loop through the commands again to build the main content
                foreach($command in $moduleCommands) {
                    $commandHelp = Get-Help $command ; 

                    # platyps markdownhelp
                    if($MarkdownHelp){
                        $meta = @{
                            'layout' = 'pshelp';
                            #'author' = 'tto';
                            Author = $null # $moduleData.Author ; 
                            'title' = $null #$($commandHelp.Name);
                            #'category' = $($commandHelp.ModuleName.ToLower());
                            category = $null ; 
                            'excerpt' = $null # "`"$($commandHelp.Synopsis)`"";
                            'date' = $(Get-Date -Format yyyy-MM-dd);
                            'redirect_from' = $null #"[`"/PowerShell/$($commandHelp.ModuleName)/$($commandHelp.Name)/`", `"/PowerShell/$($commandHelp.ModuleName)/$($commandHelp.Name.ToLower())/`", `"/PowerShell/$($commandHelp.Name.ToLower())/`"]" ; 
                        } ; 
                        if($moduleData.Author){$meta.Author = $moduleData.Author} ; 
                        if($commandHelp.Name){$meta.title = $commandHelp.Name} ; 
                        if($commandHelp.ModuleName){
                            $meta.category = $($commandHelp.ModuleName.ToLower()) ; 
                            $meta.'redirect_from' = "[`"/PowerShell/$($commandHelp.ModuleName)/$($commandHelp.Name)/`", `"/PowerShell/$($commandHelp.ModuleName)/$($commandHelp.Name.ToLower())/`", `"/PowerShell/$($commandHelp.Name.ToLower())/`"]" ; 
                        } ; 
                        if($commandHelp.Synopsis){$meta.excerpt = "`"$($commandHelp.Synopsis)`""} ; 
                        if($moduleData.Author){$meta.Author = $moduleData.Author} ; 


                        if($commandHelp.Synopsis -notmatch "\[|\]") {
                            #New-MarkdownHelp -Command $command -OutputFolder (join-path -path $Destination -childpath '\_OnlineHelp\a') -Metadata $meta -Force ; 
                            New-MarkdownHelp -Command $command -OutputFolder $outmd -Metadata $meta -Force ; 
                        } ;     
                    } ;



                    $html += @"
        <!-- $($command) -->
        <div class="panel panel-default">
          <div class="panel-heading">
            <h2 id="$($command)-Header">$($command)</h1>
          </div>
          <div class="panel-body">
            <h3 id="$($command)-Synopsis">Synopsis</h3>
            <p>$([System.Web.HttpUtility]::HtmlEncode($commandHelp.Synopsis))</p>
            <h3 id="$($command)-Syntax">Syntax</h3>

"@ ; 
                    # get and format the command syntax
                    $syntaxString = '' ; 
                    foreach($syntax in ($commandHelp.syntax.syntaxItem)) {
                        $syntaxString += "$($syntax.name)" ; 
                        foreach ($syntaxParameter in ($syntax.parameter)) {
                            $syntaxString += ' ' ; 
                            # parameter is required
                            if(($syntaxParameter.required) -eq 'true') {
                                $syntaxString += "-$($syntaxParameter.name)" ; 
                                if($syntaxParameter.parameterValue) { $syntaxString += " <$($syntaxParameter.parameterValue)>" } ; 
                            } else {
                                # parameter is not required
                                $syntaxString += "[-$($syntaxParameter.name)" ; 
                                if($syntaxParameter.parameterValue) { $syntaxString += " <$($syntaxParameter.parameterValue)>]" }
                                elseif($syntaxParameter.parameterValueGroup) { $syntaxString += " {$($syntaxParameter.parameterValueGroup.parameterValue -join ' | ')}]" } 
                                else { $syntaxString += ']' } ; 
                            } ; 
                        } ; 
                        $html += @"
            <pre>$([System.Web.HttpUtility]::HtmlEncode($syntaxString))</pre>

"@ ; 
                        Remove-Variable -Name 'syntaxString' ; 
                    } ; 

                    $html += @"
            <h3 id="$($command)-Description">Description</h3>
            <p>$([System.Web.HttpUtility]::HtmlEncode($commandHelp.Description.Text -join [System.Environment]::NewLine) -replace([System.Environment]::NewLine, '<br>'))</p>
            <h3 id="$($command)-Parameters">Parameters</h3>
            <dl class="dl-horizontal">

"@ ; 
                    # get all parameter data
                    foreach($parameter in ($commandHelp.parameters.parameter)) {
                        $parameterValueText = "<$($parameter.parameterValue)>" ; 
                        $html += @" 
              <dt data-toggle="tooltip" title="$($parameter.name)">-$($parameter.name)</dt>
              <dd>$([System.Web.HttpUtility]::HtmlEncode($parameterValueText))<br>
                $($parameter.description.Text)<br><br>
                <div class="row">
                  <div class="col-md-4 col-xs-4">
                    Required?<br>
                    Position?<br>
                    Default value<br>
                    Accept pipeline input?<br>
                    Accept wildchard characters?
                  </div>
                  <div class="col-md-6 col-xs-6">
                    $([System.Web.HttpUtility]::HtmlEncode($parameter.required))<br>
                    $([System.Web.HttpUtility]::HtmlEncode($parameter.position))<br>
                    $([System.Web.HttpUtility]::HtmlEncode($parameter.defaultValue))<br>
                    $([System.Web.HttpUtility]::HtmlEncode($parameter.pipelineInput))<br>
                    $([System.Web.HttpUtility]::HtmlEncode($parameter.globbing))
                  </div>
                </div>
                <br>
              </dd>

"@ ; 
                    } ; 

                    $html += @"
            </dl>
            <h3 id="$($command)-Inputs">Inputs</h3>
            <p>$([System.Web.HttpUtility]::HtmlEncode($commandHelp.inputTypes.inputType.type.name))</p>
            <h3 id="$($command)-Outputs">Outputs</h3>
            <p>$([System.Web.HttpUtility]::HtmlEncode($commandHelp.returnTypes.returnType.type.name))</p>
            <h3 id="$($command)-Examples">Examples</h3>

"@ ; 
                    # get all examples
                    $exampleCount = 0 ; 
                    foreach($commandExample in ($commandHelp.examples.example)) {
                        $exampleCount++ ; 
                        $html += @"
            <b>Example $($exampleCount.ToString())</b>
            <pre>$([System.Web.HttpUtility]::HtmlEncode($commandExample.code))</pre>
            <p>$([System.Web.HttpUtility]::HtmlEncode($commandExample.remarks.text -join [System.Environment]::NewLine) -replace([System.Environment]::NewLine, '<br>'))</p>
            <br>

"@ ; 
                    } ; 

                    # orig, notes were unwrapped
                    # notes/.alertSet.alert.text was one big unwrapped block the line wrap above wasn't  working; revised to target 3 variants of crlfs
                    $html += @"
            <h3 id="$($command)-RelatedLinks">RelatedLinks</h3>
            <p><a href="$([System.Web.HttpUtility]::HtmlEncode($commandHelp.relatedLinks.navigationLink.uri -join ''))">$([System.Web.HttpUtility]::HtmlEncode($commandHelp.relatedLinks.navigationLink.uri -join ''))</a></p>
            <h3 id="$($command)-Notes">Notes</h3>
            <p>$([System.Web.HttpUtility]::HtmlEncode($commandHelp.alertSet.alert.text -join [System.Environment]::NewLine) -replace([system.environment]::newLine, '<br>') -replace("`r`n",'<br>') -replace("`r",'<br>') -replace("`n",'<br>')))</p>
            <br>
          </div>
        </div>
        <!-- End ConvertFrom-HexIP -->

"@ ; 
                } ; 

                # finishing up the html
                $html += @"
        </div>
    </div><!-- /.container -->
    <script src="$($jqueryFileName)"></script>
"@ ; 
            $html += @'
    <script src="bootstrap.min.js"></script>
    <script src="jasny-bootstrap.min.js"></script>
    <script>$('body').scrollspy({ target: '.sidebar-nav' })</script>
    <script>
      $('[data-spy="scroll"]').on("load", function () {
        var $spy = $(this).scrollspy('refresh')
    })
    </script>
  </body>
</html>
'@ ; 

                Write-Verbose 'Generated HTML OK' ; 

                # write html file
                $html | Out-File -FilePath $ofile.fullname -Force -Encoding 'UTF8' ; 
                Write-Verbose "$($ofile.fullname) written OK" ; 
                write-verbose "returning output path to pipeline" ; 
                $ofile.fullname | write-output ;
                if(-not $NoPreview){
                    write-host "Previewing $($ofile.fullname) in default browser..." ; 
                    Invoke-Item -Path $ofile.fullname ; 
                } ; 
            } CATCH {
                Write-Warning $_.Exception.Message ; 
            } ; 

            $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
        } ;  # loop-E
    } ;  # PROC-E
}

#*------^ Convert-HelpToHtmlFile.ps1 ^------


#*------v convert-ISEOpenSession.ps1 v------
Function convert-ISEOpenSession {

  <#
    .SYNOPSIS
    convert-ISEOpenSession - Converts remote devbox ISE debugging session (CU\documents\windowspowershell\scripts\ISESavedSession.psXML), and associated Breakpoint files (-ps1-BP.xml) to local use, converting stored paths.
    .NOTES
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2022-07-26
    FileName    : convert-ISEOpenSession.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Tags        : Powershell,FileSystem,Network
    REVISIONS   :
    * 5:02 PM 9/7/2022 fully debugged both push & pull, looks done ; debugged push fully; updated push/pull logic on rfile & lfiles; fixed bug in destfile gen code for push; added END block (largely for tailing bp target);  debugged Pull fully; added exemption for CU/AU/System installed modules/scripts, to avoid improper copy back (should be manually pulled over at the include file level). Need to debug Push.
    * 4:43 PM 8/30/2022 debugged(?)
    * 2:02 PM 8/25/2022 init
    .DESCRIPTION
    convert-ISEOpenSession - Converts remote devbox ISE debugging session (CU\documents\windowspowershell\scripts\ISESavedSession.psXML), and associated Breakpoint files (-ps1-BP.xml) to local use, converting stored paths.
    .PARAMETER FileName
    Filename for ISESadSession.psxml file to be processed (SID CU\docs\winPS\Scripts assumed))[-FileName ISESavedSession.psXML
    .PARAMETER devbox
    Remote dev box computername [-devbox c:\pathto\file]
    .PARAMETER Rfolder
    Remote dev box stock script storage path [-Rfolder c:\pathto\]
    .PARAMETER Lfolder
    Local stock script storage path [-Lfolder c:\pathto\]
    .PARAMETER SID
    Account from Remote devbox, to be copied from[-SID logonid
    .PARAMETER Push
    Switch to Pull content FROM -DevBox[-Push]
    .PARAMETER Pull
    Switch to Push content TO -Devbbox[-Pull]
    .PARAMETER Whatif
    Switch to suppress explicit resolution of share (e.g. wrote conversion wo validation converted share exists on host)[-NoValidate]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    System.String
    .EXAMPLE
    PS>  convert-ISEOpenSession -pull -verbose ;
    Demo -pull: remote $devbox C:\Users\ACCT\Documents\WindowsPowerShell\Scripts\ISESavedSession.psXML, of files, copy to local machine, along with any matching -ps1-BP.xml files, then post-conversion of the .psxmls and BP.xml files to translating remote $rpath paths to local $lpath paths, with verbose output
    .EXAMPLE
    PS>  convert-ISEOpenSession -push -verbose ;
    Demo -push: from local workstation to remote $devbox, C:\Users\ACCT\Documents\WindowsPowerShell\Scripts\ISESavedSession.psXML of files, copy to $devbox, along with any matching -ps1-BP.xml files, then post-conversion of the .psxmls and BP.xml files to translating local $lpath paths to remote $rpath paths, with verbose output
    .LINK
    https://github.com/tostka/verb-IO\
    #>
    [CmdletBinding()]
    [OutputType([string])]
    #[Alias('')]
    Param(
        [Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage = 'Filename for ISESadSession.psxml file to be processed (SID CU\docs\winPS\Scripts assumed))[-FileName ISESavedSession.psXML')]
        [ValidateNotNullOrEmpty()]
        [String]$FileName = 'ISESavedSession.psXML',
        [Parameter(Mandatory=$false,HelpMessage = 'Remote dev box computername [-devbox c:\pathto\file]')]
        [ValidateNotNullOrEmpty()]
        [String]$devbox = $AdminJumpBox,
        [Parameter(Mandatory=$false,HelpMessage = 'Remote dev box stock script storage path [-Rfolder c:\pathto\]')]
        [string]$Rfolder = 'd:\scripts\',
        [Parameter(Mandatory=$false,HelpMessage = 'Local stock script storage path [-Lfolder c:\pathto\]')]
        [string]$Lfolder = 'C:\usr\work\o365\scripts\',
        [Parameter(Mandatory=$false,HelpMessage = 'Account from Remote devbox, to be copied from[-SID logonid')]
        [ValidateNotNullOrEmpty()]
        $SID = $TorMeta.logon_SID.split('\')[1],
        [Parameter(HelpMessage = 'Switch to Pull content FROM -DevBox[-Push]')]
        [switch]$Push,
        [Parameter(HelpMessage = 'Switch to Push content TO -Devbbox[-Pull]')]
        [switch]$Pull,
        [Parameter(HelpMessage = 'Whatif switch[-whatif]')]
        [switch]$whatif
    )
    BEGIN {
        $verbose = ($VerbosePreference -eq "Continue") ; 
        
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ; 
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ; 
            write-verbose "(non-pipeline - param - input)" ; 
        } ; 

    } ;  # BEGIN-E
    PROCESS {
        foreach($item in $FileName) {
            
            write-host "Processing:$($item)" ; 
            TRY{
                if($Pull){
                    $srcOpenFile = (gci -path "\\$devbox\c$\users\$($SID)\documents\windowspowershell\scripts\$($item)" -ErrorAction 'STOP').fullname ; 
                    # \\DEVBOX\c$\users\LOGON\documents\windowspowershell\scripts\ISESavedSession.psXML
                    # local equiv, same acct
                    $destOpenFile = (($srcOpenFile.split('\') | select -skip 3) -join '\').replace('$',':') ; 
                } elseif($Push){
                    $srcOpenFile = (gci -path "c:\users\$($SID)\documents\windowspowershell\scripts\$($item)" -ErrorAction 'STOP').fullname ; 
                    $destOpenFile = "\\$($devbox)\$("C:\users\$($SID)\documents\windowspowershell\scripts\ISESavedSession.psXML".replace(':','$'))"; 
                } else { 
                    throw "Neither -Push or -Pull specified!: Please use one or the other!" ; 
                } ; 
                $smsg = "(`$srcOpenFile:$($srcOpenFile)" 
                if(test-path -path $srcOpenFile){$smsg += ":(exists)"}
                else{$smsg += ":(missing)"}; 
                $smsg += "`n`$destOpenFile:$($destOpenFile))" ; 
                if(test-path -path $destOpenFile){$smsg += ":(exists))"} 
                else{$smsg += ":(missing)"}; 
                write-verbose $smsg ; 
                if($srcOpenFile){
                    write-verbose "(confirmed:`$srcOpenFile:$($srcOpenFile))" ; 
                } else { 
                    $smsg = "UNABLE TO LOCATE `$srcOpenFile:$($srcOpenFile)!" ; 
                    write-warning $smsg ; 
                    throw $smsg ; 
                    Break ; 
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #-=-record a STATUSWARN=-=-=-=-=-=-=
                $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
                #-=-=-=-=-=-=-=-=
                $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ; 


            <#
            $pltCI=[ordered]@{ 
                path = (gci $srcOpenFile -ea 'STOP').fullname ;
                destination = $lfolder ;
                erroraction = 'STOP' ;
            } ;         
            write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):copy-item w`n$(($pltCI|out-string).trim())" ;
            copy-item @pltCI -whatif:$($whatif); 
            #>
            # why copy locally, if we can output direct to a variant filename, sourced from remote
            

            if($push){
                $smsg = "Create remote variant:$($destOpenFile)" ;
            }elseif($pull){
                $smsg = "Create local variant:$($destOpenFile)" ;
            } ; 
            write-host $smsg ; 
            write-host "(localize paths)" ; 
            TRY{
                if($Pull){
                    (get-content $srcOpenFile) | Foreach-Object {
                        $_ -replace [Regex]::Escape($rfolder), $lfolder 
                    } | set-content -Encoding UTF8 -path $destOpenFile -whatif:$($whatif); 
                } elseif($Push){
                    (get-content $srcOpenFile) | Foreach-Object {
                        $_ -replace [Regex]::Escape($lfolder), $rfolder
                    } | set-content -Encoding UTF8 -path $destOpenFile -whatif:$($whatif); 
                    
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #-=-record a STATUSWARN=-=-=-=-=-=-=
                $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
                #-=-=-=-=-=-=-=-=
                $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ; 

            write-verbose "Localized `$destOpenFile`n$((gc $destOpenFile|out-string).trim())" ; 
            
            if($pull){
                write-verbose "(processing remote OpenFile)" ; 
                $lfiles = ixml $destOpenFile; 
                $rfiles = ixml $srcOpenFile ; 
                $tOpenfile = $rfiles ; 
            }elseif($push){
                write-verbose "(processing local OpenFile)" ; 
                $lfiles = ixml $srcOpenFile; 
                $rfiles = ixml $destOpenFile ; 
                $tOpenfile = $lfiles ; 
            } ; 

            foreach($xfile in $tOpenfile){
                write-host "==$($xfile):" ; 

                # exempt installed module files & scripts (don't want to copy those back, they should be manually copied over and spliced into source module code)
                if($xfile -match $rgxPSAllUsersScope){
                    write-host "exempting AllUsersScope-installed file!:`n$($xfile)" ; 
                    break ; 
                }elseif($xfile -match $rgxModsSystemScope){
                    write-host "exempting SystemScope-installed file!:`n$($xfile)" ; 
                    break ; 
                }elseif($xfile -match $rgxPSCurrUserScope){
                    write-host "exempting CurrentUserScope-installed file!:`n$($xfile)" ; 
                    break ; 
                } else {
                    write-verbose "(file confirmed non-installed content)" ; 
                } ; 
                $pltCI=[ordered]@{ 
                    path = $null 
                    destination = $null ;
                    erroraction = 'STOP' ;
                    whatif = $($whatif) ;
                } ;     
                
                TRY{
                    
                    if($Pull){
                        $pltCI.path = (gci "\\$($devbox)\$($xfile.replace(':','$'))" -ErrorAction 'STOP').fullname ; 
                        #$pltCI.destination = $lfolder ; 
                        # use full path dest, provides something to copy for follow on commands
                        $pltCI.destination = (join-path -path $lfolder -childpath (split-path $xfile -leaf) ) ; 
                    } elseif($Push){
                        $pltCI.path = (gci -path $xfile -ErrorAction 'STOP').fullname
                        # full path dest:
                        $pltCI.destination = join-path -path "\\$($devbox)\$($rfolder.replace(':','$'))" -childpath (split-path $xfile -leaf) ; 
                    } else { 
                        throw "Neither -Push or -Pull specified!: Please use one or the other!" ; 
                    } ; 
                    if($pltCI.path){
                        write-verbose "(confirmed:`$pltCI.path:$($pltCI.path))" ; 
                        
                    } else { 
                        $smsg = "UNABLE TO LOCATE `$pltCI.path:$($pltCI.path)!" ; 
                        write-warning $smsg ; 
                        throw $smsg ; 
                        Break ; 
                    } ; 

                    if($pltCI.path -AND $pltCI.destination){
                         
                        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):copy-item w`n$(($pltCI|out-string).trim())" ; 
                        copy-item @pltCI ; 

                        write-host "(checking for matching -ps1-BP.xml file...)" ;         
                        
                        if($Pull){
                            $srcBPFile  = (gci "\\$($devbox)\$($xfile.replace(':','$').replace('.ps1','-ps1-BP.xml'))").fullname ; 
                            # local equiv, same acct
                            if($srcBPFile) {
                                
                                $destBPFile = (join-path -path $lfolder -child (split-path $srcBPFile -leaf) ) 
                                write-host "(localize BP file paths)" ; 
                                (get-content -path $srcBPFile) | Foreach-Object {
                                    $_ -replace [Regex]::Escape($rfolder), $lfolder 
                                } | set-content -Encoding UTF8 -path $destBPFile -whatif:$($whatif) ; 
                                
                            } ; 
                                
                        } elseif($Push){
                            $srcBPFile  = (gci $xfile.replace('.ps1','-ps1-BP.xml') ).fullname ; 
                            if($srcBPFile) {
                                
                                $destBPFile = join-path -path (join-path -path "\\$($devbox)\" -childpath $rfolder.replace(':','$')) -childpath (split-path $srcBPFile -leaf) ; 
                                write-host "(localize BP file paths)" ; 
                                (get-content -path $srcBPFile) | Foreach-Object {
                                    $_ -replace [Regex]::Escape($lfolder), $rfolder
                                } | set-content -Encoding UTF8 -path $destBPFile -whatif:$($whatif); 
                                
                            } ; 
                        }
                        
                        if($srcBPFile -AND -not($whatif)) {
                            write-verbose "Localized `$destBPFile`n$((gc $destBPFile|out-string).trim())" ; 
                        }elseif($whatif){
                            # drop through
                        }else {
                            write-host -ForegroundColor yellow "(Unable to locatea matching BP file:`n$("\\$($devbox)\$($xfile.replace(':','$').replace('.ps1','-ps1-BP.xml'))"))" ; 
                        } ; 
                    } else { 
                        write-warning "Unable to locate:$("\\$($devbox)\$($xfile.replace(':','$'))")!" ; 
                    } ; 
                } CATCH {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #-=-record a STATUSWARN=-=-=-=-=-=-=
                    $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                    if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                    if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
                    #-=-=-=-=-=-=-=-=
                    $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
                } ; 

            } ;  # loop-E


        } ;  # loop-E
    } ;  # PROC-E
    END{
        write-host "Pass completed" ; 
    } ; 
}

#*------^ convert-ISEOpenSession.ps1 ^------


#*------v converto-VSCConfig.ps1 v------
function converto-VSCConfig {
    <#
    .SYNOPSIS
    converto-VSCConfig - Process a sample ISE debugging command line, and convert it to a VSC launch.json 'configurations' entry
    .NOTES
    Version     : 1.1.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2:58 PM 12/15/2019
    FileName    :
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit :
    AddedWebsite:
    AddedTwitter:
    REVISIONS
    * 12:50 PM 6/17/2022 ren build-VSCConfig -> converto-VSCConfig, alias orig name
    * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:14 AM 12/30/2019 added CBH .INPUTS & .OUTPUTS, including specific material returned.
    * 5:51 PM 12/16/2019 added OneArgument param
    * 2:58 PM 12/15/2019 INIT
    .DESCRIPTION
    converto-VSCConfig - Process a sample ISE debugging command line, and convert it to a VSC launch.json 'configurations' entry
    .PARAMETER  CommandLine
    CommandLine to be converted into a launch.json configuration
    .PARAMETER OneArgument
    Flag to specify all arguments should be in a single unparsed entry[-OneArgument]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Console dump & copy to clipboard, of model launch.json conversion of ISE Breakpoints xml file.
    .EXAMPLE
    $bRet = converto-VSCConfig -CommandLine $updatedContent -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
    if (!$bRet) {Continue } ;
    .LINK
    #>
    [CmdletBinding()]
    [Alias('build-VSCConfig')]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "CommandLine to be written to specified file [-CommandLine script.ps1 arguments]")]
        [ValidateNotNullOrEmpty()]$CommandLine,
        [Parameter(HelpMessage = "Flag to specify all arguments should be in a single unparsed entry[-OneArgument]")]
        [switch] $OneArgument = $true,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    
    #$verbosePreference = "Continue" # opts: Stop(&Error)|Inquire(&Prompt)|Continue(Display)|SilentlyContinue(Suppress);
    $Verbose = ($VerbosePreference -eq "Continue") ; 
    #$CommandLine = Read-Host "Enter Command to be Parsed" ;
    $parsedCmdLine = Split-CommandLine -CommandLine $CommandLine | Where-Object { $_.length -gt 1 }  ;
    $ttl = ($parsedCmdLine | Measure-Object).count ;

    $error.clear() ;
    TRY {
        # 1st elem is the script/exec name
        $jsonRequest = [ordered]@{
            type    = "PowerShell";
            request = "launch";
            name    = "PS $(split-path $parsedCmdLine[0] -Leaf)" ;
            script  = (resolve-path -path $parsedCmdLine[0]).path;
            args    = $() ;
            cwd     = "`${workspaceRoot}";
        } ;

        if ($ttl -gt 1) {
            if ($OneArgument) {
                $jsonRequest.args = $parsedCmdLine[1..$($ttl)] -join " " ;
            }
            else {
                # args are 2nd through last elem
                $jsonRequest.args = $parsedCmdLine[1..$($ttl)]
            } ;
        } ;
        if ($showDebug) {
            Write-HostOverride -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):ConvertTo-Json w`n$(($jsonRequest|out-string).trim())`nargs:`n$(($jsonRequest.args|out-string).trim())" ;
        } ;
        $cfg = $jsonRequest | convertto-json ;
    }
    CATCH {
        Write-Error "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        $false | Write-Output ;
        CONTINUE #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
    } ;
    $cfgTempFile = [System.IO.Path]::GetTempFileName().replace('.tmp', '.json') ;
    Set-FileContent -Text $cfg -Path $cfgTempFile -showDebug:$($showDebug) -whatIf:$($whatIf);
    write-verbose -verbose:$true "Generated launch.json config entry for input:`n w`n$(($cfg|out-string).trim())" ;
    write-verbose -verbose:$true "Generated launch.json config entry for input:`n w`n$((get-command $cfgTempFile |out-string).trim())" ;
    write-verbose -verbose:$true "(copied to clipboard)" ;
    $cfg | C:\WINDOWS\System32\clip.exe ;
    $true | write-output ;

}

#*------^ converto-VSCConfig.ps1 ^------


#*------v ConvertTo-Breakpoint.ps1 v------
Function ConvertTo-Breakpoint {
    <#
    .SYNOPSIS
    ConvertTo-Breakpoint - Converts an errorrecord to a breakpoint
    .NOTES
    Version     : 2.1.0
    Author      : KevinMarquette
    Website     :	https://github.com/KevinMarquette
    Twitter     :	@KevinMarquette
    CreatedDate : 2022-12-15
    FileName    : ConvertTo-Breakpoint.ps1
    License     : https://github.com/KevinMarquette/ConvertTo-Breakpoint/blob/master/LICENSE
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,debugging
    AddedCredit : Todd Kadrie
    AddedWebsite:	http://www.toddomation.com
    AddedTwitter:	@tostka / http://twitter.com/tostka
    REVISIONS
    * 12:20 PM 12/22/2022 distilled into freestanding function .ps1: shifted priv func into internal, and added to verb-dev, OTB formatting. 
    * 4/18/18 KM's posted git version
    .DESCRIPTION
    ConvertTo-Breakpoint - Converts an errorrecord to a breakpoint 
    
    This works the best in the ISE
    VSCode requires the debugger to be running for Set-PSBreakpoint to work
    
    Comments from linked blog post:
    
    [Powershell: ConvertTo-Breakpoint - powershellexplained.com/](https://powershellexplained.com/2018-04-18-Powershell-ConvertTo-Breakpoint/)
   
    # The Idea

    I often check the `$error[0].ScriptStackTrace` for the source of an error and then go place a breakpoint where the error was raised. I realized that I could parse the `ScriptStackTrace` and call `Set-PSBreakPoint` directly. It is a fairly simple idea and it turned out to be just as easy to write.

    # Putting it all together

    If you ever looked at a `ScriptStackTrace` on an error, you would see something like this:

    ```powershell
    PS> $error[0].ScriptStackTrace
        at New-Error, C:\workspace\ConvertTo-Breakpoint\testing.ps1: line 2
        at Get-Error, C:\workspace\ConvertTo-Breakpoint\testing.ps1: line 6
        at <ScriptBlock>, C:\workspace\ConvertTo-Breakpoint\testing.ps1: line 9
    ```

    While the data is just a string, it is very consistent and easy to parse with regex. Here is the regex pattern that I used to match each line: `at .+, (?<Script>.+): line (?<Line>\d+)`

    I was a little fancy and used [named sub-expression matches](https://powershellexplained.com/2016-11-06-powershell-hashtable-everything-you-wanted-to-know-about/?utm_source=blog&utm_medium=blog#regex-matches). I do this so I can access them by name with `$matches.Script` and `$matches.Line`.

    Once I had the data that I needed, it was a quick call to `Set-PSBreakPoint` to set the breakpoint.

    ```powershell
    Set-PSBreakPoint -Script $matches.Script -Line $matches.Line
    ```

    I put a bit more polish on it and called it `ConvertTo-Breakpoint`.

    I do a full step by step walk of the entire function in this video: [ConvertTo-Breakpoint: Writing the cmdlet](https://youtu.be/2tsA1zsIwGE?t=27m26s).

    # How to use

    This is the cool part. I can now take any `$error` and pipe it to `ConvertTo-Breakpoint`. Then a breakpoint will be created where the error was thrown.

    ```powershell
    $error[0] | ConvertTo-BreakPoint
    ```

    I added proper pipeline support so you can give it all your errors.

    ```powershell
    $error | ConvertTo-BreakPoint
    ```

    I even added `-All` as a switch to create a breakpoint at each point in the callstack instead of just the source of the error.

    ```powershell
    $error[0] | ConvertTo-BreakPoint -All
    ```

    ## VSCode debugger

    In my experimentation with VSCode and `Set-PSBreakpoint`; I discovered that you have to have the debugger running for `Set-PSBreakpoint` to set breakpoints. There is an issue on github about this already. This is why I did the demo video in the ISE.

    # Where do I find it?

    This is already published in the PSGallery. You can install it and start experimenting with it right away.

    ```powershell
    Install-Module -Name ConvertTo-Breakpoint -Scope CurrentUser
    ```

    If you would like to checkout the source, I published it on github with all my other tools:

    -   [https://github.com/KevinMarquette/ConvertTo-Breakpoint](https://github.com/KevinMarquette/ConvertTo-Breakpoint/blob/master/module/public/ConvertTo-Breakpoint.ps1)
    
    .EXAMPLE
    PS> $error[0] | ConvertTo-Breakpoint ;
    The various values returned will be Version 1, Version 2, or Off.
    .EXAMPLE
    PS> $error[0] | ConvertTo-Breakpoint -All
     
    .LINK
    https://github.com/tostka/verb-dev
    https://github.com/KevinMarquette/ConvertTo-Breakpoint
    https://powershellexplained.com/2018-04-18-Powershell-ConvertTo-Breakpoint/
    #>
    [CmdletBinding(SupportsShouldProcess)]
    PARAM(
        [parameter(Mandatory,Position = 0,ValueFromPipeline,HelpMessage='The Error Record[-ErrorRecord `$Error[0]]')]
        [Alias('InputObject')]
        $ErrorRecord,   
        [parameter(HelpMessage='Switch that sets breakpoints on the entire stack[-ALL]')] 
        [switch]$All
    )  ; 
    BEGIN{
        #*------v Function _extractBreakpoint v------
        function _extractBreakpoint {
            <#
            .DESCRIPTION
            Parses a script stack trace for breakpoints
            .EXAMPLE
            $error[0].ScriptStackTrace | _extractBreakpoint
            #>
            [OutputType('System.Collections.Hashtable')]
            [cmdletbinding()]
            PARAM(
                # The ScriptStackTrace
                [parameter(
                    ValueFromPipeline
                )]
                [AllowNull()]
                [AllowEmptyString()]
                [Alias('InputObject')]
                [string]
                $ScriptStackTrace
            )
            BEGIN{$breakpointPattern = 'at .+, (?<Script>.+): line (?<Line>\d+)'} ;
            PROCESS{
                if (-not [string]::IsNullOrEmpty($ScriptStackTrace)){
                    $lineList = $ScriptStackTrace -split [System.Environment]::NewLine
                    foreach($line in $lineList){
                        if ($line -match $breakpointPattern){
                            if ($matches.Script -ne '<No file>' -and (Test-Path $matches.Script)){  
                                @{
                                    Script = $matches.Script
                                    Line   = $matches.Line ; 
                                } ;                           
                            } ; 
                        } ; 
                    } ;  # loop-E
                } ; 
            } ;  # PROC-E
        } ;   
        #*------^ END Function _extractBreakpoint ^------      
    } ;
    PROCESS{
        foreach ($node in $ErrorRecord){
            $breakpointList = $node.ScriptStackTrace | _extractBreakpoint ; 
            foreach ($breakpoint in $breakpointList){
                $message = '{0}:{1}' -f $breakpoint.Script,$breakpoint.Line ; 
                if($PSCmdlet.ShouldProcess($message)){
                    Set-PSBreakpoint @breakpoint ; 
                    if (-Not $PSBoundParameters.All){
                        break ; 
                    } ; 
                } ; 
            } ; 
        } ; 
    }  ; # PROC-E
}

#*------^ ConvertTo-Breakpoint.ps1 ^------


#*------v convertTo-EscapedPSText.ps1 v------
Function convertTo-EscapedPSText {
    <#
    .SYNOPSIS
    convertTo-EscapedPSText - convert a scriptblock of Powershell code text, to an esaped equivelent - specifically backtick-escape all special characters [$*\~;(%?.:@/]. 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-11-08
    FileName    : convertTo-EscapedPSText.ps1
    License     : MIT License
    Copyright   : (c) 2021 Todd Kadrie
    Github      : https://github.com/tostka/verb-text
    Tags        : Powershell,Text
    AddedCredit : REFERENCE
    AddedWebsite:	URL
    AddedTwitter:	URL
    REVISIONS
    * 12:44 PM 6/17/2022 update CBH; move verb-text -> verb-dev
    * 2:10 PM 3/1/2022 updated the ScriptBlock param to string-array [string[]], preserves the multi-line nature of original text (otherwise, ps coerces arrays into single-element strings)
    * 11:09 AM 11/8/2021 init
    .DESCRIPTION
    convertTo-EscapedPSText - convert a scriptblock of Powershell code text, to an esaped equivelent - specifically backtick-escape all special characters [$*\~;(%?.:@/]. 
    Intent is to run this prior to running a -replace pass on a given piece of Powershell code, to ensure the special characters in the block are treated as literal text. Following search and replace, one would typically *un*-escape the special characters by running convertFrom-EscapedPSText() on the block. 
    .PARAMETER  ScriptBlock
    Semi-colon-delimited ScriptBlock of powershell to be wrapped at 
    .EXAMPLE
    PS>  # pre-escape PS special chars
    PS>  $ScriptBlock = get-content c:\path-to\script.ps1 ; 
    PS>  $ScriptBlock=convertTo-EscapedPSText -ScriptBlock $ScriptBlock ; 
    PS>  $splitAt = ";" ; 
    PS>  $replaceWith = ";$([Environment]::NewLine)" ; 
    PS>  # ";`r`n"  ; 
    PS>  $ScriptBlock = $ScriptBlock | Foreach-Object {$_ -replace $splitAt, $replaceWith } ; 
    PS>  $ScriptBlock=convertFrom-EscapedPSText -ScriptBlock $ScriptBlock ; 
    Load a script file into a $ScriptBlock vari, escape special characters in the $Scriptblock, run a wrap on the text at semicolons (replace ';' with ';`n), then unescape the specialcharacters in the scriptblock, back to original functional state. 
    .LINK
    https://github.com/tostka/verb-Text
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$false,HelpMessage="ScriptBlock
    Semi-colon-delimited ScriptBlock of powershell to be wrapped at [-ScriptBlock 'c:\path-to\script.ps1']")]
        [Alias('Code')]
        [string[]]$ScriptBlock
    )  ; 
    if(-not $ScriptBlock){
        $ScriptBlock= (get-clipboard) # .trim().replace("'",'').replace('"','') ;
        if($ScriptBlock){
            write-verbose "No -ScriptBlock specified, detected text on clipboard:`n$($ScriptBlock)" ;
        } else {
            write-warning "No -path specified, nothing suitable found on clipboard. EXITING!" ;
            Break ;
        } ;
    } else {
        write-verbose "ScriptBlock:$($ScriptBlock)" ;
    } ;
    # issue specific to PS, -replace isn't literal, see's $ as variable etc control char
    # to escape them, have to dbl: $password.Replace('$', $$')
    #$ScriptBlock = $ScriptBlock.Replace('$', '$$');
    # rgx replace all special chars, to make them literals, before doing the replace (graveaccent escape ea matched char in the [$*\~;(%?.:@/] range)
    $ScriptBlock = $scriptblock -replace '([$*\~;(%?.:@/]+)','`$1' ;
    $ScriptBlock | write-output ; 
}

#*------^ convertTo-EscapedPSText.ps1 ^------


#*------v ConvertTo-ModuleDynamicTDO.ps1 v------
function ConvertTo-ModuleDynamicTDO {
    <#
    .SYNOPSIS
    ConvertTo-ModuleDynamicTDO.ps1 - Revert a monolisthic module.psm1 module file, to dynamic include .psm1. Returns a hash with status:$true/$false, and PsmNameBU:The name of a backup of the original .psm1 file (for restoring on failures)
    .NOTES
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
    * 3:07 PM 5/13/2022ren unmerge-Module -> ConvertTo-ModuleDynamicTDO() (use std verb; adopt keyword to unique my work from 3rd-party funcs); added Unmerge-Module to Aliases; 
    * 4:06 PM 5/12/2022 merge over latest working updates to merge-module.ps1; *untested*
    * 8:08 AM 5/3/2022 WIP init convert of Merge-Module to unmerge-module
    .DESCRIPTION
    ConvertTo-ModuleDynamicTDO.ps1 - Revert a monolisthic module.psm1 module file, to dynamic include .psm1. Returns a hash with status:$true/$false, and PsmNameBU:The name of a backup of the original .psm1 file (for restoring on failures)
    .PARAMETER  ModuleName
    Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]
    .PARAMETER  ModuleSourcePath
    Directory containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]
    .PARAMETER ModuleDestinationPath
    Final monolithic module .psm1 file name to be populated [-ModuleDestinationPath c:\path-to\module\module.psm1]
    .PARAMETER NoAliasExport
    Flag that skips auto-inclusion of 'Export-ModuleMember -Alias * ' in merged file [-NoAliasExport]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Outputs a hashtable object containing: Status[$true/$false], PsmNameBU [the name of the backup of the original psm1 file]
    .EXAMPLE
    PS> .\ConvertTo-ModuleDynamicTDO.ps1 -ModuleName verb-AAD -ModuleSourcePath C:\sc\verb-AAD\Public -ModuleDestinationPath C:\sc\verb-AAD\verb-AAD -showdebug -whatif ;
    Command line process
    .EXAMPLE
    PS> $pltmergeModule=[ordered]@{
    PS>     ModuleName="verb-AAD" ;
    PS>     ModuleSourcePath="C:\sc\verb-AAD\Public","C:\sc\verb-AAD\Internal" ;
    PS>     ModuleDestinationPath="C:\sc\verb-AAD\verb-AAD" ;
    PS>     LogSpec = $logspec ;
    PS>     NoAliasExport=$($NoAliasExport) ;
    PS>     ErrorAction="Stop" ;
    PS>     showdebug=$($showdebug);
    PS>     whatif=$($whatif);
    PS> } ;
    PS> $smsg= "ConvertTo-ModuleDynamicTDO w`n$(($pltmergeModule|out-string).trim())" ;
    PS> if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
    PS> else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS> $ReportObj = ConvertTo-ModuleDynamicTDO @pltmergeModule ;
    Splatted example (from process-NewModule.ps1)
    .LINK
    https://www.toddomation.com
    #>
    [CmdletBinding()]
    [Alias('Unmerge-Module')]
    PARAM (
        [Parameter(Mandatory = $True, HelpMessage = "Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]")]
            [string] $ModuleName,
        [Parameter(Mandatory = $True, HelpMessage = "Array of directory paths containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]")]
            [array] $ModuleSourcePath,
        [Parameter(Mandatory = $True, HelpMessage = "Directory path in which the final .psm1 file should be constructed [-ModuleDestinationPath c:\path-to\module\module.psm1]")]
            [string] $ModuleDestinationPath,
        [Parameter(Mandatory = $False, HelpMessage = "Logging spec object (output from start-log())[-LogSpec `$LogSpec]")]
            $LogSpec,
        [Parameter(HelpMessage = "Flag that skips auto-inclusion of 'Export-ModuleMember -Alias * ' in merged file [-NoAliasExport]")]
            [switch] $NoAliasExport,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
            [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
            [switch] $whatIf
    ) ;
    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
    # Get parameters this function was invoked with
    $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
    write-verbose -verbose:$verbose "`$PSBoundParameters:`n$(($PSBoundParameters|out-string).trim())" ;
    $verbose = ($VerbosePreference -eq "Continue") ;

    $sBnr="#*======v $(${CmdletName}): v======" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

    # path to stock dynamic psm1, to be used to reconstruct the existing .psm1 to dynamic.
    $Psm1TemplatePath = "C:\sc\powershell\PlasterModuleTemplate-master\PPoShModuleTemplate\template.psm1" ;
    $rgxSigStart='#\sSIG\s#\sBegin\ssignature\sblock' ;
    $rgxSigEnd='#\sSIG\s#\sEnd\ssignature\sblock' ;

    $PassStatus = $null ;
    $PassStatus = @() ;

    $tModCmdlet = "Get-FileEncoding" ;
    if(!(test-path function:$tModCmdlet)){
         write-warning -verbose:$true  "UNABLE TO VALIDATE PRESENCE OF $tModCmdlet";
         $tModFile = "verb-IO.ps1" ; $sLoad = (join-path -path $LocalInclDir -childpath $tModFile) ; if (Test-Path $sLoad) {     Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ; . $sLoad ; if ($showdebug) { Write-Verbose -verbose "Post $sLoad" }; } else {     $sLoad = (join-path -path $backInclDir -childpath $tModFile) ; if (Test-Path $sLoad) {         Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ; . $sLoad ; if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };     }     else { Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ; exit; } ; } ;
    } ;

    if($logspec){
        $logging=$logspec.logging ;
        $logfile=$logspec.logfile ;
        $transcript=$logspec.transcript ;
    } ;

    <# doesn't do anything: resolve to gci, but assigned to strong-typed [string] vari -> just re-coerces back to [string} on fullname property
    if ($ModuleDestinationPath.GetType().FullName -ne 'System.IO.DirectoryInfo') {
        $ModuleDestinationPath = get-item -path $ModuleDestinationPath ;
        # doesn't do anything: resolve to gci, but on [string] vari, just re-coercess back to string on fullname
    } ;
    #>
    $ModuleRootPath = split-path $ModuleDestinationPath -Parent ;

    $ttl = ($ModuleSourcePath | Measure-Object).count ;
    $iProcd = 0 ;

    $ExportFunctions = @() ;
    $PrivateFunctions = @() ;

    $PsmName="$ModuleDestinationPath\$ModuleName.psm1" ;
    $PsdName="$ModuleDestinationPath\$ModuleName.psd1" ;
    $PsmNameTmp="$ModuleDestinationPath\$ModuleName.psm1_TMP" ;
    $PsdNameTmp="$ModuleDestinationPath\$ModuleName.psd1_TMP" ;


    # backup existing & purge the dyn-include block
    if(test-path -path $PsmName){
        $rawSourceLines = get-content -path $PsmName  ;
        $SrcLineTtl = ($rawSourceLines | Measure-Object).count ;
        $PsmNameBU = backup-FileTDO -path $PsmName -showdebug:$($showdebug) -whatif:$($whatif) ;
        if (!$PsmNameBU) {throw "FAILURE" } ;

        # also backup the $psdname
        if(test-path -path $PsmName){
            write-verbose "(backup-FileTDO -path $($psdname))" ;
            $PsdNameBU = backup-FileTDO -path $PsdName -showdebug:$($showdebug) -whatif:$($whatif) ;
            if (!$PsdNameBU) {throw "FAILURE" } ;
        } ; 

        # the above produces 'C:\sc\verb-Auth\verb-Auth\verb-auth.psm1_20210609-1544PM' files from the prior .psm1
        # make it purge all but the last 2 backups above, dated prior to today.
        #$PsmName = 'C:\sc\verb-Auth\verb-Auth\verb-Auth.psm1'
        $pltRGens =[ordered]@{
            Path = (split-path $PsmName) ;
            Include =(split-path $PsmName -leaf).replace('.psm1','.psm1_*') ;
            Pattern = '\.ps(m|d)1_\d{8}-\d{3,4}(A|P)M$' ;
            FilterOn = 'CreationTime' ;
            Keep = 2 ;
            KeepToday = $true ;
            verbose=$true ;
            whatif=$($whatif) ;
        } ;
        write-host -foregroundcolor green "DEADWOOD REMOVAL:remove-UnneededFileVariants w`n$(($pltRGens|out-string).trim())" ;
        remove-UnneededFileVariants @pltRGens ;

        # this script *appends* to the existing .psm1 file.
        # which by default includes a dynamic include block:
        # detect and drop out the above, for the monolithic version
        $rgxPurgeblockStart = '#Get\spublic\sand\sprivate\sfunction\sdefinition\sfiles\.' ;
        # stock dyanmic export of collected functions
        #$rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s;';
        # updated version of dyn end, that also explicitly exports -alias *
        $rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s-Alias\s\*\s;\s'
        $dynIncludeOpen = ($rawsourcelines | select-string -Pattern $rgxPurgeblockStart).linenumber ;
        $dynIncludeClose = ($rawsourcelines | select-string -Pattern $rgxPurgeBlockEnd).linenumber ;
        if(!$dynIncludeOpen){$dynIncludeClose = 0 } ;
        $updatedContent = @() ; $DropContent=@() ;

        if($dynIncludeOpen -AND $dynIncludeClose){
            # dyn psm1
            $smsg= "(existed dyn-include psm1 detected - no changes needed...)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

        } else {
            # monolithic psm1?
            $smsg= "(NON-dyn psm1 detected - purging existing non-CBH content...)" ;
            # monolithic psm1?
            $smsg= "(NON-dyn psm1 detected - purging existing non-CBH content...)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            # parse out the CBH and just start from that:
            $oBlkComments = Get-CommentBlocks -TextLines $rawSourceLines -showdebug:$($showdebug) -whatif:$($whatif) ;
            <# returned props
            * metaBlock : `<#PSScriptInfo..#`> published script metadata block (added via New|Update-ScriptFileInfo, at top of file)
            * metaOpen : Line# of start of metaBlock
            * metaClose : Line# of end of metaBlock
            * cbhBlock : Comment-Based-Help block
            * cbhOpen : Line# of start of CBH
            * cbhClose : Line# of end of CBH
            * interText : Block of text *between* any metaBlock metaClose line, and any CBH cbhOpen line.
            * metaCBlockIndex : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the metaBlock
            * CbhCBlockIndex  : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the cbhBlock
            #>
            <# so we want a stack of
            # [psm1name]

            [metaBlock]
            [interText]
            [cbhBlock]
            [PostCBHBlock]
            [space]
            [optional PostCBHBlock2]
            [space]
            ...and then add the includes to the file
            #>

            # doing a herestring assigned to $updatedContent *unwraps* everything!
            # do them in separately
            #"$($oBlkComments.metaBlock)`n$($oBlkComments.interText)`n$($oBlkComments.cbhBlock)" | Add-Content @pltAdd ;
            $updatedContent += "# $(split-path -path $PsmName -leaf)`n"
            if($oBlkComments.metaBlock){$updatedContent += $oBlkComments.metaBlock  |out-string ; } ;
            if($oBlkComments.interText ){$updatedContent += $oBlkComments.interText  |out-string ; } ;
            $updatedContent += $oBlkComments.cbhBlock |out-string ;

            # add $ModuleRoot & $ModuleVersion, if not already present
            #$rgxModRootvar = '\$script:ModuleRoot\s=\s\$PSScriptRoot\s;' ;
            #$rgxModVersvar = '\$script:ModuleVersion\s=\s\(Import-PowerShellDataFile\s-Path\s\(get-childitem\s\$script:moduleroot\\\*\.psd1\)\.fullname\)\.moduleversion\s;'
            # $runningInVsCode = $env:TERM_PROGRAM -eq 'vscode' ;

            # grab and add psv2 DYN exclude customization, or add empty defaults (should be present in either MON or DYN .psm1, to support going back and forth)
            $rgxPsv2Publvar = "\`$Psv2PublicExcl\s=\s@\(" ;
            $psv2PubLine = (select-string -Path  $PsmName -Pattern $rgxPsv2Publvar).line ;
            $rgxPsv2PrivExcl = "\`$Psv2PrivateExcl\s=\s@\(" ;
            $psv2PrivLine = (select-string -Path  $PsmName -Pattern $rgxPsv2PrivExcl).line

            # Post CBH always add the helper/alias-export command (functions are covered in the psd1 manifest, dyn's have in the template)
            $PostCBHBlock=@"

    `$script:ModuleRoot = `$PSScriptRoot ;
    `$script:ModuleVersion = (Import-PowerShellDataFile -Path (get-childitem `$script:moduleroot\*.psd1).fullname).moduleversion ;
    `$runningInVsCode = `$env:TERM_PROGRAM -eq 'vscode' ;

"@ ;

    # scrap the entire $psv2Publine etc block - it's causing corruption, and I won't need it post upgrade off of exop
     <# lifted from 241-251above:
     $(
    if($psv2PubLine){
        "$($psv2PubLine)"
    } else {
        "`$Psv2PublicExcl = @() ;"
    })
    $(
    if($psv2PrivLine){
        "$($psv2PrivLine)"
    } else {
        "`$Psv2PrivateExcl = @() ;"
    }
    )
     #>
            if($PostCBHBlock){
                write-verbose "adding `$PostCBHBlock"
                $updatedContent += $PostCBHBlock |out-string ;
            } ;

            # alt, instead of building block, we could subtract out the functions block from the existing .psm1 and sub in dyn

            # extract the dyn block out of $Psm1TemplatePath
            if(test-path -path $Psm1TemplatePath){
                # $dynIncludeOpen, $dynIncludeClose
                $rgxTmpDynStart = '#Get\spublic\sand\sprivate\sfunction\sdefinition\sfiles\.' ;
                $rgxTmpDynEnd = 'Export-ModuleMember\s-Function' ;
                $TmplrawSourceLines = get-content -path $Psm1TemplatePath  ;
                $TmplSrcLineTtl = ($TmplrawSourceLines | Measure-Object).count ;
                $TmpldynIncludeOpen = ($TmplrawSourceLines | select-string -Pattern $rgxTmpDynStart).linenumber ;
                $TmpldynIncludeClose = ($TmplrawSourceLines | select-string -Pattern $rgxTmpDynEnd).linenumber ;
                if($TmpldynIncludeOpen -AND $TmpldynIncludeClose){
                    $dynBlock = $TmplrawSourceLines[($TmpldynIncludeOpen-2)..($TmpldynIncludeClose-2)] ;
                    #$dynBlock += $TmplrawSourceLines[($TmpldynIncludeClose)..$Srclinettl] ;
                } else {

                } ;
                $updatedContent += $dynBlock |out-string ;


            } else {

            } ;


        } ;  # if-E mono to dyn conversion

        if($updatedContent){
           $pltSCFE=[ordered]@{PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; }
            $bRet = Set-ContentFixEncoding -Value ($updatedContent | out-string) -Path $PsmNameTmp @pltSCFE ;
            if(-not $bRet -AND -not $whatif){throw "Set-ContentFixEncoding $($PsmNameTmp)!" } else {
                $PassStatus += ";UPDATED:Set-ContentFixEncoding ";
            }  ;
        } else {
            $PassStatus += ";ERROR:Set-ContentFixEncoding";
            $smsg= "NO PARSEABLE METADATA/CBH CONTENT IN EXISTING FILE, TO BUILD UPDATED PSM1 FROM!`n$($PsmName)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #$false | write-output ;
            $ReportObj=[ordered]@{
                Status=$false ;
                PsmNameBU = $PsmNameBU ;
                PsdNameBU = $PsdNameBU ;
                PassStatus = $PassStatus ;
            } ;
            $ReportObj | write-output ;
            Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
        } ;
    } ; # if(test-path -path $PsmName)

    # DEFAULT - DIRS CREATION - git doesn't reproduce empty dirs, create if empty (avoids errors later)
    # exempt the .git & .vscode dirs, we don't publish those to modules dir
    # use the func
    $pltInitPsMDirs=[ordered]@{
        #ModuleName=$($ModuleName) ;
        ModuleSourcePath=$ModuleSourcePath ;
        ModuleDestinationPath=$ModuleDestinationPath ;
        #ModuleRootPath = $ModuleRootPath ;
        ErrorAction="Stop" ;
        #showdebug=$($showdebug);
        whatif=$($whatif);
    } ;
    $smsg= "Initialize-PSModuleDirectories w`n$(($pltInitPsMDirs|out-string).trim())" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    $sRet = Initialize-PSModuleDirectories @pltInitPsMDirs ;
    if($sRet){
        if([array]$sRet.split(';').trim() -contains 'new-item:ERROR'){
        # or, work with raw ;-delim'd string:
        #if($sret.indexof('new-item:ERROR')){
            $smsg = "Initialize-PSModuleDirectories:new-item:ERROR!"  ;
            write-warning $smsg ;
            throw $smsg ;
        }
    } else {
        $smsg = "(no `$sRet returned on call)" ;
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    } ;
    

    # $MODULESOURCEPATH - DIRS CREATION ( & loops the public files and adds to monolith .psm1)
    foreach ($ModuleSource in $ModuleSourcePath) {
        $iProcd++ ;
        if ($ModuleSource.GetType().FullName -ne 'System.IO.DirectoryInfo') {
            # git doesn't reproduce empty dirs, create if empty
            if(!(test-path -path $ModuleSource)){
                 $pltDir = [ordered]@{
                    path     = $ModuleSource ;
                    ItemType = "Directory" ;
                    ErrorAction="Stop" ;
                    whatif   = $($whatif) ;
                } ;
                $smsg = "Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $bRetryf=$false ;
                $error.clear() ;
                TRY {
                    new-item @pltDir | out-null ;
                    $PassStatus += ";new-item:UPDATED";
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $bRetry=$true ;
                    $PassStatus += ";new-item:ERROR";
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
                if($bRetry){
                    $pltDir.add('force',$true) ;
                    $smsg = "RETRY:FORCE:Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $error.clear() ;
                    TRY {
                        new-item @pltDir | out-null ;
                        $PassStatus += ";new-item:UPDATED";
                    } CATCH {
                        $ErrorTrapped = $Error[0] ;
                        $PassStatus += ";new-item:ERROR";
                        $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $bRetry=$false
                        Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
                    } ;
                } ;
            } ;
            $ModuleSource = get-item -path $ModuleSource ;
        } ;

        #
        # below loops the public files and adds to monolith .psm1
        # we still need to build the manual ExportFunctions for the psd1 update (can't be done dynamically in there)
        # Process components below $ModuleSource
        $sBnrS = "`n#*------v ($($iProcd)/$($ttl)):$($ModuleSource) v------" ;
        $smsg = "$($sBnrS)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $error.clear() ;
        TRY {
            [array]$ComponentScripts = $null ; [array]$ComponentModules = $null ;
            if($ModuleSource.count){
                # excl -Exclude _CommonCode.ps1 (gets added to .psm1 at end of all processing)
                $ComponentScripts = Get-ChildItem -Path $ModuleSource\*.ps1 -Exclude _CommonCode.ps1 -Recurse -ErrorAction SilentlyContinue | Sort-Object name  ;
                $ComponentModules = Get-ChildItem -Path $ModuleSource\*.psm1 -Recurse -ErrorAction SilentlyContinue | Sort-Object name;
            } ;
            #$pltAdd = @{Path=$PsmNameTmp ; whatif=$whatif;} ;
            # shift to Add-ContentFixEncoding
            $pltAdd =[ordered]@{Path=$PsmNameTmp ; PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; }

            $ttlCS = ($ComponentScripts|measure).count ; $pCS=0 ;
            foreach ($ScriptFile in $ComponentScripts) {
                $pCS++ ;
                $smsg= "Processing ($($pCS)/$($ttlCS)):$($ScriptFile)..." ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                $AST = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$Null ) ;
                $ASTFunctions =  $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;

                # public & functions = public ; private & internal = private - flip output to -showdebug or -verbose, only
                if($ModuleSource.fullname -match '(Public|Functions)'){
                    $smsg= "$($ScriptFile.name):PUB FUNC:`n$(($ASTFunctions) -join ',' |out-string)" ;
                    if($showDebug) {
                        if ($logging -AND ($showDebug -OR $verbose)) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug }  #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ;
                    $ExportFunctions += $ASTFunctions.name ;
                } elseif($ModuleSource -match '(Private|Internal)'){
                    $smsg= "$($ScriptFile.name):PRIV FUNC:`n$(($ASTFunctions) -join ',' |out-string)" ;
                    if($showDebug) {
                        if ($logging -AND ($showDebug -OR $verbose)) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug }  #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ;
                    $PrivateFunctions += $ASTFunctions.name ;
                } ;
            } ; # loop-E


        } CATCH {
            $ErrorTrapped = $Error[0] ;
            $PassStatus += ";ComponentLoop:ERROR";
            $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #$false | write-output ;
            $ReportObj=[ordered]@{
                Status=$false ;
                PsmNameBU = $PsmNameBU ;
                PsdNameBU = $PsdNameBU ;
                PassStatus = $PassStatus ;
            } ;
            $ReportObj | write-output ;
            #Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            Continue ;
        } ;

        $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;


    } ; # loop-E foreach ($ModuleSource in $ModuleSourcePath) {

    # add support for Public\_CommonCode.ps1 (module-spanning code that trails the functions block in the .psm1)
    if($PublicPath = $ModuleSourcePath |Where-Object{$_ -match 'Public'}){
        if($ModFile = Get-ChildItem -Path $PublicPath\_CommonCode.ps1 -ea 0 ){
            $smsg= "Adding:$($ModFile)..." ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $bRet = "#*======v _CommonCode v======" | out-string | Add-ContentFixEncoding @pltAdd ;
            if(-not $bRet -AND -not $whatif){throw "Add-ContentFixEncoding $($pltAdd.Path)!" } ;
            $Content = Get-Content $ModFile ;
            if($Content| Where-Object{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                $smsg= "*WARNING*:SUBFILE`n$($ModFile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;
                if($showDebug) {
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
                exit ;
            } ;
            $bRet = $Content | out-string | Add-ContentFixEncoding @pltAdd ;
            if(-not $bRet -AND -not $whatif){throw "Add-ContentFixEncoding $($pltAdd.Path)!" } ;
            $bRet = "#*======^ END _CommonCode ^======" | out-string | Add-ContentFixEncoding @pltAdd ;
            if(-not $bRet -AND -not $whatif){throw "Add-ContentFixEncoding $($pltAdd.Path)!" } ;
            $PassStatus += ";Add-Content:UPDATED";
        } else {
            write-verbose "(no Public\_CommonCode.ps1)" ;
        } ;
    } ;

    # append the Export-ModuleMember -Function $publicFunctions  (psd1 functionstoexport is functional instead),
    $smsg= "(Updating Psm1 Export-ModuleMember -Function to reflect Public modules)" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #"Export-ModuleMember -Function $(($ExportFunctions) -join ',')" | Add-Content @pltAdd ;
    # Collect & set explicitly in the psm1, the psd1 Set-ModuleFunctoin buildhelper isn't doing the full set, only above.
    # stick the Alias * in there too, force it as the psd1 spec's simply override the explicits in the psm1

    #"`nExport-ModuleMember -Function $(($ExportFunctions) -join ',') -Alias *" | Add-Content @pltAdd ;

    # tack in footerblock to the merged psm1 (primarily export-modulemember -alias * ; can also be any function-trailing content you want in the psm1)
    <# merged version
    $FooterBlock=@"

#*======^ END FUNCTIONS ^======

Export-ModuleMember -Function $(($ExportFunctions) -join ',') -Alias *

"@ ;
#>
    # unmerged version:
    # Export-ModuleMember -Function $Public.Basename ;
    $FooterBlock=@"

Export-ModuleMember -Function `$(`$Public.Basename) -join ',') -Alias *

"@ ;

    $pltAdd = [ordered]@{Path=$PsmNameTmp ; PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; }
    if(-not($NoAliasExport)){
        $smsg= "Adding:FooterBlock..." ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $bRet = $FooterBlock | out-string | Add-ContentFixEncoding @pltAdd ;
        if(-not $bRet -AND -not $whatif){throw "Add-ContentFixEncoding $($pltAdd.Path)!" } ;
        $PassStatus += ";Add-Content:UPDATED";
    } else {
        $smsg= "NoAliasExport specified:Skipping FooterBlock add" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $bRet = "#*======^ END FUNCTIONS ^======" | out-string | Add-ContentFixEncoding @pltAdd ;
        if(-not $bRet -AND -not $whatif){throw "Add-ContentFixEncoding $($pltAdd.Path)!" } ;
        $PassStatus += ";Add-Content:UPDATED";
    } ;

    # this can't be done dyn, it's a static array in the psd1, that will require a fresh merge pass to rebuild each added function .ps1
    # update the manifest too: # should be forced array: FunctionsToExport = @('build-VSCConfig','Get-CommentBlocks','get-VersionInfo','ConvertTo-ModuleDynamicTDO','parseHelp')
    $smsg = "Updating the Psd1 FunctionsToExport to match" ;
    if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    $rgxFuncs2Export = 'FunctionsToExport((\s)*)=((\s)*).*' ;

    $tf = $PsdNameTmp ;
    # switch back to manual local updates
    $pltSCFE=[ordered]@{Path = $tf ; PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; }
    if($psd1ExpMatch = Get-ChildItem $tf | select-string -Pattern $rgxFuncs2Export ){
        <#
        (Get-Content $tf) | Foreach-Object {
            $_ -replace $rgxFuncs2Export , ("FunctionsToExport = " + "@('" + $($ExportFunctions -join "','") + "')")
        } | out-string | Set-ContentFixEncoding @pltSCFE ;
        #>
        # 2-step it, we're getting only $value[-1] through the pipeline
        $newContent = (Get-Content $tf) | Foreach-Object {
            $_ -replace $rgxFuncs2Export , ("FunctionsToExport = " + "@('" + $($ExportFunctions -join "','") + "')")
        } | out-string ; # this writes to $PsdNameTmp
        $bRet = Set-ContentFixEncoding @pltSCFE -Value $newContent ;
        if(-not $bRet -AND -not $whatif){throw "Set-ContentFixEncoding $($tf)!" } ;
        $PassStatus += ";Set-Content:UPDATED";
    } else {
        $smsg = "UNABLE TO Regex out $($rgxFuncs2Export) from $($tf)`nFunctionsToExport CAN'T BE UPDATED!" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    } ;

     if(-not $whatif){
        $bRet = Test-ModuleTMPFiles @pltTMTmp ;

        if ($bRet.valid -AND $bRet.Manifest -AND $bRet.Module){
            $PassStatus += ";Test-ModuleTMPFiles:UPDATE";
            $pltCpyPsm1 = @{ Path=$PsmNameTmp ; Destination=$PsmName ; whatif=$whatif; ErrorAction="STOP" ; } ;
            $smsg = "Processing error free: Overwriting temp .psm1 with temp copy`ncopy-item w`n$(($pltCpyPsm1|out-string).trim())" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            $pltCpyPsd1 = @{ Path=$PsdNameTmp ; Destination=$PsdName ; whatif=$whatif; ErrorAction="STOP" ; } ;
            $error.clear() ;
            TRY {
                copy-Item  @pltCpyPsm1 ;
                $PassStatus += ";copy-Item:UPDATE";
                $smsg = "Processing error free: Overwriting temp .psd1 with temp copy`ncopy-item w`n$(($pltCpyPsd1|out-string).trim())" ;

                if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                copy-Item @pltCpyPsd1 ;
                $PassStatus += ";copy-Item:UPDATE";

            } CATCH {
                Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                $PassStatus += ";copy-Item:ERROR";
                Break  ;
            } ;
        } else {
            $smsg = "Test-ModuleTMPFiles:FAIL! Aborting!" ;
            $PassStatus += ";Test-ModuleTMPFiles :ERROR";
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            Break ;
        } ;
    } else {
        $smsg = "(whatif:skipping updates)" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info} #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    };

    #if($PassStatus.tolower().contains('error')){ # not properly matching, switch to select-string regex, the appends are line per append, multiline seems to break contains.
    if($PassStatus.tolower() | select-string '.*error.*'){
        $smsg = "ERRORS LOGGED, ABORTING UPDATE OF ORIGINAL .PSM1!:`n$($pltCpy.Destination)" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug
        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    } elseif(!$whatif) {
        
    } else {
        $smsg = "(whatif:skipping updates)" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info} #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    };
    $ReportObj=[ordered]@{
        Status=$true ;
        PsmNameBU = $PsmNameBU ;
        PsdNameBU = $PsdNameBU ;
        PassStatus = $PassStatus ;
    } ;
    if($PassStatus.tolower() | select-string '.*error.*'){
        $ReportObj.Status=$false ;
    } ;
    $ReportObj | write-output ;

    $smsg = $sBnr.replace('=v','=^').replace('v=','^=') ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
}

#*------^ ConvertTo-ModuleDynamicTDO.ps1 ^------


#*------v ConvertTo-ModuleMergedTDO.ps1 v------
function ConvertTo-ModuleMergedTDO {
    <#
    .SYNOPSIS
    ConvertTo-ModuleMergedTDO.ps1 - Merge function .ps1 files into a monolisthic module.psm1 module file, returns a hash with status:$true/$false, and PsmNameBU:The name of a backup of the original .psm1 file (for restoring on failures)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2019-12-10
    FileName    : ConvertTo-ModuleMergedTDO.ps1
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit : Przemyslaw Klys
    AddedWebsite: https://evotec.xyz/powershell-single-psm1-file-versus-multi-file-modules/
    Tags        : Powershell,Module,Development
    AddedTwitter:
    REVISIONS
    * 5:45 PM 8/7/2024 reformat params ; coerce $RequiredVersion from psd1.moduleversion, if blank ; add test for $rgxPurgeBlockEnd2, ExportModuleMembers syntax in later omds ; fixed/updated FunctionsToExport 
    * 2:04 PM 6/29/2022 rem'd out/removed the $psv2PubLine, $psv2PrivLine dyn exclude material - won't be needed once exop upgraded past psv2
    * 5:18 PM 6/1/2022 splice in support for confirm-ModuleBuildSync ; 
    * 5:16 PM 5/31/2022 add: -RequiredVersion; # 4:48 PM 5/31/2022 getting mismatch/revert in revision to prior spec, confirm/force set it here, call confirm-ModulePsd1Version()/confirm-ModulePsm1Version() (which handle _TMP versions, that stock tools *won't*)
    * 4:38 PM 5/27/2022 update all Set-ContentFixEncoding & Add-ContentFixEncoding -values to pre |out-string to collapse arrays into single writes
    * 8:34 AM 5/16/2022 sub backupfile -> backup-FileTDO ; typo: used Aliases for Alias
    * 3:07 PM 5/13/2022ren Merge-Module -> ConvertTo-ModuleMergedTDOTDO() (use std verb; adopt keyword to unique my work from 3rd-party funcs); added Merge-Module to Aliases; 
    * 4:08 PM 5/12/2022 got through a full non -Dyn pass, to publish and ipmo -for. Still need to port over latest merge-module.ps1 chgs -> unmerge-module.ps1. ; updated CBH expl ; cleanedup, duped over minor items from unmerge-module()
    * 2:24 PM 5/9/2022 backed in, untested, updates from unmerge-module, to bring roughly back into sync.
    * 3:40 PM 5/3/2022 coded in, untested, remove-authenticodesignature(), and Psv2 DYN exclude $PostCBHBlock content
    * 11:25 AM 9/21/2021 added code to remove obsolete gens of .nupkgs & build log files (calls to new verb-io:remove-UnneededFileVariants()); CBH:added Tags; fixed missing CmdletBinding (which breaks functional verbose); added brcketing Banr (easier to tell where breaks occur)
    * 12:15 PM 4/21/2021 expanded select-string aliases
    * 11:42 AM 6/30/2020 fixed Public\_CommonCode.ps1, -ea 0 when not present
    * 1:13 PM 6/29/2020 add support for .Public\_CommonCode.ps1 - module-spanning code that should follow the Function block in the .psm1
    * 3:27 PM 3/15/2020 load-Module: added $PsmNameTmp, $PsdNameTmp and shifted updating to a _TMP file of each, which at end, if error free, overwrites the current functional copy (correcting prior issue with corruption of existing copy, when there were processing errors).
    * failing to load verb-io content, added a forceload if get-fileencoding isn't present, added new PassStatus tests and passed back in output, also now does the build in a .psm1_TMP file, to avoid damaging last functional copy
    * 12:42 PM 3/3/2020 fixed missing trailing sbnr (Internal)
    * 10:36 AM 3/3/2020 added pre-check & echo when unable to locate the psd1 FunctionsToExport value
    * 1:58 PM 3/2/2020 as Set-ModuleFunction isn't properly setting *all* exported, go back to collecting and updating the psm1 & psd1 *both* via regx
    * 9:12 AM 2/29/2020 shift export-modulemember/FooterBlock to bottom, added FUNCTIONS delimiter lines
    * 9:17 AM 2/27/2020 added new -NoAliasExport param, and added the missing
    * 3:44 PM 2/26/2020 Merge-Module: added -LogSpec param (feed it the object returned by a Start-Log() pass).
    * 11:27 AM Merge-Module 2/24/2020 suppress block dumps to console, unless -showdebug or -verbose in use
    * 7:24 AM 1/3/2020 #936: trimmed errant trailing ;- byproduct of fix-encoding pass
    * 10:33 AM 12/30/2019 Merge-Module():951,952 assert sorts into alpha order (make easier to find in the psm1)
    * 10:20 AM 12/30/2019 Merge-Module(): fixed/debugged monolithic build options, now works. Could use some code to autoupdate all .NOTES:Version fields, but that's for future.
    * 8:59 AM 12/30/2019 Merge-Module(): Added code to update against monolithic/non-dyn-incl psm1s. Parses CBH & meta blocks out & constructs a new psm1 from the content.
    * 9:51 AM 12/28/2019 Merge-Module fixed $sBnrSStart/End typo
    * 1:23 PM 12/27/2019 pulled regex sig replace with simple start/end detect and throw error (was leaving dangling curlies in psm1)
    * 12:11 PM 12/27/2019 swapped write-error in catch blocks with write-warning - we seems to be failing to exec the bal of the catch
    * 7:46 AM 12/27/2019 Merge-Module(): added included file demarc comments to improve merged file visual parsing, accumulating $PrivateFunctions now as well, explicit echos
    * 8:51 AM 12/20/2019 removed plural from ModuleSourcePaths -> ModuleSourcePath (matches all the calls etc)
    *8:50 PM 12/18/2019 sorted hard-coded verb-aad typo
    2:54 PM 12/11/2019 rewrote, added backup of psm1, parsing out the stock dyn-include code from the orig psm1, leverages fault-tolerant set-fileContent(), switched sourcepaths to array type, and looped, detecting public/internal by path and prepping for the export list.
    * 2018/11/06 Przemyslaw Klys posted version
    .DESCRIPTION
    ConvertTo-ModuleMergedTDO.ps1 - Merge function .ps1 files into a monolisthic module.psm1 module file, returns a hash with status:$true/$false, and PsmNameBU:The name of a backup of the original .psm1 file (for restoring on failures)
    .PARAMETER  ModuleName
    Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]
    .PARAMETER  ModuleSourcePath
    Directory containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]
    .PARAMETER ModuleDestinationPath
    Final monolithic module .psm1 file name to be populated [-ModuleDestinationPath c:\path-to\module\module.psm1]
    .PARAMETER RequiredVersion
    Optional Explicit 3-digit RequiredVersion specification (as contrasts with using current Manifest .psd1 ModuleVersion value)[-Version 2.0.3]
    .PARAMETER NoAliasExport
    Flag that skips auto-inclusion of 'Export-ModuleMember -Alias * ' in merged file [-NoAliasExport]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Outputs a hashtable object containing: Status[$true/$false], PsmNameBU [the name of the backup of the original psm1 file]
    .EXAMPLE
    .\ConvertTo-ModuleMergedTDO.ps1 -ModuleName verb-AAD -ModuleSourcePath C:\sc\verb-AAD\Public -ModuleDestinationPath C:\sc\verb-AAD\verb-AAD -showdebug -whatif ;
    Command line process
    .EXAMPLE
    PS> $pltmergeModule=[ordered]@{
    PS>     ModuleName="verb-AAD" ;
    PS>     ModuleSourcePath="C:\sc\verb-AAD\Public","C:\sc\verb-AAD\Internal" ;
    PS>     ModuleDestinationPath="C:\sc\verb-AAD\verb-AAD" ;
    PS>     LogSpec = $logspec ;
    PS>     NoAliasExport=$($NoAliasExport) ;
    PS>     ErrorAction="Stop" ;
    PS>     showdebug=$($showdebug);
    PS>     whatif=$($whatif);
    PS> } ;
    PS> $smsg= "ConvertTo-ModuleMergedTDO w`n$(($pltmergeModule|out-string).trim())" ;
    PS> if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
    PS> else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS> $ReportObj = ConvertTo-ModuleMergedTDO @pltmergeModule ;
    Splatted example (from process-NewModule.ps1)
    .LINK
    https://www.toddomation.com
    #>
    [CmdletBinding()]
    [Alias('Merge-Module')]
    PARAM (
        [Parameter(Mandatory = $True, HelpMessage = "Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]")]
            [string] $ModuleName,
        [Parameter(Mandatory = $True, HelpMessage = "Array of directory paths containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]")]
            [array] $ModuleSourcePath,
        [Parameter(Mandatory = $True, HelpMessage = "Directory path in which the final .psm1 file should be constructed [-ModuleDestinationPath c:\path-to\module\module.psm1]")]
            [string] $ModuleDestinationPath,
        [Parameter(HelpMessage="Optional Explicit 3-digit RequiredVersion specification (as contrasts with using current Manifest .psd1 ModuleVersion value)[-Version 2.0.3]")]
            [version]$RequiredVersion,
        [Parameter(Mandatory = $False, HelpMessage = "Logging spec object (output from start-log())[-LogSpec `$LogSpec]")]
            $LogSpec,
        [Parameter(HelpMessage = "Flag that skips auto-inclusion of 'Export-ModuleMember -Alias * ' in merged file [-NoAliasExport]")]
            [switch] $NoAliasExport,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
            [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
            [switch] $whatIf
    ) ;
    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
    # Get parameters this function was invoked with
    $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
    write-verbose  "`$PSBoundParameters:`n$(($PSBoundParameters|out-string).trim())" ;
    $verbose = ($VerbosePreference -eq "Continue") ;
    
    $sBnr="#*======v $(${CmdletName}): v======" ; 
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    
    # (unused for -merged, but dupe over from unmerge-module, for some consistency)
    $Psm1TemplatePath = "C:\sc\powershell\PlasterModuleTemplate-master\PPoShModuleTemplate\template.psm1" ; 
    $rgxSigStart='#\sSIG\s#\sBegin\ssignature\sblock' ;
    $rgxSigEnd='#\sSIG\s#\sEnd\ssignature\sblock' ;
    
    $PassStatus = $null ;
    $PassStatus = @() ;

    $tModCmdlet = "Get-FileEncoding" ;
    if(!(test-path function:$tModCmdlet)){
         write-warning -verbose:$true  "UNABLE TO VALIDATE PRESENCE OF $tModCmdlet";
         $tModFile = "verb-IO.ps1" ; $sLoad = (join-path -path $LocalInclDir -childpath $tModFile) ; if (Test-Path $sLoad) {     Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ; . $sLoad ; if ($showdebug) { Write-Verbose -verbose "Post $sLoad" }; } else {     $sLoad = (join-path -path $backInclDir -childpath $tModFile) ; if (Test-Path $sLoad) {         Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ; . $sLoad ; if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };     }     else { Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ; exit; } ; } ;
    } ;

    if($logspec){
        $logging=$logspec.logging ;
        $logfile=$logspec.logfile ;
        $transcript=$logspec.transcript ;
    } ;

    <# doesn't do anything: resolve to gci, but assigned to strong-typed [string] vari -> just re-coerces back to [string} on fullname property
    if ($ModuleDestinationPath.GetType().FullName -ne 'System.IO.DirectoryInfo') {
        $ModuleDestinationPath = get-item -path $ModuleDestinationPath ;
        # doesn't do anything: resolve to gci, but on [string] vari, just re-coercess back to string on fullname
    } ;
    #>

    $ModuleRootPath = split-path $ModuleDestinationPath -Parent ;

    $ttl = ($ModuleSourcePath | Measure-Object).count ;
    $iProcd = 0 ;

    $ExportFunctions = @() ;
    $PrivateFunctions = @() ;

    $PsmName="$ModuleDestinationPath\$ModuleName.psm1" ;
    $PsdName="$ModuleDestinationPath\$ModuleName.psd1" ;
    $PsmNameTmp="$ModuleDestinationPath\$ModuleName.psm1_TMP" ;
    $PsdNameTmp="$ModuleDestinationPath\$ModuleName.psd1_TMP" ;
    if(-not $RequiredVersion){
        $psdProfile = Test-ModuleManifest -Path $PsdName -ErrorAction STOP ; 
        [string]$RequiredVersion = $psdProfile.version
    } ; 

    # backup existing & purge the dyn-include block
    if(test-path -path $PsmName){
        $rawSourceLines = get-content -path $PsmName  ;
        $SrcLineTtl = ($rawSourceLines | Measure-Object).count ;
        write-verbose "(backup-FileTDO -path $($PsmName))" ;
        $PsmNameBU = backup-FileTDO -path $PsmName -showdebug:$($showdebug) -whatif:$($whatif) ;
        if (!$PsmNameBU) {throw "FAILURE" } ;

        # also backup the $psdname
        if(test-path -path $PsmName){
            write-verbose "(backup-FileTDO -path $($psdname))" ;
            $PsdNameBU = backup-FileTDO -path $PsdName -showdebug:$($showdebug) -whatif:$($whatif) ;
            if (!$PsdNameBU) {throw "FAILURE" } ;
        } ; 

        # the above produces 'C:\sc\verb-Auth\verb-Auth\verb-auth.psm1_20210609-1544PM' files from the prior .psm1
        # make it purge all but the last 2 backups above, dated prior to today.
        #$PsmName = 'C:\sc\verb-Auth\verb-Auth\verb-Auth.psm1'
        $pltRGens =[ordered]@{
            Path = (split-path $PsmName) ;
            Include =(split-path $PsmName -leaf).replace('.psm1','.psm1_*') ;
            Pattern = '\.ps(m|d)1_\d{8}-\d{3,4}(A|P)M$' ;
            FilterOn = 'CreationTime' ;
            Keep = 2 ;
            KeepToday = $true ;
            verbose=$true ;
            whatif=$($whatif) ;
        } ; 
        write-host -foregroundcolor green "DEADWOOD REMOVAL:remove-UnneededFileVariants w`n$(($pltRGens|out-string).trim())" ; 
        remove-UnneededFileVariants @pltRGens ;

        # this script *appends* to the existing .psm1 file.
        # which by default includes a dynamic include block:
        # detect and drop out the above, for the monolithic version
        $rgxPurgeblockStart = '#Get\spublic\sand\sprivate\sfunction\sdefinition\sfiles\.' ;
        # stock dyanmic export of collected functions
        #$rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s;';
        # updated version of dyn end, that also explicitly exports -alias *
        $rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s-Alias\s\*\s;\s'
        $rgxPurgeBlockEnd2 = 'Export-ModuleMember\s-Function\s\$Public\.Basename\s-Alias\s\*\s;'
        $dynIncludeOpen = ($rawsourcelines | select-string -Pattern $rgxPurgeblockStart).linenumber ;
        $dynIncludeClose = ($rawsourcelines | select-string -Pattern $rgxPurgeBlockEnd).linenumber ;
        if(-not $dynIncludeClose){
            $dynIncludeClose = ($rawsourcelines | select-string -Pattern $rgxPurgeBlockEnd2).linenumber ;
        } ; 
        if(!$dynIncludeOpen){$dynIncludeClose = 0 } ;
        $updatedContent = @() ; $DropContent=@() ;

        if($dynIncludeOpen -AND $dynIncludeClose){
            # dyn psm1
            $smsg= "(dyn-include psm1 detected - purging content for Merged Build...)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $updatedContent = $rawSourceLines[0..($dynIncludeOpen-2)] ;
            $updatedContent += $rawSourceLines[($dynIncludeClose)..$Srclinettl] ;
            $DropContent = $rawsourcelines[$dynIncludeOpen..$dynIncludeClose] ;
            if($showdebug){
                $smsg= "`$DropContent:`n$($DropContent|out-string)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ;
        } else {
            # monolithic psm1?
            $smsg= "(NON-dyn psm1 detected - purging existing non-CBH content...)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            # parse out the CBH and just start from that:
            $oBlkComments = Get-CommentBlocks -TextLines $rawSourceLines -showdebug:$($showdebug) -whatif:$($whatif) ;
            <# returned props
            * metaBlock : `<#PSScriptInfo..#`> published script metadata block (added via New|Update-ScriptFileInfo, at top of file)
            * metaOpen : Line# of start of metaBlock
            * metaClose : Line# of end of metaBlock
            * cbhBlock : Comment-Based-Help block
            * cbhOpen : Line# of start of CBH
            * cbhClose : Line# of end of CBH
            * interText : Block of text *between* any metaBlock metaClose line, and any CBH cbhOpen line.
            * metaCBlockIndex : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the metaBlock
            * CbhCBlockIndex  : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the cbhBlock
            #>
            <# so we want a stack of
            # [psm1name]

            [metaBlock]
            [interText]
            [cbhBlock]
            [PostCBHBlock]
            [space]
            [optional PostCBHBlock2]
            [space]
            ...and then add the includes to the file
            #>

            # doing a herestring assigned to $updatedContent *unwraps* everything!
            # do them in separately
            #"$($oBlkComments.metaBlock)`n$($oBlkComments.interText)`n$($oBlkComments.cbhBlock)" | Add-Content @pltAdd ;
            $updatedContent += "# $(split-path -path $PsmName -leaf)`n"
            if($oBlkComments.metaBlock){$updatedContent += $oBlkComments.metaBlock  |out-string ; } ;
            if($oBlkComments.interText ){$updatedContent += $oBlkComments.interText  |out-string ; } ;
            $updatedContent += $oBlkComments.cbhBlock |out-string ;

            # grab and add psv2 exclude customization, or add empty defaults (should be present in either MON or DYN .psm1ss, to support going back and forth)
            #$Psv2PublicExcl = @('ConvertFrom-SourceTable.ps1','Test-PendingReboot.ps1') ;
            $rgxPsv2Publvar = "\`$Psv2PublicExcl\s=\s@\(" ;  
            $psv2PubLine = (select-string -Path  $PsmName -Pattern $rgxPsv2Publvar).line ; 
            $rgxPsv2PrivExcl = "\`$Psv2PrivateExcl\s=\s@\(" ;  
            $psv2PrivLine = (select-string -Path  $PsmName -Pattern $rgxPsv2PrivExcl).line

            # Post CBH always add the helper/alias-export command (functions are covered in the psd1 manifest, dyn's have in the template)
            $PostCBHBlock=@"

    `$script:ModuleRoot = `$PSScriptRoot ;
    `$script:ModuleVersion = (Import-PowerShellDataFile -Path (get-childitem `$script:moduleroot\*.psd1).fullname).moduleversion ;
    `$runningInVsCode = `$env:TERM_PROGRAM -eq 'vscode' ;

#*======v FUNCTIONS v======

"@ ;
     
     # scrap the entire $psv2Publine etc block - it's causing corruption, and I won't need it post upgrade off of exop
     <# lifted from 277 - 288 above:
     $(
    if($psv2PubLine){
        "$($psv2PubLine)"
    } else {
        "`$Psv2PublicExcl = @() ;"
    })
    $(
    if($psv2PrivLine){
        "$($psv2PrivLine)"
    } else {
        "`$Psv2PrivateExcl = @() ;"
    })
     #>
     
     
            write-verbose "adding `$PostCBHBlock"
            $updatedContent += $PostCBHBlock |out-string ;

        } ;  # if-E dyn/monolithic source psm1


        if($updatedContent){
            $pltSCFE=[ordered]@{PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; } 
            #$bRet = Set-ContentFixEncoding -Value $updatedContent -Path $PsmNameTmp @pltSCFE ; 
            # we're getting 4 writes in set-cfe, for each block added to updatedcontent, lets try |out-string before passing, to see if they fold into one write
            $bRet = Set-ContentFixEncoding -Value ($updatedContent| out-string) -Path $PsmNameTmp @pltSCFE ; 
            if(-not $bRet -AND -not $whatif){throw "Set-ContentFixEncoding $($PsmNameTmp)!" } else {
                $PassStatus += ";UPDATED:Set-ContentFixEncoding ";
            }  ;
        } else {
            $PassStatus += ";ERROR:Set-ContentFixEncoding";
            $smsg= "NO PARSEABLE METADATA/CBH CONTENT IN EXISTING FILE, TO BUILD UPDATED PSM1 FROM!`n$($PsmName)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #$false | write-output ;
            $ReportObj=[ordered]@{
                Status=$false ;
                PsmNameBU = $PsmNameBU ;
                PsdNameBU = $PsdNameBU ;
                PassStatus = $PassStatus ;
            } ;
            $ReportObj | write-output ;
            Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
        } ;
    } ;

    # DEFAULT - DIRS CREATION - git doesn't reproduce empty dirs, create if empty (avoids errors later)
    # exempt the .git & .vscode dirs, we don't publish those to modules dir
    # use the func
    $pltInitPsMDirs=[ordered]@{
        #ModuleName=$($ModuleName) ;
        ModuleSourcePath=$ModuleSourcePath ;
        ModuleDestinationPath=$ModuleDestinationPath ;
        #ModuleRootPath = $ModuleRootPath ;
        ErrorAction="Stop" ;
        #showdebug=$($showdebug);
        whatif=$($whatif);
    } ;
    $smsg= "Initialize-PSModuleDirectories w`n$(($pltInitPsMDirs|out-string).trim())" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

    $sRet = Initialize-PSModuleDirectories @pltInitPsMDirs ;
    #if($sRet.split(';') -contains "new-item:ERROR"){
    if($sRet){
        if([array]$sRet.split(';').trim() -contains 'new-item:ERROR'){
        # or, work with raw ;-delim'd string:
        #if($sret.indexof('new-item:ERROR')){
            $smsg = "Initialize-PSModuleDirectories:new-item:ERROR!"  ;
            write-warning $smsg ; 
            throw $smsg ;
        }
    } else {
        $smsg = "(no `$sRet returned on call)" ;
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    } ; 


    # $MODULESOURCEPATH - DIRS CREATION
    foreach ($ModuleSource in $ModuleSourcePath) {
        $iProcd++ ;
        if ($ModuleSource.GetType().FullName -ne 'System.IO.DirectoryInfo') {
            # git doesn't reproduce empty dirs, create if empty
            if(!(test-path -path $ModuleSource)){
                 $pltDir = [ordered]@{
                    path     = $ModuleSource ;
                    ItemType = "Directory" ;
                    ErrorAction="Stop" ;
                    whatif   = $($whatif) ;
                } ;
                $smsg = "Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $bRetry=$false ;
                $error.clear() ;
                TRY {
                    new-item @pltDir | out-null ;
                    $PassStatus += ";new-item:UPDATED";
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $bRetry=$true ;
                    $PassStatus += ";new-item:ERROR";
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
                if($bRetry){
                    $pltDir.add('force',$true) ;
                    $smsg = "RETRY:FORCE:Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $error.clear() ;
                    TRY {
                        new-item @pltDir | out-null ;
                        $PassStatus += ";new-item:UPDATED";
                    } CATCH {
                        $ErrorTrapped = $Error[0] ;
                        $PassStatus += ";new-item:ERROR";
                        $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $bRetry=$false
                        Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
                    } ;
                } ;
            } ;
            $ModuleSource = get-item -path $ModuleSource ;
        } ;

        # Process components below $ModuleSource
        $sBnrS = "`n#*------v ($($iProcd)/$($ttl)):$($ModuleSource) v------" ;
        $smsg = "$($sBnrS)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $error.clear() ;
        TRY {
            [array]$ComponentScripts = $null ; [array]$ComponentModules = $null ;
            if($ModuleSource.count){
                # excl -Exclude _CommonCode.ps1 (gets added to .psm1 at end of all processing)
                $ComponentScripts = Get-ChildItem -Path $ModuleSource\*.ps1 -Exclude _CommonCode.ps1 -Recurse -ErrorAction SilentlyContinue | Sort-Object name  ;
                $ComponentModules = Get-ChildItem -Path $ModuleSource\*.psm1 -Recurse -ErrorAction SilentlyContinue | Sort-Object name;
            } ;

            #$pltAdd = @{ Path=$PsmNameTmp ; whatif=$whatif; } ;
            $pltAdd = [ordered]@{Path=$PsmNameTmp ; PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; } 

            # -Merged/monolithic should have no sigs on included functions: just do a batch remove-authenticodesignature pass on all of the above
            $smsg= "Processing $($ComponentScripts.count) `$ComponentScripts files through Remove-AuthenticodeSignature..." ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $pltRAS=[ordered]@{ Path = $ComponentScripts.fullname ;  whatif = $($whatif) ;  verbose = $($verbose) ;  } ; 
            $smsg = "Remove-AuthenticodeSignature w`n$(($pltRAS|out-string).trim())" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            # nocap, isn't currently built to return status
            Remove-AuthenticodeSignature @pltRAS ; 

            $ttlCS = ($ComponentScripts|measure).count ; $pCS=0 ; 
            foreach ($ScriptFile in $ComponentScripts) {
                $pCS++ ; 
                $smsg= "Processing ($($pCS)/$($ttlCS)):$($ScriptFile)..." ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $ParsedContent = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$null) ;
                # above is literally the entire AST, unfiltered. Should be ALL parsed entities.
                # add demarc comments - this is AST parsed, so it prob doesn't include delimiters
                $sBnrSStart = "`n#*------v $($ScriptFile.name) v------" ;
                $sBnrSEnd = "$($sBnrSStart.replace('-v','-^').replace('v-','^-'))" ;
                #$bRet = "$($sBnrSStart)`n$($ParsedContent.EndBlock.Extent.Text)`n$($sBnrSEnd)" | Add-ContentFixEncoding @pltAdd ;
                # add | out-string to collapse object arrays
                $bRet = "$($sBnrSStart)`n$($ParsedContent.EndBlock.Extent.Text)`n$($sBnrSEnd)" | out-string | Add-ContentFixEncoding @pltAdd ;
                if(-not $bRet -AND -not $whatif){throw "Add-ContentFixEncoding $($pltAdd.Path)!" } ;

                $AST = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$Null ) ;
                $ASTFunctions =  $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;

                # public & functions = public ; private & internal = private - flip output to -showdebug or -verbose, only
                if($ModuleSource.fullname -match '(Public|Functions)'){
                    $smsg= "$($ScriptFile.name):PUB FUNC:`n$(($ASTFunctions) -join ',' |out-string)" ;
                    if($showDebug) {
                        if ($logging -AND ($showDebug -OR $verbose)) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug }  #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ;
                    $ExportFunctions += $ASTFunctions.name ;
                } elseif($ModuleSource -match '(Private|Internal)'){
                    $smsg= "$($ScriptFile.name):PRIV FUNC:`n$(($ASTFunctions) -join ',' |out-string)" ;
                    if($showDebug) {
                        if ($logging -AND ($showDebug -OR $verbose)) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug }  #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ;
                    $PrivateFunctions += $ASTFunctions.name ;
                } ;
            } ; # loop-E

            # Process Modules below project
            $ttlCM = ($ComponentModules|measure).count ; $pCM=0 ; 
            foreach ($ModFile in $ComponentModules) {
                $pCM++ ; 
                $smsg= "Adding ($($pCM)/$($ttlCM)):$($ModFile)..." ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $Content = Get-Content $ModFile ;

                if($Content| Where-Object{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                    $smsg= "*WARNING*:SUBFILE`n$($ModFile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;
                    if($showDebug) {
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ;
                    exit ;
                } ;
                # add | out-string to collapse object arrays
                $bRet = $Content | out-string | Add-ContentFixEncoding @pltAdd ;
                if(-not $bRet -AND -not $whatif){throw "Add-ContentFixEncoding $($pltAdd.Path)!" } ;
                $PassStatus += ";Add-Content:UPDATED";
                # by contrast, this is NON-AST parsed - it's appending the entire raw file content. Shouldn't need delimiters - they'd already be in source .psm1
            } ;

        } CATCH {
            $ErrorTrapped = $Error[0] ;
            $PassStatus += ";ComponentLoop:ERROR";
            $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #$false | write-output ;
            $ReportObj=[ordered]@{
                Status=$false ;
                PsmNameBU = $PsmNameBU ;
                PsdNameBU = $PsdNameBU ;
                PassStatus = $PassStatus ;
            } ;
            $ReportObj | write-output ;
            #Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            Continue ;
        } ;

        $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;


    } ; # loop-E foreach ($ModuleSource in $ModuleSourcePath) {

    # add support for Public\_CommonCode.ps1 (module-spanning code that trails the functions block in the .psm1)
    if($PublicPath = $ModuleSourcePath |Where-Object{$_ -match 'Public'}){
        if($ModFile = Get-ChildItem -Path $PublicPath\_CommonCode.ps1 -ea 0 ){
            $smsg= "Adding:$($ModFile)..." ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            # add | out-string to collapse object arrays
            $bRet = "#*======v _CommonCode v======" | out-string | Add-ContentFixEncoding @pltAdd ;
            if(-not $bRet -AND -not $whatif){throw "Add-ContentFixEncoding $($pltAdd.Path)!" } ;
            $Content = Get-Content $ModFile ;
            if($Content| Where-Object{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                $smsg= "*WARNING*:SUBFILE`n$($ModFile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;
                if($showDebug) {
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
                exit ;
            } ;
            $bRet =$Content | out-string | Add-ContentFixEncoding @pltAdd ;
            if(-not $bRet -AND -not $whatif){throw "Add-ContentFixEncoding $($pltAdd.Path)!" } ;
            $bRet ="#*======^ END _CommonCode ^======" | out-string | Add-ContentFixEncoding @pltAdd ;
            if(-not $bRet -AND -not $whatif){throw "Add-ContentFixEncoding $($pltAdd.Path)!" } ;
            $PassStatus += ";Add-Content:UPDATED";
        } else {
            write-verbose "(no Public\_CommonCode.ps1)" ;
        } ;
    } ;

    # append the Export-ModuleMember -Function $publicFunctions  (psd1 functionstoexport is functional instead),
    $smsg= "(Updating Psm1 Export-ModuleMember -Function to reflect Public modules)" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #"Export-ModuleMember -Function $(($ExportFunctions) -join ',')" | Add-Content @pltAdd ;
    # Collect & set explicitly in the psm1, the psd1 Set-ModuleFunctoin buildhelper isn't doing the full set, only above.
    # stick the Alias * in there too, force it as the psd1 spec's simply override the explicits in the psm1

    #"`nExport-ModuleMember -Function $(($ExportFunctions) -join ',') -Alias *" | Add-Content @pltAdd ;

    # tack in footerblock to the merged psm1 (primarily export-modulemember -alias * ; can also be any function-trailing content you want in the psm1)
    <# unmerged version:
    $FooterBlock=@"

Export-ModuleMember -Function `$(`$Public.Basename) -join ',') -Alias *

"@ ;
#>
    # merged version
    $FooterBlock=@"

#*======^ END FUNCTIONS ^======

Export-ModuleMember -Function $(($ExportFunctions) -join ',') -Alias *

"@ ;
    $pltAdd = [ordered]@{Path=$PsmNameTmp ; PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; } 
    if(-not($NoAliasExport)){
        $smsg= "Adding:FooterBlock..." ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $bRet = $FooterBlock | out-string | Add-ContentFixEncoding @pltAdd ;
        if(-not $bRet -AND -not $whatif){throw "Add-ContentFixEncoding $($pltAdd.Path)!" } ;
        $PassStatus += ";Add-Content:UPDATED";
    } else {
        $smsg= "NoAliasExport specified:Skipping FooterBlock add" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $bRet = "#*======^ END FUNCTIONS ^======" | out-string | Add-ContentFixEncoding @pltAdd ;
        if(-not $bRet -AND -not $whatif){throw "Add-ContentFixEncoding $($pltAdd.Path)!" } ;
        $PassStatus += ";Add-Content:UPDATED";
    } ;


    # update the manifest too: # should be forced array: FunctionsToExport = @('build-VSCConfig','Get-CommentBlocks','get-VersionInfo','ConvertTo-ModuleMergedTDO','parseHelp')
    $smsg = "Updating the Psd1 FunctionsToExport to match" ;
    if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    $rgxFuncs2Export = 'FunctionsToExport((\s)*)=((\s)*).*' ;
    # build a dummy name for testing .psm1|psd1
    #$testpsm1 = join-path -path (split-path $PsmNameTmp) -ChildPath "$(new-guid).psm1" ; 

    <# 1:57 PM 8/7/2024
    if(-not (test-path $PsdNameTmp) -And (test-path $PsdName)){
        $smsg = "no pre-existing `$PsdNameTmp ; sourcing `$PsdNameTmp as stock copy of $($PsdName) " ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success   
        $srcPsd = $PsdName ; 
        $destPsed = $PsdNameTmp ; 
    } ; 
    $tf = $PsdNameTmp ;
    # switch back to manual local updates
    # 1:57 PM 8/7/2024
    # issue: $psmNameTmp has been constructed bit by bit accumlating thge migrated content
    # but $psdNameTmp has never been touched. Should be read off of the source psd1
    # set-content => $tf/$psdNameTmp
    # the source will need to be the $PsdName
    #>
    $pltSCFE=[ordered]@{
        Path = $PsdNameTmp ; # $tf ;
        PassThru=$true ;
        Verbose=$($verbose) ;
        whatif= $($whatif) ;
    } 
    #if($psd1ExpMatch = Get-ChildItem $tf | select-string -Pattern $rgxFuncs2Export ){
    if($psd1ExpMatch = Get-ChildItem $PsdName | select-string -Pattern $rgxFuncs2Export ){
        # 2-step it, we're getting only $value[-1] through the pipeline
        # add | out-string to collapse object arrays
        #$newContent = (Get-Content $tf) | Foreach-Object {
        # 1:58 PM 8/7/2024 switch src to orig $psdName
        $newContent = (Get-Content $PsdName) | Foreach-Object {
            $_ -replace $rgxFuncs2Export , ("FunctionsToExport = " + "@('" + $($ExportFunctions -join "','") + "')")
        } | out-string ; 
        # this writes to $PsdNameTmp
        $bRet = Set-ContentFixEncoding @pltSCFE -Value $newContent ; 
        if(-not $bRet -AND -not $whatif){throw "Set-ContentFixEncoding $($tf)!" } ;
        $PassStatus += ";Set-Content:UPDATED";
    } else {
        $smsg = "UNABLE TO Regex out $($rgxFuncs2Export) from $($tf)`nFunctionsToExport CAN'T BE UPDATED!" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    } ;

    # 4:48 PM 5/31/2022 getting mismatch/revert in revision to prior spec, confirm/force set it here:
    # 2:16 PM 6/1/2022 shift to confirm-ModuleBuildSync() wrapper
    <# -----------
    # $bRet = confirm-ModulePsd1Version -Path 'C:\sc\verb-IO\verb-IO\verb-IO.psd1_TMP' -RequiredVersion '2.0.3' -whatif  -verbose
    # [Parameter(HelpMessage="Optional Explicit 3-digit RequiredVersion specification (as contrasts with using current Manifest .psd1 ModuleVersion value)[-Version 2.0.3]")]
    #        [version]$RequiredVersion,
    $pltCMPV=[ordered]@{
        Path = $PsdNameTmp ;
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
    } else { 
        $smsg = "confirm-ModulePsd1Version:FAIL! Aborting!" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        Break ;
    } ;
    
    # do the psm1 too
    #$bRet = confirm-ModulePsm1Version -Path 'C:\sc\verb-IO\verb-IO\verb-io.psm1_TMP' -RequiredVersion '2.0.3' -whatif:$($whatif) -verbose:$($verbose) ;
    $pltCMPMV=[ordered]@{
        Path = $PsmNameTmp ; ;
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
    } else { 
        $smsg = "confirm-ModulePsm1Version:FAIL! Aborting!" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        Break ;
    } ;
    # -----------
    #>
    # shift to wrapper confirm-ModuleBuildSync() -NoTest, as only process-NewModule needs that step
    # $bRet = confirm-ModuleBuildSync -ModPsdPath 'C:\sc\verb-IO\verb-IO\verb-IO.psd1_TMP' -RequiredVersion '2.0.3' -whatif -verbose
    $pltCMBS=[ordered]@{
        ModPsdPath = $PsdNameTmp ;
        RequiredVersion = $RequiredVersion ;
        NoTest = $true ; 
        whatif = $($whatif) ;
        verbose = $($verbose) ;
    } ;
    $smsg = "confirm-ModuleBuildSync w`n$(($pltCMBS|out-string).trim())" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    $bRet = confirm-ModuleBuildSync @pltCMBS ;
    if($bRet.Manifest -AND $bRet.Module -AND $bRet.Pester -AND $bRet.Guid -AND $bRet.Version -AND $bRet.Valid){
        $smsg = "(confirm-ModuleBuildSync:Success)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } else { 
        $smsg = "confirm-ModuleBuildSync:FAIL! Aborting!" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        Break ;
    } ;    

    # 3:20 PM 5/11/2022 move psd1_tmp|psm1_tmp testing to func: 
    # whatif = $($whatif) 
    $pltTMTmp=[ordered]@{ModuleNamePSM1Path = $PsmNameTmp ; verbose = $($verbose) ;} ; 
    $smsg = "Test-ModuleTMPFiles w`n$(($pltTMTmp|out-string).trim())" ; 
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

    if(-not $whatif){
        $bRet = Test-ModuleTMPFiles @pltTMTmp ; 
        if ($bRet.valid -AND $bRet.Manifest -AND $bRet.Module){
            $PassStatus += ";Test-ModuleTMPFiles:UPDATE";
            $pltCpyPsm1 = @{ Path=$PsmNameTmp ; Destination=$PsmName ; whatif=$whatif; ErrorAction="STOP" ; } ;
            $smsg = "Processing error free: Overwriting temp .psm1 with temp copy`ncopy-item w`n$(($pltCpyPsm1|out-string).trim())" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            $pltCpyPsd1 = @{ Path=$PsdNameTmp ; Destination=$PsdName ; whatif=$whatif; ErrorAction="STOP" ; } ;
            $error.clear() ;
            TRY {
                copy-Item  @pltCpyPsm1 ;
                $PassStatus += ";copy-Item:UPDATE";
                $smsg = "Processing error free: Overwriting temp .psd1 with temp copy`ncopy-item w`n$(($pltCpyPsd1|out-string).trim())" ;

                if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                copy-Item @pltCpyPsd1 ;
                $PassStatus += ";copy-Item:UPDATE";

            } CATCH {
                Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                $PassStatus += ";copy-Item:ERROR";
                Break  ;
            } ;
        } else {
            $smsg = "Test-ModuleTMPFiles:FAIL! Aborting!" ;
            $PassStatus += ";Test-ModuleTMPFiles :ERROR";
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            Break ;
        } ;
    } else {
        $smsg = "(whatif:skipping updates)" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info} #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    };

    #if($PassStatus.tolower().contains('error')){ # not properly matching, switch to select-string regex, the appends are line per append, multiline seems to break contains.
    if($PassStatus.tolower() | select-string '.*error.*'){
        $smsg = "ERRORS LOGGED, ABORTING UPDATE OF ORIGINAL .PSM1!:`n$($pltCpy.Destination)" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug
        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    } elseif(!$whatif) {
        

    } else {
        $smsg = "(whatif:skipping updates)" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info} #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    };
    $ReportObj=[ordered]@{
        Status=$true ;
        PsmNameBU = $PsmNameBU ;
        PsdNameBU = $PsdNameBU ;
        PassStatus = $PassStatus ;
    } ;
    if($PassStatus.tolower() | select-string '.*error.*'){
        $ReportObj.Status=$false ;
    } ;
    $ReportObj | write-output ;
    
    $smsg = $sBnr.replace('=v','=^').replace('v=','^=') ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
}

#*------^ ConvertTo-ModuleMergedTDO.ps1 ^------


#*------v convertTo-UnwrappedPS.ps1 v------
Function convertTo-UnwrappedPS {
    <#
    .SYNOPSIS
    convertTo-UnwrappedPS - Unwrap a a Powershell ScriptBlock at _preexisting_ semi-colon (;) delimiters (does not add semicolons or otherwise attempt to parse the scriptblock into definited lines; just adds CrLF's following the semicolons).
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-11-08
    FileName    : convertTo-UnwrappedPS.ps1
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-text
    Tags        : Powershell,Text
    AddedCredit : REFERENCE
    AddedWebsite:	URL
    AddedTwitter:	URL
    REVISIONS
    * 12:44 PM 6/17/2022 update CBH; move verb-text -> verb-dev
    * 9:38 AM 11/22/2021 ren unwrap-ps -> convertTo-UnwrappedPS 
    * 11:09 AM 11/8/2021 init
    .DESCRIPTION
    convertTo-UnwrappedPS - Unwrap a a Powershell ScriptBlock at _preexisting_ semi-colon (;) delimiters (does not add semicolons or otherwise attempt to parse the scriptblock into definited lines; just adds CrLF's following the semicolons).
    .PARAMETER  ScriptBlock
    Semi-colon-delimited ScriptBlock of powershell to be wrapped at 
    .EXAMPLE
    PS>  $text=convertTo-UnwrappedPS -ScriptBlock "write-host 'yea';`ngci 'c:\somefile.txt';" ;
    Unwrap the specified scriptblock at the semicolons. 
    .LINK
    https://github.com/tostka/verb-Text
    #>
    [CmdletBinding()]
    [Alias('unwrap-PS')]
    param(
        [Parameter(Position=0,Mandatory=$false,HelpMessage="ScriptBlock
    Semi-colon-delimited ScriptBlock of powershell to be unwrapped (sub-out ;`n with ;) [-ScriptBlock 'c:\path-to\script.ps1']")]
        [Alias('Code')]
        [string]$ScriptBlock
    )  ; 
    if(-not $ScriptBlock){
        $ScriptBlock= (get-clipboard) # .trim().replace("'",'').replace('"','') ;
        if($ScriptBlock){
            write-verbose "No -ScriptBlock specified, detected text on clipboard:`n$($ScriptBlock)" ;
        } else {
            write-warning "No -path specified, nothing suitable found on clipboard. EXITING!" ;
            Break ;
        } ;
    } else {
        write-verbose "ScriptBlock:$($ScriptBlock)" ;
    } ;
    # issue specific to PS, -replace isn't literal, see's $ as variable etc control char
    # to escape them, have to dbl: $password.Replace('$', $$')
    #$ScriptBlock = $ScriptBlock.Replace('$', '$$');
    # rgx replace all special chars, to make them literals, before doing any -replace (graveaccent escape ea)
    #$ScriptBlock = $scriptblock -replace '([$*\~;(%?.:@/]+)','`$1' ;
    $ScriptBlock=convertTo-EscapedPSText -ScriptBlock $ScriptBlock -Verbose:($PSBoundParameters['Verbose'] -eq $true) ; 
    # functional AHK: StringReplace clipboard, clipboard, `;, `;`r`n, All
    $splitAt = ";$([Environment]::NewLine)" ; 
    
    $replaceWith = ";" ; 
    # ";`r`n"  ; 
    $ScriptBlock = $ScriptBlock | Foreach-Object {
            $_ -replace $splitAt, $replaceWith ;
    } ; 
    # then put the $'s back (stays dbld):
    #$ScriptBlock = $ScriptBlock.Replace('$$', '$')
    # reverse escapes - have to use dbl-quotes around escaped backtick (dbld), or it doesn't become a literal
    #$ScriptBlock = $scriptblock -replace "``([$*\~;(%?.:@/]+)",'$1'; 
    $ScriptBlock=convertFrom-EscapedPSText -ScriptBlock $ScriptBlock  -Verbose:($PSBoundParameters['Verbose'] -eq $true) ;  
    $ScriptBlock | write-output ; 
}

#*------^ convertTo-UnwrappedPS.ps1 ^------


#*------v convertTo-WrappedPS.ps1 v------
Function convertTo-WrappedPS {
    <#
    .SYNOPSIS
    convertTo-WrappedPS - Wrap a a Powershell ScriptBlock at _preexisting_ semi-colon (;) delimiters (does not add semicolons or otherwise attempt to parse the scriptblock into definited lines; just adds CrLF's following the semicolons).
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-11-08
    FileName    : convertTo-WrappedPS.ps1
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-text
    Tags        : Powershell,Text
    AddedCredit : REFERENCE
    AddedWebsite:	URL
    AddedTwitter:	URL
    REVISIONS
    * 12:44 PM 6/17/2022 update CBH; move verb-text -> verb-dev
    * 9:38 AM 11/22/2021 ren wrap-ps -> convertTo-WrappedPS with wrap-ps alias ; added pipeline support
    * 11:09 AM 11/8/2021 init
    .DESCRIPTION
    convertTo-WrappedPS - Wrap a a Powershell ScriptBlock at _preexisting_ semi-colon (;) delimiters (does not add semicolons or otherwise attempt to parse the scriptblock into definited lines; just adds CrLF's following the semicolons)
    .PARAMETER  ScriptBlock
    Semi-colon-delimited ScriptBlock of powershell to be wrapped at 
    .EXAMPLE
    PS>  $text=convertTo-WrappedPS -ScriptBlock "write-host 'yea'; gci 'c:\somefile.txt';" ;
    Wrap the specified scriptblock at the semicolons. 
    .EXAMPLE
    PS>  $text= "write-host 'yea'; gci 'c:\somefile.txt';" | convertTo-WrappedPS ;
    Pipeline example
    .LINK
    https://github.com/tostka/verb-Text
    #>
    [CmdletBinding()]
    [Alias('wrap-PS')]
    PARAM(
        [Parameter(Position=0,Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="ScriptBlock
    Semi-colon-delimited ScriptBlock of powershell to be wrapped at [-ScriptBlock 'c:\path-to\script.ps1']")]
        [Alias('Code')]
        [string]$ScriptBlock
    )  ; 
    if(-not $ScriptBlock){
        $ScriptBlock= (get-clipboard) # .trim().replace("'",'').replace('"','') ;
        if($ScriptBlock){
            write-verbose "No -ScriptBlock specified, detected text on clipboard:`n$($ScriptBlock)" ;
        } else {
            write-warning "No -path specified, nothing suitable found on clipboard. EXITING!" ;
            Break ;
        } ;
    } else {
        write-verbose "ScriptBlock:$($ScriptBlock)" ;
    } ;
    # issue specific to PS, -replace isn't literal, see's $ as variable etc control char
    # to escape them, have to dbl: $password.Replace('$', $$')
    #$ScriptBlock = $ScriptBlock.Replace('$', '$$');
    # rgx replace all special chars, to make them literals, before doing any -replace (graveaccent escape ea)
    #$ScriptBlock = $scriptblock -replace '([$*\~;(%?.:@/]+)','`$1' ;
    $ScriptBlock=convertTo-EscapedPSText -ScriptBlock $ScriptBlock -Verbose:($PSBoundParameters['Verbose'] -eq $true) ; 
    # functional AHK: StringReplace clipboard, clipboard, `;, `;`r`n, All
    $splitAt = ";" ; 
    $replaceWith = ";$([Environment]::NewLine)" ; 
    # ";`r`n"  ; 
    $ScriptBlock = $ScriptBlock | Foreach-Object {
            $_ -replace $splitAt, $replaceWith ;
    } ; 
    # then put the $'s back (stays dbld):
    #$ScriptBlock = $ScriptBlock.Replace('$$', '$')
    # reverse escapes - have to use dbl-quotes around escaped backtick (dbld), or it doesn't become a literal
    #$ScriptBlock = $scriptblock -replace "``([$*\~;(%?.:@/]+)",'$1'; 
    $ScriptBlock=convertFrom-EscapedPSText -ScriptBlock $ScriptBlock  -Verbose:($PSBoundParameters['Verbose'] -eq $true) ;  
    $ScriptBlock | write-output ; 
}

#*------^ convertTo-WrappedPS.ps1 ^------


#*------v copy-ISELocalSourceToTab.ps1 v------
function copy-ISELocalSourceToTab {
    <#
    .SYNOPSIS
    copy-ISELocalSourceToTab - From a remote RDP session running ISE, copy a file (and any matching -PS-BP.XML) from specified admin client machine to remote ISE host (renaming function sources to _func.ps1) and open the copied file in the remot ISE.
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2024-05-22
    FileName    : copy-ISELocalSourceToTab
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging,backup
    REVISIONS
    * 9:20 AM 2/10/2025 tweaked to permit non-tsclient-spanning use: supports copying from local repo to a separate generic debugging copy; fixed swapped error msgs at bottom of PROC{}
    * 3:30 PM 10/25/2024 appears to work for bp, non-func as well;  inital non-BP.xml func copy working ; port from copy-ISETabFileToLocal(), to do the reverse
    * 2:15 PM 5/29/2024 add: c:\sc dev repo dest test, prompt for optional -nofunc use (avoid mistakes copying into repo with _func.ps1 source name intact)
    * 1:22 PM 5/22/2024init
    .DESCRIPTION
    copy-ISELocalSourceToTab - From a remote RDP session running ISE, copy a file (and any matching -PS-BP.XML) from specified admin client machine to remote ISE host (renaming function sources to _func.ps1) and open the copied file in the remot ISE.

    This also checks for a matching exported breakpoint file (name matches target script .ps1, with trailing name ...-ps1-BP.xml), and prompts to also COPY that file along with the .ps1. 

    .PARAMETER Path
    Path to source file (defaults to `$psise.CurrentFile.FullPath)[-Path 'D:\scripts\copy-ISELocalSourceToTab_func.ps1']
    .PARAMETER LocalSource
    Localized destination directory path[-path c:\pathto\]
    .PARAMETER Func
    Switch to append '_func' substring to the original file name, while copying (used for copying module functions from .\Public directory to ensure no local name clash for debugging[-Func]
    .PARAMETER whatIf
    Whatif switch [-whatIf]
    .EXAMPLE
    PS> copy-ISELocalSourceToTab -LocalSource C:\sc\verb-Exo\public\Connect-EXO.ps1 -func  -Verbose -whatif ;
    Copy the specified local path on the RDP session, to the default destination path, whatif, with verbose output
    .EXAMPLE
    PS> copy-ISELocalSourceToTab -LocalSource C:\usr\work\o365\scripts\New-CMWTempMailContact.ps1 -Verbose -whatif ; 
    Copy the current tab file to explicit specified -LocalDesetination, replacing any _func substring from filename, with whatif, with verbose output
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    #[Alias('')]
    PARAM(
        #[Parameter(Mandatory = $false,Position=0,HelpMessage="Path to source file (defaults to `$psise.CurrentFile.FullPath)[-Path 'D:\scripts\copy-ISELocalSourceToTab_func.ps1']")]
        [Parameter(Mandatory = $false,Position=0,HelpMessage="Path to local machine destination (defaults to d:\scripts\)[-Path 'D:\scripts\copy-ISELocalSourceToTab_func.ps1']")]
            [ValidateScript({Test-Path $_ -PathType 'Container'})]
            #[string]
            #[system.io.fileinfo]$Path=$psise.CurrentFile.FullPath,
            [system.io.fileinfo]$Path,
        [Parameter(Mandatory = $true,Position = 1,HelpMessage = 'Localized destination directory path[-path c:\pathto\]')]
            #[Alias('PsPath')]
            #[ValidateScript({Test-Path $_ -PathType 'Container'})]
            <#[ValidateScript({
                if([uri]$_ |?{ $_.IsUNC}){
                    throw "UNC Path specified: Please specify a 'localized' path!" ; 
                }elseif([uri]$_ |?{$_.AbsolutePath -AND $_.LocalPath -AND $_.IsFile -AND -not $_.IsUNC}){
                    $true ;
                }else{
                    throw "Invalid path!" ; 
                }
            })]
            #>
            [System.IO.DirectoryInfo]$LocalSource,
            #[string]$LocalSource,
        [Parameter(HelpMessage="Switch to append '_func' substring to the original file name, while copying (used for copying module functions from .\Public directory to ensure no local name clash for debugging[-Func])")]
            [switch]$Func,
        [Parameter(HelpMessage="Whatif switch [-whatIf]")]
            [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $nonRDPDefaultPath = 'c:\usr\work\ps\scripts\' ; 
        $sBnr="#*======v $($CmdletName): v======" ;
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
        $moveBP = $false ; 
        if($env:SESSIONNAME  -match 'RDP-Tcp#\d+'){
            $defaultPath = 'd:\scripts\' ; 
        } elseif(-not $Path -AND (test-path $nonRDPDefaultPath )){
            $defaultPath = $nonRDPDefaultPath ; 
            write-host -foregroundcolor yellow "(no -Path specified, defaulting to $($defaultPath))" ; 

        } else {
            write-warning "Neither -Path, nor pre-existing $($nonRDPDefaultPath):Please rerun specifying a -Path destination for new copy" ; 
        } ;
    }
    PROCESS {
        if ($psise){
            #if($env:SESSIONNAME  -match 'RDP-Tcp#\d+'){
                TRY{
                    if($path){
                        [system.io.fileinfo[]]$Destination = @($path) ;
                    } else { 
                        [system.io.fileinfo[]]$Destination = @($defaultPath)
                    } ;  
                    [array]$RDPSource=@() ; 
                    [system.io.fileinfo[]]$CopiedFiles= $null ; 
                        if(-not $Func -AND $LocalSource -match '^C:\\sc\\'){
                            $smsg = "Note: Copying from `$LocalSource prefixed with C:\sc\ (dev repo)" ; 
                            $smsg += "`nWITHOUT specifying -Func!" ; 
                            $smsg += "`nDO YOU WANT TO USE -Func (assert _func.ps1 on copy)?" ; 
                            write-warning $smsg ; 
                            $bRet=Read-Host "Enter YYY to continue. Anything else will exit"  ; 
                            if ($bRet.ToUpper() -eq "YYY") {
                                $smsg = "(specifying -Func)" ; 
                                write-host -foregroundcolor green $smsg  ;
                                $Func = $true ; 
                            } else {
                                $smsg = "(*skip* use of -Func)" ; 
                                write-host -foregroundcolor yellow $smsg  ;
                            } ; 
                        } ; 
                        if($env:SESSIONNAME  -match 'RDP-Tcp#\d+'){
                            if($LocalSource.fullname.substring(0,1) -ne 'c'){
                                $tmpPath = $LocalSource.fullname.replace(':','$') ; 
                                $tmpPath = (join-path -path "\\$($mybox[0])\" -childpath $tmpPath) ; 
                            }else{
                                $tmpPath = $LocalSource.fullname.replace(':','') ; 
                                $tmpPath = (join-path -path "\\tsclient\" -childpath $tmpPath) ; 
                            } ; 
                            $LocalSource = $tmpPath ; 
                        } else {
                            write-host "(local non-RDP session: coppying without tsclient translation)" 
                        } ; 
                        
                        write-verbose "resolved `$LocalSource:$($LocalSource)" ; 
                        if(-not (test-path -path $LocalSource)){
                            $smsg = "Missing/invalid converted `$LocalSource:"
                            $smsg += "`n$($LocalSource)" ; 
                            write-warning $smsg ; 
                            throw $smsg ; 
                            break ; 
                        } else{
                            write-verbose "Adding confirmed `$LocalSource:$($LocalSource) to `$RDPSource:" 
                            $RDPSource += $LocalSource ; 
                        } ;
                        
                        # check for matching local ps1-BP.xml file to also copy
                        if($bpp = get-childitem -path ($LocalSource.fullname.replace('.ps1','-ps1-BP.xml')) -ea 0){
                            $smsg = "Matching Breakpoint export file found:`n$(($bpp |out-string).trim())" ; 
                            $smsg += "`nDo you want to move this file with the .ps1?" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Prompt } 
                            else{ write-host -foregroundcolor YELLOW "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $bRet=Read-Host "Enter Y to continue. Anything else will exit"  ; 
                            if ($bRet.ToUpper() -eq "Y") {
                                $smsg = "(copying -BP.xml file)" ; 
                                write-host -foregroundcolor green $smsg  ;
                                $moveBP = $true ; 
                                $RDPSource += @($bpp)
                            } else {
                                $smsg = "(*skip* copying -BP.xml file)" ; 
                                write-host -foregroundcolor yellow $smsg  ;
                            } ; 
                        } ; 
                        $pltCI=[ordered]@{
                            path = $null ; 
                            destination = $null ; 
                            erroraction = 'STOP' ;
                            verbose = $true ; 
                            whatif = $($whatif) ;
                        } ;
                        foreach($src in $RDPSource){
                            $pltCI.path = $src.fullname ; 
                            if($Func){
                                #$pltCI.destination = (join-path -path $RDPSource -childpath $src.name.replace('_func','') -EA stop)
                                #$Destination
                                $pltCI.destination = (join-path -path $Destination -childpath $src.name.replace('.ps1','_func.ps1') -EA stop)
                            } else { 
                                #$pltCI.destination = (join-path -path $RDPSource -childpath $src.name  -EA stop); 
                                $pltCI.destination = (join-path -path $Destination -childpath $src.name  -EA stop); 
                            } ; 
                            $smsg = "copy-item w`n$(($pltCI|out-string).trim())" ; 
                            write-host -foregroundcolor green $smsg  ;
                            copy-item @pltCI ; 
                            $CopiedFiles += $pltCI.destination
                        } ; 
                        if(-not $whatif){
                            # then open the copied non -ps1-bp.xml files
                            foreach($cfile in ($CopiedFiles | ?{$_.fullname -notmatch '-ps1-BP.xml$'} ) ){
                                if($psise.powershelltabs.files.fullpath -contains $cfile){
                                    # preclose the existing tab
                                    If($closefile = $psISE.CurrentPowerShellTab.Files | ?{$_.fullpath -eq $cfile.fullname}){
                                        write-verbose "Closing tab file:`n$(($closefile| ft -a |out-string).trim())" ;
                                        #$result = $psISE.CurrentPowerShellTab.Files.remove($closefile) ;
                                        #$targetFileTab =  $psise.PowerShellTabs.files | ?{$_.fullpath -eq $cfile.fullname} ;
                                        $refreshIsFocused = $true ; 
                                        if(get-command export-ISEBreakPoints){
                                            write-host -foregroundcolor yellow "Tab refresh:Pre-running epbp!" ; 
                                            export-ISEBreakPoints
                                        } else { 
                                            write-warning "UNABLE:get-command export-ISEBreakPoints!" ; 
                                        } ; 
                                        $psISE.CurrentPowerShellTab.Files.Remove($closefile) ; 
                                    } ; 

                                    <#
                                    # preclose the existing tab
                                    #write-host "($cfile) is already OPEN in Current ISE tab list (skipping)" ;
                                    # have to loop locate the open file
                                    #-=-=-=-=-=-=-=-=
                                    $allISEFiles = $psise.powershelltabs.files #.fullpath ;
                                    if($cfile){
                                        $tFile = $allISEFiles | ?{$_.Fullpath -eq $cfile.fullname}
                                    } else{$tFile = $allISEFiles | select DisplayName,FullPath | out-gridview -Title "Pick Tab to focus:" -passthru};
                                    If($tFile){
                                        $Name = $tFile.DisplayName ;
                                        write-verbose "Searching for $($tFile.DisplayName)" ;
                                        #loop tabs for target displayname
                                        # Get the tab using the name
                                        # Finds the tab, but there's version bug in the SelectedPowerShellTab, doesn't like setting to the discovered $tab…
                                        if( $Name )  {
                                            $found = 0 ;
                                            $refreshIsFocused = $false ; 
                                            if($host.version.major -lt 3){
                                                for( $i = 0; $i -lt $psise.PowerShellTabs.Count; $i++){
                                                    write-verbose $psise.PowerShellTabs[$i].DisplayName ;
                                                    if( $psise.PowerShellTabs[$i].DisplayName -eq $Name ){
                                                        $tab = $psise.PowerShellTabs[$i] ;
                                                        $found++ ;
                                                    } ;
                                                } ;
                                                if($found -eq 0) {Throw ("Could not find a tab named " + $Name) } else {
                                                    $psISE.PowerShellTabs.SelectedPowerShellTab = $tab | select -first 1 ;
                                                } ;
                                            } else {
                                                for( $i = 0; $i -lt $psise.PowerShellTabs.files.Count; $i++){
                                                    write-verbose $psise.PowerShellTabs.files[$i].DisplayName ;
                                                    if( $psise.PowerShellTabs.files[$i].DisplayName -eq $Name ){
                                                        $tab = $psise.PowerShellTabs.files[$i] ;
                                                        # it's doubtful you really need to cycle the 'files', vs postfilter; but postfilter works fine for $psISE.CurrentPowerShellTab.Files.SetSelectedFile
                                                        # (and SelectedPowerShellTab explicitly *doesnt* work anymore under ps5 at least, as written above in the ms learn exampls)
                                                        $targetFileTab =  $psise.PowerShellTabs.files | ?{$_.displayname -eq $Name} ;
                                                        $found++ ;
                                                    } ;
                                                } ;
                                                if($found -eq 0) {
                                                    $refreshIsFocused = $false ; 
                                                    Throw ("Could not find a tab named " + $Name) 
                                                
                                                } else {
                                                    #$psISE.PowerShellTabs.files.SelectedPowerShellTab = $tab | select -first 1 ;
                                                    $psISE.CurrentPowerShellTab.Files.SetSelectedFile(($targetFileTab | select -first 1))
                                                    $refreshIsFocused = $true ; 
                                                } ;
                                            } ;
                                        } ;
                                    }
                                    #-=-=-=-=-=-=-=-=
                                    if($refreshIsFocused -AND ($targetFileTab | select -first 1)){
                                        # first run export-ISEBreakPoints 
                                        if(get-command export-ISEBreakPoints){
                                            write-host -foregroundcolor yellow "Tab refresh:Pre-running epbp!" ; 
                                            export-ISEBreakPoints
                                        } else { 
                                            write-warning "$((get-date).ToString('HH:mm:ss')):MSG" ; 
                                        } ; 
                                        $psISE.PowerShellTabs.Remove(($targetFileTab | select -first 1)) ; 
                                    } ; 
                                    #>
                                }    
                                # add the tab 
                                if(test-path $cfile.fullname){
                                    <# #New tab & open in new tab: - no we want them all in one tab
                                    write-verbose "(adding tab, opening:$($cfile))"
                                    $tab = $psISE.PowerShellTabs.Add() ;
                                    $tab.Files.Add($cfile) ;
                                    #>
                                    #open in current tab
                                    write-verbose "(opening:$($cfile))"
                                    $newtabfile = $psISE.CurrentPowerShellTab.Files.Add($cfile) ;  ;
                                    write-verbose "Reload:import-ISEBreakPoints" 
                                    if(get-command import-ISEBreakPoints){
                                        write-host -foregroundcolor yellow "Tab refresh:Pre-running epbp!" ; 
                                        write-verbose "focusing `$newTab" ; 
                                        $psISE.CurrentPowerShellTab.Files.SetSelectedFile($newtabfile) ; 
                                        import-ISEBreakPoints
                                    } else { 
                                        write-warning "UNABLE:get-command import-ISEBreakPoints!" ; 
                                    } ; 
                                } else {  write-warning "Unable to Open missing orig file:`n$($cfile)" };
                            }; # loop-E
                        } else { 
                            write-host "(-whatif: Skipping balance)" ; 
                        } ; 
                    <#} else { 
                        throw "NO POPULATED `$psise.CurrentFile.FullPath!`n(PSISE-only, with a target file tab selected)" ; 
                    } ; 
                    #>
                } CATCH {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                    write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                } ;             
            #} else {  write-warning "This script only functions within an RDP remote session (non-local)" };
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}

#*------^ copy-ISELocalSourceToTab.ps1 ^------


#*------v copy-ISETabFileToLocal.ps1 v------
function copy-ISETabFileToLocal {
    <#
    .SYNOPSIS
    copy-ISETabFileToLocal - Copy the currently open ISE tab file, to local machine (RDP remote only), prompting for local path. The filename copied is either the intact local name, or, if -stripFunc is used, the filename with any _func substring removed. 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2024-05-22
    FileName    : copy-ISETabFileToLocal
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging,backup
    REVISIONS
    * 9:20 AM 2/10/2025 tweaked to permit non-tsclient-spanning use: supports copying from a separate generic debugging copy to local repo; 
        fixed inaccurate CBH expl (was rote copy from copy-iselocalsourcetotab()); fixed swapped error msgs at bottom of PROC{}
    * 3:55 PM 10/25/2024 added cbh demo using -path ; pulled -path container validator (should always be a file) ;  fixed unupdated -nofunc else echo
    * 2:15 PM 5/29/2024 add: c:\sc dev repo dest test, prompt for optional -nofunc use (avoid mistakes copying into repo with _func.ps1 source name intact)
    * 1:22 PM 5/22/2024init
    .DESCRIPTION
    copy-ISETabFileToLocal - Copy the currently open ISE tab file, to local machine (RDP remote only), prompting for local path. The filename copied is either the intact local name, or, if -stripFunc is used, the filename with any _func substring removed. 
    This also checks for a matching exported breakpoint file (name matches target script .ps1, with trailing name ...-ps1-BP.xml), and prompts to also move that file along with the .ps1. 

    .PARAMETER Path
    Path to source file (defaults to `$psise.CurrentFile.FullPath)[-Path 'D:\scripts\copy-ISETabFileToLocal_func.ps1']
    .PARAMETER LocalDestination
    Localized destination directory path[-path c:\pathto\]
    .PARAMETER noFunc
    Switch to remove any '_func' substring from the original file name, while copying (used for copying to final module .\Public directory for publishing[-noFunc]
    .PARAMETER whatIf
    Whatif switch [-whatIf]
    .EXAMPLE
    PS> copy-ISETabFileToLocal -verbose -whatif
    Copy the current tab file to prompted local destination, whatif, with verbose output
    .EXAMPLE
    PS> copy-ISETabFileToLocal -verbose -localdest C:\sc\verb-dev\public\ -noFunc -whatif
    Copy the current tab file to explicit specified -LocalDesetination, replacing any _func substring from filename, with whatif, with verbose output
    .EXAMPLE
    PS> copy-ISETabFileToLocal -Path d:\scripts\get-LastEvent_func.ps1 -LocalDestination C:\sc\verb-logging\public\ -noFunc -whatif
    Copy specified -path source file to explicit specified -LocalDesetination, replacing any _func substring from filename, with whatif, with verbose output (used for debugging, when current tab file switch to be another file)
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('cpIseFileLocal')]
    PARAM(
        [Parameter(Mandatory = $false,Position=0,HelpMessage="Path to source file (defaults to `$psise.CurrentFile.FullPath)[-Path 'D:\scripts\copy-ISETabFileToLocal_func.ps1']")]
            [ValidateScript({Test-Path $_ })]
            [system.io.fileinfo]$Path=$psise.CurrentFile.FullPath,
        [Parameter(Mandatory = $true,Position = 1,HelpMessage = 'Localized destination directory path[-path c:\pathto\]')]
            [ValidateScript({
                if([uri]$_ |?{ $_.IsUNC}){
                    throw "UNC Path specified: Please specify a 'localized' path!" ; 
                }elseif([uri]$_ |?{$_.AbsolutePath -AND $_.LocalPath -AND $_.IsFile -AND -not $_.IsUNC}){
                    $true ;
                }else{
                    throw "Invalid path!" ; 
                }
            })]
            [string]$LocalDestination,
        [Parameter(HelpMessage="Switch to remove any '_func' substring from the original file name, while copying (used for copying to final module .\Public directory for publishing[-noFunc])")]
            [switch]$noFunc,
        [Parameter(HelpMessage="Whatif switch [-whatIf]")]
            [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue") ; 
        $nonRDPDefaultPath = 'c:\usr\work\ps\scripts\' ; 
        $sBnr="#*======v $($CmdletName): v======" ;
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
        if($env:SESSIONNAME  -match 'RDP-Tcp#\d+'){
            $defaultPath = 'd:\scripts\' ; 
        } elseif(-not $Path -AND (test-path $nonRDPDefaultPath )){
            $defaultPath = $nonRDPDefaultPath ; 
            write-host -foregroundcolor yellow "(no -Path specified, defaulting to $($defaultPath))" ; 
        } elseif($Path){


        } else {
            write-warning "Neither -Path, nor pre-existing $($nonRDPDefaultPath):Please rerun specifying a -Path destination for new copy" ; 
            break ; 
        } ;
        $moveBP = $false ; 
    }
    PROCESS {
        if ($psise){
            #if($env:SESSIONNAME  -match 'RDP-Tcp#\d+'){
                TRY{
                    if($path){
                        [system.io.fileinfo[]]$source = @($path) ; 
                        if(-not $noFunc -AND $LocalDestination -match '^C:\\sc\\'){
                            $smsg = "Note: Copying to `$LocalDestination prefixed with C:\sc\ (dev repo)" ; 
                            $smsg += "`nWITHOUT specifying -NoFunc!" ; 
                            $smsg += "`nDO YOU WANT TO USE -NOFUNC (suppress _func.ps1 on copy)?" ; 
                            write-warning $smsg ; 
                            $bRet=Read-Host "Enter YYY to continue. Anything else will exit"  ; 
                            if ($bRet.ToUpper() -eq "YYY") {
                                $smsg = "(specifying -NoFunc)" ; 
                                write-host -foregroundcolor green $smsg  ;
                                $noFunc = $true ; 
                            } else {
                                $smsg = "(*skip* use of -NoFunc)" ; 
                                write-host -foregroundcolor yellow $smsg  ;
                            } ; 
                        } ; 
                        if($env:SESSIONNAME  -match 'RDP-Tcp#\d+'){
                            if($LocalDestination.substring(0,1) -ne 'c'){
                                $Destination = $LocalDestination.replace(':','$') ; 
                                $Destination = (join-path -path "\\$($mybox[0])\" -childpath $Destination) ; 
                            }else{
                                $Destination = $LocalDestination.replace(':','') ; 
                                $Destination = (join-path -path "\\tsclient\" -childpath $Destination) ; 
                            } ; 
                        } else {
                            write-host "(local non-RDP session: coppying without tsclient translation)" 
                            $Destination = $LocalDestination ; 
                        } ; 
                        write-verbose "resolved `$Destination:$($Destination)" ; 
                        if(-not (test-path -path $Destination)){
                            $smsg = "Missing/invalid converted `$Destination:"
                            $smsg += "`n$($Destination)" ; 
                            write-warning $smsg ; 
                            throw $smsg ; 
                            break ; 
                        } ;
                        # check for matching local ps1-BP.xml file to also copy
                        if($bpp = get-childitem -path ($path.fullname.replace('.ps1','-ps1-BP.xml')) -ea 0){
                            $smsg = "Matching Breakpoint export file found:`n$(($bpp |out-string).trim())" ; 
                            $smsg += "`nDo you want to move this file with the .ps1?" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Prompt } 
                            else{ write-host -foregroundcolor YELLOW "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $bRet=Read-Host "Enter Y to continue. Anything else will exit"  ; 
                            if ($bRet.ToUpper() -eq "Y") {
                                $smsg = "(copying -BP.xml file)" ; 
                                write-host -foregroundcolor green $smsg  ;
                                $moveBP = $true ; 
                                $source += @($bpp)
                            } else {
                                $smsg = "(*skip* copying -BP.xml file)" ; 
                                write-host -foregroundcolor yellow $smsg  ;
                            } ; 
                        } ; 
                        $pltCI=[ordered]@{
                            path = $null ; 
                            destination = $null ; 
                            erroraction = 'STOP' ;
                            verbose = $true ; 
                            whatif = $($whatif) ;
                        } ;
                        foreach($src in $source){
                            $pltCI.path = $src.fullname ; 
                            if($noFunc){
                                $pltCI.destination = (join-path -path $Destination -childpath $src.name.replace('_func','') -EA stop)
                            } else { 
                                $pltCI.destination = (join-path -path $Destination -childpath $_.name  -EA stop); 
                            } ; 
                            $smsg = "copy-item w`n$(($pltCI|out-string).trim())" ; 
                            write-host -foregroundcolor green $smsg  ;
                            copy-item @pltCI ; 
                        } ; 
                    } else { 
                        throw "NO POPULATED `$psise.CurrentFile.FullPath!`n(PSISE-only, with a target file tab selected)" ; 
                    } ; 
                } CATCH {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                    write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                } ;             
            #} else { write-warning "This script only functions within an RDP remote session (non-local)" };
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing"  };
    } # PROC-E
    END{
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}

#*------^ copy-ISETabFileToLocal.ps1 ^------


#*------v export-CommentBasedHelpToFileTDO.ps1 v------
function export-CommentBasedHelpToFileTDO{
    <#
    .SYNOPSIS
    export-CommentBasedHelpToFileTDO - Exports comment-based help for a specified command to a text file.
    .NOTES
    Version     : 0.0.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2025-01-16
    FileName    : export-CommentBasedHelpToFileTDO.ps1
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Help,CommentBasedHelp,CBH,Documentation
    AddedCredit : REFERENCE
    AddedWebsite: URL
    AddedTwitter: URL
    REVISIONS
    * 2:44 PM 1/16/2025 init
    .DESCRIPTION
    export-CommentBasedHelpToFileTDO - This function retrieves the full help content for a specified command and exports it to a text file. If the help content is populated, it saves the content to a file (named [cmdlet.name].help.txt) and opens it in a text editor if available.
    .PARAMETER Command
    The name of the command for which to export the help content.
    .PARAMETER Destination
    Destination path for output xxx.help.txt file [-path c:\path-to\]"
    .PARAMETER noReview
    switch to suppress post-open in Editor[-noReview]
    .PARAMETER LengthThreshold
    Minimum Length threshold (to recognize populated CBH)(defaults 200)[-LengthThreshold 1000]
    .INPUTS
    String. The function accepts pipeline input.
    .OUTPUTS
    None. The function writes the help content to a file.
    .EXAMPLE
    PS> export-CommentBasedHelpToFileTDO -Command "Get-Process" ; 
    Demos export of the get-process command full help to a Get-Process.help.txt file (the destionation directory will be interactively prompted for)
    .EXAMPLE
    PS> $tmod = 'verb-dev' ;
    PS> if($GIT_REPOSROOT -AND ($modroot = (join-path -path $GIT_REPOSROOT -child $tmod))){
    PS>     if(-not (test-path "$modroot\Help")){ mkdir "$modroot\Help" -verbose } ;
    PS>     $hlpRoot = (Resolve-Path -Path "$modroot\Help" -ea STOP).path ;
    PS>     gcm -mod verb-dev | select -expand name | select -first 5 | export-CommentBasedHelpToFileTDO -destination $hlpRoot -NoReview -verbose ;
    PS> } ; 
    PS> 
    Demo that runs a module and exports each get-command-discovered command within the module, to a [name].help.txt file output to the Module's Help directory 
    (which is discovered as a subdir of the `$GIT_REPOSROOT autovariable). Creates the Help directory if not pre-existing. Suppresses notepad post open, via -NoReview param.
 
    (creates the directory, if not found) 
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('epCBH','export-CBH')]
    PARAM(
        [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$true,HelpMessage="CommandName [-Command 'resolve-user']")]
            [string]$Command,
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $True, HelpMessage = "Destination path for output xxx.help.txt file [-path c:\path-to\]")]
            [Alias('PsPath')]
            [ValidateScript({Test-Path $_ -PathType 'Container'})]
            [System.IO.DirectoryInfo[]]$Destination,
        [Parameter(HelpMessage="switch to suppress post-open in Editor[-noReview]")]
            [switch]$noReview,            
        [Parameter(HelpMessage="Minimum Length threshold (to recognize populated CBH)(defaults 200)[-LengthThreshold 1000]")]
            [int]$LengthThreshold=200
    );
    BEGIN {
        [string[]]$Aggrfails = @() ; 
        $Prcd = 0 ;
    }
    PROCESS{
        foreach($item in $command){
            TRY{
                $Prcd++ ; 
                $sBnrS="`n#*------v PROCESSING #$($Prcd) :$($item) v------" ; 
                write-host -foregroundcolor green $sBnrS ;
                write-verbose "get-command ($item)" ; 
                $gcmd = get-command $item -ErrorAction STOP ;
                $ofhelp = (join-path -path $Destination -childpath "$($gcmd.name).help.txt" -ErrorAction STOP) ;
                write-verbose "resolved output file:$($ofhelp)" ; 
                write-verbose "get-help ($gcmd.name) -full" ; 
                $hlp = get-help $gcmd.name -full -ErrorAction STOP ; 
                $hlpChars = (($hlp | out-string).ToCharArray() |  measure).count ; 
                write-verbose "`$hlpChars: $($hlpChars)" ; 
                #if($hlp.length -gt $LengthThreshold){
                #if( (($hlp | out-string).ToCharArray() |  measure).count -gt $LengthThreshold){
                if($hlpChars -gt $LengthThreshold){
                    write-host "Out-File -FilePath $($ofhelp)" ; 
                    $hlp| Out-File -FilePath $ofhelp -verbose ; 
                } else { 
                    $smsg =  "get-help $($gcmd.name) -full returned an tiny output`n$(($hlp|out-string).trim())" ; 
                    write-warning $smsg ;
                    $failsumm = 
                    $Aggrfails += [pscustomobject]@{
                        name = $item ; 
                        chars = $hlpChars ; 
                    } ; 
                    throw $smsg ; 
                } ; 
                if( -not $noReview){
                    write-host "(Opening output in editor)" ; 
                    if(get-command notepad2.exe){notepad2 $ofhelp ; }
                    elseif(get-command notepad.exe){notepad $ofhelp ; }
                    elseif(get-command vim){vim $ofhelp ; }
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                write-warning $smsg ;
                Continue ; 
            } ; 
            write-host -foregroundcolor green $sBnrS.replace('-v','-^').replace('v-','^-') ;
        } ; 
    } ; 
    END{
        if(($Aggrfails|  measure).count){
            write-warning "RETURNING (NAME,#CHARS) of tested sources that failed to execute get-help -full > [output].help.txt" ; 
            $Aggrfails | write-output ; 
        } ; 
    }
}

#*------^ export-CommentBasedHelpToFileTDO.ps1 ^------


#*------v export-FunctionsToFilesTDO.ps1 v------
function export-FunctionsToFilesTDO {
    <#
    .SYNOPSIS
    export-FunctionsToFilesTDO - Parse out all functions from the specified -Path (via AST Parser), and output each to _func.ps1 files in specified destination dir
    .NOTES
    Version     : 0.0.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2025-10-07
    FileName    : export-FunctionsToFilesTDO.ps1
    License     : MIT License
    Copyright   : (c) 2025 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,function,export
    AddedCredit : REFERENCE
    AddedWebsite: URL
    AddedTwitter: URL
    REVISIONS   :
    * 12:26 PM 10/7/2025 add autocreate missing dest dir; cbh demo diffing exports against the repo tree for commit updates back;  port from get-FunctionBlocks(), works, add to vdev
    * 2:53 PM 5/18/2022 $parsefile -> $path, strong typed
    # 5:55 PM 3/15/2020 fix corrupt ABC typo
    # 10:21 AM 9/27/2019 just pull the functions in a file and pipeline them, nothing more.
    .DESCRIPTION
    export-FunctionsToFilesTDO - Parse out all functions from the specified -Path (via AST Parser), and output each to _func.ps1 files in specified destination dir

    Automatically skips 'internal functions', those by convention tagged with an underscore as the first letter of the function name, unless 
    -IncludeInternalFunctions is specified (which would cause the internal function to export both within it's parent function, and as a separate freestanding function file).
    .PARAMETER  Path
    Script/Module file(s) to be parsed [path-to\script.ps1]
    .PARAMETER  Destination
    Directory into which new [functionname]_func.ps1 files should be written[-Destination path-to\]
    .PARAMETER  NoFunc
    Switch to output exported functions without standard _func.ps1 suffix.[-NoFunc]
    .PARAMETER Include
    String Array of function names to be included in export - the only functions found, that will be exported - from specified Path file.[-Include @('func1','func2')]
    .PARAMETER Exclude
    String Array of function names to be excluded from export, in specified Path file (defaults to '2b4','2b4c','fb4').[-Exclude @('2b4','2b4c','fb4')]
    .PARAMETER IncludeInternalFunctions
    Switch to override default behavior - skip internal functions (as indicated by underscore prefix in function naame) - and instead export internal functions BOTH as part of their parent function, and as a separate function file[-IncludeInternalFunctions)]
    .PARAMETER whatIf
    Whatif Flag  [-whatIf]
    .INPUTS
    system.io.fileinfo[] Accepts piped input for Path variable Array
    .OUTPUTS
    System.String outputs count summary to pipeline
    .EXAMPLE
    PS> $results = export-FunctionsToFilesTDO -Path C:\sc\powershell\PSScripts\build\xopBuildLibrary.psm1 -Destination "C:\sc\powershell\PSScripts\build\epFuncs" -verbose  ;
    Parse and export all items in the specified file, to the destination directory
    .EXAMPLE
    PS> $results = export-FunctionsToFilesTDO -Path C:\sc\powershell\PSScripts\build\xopBuildLibrary.psm1 -Destination "C:\sc\powershell\PSScripts\build\epFuncs2" -verbose -NoFunc ;
    Demo exports with -Nofunc to suppress _func.ps1 suffix on exported filemames.
    .EXAMPLE
    PS> gci C:\sc\powershell\PSScripts\build\modslist20251007-1147AM.txt | sls '^\w+' | %{
    PS>     $hit = $_ ;
    PS>     $tfunc = $hit.line.trim() ;
    PS>     write-host $tfunc ;
    PS>     if($found = gci "c:\sc\$($tfunc).ps1" -recur){
    PS>         $epspec = (join-path (split-path $hit.Path) "epFuncs\$($tfunc)_func.ps1")
    PS>         if($epfile = gci $epspec){
    PS>             @($found.fullname,$epfile.fullname) | gci | ft -a fullname,length,LastWriteTime ;
    PS>             (windiff $found.fullname $epfile.fullname) ;
    PS>             Read-Host "Press any key to continue . . ." | Out-Null ;
    PS>         }else{write-host -foregroundcolor gray "(no match epspec:$($epspec))" } ; ;
    PS>     }else{write-host -foregroundcolor gray "(no match $($tfunc))" } ;
    PS> } ; 
    Demo reviewing diffs between exported .ps1 files, and repo-tree c:\sc\* content, for commiting back as updates to the repo: 
    Works from a text file with the updated function names (which are sls rgx matched as unindented lines in the file),
    each of which are searched as filenames within the repositories root; 
    on any match, the matching file is windif'd against the exported file for the function, and the loop is paused. 
    This permits reviewing updates against the repo, and where material, the updated .ps1 can be copied back to the repo tree, for commit.
    The appropriate copy-item -path & -dest values are part of the echo (as fullname properties).
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('export-FunctionsToFiles')]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Script/Module file(s) to be parsed [path-to\script.ps1]")]
            [ValidateNotNullOrEmpty()]
            [Alias('ParseFile')]
            [system.io.fileinfo[]]$Path,
        [Parameter(Position = 1, Mandatory = $True, HelpMessage = "Directory into which new [functionname]_func.ps1 files should be written[-Destination path-to\]")]
            [ValidateNotNullOrEmpty()]
            [System.IO.DirectoryInfo]$Destination,
        [Parameter(HelpMessage = "Switch to output exported functions without standard _func.ps1 suffix.[-NoFunc]")]
            [switch]$NoFunc,
        [Parameter(HelpMessage = "String Array of function names to be included in export - the only functions found, that will be exported - from specified Path file.[-Include @('func1','func2')]")]
            [string[]]$Include,
        [Parameter(HelpMessage = "String Array of function names to be excluded from export, in specified Path file (defaults to '2b4','2b4c','fb4').[-Exclude @('2b4','2b4c','fb4')]")]
            [string[]]$Exclude = @('2b4','2b4c','fb4'),
        [Parameter(HelpMessage = "Switch to override default behavior - skip internal functions (as indicated by underscore prefix in function naame) - and instead export internal functions BOTH as part of their parent function, and as a separate function file[-IncludeInternalFunctions)]")]
            [string[]]$IncludeInternalFunctions,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
            [switch] $whatIf
    )  ;
    BEGIN{
        if(-not (test-path $Destination)){mkdir $Destination -verbose} ; 
        $sw = [Diagnostics.Stopwatch]::StartNew();
        $prcd = 0 ; 
    } # BEG-E
    PROCESS{
        foreach($item in $Path){
            $smsg = "(running AST parse on $($item.fullname)...)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
            $AST = [System.Management.Automation.Language.Parser]::ParseFile($item.fullname, [ref]$null, [ref]$Null ) ;
            $smsg = "(parsing Functions from AST...)" ; 
            if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            $funcsInFile = $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
            # this variant pulls commands v functions
            #$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)
            <# available properties/methods of parsed return
                $funcs[5] | gm
                   TypeName: System.Management.Automation.Language.FunctionDefinitionAst
                Name           MemberType Definition
                ----           ---------- ----------
                Copy           Method     System.Management.Automation.Language.Ast Copy()
                Equals         Method     bool Equals(System.Object obj)
                Find           Method     System.Management.Automation.Language.Ast Find(System.Func[System.Management.Automation.Language.Ast,bool] ...
                FindAll        Method     System.Collections.Generic.IEnumerable[System.Management.Automation.Language.Ast] FindAll(System.Func[Syste...
                GetHashCode    Method     int GetHashCode()
                GetHelpContent Method     System.Management.Automation.Language.CommentHelpInfo GetHelpContent(System.Collections.Generic.Dictionary[...
                GetType        Method     type GetType()
                SafeGetValue   Method     System.Object SafeGetValue()
                ToString       Method     string ToString()
                Visit          Method     System.Object Visit(System.Management.Automation.Language.ICustomAstVisitor astVisitor), void Visit(System....
                Body           Property   System.Management.Automation.Language.ScriptBlockAst Body {get;}
                Extent         Property   System.Management.Automation.Language.IScriptExtent Extent {get;}
                IsFilter       Property   bool IsFilter {get;}
                IsWorkflow     Property   bool IsWorkflow {get;}
                Name           Property   string Name {get;}
                Parameters     Property   System.Collections.ObjectModel.ReadOnlyCollection[System.Management.Automation.Language.ParameterAst] Param...
                Parent         Property   System.Management.Automation.Language.Ast Parent {get;}
            #>
            $ttl = $funcsInFile |  measure | select -expand count ;             
            foreach ($func in $funcsInFile) {
                $prcd++ ; 
                #$func | write-output ;
                $smsg = $sBnrS="`n#*------v PROCESSING ($($prcd)/$($ttl)): $($func.name) : v------" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level H2 } else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if(-NOT $IncludeInternalFunctions -AND ($func.name -match '^_')){
                    $smsg = "Function name - $($func.name) - prefixed by _ (underscore) -> traditionally marks an INTERNAL function" ; 
                    $smsg += "`n-IncludeInternalFunctions *not* in use -> Skipping internal function export" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    Continue ; 
                } ; 
                if($Exclude -contains $func.name){
                    $smsg = "(skipping -Exclude:$($func.name))" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    Continue ; 
                } ; 
                if(-NOT $Include -OR ($Include -AND ($Include -contains $func.name))){
                    if($Include){
                        $smsg = "(-Include:$($func.name))" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    } ; 
                
                    if($NoFunc){
                        $ofilename = join-path -path $Destination -ChildPath "$($func.name).ps1" ; 
                    }else{
                        $ofilename = join-path -path $Destination -ChildPath "$($func.name)_func.ps1" ; 
                    }; 
                    $pltSCFE=[ordered]@{PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; } 
                    #$bRet = Set-ContentFixEncoding -Value $updatedContent -Path $PsmNameTmp @pltSCFE ; 
                    # we're getting 4 writes in set-cfe, for each block added to updatedcontent, lets try |out-string before passing, to see if they fold into one write
                    $outContent = @() ; 
                    $outContent += @("# $($func.name).ps1")
                    $outContent += @("`n")
                    $outContent += @("#region $($func.name.toUpper() -replace '-', '_') ; #*------v $($func.name) v------")
                    $outContent += @($func.extent.text) ; 
                    $outContent += @("#endregion $($func.name.toUpper() -replace '-', '_') ; #*------^ END $($func.name) ^------")        
                    #$bRet = Set-ContentFixEncoding -Value ($func.extent.text| out-string) -Path $PsmNameTmp @pltSCFE ; 
                    $bRet = Set-ContentFixEncoding -Value ($outContent| out-string) -Path $ofilename @pltSCFE ; 
                    if(-not $bRet -AND -not $whatif){throw "Set-ContentFixEncoding $($ofilename)!" } else {
                        $PassStatus += ";UPDATED:Set-ContentFixEncoding ";
                    }  ;
                } else { 
                   $smsg = "(skipping -non-Include:$($func.name))" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    Continue ;  
                } ; 
                $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            } ;
        } ;  # loop-E $item
    } ;  # PROC-E
    END{
        $sw.Stop() ;
        write-verbose ("Elapsed Time: {0:dd}d {0:hh}h {0:mm}m {0:ss}s {0:fff}ms" -f $sw.Elapsed) ; 
        $smsg = "$($prcd) functions exported to $($destination)" 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
        $smsg | write-output ; 
    } ; 
}

#*------^ export-FunctionsToFilesTDO.ps1 ^------


#*------v export-ISEBreakPoints.ps1 v------
function export-ISEBreakPoints {
    <#
    .SYNOPSIS
    export-ISEBreakPoints - Export all 'Line' ise breakpoints to XML file 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2020-08-25
    FileName    : export-ISEBreakPoints
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 9:06 PM 8/12/2025 added code to create CUScripts if missing
    * 8:27 AM 3/26/2024 chg eIseBp -> epIseBp
    * 2:35 PM 5/24/2023 add: prompt for force deletion of existing .xml if no psbreakpoints defined in loaded ISE copy for script.
    * 10:20 AM 5/11/2022 added whatif support; updated CBH ; expanded echos; cleanedup
    * 8:58 AM 5/9/2022 add: test for bps before exporting
    * 12:56 PM 8/25/2020 fixed typo in 1.0.0 ; init, added to verb-dev module
    .DESCRIPTION
    export-ISEBreakPoints - Export all 'Line' ise breakpoints to XML file
    By default, attempts to save to the same directory as the script, but if the directory specified doesn't exist, it redirects the save to the c:\scripts dir.
    .PARAMETER PathDefault
    Default Path for export (when `$Script directory is unavailable)[-PathDefault c:\path-to\]
    .PARAMETER Script
    Path to target Script file (defaults to Current ISE Tab fullpath)[-Script c:\path-to\file.ext]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    export-ISEBreakPoints
    Export all 'line'-type breakpoints on the current open ISE tab, to a matching xml file
    .EXAMPLE
    export-ISEBreakPoints -Script c:\path-to\script.ps1
    Export all 'line'-type breakpoints from the specified script, to a matching xml file
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('epIseBp','epBP')]
    PARAM(
        [Parameter(HelpMessage="Default Path for export (when `$Script directory is unavailable)[-PathDefault c:\path-to\]")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$PathDefault = 'c:\scripts',
        [Parameter(HelpMessage="(debugging):Path to target Script file (defaults to Current ISE Tab fullpath)[-Script c:\path-to\file.ext]")]
        #[ValidateScript({Test-Path $_})]
        [string]$Script,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")} ;
        
    PROCESS {
        if ($psise){
            if($Script){
                write-verbose "`$Script:$($Script)" ; 
                if( ($tScript = (gci $Script).FullName) -AND ($psise.powershelltabs.files.fullpath -contains $tScript)){
                    write-host "-Script specified diverting target to:`n$($Script)" ; 
                    $tScript = $Script ; 
                    $xFname=$tScript.replace(".ps1","-ps1.xml").replace(".psm1","-psm1.xml").replace(".","-BP.") ;
                } else { 
                    throw "-Script specified is not a valid path!`n$($Script)`n(or is not currently open in ISE)" ; 
                } ; 
            } elseif($psise.CurrentFile.FullPath){
                write-verbose "(processing `$psise.CurrentFile.FullPath:$($psise.CurrentFile.FullPath)...)"
                $tScript = $psise.CurrentFile.FullPath ;
                # default to same loc, variant name of script in currenttab of ise
                $xFname=$tScript.replace(".ps1","-ps1.xml").replace(".psm1","-psm1.xml").replace(".","-BP.") ;
                $AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;                 
                if(-not (test-path $AllUsrsScripts )){mkdir $AllUsrsScripts  -verbose } ; 
                if( ( (split-path $xFname) -eq $AllUsrsScripts) -OR (-not(test-path (split-path $xFname))) ){
                    # if in the AllUsers profile, or the ISE script dir is invalid
                    if($tdir = get-item "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts"){
                        write-verbose "(`$tDir:CUser has a profile Scripts dir: using it for xml output:`n$($tdir))" ;
                    } elseif($tdir = get-item $PathDefault){
                        write-verbose "(`$tDir:Using `$PathDefault:$($PathDefault))" ; 
                    } else {
                        throw "Unable to resolve a suitable destination for the current script`n$($tScript)" ; 
                        break ; 
                    } ; 
                    $smsg = "broken path, defaulting to: $($tdir.fullname)" ; 
                    $xFname = $xFname.replace( (split-path $xFname), $tdir.fullname) ;
                } ;
            } else { throw "ISE has no current file open. Open a file before using this script" } ; 
        
            write-host "Creating BP file:$($xFname)" ;
            $xBPs= get-psbreakpoint |?{ ($_.Script -eq $tScript) -AND ($_.line)} ;
            if($xBPs){
                $xBPs | Export-Clixml -Path $xFname -whatif:$($whatif);
                $smsg = "$(($xBPs|measure).count) Breakpoints exported to $xFname`n$(($xBPs|sort line|ft -a Line,Script|out-string).trim())" ;
                if($whatif){$smsg = "-whatif:$($smsg)" };
                write-host $smsg ; 
            }elseif(test-path $xfname){
                $smsg = "$($tScript): has *no* Breakpoints set," 
                $smsg += "`n`tbut PREVIOUS file EXISTS!" ; 
                $smsg += "`nDo you want to DELETE/OVERWRITE the existing file? " ; 
                write-host -foregroundcolor YELLOW "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ;
                $bRet=Read-Host "Enter YYY to continue. Anything else will exit"  ; 
                if ($bRet.ToUpper() -eq "YYY") {
                    remove-item -path $xFname -verbose -whatif:$($whatif); 
                } else { 
                    write-host "(invalid response, skipping .xml file purge)" ; 
                } ; 
            } else {
                write-warning "$($tScript): has *no* Breakpoints set!`n(an no existing .xml exists: No Action)" ; 
            }
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
}

#*------^ export-ISEBreakPoints.ps1 ^------


#*------v export-ISEBreakPointsALL.ps1 v------
function export-ISEBreakPointsALL {
    <#
    .SYNOPSIS
    export-ISEBreakPointsALL - Loop open tabs in ISE, and foreach: Export all 'Line' ise breakpoints to XML file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : export-ISEBreakPointsALL
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 8:27 AM 3/26/2024 chg eIseBpAll -> epIseBpAll
    * 1:22 PM 2/28/2024 add: 'epBpAll' alias
    * 12:23 PM 5/23/2022 added try/catch: failed out hard on Untitled.ps1's
    * 9:19 AM 5/20/2022 add: eIseBpAll alias (using these a lot lately)
    * 12:14 PM 5/11/2022 init
    .DESCRIPTION
    export-ISEBreakPointsALL - Loop open tabs in ISE, and foreach: Export all 'Line' ise breakpoints to XML file
    Quick bulk dump, when ISE ineveitbly stops properly echo'ing variable values to terminal (and need to close and re-open all open files, with BPs intact)
    By default, attempts to save to the same directory as the script, but if the directory specified doesn't exist, it redirects the save to the c:\scripts dir.
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    export-ISEBreakPointsALL -verbose -whatif
    Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('epIseBpAll','epBpAll')]
    PARAM(
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ; 
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
    }
    PROCESS {
        if ($psise){
            write-host "Exporting PSBreakPoints for ALL TABS of currently open ISE"
            $allISEScripts = $psise.powershelltabs.files.fullpath ;
            foreach($ISES in $allISEScripts){
                $sBnrS="`n#*------v PROCESSING : $($ISES) v------" ; 
                write-host -foregroundcolor white "$((get-date).ToString('HH:mm:ss')):$($sBnrS)" ;
                write-host "==exporting $($ISES):" ;
                $pltEISEBP=@{Script= $ISES ;whatif=$($whatif) ;verbose=$($verbose) ; } ;
                $smsg  = "export-ISEBreakPoints w`n$(($pltEISEBP|out-string).trim())" ;
                write-verbose $smsg ;
                try{
                    export-ISEBreakPoints @pltEISEBP ;
                } catch {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    CONTINUE ; 
                } ; 
                write-host -foregroundcolor white "$((get-date).ToString('HH:mm:ss')):$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            } ;
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}

#*------^ export-ISEBreakPointsALL.ps1 ^------


#*------v export-ISEOpenFiles.ps1 v------
function export-ISEOpenFiles {
    <#
    .SYNOPSIS
    export-ISEOpenFiles - Export a list of all currently open ISE tab files, to CU \WindowsPowershell\Scripts\ISESavedSession.psXML file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : export-ISEOpenFiles
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 9:06 PM 8/12/2025 added code to create CUScripts if missing
    * 8:31 AM 3/26/2024 chg eIseOpen -> epIseOpen
    * 3:28 PM 6/23/2022 add -Tag param to permit running interger-suffixed variants (ie. mult ise sessions open & stored from same desktop). 
    * 9:19 AM 5/20/2022 add: eIseOpen alias (using these a lot lately; w freq crashouts of ise, and need to recover all files open & BPs to quickly get back to function)
    * 12:12 PM 5/11/2022 init
    .DESCRIPTION
    export-ISEOpenFiles - Export a list of all currently open ISE tab files, to CU \WindowsPowershell\Scripts\ISESavedSession.psXML file
    Quick bulk dump, when ISE ineveitbly stops properly echo'ing variable values to terminal (and need to close and re-open all open files)
    .PARAMETER Tag
    Optional Tag to apply to as filename suffix[-tag 'label']
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    PS> export-ISEOpenFiles -verbose -whatif
    Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif
    .EXAMPLE
    PS> export-ISEOpenFiles -Tag 'mfa' -verbose -whatif
    Export with Tag 'mfa' applied to filename (e.g. "ISESavedSession-MFA.psXML")
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('epIseOpen')]
    PARAM(
        [Parameter(Position=0,HelpMessage="Optional Tag to apply to filename[-Tag MFA]")]
        [string]$Tag,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
    }
    PROCESS {
        if ($psise){
            #$AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;
            $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
            if(-not (test-path $cuscripts)){mkdir $CUScripts -verbose } ; 
            if($Tag){
                $txmlf = join-path -path $CUScripts -ChildPath "ISESavedSession-$($Tag).psXML" ;
            } else { 
                $txmlf = join-path -path $CUScripts -ChildPath 'ISESavedSession.psXML' ;
            } ; 
            $allISEScripts = $psise.powershelltabs.files.fullpath ;
            $smsg = "Exporting $(($allISEScripts|measure).count) Open Files list for ALL TABS of currently open ISE, to:`n"
            $smsg += "`n$($txmlf)" ;
            write-host -foregroundcolor green $smsg ;
            if($allISEScripts){
                $allISEScripts | Export-Clixml -Path $txmlf -whatif:$($whatif);
            } else {write-warning "ISE has no detectable tabs open" }
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}

#*------^ export-ISEOpenFiles.ps1 ^------


#*------v export-OpenNotepads.ps1 v------
function export-OpenNotepads {
    <#
    .SYNOPSIS
    export-OpenNotepads - Export a list of all currently open Notepad* variant (notepad2/3 curr) windows, to CU \WindowsPowershell\Scripts\data\NotePdSavedSession-....psXML file (uses -Tag if specified, otherwise timestamps the file)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2025-07-02
    FileName    : export-OpenNotepads.ps1
    License     : MIT License
    Copyright   : (c) 2025 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 1:53 PM 7/2/2025 converted to func;  init
    .DESCRIPTION
    export-OpenNotepads - Export a list of all currently open Notepad* variant (notepad2/3 curr) windows, to CU \WindowsPowershell\Scripts\data\NotePdSavedSession-....

    Goal is to quickest productive work state after a reboot (get all the open files back open for continued review and work)

    Exports are in psXML files (xml) to the 'CurrentUserProfile\WindowsPowershell\Scripts\data\' directory:

    - If a -Tag is specified, the exported summary is named  'NotePdSavedSession-$($Tag).psXML'

    - If NO -Tag is specified, the exported summary is named with a timestamp in form: NotePdSavedSession-yyyyMMdd-HHmmtt.psXML

    .PARAMETER Tag
    Optional Tag to apply to as filename suffix (otherwise appends a timestamp)[-tag 'label']
    .PARAMETER rgxExclTitles
    Regex filter reflecting window MainWindowTitle strings to be excluded from exports (defaults to a stock filter)[-rgxExclTitles '^((\*\s)*)(Untitled|input\.txt|tmp\.ps1|tmpL\.ps1)\s-\s']
    .PARAMETER rgxNPAppNames
    Regex filter reflecting window MainWindowTitle Notepad* variant suffix strings to be targeted for exports (defaults to a stock filter)[rgxNPAppNames '\s-\s(Notepad\s2e\sx64|Notepad3)']
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    PS> export-OpenNotepads -verbose -whatif
    Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif
    .EXAMPLE
    PS> export-OpenNotepads -Tag 'mfa' -verbose -whatif
    Export with Tag 'mfa' applied to filename (e.g. "ISESavedSession-MFA.psXML")
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('epNpOpen')]
    PARAM(
        [Parameter(Position=0,HelpMessage="Optional Tag to apply to as filename suffix (otherwise appends a timestamp)[-tag 'label']")]
            [string]$Tag,
        [Parameter(HelpMessage="Regex filter reflecting window MainWindowTitle strings to be excluded from exports (defaults to a stock filter)[-rgxExclTitles '^((\*\s)*)(Untitled|input\.txt|tmp\.ps1|tmpL\.ps1)\s-\s']")]
            [regex]$rgxExclTitles =  '^((\*\s)*)(Untitled|input\.txt|tmp\.ps1|tmpL\.ps1)\s-\s',
        [Parameter(HelpMessage="Regex filter reflecting window MainWindowTitle Notepad* variant suffix strings to be targeted for exports (defaults to a stock filter)[rgxNPAppNames '\s-\s(Notepad\s2e\sx64|Notepad3)']")]
            [regex]$rgxNPAppNames = "\s-\s(Notepad\s2e\sx64|Notepad3)",
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
            [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
        $prPS = 'Name', 'Id', 'Path', 'Description', 'MainWindowHandle', 'MainWindowTitle', 'ProcessName', 'StartTime', 'ExitCode', 'HasExited', 'ExitTime' ;
        #$rgxExclTitles =  '^((\*\s)*)(Untitled|input\.txt|tmp\.ps1|tmpL\.ps1)\s-\s';
        #$rgxNPAppNames = "\s-\s(Notepad\s2e\sx64|Notepad3)"

        [string[]]$chkpaths = @() ;
        $chkpaths += @('c:\usr\work\incid\','c:\usr\work\ps\scripts\','c:\usr\work\exch\scripts\','C:\usr\work\o365\scripts\')
        $chkpaths += @($(resolve-path c:\sc\verb-*\public))

        $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
        # CREATE new WindowsPowershell\Scripts\data folder if nonexist, use it to park data .xml & jsons etc for script processing/output (should prob shift the ise export/import code to use it)
        $npExpDir = join-path -path $CUScripts -ChildPath 'data' ;
        if(-not(test-path $npExpDir)){
            mkdir $npExpDir -verbose ;
        }

        if($Tag){
            $txmlf = join-path -path $npExpDir -ChildPath "NotePdSavedSession-$($Tag).psXML" ;
        } else {
            $txmlf = join-path -path $npExpDir -ChildPath "NotePdSavedSession-$(get-date -format 'yyyyMMdd-HHmmtt').psXML" ;
        } ;
    } # BEG-E
    PROCESS {

        $npProc = get-process notepad* | ? { $_.MainWindowTitle -notmatch $rgxExclTitles } | select $prPS ;


        $npExports = @() ;
        $prcd = 0 ;
        $ttl = $npProc |  measure | select -expand count ;
        foreach ($npp in $npProc) {
            $prcd++ ;
            write-verbose "Processing:($($prcd)/$($ttl)):$($npp.MainWindowHandle)"
            $fname = $null ;
            $fsummary = [ordered]@{
                Name             = $null ;
                Id               = $null ;
                Path             = $null ;
                Description      = $null ;
                MainWindowHandle = $null ;
                MainWindowTitle  = $null ;
                ProcessName      = $null ;
                StartTime        = $null ;
                ExitCode         = $null ;
                HasExited        = $null ;
                ExitTime         = $null ;
                FilePath         = $null ;
                Resolved         = $false ;
                NPAppPath        = $null ;
            }
            if ($fname =[regex]::match($npp.MainWindowTitle,"^((\*\s)*)[\w\-. ]+(?=(\s-\sNotepad\s2e\sx64|\s-\sNotepad3))").groups[0].value){
                $chkpaths |%{
                    $testpath = (join-path $_ $fname);
                    if($hit = gci -path $testpath -ea 0){
                        write-verbose "HIT:$($testpath)"
                        $fsummary.Name = $npp.Name ;
                        $fsummary.Id               = $npp.Id ;
                        $fsummary.Path             = $npp.Path ;
                        $fsummary.Description      = $npp.Description ;
                        $fsummary.MainWindowHandle = $npp.MainWindowHandle ;
                        $fsummary.MainWindowTitle  = $npp.MainWindowTitle ;
                        $fsummary.ProcessName      = $npp.ProcessName ;
                        $fsummary.StartTime        = $npp.StartTime ;
                        $fsummary.ExitCode         = $npp.ExitCode ;
                        $fsummary.HasExited        = $npp.HasExited ;
                        $fsummary.ExitTime         = $npp.ExitTime ;
                        $fsummary.FilePath         = $hit.fullname ;
                        $fsummary.Resolved         = $true ;
                        $fsummary.NPAppPath        = $npp.Path ;
                        #break
                        $npExports += [PSCustomObject]$fsummary
                    } else {
                        write-verbose "no hit:$($testpath)"
                    }
                } ;
                #$hit ;
            } else {
                $smsg = "Unable to resolve a usable filename from:" ;
                $smsg += "`n$(($npp | ft -a |out-string).trim())" ;
                write-warning $smsg ;
            }
        } ; # loop-E
    } #  # PROC-E
    END{
        if ($npExports ){
            $smsg = "Exporting $(($npExports|measure).count) Open Notepad* session summaries to:`n"
            $smsg += "`n$($txmlf)" ;
            write-host -foregroundcolor green $smsg ;
            $npExports | sort StartTime | Export-Clixml -Path $txmlf -whatif:$($whatif);

        }else{
            write-warning "No matched notepad* file-related matches completed. `nSkipping exports"
        };
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}

#*------^ export-OpenNotepads.ps1 ^------


#*------v find-NounAliasesTDO.ps1 v------
Function find-NounAliasesTDO {
    <#
    .SYNOPSIS
    find-NounAliasesTDO.ps1 - Polls current Aliases defined on the local system, to try to discern 'standard' but non-formally-documented 'noun' aliases for a given Powershell Noun (as Verb's have aliases have formal/recommended aliases in MS documentation, but Noun's are not covered with the same guidence). (E.g. the common Noun 'module' uses the standard alias 'mo', in get-module (gmo), import-module (ipmo), etc))
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2023-12-12
    FileName    : find-NounAliasesTDO.ps1
    License     : MIT License
    Copyright   : (c) 2023 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,verbs
    REVISION
    * 1:32 PM 12/13/2023 init
    .DESCRIPTION
    find-NounAliasesTDO.ps1 - Polls current Aliases defined on the local system, to try to discern 'standard' but non-formally-documented 'noun' aliases for a given Powershell Noun (as Verb's have aliases have formal/recommended aliases in MS documentation, but Noun's are not covered with the same guidence). (E.g. the common Noun 'module' uses the standard alias 'mo', in get-module (gmo), import-module (ipmo), etc))

    I use this for building mnemoic splatted variable names: $plt[verbAlias][NounAlias]

    While Verb Aliases are documented at...
    
        [Approved Verbs for PowerShell Commands - PowerShell | Microsoft Learn - UID - learn.microsoft.com/](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3)
    
    ...commonly-used Noun's lack the same guidence. 

    But there are discernable patterns: 
    Fore example all the '[verb]-Module' cmdlet Alias varants use:
        - the standard one or two-character verb aliases (g=get, ip = import, r=remove), 
        - and the same trailing pair of characters in each default Alias: 'mo'
    
    => which implies 'mo' is the NounAlias for 'module'

    So given the above, we can derive patterns of 'Noun Aliases' by:
    1) looping through the standard Verb list, 
    2) pulling all defined aliases with a definition using a given verb-Noun combo, 
    3) disards any alias that:
        - includes a dash (-), implies variant verb-noun names coverage, not short aliases
        - or is greater than 4 charaters, again, implies *not* a Microsoft standard alias, which observationally appear to be 3-4 characters long, by defailt.
    3) and examine/parse off the known-verb-Alias portion of the Alias, 
    4) and consider the remainder - for builtin or common-Microsoft-Modules, to be 'semi-standards'.
    5) Once the number of matched/analyzed aliases have been completed - as specified by MatchThreshold (3 default), the processing on the current verb-Noun combo is ended, and the process moves onto the next verb in the series.
   
    As this process needs to discover **all aliases**, _including_ verb-aliases MS has historically used that *aren't* compliant with the current published get-Verb list, 
    this code includes *non-compliant* historical MS verb-> alias mappings (cnsn -> Connect-PSSession, verb docs says use 'cc' with cn == Confirm), in it's analysis. 
    As even in those older cases, the non-stqandard Verb aliases may steal yield functional standard Noun Aliases, for our own guidence.
    
    > 🏷️  **Note**
    > 
    > Microsoft has *not* been consistent in the verb aliases they've used in cmdlets over time. 
    > The below includes notations of observed instances where MS has used a _different_ alias for the same verb, on different 'official' modules and cmdlets.

        a | Add
        ap | Approve
        as | Assert
        ba | Backup
        bl | Block
        bd | Build
        ch | Checkpoint
        cl | Clear
        cs | Close
        cr | Compare
        cp | Complete
        cm | Compress
        cn | Confirm
        cc,cn | Connect (cnsn -> Connect-PSSession, verb docs says cc, and cn == Confirm)
        cv | Convert
        cf | ConvertFrom
        ct | ConvertTo
        cp | Copy
        db | Debug
        dn | Deny
        dp | Deploy
        d | Disable
        dc,dn | Disconnect (dnsn -> Disconnect-PSSession, verb docs says dc)
        dm | Dismount
        ed | Edit
        e | Enable
        et | Enter
        ex | Exit
        en | Expand
        ep | Export
        f | Format
        g | Get
        gr | Grant
        gp | Group
        h | Hide 
        j | Join 
        ip | Import
        i | Invoke
        in | Initialize
        is | Install
        l | Limit
        lk | Lock 
        ms | Measure
        mg | Merge
        mt | Mount
        m | Move
        n | New
        op | Open 
        om | Optimize 
        o | Out
        pi | Ping
        pop | Pop 
        pt | Protect
        pb | Publish
        pu | Push
        rd | Read 
        re | Redo
        rc | Receive
        rg | Register
        r | Remove
        rn | Rename
        rp | Repair
        rq | Request
        rv | Resolve
        rt | Restart
        rr | Restore
        ru | Resume
        rk | Revoke
        sv | Save
        sr | Search 
        sc | Select
        sd | Send
        s | Set
        sh | Show
        sk | Skip
        sl | Split 
        sa | Start
        st | Step 
        sp | Stop
        sb | Submit
        ss,su | Suspend (sujb -> Suspend-Job, verb docs says ss)
        sy | Sync
        sw | Switch 
        t | Test
        tr | Trace
        ul | Unblock
        un | Undo 
        us | Uninstall
        uk | Unlock
        up | Unprotect
        ub | Unpublish
        ur | Unregister
        ud | Update
        u | Use
        w | Wait
        wc | Watch
        ? | Where
        wr | Write

    ## Powershell code to convert a markdown table like the above, to the input $sdata value above:
     (uses my verb-IO module's convertfrom-MarkdownTable())

    ```powershell
    $verbAliases = @"
Prefix | Verb
a | Add
ap | Approve
as | Assert
ba | Backup
bl | Block
bd | Build
ch | Checkpoint
cl | Clear
cs | Close
cr | Compare
cp | Complete
cm | Compress
cn | Confirm
cc | Connect
cv | Convert
cf | ConvertFrom
ct | ConvertTo
cp | Copy
db | Debug
dn | Deny
dp | Deploy
d | Disable
dc | Disconnect
dm | Dismount
ed | Edit
e | Enable
et | Enter
ex | Exit
en | Expand
ep | Export
f | Format
g | Get
gr | Grant
gp | Group
h | Hide
j | Join
ip | Import
i | Invoke
in | Initialize
is | Install
l | Limit
lk | Lock
ms | Measure
mg | Merge
mt | Mount
m | Move
n | New
op | Open
om | Optimize
o | Out
pi | Ping
pop | Pop
pt | Protect
pb | Publish
pu | Push
rd | Read
re | Redo
rc | Receive
rg | Register
r | Remove
rn | Rename
rp | Repair
rq | Request
rv | Resolve
rt | Restart
rr | Restore
ru | Resume
rk | Revoke
sv | Save
sr | Search
sc | Select
sd | Send
s | Set
sh | Show
sk | Skip
sl | Split
sa | Start
st | Step
sp | Stop
sb | Submit
ss | Suspend
sy | Sync
sw | Switch
t | Test
tr | Trace
ul | Unblock
un | Undo
us | Uninstall
uk | Unlock
up | Unprotect
ub | Unpublish
ur | Unregister
ud | Update
u | Use
w | Wait
wc | Watch
? | Where
wr | Write
"@ ; 
    write-verbose "split & replace ea line with a quote-wrapped [alias];[verb] combo, then join the array with commas" ;
    $sdata = "'$(($verbAliases.Split([Environment]::NewLine).replace(' | ',';') | %{ "$($_)" }) -join "','")'" ; 
    ```
    
    .PARAMETER ResultSize
    Integer maximum number of results to request from get-command (defaults to 10)[-ResultSize 100]
    .PARAMETER MatchThreshold
    Integer maximum number of matches to process, before moving on to the next verb in the series (defaults to 10)[-MatchThreshold 10]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    System.string
    .EXAMPLE
    PS> $NounAliasesFound = find-NounAliasesTDO ;
    Return the 'standard' MS alias for the 'Compare' verb (returns 'cr')
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('get-VerbAlias')]
    [OutputType([boolean])]
    PARAM (
        #[Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Verb to find the assoicated standard alias[-verb report]")]
        #[string[]] $Verb
        [Parameter(HelpMessage="Integer maximum number of results to request from get-command (defaults to 10)[-ResultSize 100]")]
            [int]$ResultSize = 20,
        [Parameter(HelpMessage="Integer maximum number of matches to process, before moving on to the next verb in the series (defaults to 10)[-MatchThreshold 10]")]
            [int]$MatchThreshold = 3
    ) ;
    BEGIN {
        $verbose = ($VerbosePreference -eq "Continue") ; 

        $verbAliases = @"
Prefix | Verb
a | Add
ap | Approve
as | Assert
ba | Backup
bl | Block
bd | Build
ch | Checkpoint
cl | Clear
cs | Close
cr | Compare
cp | Complete
cm | Compress
cn | Confirm
cn | Connect
cc | Connect
cv | Convert
cf | ConvertFrom
ct | ConvertTo
cp | Copy
db | Debug
dn | Deny
dp | Deploy
d | Disable
dc | Disconnect
dn | Disconnect 
dm | Dismount
ed | Edit
e | Enable
et | Enter
ex | Exit
en | Expand
ep | Export
f | Format
g | Get
gr | Grant
gp | Group
h | Hide
j | Join
ip | Import
i | Invoke
in | Initialize
is | Install
l | Limit
lk | Lock
ms | Measure
mg | Merge
mt | Mount
m | Move
n | New
op | Open
om | Optimize
o | Out
pi | Ping
pop | Pop
pt | Protect
pb | Publish
pu | Push
rd | Read
re | Redo
rc | Receive
rg | Register
r | Remove
rn | Rename
rp | Repair
rq | Request
rv | Resolve
rt | Restart
rr | Restore
ru | Resume
rk | Revoke
sv | Save
sr | Search
sc | Select
sd | Send
s | Set
sh | Show
sk | Skip
sl | Split
sa | Start
st | Step
sp | Stop
sb | Submit
ss | Suspend
su | Suspend
sy | Sync
sw | Switch
t | Test
tr | Trace
ul | Unblock
un | Undo
us | Uninstall
uk | Unlock
up | Unprotect
ub | Unpublish
ur | Unregister
ud | Update
u | Use
w | Wait
wc | Watch
? | Where
wr | Write
"@ | convertfrom-markdowntable ; 

        $allAliases = get-alias ; 
        write-verbose "$($allAliases | measure-object | select -expand count) total system aliases discovered" ;  
        $Aggreg = @() ;
} ;
    PROCESS {
        
        foreach($alPre in $verbAliases){
            write-host "Procesing Verb (alias): $($alPre.verb):($($alPre.Prefix))" ; 
            if($alPre.Prefix -eq 'cc'){
                write-verbose 'gotcha!' ; 
            } ; 
            #ResultSize, MatchThreshold
            $cmds = get-command -verb $alPre.verb -totalcount $ResultSize ; 
            $smsg = "get-command -verb $($alPre.verb) matched $(($cmds|measure-object).count) commands:" ; 
            $smsg += "`n$(($cmds.name|out-string).trim())" ; 
            write-verbose $smsg ; 
            $prcd = 0 ; 
            foreach($cmd in $cmds){
                if($als = $allAliases  | ?{$_.Definition -eq $cmd.name}){
                    $smsg = "`$allAliases  | `?{$_.Definition -eq '$($cmd.name)'} matched $(($als|measure-object).count) commands:" ;
                    $smsg += "`n$(($als.name|out-string).trim())" ; 
                    write-verbose $smsg ; 

                    foreach($al in $als){
                        if( $al.name.tostring().contains('-') ){
                            write-verbose "name contains dash"
                        }elseif($al.name.tostring().length -gt 4){
                            write-verbose "$($al.name).length -gt 4:$($al.name.tostring().length)"
                        }else{
                            $prcd++ ; 
                            if($prcd -gt $MatchThreshold){ 
                                write-verbose "$($prcd) matched aliases found: Halting loop on verb:$($alPre.verb)" ; 
                                break ;
                            } ; 
                            write-host "$($cmd.name):$($al.name.tostring()):noun:$($cmd.noun), derived assoc nounAlias:$($al.name.tostring().replace($alPre.Prefix,''))"
                            $hsh=@{
                                Noun = $cmd.noun ; 
                                NounAlias = $al.name.tostring().replace($alPre.Prefix,'') ; 
                            } ; 
                            $aggreg += New-Object -TypeName PsObject -Property $hsh ; 
                        } ; 
                    } ;  # loop-E
                    #if($prcd -eq 0){
                    #    write-verbose "(no matching aliases were discovered processing verb:$($alPre.verb)" ; 
                    #} ; 
                } else {
                    write-host -nonewline '.'
                }; 
            } ; 
        } ; 
        
    } ;  # PROC-E
    END {
        $aggreg | sort noun | write-output  ; 
        write-host "Post analysis:" ; 
        foreach($agg in ($AGGREG | sort noun)){
            $tnoun = $agg ; 
            $smsg = "==$($tnoun.noun):NounAlias distribution:" ; 
            $smsg += "`n$(($aggreg |?{$_.noun -eq $tnoun.noun} | group nounalias  |  ft -a count,name|out-string).trim())`n" ; 
            write-host $smsg ;   
        } ; 
    } ; # END-E
}

#*------^ find-NounAliasesTDO.ps1 ^------


#*------v get-AliasAssignsAST.ps1 v------
function get-AliasAssignsAST {
    <#
    .SYNOPSIS
    get-AliasAssignsAST - All Alias assigns ((set|new)-Alias) from the specified $Parsefile, output them directly to pipeline (capture on far end & parse/display)
    .NOTES
    Author: Todd Kadrie
    Based on Code by: Philip Giuliani (broken example), functional AST code & example by Bartek Bielawski
    Website:	http://tinstoys.blogspot.com
    Twitter:	http://twitter.com/tostka
    REVISIONS   :
    # 9:55 AM 5/18/2022 add ported variant of get-functionblocks()
    .DESCRIPTION
    get-AliasAssignsAST - All Alias assigns ((set|new)-Alias) from the specified $Parsefile, output them directly to pipeline (capture on far end & parse/display)
    .PARAMETER  Path
    Script to be parsed [path-to\script.ps1]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    None. Returns matched Function block to pipeline.
    get-AliasAssignsAST -Parse C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    Pull/display the Add-EMSRemote function from the specified .ps1, using named params
    .EXAMPLE
    $aliasAssigns = get-AliasAssignsAST C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    $aliasassigns | ?{$_ -like '*get-ScriptProfileAST*'}
    Pull ALL Alias Assignements, and post-filter return for specific Alias Definition/Value.
    .LINK
    https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
    https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/
    #>

    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Script to be parsed [path-to\script.ps1]")][ValidateNotNullOrEmpty()]
        [Alias('ParseFile')]
        [system.io.fileinfo]$Path
    )  ;
    $sw = [Diagnostics.Stopwatch]::StartNew();
    New-Variable astTokens -force ; New-Variable astErr -force ;
    write-verbose "$((get-date).ToString('HH:mm:ss')):(running AST parse...)" ; 
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$astTokens, [ref]$astErr) ;
    # use of aliased commands (% for foreach-object etc)
    #$aliases = $astTokens | where {$_.tokenflags -eq 'commandname' -AND $_.kind -eq 'identifier'} ;
    # new|set-alias use
    write-verbose "$((get-date).ToString('HH:mm:ss')):(finding all of the commands references...)" ; 
    $ASTAllCommands = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true) ; 
    write-verbose "$((get-date).ToString('HH:mm:ss')):(pulling set/new-Alias commands out...)" ; 
    $ASTAliasAssigns = ($ASTAllCommands | ?{$_.extent.text -match '(set|new)-alias'}).extent.text
    # dump the .extent.text, if you want the explicit set/new-alias commands 
    # this variant pulls commands v functions
    #$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)

    foreach ($aliasAssign in $ASTAliasAssigns) {
        $aliasAssign | write-output ;
    } ;
    $sw.Stop() ;
    write-verbose ("Elapsed Time: {0:dd}d {0:hh}h {0:mm}m {0:ss}s {0:fff}ms" -f $sw.Elapsed) ; 
}

#*------^ get-AliasAssignsAST.ps1 ^------


#*------v get-CodeProfileAST.ps1 v------
function get-CodeProfileAST {
        <#
        .SYNOPSIS
        get-CodeProfileAST - Parse and return script/module/function compoonents, Module using Language.FunctionDefinitionAst parser
        .NOTES
        Version     : 1.1.0
        Author      : Todd Kadrie
        Website     : https://www.toddomation.com
        Twitter     : @tostka / http://twitter.com/tostka
        CreatedDate : 3:56 PM 12/8/2019
        FileName    : get-CodeProfileAST.ps1
        License     : MIT License
        Copyright   : (c) 2025 Todd Kadrie
        Github      : https://github.com/tostka/verb-dev
        AddedCredit :
        AddedWebsite:
        AddedTwitter:
        REVISIONS
        * 10:57 AM 5/19/2025 add: CBH for more extensive code profiling demo (for targeting action-verb cmds in code, from specific modules); fixed some missing CBH info.
        * 4:11 PM 5/15/2025 add psv2-ordered compat
        * 10:43 AM 5/14/2025 added SSP-suppressing -whatif:/-confirm:$false to nv's
        * 12:10 PM 5/6/2025 added -ScriptBlock, and logic to process either file or scriptblock; added examples demoing resolve Microsoft.Graph module cmdlet permissions from a file, 
            and connect-MGGraph with the resolved dynamic permissions scope. 
            Added try/catch
        * 8:44 AM 5/20/2022 flip output hash -> obj; renamed $fileparam -> $path; fliped $path from string to sys.fileinfo; 
            flipped AST call to include asttokens in returns; added verbose echos - runs 3m on big .psm1's (125 funcs)
        # 12:30 PM 4/28/2022 ren get-ScriptProfileAST -> get-CodeProfileAST, aliased original name (more descriptive, as covers .ps1|.psm1), add extension validator for -File; ren'd -File -> Path, aliased: 'PSPath','File', strongly typed [string] (per BP).
        # 1:01 PM 5/27/2020 moved alias: profile-FileAST win func
        # 5:25 PM 2/29/2020 ren profile-FileASt -> get-ScriptProfileAST (aliased orig name)
        # * 7:50 AM 1/29/2020 added Cmdletbinding
        * 9:04 AM 12/30/2019 profile-FileAST: updated CBH: added .INPUTS & OUTPUTS, including hash properties returned
        * 3:56 PM 12/8/2019 INIT
        .DESCRIPTION
        get-CodeProfileAST - Parse and return script/module/function compoonents, Module using Language.FunctionDefinitionAst parser
        .PARAMETER  File
        Path to script/module file
        .PARAMETER scriptblock
        Scriptblock of code[-scriptblock `$sbcode]
        .PARAMETER Functions
        Flag to return Functions-only [-Functions]
        .PARAMETER Parameter
        Flag to return Parameter-only [-Functions]
        .PARAMETER Variables
        Flag to return Variables-only [-Variables]
        .PARAMETER Aliases
        Flag to return Aliases-only [-Aliases]
        .PARAMETER GenericCommands
        Flag to return GenericCommands-only [-GenericCommands]
        .PARAMETER All
        Flag to return All [-All]
        .PARAMETER ShowDebug
        Parameter to display Debugging messages [-ShowDebug switch]
        .PARAMETER Whatif
        Parameter to run a Test no-change pass [-Whatif switch]
        .INPUTS
        None
        .OUTPUTS
        Outputs a system.object containing:
        * Parameters : Details on all Parameters in the file
        * Functions : Details on all Functions in the file
        * VariableAssignments : Details on all Variables assigned in the file
        .EXAMPLE
        PS> $ASTProfile = get-CodeProfileAST -File c:\pathto\script.ps1 -All -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
        Profile a file, and return the raw $ASTProfile object to the piepline (default behavior)
        PS> $ASTProfile = get-CodeProfileAST -File c:\pathto\script.ps1 -All -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
        PS> $sb = [scriptblock]::Create((gc 'c:\pathto\script.ps1' -raw))  ; 
        PS> $ASTProfile = get-CodeProfileAST  = get-CodeProfileAST -scriptblock $sb -All ;     
        Profile a scriptblock (created by loading a file into a scriptblock variable )
        .EXAMPLE
        PS> $FunctionNames = (get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -Functions).functions.name ;
        Return the Functions within the specified script, and select the name properties of the functions object returned.
        .EXAMPLE
        PS> $AliasAssignments = (get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -Aliases).Aliases.extent.text;
        Return the set/new-Alias commands from the specified script, selecting the full syntax of the command
        .EXAMPLE
        PS> $WhatifLines = ((get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -GenericCommands).GenericCommands | ?{$_.extent -like '*whatif*' } | select -expand extent).text
        Return any GenericCommands from the specified script, that have whatif within the line
        .EXAMPLE
        PS> $cmdlets = @() ; 
        PS> $rgxVNfilter = "\w+-mg\w+" ; 
        PS> (((get-CodeProfileAST -File D:\scripts\new-MGDomainRegTDO.ps1  -GenericCommands).GenericCommands |?{$_.extent -match "-mg"}).extent.text).Split([Environment]::NewLine) |%{
        PS>     $thisLine = $_ ; 
        PS>     if($thisLine -match $rgxVNfilter){
        PS>         $cmdlets += $matches[0] ; 
        PS>     } ; 
        PS> } ; 
        PS> write-verbose "Normalize & unique names"; 
        PS> $cmdlets = $cmdlets | %{get-command -name $_| select -expand name } | select -unique ; ; 
        PS> $cmdlets ; 
        PS> $PermsRqd = @() ; 
        PS> $cmdlets |%{
        PS>     write-host -NoNewline '.' ; 
        PS>     $PermsRqd += Find-MgGraphCommand -command $_ -ea STOP| Select -First 1 -ExpandProperty Permissions | Select -Unique name ; 
        PS> } ; 
        PS> write-host -foregroundcolor yellow "]" ; 
        PS> $PermsRqd = $PermsRqd.name | select -unique ;
        PS> $smsg = "Connect-mgGraph -scope`n`n$(($PermsRqd|out-string).trim())" ;
        PS> $smsg += "`n`n(Perms reflects Cmdlets:$($Cmdlets -join ','))" ;
        PS> write-host $smsg ;
        PS> $ccResults = Connect-mgGraph -scope $PermsRqd -ea STOP ;    
        Demo processing a script file for [verb]-MG[noun] cmdlets (e.g. that are part of Microsoft.Graph module), 
            - normalize the names via gcm, and select uniques, 
            - Then use MG module's Find-MgGraphCommand to resolve required Permissions, 
            - Then run Connect-mgGraph dynamically scoped to the necessary permissions. 
        .EXAMPLE
        PS> $bRet = (get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -All) ;
        PS> $bRet.functions.name ;
        PS> $bret.variables.extent.text
        PS> $bret.aliases.extent.text
        Return ALL variant objects - Functions, Parameters, Variables, aliases, GenericCommands - from the specified script, and output the function names, variable names, and alias assignement commands
        .EXAMPLE
        PS> $GCmds = (get-CodeProfileAST -File .\new-MGDomainRegTDO.ps1 -GenericCommands).GenericCommands ;
        PS> $rgxverbNounNames = "\b\w+\-\w+\b" ;
        PS> # match extents with verb-noun substrings
        PS> $CmdletNames = @() ;
        PS> ($GCmds|?{$_.extent -match $rgxverbNounNames}) | %{
        PS>   $isolatedlines = $_ ;
        PS>   # isolate the actual verb-noun substrings
        PS>   $CmdletNames += $isolatedlines.extent.text | %{if($_ -match $rgxverbNounNames){ $matches[0]}}
        PS> } ; 
        PS> # unique the list
        PS> #$CmdletNames = $CmdletNames | select -unique | sort ; # isn't unbiqueing for some reason (passes dupes), use group
        PS> $CmdletNames = $CmdletNames | group | select -expand  name | sort ;
        PS> # resolve each to a source (and properly case the name), or default source to 'unresolved' if fails gcm (note function [Alias()] names in use will come back with $null source: they gcm, but there's no source to return)
        PS> $ResolvedCmds = $CmdletNames | %{    
        PS>     $thiscmd = $_ ;
        PS>     $hsCmdSummary = [ordered]@{'name'=$null;'source'=$null;'verb'=$null;'noun'=$null; CommandType=$null} ;
        PS>     if($rvGcm = gcm $thiscmd  -ea 0){
        PS>         $hsCmdSummary.name = $rvGcm.name ; $hsCmdSummary.source = $rvGcm.source ;;
        PS>         $hsCmdSummary.verb = $rvGcm.verb ; $hsCmdSummary.noun = $rvGcm.noun ; $hsCmdSummary.CommandType=$rvGcm.CommandType ;
        PS>     }else {
        PS>         # fake it from what we know
        PS>         $hsCmdSummary.name = $thiscmd  ; $hsCmdSummary.source = 'UNRESOLVED' ;
        PS>         $hsCmdSummary.verb,$hsCmdSummary.noun = $thiscmd.split('-');
        PS>         $hsCmdSummary.CommandType="UNRESOLVED" ;
        PS>     };
        PS>     [pscustomobject]$hsCmdSummary ;
        PS> } | sort source,name ;
        PS> $ResolvedCmds| ft -a ;

            name                         source                                       verb        noun                  CommandType
            ----                         ------                                       ----        ----                  -----------
            Out-Clipboard                                                                                                     Alias
            Resolve-DnsName              DnsClient                                    Resolve     DnsName                    Cmdlet
            New-MgDomain                 Microsoft.Graph.Identity.DirectoryManagement New         MgDomain                 Function
            ForEach-Object               Microsoft.PowerShell.Core                    ForEach     Object                     Cmdlet
            Write-Degug                  UNRESOLVED                                   Write       Degug                  UNRESOLVED
            ...

        PS> $ResolvedCmds | ? verb -ne 'get' | ft -a  ; 
        AST parse out all verb-noun format generic commands from a source (regex demarced on word boundaries) ; unique the returned strings, then resolve each against a source/module, w verb,noun,source & commandtype. 
        Goal is to profile code for updates around source modules, and types of verb (action/change verbs, for adding shouldproceses support, etc). 
        Trailing command outputs the non-'Get' verb items.
        .LINK
        https://github.com/tostka/verb-dev
        #>
        [CmdletBinding()]
        [Alias('get-ScriptProfileAST')]
        PARAM(
            [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Path to script[-File path-to\script.ps1]")]
                [ValidateScript( {Test-Path $_})][ValidatePattern( "\.(ps1|psm1|txt)$")]
                [Alias('PSPath','File')]
                [system.io.fileinfo]$Path,
            [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Scriptblock of code[-scriptblock `$sbcode]")]
                [Alias('code')]
                $scriptblock,
            [Parameter(HelpMessage = "Flag to return Functions-only [-Functions]")]
                [switch] $Functions,
            [Parameter(HelpMessage = "Flag to return Parameters-only [-Functions]")]
                [switch] $Parameters,
            [Parameter(HelpMessage = "Flag to return Variables-only [-Variables]")]
                [switch] $Variables,
            [Parameter(HelpMessage = "Flag to return Aliases-only [-Aliases]")]
                [switch] $Aliases,
            [Parameter(HelpMessage = "Flag to return GenericCommands-only [-GenericCommands]")]
                [switch] $GenericCommands,
            [Parameter(HelpMessage = "Flag to return All [-All]")]
                [switch] $All,
            [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
                [switch] $showDebug,
            [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
                [switch] $whatIf
        ) ;
        BEGIN {
            TRY{
                $Verbose = ($VerbosePreference -eq "Continue") ;
                if(-NOT ($path -OR $scriptblock)){
                    throw "neither -Path or -Scriptblock specified: Please specify one or the other when running" ; 
                    break ; 
                } elseif($path -AND $scriptblock){
                    throw "BOTH -Path AND -Scriptblock specified: Please specify EITHER one or the other when running" ; 
                    break ; 
                } ;  
                if ($Path -AND $Path.GetType().FullName -ne 'System.IO.FileInfo') {
                    write-verbose "(convert path to gci)" ; 
                    $Path = get-childitem -path $Path ; 
                } ;
                if ($scriptblock -AND $scriptblock.GetType().FullName -ne 'System.Management.Automation.ScriptBlock') {
                    write-verbose "(recast -scriptblock to [scriptblock])" ; 
                    $scriptblock= [scriptblock]::Create($scriptblock) ; 
                } ;
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ; 
        } ;
        PROCESS {
            $sw = [Diagnostics.Stopwatch]::StartNew();
            TRY{
                write-verbose "$((get-date).ToString('HH:mm:ss')):(running AST parse...)" ; 
                New-Variable astTokens -Force -whatif:$false -confirm:$false ; New-Variable astErr -Force -whatif:$false -confirm:$false ; 
                if($Path){            
                    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$astTokens, [ref]$astErr) ; 
                }elseif($scriptblock){
                    $AST = [System.Management.Automation.Language.Parser]::ParseInput($scriptblock, [ref]$astTokens, [ref]$astErr) ; 
                } ;     
                if($host.version.major -ge 3){$objReturn=[ordered]@{Dummy = $null ;} }
                else {$objReturn = @{Dummy = $null ;} } ;
                if ($Functions -OR $All) {
                    write-verbose "$((get-date).ToString('HH:mm:ss')):(parsing Functions from AST...)" ; 
                    $ASTFunctions = $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
                    $objReturn.add('Functions', $ASTFunctions) ;
                } ;
                if ($Parameters -OR $All) {
                    write-verbose "$((get-date).ToString('HH:mm:ss')):(parsing Parameters from AST...)" ; 
                    $ASTParameters = $ast.ParamBlock.Parameters.Name.variablepath.userpath ;
                    $objReturn.add('Parameters', $ASTParameters) ;
                } ;
                if ($Variables -OR $All) {
                    write-verbose "$((get-date).ToString('HH:mm:ss')):(parsing Variables from AST...)" ; 
                    $AstVariableAssignments = $ast.FindAll( { $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true) ;
                    $objReturn.add('Variables', $AstVariableAssignments) ;
                } ;
                if ($($Aliases -OR $GenericCommands) -OR $All) {
                    write-verbose "$((get-date).ToString('HH:mm:ss')):(parsing ASTGenericCommands from AST...)" ; 
                    $ASTGenericCommands = $ast.FindAll( { $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) ;
                    if ($Aliases -OR $All) {
                        write-verbose "$((get-date).ToString('HH:mm:ss')):(post-filtering (set|new)-Alias from AST...)" ; 
                        $ASTAliasAssigns = ($ASTGenericCommands | ? { $_.extent.text -match '(set|new)-alias' }) ;
                        $objReturn.add('Aliases', $ASTAliasAssigns) ;
                    } ;
                    if ($GenericCommands -OR $All) {
                        $objReturn.add('GenericCommands', $ASTGenericCommands) ;
                    } ;
                } ;
                #$objReturn | Write-Output ;
                New-Object PSObject -Property $objReturn | Write-Output ;
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ; 
        } ;
        END {
            $sw.Stop() ;
            $smsg = ("Elapsed Time: {0:dd}d {0:hh}h {0:mm}m {0:ss}s {0:fff}ms" -f $sw.Elapsed) ; 
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ;
    }

#*------^ get-CodeProfileAST.ps1 ^------


#*------v get-CodeRiskProfileAST.ps1 v------
Function get-CodeRiskProfileAST {
    <#
    .SYNOPSIS
    get-CodeRiskProfileAST.ps1 - Analyze a script/function/module (ps1|psm1) and prepare a report showing what commands it would run, necessary parameters, and anything that might pose a danger. Outputs/displays an ABOUT_[filebasename].help.txt file. 
    .NOTES
    Version     : 3.4.1
    Author      : Jeff Hicks
    Website     : https://www.powershellgallery.com/packages/ISEScriptingGeek/3.4.1
    Twitter     : 
    CreatedDate : 2022-04-26
    FileName    : get-CodeRiskProfileAST.ps1
    License     : 
    Copyright   : 
    Github      : 
    Tags        : Powershell,Parser,Risk
    REVISIONS
    * 12:58 PM 4/28/2022 ren'd get-ASTCodeRiskProfile.ps1 -> get-CodeRiskProfileAST.ps1 (matches other verb-dev functions in niche)
    * 3:59 PM 4/26/2022 ren'd get-ASTProfile() (JH's original func name) & get-ASTScriptProfile.ps1 -> get-ASTCodeRiskProfile ; fixed output wrap issues (added `n to a few of the here string leads, to ensure proper line wraps occured). ;  spliced over jdhitsolutions' latest rev of get-ASTCodeRiskProfile() (reverts -Reportpath param back to orig -FilePath); move it into verb-dev
    * Jun 24, 2019 jdhitsolutions from v3.4.1 of ISEScriptingGeek module
    * 8:26 AM 2/27/2020 added CBH, renamed FilePath to ReportDir, expanded param defs a little. 
    * 2019, posted vers 3.4.1
    .DESCRIPTION
    get-CodeRiskProfileAST.ps1 - Analyze a script/function/module (ps1|psm1) and prepare a report showing what commands it would run, necessary parameters, and anything that might pose a danger. Outputs/displays an ABOUT_[filebasename].help.txt file.  
    Based on Jeff Hicks' get-ASTProfile() script. 
    .PARAMETER  Path
    Enter the path of a PowerShell script
    .PARAMETER  FilePath
    Report output directory
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    PS> get-CodeRiskProfileAST -Path 'C:\sc\verb-AAD\verb-AAD\verb-AAD.psm1' -FilePath 'C:\sc\verb-AAD\'
    .LINK
    #>
    [cmdletbinding()]
    Param(
        [Parameter(Position = 0, HelpMessage = "Enter the path of a PowerShell script")]
        [ValidateScript( {Test-Path $_})][ValidatePattern( "\.(ps1|psm1|txt)$")]
        [string]$Path = $(Read-Host "Enter the filename and path to a PowerShell script"),
        [Parameter(HelpMessage = "Report output directory")]
        [ValidateScript( {Test-Path $_})][Alias("fp", "out")]
        [string]$FilePath = "$env:userprofile\Documents\WindowsPowerShell"
    )

    Write-Verbose "Starting $($myinvocation.MyCommand)"

    #region setup profiling
    #need to resolve full path and convert it
    $Path = (Resolve-Path -Path $Path).Path | Convert-Path
    Write-Verbose "Analyzing $Path"

    Write-Verbose "Parsing File for AST"
    New-Variable astTokens -force
    New-Variable astErr -force

    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$astTokens, [ref]$astErr)

    #endregion

    #region generate AST data

    #include PowerShell version information
    Write-Verbose "PSVersionTable"
    Write-Verbose ($PSversionTable | Out-String)

    if ($ast.ScriptRequirements) {
        $requirements = ($ast.ScriptRequirements | Out-String).Trim()
    }
    else {
        $requirements = "-->None detected`n"
    }

    if ($ast.ParamBlock.Parameters ) {
        write-verbose "Parameters detected"
        $foundParams = $(($ast.ParamBlock.Parameters |
                    Select-Object Name, DefaultValue, StaticType, Attributes |
                    Format-List | Out-String).Trim()
        )
    }
    else {
        $foundParams = "-->None detected. Parameters for nested commands not tested.`n"
    }


    #define the report text
    $report = @"
This is an analysis of a PowerShell script or module. Analysis will most likely NOT be 100% thorough.
"@

    Write-Verbose "Getting requirements and parameters"
    $report += @"
`nREQUIREMENTS
$requirements
PARAMETERS
$foundparams
"@

    Write-Verbose "Getting all command elements"

    $commands = @()
    $unresolved = @()

    $genericCommands = $astTokens |
        Where-Object {$_.tokenflags -eq 'commandname' -AND $_.kind -eq 'generic'}

    $aliases = $astTokens |
        Where-Object {$_.tokenflags -eq 'commandname' -AND $_.kind -eq 'identifier'}

    Write-Verbose "Parsing commands"
    foreach ($command in $genericCommands) {
        Try {
            $commands += Get-Command -Name $command.text -ErrorAction Stop
        }
        Catch {
            $unresolved += $command.Text
        }
    }

    foreach ($command in $aliases) {
        Try {
            $commands += Get-Command -Name $command.text -erroraction Stop |
                ForEach-Object {
                #get the resolved command
                Get-Command -Name $_.Definition
            }
        }
        Catch {
            $unresolved += $command.Text
        }
    }

    Write-Verbose "All commands"
    $report += @"
ALL COMMANDS
All possible PowerShell commands. This list may not be complete or even correct.
$(($Commands | Sort -Unique | Format-Table -autosize | Out-String).Trim())
"@

    Write-Verbose "Unresolved commands"
    if ($unresolved) {
        $unresolvedText = $Unresolved | Sort-Object -Unique | Format-Table -autosize | Out-String
    }
    else {
        $unresolvedText = "-->None detected`n"
    }

    $report += @"
`nUNRESOLVED
These commands may be called from nested commands or unknown modules.
$unresolvedtext
"@

    Write-Verbose "Potentially dangerous commands"
    #identify dangerous commands
    $danger = "Remove", "Stop", "Disconnect", "Suspend", "Block",
    "Disable", "Deny", "Unpublish", "Dismount", "Reset", "Resize",
    "Rename", "Redo", "Lock", "Hide", "Clear"

    $danger = $commands | Where-Object {$danger -contains $_.verb} | Sort-Object Name | Get-Unique

    if ($danger) {
        $dangercommands = $($danger | Format-Table -AutoSize | Out-String).Trim()
    }
    else {
        $dangercommands = "-->None detected`n"
    }

    #get type names, some of which may come from parameters
    Write-Verbose "Typenames"

    $typetokens = $asttokens | Where-Object {$_.tokenflags -eq 'TypeName'}
    if ($typetokens ) {
        $foundTypes = $typetokens |
            Sort-Object @{expression = {$_.text.toupper()}} -unique |
            Select-Object -ExpandProperty Text | ForEach-Object { "[$_]"} | Out-String
    }
    else {
        $foundTypes = "-->None detected`n"
    }

    $report += @"
TYPENAMES
These are identified .NET type names that might be used as accelerators.
$foundTypes
"@

    $report += @"
WARNING
These are potentially dangerous commands.
$dangercommands
"@

    #endregion

    Write-Verbose "Display results"
    #region create and display the result

    #create a help topic file using the script basename
    $basename = (Get-Item $Path).basename
    #stored in the Documents folder
    $reportFile = Join-Path -Path $FilePath -ChildPath "ABOUT_$basename.help.txt"

    Write-Verbose "Saving report to $reportFile"
    #insert the Topic line so help recognizes it
    @"
TOPIC
about $basename profile
"@ |Out-File -FilePath $reportFile -Encoding ascii

    #create the report
    @"
SHORT DESCRIPTION
Script Profile report for: $Path
"@ | Out-File -FilePath $reportFile -Encoding ascii -Append

    @"
LONG DESCRIPTION
$report
"@  | Out-File -FilePath $reportFile -Encoding ascii -Append

    #view the report with Notepad

    Notepad $reportFile

    #endregion

    Write-Verbose "Profiling complete."
}

#*------^ get-CodeRiskProfileAST.ps1 ^------


#*------v Get-CommentBlocks.ps1 v------
function Get-CommentBlocks {
    <#
    .SYNOPSIS
    Get-CommentBlocks - Parse specified Path (or inbound Textcontent) for Comment-BasedHelp, and surrounding structures.
    .NOTES
    Version     : 1.1.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 8:07 PM 11/18/2019
    FileName    :
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit :
    AddedWebsite:
    AddedTwitter:
    REVISIONS
    * 3:49 PM 4/14/2020 minor change
    * 5:19 PM 4/11/2020 added Path variable, and ParameterSet/exlus support
    * 8:36 AM 12/30/2019 Get-CommentBlocks:updated cbh and added .INPUTS/.OUTPUTS cbh entries, detailing the subcompontents of the hashtable returned
    * 8:28 PM 11/17/2019 INIT
    .DESCRIPTION
    Get-CommentBlocks - Parse specified Path (or inbound Textcontent) for Comment-BasedHelp, and surrounding structures. Returns following parsed content: metaBlock (`<#PSScriptInfo..#`>), metaOpen (Line# of start of metaBlock), metaClose (Line# of end of metaBlock), cbhBlock (Comment-Based-Help block), cbhOpen (Line# of start of CBH), cbhClose (Line# of end of CBH), interText (Block of text *between* any metaBlock metaClose line, and any CBH cbhOpen line), metaCBlockIndex ( Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the metaBlock), CbhCBlockIndex  (Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the cbhBlock)
    .PARAMETER  TextLines
    Raw source lines from the target script file (as gathered with get-content) [-TextLines TextArrayObj]
    .PARAMETER Path
    Path to a powershell ps1/psm1 file to be parsed for CBH [-Path c:\path-to\script.ps1]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Returns a hashtable containing the following parsed content/objects, from the Text specified:
    * metaBlock : `<#PSScriptInfo..#`> published script metadata block (added via New|Update-ScriptFileInfo, at top of file)
    * metaOpen : Line# of start of metaBlock
    * metaClose : Line# of end of metaBlock
    * cbhBlock : Comment-Based-Help block
    * cbhOpen : Line# of start of CBH
    * cbhClose : Line# of end of CBH
    * interText : Block of text *between* any metaBlock metaClose line, and any CBH cbhOpen line.
    * metaCBlockIndex : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the metaBlock
    * CbhCBlockIndex  : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the cbhBlock
    .EXAMPLE
    $rawSourceLines = get-content c:\path-to\script.ps*1  ;
    $oBlkComments = Get-CommentBlocks -TextLines $rawSourceLines -showdebug:$($showdebug) -whatif:$($whatif) ;
    $metaBlock = $oBlkComments.metaBlock ;
    if ($metaBlock) {
        $smsg = "Existing MetaData located and tagged" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug
    } ;
    $cbhBlock = $oBlkComments.cbhBlock ;
    $preCBHBlock = $oBlkComments.interText ;
    .LINK
    #>
    ##Requires -RunasAdministrator

    [CmdletBinding()]
    PARAM(
        [Parameter(ParameterSetName='Text',Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Raw source lines from the target script file (as gathered with get-content) [-TextLines TextArrayObj]")]
        [ValidateNotNullOrEmpty()]$TextLines,
        [Parameter(ParameterSetName='File',Position = 0, Mandatory = $True, HelpMessage = "Path to a powershell ps1/psm1 file to be parsed for CBH [-Path c:\path-to\script.ps1]")]
        [ValidateScript({Test-Path $_})]$Path,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    $Verbose = ($VerbosePreference -eq "Continue") ;

    if($Path){
        $TextLines = get-content -path $path  ;
    } ;

    $AllBlkCommentCloses = $TextLines | Select-string -Pattern '\s*#>' | Select-Object -ExpandProperty LineNumber ;
    $AllBlkCommentOpens = $TextLines | Select-string -Pattern '\s*<#' | Select-Object  -ExpandProperty LineNumber ;

    $MetaStart = $TextLines | Select-string -Pattern '\<\#PSScriptInfo' | Select-Object -First 1 -ExpandProperty LineNumber ;

    # cycle the comment-block combos till you find the CBH comment block
    $metaBlock = $null ; $metaBlock = @() ;
    $cbhBlock = $null ; $cbhBlock = @() ;

    $rgxCBHKeywords = "\.(SYNOPSIS|DESCRIPTION|PARAMETER|EXAMPLE|INPUTS|OUTPUTS|NOTES|LINK|COMPONENT|ROLE|FUNCTIONALITY|FORWARDHELPTARGETNAME|FORWARDHELPCATEGORY|REMOTEHELPRUNSPACE|EXTERNALHELP)"

    $Procd = 0 ;
    foreach ($Open in $AllBlkCommentOpens) {
        $tmpBlock = $TextLines[($Open - 1)..($AllBlkCommentCloses[$Procd] - 1)]

        if ($tmpBlock -match '\<\#PSScriptInfo') {
            $metaCBlockIndex = $Procd ;
            $metaOpen = $Open - 1 ;
            $metaClose = $AllBlkCommentCloses[$Procd] - 1
            $metaBlock = $tmpBlock ;
            if ($showDebug) {
                if ($metaOpen -AND $metaClose) {
                    $smsg = "Existing MetaData located and tagged" ;
                    #if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug
                    write-verbose -verbose:$true  "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                } ;
            } ;
        }
        elseif ($tmpBlock -match $rgxCBHKeywords) {
            $CbhCBlockIndex = $Procd ;
            $CBHOpen = $Open - 1 ;
            $CBHClose = $AllBlkCommentCloses[$Procd] - 1 ;
            $cbhBlock = $tmpBlock ;
            if ($showDebug) {
                if ($metaOpen -AND $metaClose) {
                    $smsg = "Existing CBH metaBlock located and tagged" ;
                    #if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug
                    write-verbose -verbose:$true  "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                } ;
            } ;
            break ;
        } ;
        $Procd++ ;
    };


    $InterText = $null ; $InterText = [ordered]@{ } ;
    if ($metaClose -AND $cbhOpen) {
        $InterText = $TextLines[($metaClose + 1)..($cbhOpen - 1 )] ;
    }
    else {
        write-verbose -verbose:$true  L"$((get-date).ToString('HH:mm:ss')):(doesn't appear to be an inter meta-CBH block)" ;
    } ;
    <#
    metaBlock : <#PSScriptInfo published script metadata block
    metaOpen : Line# of start of metaBlock
    metaClose : Line# of end of metaBlock
    cbhBlock : Comment-Based-Help block
    cbhOpen : Line# of start of CBH
    cbhClose : Line# of end of CBH
    interText : Block of text *between* any metaBlock metaClose, and any CBH cbhOpen.
    metaCBlockIndex : Of the collection of all block comments - `<#..#`> , the index of the one corresponding to the metaBlock
    CbhCBlockIndex  : Of the collection of all block comments - `<#..#`> , the index of the one corresponding to the cbhBlock
    #>
    $objReturn = [ordered]@{
        metaBlock       = $metaBlock  ;
        metaOpen        = $metaOpen ;
        metaClose       = $metaClose ;
        cbhBlock        = $cbhBlock ;
        cbhOpen         = $cbhOpen ;
        cbhClose        = $cbhClose ;
        interText       = $InterText ;
        metaCBlockIndex = $metaCBlockIndex ;
        CbhCBlockIndex  = $CbhCBlockIndex ;
    } ;
    $objReturn | Write-Output

}

#*------^ Get-CommentBlocks.ps1 ^------


#*------v get-FunctionBlock.ps1 v------
function get-FunctionBlock {
    <#
    .SYNOPSIS
    get-FunctionBlock - Retrieve the specified $functionname function block from the specified $Parsefile.
    .NOTES
    Author: Todd Kadrie
    Based on Code by: Philip Giuliani (broken example), functional AST code & example by Bartek Bielawski
    Website:	http://tinstoys.blogspot.com
    Twitter:	http://twitter.com/tostka
    REVISIONS   :
    * 2:51 PM 5/18/2022 updated parsefile -> path, and strong typed
    # 10:07 AM 9/27/2019 ren'd GetFuncBlock -> get-FunctionBlock & tighted up, added named param expl
    3:19 PM 8/31/2016 - initial version, functional
    .DESCRIPTION
    .PARAMETER  ParseFile
    Script to be parsed [path-to\script.ps1]
    .PARAMETER  functionName
    Function name to be found and displayed from ParseFile
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns matched Function block to pipeline.
    .EXAMPLE
    get-FunctionBlock C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 Add-EMSRemote ;
    Pull/display the Add-EMSRemote function from the specified .ps1, using positional params
    .EXAMPLE
    get-FunctionBlock -Parse C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 -Func Add-EMSRemote ;
    Pull/display the Add-EMSRemote function from the specified .ps1, using named params
    .LINK
    https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
    https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/
    #>

    Param(
        [Parameter(Position=0,MandaTory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Script to be parsed [path-to\script.ps1]")][ValidateNotNullOrEmpty()]
        [Alias('ParseFile')]
        [system.io.fileinfo]$Path
        ,[Parameter(Position=1,MandaTory=$True,HelpMessage="Function name to be found and displayed from ParseFile")]
        $functionName
    )  ;


    # 2:07 PM 8/31/2016 alt code:
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path.fullname,[ref]$null,[ref]$Null ) ;
    $funcsInFile = $AST.FindAll({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true) ;
    # this variant pulls commands v functions
    #$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)

    $matchfunc = $null ;
    foreach($func in $funcsInFile) {
        if($func.Name -eq $functionName) {
            $matchfunc = $func ;
            break ;
        } ;
    } ;
    if($matchfunc -eq $null){ return 0 } ;
    $matchfuncBody = $matchfunc.Body ;

    # dumping the last line# for the targeted funct to pipeline
    #return $matchfuncBody.Extent.EndLineNumber ;

    # 2:20 PM 8/31/2016 return the function with bracketing

    $sPre="$("=" * 50)`n#*------v Function $($matchfunc.name) from Script:$($Path.fullname) v------" ;
    $sPost="#*------^ END Function $($matchfunc.name) from Script:$($Path.fullname) ^------ ;`n$("=" * 50)" ;

    # here string seems to make it crap out, just append together
    $sOut = $null ;
    $sOut += "$($sPre)`nFunction $($matchfunc.name) " ;
    $sOut += "$($matchfunc.Body) $($sPost)" ;

    write-verbose -verbose:$true "Script:$($Path.fullname): Matched Function:$($functionName) " ;
    $sOut | write-output ;

}

#*------^ get-FunctionBlock.ps1 ^------


#*------v get-FunctionBlocks.ps1 v------
function get-FunctionBlocks {
    <#
    .SYNOPSIS
    get-FunctionBlocks - All functions from the specified $Parsefile, output them directly to pipeline (capture on far end & parse/display)
    .NOTES
    Author: Todd Kadrie
    Based on Code by: Philip Giuliani (broken example), functional AST code & example by Bartek Bielawski
    Website:	http://tinstoys.blogspot.com
    Twitter:	http://twitter.com/tostka
    REVISIONS   :
    * 9:38 AM 10/7/2025 CBH added leading tag for 1st demo
    * 2:53 PM 5/18/2022 $parsefile -> $path, strong typed
    # 5:55 PM 3/15/2020 fix corrupt ABC typo
    # 10:21 AM 9/27/2019 just pull the functions in a file and pipeline them, nothing more.
    .DESCRIPTION
    .PARAMETER  ParseFile
    Script to be parsed [path-to\script.ps1]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    None. Returns matched Function block to pipeline.
    .EXAMPLE
    get-FunctionBlocks -Parse C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    Pull/display the Add-EMSRemote function from the specified .ps1, using named params
    .EXAMPLE
    $funcs = get-FunctionBlocks C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    $funcs |?{$_.name -eq 'get-lastwake'} | format-list name,body
    Pull ALL functions, and post-filter return for specific function, and dump the name & body to console.
    .EXAMPLE
    $funcs = get-FunctionBlocks C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    ($funcs |?{$_.name -eq 'get-lastwake'}).Extent.text
    Pull ALL functions, and post-filter return for specific function, and dump the extent.text (body) to console.
    .EXAMPLE
    $funcs = get-FunctionBlocks C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    foreach($func in $funcs){
      $sPre="$("=" * 50)`n#*------v Function $($func.name) from Script:$($ParseFile) v------" ;
      $sPost="#*------^ END Function $($func.name) from Script:$($ParseFile) ^------ ;`n$("=" * 50)" ;
      $sOut = $null ;
      $sOut += "$($sPre)`nFunction $($func.name) " ;
      $sOut += "$($func.Body) $($sPost)" ;
      write-host $sOut
    } ;
    Output a formatted block of Name & Bodies (approx the get-FunctionBlock())
    .LINK
    https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
    https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/
    #>

    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Script to be parsed [path-to\script.ps1]")][ValidateNotNullOrEmpty()]
        [Alias('ParseFile')]
        [system.io.fileinfo]$Path
    )  ;
    $sw = [Diagnostics.Stopwatch]::StartNew();
    write-verbose "$((get-date).ToString('HH:mm:ss')):(running AST parse...)" ; 
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path.fullname, [ref]$null, [ref]$Null ) ;
    write-verbose "$((get-date).ToString('HH:mm:ss')):(parsing Functions from AST...)" ; 
    $funcsInFile = $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
    # this variant pulls commands v functions
    #$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)

    foreach ($func in $funcsInFile) {
        $func | write-output ;
    } ;
    $sw.Stop() ;
    write-verbose ("Elapsed Time: {0:dd}d {0:hh}h {0:mm}m {0:ss}s {0:fff}ms" -f $sw.Elapsed) ; 
}

#*------^ get-FunctionBlocks.ps1 ^------


#*------v get-HelpParsed.ps1 v------
function get-HelpParsed {
    <#
    .SYNOPSIS
    get-HelpParsed - Parse Script CBH with get-help -full, return System.Object with Helpparsed property PSCustomObject (as parsed by get-help); hasExistingCBH boolean, and NotesHash OrderedDictionary reflecting a fully parsed NOTES block into hashtable of key:value combos (as split on colon's per line)
    .NOTES
    Version     : 1.1.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 3:45 PM 11/16/2019
    FileName    :
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit :
    AddedWebsite:
    AddedTwitter:
    REVISIONS
    10:43 AM 10/2/2023 ren to std verb-noun, alias orig name parseHelp -> parse-Help; No use real verb -> get-HelpParsed;
    added incrementing names to non-unique NOTES block key names (duplicates of Author, Website, Twitter etc, become Author1, Website1, ...) 
    fliped the hash returned to [ordered] - important where you have duplicated blocks of author,website,twitter to ensure the assoicated tags are contiguous in the output, and reflect the order from the source CBH block.
    * 3:45 PM 4/14/2020 added pretest of $path extension, get-help only works with .ps1/.psm1 script files (misnamed temp files fail to parse)
    * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:11 AM 12/30/2019 get-HelpParsed(): added CBH .INPUTS & .OUTPUTS, specifying returns hash of get-help parsed output, and presence of CBH in the file
    * 10:03 PM 12/2/201919 INIT
    .DESCRIPTION
    get-HelpParsed - Parse Script CBH with get-help -full, return System.Object with Helpparsed property PSCustomObject (as parsed by get-help); hasExistingCBH boolean, and NotesHash OrderedDictionary reflecting a fully parsed NOTES block into hashtable of key:value combos (as split on colon's per line)

    Between get-HelpParsed/parse-Help and get-VersionInfo, both do largely the same thing, but this uses a more flexible get-help call syntax less likely to mis-parse CBH out of a given target. This variant has also been continuosly updated, get-VersionInfo has been static since 4/2020.
    
    The NotesHash hashtable returned is aimed parsing out and returning usable metadata from my personal system of populating the NOTES block with standardized colon-delimited metadata:
    Version     : 1.1.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 3:45 PM 11/16/2019
    FileName    :
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/verb-dev
    AddedCredit :
    AddedWebsite:
    AddedTwitter:
    (the tags above are not standard but I find them useful none the less, especitally where using this type of parsing to assemble and reuse canned settings with a given script or function).

    My trailing entry in the notes block is the REVISION tag, which reflects solely the stack of updates on the code (The line following the REVISIONS lines should be part of another CBH keyword block)
    Where a given key value in a notes block is non-unique, subsequent instances of the same key have an incrementing integer appended to render them unique, for inclusion in the hash.

    Note, if using temp files, you *can't* pull get-help on anything but script/module files, with the proper extension (.e.g if you've got temp's named .TMP, get-help won't parse them)

    .PARAMETER  Path
    Path to script
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Outputs a hashtable with following content/objects:
    * HelpParsed : Raw object output of a get-help -full [path] against the specified $Path
    * hasExistingCBH : Boolean indicating if a functional CBH was detected
    * NotesHash
    * RevisionsText
    .EXAMPLE
    $bRet = get-HelpParsed -Path $oSrc.fullname -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
    if($bRet.HelpParsed){
        $HelpParsed = $bRet.HelpParsed
    } ;
    if($bRet.hasExistingCBH){
        $hasExistingCBH = $bRet.hasExistingCBH
    } ;
    .EXAMPLE
    PS> $prpHP = @{name="alertSet";expression={$_.alertSet | out-string}},'Category','description', @{name="description";expression={$_.description | out-string}}, @{name="details";expression={$_.details | out-string}}, @{name="examples";expression={$_.examples | out-string}}, @{name="inputTypes";expression={$_.inputTypes | out-string}}, 'ModuleName','Name', @{name="parameters";expression={$_.parameters | out-string}}, @{name="returnValues";expression={$_.returnValues | out-string}}, 'Synopsis', @{name="syntax";expression={$_.syntax | out-string}} ;
    PS> $bRet | fl $prpHP ; 

    alertSet     :

                       Author: Todd Kadrie
                       Website:	http://tinstoys.blogspot.com
                       Twitter:	http://twitter.com/tostka
                       Additional Credits: [REFERENCE]
                       Website:	[URL]
                       Twitter:	[URL]
                       REVISIONS   :
                       # 1:54 PM 7/26/2023 updated 'jpg' thumbnail image seeking code to target both .jpg & .webp (YT has shifted to the latter on recent dl), driven by 
                        $rgxYTCoverExts constant;
                       fixed inaccur helpmessage/param for $inputobject; ren'd all $*jpg vari refs to $*thumb, to reflect the image files are thumbs of either .jpg or webp type, 
                       using postfilter match on extension rgx; updated CBH desc/synopsis for accuracy
                       ....
                   

    Category     : ExternalScript
    description  : 
                   move-ConvertedVidFiles.ps1 - Post youtube vid-conversion-toMp3 script that collects mp4|mkv|webm files, checks for matching mp3 files -gt 1MB, and mathing 
                   jpg|webp files, and 
                   then collects the vid & jpg|webp files and moves them to C:\vidtmp\_vids-done\ & C:\vidtmp\_jpgs-done\ respectively

    details      : 
                   NAME
                       C:\usr\work\ps\scripts\move-ConvertedVidFiles.ps1
                   
                   SYNOPSIS
                       move-ConvertedVidFiles.ps1 - Post vid-conversion-toMp3 script that collects mp4|mkv|webm files, checks for matching mp3 files -gt 1MB, and mathing 
                   jpg|webp thumbnail 
                       files, and then collects the vid & jpg|webp files and moves them to C:\vidtmp\_vids-done\ & C:\vidtmp\_jpgs-done\ respectively

    examples     : 
                   -------------------------- EXAMPLE 1 --------------------------
               
                   PS C:\>.\move-ConvertedVidFiles.ps1
               
                   Default settings running from current path

                   -------------------------- EXAMPLE 2 --------------------------
               
                   PS C:\>.\move-ConvertedVidFiles.ps1 -InputObject "C:\vidtmp\" -showdebug -whatif ;
               
                   Whatif & showdebug pass specifying a specific path to check.

    inputTypes   : 
                   Accepts piped input.

    ModuleName   : 
    Name         : C:\usr\work\ps\scripts\move-ConvertedVidFiles.ps1
    parameters   : 
                       -InputObject <Object>
                           Path to be checked for transcod to mp3 (and matching .jpg|webp)
                       
                           Required?                    false
                           Position?                    1
                           Default value                
                           Accept pipeline input?       true (ByValue, ByPropertyName)
                           Accept wildcard characters?  false
                       
                       -showDebug [<SwitchParameter>]
                           Parameter to display Debugging messages [-ShowDebug switch]
                       
                           Required?                    false
                           Position?                    named
                           Default value                False
                           Accept pipeline input?       false
                           Accept wildcard characters?  false
                       
                       -whatIf [<SwitchParameter>]
                       
                           Required?                    false
                           Position?                    named
                           Default value                False
                           Accept pipeline input?       false
                           Accept wildcard characters?  false
                       
                       <CommonParameters>
                           This cmdlet supports the common parameters: Verbose, Debug,
                           ErrorAction, ErrorVariable, WarningAction, WarningVariable,
                           OutBuffer, PipelineVariable, and OutVariable. For more information, see 
                           about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).

    returnValues : 
                   Returns an object with uptime data to the pipeline.

    Synopsis     : move-ConvertedVidFiles.ps1 - Post youtube vid-conversion-toMp3 script that collects mp4|mkv|webm files, checks for matching mp3 files -gt 1MB, and mathing 
                   jpg|webp thumbnail files, and then collects the vid & jpg|webp files and moves them to C:\vidtmp\_vids-done\ & C:\vidtmp\_jpgs-done\ respectively
    syntax       : 
                   C:\usr\work\ps\scripts\move-ConvertedVidFiles.ps1 [[-InputObject] <Object>] [-showDebug] [-whatIf] [<CommonParameters>]    

    Builds on first expl: Demos expressed properties that outline the default data returned pre-parsed by get-help. 
    .EXAMPLE
    PS> $bret.Noteshash

    Name                           Value                                                                                                                                              
    ----                           -----                                                                                                                                              
    Author                         Todd Kadrie                                                                                                                                        
    Website                        http://tinstoys.blogspot.com                                                                                                                       
    Twitter                        http://twitter.com/tostka                                                                                                                          
    Website1                       [URL]                                                                                                                                              
    Twitter1                       [URL]                                                                                                                                              
    LastRevision                   # 1:54 PM 7/26/2023 updated 'jpg' thumbnail image seeking code to target both .jpg & .webp (YT has shifted to the latter on recent dl), driven b...

    
    Also builds on first expl: Demo contents of the returned NotesHash ordered hashtable property of the return
    .EXAMPLE
    PS> $bret.RevisionsText

    # 1:54 PM 7/26/2023 updated 'jpg' thumbnail image seeking code to target both .jpg & .webp (YT has shifted to the latter on recent dl), driven by $rgxYTCoverExts constant;
    fixed inaccur helpmessage/param for $inputobject; ren'd all $*jpg vari refs to $*thumb, to reflect the image files are thumbs of either .jpg or webp type, 
    using postfilter match on extension rgx; updated CBH desc/synopsis for accuracy
    # 11:17 AM 7/21/2023 working fully; ...

    Also builds on first expl: Demo contents of the returned RevisionsText property.

    .LINK
    https://github.com/verb-dev
    #>
    # [ValidateScript({Test-Path $_})], [ValidateScript({Test-Path $_})]
    [CmdletBinding()]
    [Alias('parse-Help','parseHelp')]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to script[-Path path-to\script.ps1]")]
        [ValidateScript( { Test-Path $_ })]$Path,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    $Verbose = ($VerbosePreference -eq "Continue") ; 
    if ($Path.GetType().FullName -ne 'System.IO.FileInfo') {
        $Path = get-childitem -path $Path ;
    } ;
    # Collect existing HelpParsed
    $error.clear() ;
    if($Path.Extension -notmatch '\.PS((M)*)1'){
        $smsg = "Specified -Path is *INVALID* for processing with Get-Help`nMust specify a file with valid .PS1/.PSM1 extensions.`nEXITING" ; 
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-error -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        Exit ; 
    } ; 
    TRY {
        $HelpParsed = Get-Help -Full $Path.fullname
    }
    CATCH {
        Write-Error "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        Continue #Opts: STOP(debug)|EXIT(close)|Continue(move on in loop cycle)
    } ;

    $objReturn = [ordered]@{
        HelpParsed     = $HelpParsed  ;
        hasExistingCBH = $false ;
        NotesHash = $null ; 
        RevisionsText = $null ; 
    } ;

    <# CBH keywords to use to detect CBH blocks
        SYNOPSIS
        DESCRIPTION
        PARAMETER
        EXAMPLE
        INPUTS
        OUTPUTS
        NOTES
        LINK
        COMPONENT
        ROLE
        FUNCTIONALITY
        FORWARDHELPTARGETNAME
        FORWARDHELPCATEGORY
        REMOTEHELPRUNSPACE
        EXTERNALHELP
    #>
    $rgxCBHKeywords = "\.(SYNOPSIS|DESCRIPTION|PARAMETER|EXAMPLE|INPUTS|OUTPUTS|NOTES|LINK|COMPONENT|ROLE|FUNCTIONALITY|FORWARDHELPTARGETNAME|FORWARDHELPCATEGORY|REMOTEHELPRUNSPACE|EXTERNALHELP)"

    # 4) determine if target already has CBH:
    if ($showDebug) {
        $smsg = "`$Path.FullName:$($Path.FullName):`n$(($helpparsed | select Category,Name,Synopsis, param*,alertset,details,examples |out-string).trim())" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    } ;


    if ( ( ($HelpParsed.Category -eq 'ExternalScript') -AND ($HelpParsed.Name -eq $Path.Name) ) ) {
        <# weird, helpparsed.synopsis is 3 lines long (has word wraps), although the first looks like the $Path.name, it still doesn't match
            pull Synopsis out - it's always populated but matching it is a PITA
            -AND ($HelpParsed.Synopsis -ne $Path.FullName)
        #>
        if ( -not($HelpParsed.examples) -AND -not($HelpParsed.examples) -AND -not($HelpParsed.examples) -AND -not($HelpParsed.examples) -AND -not($HelpParsed.examples) -AND -not($HelpParsed.examples) -AND -not($HelpParsed.examples) -AND ($HelpParsed.Synopsis -ne $Path.FullName ) ) {
            #  non-cbh/non-meta script
            <# completey non-cbh/non-meta script get-help -fulls as:
                #-=-=-=-=-=-=-=-=
                Name          : get-NonUserMbxsByOU.ps1
                Category      : ExternalScript
                Synopsis      : get-NonUserMbxsByOU.ps1
                Component     :
                Role          :
                Functionality :
                ModuleName    :
                Length        : 26
                #-=-=-=-=-=-=-=-=
            #>
            $objReturn.hasExistingCBH = $false ;
        }
        else {
            # partially configured CBH, at least one of the above are populated
            $objReturn.hasExistingCBH = $true ;
        } ;

    }
    elseif ( ( ($HelpParsed.Category -eq 'ExternalScript') -AND ($HelpParsed.Name -eq $Path.FullName) ) ) {
        if ( ($HelpParsed.examples) -OR ($HelpParsed.examples) -OR ($HelpParsed.examples) -OR ($HelpParsed.examples) -OR ($HelpParsed.examples) -OR ($HelpParsed.examples) -OR ($HelpParsed.examples) -OR ($HelpParsed.Synopsis -ne $Path.FullName ) ) {
            <# weird, helpparsed.synopsis is 3 lines long (has word wraps), although the first looks like the $Path.name, it still doesn't match
            pull Synopsis out - it's always populated but matching it is a PITA
            -AND ($HelpParsed.Synopsis -ne $Path.FullName)
            #>
            <#
            # script with cbh, no meta get-help -fulls as:
                #-=-=-=-=-=-=-=-=
                examples      : @{example=System.Management.Automation.PSObject[]}
                alertSet      : @{alert=System.Management.Automation.PSObject[]}
                parameters    :
                details       : @{name=C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1; description=System.Management.Automation.PSObject[]}
                description   : {@{Text=get-NonUserMbxsByOU.ps1 - Get non-user mailboxes by OU}}
                relatedLinks  : @{navigationLink=@{linkText=}}
                syntax        : @{syntaxItem=@{name=C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1}}
                xmlns:maml    : http://schemas.microsoft.com/maml/2004/10
                xmlns:command : http://schemas.microsoft.com/maml/dev/command/2004/10
                xmlns:dev     : http://schemas.microsoft.com/maml/dev/2004/10
                Name          : C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1
                Category      : ExternalScript
                Synopsis      : get-NonUserMbxsByOU.ps1 - Get non-user mailboxes by OU
                Component     :
                Role          :
                Functionality :
                ModuleName    :
                #-=-=-=-=-=-=-=-=
        #>
            $objReturn.hasExistingCBH = $true ;
        }
        else {
            throw "Error: This script has an undefined mixture of CBH values!"
        } ;
        <# # script with cbh & meta get-help -fulls as:
            #-=-=-=-=-=-=-=-=
            examples      : @{example=System.Management.Automation.PSObject[]}
            relatedLinks  : @{navigationLink=@{linkText=}}
            details       : @{name=C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1; description=System.Management.Automation.PSObject[]}
            description   : {@{Text=get-NonUserMbxsByOU.ps1 - Get non-user mailboxes by OU}}
            parameters    :
            syntax        : @{syntaxItem=@{name=C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1}}
            xmlns:maml    : http://schemas.microsoft.com/maml/2004/10
            xmlns:command : http://schemas.microsoft.com/maml/dev/command/2004/10
            xmlns:dev     : http://schemas.microsoft.com/maml/dev/2004/10
            Name          : C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1
            Category      : ExternalScript
            Synopsis      : get-NonUserMbxsByOU.ps1 - Get non-user mailboxes by OU
                            Version     : 1.0.1
                            Author      : Todd Kadrie
                            Website     : https://www.toddomation.com
                            Twitter     : @tostka / http://twitter.com/tostka
                            CreatedDate : 2019-11-25
                            FileName    : C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1
                            License     : MIT License
                            Copyright   : (c)  2019 Todd Kadrie. All rights reserved.
                            Github      : https://github.com/tostka
                            AddedCredit : REFERENCE
                            AddedWebsite:	URL
                            AddedTwitter:	URL
                            REVISIONS
                            * 21:53 PM 11/25/2019 Added default CBH
            Component     :
            Role          :
            Functionality :
            ModuleName    :
    #>

        <# interesting point, even with NO CBH, get-help returns content (nuts)

        An non-CBH script will return at minimum:
        #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        $HelpParsed
        Move-MultMbxsToExo.ps1


        #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        $HelpParsed.Synopsis
        Move-MultMbxsToExo.ps1


        #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        which rgx escape reveals as:
        #-=-=-=-=-=-=-=-=
        [regex]::Escape($($HelpParsed.Synopsis))
        Move-MultMbxsToExo\.ps1\ \r\n
        #-=-=-=-=-=-=-=-=
        But attempts to build a regex to match the above haven't been successful
        So, we go to explicitly testing the highpoints to fail a non-CBH:
        ($HelpParsed.Category -eq 'ExternalScript') -AND ($HelpParsed.Name -eq $Path.Name) -AND (!$HelpParsed.parameters) -AND (!($HelpParsed.alertSet)) -AND (!($HelpParsed.details)) -AND (!($HelpParsed.examples))
    #>


    } elseif ($HelpParsed.Name -eq 'default') {
        # failed to properly parse CBH
        $objReturn.helpparsed = $null ; 
        $objReturn.hasExistingCBH = $false ;
        $objReturn.NotesHash = $null ; 
    } ;  

    # 12:24 PM 4/13/2020 splice in the get-VersionInfo notes processing code
    $notes = $null ; 
    if($host.version.major -lt 3){
        $notes = @{ } ;
    } else { 
        $notes = [ordered]@{ } ;
    } ; 

    $notesLines = $null ; $notesLineCount = $null ;
    $revText = $null ; $CurrLine = 0 ; 
    $rgxNoteMeta = '^((\s)*)\w{3,}((\s*)*)\:((\s*)*)*.*' ; 
    if ( ($notesLines = $HelpParsed.alertSet.alert.Text -split '\r?\n').Trim() ) {
        $notesLineCount = ($notesLines | measure).count ;
        foreach ($line in $notesLines) {
            $CurrLine++ ; 
            if (!$line) { continue } ;
            if($line -match $rgxNoteMeta ){
                $name = $null ; $value = $null ;
                if ($line -match '(?i:REVISIONS((\s*)*)((\:)*))') { 
                    # at this point, from here down should be rev data
                    $revText = $notesLines[$($CurrLine)..$($notesLineCount)] ;  
                    $notes.Add("LastRevision", $notesLines[$currLine]) ;
                    Continue ;
                    #break ; 
                    # no don't break, parse the entire stack, there's could be a range of keywords below REVISIONS
                } ;
                if ($line.Contains(':')) {
                    $nameValue = $null ;
                    $nameValue = @() ;
                    # Split line by the first colon (:) character.
                    $nameValue = ($line -split ':', 2).Trim() ;
                    $name = $nameValue[0] ;
                    if ($name) {
                        $value = $nameValue[1] ;
                        if ($value) { $value = $value.Trim() } ;
                        #if (!($notes.ContainsKey($name))) { $notes.Add($name, $value) } ;
                        # incremnent the keyname to continue adding additional same-keyed items
                        # ordered has .conains method, non ordered has containskey method
                        if($host.version.major -lt 3){
                            if (-not ($notes.ContainsKey($name))) { 
                                $notes.Add($name, $value) 
                            } else {
                                $incr = 1 ; 
                                $nameN = "$($name)$($incr)"
                                while ($notes.ContainsKey($nameN)) {
                                    $incr++ ; 
                                    write-verbose "incrementing hash key clash:$($incr)" ; 
                                } ; 
                                $notes.Add($nameN, $value) ; 
                            } ;
                        } else { 
                            if (-not ($notes.Contains($name))) { 
                                $notes.Add($name, $value) 
                            } else {
                                $incr = 1 ; 
                                $nameN = "$($name)$($incr)"
                                while ($notes.Contains($nameN)) {
                                    $incr++ ; 
                                    write-verbose "incrementing hash key clash:$($incr)" ; 
                                } ; 
                                $notes.Add($nameN, $value) ; 
                            } ;
                        } ; 
                    } ;
                } ;
            } ; 
        } ;
        $objReturn.NotesHash = $notes ;
        $objReturn.RevisionsText = $revText ; 
    } ; 

    $objReturn | Write-Output ;
}

#*------^ get-HelpParsed.ps1 ^------


#*------v get-ISEBreakPoints.ps1 v------
function get-ISEBreakPoints {
    <#
    .SYNOPSIS
    get-ISEBreakPoints - Get-PSBreakPoints for solely the current focused ISE Open Tab
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2024-07-11
    FileName    : get-ISEBreakPoints
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 2:27 PM 7/11/2024 init
    .DESCRIPTION
    get-ISEBreakPoints - Get-PSBreakPoints for solely the current focused ISE Open Tab (fltered on -script param)
    .EXAMPLE
    PS> get-isebreakpoints | ft -a ; 

        ID Script                        Line Command Variable Action
        -- ------                        ---- ------- -------- ------
        70 test-ExoDnsRecordTDO_func.ps1  237                        
        71 test-ExoDnsRecordTDO_func.ps1  256                        
        ...                       

    Export all 'line'-type breakpoints on the current open ISE tab, to a matching xml file
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('gIseBp')]
    PARAM() ;
    PROCESS {
        if ($psise){
            if($psise.CurrentFile.FullPath){
                get-psbreakpoint -script $psise.CurrentFile.FullPath | write-output ; 
            } else { throw "ISE has no current file open. Open a file before using this script" } ; 
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
}

#*------^ get-ISEBreakPoints.ps1 ^------


#*------v get-ISEOpenFilesExported.ps1 v------
function get-ISEOpenFilesExported {
    <#
    .SYNOPSIS
    get-ISEOpenFilesExported - List CU profile .\Documents\WindowsPowerShell\Scripts\*.psXML files, reflecting prior exports via export-ISEOpenFiles, as targets for import via import-ISEOpenFiles
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : get-ISEOpenFilesExported.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 1:55 PM 5/29/2025 add expl dumping report of name & the constituent files in most recent exports
    * 9:24 AM 9/14/2023 CBH add:demo of pulling lastwritetime and using to make automatd decisions, or comparison reporting (as this returns a fullname, not a file object)
    * 1:55 PM 3/29/2023 flipped alias (clashed) iIseOpen -> gIseOpen
    * 8:51 AM 3/8/2023 init
    .DESCRIPTION
    get-ISEOpenFilesExported - List CU profile .\Documents\WindowsPowerShell\Scripts\*.psXML files, reflecting prior exports via export-ISEOpenFiles, as targets for import via import-ISEOpenFiles
    Returns list of string filepaths to pipeline, for further filtering, and passage to import-ISEOpenFiles
    .PARAMETER Tag
    Optional Tag to apply to as filename suffix[-tag 'label']
    .EXAMPLE
    PS> get-ISEOpenFilesExported -verbose
    Find any pre-existing exported ISESavedSession*.psXML files (those exported via export-ISEOpenFiles)
    .EXAMPLE
    PS> get-ISEOpenFilesExported -Tag MFA -verbose  
    Find any pre-existing exported ISESavedSession*MFA*.psXML files (those exported with -Tag MFA)
    .EXAMPLE
    PS> get-ISEOpenFilesExported -Tag MFA | import-ISEOpenFiles ; 
    Example pipelining the outputs into import-ISEOPenFiles() (via pipeline support for it's -FilePath param)
    .EXAMPLE
    PS> get-ISEOpenFilesExported | %{gci $_} | sort LastWriteTime | ft -a fullname,lastwritetime ; 
    Example finding the 'latest' (newest LastWritTime) and echoing for review
    .EXAMPLE
    PS> get-ISEOpenFilesExported | %{gci $_} | sort LastWriteTime | select -last 1 | select -expand fullname | import-ISEOpenFiles ; 
    Example finding the 'latest' (newest LastWritTime), and then importing into ISE.
    .EXAMPLE    
    PS> get-ISEOpenFilesExported | %{gci $_} | sort LastWriteTime | ? LastWriteTime -gt (get-date '5/11/2025')  | %{[xml]$xml = gc $_.fullname ; write-host -foregroundcolor green "`n====$($_.name)`n$(($xml.Objs.S|out-string).trim())`n===" ; }
    Dump summary of names & files contained, in most recent after spec'd time, sorted on LastWriteTime
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('gIseOpen')]
    PARAM(
        [Parameter(Position=0,HelpMessage="Optional Tag to check for, within prior-export filename[-Tag MFA]")]
        [string]$Tag
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        $smsg = $sBnr ;
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    }
    PROCESS {
        if ($psise){
            #$AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;
            $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
            if($Tag){
                $txmlf = join-path -path $CUScripts -ChildPath "ISESavedSession-*$($Tag)*.psXML" ;
            } else { 
                $txmlf = join-path -path $CUScripts -ChildPath 'ISESavedSession*.psXML' ;
            } ; 
            #$allISEScripts = $psise.powershelltabs.files.fullpath ;
            $error.clear() ;
            TRY {
                
                if($hits = get-childitem -path $txmlf -ErrorAction SilentlyContinue){
                    $smsg = "(returning matched file fullnames to pipeline for ..."
                    $smsg += "`ngci $($txmlf):" ; 
                    $smsg += "`n)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    $hits | select -expand fullname ; 
                } else { 
                     $smsg = "No matches found for search..."
                    $smsg += "`ngci $($txmlf):" ; 
                    $smsg += "`n)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                write-warning $smsg ;
                Continue ; #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    }
}

#*------^ get-ISEOpenFilesExported.ps1 ^------


#*------v get-ModuleRevisedCommands.ps1 v------
function get-ModuleRevisedCommands {
    <#
    .SYNOPSIS
    get-ModuleRevisedCommands - Dynamically located any revised module 'Public' source .ps1, as identified as (LastWriteTime -gt RequiredVersion.pkg.LastWriteTime), and return array of fullname paths to .ps1's for ipmo during revision debugging.
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : get-ModuleRevisedCommands
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 12:17 PM 6/2/2022 #171 corrected typo in 'no matches' output ; as ipmo w/in a module doesn't export the results to the 
        environement, post-exec, ren import-ModuleRevised -> get-ModuleRevisedCommands, 
        and hard-code export list as sole function; set catch to continue; added 
        -ReturnList for external ipmo;  flipped pipeline array detect to test name 
        count, and not isArray (it's hard typed array, so it's always array)
    * 12:11 PM 5/25/2022 init
    .DESCRIPTION
    get-ModuleRevisedCommands - Dynamically located any revised module 'Public' source .ps1, as identified as (LastWriteTime -gt RequiredVersion.pkg.LastWriteTime), and return array of fullname paths to .ps1's for ipmo during revision debugging.
    Quick, 'reload my current efforts for testing', that isolates most recent revised .\Public folder .ps1's, for the specified module, and returns an array, to be ipmo -force -verbose, for debugging. 
    Assumes that module source files are in following tree structure (example for the Verb-IO module):

    ```text
    C:\SC\VERB-IO
    ├───Internal
    │       [Internal 'non'-exported cmdlet files].ps1 
    ├───Package
    │       verb-io.2.0.3.nupkg # RequiredRevision nupkg file location and name-structure
    ├───Public
    │       [Public exported cmdlet files].ps1
    └───verb-IO
        │   verb-IO.psd1 # module Manifest psd1
        │   verb-IO.psm1 # module .psm1 file
    ```

    Notes: 
        - Supports specifying name as a semicolon-delimted string: "[moduleName];[requiredversion]", to pass an array of name/requiredversion combos for processing. 
        - ipmo -fo -verb 'C:\sc\verb-dev\public\get-ModuleRevisedCommands.ps1' ; 
    
        - In general this seems to work more effectively run with single-modules and -RequiredVersion, rather than feeding an array through with a common -ExplicitTime. 

    .PARAMETER Name
    Module Name to have revised Public source directory import-module'd. Optionally can specify as semicolon-delimited hybrid value: -Name [ModuleName];[RequiredVersion] [-Name verb-io]
    .PARAMETER RequiredVersion
    Required module .pkg file version to be used as filter date  for determining 'revised' public cmdlets[-RequiredVersion '2.0.3']
    .PARAMETER ExplicitTime
    Explicit timestamp to be used for 'Revised' Public .ps1 cmdlet filtering[-ExplicitTime (get-date).adddays(-14)]
    .EXAMPLE
    PS> get-ModuleRevisedCommands -Name verb-io -RequiredVersion '2.0.3' -verbose
    Retrieve any Public cmdlet .ps1 for the source directory of verb-io, dated after the locally stored nupkg file for Version 2.0.3
    .EXAMPLE
    PS> get-ModuleRevisedCommands -Name verb-io -ExplicitTime (get-date).adddays(-14) -verbose
    Retrieve any Public cmdlet .ps1 for the source directory of verb-io, dated in the last 14 days (as specified via -ExplicitTime parameter).
    .EXAMPLE
    PS> get-ModuleRevisedCommands -Name 'verb-io','verb-dev' -ExplicitTime (get-date).adddays(-14) -verbose ;
    Retrieve both verb-io and verb-dev, against revisions -ExplicitTime'd 14days prior.
    .EXAMPLE
    PS> [array]$lmod = get-ModuleRevisedCommands -Name verb-dev -verbose -RequiredVersion 1.5.9 -ReturnList ;
    PS> $lmod += get-ModuleRevisedCommands -Name verb-io -verbose -RequiredVersion 2.0.0 -ReturnList;
    PS> ipmo -fo -verb $lmod ;    
    Demo use of external ipmo of resulting list.
    .EXAMPLE
    PS> $lmod= get-ModuleRevisedCommands -Name "verb-dev;1.5.9","verb-io;2.0.0" ; 
    PS> ipmo -fo -verb $lmod ;    
    Demo use of semicolon-delimited -Name with both ModuleName and RequiredVersion, in an array, with external ipmo of resulting list.
    .LINK
    https://github.com/tostka/verb-dev
    #>
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    [CmdletBinding(DefaultParameterSetName='Version')]
    [Alias('gmorc')]
    PARAM(
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Module Name to have revised Public source directory import-module'd[-PARAM SAMPLEINPUT]")]
        [ValidateNotNullOrEmpty()]
        #[Alias('ALIAS1', 'ALIAS2')]
        [string[]]$Name,
        [Parameter(ParameterSetName='Version',HelpMessage="Required module .pkg file version to be used as filter date  for determining 'revised' public cmdlets[-RequiredVersion '2.0.3']")]
        [version] $RequiredVersion,
        [Parameter(ParameterSetName='Date',HelpMessage="Explicit timestamp to be used for 'Revised' Public .ps1 cmdlet filtering[-ExplicitTime (get-date).adddays(-14)]")]
        [datetime] $ExplicitTime,
        [Parameter(HelpMessage="Switch to load Internal commands (along with 'Public' commands)[-whatIf]")]
        [switch] $Internal
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue") ;
        $sBnr="#*======v $($CmdletName): v======" ; 
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;

        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ; 
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ; 
            write-verbose "(non-pipeline - param - input)" ; 
        } ; 
        if( $RequiredVersion -AND (($Name|measure).count -gt 1)){
            $smsg = "An array of -Name (modules) values was specified"
            $smsg += "`nalong with a -RequiredVersion specification:"
            $smsg += "`nThis command can use a generic ExplicitTime filter across multiple modules,"
            $smsg += "`nbut *cannot* use a single -RequiredVersion across multiple modules!"
            $smsg += "`nPlease rerun the command, specifying either a *non-Array* for -Name, or a generic -ExplicitTime to filter target command revisions"
            $smsg += "`nOr use the -Name `"[modulename];[requiredversion]`" parameter option to specify per-module requiredversion values"
            $smsg += "`n(which also supports running an array of the Name combos)."
            write-warning $smsg ; 
            throw $smsg ; 
            Break ; 
        } ; 
    }
    PROCESS {
        foreach ($item in $Name){
            $sBnrS="`n#*------v PROCESSING : $($item) v------" ; 
            write-host -foregroundcolor green $sBnrS ;

            if($item.contains(';')){
                if($RequiredVersion){
                    $smsg = "-RequiredVersion specified, while using semicolon-delimited Name;RequiredVersion spec."
                    $smsg += "`nuse one or the other, but not *both*" ; 
                    write-warning $smsg ; 
                    throw $smsg ; 
                    Break ;
                } else { 
                    write-verbose "(semicolon-delimited -Name value found: splitting on semicolon and assuming pattern:[`$Name];[`$RequiredVersion]" ; 
                    $ModuleName,$tRequiredVersion = $item.split(';')
                } ; 
            } else {
                $ModuleName = $item ; 
                $tRequiredVersion = $RequiredVersion
            } ; ; 
            $error.clear() ;
            TRY{
                [string]$ModRoot = gi c:\sc\$ModuleName ;
                [string[]]$revisedcommands = @() ; 
                $smsg = "(filtering:`n`$ModRoot:$($ModRoot)" ; 
                if($tRequiredVersion){
                    $smsg += "`nOn RequiredVersion:$($tRequiredVersion)" ; 
                    [system.io.fileinfo]$targetPkg = (Resolve-Path "$modroot\Package\*$($tRequiredVersion.ToString()).nupkg").path ;
                    $cutDate = $targetPkg.lastwritetime ; 
                    $smsg += "`nwith effective CutDate:$($cutDate))" ; 
                } elseif($ExplicitTime){
                    $cutDate = $ExplicitTime ; 
                    $smsg += "`nwith ExplicitTime CutDate:$($cutDate))" ; 
                } else {
                    write-warning "Neither -RequiredVersion nor -ExplicitTime specified: Please specify one or the other)" ; 
                    Break ; 
                }; 
                write-verbose $smsg ; 
                $revisedcommands = (gci $ModRoot\public\*.ps1 | ? LastWriteTime -gt  $cutDate).fullname ; 
                if($Internal){
                    $revisedcommands += (gci $ModRoot\Internal\*.ps1 | ? LastWriteTime -gt  $cutDate).fullname ; 
                } 
                $smsg = "$(($revisedcommands|measure).count) matching commands returned)" ; 
                write-verbose $smsg ;

            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-warning "$($smsg)" } ;
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ; 
            if ($revisedcommands){
                write-verbose "(returning `$revisedcommands to pipeline)" ; 
                $revisedcommands | write-output ; 
            } else {  
                $smsg = "No Revised $($ModuleName) cmdlets detected (post $(get-date $cutDate -format 'yyyyMMdd-HHmmtt'))"
                write-host $smsg ;
                #$false | write-output ; # NO don't return $false, it just winds up in the array of functional ipmo-ables
            };
            write-host -foregroundcolor green $sBnrS.replace('-v','-^').replace('v-','^-') ;
        } ;  # loop-E $items in $NaME
    } # PROC-E
    END{
        write-host -foregroundcolor green $sBnr.replace('=v','=^').replace('v=','^=') ; 
    } ;
}

#*------^ get-ModuleRevisedCommands.ps1 ^------


#*------v get-NounAliasTDO.ps1 v------
Function get-NounAliasTDO {
    <#
    .SYNOPSIS
    get-NounAliasTDO.ps1 - Returns dereived 'alias' a given Powershell Noun (as derived from use of verb-dev:Find-NounAliasesTDO()))
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2023-12-12
    FileName    : get-NounAliasTDO.ps1
    License     : MIT License
    Copyright   : (c) 2023 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,verbs
    REVISION
    * 3:00 PM 7/20/2022 init
    .DESCRIPTION
    get-NounAliasTDO.ps1 - Returns dereived 'alias' a given Powershell Noun (as derived from use of verb-dev:Find-NounAliasesTDO()))

    I use this for building mnemoic splatted variable names: $plt[verbAlias][objectalias]

    As documented at:
    
    [Approved Verbs for PowerShell Commands - PowerShell | Microsoft Learn - UID - learn.microsoft.com/](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3)
    
   
    > 🏷️  **Note**
    > 
    > Microsoft has *not* been consistent in the verb aliases they've used in cmdlets over time. 
    > The below includes notations of observed instances where MS has used a _different_ alias for the same verb, on different 'official' modules and cmdlets.

        a | Add
        ap | Approve
        as | Assert
        ba | Backup
        bl | Block
        bd | Build
        ch | Checkpoint
        cl | Clear
        cs | Close
        cr | Compare
        cp | Complete
        cm | Compress
        cn | Confirm
        cc,cn | Connect (cnsn -> Connect-PSSession, verb docs says cc, and cn == Confirm)
        cv | Convert
        cf | ConvertFrom
        ct | ConvertTo
        cp | Copy
        db | Debug
        dn | Deny
        dp | Deploy
        d | Disable
        dc,dn | Disconnect (dnsn -> Disconnect-PSSession, verb docs says dc)
        dm | Dismount
        ed | Edit
        e | Enable
        et | Enter
        ex | Exit
        en | Expand
        ep | Export
        f | Format
        g | Get
        gr | Grant
        gp | Group
        h | Hide 
        j | Join 
        ip | Import
        i | Invoke
        in | Initialize
        is | Install
        l | Limit
        lk | Lock 
        ms | Measure
        mg | Merge
        mt | Mount
        m | Move
        n | New
        op | Open 
        om | Optimize 
        o | Out
        pi | Ping
        pop | Pop 
        pt | Protect
        pb | Publish
        pu | Push
        rd | Read 
        re | Redo
        rc | Receive
        rg | Register
        r | Remove
        rn | Rename
        rp | Repair
        rq | Request
        rv | Resolve
        rt | Restart
        rr | Restore
        ru | Resume
        rk | Revoke
        sv | Save
        sr | Search 
        sc | Select
        sd | Send
        s | Set
        sh | Show
        sk | Skip
        sl | Split 
        sa | Start
        st | Step 
        sp | Stop
        sb | Submit
        ss,su | Suspend (sujb -> Suspend-Job, verb docs says ss)
        sy | Sync
        sw | Switch 
        t | Test
        tr | Trace
        ul | Unblock
        un | Undo 
        us | Uninstall
        uk | Unlock
        up | Unprotect
        ub | Unpublish
        ur | Unregister
        ud | Update
        u | Use
        w | Wait
        wc | Watch
        ? | Where
        wr | Write

    ## Powershell code to convert a markdown table like the above, to the input $sdata value above:
     (uses my verb-IO module's convertfrom-MarkdownTable())

    ```powershell
    $nounAliases = @"
al | Alias
bp | PSBreakpoint
c | Content
ci | ChildItem
cm | Command
cs | PSCallStack
csv | Csv
dr | PSDrive
ex | Expression
gv | GridView
h | Host
hx | Hex
hy | History
i | Item
in | ComputerInfo
jb | Job
l | list
m | member
mo | Module
p | ItemProperty
pa | Path
Prefix | Noun
ps | Process
pv | ItemPropertyValue
rm | RestMethod
sn | PSSession
snp | PSSnapin
st | SourceTable
sv | Service
t | Table
tn | Typename
tz | TimeZone
u | Unique
v | Variable
w | Wide
wmi | WmiObject, WmiMethod
wr | WebRequest
"@ ; 
    write-verbose "split & replace ea line with a quote-wrapped [alias];[noun] combo, then join the array with commas" ;
    $nounAliases.Split([Environment]::NewLine) | sort ; 
    $sdata = "'$(($nounAliases.Split([Environment]::NewLine).replace(' | ',';') | %{ "$($_)" }) -join "','")'" ; 
    ```
    
    .PARAMETER Noun
    Noun to find the associated standard alias[-Noun process]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    System.string
    .EXAMPLE
    PS> 'Module' | get-NounAliasTDO ;
    Return the 'standard' MS alias for the 'Module' noun (returns 'mo')
    .EXAMPLE
    PS> get-alias | sort displayname | ?{$_.displayname -match '\s->\s' } | ft -a displayname
    Quick code to dump a list for review, for addition to this function (without full pass of find-NounAliasesTDO)
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('get-NounAlias')]
    #[OutputType([boolean])]
    PARAM (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Noun to find the associated standard alias[-Noun Module]")]
        [string[]] $Noun
    ) ;
    BEGIN {
        $verbose = ($VerbosePreference -eq "Continue") ; 
        # array of mappings: [Noun];[std alias] (1st entry is the column name row, for use when an input for a data table, or into convertto-Markdowntable)
        $sdata = 'al;Alias','bp;PSBreakpoint','c;Content','ci;ChildItem','cm;Command','cs;PSCallStack','csv;Csv',
        'dr;PSDrive','ex;Expression','gv;GridView','h;Host','hx;Hex','hy;History','i;Item','in;ComputerInfo',
        'jb;Job','l;list','m;member','mo;Module','p;ItemProperty','pa;Path','Prefix;Noun','ps;Process',
        'pv;ItemPropertyValue','rm;RestMethod','sn;PSSession','snp;PSSnapin','st;SourceTable','sv;Service','t;Table',
        'tn;Typename','tz;TimeZone','u;Unique','v;Variable','w;Wide','wr;WebRequest'
        # convert semi-delimted array of values into indexed hash for lookups
        $hshAliasesPrfx = @{} ;
        $sdata | select-object -skip 1 |foreach-object{
            # split at semi, and assign the array elements to $value & $key respectively
            $value,$key = $_.split(';') ; 
            # add indexed hash element on $key with $value
            $hshAliasesPrfx[$key] = $value ;
        } ;
        # clear temp varis
        'sdata','key','value' | remove-variable -ea 0 -verbose ; 
    } ;
    PROCESS {
        foreach($item in $Noun){
            write-verbose "(checking: $($item))" ; 
            if($hshAliasesPrfx[$item]){
                $hshAliasesPrfx[$item] | write-output 
            }else {
                write-warning "no lookup match for Noun '$($item)'" 
                $false | write-output ; 
            } ;
        } ; 
    } ;  # PROC-E
    END {} ; # END-E
}

#*------^ get-NounAliasTDO.ps1 ^------


#*------v get-OpenNotepadsExported.ps1 v------
function get-OpenNotepadsExported {
    <#
    .SYNOPSIS
    get-OpenNotepadsExported - List CU profile .\Documents\WindowsPowerShell\Scripts\data\NotePdSavedSession*.psXML files, reflecting prior exports via export-OpenNotepads, as targets for import via import-OpenNotepads
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : get-OpenNotepadsExported.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 1:46 PM 7/2/2025 init, works
    .DESCRIPTION
    get-OpenNotepadsExported - List CU profile .\Documents\WindowsPowerShell\Scripts\data\NotePdSavedSession*.psXML files, reflecting prior exports via export-OpenNotepads, as targets for import via import-OpenNotepads

    Returns list of string filepaths to pipeline, for further filtering, and passage to import-OpenNotepads
    .PARAMETER Tag
    Optional Tag to apply to as filename suffix[-tag 'label']
    .EXAMPLE
    PS> get-OpenNotepadsExported -verbose
    Find any pre-existing exported ISESavedSession*.psXML files (those exported via export-OpenNotepads)
    .EXAMPLE
    PS> get-OpenNotepadsExported -Tag MFA -verbose  
    Find any pre-existing exported ISESavedSession*MFA*.psXML files (those exported with -Tag MFA)
    .EXAMPLE
    PS> get-OpenNotepadsExported -Tag MFA | import-OpenNotepads ; 
    Example pipelining the outputs into import-OpenNotepads() (via pipeline support for it's -FilePath param)
    .EXAMPLE
    PS> get-OpenNotepadsExported | %{gci $_} | sort LastWriteTime | ft -a fullname,lastwritetime ; 
    Example finding the 'latest' (newest LastWritTime) and echoing for review
    .EXAMPLE
    get-OpenNotepadsExported | %{gci $_} | sort LastWriteTime | select -last 1 | select -expand fullname | import-OpenNotepads ; 
    Example finding the 'latest' (newest LastWritTime), and then importing into ISE.
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('gIseOpen')]
    PARAM(
        [Parameter(Position=0,HelpMessage="Optional Tag to check for, within prior-export filename[-Tag MFA]")]
        [string]$Tag
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        $smsg = $sBnr ;
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    }
    PROCESS {
        
        #$AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;
        $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
        # CREATE new WindowsPowershell\Scripts\data folder if nonexist, use it to park data .xml & jsons etc for script processing/output (should prob shift the ise export/import code to use it)
        $npExpDir = join-path -path $CUScripts -ChildPath 'data' ;
        if(-not(test-path $npExpDir)){
            mkdir $npExpDir -verbose ;
        }

        if($Tag){
            $txmlf = join-path -path $npExpDir -ChildPath "NotePdSavedSession-$($Tag)*.psXML" ;
        } else {
            $txmlf = join-path -path $npExpDir -ChildPath "NotePdSavedSession-*.psXML" ;
        } ;
        #$allISEScripts = $psise.powershelltabs.files.fullpath ;
        $error.clear() ;
        TRY {
                
            if($hits = get-childitem -path $txmlf -ErrorAction SilentlyContinue){
                $smsg = "(returning matched file fullnames to pipeline for ..."
                $smsg += "`ngci $($txmlf):" ; 
                $smsg += "`n)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                $hits | select -expand fullname ; 
            } else { 
                    $smsg = "No matches found for search..."
                $smsg += "`ngci $($txmlf):" ; 
                $smsg += "`n)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            } ; 
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
            write-warning $smsg ;
            Continue ; #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
        } ;
        
    } # PROC-E
    END{
        $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    }
}

#*------^ get-OpenNotepadsExported.ps1 ^------


#*------v get-ProjectNameTDO.ps1 v------
function get-ProjectNameTDO {
    <#
    .SYNOPSIS
    get-ProjectNameTDO.ps1 - Get the name for this project (lifted from BuildHelpers module, and renamed to avoid collisions
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-10-15
    FileName    : get-ProjectNameTDO.ps1
    License     : MIT License 
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell
    AddedCredit :  RamblingCookieMonster (Warren Frame)
    AddedWebsite: https://github.com/RamblingCookieMonster
    AddedTwitter: @pscookiemonster
    AddedWebsite: https://github.com/RamblingCookieMonster/BuildHelpers
    REVISIONS
    * 11:20 AM 12/12/2022 completely purged rem'd require stmts, confusing, when they echo in build...
    * 11:51 AM 10/16/2021 init version, minor CBH mods, put into OTB format. 
    * 1/1/2019 BuildHelpers most recent rev of the get-PsModuleManifest function.
    .DESCRIPTION
    Get the name for this project

        Evaluates based on the following scenarios:
            * Subfolder with the same name as the current folder
            * Subfolder with a <subfolder-name>.psd1 file in it
            * Current folder with a <currentfolder-name>.psd1 file in it
            + Subfolder called "Source" or "src" (not case-sensitive) with a psd1 file in it

        If no suitable project name is discovered, the function will return
        the name of the root folder as the project name.
        
         We assume you are in the project root, for several of the fallback options
         
         [How to Write a PowerShell Module Manifest - PowerShell | Microsoft Docs - docs.microsoft.com/](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-module-manifest?view=powershell-7.1)
         "You link a manifest file to a module by naming the manifest the same as the module, and storing the manifest in the module's root directory."
         
         [Understanding a Windows PowerShell Module - PowerShell | Microsoft Docs - docs.microsoft.com/](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/understanding-a-windows-powershell-module?view=powershell-7.1)
          "A module is a set of related Windows PowerShell functionalities, grouped together as a convenient unit (usually saved in a single directory)."
          "Regardless, the path of the folder is referred to as the base of the module (ModuleBase), and the name of the script, binary, or manifest module file (.psm1) should be the same as the module folder name, with the following exceptions:..."
          
    .FUNCTIONALITY
    CI/CD
    .PARAMETER Path
    Path to project root. Defaults to the current working path [-path 'C:\sc\PowerShell-Statistics\']
    .EXAMPLE
    $ModuleName = get-ProjectNameTDO -path c:\sc\someproj\
    Retrieve the Name from the specified project, and assign it to the $ModuleName variable
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://github.com/RamblingCookieMonster/BuildHelpers
    .LINK
    Get-BuildVariable
    .LINK
    Set-BuildEnvironment
    .LINK
    about_BuildHelpers
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to project root. Defaults to the current working path [-path 'C:\sc\PowerShell-Statistics\']")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$Path = $PWD.Path,
        [validatescript({
            if(-not (Get-Command $_ -ErrorAction SilentlyContinue))
            {
                throw "Could not find command at GitPath [$_]"
            }
            $true
        })]
        $GitPath = 'git'
    ) ;
    
    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
    $sBnr="#*======v RUNNING :$($CmdletName):$($Extension):$($Path) v======" ; 
    $smsg = "$($sBnr)" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

    if(!$PSboundParameters.ContainsKey('GitPath')) {
        $GitPath = (Get-Command $GitPath -ErrorAction SilentlyContinue)[0].Path ; 
    } ; 

    $WeCanGit = ( (Test-Path $( Join-Path $Path .git )) -and (Get-Command $GitPath -ErrorAction SilentlyContinue) ) ; 

    $Path = ( Resolve-Path $Path ).Path ; 
    $CurrentFolder = Split-Path $Path -Leaf   ; 
    $ExpectedPath = Join-Path -Path $Path -ChildPath $CurrentFolder ; 
    if(Test-Path $ExpectedPath) { $result = $CurrentFolder }
    else{
        # Look for properly organized modules
        $ProjectPaths = Get-ChildItem $Path -Directory |
            Where-Object {
                Test-Path $(Join-Path $_.FullName "$($_.name).psd1")  
            } |
                Select-Object -ExpandProperty Fullname ; 

        if( @($ProjectPaths).Count -gt 1 ){
            Write-Warning "Found more than one project path via subfolders with psd1 files" ; 
            $result = Split-Path $ProjectPaths -Leaf ; 
        } elseif( @($ProjectPaths).Count -eq 1 ){
            $result = Split-Path $ProjectPaths -Leaf ; 
        } elseif( Get-Item "$Path\S*rc*\*.psd1" -OutVariable SourceManifests){
            # PSD1 in Source or Src folder
            If ( $SourceManifests.Count -gt 1 ){
                Write-Warning "Found more than one project manifest in the Source folder" ; 
            } ; 
            $result = $SourceManifests.BaseName
        } elseif( Test-Path "$ExpectedPath.psd1" ) {
            #PSD1 in root of project - ick, but happens.
            $result = $CurrentFolder ; 
        } elseif ( $PSDs = Get-ChildItem -Path $Path "*.psd1" ){
            #PSD1 in root of project but name doesn't match
            #very ick or just an icky time in Azure Pipelines
            if ($PSDs.count -gt 1) {
                Write-Warning "Found more than one project manifest in the root folder" ; 
            } ; 
            $result = $PSDs.BaseName ; 
        } elseif ( $WeCanGit ) {
            #Last ditch, are you in Azure Pipelines or another CI that checks into a folder unrelated to the project?
            #let's try some git
            $result = (Invoke-Git -Path $Path -GitPath $GitPath -Arguments "remote get-url origin").Split('/')[-1] -replace "\.git","" ; 
        } else {
            Write-Warning "Could not find a project from $($Path); defaulting to project root for name" ; 
            $result = Split-Path $Path -Leaf ; 
        } ; 
    } ; 

    if ($env:APPVEYOR_PROJECT_NAME -and $env:APPVEYOR_JOB_ID -and ($result -like $env:APPVEYOR_PROJECT_NAME)) {
        $env:APPVEYOR_PROJECT_NAME ; 
    } else {
        $result ; 
    } ; 
        
    $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
}

#*------^ get-ProjectNameTDO.ps1 ^------


#*------v Get-PSBreakpointSorted.ps1 v------
function Get-PSBreakpointSorted {
<#
    .SYNOPSIS
    Get-PSBreakpointSorted.ps1 - Simple Get-PSBreakpoint wrapper function (gbps alias), force Script,Line sort order on gbp output - wtf wants it's default bp# sort order?!
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2022-07-26
    FileName    : Get-PSBreakpointSorted.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Development,Debugging,BreakPoints
    REVISIONS
    * 10:55 AM 7/26/2022 init
    .DESCRIPTION
    Get-PSBreakpointSorted.ps1 - Simple Get-PSBreakpoint wrapper function (gbps alias), force Script,Line sort order on gbp output - wtf wants it's default bp# sort order?!
    Also uses abbreviated, more condensed 'format-table -a ID,Script,Line' output.
    .EXAMPLE
    Get-PSBreakpointSorted
    Stock call
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    #>
    [CmdletBinding()]
    [Alias('gbps')]
    Param() ;
    get-psbreakpoint | sort script,line | format-table -a ID,Script,Line ; 
}

#*------^ Get-PSBreakpointSorted.ps1 ^------


#*------v Get-PSModuleFile.ps1 v------
function Get-PSModuleFile {
    <#
    .SYNOPSIS
    Get-PSModuleFile.ps1 - Locate & return the string path to a module's manifest .psd1 file, given the root path of the moodule (direct lift from BuildHelpers:Get-PSModuleManifest, but I want a sep copy wo BH as a dependancy)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-10-15
    FileName    : Get-PSModuleFile.ps1
    License     : MIT License 
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell
    AddedCredit :  RamblingCookieMonster (Warren Frame)
    AddedWebsite: https://github.com/RamblingCookieMonster
    AddedTwitter: @pscookiemonster
    AddedWebsite: https://github.com/RamblingCookieMonster/BuildHelpers
    REVISIONS
    * 11:20 AM 12/12/2022 completely purged rem'd require stmts, confusing, when they echo in build...
    * 9:31 AM 9/27/2022 CBH update, clearly indic it returns a [string] and not a file obj 
    * 10:48 AM 3/14/2022 updated CBH for missing extension param
    * 11:38 AM 10/15/2021 init version, added support for locating both .psd1 & .psm1, a new -Extension param to drive the choice, and a 'both' optional extension spec to retrieve both file type paths.
    * 1/1/2019 BuildHelpers most recent rev of the get-PsModuleManifest function.
    .DESCRIPTION
    Get-PSModuleFile.ps1 - Locate & return the string path to a module's manifest .psd1 file, given the root path of the moodule (direct lift from BuildHelpers:Get-PSModuleManifest, but I want a sep copy wo BH as a dependancy)
    Get the PowerShell key psd1|psm1 for a project ;
        Evaluates based on the following scenarios: ;
            * Subfolder with the same name as the current folder with a psd1|psm1 file in it ;
            * Subfolder with a <subfolder-name>.psd1|psm1 file in it ;
            * Current folder with a <currentfolder-name>.psd1|psm1 file in it ;
            + Subfolder called "Source" or "src" (not case-sensitive) with a psd1|psm1 file in it ;
        Note: This does not handle paths in the format Folder\ModuleName\Version\ ;
    .PARAMETER Path
    Path to project root. Defaults to the current working path [-path 'C:\sc\PowerShell-Statistics\']
    .PARAMETER Path Extension
    Specify Module file type: Module .psm1 file or Manifest .psd1 file (psd1|psm1|both - defaults psd1)[-Extension .psm1]
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    System.String
    .EXAMPLE
    $psd1M = Get-PSModuleFile -path c:\sc\someproj\
    Retrieve the defualt .psd1 Manifest from the specified project, and assign the fullpath to the $psd1M variable
    .EXAMPLE
    Get-PSModuleFile -path c:\sc\someproj\ -extension 'psm1'
    Use the -Extension 'Both' option to find and return the path to the .psm1 Module file for the specified project, 
    .EXAMPLE
    $modulefiles = Get-PSModuleFile -path c:\sc\someproj\ -extension both
    Use the -Extension 'Both' option to find and return the paths of both the .psd1 Manifest and the .psm1 Module for the specified project, and assign the fullpath to the $modulefiles variable
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://github.com/RamblingCookieMonster/BuildHelpers
    #>  
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to project root. Defaults to the current working path [-path 'C:\sc\PowerShell-Statistics\']")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$Path = $PWD.Path,
        [Parameter(HelpMessage="Specify Module file type: Module .psm1 file or Manifest .psd1 file (psd1|psm1 - defaults psd1)[-Extension .psm1]")]
        [ValidateSet('.psd1','.psm1','both')]
        [string] $Extension='.psd1'
    ) ;
    
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $sBnr="#*======v RUNNING :$($CmdletName):$($Extension):$($Path) v======" ; 
        $smsg = "$($sBnr)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

        if($Extension -eq 'Both'){
            [array]$Exts = '.psd1','.psm1'
            write-verbose "(-extension Both specified: Running both:$($Exts -join ','))" ; 
        } else {
            $Exts = $Extension ; 
        } ; 
        $Path = ( Resolve-Path $Path ).Path ; 
        $CurrentFolder = Split-Path $Path -Leaf ;
        $ExpectedPath = Join-Path -Path $Path -ChildPath $CurrentFolder ;
        
        foreach($ext in $Exts){
            $ExpectedFile = Join-Path -Path $ExpectedPath -ChildPath "$CurrentFolder$($ext)" ;
            if(Test-Path $ExpectedFile){$ExpectedFile  } 
            else {
                # Look for properly organized modules (name\name.ps(d|m)1)
                $ProjectPaths = Get-ChildItem $Path -Directory |
                    ForEach-Object {
                        $ThisFolder = $_ ;
                        write-verbose "checking:$($ThisFolder)" ; 
                        $ExpectedFile = Join-Path -path $ThisFolder.FullName -child "$($ThisFolder.Name)$($ext)" ;
                        If( Test-Path $ExpectedFile) {$ExpectedFile  } ;
                    } ;
                if( @($ProjectPaths).Count -gt 1 ){
                    Write-Warning "Found more than one project path via subfolders with psd1 files" ;
                    $ProjectPaths  ;
                } elseif( @($ProjectPaths).Count -eq 1 )  {$ProjectPaths  } 
                elseif( Test-Path "$ExpectedPath$($ext)" ) {
                    write-verbose "`$ExpectedPath:$($ExpectedPath)" ; 
                    #PSD1 in root of project - ick, but happens.
                    "$ExpectedPath$($ext)"  ;
                } elseif( Get-Item "$Path\S*rc*\*$($ext)" -OutVariable SourceFiles)  {
                    # PSD1 in Source or Src folder
                    If ( $SourceFiles.Count -gt 1 ) {
                        Write-Warning "Found more than one project $($ext) file in the Source folder" ;
                    } ;
                    $SourceFiles.FullName ;
                } else {
                    Write-Warning "Could not find a PowerShell module $($ext) file from $($Path)" ;
                } ;
            } ;
        } ; 
        $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
}

#*------^ Get-PSModuleFile.ps1 ^------


#*------v get-StrictMode.ps1 v------
Function get-StrictMode {
    <#
    .SYNOPSIS
    get-StrictMode - A very simple function to retrieve the Set-StrictMode setting of the user
session. 
    .NOTES
    Version     : 2.1.0
    Author      : Sea Star Development
    Website     :	https://www.powershellgallery.com/packages/strictmode/2.1/Content/strictmode.ps1
    Twitter     :	
    CreatedDate : 2022-12-15
    FileName    : get-StrictMode.ps1
    License     : (none asserted)
    Copyright   : Sea Star Development
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,debugging
    AddedCredit : Todd Kadrie
    AddedWebsite:	http://www.toddomation.com
    AddedTwitter:	@tostka / http://twitter.com/tostka
    REVISIONS
    * 1:10 PM 12/15/2022 added vers 3 test/triggers (existing only went to v2); updated CBH; added to verb-dev
    * 11/17/2017 (posted psg version) "V2.1 Incorporate Version() and ToString() ScriptMethods, 4 Jan 2013."
    .DESCRIPTION
    get-StrictMode - A very simple function to retrieve the Set-StrictMode setting of the user
session. 
    Retrieve the Set-StrictMode setting for the current session.
This procedure is necessary as there is, apparently, no equivalent PowerShell
variable for this and it enables the setting to be returned to its original
state after possibly being changed within a script. Add this function
to your $profile. 

    [Set-StrictMode (Microsoft.PowerShell.Core) - PowerShell | Microsoft Learn - learn.microsoft.com/](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode?view=powershell-7.2)

    ## -Version

    ### `1.0`

    -   Prohibits references to uninitialized variables, except for uninitialized variables in strings.

    ### `2.0`

    -   Prohibits references to uninitialized variables. This includes uninitialized variables in strings.
    -   Prohibits references to non-existent properties of an object.
    -   Prohibits function calls that use the syntax for calling methods.

    ### `3.0`

    -   Prohibits references to uninitialized variables. This includes uninitialized variables in strings.
    -   Prohibits references to non-existent properties of an object.
    -   Prohibits function calls that use the syntax for calling methods.
    -   Prohibit out of bounds or unresolvable array indexes.

    .EXAMPLE
    PS> Get-StrictMode
    The various values returned will be Version 1, Version 2, or Off.
    .EXAMPLE
    PS> $a = (Get-StrictMode).Version()
    This will allow the environment to be restored just by entering the commmand
    Invoke-Expression "Set-StrictMode $a" 
    .LINK
    https://github.com/tostka/verb-Text
    https://www.powershellgallery.com/packages/strictmode/2.1
    #>
    [CmdletBinding()]
    PARAM()  ; 
    $errorActionPreference = 'Stop' ; 
    $version = '0' ; 
    try {
        $version = '3' ; 
        #V3 will catch on these
        $a = @(1) ; 
        $null -eq $a[2] | out-null ; 
        $null -eq $a['abc'] | out-null ; 
        $version = '2' ; 
        #V2 will catch this
        $z = "2 * $nil"       
        $version = '1' ; 
        #V1 will catch this.
        $z = 2 * $nil ;
        $version = 'Off' ; 
    } catch {} ; 
    $errorActionPreference = 'Continue' ; 
    New-Module -ArgumentList $version -AsCustomObject -ScriptBlock {
        param ([String]$version) ; 
        function Version() {
            if ($version -eq 'Off') {
                [String]$output = '-Off' ; 
            } else {
                [String]$output = "-Version $version" ; 
            } ; 
            #(Get-StrictMode).Version() ; 
            "$output" | write-output ;
        } ; 
        function ToString() {
            if ($version -ne 'Off') {
              $version = "Version $version" ; 
            } ; 
            #Get-StrictMode will output string.
            "StrictMode: $version" | write-output  ;
        }  ; 
        Export-ModuleMember -function Version,ToString  ; 
    }  ; 
}

#*------^ get-StrictMode.ps1 ^------


#*------v get-VariableAssignsAST.ps1 v------
function get-VariableAssignsAST {
    <#
    .SYNOPSIS
    get-VariableAssignsAST - All Alias assigns ((set|new)-Alias) from the specified $Parsefile, output them directly to pipeline (capture on far end & parse/display)
    .NOTES
    Author: Todd Kadrie
    Based on Code by: Philip Giuliani (broken example), functional AST code & example by Bartek Bielawski
    Website:	http://tinstoys.blogspot.com
    Twitter:	http://twitter.com/tostka
    REVISIONS   :
    # 9:55 AM 5/18/2022 add ported variant of get-functionblocks()
    .DESCRIPTION
    get-VariableAssignsAST - All Variable assigns from the specified $Path, output them directly to pipeline (capture on far end & parse/display)
    .PARAMETER  Path
    Script to be parsed [path-to\script.ps1]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    None. Returns matched Function block to pipeline.
    get-VariableAssignsAST -Parse C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    Pull/display the Add-EMSRemote function from the specified .ps1, using named params
    .EXAMPLE
    $VariAssigns = get-VariableAssignsAST C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    $VariAssigns | ?{$_ -like '*get-ScriptProfileAST*'}
    Pull ALL Variable Assignements, and post-filter return for specific Alias Definition/Value.
    .LINK
    https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
    https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/
    #>

    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Script to be parsed [path-to\script.ps1]")][ValidateNotNullOrEmpty()]
        [Alias('ParseFile')]
        [system.io.fileinfo]$Path
    )  ;

    $sw = [Diagnostics.Stopwatch]::StartNew();

    New-Variable astTokens -force ; New-Variable astErr -force ;
    write-verbose "$((get-date).ToString('HH:mm:ss')):(running AST parse...)" ; 
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$astTokens, [ref]$astErr) ;
    # use of aliased commands (% for foreach-object etc)
    #$aliases = $astTokens | where {$_.tokenflags -eq 'commandname' -AND $_.kind -eq 'identifier'} ;
    # new|set-alias use
    write-verbose "$((get-date).ToString('HH:mm:ss')):(finding all of the commands references...)" ; 
    $ASTAllCommands = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true) ; 
    #write-verbose "$((get-date).ToString('HH:mm:ss')):(pulling set/new-Alias commands out...)" ; 
    #$ASTAliasAssigns = ($ASTAllCommands | ?{$_.extent.text -match '(set|new)-alias'}).extent.text
    # dump the .extent.text, if you want the explicit set/new-alias commands 
    # this variant pulls commands v functions
    #$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)
    write-verbose "$((get-date).ToString('HH:mm:ss')):(find all of the variable assignments...)" ; 
    $ASTVariableAssigns = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.VariableExpressionAst]},$true) ; 
    # or, shrtening with *
    # $AST.FindAll({$args[0].GetType().Name -like "*Variable*Ast"}, $true) | Select-Object -Property Extent -Unique ; 
    # dump the parent.extent.text, to get the raw line from the code (vs all the components in the AST).
    foreach ($variableAssign in $ASTVariableAssigns.parent.extent.text) {
        $variableAssign | write-output ;
    } ;
    $sw.Stop() ;
    write-verbose ("Elapsed Time: {0:dd}d {0:hh}h {0:mm}m {0:ss}s {0:fff}ms" -f $sw.Elapsed) ; 
}

#*------^ get-VariableAssignsAST.ps1 ^------


#*------v get-VerbAliasTDO.ps1 v------
Function get-VerbAliasTDO {
    <#
    .SYNOPSIS
    get-VerbAliasTDO.ps1 - Returns the 'standard' alias prefix for a given Powershell verb (according to MS documentation). (E.g. the common verb 'copy' has uses the standard alias prefix 'cp')
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2023-12-12
    FileName    : get-VerbAliasTDO.ps1
    License     : MIT License
    Copyright   : (c) 2023 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,verbs
    REVISION
    * 11:57 AM 12/10/2024 confirmed it already covers Build(bd) & Deploy (dp) added under Ps6 (though not present in ps5)
    * 9:37 AM 12/9/2024 corrected CBH/comment typo get-NounAlias -> get-VerbAlias
    * 3:00 PM 7/20/2022 init
    .DESCRIPTION
    get-VerbAliasTDO.ps1 - Returns the 'standard' alias prefix for a given Powershell verb (according to MS documentation). (E.g. the common verb 'copy' has uses the standard alias prefix 'cp')

    I use this for building mnemoic splatted variable names: $plt[verbAlias][objectalias]

    As documented at:
    
    [Approved Verbs for PowerShell Commands - PowerShell | Microsoft Learn - UID - learn.microsoft.com/](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3)
    
   
    > 🏷️  **Note**
    > 
    > Microsoft has *not* been consistent in the verb aliases they've used in cmdlets over time. 
    > The below includes notations of observed instances where MS has used a _different_ alias for the same verb, on different 'official' modules and cmdlets.

        a | Add
        ap | Approve
        as | Assert
        ba | Backup
        bl | Block
        bd | Build
        ch | Checkpoint
        cl | Clear
        cs | Close
        cr | Compare
        cp | Complete
        cm | Compress
        cn | Confirm
        cc,cn | Connect (cnsn -> Connect-PSSession, verb docs says cc, and cn == Confirm)
        cv | Convert
        cf | ConvertFrom
        ct | ConvertTo
        cp | Copy
        db | Debug
        dn | Deny
        dp | Deploy
        d | Disable
        dc,dn | Disconnect (dnsn -> Disconnect-PSSession, verb docs says dc)
        dm | Dismount
        ed | Edit
        e | Enable
        et | Enter
        ex | Exit
        en | Expand
        ep | Export
        f | Format
        g | Get
        gr | Grant
        gp | Group
        h | Hide 
        j | Join 
        ip | Import
        i | Invoke
        in | Initialize
        is | Install
        l | Limit
        lk | Lock 
        ms | Measure
        mg | Merge
        mt | Mount
        m | Move
        n | New
        op | Open 
        om | Optimize 
        o | Out
        pi | Ping
        pop | Pop 
        pt | Protect
        pb | Publish
        pu | Push
        rd | Read 
        re | Redo
        rc | Receive
        rg | Register
        r | Remove
        rn | Rename
        rp | Repair
        rq | Request
        rv | Resolve
        rt | Restart
        rr | Restore
        ru | Resume
        rk | Revoke
        sv | Save
        sr | Search 
        sc | Select
        sd | Send
        s | Set
        sh | Show
        sk | Skip
        sl | Split 
        sa | Start
        st | Step 
        sp | Stop
        sb | Submit
        ss,su | Suspend (sujb -> Suspend-Job, verb docs says ss)
        sy | Sync
        sw | Switch 
        t | Test
        tr | Trace
        ul | Unblock
        un | Undo 
        us | Uninstall
        uk | Unlock
        up | Unprotect
        ub | Unpublish
        ur | Unregister
        ud | Update
        u | Use
        w | Wait
        wc | Watch
        ? | Where
        wr | Write

    ## Powershell code to convert a markdown table like the above, to the input $sdata value above:
     (uses my verb-IO module's convertfrom-MarkdownTable())

    
    ```powershell
    $verbAliases = @"
Prefix | Verb
a | Add
ap | Approve
as | Assert
ba | Backup
bl | Block
bd | Build
ch | Checkpoint
cl | Clear
cs | Close
cr | Compare
cp | Complete
cm | Compress
cn | Confirm
cc | Connect
cv | Convert
cf | ConvertFrom
ct | ConvertTo
cp | Copy
db | Debug
dn | Deny
dp | Deploy
d | Disable
dc | Disconnect
dm | Dismount
ed | Edit
e | Enable
et | Enter
ex | Exit
en | Expand
ep | Export
f | Format
g | Get
gr | Grant
gp | Group
h | Hide
j | Join
ip | Import
i | Invoke
in | Initialize
is | Install
l | Limit
lk | Lock
ms | Measure
mg | Merge
mt | Mount
m | Move
n | New
op | Open
om | Optimize
o | Out
pi | Ping
pop | Pop
pt | Protect
pb | Publish
pu | Push
rd | Read
re | Redo
rc | Receive
rg | Register
r | Remove
rn | Rename
rp | Repair
rq | Request
rv | Resolve
rt | Restart
rr | Restore
ru | Resume
rk | Revoke
sv | Save
sr | Search
sc | Select
sd | Send
s | Set
sh | Show
sk | Skip
sl | Split
sa | Start
st | Step
sp | Stop
sb | Submit
ss | Suspend
sy | Sync
sw | Switch
t | Test
tr | Trace
ul | Unblock
un | Undo
us | Uninstall
uk | Unlock
up | Unprotect
ub | Unpublish
ur | Unregister
ud | Update
u | Use
w | Wait
wc | Watch
? | Where
wr | Write
"@ ; 
    write-verbose "split & replace ea line with a quote-wrapped [alias];[verb] combo, then join the array with commas" ;
    $sdata = "'$(($verbAliases.Split([Environment]::NewLine).replace(' | ',';') | %{ "$($_)" }) -join "','")'" ; 
    ```
    
    .PARAMETER Verb
    Verb to find the associated standard alias[-verb report]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    System.string
    .EXAMPLE
    PS> 'Compare' | get-verbAliasTDO ;
    Return the 'standard' MS alias for the 'Compare' verb (returns 'cr')
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('get-VerbAlias')]
    #[OutputType([boolean])]
    PARAM (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Verb to find the associated standard alias[-verb report]")]
        [string[]] $Verb
    ) ;
    BEGIN {
        $verbose = ($VerbosePreference -eq "Continue") ; 
        # array of mappings: [verb];[std alias] (1st entry is the column name row, for use when an input for a data table, or into convertto-Markdowntable)
        $sdata = 'Prefix;Verb','a;Add','ap;Approve','as;Assert','ba;Backup','bl;Block','bd;Build','ch;Checkpoint','cl;Clear',
            'cs;Close','cr;Compare','cp;Complete','cm;Compress','cn;Confirm','cc;Connect','cv;Convert','cf;ConvertFrom',
            'ct;ConvertTo','cp;Copy','db;Debug','dn;Deny','dp;Deploy','d;Disable','dc;Disconnect','dm;Dismount','ed;Edit',
            'e;Enable','et;Enter','ex;Exit','en;Expand','ep;Export','f;Format','g;Get','gr;Grant','gp;Group','h;Hide','j;Join',
            'ip;Import','i;Invoke','in;Initialize','is;Install','l;Limit','lk;Lock','ms;Measure','mg;Merge','mt;Mount','m;Move',
            'n;New','op;Open','om;Optimize','o;Out','pi;Ping','pop;Pop','pt;Protect','pb;Publish','pu;Push','rd;Read','re;Redo',
            'rc;Receive','rg;Register','r;Remove','rn;Rename','rp;Repair','rq;Request','rv;Resolve','rt;Restart','rr;Restore',
            'ru;Resume','rk;Revoke','sv;Save','sr;Search','sc;Select','sc;Select-object','sd;Send','s;Set','sh;Show','sk;Skip','sl;Split','sa;Start',
            'st;Step','sp;Stop','sb;Submit','ss;Suspend','sy;Sync','sw;Switch','t;Test','tr;Trace','ul;Unblock','un;Undo',
            'us;Uninstall','uk;Unlock','up;Unprotect','ub;Unpublish','ur;Unregister','ud;Update','u;Use','w;Wait','wc;Watch',
            '?;Where','wr;Write' ; 
        # convert semi-delimted array of values into indexed hash for lookups
        $hshAliasesPrfx = @{} ;
        $sdata | select-object -skip 1 |foreach-object{
            # split at semi, and assign the array elements to $value & $key respectively
            $value,$key = $_.split(';') ; 
            # add indexed hash element on $key with $value
            $hshAliasesPrfx[$key] = $value ;
        } ;
        # clear temp varis
        'sdata','key','value' | remove-variable -ea 0 -verbose ; 
    } ;
    PROCESS {
        foreach($item in $verb){
            write-verbose "(checking: $($item))" ; 
            #[boolean]((Get-Verb).Verb -match $item) | write-output ;
            if($hshAliasesPrfx[$item]){
                $hshAliasesPrfx[$item] | write-output 
            }else {
                write-warning "no lookup match for verb '$($item)'" 
                $false | write-output ; 
            } ;
        } ; 
    } ;  # PROC-E
    END {} ; # END-E
}

#*------^ get-VerbAliasTDO.ps1 ^------


#*------v Get-VerbSynonymTDO.ps1 v------
Function Get-VerbSynonymTDO {
    <#
    .SYNOPSIS
    Get-VerbSynonymTDO.ps1 - The Get-VerbSynonymTDO advanced function returns the synonyms for a verb. 
    .NOTES
    Version     : 1.4.5
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2023-12-12
    FileName    : Get-VerbSynonymTDO.ps1
    License     : MIT License
    Copyright   : (c) 2023 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,verbs
    AddedCredit : Tommy Maynard
    AddedWebsite: http://tommymaynard.com
    AddedTwitter: @thetommymaynard / http://twitter.com/thetommymaynard
    REVISION
    * 8:23 AM 12/13/2024 add: Alias 'Get-VerbSyn'
    * 11:55 AM 12/10/2024 add: Alias to output (queried via my verb-dev\get-VerbAliasTDO()) add: pretest input Verb, for ApprovedVerb status and pre-echo it into the outputs ; add -AllowMultiWord, otherwise, it now auto-skips multiword returned Synonyms ; 
        looked at adding theaurus.com support, by splicing over code from kpatnayakuni's get-synonym.ps1, but found it doesn't parse properly anymore (html revisions in theaurus.com output) ; 
        replaced TMs key ('fkS0rTuZ62Duag0bYgwn') with my own (simply requires a google logon, to obtain a free key).
    * 4:24 PM 12/09/2024 added full pipeline support, and looping to handle multiple verbs; updated CBH, removed script wrapper & script registration block; 
        renamed Get-TMVerbSynonym -> Get-VerbSynonymTDO(), added to verb-dev (could treat as a text movule, verb-text, but it does ps-approved verb testing, which doesn't apply to raw text.
    * 3:00 PM 7/20/2022 init
    * 06/09/2016 TM posted v1.4 cites: [1.3], 01/04/2017 [1.4] 
    TM's prior release notes below:
    Version 1.4
        - Changed -- to $null for properties that do not have a value.
        - Removed redundant Get-Verb execution, when checking if a synonym is approved (uses OutVariable and temporary variable).
        - Renamed $Approved to $ApprovedVerb due to introducing the Approved switch parameter.
        - Added Approved switch parameter to only return approved synonyms without Where-Object filtering.
        - Added hardcoded position parameter attribute to the Verb parameter.
        - Added verb supplied by user to output object; renamed Verb property used for synonym to Synonym. This creates a list by default; however, it will allow for the Verb parameter taking multiple verbs... version 1.5 perhaps.
        - Rewrote help where necessary to indicate changes.
        - Added *another* If statement, to ensure an object isn't created if the Verb and Synonym are the same: Get synonyms won't return Get; Start synonyms won't return Start.     
    Version 1.3
        - Modified code to handle logic outside of the object creation time.
        - Added Group property: Indicates name of the verb's group when verb is approved.
        - Changed Approved string property of Yes and No, to $true and $false.
        - Rewrote help where necessary to indicate changes.
    Version 1.2
        - Skipped 1.1
        - Included my key for http://thesaurus.altervista.org. This keeps from needing to register for a key.
        - Decreased number of spaces in help. Other help changes due to not needing to register for a key.
        - As API key is included, modified code to
    .DESCRIPTION
    The Get-VerbSynonymTDO advanced function returns the synonyms for a verb, and indicates if they are approved verbs using Get-Verb. Additionally, if the verb is approved, it will indicate the group. This advanced function relies on the thesaurus at altervista.org.
    
    Note: What it detects as 'Approved' will depend on the rev of Powershell run under (as it uses get-verb to detect ApprovedVerbs):
     - new verbs added to ps6 - Deploy(dp) & Build (bd) - will only detect if run under Ps6+

    This is a tweaked variant of Tommy Maynard's Get-TMVerbSynonym: I'd fork his source, if he had it _github/bitbucket; Unfortunately he only posts revs to PSGallery (which isn't a git-able source revision system). So we "manually fork". 
    
    This leverages the http://thesaurus.altervista.org/thesaurus/ Thesaurus API to pull synonyms for the intput vert, and then cycles each against get-verb to qualify Approved status on each option. 
    Benefit, over get-Verb is that it autoresolves your conceptual verb, against related approved verb options. 
    
    Automatically drops multi-word synonyms (unless -AllowMultiWords used), as they aren't permitted ApprovedVerbs in Powershell. 
    
    .PARAMETER Verb
    String array of verbs for which the function will find synonyms.[-verb 'Report','publish']
    .PARAMETER Key 
    This parameter requires an API key parameter value to use this function. Versions 1.2 and greater include an API key, so there's no need to register for one. 
    .PARAMETER Approved 
    This switch parameter ensures that the results are only approved verbs. 
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    System.PSCustomObject
    .EXAMPLE
    PS> PS > Get-VerbSynonymTDO -Verb Launch | Format-Table -AutoSize
 
        Verb Synonym Group Approved Notes
        ---- ------- ----- -------- -----
        Launch Abolish False Antonym
        Launch Begin False
        Launch Commence False
        Launch Displace False
        Launch Establish False
        Launch Found False
        Launch Get Common True
        Launch Get Down False
        Launch Impel False
        Launch Move Common True
        Launch Open Common True
        Launch Open Up False
        Launch Plunge False
        Launch Propel False
        Launch Set About False
        Launch Set In Motion False
        Launch Set Out False
        Launch Set Up False
        Launch Smooth False
        Launch Smoothen False
        Launch Start Lifecycle True
        Launch Start Out False
     
    This example returns all the synonyms for the verb "launch." 
    .EXAMPLE
    PS> Get-VerbSynonymTDO -Verb write,trace -verbose -Approved | ft -a 
    Run multiple verbs through, return only ApprovedVerbs
    .EXAMPLE
    PS > Get-VerbSynonymTDO -Verb Launch -Approved | Format-Table -AutoSize
 
        Verb Synonym Group Approved Notes
        ---- ------- ----- -------- -----
        Launch Get Common True
        Launch Move Common True
        Launch Open Common True
        Launch Start Lifecycle True
 
    This example returns only the synonyms for the verb "Launch" that are approved verbs. If there were no approved verbs, this example would return no results.
    .EXAMPLE
    PS> Get-VerbSynonymTDO -Verb car | Format-Table -Autosize
    
        WARNING: The word "Car" may not have any verb synonyms.
 
    This example attempts to return synonyms for the word car. Since car cannot be used as a verb, it returns a warning message. This function only works when the word supplied can be used as a verb.
 
.EXAMPLE
    PS> Get-VerbSynonymTDO -Verb exit | Sort-Object Approved -Descending | Format-Table -AutoSize
 
        Verb Synonym Group Approved Notes
        ---- ------- ----- -------- -----
        Exit Move Common True
        Exit Enter Common True Antonym
        Exit Be Born False Antonym
        Exit Pop Off False
        Exit Play False
        Exit Perish False
        Exit Pass Away False
        Exit Pass False
        Exit Leave False
        Exit Kick The Bucket False
        Exit Go Out False
        Exit Go False
        Exit Give-Up The Ghost False
        Exit Get Out False
        Exit Expire False
        Exit Drop Dead False
        Exit Die Out False Related Term
        Exit Die Off False Related Term
        Exit Die Down False Related Term
        Exit Die False
        Exit Decease False
        Exit Croak False
        Exit Conk False
        Exit Choke False
        Exit Change State False
        Exit Cash In One's Chips False
        Exit Buy The Farm False
        Exit Snuff It False
        Exit Turn False
 
    This example returns synonyms for the verb "exit," and sorts the verbs by those that are approved. At the time of writing, this example only returned two approved verbs: Move and Enter. Enter is actually an antonym, and is indicated as such in the Notes property.
     
    .LINK
    https://gist.github.com/tommymaynard/76a219efa9ff51f3c90064f04fa1b662/revisions
    https://tommymaynard.com/get-tmverbsynonym-1-4-2017/
    https://www.powershellgallery.com/packages/Get-TMVerbSynonym/1.4/Content/Get-TMVerbSynonym.ps1
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('Get-VerbSynonym','Get-TMVerbSynonym','Get-VerbSyn')]
    #[OutputType([boolean])]
    PARAM (
        [Parameter(Mandatory = $true,Position=0,ValueFromPipeline=$true,HelpMessage="String array of verbs for which the function will find synonyms.[-verb 'Report','publish']")]
            [string[]]$Verb,
        [Parameter(,HelpMessage="This parameter requires an API key parameter value to use this function. Versions 1.2 and greater include an API key, so there's no need to register for one. [-Key aaa0aaaa62aaaa0aaaaa")]
            [string]$Key = 'kVW9sY6X4zpY01aciPne',
        [Parameter(,HelpMessage="This switch parameter ensures that the results are only approved verbs. [-Approved]")]
            [switch]$Approved,
        [Parameter(,HelpMessage="This switch parameter permits multi-word synonyms (overrides default; are unsupported by Powershell). [-AllowMultiWord]")]
            [switch]$AllowMultiWord
    ) ;
    BEGIN {
        $verbose = ($VerbosePreference -eq "Continue") ; 
        # check if using Pipeline input or explicit params:
        if ($rPSCmdlet.MyInvocation.ExpectingInput) {
            $smsg = "Data received from pipeline input: '$($InputObject)'" ;
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } else {
            # doesn't actually return an obj in the echo
            #$smsg = "Data received from parameter input: '$($InputObject)'" ;
            #if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            #else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ;
          
    } ;
    PROCESS {
        #region PROCESS ; #*------v PROCESS v------
        $Error.Clear() ; 
        $ttl = $verb |  measure | select -expand count ; 
        $prcd = 0 ; 
        #region PIPELINE_PROCESSINGLOOP ; #*------v PIPELINE_PROCESSINGLOOP v------
        foreach($item in $verb) {
            $prcd++ ; 
            $smsg = $sBnrS="`n#*------v PROCESSING ($($prcd)/$($ttl)) : $($item) v------" ; 
            write-verbose $smsg ; 
            
            # Modify case: Capitalize first letter.
            $item = (Get-Culture).TextInfo.ToTitleCase($item) ; 
            # Obtain thesaurus information on verb.
            
            write-verbose "Pretest if the specified Verbs is already a known ApprovedVerb"
            If (Get-Verb -Verb $item -OutVariable TempVerbCheck) {
                $ApprovedVerb = $true ; 
                $Group = $TempVerbCheck.Group ; 
                Remove-Variable -Name TempVerbCheck ; 
                write-host -foregroundcolor green "Note: specified verb:$($item) is *already* an Approved Verb for Powershell" ; 
                [pscustomobject]@{
                    Verb = $item ; 
                    Synonym = '(self)' ; 
                    Group = $Group ; 
                    Approved = $ApprovedVerb ; 
                    Notes = $Notes ; 
                    Alias = (get-VerbAliasTDO -Verb $item -ea Continue) ;
                } | write-output ; 
            } ; 

            TRY {
                Write-Verbose -Message "Downloading thesaurus.altervista.org synonyms for $item." ; 
                [xml]$Data = (Invoke-WebRequest -Uri "http://thesaurus.altervista.org/thesaurus/v1?word=$item&language=en_US&key=$Key&output=xml" -Verbose:$false).Content ; 
            } CATCH [System.Net.WebException] {
                Write-Warning -Message "Unable to find any synonyms for $item. Please check your spelling." ; 
            } CATCH {
                Write-Warning -Message 'Unhandled error condition in PROCESS Block.' ; 
            } ;    
                
            # Check supplied verb against thesaurus.
            Write-Verbose -Message "Checking for synonoms for $item."
            If ($Data) {
                Write-Verbose -Message 'Attempting to parse synonyms list.' ; 
                
                TRY {
                    $Synonyms = ($Data.response.list | Where-Object -Property Category -eq '(verb)' | 
                        Select-Object -ExpandProperty Synonyms).Split('|') | 
                            Select-Object -Unique | Sort-Object ; 
                } CATCH [System.Management.Automation.RuntimeException] {
                    Write-Warning -Message "The word ""$item"" may not have any verb synonyms." ; 
                } CATCH {
                    Write-Warning -Message 'Unhandled error condition in Process Block.' ; 
                } ; 
                TRY {
                
                    Write-Verbose -Message 'Building results.' ; 
                    Foreach ($Synonym in $Synonyms) {
                        $Synonym = (Get-Culture).TextInfo.ToTitleCase($Synonym) ; 
                        <#
                        if($Synonym -match 'Trace|Write'){
                            write-host 'gotcha!' ;
                        }
                        #>                        
                        # Clear paraenthesis: (Antonym) and (Related Term) --> Antonym and Related Term.
                        # Write to Notes variable.
                        if ($Synonym -match '\(*\)') {
                            $Notes = $Synonym.Split('(')[-1].Replace(')','') ; 
                            $Synonym = ($Synonym.Split('(')[0]).Trim() ; 
                        } Else {
                            $Notes = $null ; 
                        } ; 
                        if (-not $AllowMultiWord -AND $Synonym -match '\s'){
                            write-verbose "skipping multi-word synonym:$($Synonym)" ; 
                            Continue ; 
                        }
                        # Determine if verb is approved.
                        If (Get-Verb -Verb $Synonym -OutVariable TempVerbCheck) {
                            $ApprovedVerb = $true ; 
                            $Group = $TempVerbCheck.Group ; 
                            Remove-Variable -Name TempVerbCheck ; 
                        } Else {
                            $ApprovedVerb = $false ; 
                            $Group = $null ; 
                        } ; 

                        # Build Objects.
                        If ($item -ne $Synonym) {
                            If ($Approved) {
                                If ($ApprovedVerb -eq $true) {
                                    [pscustomobject]@{
                                        Verb = $item ; 
                                        Synonym = $Synonym ; 
                                        Group = $Group ; 
                                        Approved = $ApprovedVerb ; 
                                        Notes = $Notes ; 
                                        Alias = if($ApprovedVserb){(get-VerbAliasTDO -Verb $Synonym -ea Continue)}else{$null} ;
                                    } | write-output ; 
                                } ; 
                            } Else {
                                [pscustomobject]@{
                                    Verb = $item ; 
                                    Synonym = $Synonym ; 
                                    Group = $Group ; 
                                    Approved = $ApprovedVerb ; 
                                    Notes = $Notes ; 
                                    Alias = if($ApprovedVerb){(get-VerbAliasTDO -Verb $Synonym -ea Continue)}else{$null} ;
                                } | write-output ; 
                            }  ; 
                        }  ;  # if-E ($item -ne $Synonym).
                    } ; # loop-E
                } CATCH [System.Management.Automation.RuntimeException] {
                    Write-Warning -Message "The word ""$item"" may not have any verb synonyms." ; 
                } CATCH {
                    Write-Warning -Message 'Unhandled error condition in Process Block.' ; 
                } ; 
            } ;
            write-verbose  $sBnrS.replace('-v','-^').replace('v-','^-') ;
        } ;  # loop-E
        #endregion PIPELINE_PROCESSINGLOOP ; #*------^ END PIPELINE_PROCESSINGLOOP ^------
    } ;  # PROC-E
    END {} ; # END-E
}

#*------^ Get-VerbSynonymTDO.ps1 ^------


#*------v get-VersionInfo.ps1 v------
function get-VersionInfo {
    <#
    .SYNOPSIS
    get-VersionInfo.ps1 - get-VersionInfo.ps1 - Extract comment-help .NOTES block into a hashtable, key-value split on colons, to provide portable metadata (for New/Update-ScriptFileInfo inputs).
    .NOTES
    Version     : 0.2.0
    Author      : Todd Kadrie
    Website     :	https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
    CreatedDate : 02/07/2019
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    AddedCredit : Based on code & concept by Alek Davis
    AddedWebsite:	https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
    AddedTwitter:
    REVISIONS
    * 3:47 PM 4/14/2020 substantially shifted role to parseHelp(), which is less brittle and less likely to fail the critical get-help call that underlies the parsing. 
    * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:36 AM 12/30/2019 added CBH .INPUTS & OUTPUTS, including description of the hashtable of key/value pairs returned, for existing CBH .NOTES block
    * added explicit -path param to get-help
    * 8:39 PM 11/21/2019 added test for returned get-help
    * 8:27 AM 11/5/2019 Todd rework: Added Path param, parsed to REVISIONS: block, & return the top rev as LastRevision key in returned object.
    * 02/07/2019 Posted version
    .DESCRIPTION
    get-VersionInfo.ps1 - Extract comment-help .NOTES block into a hashtable, key-value split on colons, to provide portable metadata (for New/Update-ScriptFileInfo inputs).
    .PARAMETER  Path
    Path to target script (defaults to $PSCommandPath)
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .INPUTS
    None
    .OUTPUTS
    Returns a hashtable of key-value pairs for each of the entries in the .NOTES CBH block in a given file. 
    .EXAMPLE
    .\get-VersionInfo
    Default process from $PSCommandPath
    .EXAMPLE
    .\get-VersionInfo -Path .\path-to\script.ps1 -verbose:$VerbosePreference
    Explicit file via -Path
    .LINK
    https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to target script (defaults to `$PSCommandPath) [-Path -Path .\path-to\script.ps1]")]
        [ValidateScript( { Test-Path $_ })]$Path,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    $Verbose = ($VerbosePreference -eq "Continue") ; 
    $notes = $null ; $notes = @{ } ;
    # Get the .NOTES section of the script header comment.
    # key difference from parseHelp is the get-help in that one, doesn't spec -path param, AT ALL, just the value: $HelpParsed = Get-Help -Full $Path.fullname, and it *works* on the same file that won't with below
    if (!$Path) {
        $Help = Get-Help -Full -path $PSCommandPath
    }
    else { $Help = Get-Help -Full -path $Path } ;
    if($Help){
        $notesLines = ($Help.alertSet.alert.Text -split '\r?\n').Trim() ;
        foreach ($line in $notesLines) {
            if (!$line) { continue } ;
            $name = $null ; $value = $null ;
            if ($line -eq 'REVISIONS') { $bRevBlock = $true ; Continue } ;
            if ($bRevBlock) {
                $notes.Add("LastRevision", "$line") ;
                break ;
            } ;
            if ($line.Contains(':')) {
                $nameValue = $null ;
                $nameValue = @() ;
                # Split line by the first colon (:) character.
                $nameValue = ($line -split ':', 2).Trim() ;
                $name = $nameValue[0] ;
                if ($name) {
                    $value = $nameValue[1] ;
                    if ($value) { $value = $value.Trim() } ;
                    if (!($notes.ContainsKey($name))) { $notes.Add($name, $value) } ;
                } ;
            } ;
        } ;
        $notes | write-output ;
    } else {
        $false | write-output ;
    } ;
}

#*------^ get-VersionInfo.ps1 ^------


#*------v import-ISEBreakPoints.ps1 v------
function import-ISEBreakPoints {
    <#
    .SYNOPSIS
    import-ISEBreakPoints - Import the 'Line' ise breakpoints previously cached to an XML file
    .NOTES
    Version     : 1.0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2020-08-25
    FileName    : import-ISEBreakPoints
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 8:28 AM 3/26/2024 chg iIseBp -> ipIseBP
    * 10:20 AM 5/11/2022 added whatif support
    * 8:58 AM 5/9/2022 err suppress: test for bps before importing (emtpy bp xml files happen)
    * 8:43 AM 8/26/2020 fixed typo $ibp[0]->$ibps[0]
    * 1:45 PM 8/25/2020 fix bug in import code ; init, added to verb-dev module
    .DESCRIPTION
    import-ISEBreakPoints - Import the 'Line' ise breakpoints previously cached to an XML file
    By default, attempts to save to the same directory as the script, but if the directory specified doesn't exist, it redirects the save to the c:\scripts dir.
    .PARAMETER PathDefault
    Default Path for export (when `$Script directory is unavailable)[-PathDefault c:\path-to\]
    .PARAMETER Script
    Path to target Script file (defaults to Current ISE Tab fullpath)[-Script c:\path-to\file.ext]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    import-ISEBreakPoints -verbose -whatif 
    Import all 'line'-type breakpoints into the current open ISE tab, from matching xml file, , with verbose output, and whatif
    .EXAMPLE
    Import-ISEBreakPoints -Script c:\path-to\script.ps1
    Import all 'line'-type breakpoints into the specified script, from matching xml file
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('ipIseBp','ipbp')]

    #[ValidateScript({Test-Path $_})]
    PARAM(
        [Parameter(HelpMessage="Default Path for Import (when `$Script directory is unavailable)[-PathDefault c:\path-to\]")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$PathDefault = 'c:\scripts',
        [Parameter(HelpMessage="Path to target Script file (defaults to Current ISE Tab fullpath)[-Script c:\path-to\file.ext]")]
        [string]$Script,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;        
        $verbose = $($VerbosePreference -eq "Continue") ;
        $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
        if(-not (test-path $cuscripts)){mkdir $CUScripts -verbose } ; 
    } ;
    PROCESS {
        # for debugging, -Script permits targeting another script *not* being currently debugged
        if ($psise){
            if($Script){
                write-verbose "`$Script:$($Script)" ; 
                if( ($tScript = (gci $Script).fullname) -AND ($psise.powershelltabs.files.fullpath -contains $tScript)){
                    write-host "-Script specified diverting target to:`n$($Script)" ;
                    $iFname = "$($Script.replace('.ps1','-ps1.xml').replace('.psm1','-psm1.xml').replace('.','-BP.'))" ;
                } else {
                    throw "-Script specified is not a valid path!`n$($Script)`n(or is not currently open in ISE)" ;
                } ;
            } elseif($psise.CurrentFile.FullPath){
                $tScript = $psise.CurrentFile.FullPath
                # array of paths to be preferred (in order)
                # - script's current path (with either -[ext]-BP or -BP suffix)
                # make firmly typed array
                $tfiles = @("$($tScript.replace('.ps1','-ps1.xml').replace('.psm1','-psm1.xml').replace('.','-BP.'))",
                    # ^current path name variant 1
                    "$($tScript.replace('ps1','xml').replace('.','-BP.'))",
                    # ^current path name variant 2
                    "$((join-path -path "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" -childpath (split-path $tScript -leaf)).replace('.ps1','-ps1.xml').replace('.psm1','-psm1.xml').replace('.','-BP.'))" ,
                    # ^CU scripts dir
                    "$((join-path -path $PathDefault -childpath (split-path $tScript -leaf)).replace('.ps1','-ps1.xml').replace('.psm1','-psm1.xml').replace('.','-BP.'))" ;
                    # ^ PathDefault dir
                ) ;     
                # loop ea, take first hit
                foreach($tf in $tfiles){
                    if($iFname = gci $tf -ea 0 | select -exp fullname ){
                        write-verbose "(`$iFname matched:$($iFname))" ; 
                        break 
                    } 
                } ;
            } else { throw "ISE has no current file open. Open a file before using this script" } ;

            if($iFname){
                write-host "*Importing BP file:$($iFname) and setting specified BP's for open file`n$($tScript)" ;
                # clear all existing bps
                if($eBP=Get-PSBreakpoint |?{$_.line -AND $_.Script -eq $tScript}){$eBP | remove-PsBreakpoint } ;

                # set bps in found .xml file
                $iBPs = Import-Clixml -path $iFname ;

                <# fundemental issue importing cross-machines, the xml stores the full path to the script at runtime
                    $iBP.script
                C:\Users\UID\Documents\WindowsPowerShell\Scripts\maintain-AzTenantGuests.ps1
                    $tscript
                C:\usr\work\o365\scripts\maintain-AzTenantGuests.ps1
                #>
                # patch over empty existing file (file w no BP's, happens)
                if($iBPs){
                    # so if they mismatch, we need to patch over the script used in the set-psbreakpoint command
                    if(  ( (split-path $iBPs[0].script) -ne (split-path $tscript) ) -AND ($psise.powershelltabs.files.fullpath -contains $tScript) ) {
                        write-verbose "Target script is pathed to different location than .XML exported`n(patching BPs to accomodate)" ; 
                        $setPs1 = $tScript ; 
                    } else {
                        # use script on 1st bp in xml
                        $setPs1 = $iBPs[0].Script ; 
                    }; 
                    if($whatif){
                        foreach($iBP in $iBPs){
                            write-host "-whatif:set-PSBreakpoint -script $($setPs1) -line $($iBP.line)"
                        } ; 
                    } else { 
                        foreach($iBP in $iBPs){$null = set-PSBreakpoint -script $setPs1 -line $iBP.line } ; 
                    } ; 
                    $smsg = "$(($iBP|measure).count) Breakpoints imported and set as per $($iFname)`n$(($iBPs|sort line|ft -a Line,Script|out-string).trim())" ;
                    if($whatif){$smsg = "-whatif:$($smsg)" }
                    write-host $smsg ; 
                } else { 
                    write-warning "EMPTY/No-BP .xml BP file for open file $($tScript)" ;                    
                }
             } else { write-warning "Missing .xml BP file for open file $($tScript)" } ;
        } else {  write-warning 'This script only functions within PS ISE, with a script file open for editing' };
    } # PROC-E
}

#*------^ import-ISEBreakPoints.ps1 ^------


#*------v import-ISEBreakPointsALL.ps1 v------
function import-ISEBreakPointsALL {
    <#
    .SYNOPSIS
    import-ISEBreakPointsALL - Loop open tabs in ISE, and foreach: Import all 'Line' ise breakpoints from assoc'd XML file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : import-ISEBreakPointsALL
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 8:28 AM 3/26/2024 chg iIseBpAll -> ipIseBpAll
    * 1:21 PM 2/28/2024 add ipbpAll alias
    * 12:23 PM 5/23/2022 added try/catch: failed out hard on Untitled.ps1's
    * 9:19 AM 5/20/2022 add: iIseBpAll alias (using these a lot lately; w freq crashouts of ise, and need to recover all files open & BPs to quickly get back to function)
    * 1:58 PM 5/16/2022 rem'd whatif (not supported in child func)
    * 12:16 PM 5/11/2022 init
    .DESCRIPTION
    import-ISEBreakPointsALL - Loop open tabs in ISE, and foreach: Import all 'Line' ise breakpoints from assoc'd XML file
    Quick bulk import, when ISE ineveitbly stops properly echo'ing variable values to terminal (and need to close and re-open all open files, with BPs intact)
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    import-ISEBreakPointsALL -verbose -whatif
    Export all 'line'-type breakpoints for all current open ISE tabs, to matching xml files, with verbose & whatif
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('ipIseBpAll','ipbpAll')]
    PARAM(
        #[Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        #[switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue") ;
        $sBnr="#*======v $($CmdletName): v======" ; 
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
    }
    PROCESS {
        if ($psise){
            write-host "Exporting PSBreakPoints for ALL TABS of currently open ISE"
            $allISEScripts = $psise.powershelltabs.files.fullpath ;
            foreach($ISES in $allISEScripts){
                $sBnrS="`n#*------v PROCESSING : $($ISES) v------" ; 
                write-host -foregroundcolor white "$((get-date).ToString('HH:mm:ss')):$($sBnrS)" ;
                write-host "==importing $($ISES):" ;
                $pltEISEBP=@{Script= $ISES ;verbose=$($verbose) ; } ; # whatif=$($whatif) ;
                $smsg  = "import-ISEBreakPoints w`n$(($pltEISEBP|out-string).trim())" ;
                write-verbose $smsg ;
                try{
                    import-ISEBreakPoints @pltEISEBP ;
                } catch {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    CONTINUE ; 
                } ; 
                write-host -foregroundcolor white "$((get-date).ToString('HH:mm:ss')):$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            } ;
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    } ;
}

#*------^ import-ISEBreakPointsALL.ps1 ^------


#*------v import-ISEConsoleColors.ps1 v------
Function import-ISEConsoleColors {
    <#
    .SYNOPSIS
    import-ISEConsoleColors - Import stored $psise.options from a "`$(split-path $profile)\IseColors-XXX.csv" file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-03-17
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Copyright   : 
    Github      : https://github.com/tostka
    Tags        : Powershell,ExchangeOnline,Exchange,RemotePowershell,Connection,MFA
    REVISIONS   :
    * 12:44 PM 6/2/2022 removed spurious }
    * 7:29 AM 3/17/2021 init
    .DESCRIPTION
    import-ISEConsoleColors - Import stored $psise.options from a "`$(split-path $profile)\IseColors-XXX.csv" file
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    import-ISEConsoleColors;
    .LINK
    https://github.com/tostka/verb-IO
    #>
    
    [CmdletBinding()]
    Param() 
    $verbose = ($VerbosePreference -eq "Continue") ; 
    switch($host.name){
        "Windows PowerShell ISE Host" {
            ##$psISE.Options.RestoreDefaultTokenColors()
            <#$sFileTag=Read-Host "Enter 'Name' for saved color scheme" ;
            $ofile = "$(split-path $profile)\IseColors-$($sFileTag).csv" ; 
            write-host -fore green "Saving current Colors & Fonts to file: $($ofile)" ; 
            $psise.options | Select ConsolePane*,Font* | Export-CSV "$($ofile)" ;
            #>
            #$ifile = "$(split-path $profile)\IseColorsDefault.csv" ; 
            get-childitem  "$(split-path $profile)\IseColors*.csv" | out-gridview -Title "Pick IseColors-XXX.csv file of Font/Color settings to be imported into ISE:" -passthru | foreach-object {
                $ifile = $_.fullname ; 
                if(test-path $ifile){
                    (import-csv $ifile ).psobject.properties | foreach { $psise.options.$($_.name) = $_.Value} ; 
                } else { 
                    throw "Missing $($ifile), skipping import-ISEConsoleColors.ps1`nCan be created via:`n`$psise.options | Select ConsolePane*,Font* | Export-CSV '`$(split-path $profile)\IseColorsDefault.csv'"
                } ;
            } ;
        } 
        "ConsoleHost" {
            #[console]::ResetColor()  # reset console colorscheme to default
            throw "This command is intended to import ISE settings (`$psie.options object). PS `$host is not supported" ; 
        }
        default {
            write-warning "Unrecognized `$Host.name:$($Host.name), skipping $($MyInvocation.MyCommand.Name)" ; 
        } ; 
    } ; 
}

#*------^ import-ISEConsoleColors.ps1 ^------


#*------v import-ISEOpenFiles.ps1 v------
function import-ISEOpenFiles {
    <#
    .SYNOPSIS
    import-ISEOpenFiles - Import/Re-Open a list of all ISE tab files, from CU Documents\WindowsPowershell\Scripts\ISESavedSession.psXML file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : import-ISEOpenFiles
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 9:06 PM 8/12/2025 added code to create CUScripts if missing
    * 8:30 AM 3/26/2024 chg iIseOpen -> ipIseOpen
    * 3:31 PM 1/17/2024 typo fix: lacking $ on () (dumping $ISES obj into pipeline/console)
    * 1:20 PM 3/27/2023 bugfix: coerce $txmlf into [system.io.fileinfo], to make it match $fileinfo's type.
    * 9:35 AM 3/8/2023 added -filepath (with pipeline support), explicit pathed file support (to pipeline in from get-IseOpenFilesExported()).
    * 3:28 PM 6/23/2022 add -Tag param to permit running interger-suffixed variants (ie. mult ise sessions open & stored from same desktop). 
    * 9:19 AM 5/20/2022 add: iIseOpen alias (using these a lot lately; w freq crashouts of ise, and need to recover all files open & BPs to quickly get back to function)
    * 12:12 PM 5/11/2022 init
    .DESCRIPTION
    import-ISEOpenFiles - Import/Re-Open a list of all ISE tab files, from CU Documents\WindowsPowershell\Scripts\ISESavedSession.psXML file
    Quick bulk dump, when ISE ineveitbly stops properly echo'ing variable values to terminal (and need to close and re-open all open files)
    .PARAMETER Tag
    Optional Tag to apply to as filename suffix[-tag 'label']
    .PARAMETER FilePath
    Optional FullName path to prior export-ISEOpenFiles pass[-FilePath `$env:userprofile\Documents\WindowsPowershell\Scripts\ISESavedSession-DEV.psXML
    .EXAMPLE
    PS> import-ISEOpenFiles -verbose
    Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif
    .EXAMPLE
    PS> import-ISEOpenFiles -Tag 2 -verbose  
    Export with Tag '2' applied to filename (e.g. "ISESavedSession2.psXML")
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('ipIseOpen')]
    PARAM(
        [Parameter(Position=0,HelpMessage="Optional Tag to apply to filename[-Tag MFA]")]
        [string]$Tag,
        [Parameter(ValueFromPipeline = $True, HelpMessage="Optional FullName path to prior export-ISEOpenFiles pass[-FilePath `$env:userprofile\Documents\WindowsPowershell\Scripts\ISESavedSession-DEV.psXML]")]
        [system.io.fileinfo[]]$FilePath 
    ) ;

    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
    }
    PROCESS {
        if ($psise){
            if(-not $FilePath){
                #$AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;
                $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
                if(-not (test-path $cuscripts)){mkdir $CUScripts -verbose } ; 
                if($Tag){
                    [array]$txmlf = @( [system.io.fileinfo](join-path -path $CUScripts -ChildPath "ISESavedSession-$($Tag).psXML") ) ;
                } else { 
                    [array]$txmlf = @( [system.io.fileinfo](join-path -path $CUScripts -ChildPath 'ISESavedSession.psXML') ) ;
                } ; 
                #$allISEScripts = $psise.powershelltabs.files.fullpath ;
            } else { 
                foreach($item in $FilePath){
                    [array]$txmlf = @() ; 
                    if($txmlf += @(get-childitem -path $item.fullname -ea continue)){
                        $smsg = "(found specified -FilePath file)" ; 
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    } else { 
                        $smsg = "Unable to locate specified -FilePath:" ; 
                        $smsg += "`n$($item.fullname)" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    } ; 
                } ; 
            } ; 
            $error.clear() ;
            TRY {
                foreach($file in $txmlf){
                    $smsg = "==$($file.fullname)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    $allISEScripts = import-Clixml -Path $file.fullname ;
                    $smsg = "Opening $($allISEScripts| measure | select -expand count) files" ; 
                    write-verbose $smsg ; 
                    if($allISEScripts){
                        foreach($ISES in $allISEScripts){
                            if($psise.powershelltabs.files.fullpath -contains $ISES){
                                write-host "$($ISES) is already OPEN in Current ISE tab list (skipping)" ;
                            } else {
                                if(test-path $ISES){
                                    <# #New tab & open in new tab: - no we want them all in one tab
                                    write-verbose "(adding tab, opening:$($ISES))"
                                    $tab = $psISE.PowerShellTabs.Add() ;
                                    $tab.Files.Add($ISES) ;
                                    #>
                                    #open in current tab
                                    write-verbose "(opening:$($ISES))"
                                    $psISE.CurrentPowerShellTab.Files.Add($ISES) ;  ;
                                } else {  write-warning "Unable to Open missing orig file:`n$($ISES)" };
                            } ;
                        }; # loop-E
                    } ; 
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                write-warning $smsg ;
                $smsg = $ErrTrapd.Exception.Message ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }
                else{ write-WARNING $smsg } ;
                BREAK ;
                Continue ; #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}

#*------^ import-ISEOpenFiles.ps1 ^------


#*------v import-OpenNotepads.ps1 v------
function import-OpenNotepads {
    <#
    .SYNOPSIS
     import-OpenNotepads - Import & open a previously-exported list of  Notepad* variant (notepad2/3 curr) sessions
    .NOTES
    Version     : 1.0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2025-07-02
    FileName    : import-OpenNotepads.ps1
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 2:21 PM 7/2/2025 works init
    .DESCRIPTION
    import-OpenNotepads - Import & open a previously-exported list of  Notepad* variant (notepad2/3 curr) sessions
    .PARAMETER File
    Path to an exported .psxml file reflecting previously opened Notepad* variant windows & documents, to be reopened.
    .PARAMETER Tag
    Variant to specify targeting a Tag (filename suffix - portion after the std 'NotePdSavedSession-' of filename, wo .psxml extension, which by default is a timestamp, if no export -Tag was specified)[-tag 'label']
    .EXAMPLE
    PS> import-opennotepads -File 'C:\Users\kadrits\OneDrive - The Toro Company\Documents\WindowsPowershell\Scripts\data\NotePdSavedSession-20250702-1120AM.psXML' -verbose
    Demo using a full path specification to the target import file
    .EXAMPLE
    PS> import-opennotepads -Tag '20250702-1120AM'   -verbose
    Demo targeting an exported file based on the trailing Tag suffix
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('ipNpOpen')]

    #[ValidateScript({Test-Path $_})]
    PARAM(
        [Parameter(Mandatory = $False, Position = 0, ValueFromPipeline = $True, HelpMessage = 'File paths[-path c:\pathto\file.ext]')]
            [Alias('PsPath')]
            #[ValidateScript({Test-Path $_ -PathType 'Container'})]
            #[System.IO.DirectoryInfo[]]$File,
            [ValidateScript({ Test-Path $_ })]
            [system.io.fileinfo[]]$File,
            #[string[]]$File
        [Parameter(Position=0,HelpMessage="Variant to specify targeting a Tag (filename suffix - portion after the std 'NotePdSavedSession-' of filename, wo .psxml extension, which by default is a timestamp, if no export -Tag was specified)[-tag 'label']")]
            [string]$Tag,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
            [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue") ;
        $prPS = 'Name', 'Id', 'Path', 'Description', 'MainWindowHandle', 'MainWindowTitle', 'ProcessName', 'StartTime', 'ExitCode', 'HasExited', 'ExitTime' ;
        $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
        # CREATE new WindowsPowershell\Scripts\data folder if nonexist, use it to park data .xml & jsons etc for script processing/output (should prob shift the ise export/import code to use it)
        $npExpDir = join-path -path $CUScripts -ChildPath 'data' ;
        if (-not(test-path $npExpDir)) {
            mkdir $npExpDir -verbose ;
        }

        if ($Tag) {
            $txmlf = join-path -path $npExpDir -ChildPath "NotePdSavedSession-$($Tag).psXML" ;
        } elseif($File) {
            if ($File -match '\\|\/'){
                write-verbose "File appears to be fully pathed (has /\ chars)"
                $txmlf = $File ;
            } ;
            }else{
                write-verbose "unpathed -File, building target default path"
                $txmlf = join-path -path $npExpDir -ChildPath $File ;
            }

    } ;
    PROCESS {
        # for debugging, -Script permits targeting another script *not* being currently debugged


            if($txmlf){
                write-host "*Importing exported file:$($txmlf) and setting specified files for open file`n$($tScript)" ;
                
                # set apps & files in found .xml file
                $ipFiles = Import-Clixml -path $txmlf ;

                # patch over empty existing file (file w no specs, happens)
                if($ipFiles){


                    if($whatif){
                        foreach($ipFile in $ipFiles){
                            write-host "-whatif:set-PSBreakpoint -script $($setPs1) -line $($ipFile.line)"
                        } ;
                    } else {
                        foreach($ipFile in $ipFiles){
                            #$null = set-PSBreakpoint -script $setPs1 -line $ipFile.line ;
                            # $process = start-process ping.exe -windowstyle Hidden -ArgumentList "-n 1 -w 127.0.0.1" -PassThru –Wait ;
                            # $process.ExitCode
                            $pltSaPS = [ordered]@{
                                FilePath = $null ;
                                ArgumentList = $null ;
                                PassThru = $true
                            } ;
                            if($ipFile.Path){$pltSaPS.FilePath = $ipFile.Path }else{throw "missing FilePath!"} 
                            if($ipFile.FilePath){$pltSaPS.ArgumentList = $ipFile.FilePath }else{throw "missing notepad app Path!"}
                            $smsg = "start-process w`n$(($pltSaPS|out-string).trim())" ; 
                            write-verbose $smsg ; 
                            TRY{
                                $process = start-process @pltSaPS ;
                            } CATCH {
                                $ErrTrapd=$Error[0] ;
                                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                                write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                            } ;
                            write-verbose  "$($pltSaPS.Path ) $($pltSaPS.FilePath): $(($process.ExitCode|out-string).trim())" ;
                        } ;
                    } ;
                    $smsg = "$(($ipFile|measure).count) Files restored per $($txmlf)`n$(($ipFiles|sort line|ft -a Path,FilePath|out-string).trim())" ;
                    if($whatif){$smsg = "-whatif:$($smsg)" }
                    write-host $smsg ;
                } else {
                    write-warning "EMPTY/Spec .xml file for reopening" ;
                }
             } else { write-warning "Missing .xml exported file for open file $($tScript)" } ;

    } # PROC-E
}

#*------^ import-OpenNotepads.ps1 ^------


#*------v Initialize-ModuleFingerprint.ps1 v------
function Initialize-ModuleFingerprint {
    <#
    .SYNOPSIS
    Initialize-ModuleFingerprint.ps1 - Profile a specified module and summarize commands into a semantic-version 'fingerprint'.
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-10-09
    FileName    : 
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : Kevin Marquette
    AddedWebsite: https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/
    AddedTwitter: 
    REVISIONS
    * 11:02 AM 1/15/2024 had various fundemental breaks - looks like was mid-revision, and not finished, and this isn't routinely used outside of new mods (or on processbuilk... when not-preexisting .ps1): Fixes:
        - fixed $moddir.FullName -> $moddir ; 
        - researched it's use: it's not used in step-moduleversioncalculated (which has it's own copy of the logic), is used in uwps\processbulk-NewModule.ps1, not breaking anything cuz running on existing fingerprint files
        - pulled in undefined varis from other calling scripts: $moddir, $modroot, if not defined; hard break in #187: $psd1MBasename (was using .psm1 rplc for a .psd1 file) ; 
        - fixed all $psd1m.fullname -> $psd1m ; added results test to the gcm -module block (break had no cmds comming back); fixed catch block w-w -fore use ; 
    * 2:29 PM 5/16/2022 add: backup-fileTDO of the fingerprintfile
    * 9:58 AM 10/26/2021 updated all echos, wh, ww, wv's with wlts's, updated KM logic to match step-ModuleVersionCalculated's latest
    * 6:11 PM 10/15/2021 rem'd # raa, replaced psd1/psm1-location code with Get-PSModuleFile(), which is a variant of BuildHelpers get-psModuleManifest. 
    * 12:36 PM 10/13/2021 added else block to catch mods with inconsistent names between root dir, and .psm1 file, (or even .psm1 location); upgraded catchblock to curr std; added splats and verbose echos for debugging outlier processing errors
    * 7:41 PM 10/11/2021 cleaned up rem'd requires
    * 9:08 PM 10/9/2021 init version
    .DESCRIPTION
    Initialize-ModuleFingerprint.ps1 - Profile a specified module and summarize commands into a semantic-version 'fingerprint'.
    Rounded out the sample logic KM posted on the above site, along with matching processing function: Step-ModuleVersionCalculated
    .PARAMETER Path
    Path to .psm1-hosting directory of the Module[-path 'C:\sc\PowerShell-Statistics\Statistics' ]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    .EXAMPLE
    PS> Initialize-ModuleFingerprint -path 'C:\sc\Get-MediaInfo' -whatif -verbose ;
    Fingerprint the specified module path, with whatif and verbose specified
    .EXAMPLE
    $whatif = $true ;
    foreach($mod in $mods){
        if(test-path "$($mod)\fingerprint"){write-host -fore green "---`nPRESENT:$($mod)\fingerprint`n```" }
        else {Initialize-ModuleFingerprint -path $mod -whatif:$($whatif) -verbose} ;
    } ;
    Sample code to process list of module root directory paths and initialize fingerprints in the dirs currently lacking the files.
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/
    #>
    ##Requires -RunasAdministrator
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("USEA","GBMK","AUSYD")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)][ValidateCount(1,3)]
    [CmdletBinding()]
    ###[Alias('Alias','Alias2')]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to .psd1-hosting directory of the Module[-path 'C:\sc\PowerShell-Statistics\Statistics' ]")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$Path,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN { 
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;

        $sBnr="#*======v RUNNING :$($CmdletName):$($Path) v======" ; 
        $smsg = "$($sBnr)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

        # Get parameters this function was invoked with
        #$PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
        
    } ;  # BEGIN-E
    PROCESS {
        $error.clear() ;
        TRY {
            $smsg = "profiling existing content..."
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        
            if( ($path -like 'BounShell') -OR ($path -like 'VERB-transcript')){
                write-verbose "GOTCHA!" ;
            } ; 

            <# 9:58 AM 1/15/2024 below is using undefined locally $moddir.FullName; clearly it should be $path, which is a string, if we're calling it from publish-ModuleLocalFork, should use that funcs inputs resolution:
                $ModRoot = $path ; 
                $moddir = (gi -Path $path).FullName;
                $moddirfiles = gci -path $moddir -recur ;
                But it's a core piece of verb-dev\Public\Step-ModuleVersionCalculated.ps1
                No it's not, the func has internalized the logic from this:
                #695: # KM's core logic code:
                    $fingerprint = foreach ( $command in $commandList ){

                but sc\powershell\PSScripts\processbulk-NewModule.ps1 *does* run it, at line 
                #391: $pltInitModFngr=[ordered]@{Path=$ModRoot ;Verbose = ($VerbosePreference -eq 'Continue');} ;
                            $smsg = "Initialize-ModuleFingerprint w`n$(($pltInitModFngr|out-string).trim())" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                            Initialize-ModuleFingerprint @pltInitModFngr ;
                            $hasFingerprint = [boolean](test-path (join-path -path $ModRoot -childpath 'fingerprint'))

                    it's underlying 
                    #185: $scRoot = 'c:\sc\' ; 
                    #260: $modroot= join-path -path $scRoot -child $ModuleName ;

                    below is also stocking $moddirfiles TWICE
                    $moddirfiles = gci @pltGCI ;
                    $moddirfiles = gci -path $path -recur 
                    # 1st block must be roughed in not completed, rem it out
                #>
                # test and force
                if(-not $moddir -AND $path){
                    $moddir = (gi -Path $path).FullName;
                    if(-not $modroot){$modroot= $path} ; 

                }

            $pltXMO=@{Name=$null ; force=$true ; ErrorAction='STOP'} ;
            <#
            $pltGCI=[ordered]@{path=$moddir ;recurse=$true ; ErrorAction='STOP'} ;
            $smsg =  "gci w`n$(($pltGCI|out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            
            $moddirfiles = gci @pltGCI ;
            #>

            $Path = (Resolve-Path $Path).Path ; 
            $moddirfiles = gci -path $path -recur 
            # using an undefined $modname below as well, resolve it from split path
            if(-not $modname){
                $modname = split-path $Path -leaf ;
            } ;
            #-=-=-=-=-=-=-=-=
            if(-not (gcm Get-PSModuleFile -ea 0)){
                function Get-PSModuleFile {
                    [CmdletBinding()]
                    PARAM(
                        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to project root. Defaults to the current working path [-path 'C:\sc\PowerShell-Statistics\']")]
                        [ValidateScript({Test-Path $_ -PathType 'Container'})]
                        [string]$Path = $PWD.Path,
                        [Parameter(HelpMessage="Specify Module file type: Module .psm1 file or Manifest .psd1 file (psd1|psm1 - defaults psd1)[-Extension .psm1]")]
                        [ValidateSet('.psd1','.psm1','both')]
                        [string] $Extension='.psd1'
                    ) ;

                    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
                    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
                    $sBnr="#*======v RUNNING :$($CmdletName):$($Extension):$($Path) v======" ; 
                    $smsg = "$($sBnr)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                    if($Extension -eq 'Both'){
                        [array]$Exts = '.psd1','.psm1'
                        $smsg =  "(-extension Both specified: Running both:$($Exts -join ','))" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    } else {
                        $Exts = $Extension ; 
                    } ; 
                    $Path = ( Resolve-Path $Path ).Path ; 
                    $CurrentFolder = Split-Path $Path -Leaf ;
                    $ExpectedPath = Join-Path -Path $Path -ChildPath $CurrentFolder ;
        
                    foreach($ext in $Exts){
                        $ExpectedFile = Join-Path -Path $ExpectedPath -ChildPath "$CurrentFolder$($ext)" ;
                        if(Test-Path $ExpectedFile){$ExpectedFile  } 
                        else {
                            # Look for properly organized modules (name\name.ps(d|m)1)
                            $ProjectPaths = Get-ChildItem $Path -Directory |
                                ForEach-Object {
                                    $ThisFolder = $_ ;
                                    $smsg =  "checking:$($ThisFolder)" ; 
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                    $ExpectedFile = Join-Path -path $ThisFolder.FullName -child "$($ThisFolder.Name)$($ext)" ;
                                    If( Test-Path $ExpectedFile) {$ExpectedFile  } ;
                                } ;
                            if( @($ProjectPaths).Count -gt 1 ){
                                $smsg = "Found more than one project path via subfolders with psd1 files" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $ProjectPaths  ;
                            } elseif( @($ProjectPaths).Count -eq 1 )  {$ProjectPaths  } 
                            elseif( Test-Path "$ExpectedPath$($ext)" ) {
                                $smsg =  "`$ExpectedPath:$($ExpectedPath)" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                #PSD1 in root of project - ick, but happens.
                                "$ExpectedPath$($ext)"  ;
                            } elseif( Get-Item "$Path\S*rc*\*$($ext)" -OutVariable SourceFiles)  {
                                # PSD1 in Source or Src folder
                                If ( $SourceFiles.Count -gt 1 ) {
                                    $smsg = "Found more than one project $($ext) file in the Source folder" ;
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                } ;
                                $SourceFiles.FullName ;
                            } else {
                                $smsg = "Could not find a PowerShell module $($ext) file from $($Path)" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            } ;
                        } ;
                    } ; 
                    $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                }
                ##-=-=-=-=-=-=-=-=
            }

            $psd1M = Get-PSModuleFile -path $Path -ext .psd1 -verbose:$($VerbosePreference -eq 'Continue');
            $psm1 = Get-PSModuleFile -path $Path -ext .psm1 -verbose:$($VerbosePreference -eq 'Continue' ); 
            # 10:31 AM 1/15/2024 got some fullname refs, above are coming back as strings, no fullname property: fix

            if($psd1M){
                if($psd1M -is [system.array]){
                    throw "`$psd1M resolved to multiple .psm1 files in the module tree!" ; 
                } ; 
                # regardless of root dir name, the .psm1 name *is* the name of the module, use it for ipmo/rmo's
                #$psd1MBasename = ((split-path $psd1M -leaf).replace('.psm1','')) ; # this isn't going to work, it's a .psd1 path, and we're rplacing .psm1!
                $psd1MBasename = ((split-path $psd1M -leaf).replace('.psd1','')) ; # this isn't going to work, it's a .psd1 path, and we're rplacing .psm1!
                if($modname -ne $psd1MBasename){
                    $smsg = "Module has non-standard root-dir name`n$($moddir)"
                    $smsg += "`ncorrecting `$modname variable to use *actual* .psm1 basename:$($psd1MBasename)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    $modname = $psd1MBasename ; 
                } ; 
                $pltXMO.Name = $psd1M # load via full path to .psm1
                $smsg =  "import-module w`n$(($pltXMO|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                import-module @pltXMO ;
                # ipmo works on full .psd1 name, but gcm doesn't, so if then the results
                if(-not ($commandList = Get-Command -Module $modname)){
                    $smsg = "get-command -module $($modname.replace('.psd1','')) FAILED to return a list of commands!"
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; ]
                    throw $smsg ;
                    BREAK ; 
                } ;
                $pltXMO.Name = $psd1MBasename ; # have to rmo using *basename*
                $smsg =  "remove-module w`n$(($pltXMO|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                remove-module @pltXMO ;

                $smsg = "Calculating fingerprint"
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                # KM's core logic code:
                $fingerprint = foreach ( $command in $commandList ){
                    $smsg = "(=cmd:$($command)...)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    foreach ( $parameter in $command.parameters.keys ){
                        $smsg = "(---param:$($parameter)...)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        '{0}:{1}' -f $command.name, $command.parameters[$parameter].Name
                        $command.parameters[$parameter].aliases | 
                            Foreach-Object { '{0}:{1}' -f $command.name, $_}
                    };  
                } ;   

            } else {
                throw "No module .psm1 file found in `$path:`n$(join-path -path $moddir -child "$modname.psm1")" ;
            } ;  
  
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #-=-record a STATUSWARN=-=-=-=-=-=-=
            $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
            if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
            if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
            #-=-=-=-=-=-=-=-=
            $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
            else{ write-warning  "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
        } ; 
    } ;  # PROC-E
    END {
        if ( $fingerprint ){
            
            <# fingerprint is the diff, not the $oldfingprint file (which is used in step-moduleversioncalculated())
            write-verbose "(backup-FileTDO -path $($fingerprint))" ;
            $fingerprintBU = backup-FileTDO -path $fingerprint -showdebug:$($showdebug) -whatif:$($whatif) ;
            if (!$fingerprintBU) {throw "FAILURE" } ;
            #> 

            $pltOFile=[ordered]@{Encoding='utf8' ;FilePath=(join-path -path $moddir -childpath 'fingerprint') ;whatif=$($whatif) ;} ; 

            if(test-path $pltOFile.FilePath){
                write-verbose "(backup-FileTDO -path $($pltOFile.FilePath))" ;
                $fingerprintBU = backup-FileTDO -path $pltOFile.FilePath -showdebug:$($showdebug) -whatif:$($whatif) ;
                if(-not $FingerprintBU -AND -not $whatif){throw "backup-FileTDO -Source $($pltOFile.FilePath)!" }
            } else { 
                write-verbose "(no old fingerprint file to backup)" ;  
            } ;  

            write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Out-File w`n$(($pltOFile|out-string).trim())" ; 
            $fingerprint | out-file @pltOFile ; 
        } else {
            $smsg = "No funtional Module `$fingerprint generated for path specified`n$($Path)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ; 
        $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;  # END-E
}

#*------^ Initialize-ModuleFingerprint.ps1 ^------


#*------v Initialize-PSModuleDirectories.ps1 v------
Function Initialize-PSModuleDirectories {
    <#
    .SYNOPSIS
    Initialize-PSModuleDirectories.ps1 - Initialize PS Module Directories
    .NOTES
    Version     : 3.4.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-04-26
    FileName    : Initialize-PSModuleDirectories.ps1
    License     : (None Asserted)
    Copyright   : (None Asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell, development, Module
    AddedCredit : Jeff Hicks
    AddedWebsite: https://www.powershellgallery.com/packages/ISEScriptingGeek/3.4.1
    AddedTwitter: 
    REVISIONS
    * 12:23 PM 8/7/2024 removed erroneous [ValidateScript( {Test-Path $_})] from $DefaultModDirs param
    * 12:18 PM 10/12/2023 correct .\Resources -> Resource that's in use 
    * 11:21 AM 10/3/2023 added LICENSES & LIBS & RESOURCES to DefaultModDirs
   * 9:35 AM 5/9/2022 init, split out from merge/unmerge-module, have a single maintainable func, rather than trying to sync the variants
    .DESCRIPTION
    Initialize-PSModuleDirectories.ps1 - Initialize PS Module Directories
    DEFAULT - DIRS CREATION - git doesn't reproduce empty dirs, create if empty (avoids errors later)
    exempt the .git & .vscode dirs, we don't publish those to modules dir
    .PARAMETER ModuleSourcePath
    Array of directory paths containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]
    ModuleDestinationPath
    Directory path in which the final .psm1 file should be constructed [-ModuleDestinationPath c:\path-to\module\module.psm1]
    DefaultModDirs
    Array of new module subdirectory names to be created
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    $pltInitPsMDirs=[ordered]@{
        ModuleSourcePath=$ModuleSourcePath ;
        ModuleDestinationPath=$ModuleDestinationPath ;
        ErrorAction="Stop" ;
        whatif=$($whatif);
    } ;
    $smsg= "Initialize-PSModuleDirectories w`n$(($pltInitPsMDirs|out-string).trim())" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    TRY {
        $sRet = Initialize-PSModuleDirectories @pltInitPsMDirs ;
        if(sRet.split(';') -contains "new-item:ERROR"){
            $smsg = "Initialize-PSModuleDirectories:new-item:ERROR!"  ;
            write-warning $smsg ; 
            throw $smsg ;
        } ; 
    } CATCH {
        $PassStatus += ";ERROR";
        write-warning  "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        Exit ;
    } ;
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "Array of directory paths containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]")]
            [array] $ModuleSourcePath,
            [Parameter(Mandatory = $True, HelpMessage = "Directory path in which the final .psm1 file should be constructed [-ModuleDestinationPath c:\path-to\module\module.psm1]")]
        [string] $ModuleDestinationPath,
        [Parameter(HelpMessage = "Array of new module subdirectory names to be created")]
            [string[]]$DefaultModDirs = @('Public','Internal','Classes','Libs','Tests','Licenses','Resource','Docs','Docs\Cab','Docs\en-US','Docs\Markdown'),
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
            [switch] $whatIf
    )
    BEGIN { 
        #region CONSTANTS-AND-ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        write-verbose  "`$PSBoundParameters:`n$(($PSBoundParameters|out-string).trim())" ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
        
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ; 
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ; 
            write-verbose "(non-pipeline - param - input)" ; 
        } ; 

    } ;  # BEGIN-E
    PROCESS {
        $Error.Clear() ; 
        # call func with $PSBoundParameters and an extra (includes Verbose)
        #call-somefunc @PSBoundParameters -anotherParam
        
        # - Pipeline support will iterate the entire PROCESS{} BLOCK, with the bound - $array - 
        #   param, iterated as $array=[pipe element n] through the entire inbound stack. 
        # $_ within PROCESS{}  is also the pipeline element (though it's safer to declare and foreach a bound $array param).
        
        # - foreach() below alternatively handles _named parameter_ calls: -array $objectArray
        # which, when a pipeline input is in use, means the foreach only iterates *once* per 
        #   Process{} iteration (as process only brings in a single element of the pipe per pass) 
        
        foreach($Dir in $DefaultModDirs){
            
            # put your real processing in here, and assume everything that needs to happen per loop pass is within this section.
            # that way every pipeline or named variable param item passed will be processed through. 
            $tPath = join-path -path $ModuleRootPath -ChildPath $Dir ;
            if(-not (test-path -path $tPath)){
                $pltDir = [ordered]@{
                    path     = $tPath ;
                    ItemType = "Directory" ;
                    ErrorAction="Stop" ;
                    whatif   = $($whatif) ;
                } ;
                $smsg = "Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $error.clear() ;
                $bRetry=$false ;
                TRY {
                    new-item @pltDir | out-null ;
                    $PassStatus += ";new-item:UPDATED";
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $PassStatus += ";new-item:ERROR";
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" }
                    $bRetry=$true ;
                } ;
                if($bRetry){
                    $pltDir.add('force',$true) ;
                    $smsg = "Retry:FORCE:Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $error.clear() ;
                    TRY {
                        new-item @pltDir | out-null ;
                        $PassStatus += ";new-item:UPDATED";
                    } CATCH {
                        $ErrorTrapped = $Error[0] ;
                        $PassStatus += ";new-item:ERROR";
                        $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $bRetry=$false ;
                        EXIT #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
                    } ;
                } ;
            } ;
        } ;  # loop-E

    } ;  # PROC-E
    END {
        #$stopResults = try {Stop-transcript -ErrorAction stop} catch {} ;
        #write-host $stopResults ; 
        # the $PassStatus updates should have been global, but if not, return what we have and post-test for ";new-item:ERROR"; V ";new-item:UPDATED";
        $PassStatus | write-output ; 
    } ;  # END-E
}

#*------^ Initialize-PSModuleDirectories.ps1 ^------


#*------v move-ISEBreakPoints.ps1 v------
function move-ISEBreakPoints {
    <#
    .SYNOPSIS
    move-ISEBreakPoints - Offset current ISE tab's existing breakpoints by lines specified
    .NOTES
    Version     : 1.0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2020-08-25
    FileName    : move-ISEBreakPoints
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 3:29 PM 12/4/2023 new alias using proper std suffix for move == 'm': mIseBP. Technically it should be mbp (like sbp), but that's too short to be safe; too likely to accidentlaly trigger on console.
    * 3:05 PM 9/7/2022 ren & alias orig name shift-ISEBreakPoints -> move-ISEBreakPoints
    * 10:49 AM 8/25/2020 init, added to verb-dev module
    .DESCRIPTION
    move-ISEBreakPoints - Offset current ISE tab's existing breakpoints by lines specified
    .PARAMETER PathDefault
    Default Path for export (when `$Script directory is unavailable)[-PathDefault c:\path-to\]
    .EXAMPLE
    move-ISEBreakPoints -lines -4
    Shift all existing PSBreakpoints UP 4 lines
    .EXAMPLE
    move-ISEBreakPoints -lines 5
    Shift all existing PSBreakpoints DOWN 5 lines
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('sIseBp','shift-ISEBreakPoints','mIseBp')]
    PARAM(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter lines +/- to shift breakpoints on current script[-lines -3]")]
        [int]$lines
    ) ;
    BEGIN {} ;
    PROCESS {
        if ($psise -AND $psise.CurrentFile.FullPath){
            
            $eBPs = get-psbreakpoint -Script $psise.CurrentFile.fullpath ; 
            # older, mandetory param prompts instead
            #$lines=Read-Host "Enter lines +/- to shift breakpoints on current script:($($psise.CurrentFile.displayname))" ;
            foreach($eBP in $eBPs){
              remove-psbreakpoint -id $eBP.id ; 
              set-PSBreakpoint -script $eBP.script -line ($eBP.line + $lines) ; 
            } ; 
            
        } else {  write-warning 'This script only functions within PS ISE, with a script file open for editing' };

     } # PROC-E
}

#*------^ move-ISEBreakPoints.ps1 ^------


#*------v new-CBH.ps1 v------
function new-CBH {
    <#
    .SYNOPSIS
    new-CBH - Parse Script and prepend new Comment-based-Help keyed to existing contents
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 3:45 PM 11/16/2019
    FileName    :
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,Development,Scripts
    REVISIONS
    * 11:38 AM 4/14/2020 flipped filename from fullname to name
    * 4:42 PM 4/9/2020 ren NewCBH-> new-CBH shift into verb-Dev.psm1
    * 9:12 PM 11/25/2019 new-CBH: added dummy parameter name fields - drop them and you get no CBH function
    * 6:47 PM 11/24/2019 new-CBH: got revision of through a full pass of adding a new CBH addition to a non-compliant file.
    * 3:48 PM 11/16/2019 INIT
    .DESCRIPTION
    new-CBH - Parse Script and prepend new Comment-based-Help keyed to existing contents
    .PARAMETER  Path
    Path to script
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    $updatedContent = new-CBH -Path $oSrc.fullname -showdebug:$($showdebug) -whatif:$($whatif) ;
    .LINK
    #>
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to script[-Path path-to\script.ps1]")]
        [ValidateScript( { Test-Path $_ })]$Path,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    if ($Path.GetType().FullName -ne 'System.IO.FileInfo') {
        $Path = get-childitem -path $Path ;
    } ;

    $sQot = [char]34 ; $sQotS = [char]39 ;
    $NewCBH = $null ; $NewCBH = @() ;

    $smsg = "Opening a copy for reference" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug

    $editor = "notepad2.exe" ;
    $editorArgs = "$($path.fullname)" ;
    Invoke-Command -ScriptBlock { & $editor $editorArgs } ;
    write-host "`a" ;
    write-host "`a" ;
    write-host "`a" ;

    $sSynopsis = Read-Host "Enter Script SYNOPSIS text"

    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path.fullname, [ref]$null, [ref]$Null ) ;

    # parameters declared in the AST PARAM() Block
    $ASTParameters = $ast.ParamBlock.Parameters.Name.variablepath.userpath ;

    $DefaultHelpTop = @"
#VERB-NOUN.ps1

<#
.SYNOPSIS
VERB-NOUN.ps1 - $($sSynopsis)
.NOTES
Version     : 1.0.0
Author      : Todd Kadrie
Website     : https://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : $(get-date -format yyyy-MM-dd)
FileName    : $($Path.name)
License     : MIT License
Copyright   : (c)  $(get-date -format yyyy) Todd Kadrie. All rights reserved.
Github      : https://github.com/tostka
Tags        : Powershell
AddedCredit : REFERENCE
AddedWebsite:	URL
AddedTwitter:	URL
REVISIONS
* $(get-date -format 'HH:mm tt MM/dd/yyyy') Added default CBH
.DESCRIPTION
VERB-NOUN.ps1 - $($sSynopsis)
"@ ;

    $DefaultHelpBottom=@"
.PARAMETER ShowDebug
Parameter to display Debugging messages [-ShowDebug switch]
.PARAMETER Whatif
Parameter to run a Test no-change pass [-Whatif switch]
.EXAMPLE
.\VERB-NOUN.ps1
.EXAMPLE
.\VERB-NOUN.ps1
.LINK
#>
"@ ;

    $DefaultHelpBottom = @"
.PARAMETER ShowDebug
Parameter to display Debugging messages [-ShowDebug switch]
.PARAMETER Whatif
Parameter to run a Test no-change pass [-Whatif switch]
.EXAMPLE
.\VERB-NOUN.ps1
.EXAMPLE
.\VERB-NOUN.ps1
.LINK
#>
"@ ;


    $NewCBH += $DefaultHelpTop ;
    $rgxStr = 'HelpMessage=' + $sQot + "(.*)" + $sQot ;

    if (($ASTParameters | measure).count -eq 0) {
        $NewCBH += ".PARAMETER PARAMETERNAME`nPARAMETERNAMEDESCRIPTION" ;
        <# do NOT create undefined parameters - sticking a .parameter in wo a
        parametername, will BREAK get-help CBH function#>
    }
    else {
        foreach ($param in $ASTParameters) {
            $NewCBH += ".PARAMETER`t$($param.variablepath.userpath)`n$($param.variablepath.userpath)DESCRIPTION`n" ;
        } ;
    } ;

    $NewCBH += $DefaultHelpBottom ;
    $NewCBH = $NewCBH -replace ('VERB-NOUN', $Path.name.replace('.ps1', '') ) ;
    <# 7:30 PM 11/24/2019 WATCHOUT FOR *FAKE* CBH "KEYWORDS", CBH will BREAK, if it sees fake keywords.
    The keyword names are case-insensitive, but they must be spelled exactly as specified.
    The dot and the keyword name cannot be separated by even one space.
    None of the keywords are required* in comment-based help, but you can't add or
    change keywords, even it you really want a new one (such as .FILENAME, which
    would be a really good idea). If you use .NOTE (instead of .NOTES) or .EXAMPLES
    (instead of .EXAMPLE), Get-Help doesn't display any of it.
    GUESS WHAT, IF A LINE BEGINS WITH .Net, YOU GUESSED IT! CBH interprets it as a FAKE KEYWORD!
    and BREAKS all cbh retrieval by the get-help command on the file!
    #>
    $rgxFakeCBHKeywords = '^\s*\.[A-Z]+\w*\s*'
    $rgxCBHKeywords = "\.(SYNOPSIS|DESCRIPTION|PARAMETER|EXAMPLE|INPUTS|OUTPUTS|NOTES|LINK|COMPONENT|ROLE|FUNCTIONALITY|FORWARDHELPTARGETNAME|FORWARDHELPCATEGORY|REMOTEHELPRUNSPACE|EXTERNALHELP)"

    [array]$FakeKeywordLines = $null ;
    if( $NewCBH |?{($_ -match $rgxFakeCBHKeywords) -AND ($_ -notmatch $rgxCBHKeyword?)}){
        $smsg= "" ;
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):NOTE!:NEW CBH BLOCK INCLUDES A *FAKE* CBH KEYWORD LINE(S)!`n$(([array]$FakeKeywordLines |out-string).trim())" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug
        $CBH = $CBH | ForEach-Object {
            if (($_ -match $rgxFakeCBHKeywords) -AND ($_ -notmatch $rgxCBHKeywords)) {
                $_ -replace '\.(?=[A-Za-z]+)','dot' ;
            } else {
                $_
            } ;
        } ;
    } ;
    $NewCBH | write-output ;

}

#*------^ new-CBH.ps1 ^------


#*------v New-GitHubGist.ps1 v------
Function New-GitHubGist {
    <#
    .SYNOPSIS
    New-GitHubGist.ps1 - Create GitHub Gist from passed param or file contents
    .NOTES
    Author: Jeffery Hicks
    Website:	https://jdhitsolutions.com/blog/powershell/5410/creating-a-github-gist-with-powershell/
    Twitter:	@tostka, http://twitter.com/tostka
    Additional Credits: REFERENCE
    Website:	URL
    Twitter:	URL
    REVISIONS   :
    * 1/26/17 - posted version
    .DESCRIPTION
    .PARAMETER Name
    What is the name for your gist?
    PARAMETER Path
    Path to file of content to be converted
    PARAMETER Content,
    Content to be converted
    PARAMETER Description,
    Description for new Gist
    PARAMETER UserToken
    Github Access Token
    PARAMETER Private
    Switch parameter that specifies creation of a Private Gist
    PARAMETER Passthru
    Passes the new Gist through into pipeline, as a new object
    .EXAMPLE
    New-GitHubGist -Name "BoxPrompt.ps1" -Description "a fancy PowerShell prompt function" -Path S:\boxprompt.ps1
    .LINK
    https://jdhitsolutions.com/blog/powershell/5410/creating-a-github-gist-with-powershell/
    #>

    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetName = "Content")]
    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "What is the name for your gist?", ValueFromPipelineByPropertyName)]
        [ValidateNotNullorEmpty()]
        [string]$Name,
        [Parameter(ParameterSetName = "path", Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullorEmpty()]
        [Alias("pspath")]
        [string]$Path,
        [Parameter(ParameterSetName = "Content", Mandatory)]
        [ValidateNotNullorEmpty()]
        [string[]]$Content,
        [string]$Description,
        [Alias("token")]
        [ValidateNotNullorEmpty()]
        [string]$UserToken = $gitToken,
        [switch]$Private,
        [switch]$Passthru
    )

    Begin {
        Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"

        #create the header
        $head = @{
            Authorization = 'Basic ' + $UserToken
        }
        #define API uri
        $base = "https://api.github.com"

    } #begin

    Process {
        #display PSBoundparameters formatted nicely for Verbose output
        [string]$pb = ($PSBoundParameters | Format-Table -AutoSize | Out-String).TrimEnd()
        Write-Verbose "[PROCESS] PSBoundparameters: `n$($pb.split("`n").Foreach({"$("`t"*2)$_"}) | Out-String) `n"

        #json section names must be lowercase
        #format content as a string

        switch ($pscmdlet.ParameterSetName) {
            "path" {
                $gistContent = Get-Content -Path $Path | Out-String
            }
            "content" {
                $gistContent = $Content | Out-String
            }
        } #close Switch

        $data = @{
            files       = @{$Name = @{content = $gistContent } }
            description = $Description
            public      = (-Not ($Private -as [boolean]))
        } | Convertto-Json

        Write-Verbose ($data | out-string)
        Write-Verbose "[PROCESS] Posting to $base/gists"

        If ($pscmdlet.ShouldProcess("$name [$description]")) {

            #parameters to splat to Invoke-Restmethod
            $invokeParams = @{
                Method      = 'Post'
                Uri         = "$base/gists"
                Headers     = $head
                Body        = $data
                ContentType = 'application/json'
            }

            $r = Invoke-Restmethod @invokeParams

            if ($Passthru) {
                Write-Verbose "[PROCESS] Writing a result to the pipeline"
                $r | Select @{Name = "Url"; Expression = { $_.html_url } },
                Description, Public,
                @{Name = "Created"; Expression = { $_.created_at -as [datetime] } }
            }
        } #should process

    } #process

    End {
        Write-Verbose "[END    ] Ending: $($MyInvocation.Mycommand)"
    } #end

}

#*------^ New-GitHubGist.ps1 ^------


#*------v pop-FunctionDev.ps1 v------
function pop-FunctionDev {
    <#
    .SYNOPSIS
    pop-FunctionDev.ps1 - Copy a given c:\sc\[repo]\Public\function.ps1 file from prod editing dir (as function_func.ps1) back to source function .ps1 file
    .NOTES
    Version     : 1.2.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2023-10-02
    FileName    : pop-FunctionDev.ps1
    License     : (None Asserted)
    Copyright   : (None Asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell, development, html, markdown, conversion
    AddedCredit : Øyvind Kallstad @okallstad
    AddedWebsite: https://communary.net/
    AddedTwitter: @okallstad / https://twitter.com/okallstad
    REVISIONS
    * 3:09 PM 11/29/2023 added missing test on $sMod - gcm comes back with empty mod, when the item has been iflv'd in console, so prompt for a dest mod
    * 8:27 AM 11/28/2023 updated CBH; tested, works; add: fixed mod discovery typo; a few echo details, confirmed -ea stop on all cmds
    * 12:30 PM 11/22/2023 init
    .DESCRIPTION
    pop-FunctionDev.ps1 - Copy a given c:\sc\[repo]\Public\function.ps1 file from prod editing dir (as function_func.ps1) back to source function .ps1 file

    Concept is to use this to quickly 'pop' a debugging module source _func.ps1 back to the dev dir, de-suffixed from _func.ps1, so that it can be commited & rebuilt into the module. 
    
    On iniital debugging the matching function push-FunctionDev() would be used to push the .\public\function.ps1 file to the c:\usr\work\ps\scripts\ default dev destnation (or wherever it's -destination param specifies on run).
    
    .PARAMETER Path
    Source module funciton .ps1 file to be staged for editing (to uwps\Name_func.ps1)[-path 'C:\sc\verb-dev\Public\export-ISEBreakPoints.ps1']
    .PARAMETER Destination
    Directoy into which 'genericly-named output files should be written, or the full path to a specified output file[-Destination c:\pathto\MyModuleHelp.html]
    .PARAMETER SkipDependencyCheck
    Skip dependency check[-SkipDependencyCheck] 
    .PARAMETER Script
    Switch for processing target Script files (vs Modules, overrides natural blocks on processing scripts)[-Script]
    .PARAMETER MarkdownHelp
    Switch to use PlatyPS to output markdown help variants[-MarkdownHelp]
    .PARAMETER NoPreview
    Switch to suppress trailing preview of html in default browser[-NoPreview]
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Does not return output to pipeline.
    .EXAMPLE
    PS> pop-FunctionDev -Path "C:\sc\powershell\PSScripts\export-ISEBreakPoints_func.ps1" -Verbose -whatIf ;
    Demo duping uwps\xxx_func.ps1 debugging code back to source discovered module \public dir
    .EXAMPLE
    PS> $psise.powershelltabs.files.fullpath |?{$_ -match '_func\.ps1$'} | %{pop-FunctionDev -path $_ -whatif:$true -verbose } ; 
    Push back *all* _func.ps1 tabs currently open in ISE
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    #[Alias('Invoke-CreateModuleHelpFile')]
    PARAM(
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipeline = $True, HelpMessage = 'File paths[-path c:\pathto\file.ext]')]
            [Alias('PsPath')]
            #[ValidateScript({Test-Path $_ -PathType 'Container'})]
            #[System.IO.DirectoryInfo[]]$Path,
            [ValidateScript({Test-Path $_})]
            [system.io.fileinfo[]]$Path,
            #[string[]]$Path,
        #[Parameter(Mandatory = $true,HelpMessage="Path the destination 'editing' directory (defaults to uwps)[-Path c:\pathto\]")]
        #    [ValidateScript({Test-Path $_ -PathType 'Container'})]
        #    [System.IO.DirectoryInfo]$Destination = 'C:\sc\powershell\PSScripts\',
        [Parameter(HelpMessage="Force (overwrite conflict)[-force]")]
            [switch] $force, 
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
            [switch] $whatIf=$true       
    ) ; 
    BEGIN { 
        # for scripts wo support, can use regions to fake BEGIN;PROCESS;END:
        # ps1 faked:#region BEGIN ; #*------v BEGIN v------
        #region CONSTANTS-AND-ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
        # Debugger:proxy automatic variables that aren't directly accessible when debugging (must be assigned and read back from another vari) ; 
        $rPSCmdlet = $PSCmdlet ; 
        $rPSScriptRoot = $PSScriptRoot ; 
        $rPSCommandPath = $PSCommandPath ; 
        $rMyInvocation = $MyInvocation ; 
        $rPSBoundParameters = $PSBoundParameters ; 
        [array]$score = @() ; 
        if($rPSCmdlet.MyInvocation.InvocationName -match '\.ps1$'){$score+= 'ExternalScript' } else {$score+= 'Function' }
        if($rPSCmdlet.CommandRuntime.tostring() -match '\.ps1$'){$score+= 'ExternalScript' } else {$score+= 'Function' }
        $score+= $rMyInvocation.MyCommand.commandtype.tostring() ; 
        $grpSrc = $score | group-object -NoElement | sort count ;
        if( ($grpSrc |  measure | select -expand count) -gt 1){
            write-warning  "$score mixed results:$(($grpSrc| ft -a count,name | out-string).trim())" ;
            if($grpSrc[-1].count -eq $grpSrc[-2].count){
                write-warning "Deadlocked non-majority results!" ;
            } else {
                $runSource = $grpSrc | select -last 1 | select -expand name ;
            } ;
        } else {
            write-verbose "consistent results" ;
            $runSource = $grpSrc | select -last 1 | select -expand name ;
        };
        write-host "Calculated `$runSource:$($runSource)" ;
        'score','grpSrc' | get-variable | remove-variable ; # cleanup temp varis

        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $rPSCmdlet.MyInvocation.MyCommand.Name ;
        $PSParameters = New-Object -TypeName PSObject -Property $rPSBoundParameters ;
        write-verbose "`$rPSBoundParameters:`n$(($rPSBoundParameters|out-string).trim())" ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
        # pre psv2, no $rPSBoundParameters autovari to check, so back them out:
        write-verbose 'Collect all non-default Params (works back to psv2 w CmdletBinding)'
        $ParamsNonDefault = (Get-Command $rPSCmdlet.MyInvocation.InvocationName).parameters | Select-Object -expand keys | Where-Object{$_ -notmatch '(Verbose|Debug|ErrorAction|WarningAction|ErrorVariable|WarningVariable|OutVariable|OutBuffer)'} ;
        #region ENVIRO_DISCOVER ; #*------v ENVIRO_DISCOVER v------
        <#
        # Debugger:proxy automatic variables that aren't directly accessible when debugging ; 
        $rPSScriptRoot = $PSScriptRoot ; 
        $rPSCommandPath = $PSCommandPath ; 
        $rMyInvocation = $MyInvocation ; 
        $rPSBoundParameters = $PSBoundParameters ; 
        #>
        $ScriptDir = $scriptName = '' ;     
        if($ScriptDir -eq '' -AND ( (get-variable -name rPSScriptRoot -ea 0) -AND (get-variable -name rPSScriptRoot).value.length)){
            $ScriptDir = $rPSScriptRoot
        } ; # populated rPSScriptRoot
        if( (get-variable -name rPSCommandPath -ea 0) -AND (get-variable -name rPSCommandPath).value.length){
            $ScriptName = $rPSCommandPath
        } ; # populated rPSCommandPath
        if($ScriptDir -eq '' -AND $runSource -eq 'ExternalScript'){$ScriptDir = (Split-Path -Path $rMyInvocation.MyCommand.Source -Parent)} # Running from File
        # when $runSource:'Function', $rMyInvocation.MyCommand.Source is empty,but on functions also tends to pre-hit from the rPSCommandPath entFile.FullPath ;
        if( $scriptname -match '\.psm1$' -AND $runSource -eq 'Function'){
            write-host "MODULE-HOMED FUNCTION:Use `$CmdletName to reference the running function name for transcripts etc (under a .psm1 `$ScriptName will reflect the .psm1 file  fullname)"
            if(-not $CmdletName){write-warning "MODULE-HOMED FUNCTION with BLANK `$CmdletNam:$($CmdletNam)" } ;
        } # Running from .psm1 module
        if($ScriptDir -eq '' -AND (Test-Path variable:psEditor)) {
            write-verbose "Running from VSCode|VS" ; 
            $ScriptDir = (Split-Path -Path $psEditor.GetEditorContext().CurrentFile.Path -Parent) ; 
                if($ScriptName -eq ''){$ScriptName = $psEditor.GetEditorContext().CurrentFile.Path }; 
        } ;
        if ($ScriptDir -eq '' -AND $host.version.major -lt 3 -AND $rMyInvocation.MyCommand.Path.length -gt 0){
            $ScriptDir = $rMyInvocation.MyCommand.Path ; 
            write-verbose "(backrev emulating `$rPSScriptRoot, `$rPSCommandPath)"
            $ScriptName = split-path $rMyInvocation.MyCommand.Path -leaf ;
            $rPSScriptRoot = Split-Path $ScriptName -Parent ;
            $rPSCommandPath = $ScriptName ;
        } ;
        if ($ScriptDir -eq '' -AND $rMyInvocation.MyCommand.Path.length){
            if($ScriptName -eq ''){$ScriptName = $rMyInvocation.MyCommand.Path} ;
            $ScriptDir = $rPSScriptRoot = Split-Path $rMyInvocation.MyCommand.Path -Parent ;
        }
        if ($ScriptDir -eq ''){throw "UNABLE TO POPULATE SCRIPT PATH, EVEN `$rMyInvocation IS BLANK!" } ;
        if($ScriptName){
            if(-not $ScriptDir ){$ScriptDir = Split-Path -Parent $ScriptName} ; 
            $ScriptBaseName = split-path -leaf $ScriptName ;
            $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($ScriptName) ;
        } ; 
        # last ditch patch the values in if you've got a $ScriptName
        if($rPSScriptRoot.Length -ne 0){}else{ 
            if($ScriptName){$rPSScriptRoot = Split-Path $ScriptName -Parent }
            else{ throw "Unpopulated, `$rPSScriptRoot, and no populated `$ScriptName from which to emulate the value!" } ; 
        } ; 
        if($rPSCommandPath.Length -ne 0){}else{ 
            if($ScriptName){$rPSCommandPath = $ScriptName }
            else{ throw "Unpopulated, `$rPSCommandPath, and no populated `$ScriptName from which to emulate the value!" } ; 
        } ; 
        if(-not ($ScriptDir -AND $ScriptBaseName -AND $ScriptNameNoExt  -AND $rPSScriptRoot  -AND $rPSCommandPath )){ 
            throw "Invalid Invocation. Blank `$ScriptDir/`$ScriptBaseName/`ScriptNameNoExt" ; 
            BREAK ; 
        } ; 
        # echo results dyn aligned:
        $tv = 'runSource','CmdletName','ScriptName','ScriptBaseName','ScriptNameNoExt','ScriptDir','PSScriptRoot','PSCommandPath','rPSScriptRoot','rPSCommandPath' ; 
        $tvmx = ($tv| Measure-Object -Maximum -Property Length).Maximum * -1 ; 
        $tv | get-variable | %{  write-verbose ("`${0,$tvmx} : {1}" -f $_.name,$_.value) } ; 
        'tv','tvmx'|get-variable | remove-variable ; # cleanup temp varis
    
        #endregion ENVIRO_DISCOVER ; #*------^ END ENVIRO_DISCOVER ^------
        
        # check if using Pipeline input or explicit params:
        if ($rPSCmdlet.MyInvocation.ExpectingInput) {
            $smsg = "Data received from pipeline input: '$($InputObject)'" ;
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } else {
            # doesn't actually return an obj in the echo
            #$smsg = "Data received from parameter input: '$($InputObject)'" ;
            #if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            #else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ;

        # tempfile for cap'ing git output
        #$fn = "$env:temp\gitStat.txt" ; # temp file
        
    }  ;  # BEG-E
    PROCESS {
        $Error.Clear() ; 
        $pwd0 = get-location ; 
        pushd ; 
        foreach($funcfile in $Path) {
            $smsg = $sBnrS="`n#*------v PROCESSING : $($funcfile) v------" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success

            TRY{
                get-childitem -path $funcfile -ea STOP |foreach-object {
                    $sfile = $_ ; 
                    $error.clear() ;
  
                    if($sMod = get-command (split-path $sfile -leaf).replace('_func.ps1','') -ea STOP | select -expand module){
                        $smsg =  "==:$($sfile):discovered hosted in module:$($sMod.name)" ; 
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;  
                    } ELSE { 
                        # gcm comes back with empty mod, when the item has been iflv'd in console, so prompt for a solution
                        $smsg = "Unable to locate a matching Module for:`n$($sfile)!" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        #Continue
                        # recover with manual prompt
                        if($sMod =get-module -name (Read-Host "Enter the proper locally-installed Module name to contuine:") -ListAvailable -ErrorAction STOP){
                            $smsg = "Resolve input to: $($sMod.Name)" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                        } else { 
                            $smsg = "Unable to locate a matching Module for:`n$($sfile)!" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            Continue
                        } ;
                    } ;

                    if($sModDir = get-item -path "c:\sc\$($sMod.name)" -ea STOP){
                        
                        if($target = get-childitem -path (join-path -path $sModDir.fullname -ChildPath "\Public\$($sfile.name.replace('_func.ps1','.ps1'))") ){
                            
                            $smsg = "Existing file:$($target.fullname) is the destation" ; 
                            $smsg += "`nAre you SURE you want to overwrite your edited updates to the source file?" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Prompt } 
                            else{ write-host -foregroundcolor YELLOW "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $bRet=Read-Host "Enter YYY to continue. Anything else will exit"  ; 
                            if ($bRet.ToUpper() -eq "YYY") {
                                $smsg = "(Moving on)" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            } else {
                                    $smsg = "Invalid response. Exiting" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } 
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                #exit 1
                                break ; 
                            }  ; 
                            
                        } else { 
                            # no existing file to conflict
                            $smsg = "(no conflicting pre-existing '$((join-path -path $sModDir.fullname -ChildPath "\Public\$($sfile.name.replace('_func.ps1','.ps1'))"))' found)" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                        } ; 

                        $pltCI=[ordered]@{
                            path  = $sfile.fullname ;
                            destination  = $target ;
                            force = $($force) ; 
                            verbose  = $($VerbosePreference -eq 'Continue') ;
                            erroraction = 'STOP' ;
                            whatif = $($whatif) ;
                        } ;
                        $smsg = "Copying *back* from Editing:copy-item w`n$(($pltCI|out-string).trim())" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        copy-item @pltCI ; 

                        $hsMsg = @"

# To stage a branch for new work:
cd $($smoddir.fullname) ; 
# echo the curr branch
git branch

# a. create the new branch if it doesn't pre-exist
git checkout -b tostka/BRANCHNAME
# or b. switch to the existing branch
git checkout tostka/EXISTINGBRANCHNAME

# make changes, when ready
git status

# commit current branch
git commit

# push branch back to the origin remote repo
# first list all branches in local & remote repos:
git branch -a ; 

# then do push
git push -u origin tostka/BRANCHNAME

# trailing status
git status

# switch back to master:
git checkout master

# FINALLY: if done with the branch debugging, merge the branch back to master:

git merge tostka/BRANCHNAME

# cleanup, if done with it, delete a local branch:

git branch -d tostka/BRANCHNAME

# and then del the remote branch by simply pushing the chg
git push -u origin tostka/BRANCHNAME

"@ ; 
                        #---
                        $smsg = $hsMsg ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    } ELSE { 
                        $smsg = "Unable to locate a local c:\sc directory Module tree for:`n$($sfile)!" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        Continue
                    } ;
                    
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                CONTINUE;
            } ; 
            $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
        } ;  # loop-E
    } ;  # PROC-E
}

#*------^ pop-FunctionDev.ps1 ^------


#*------v push-FunctionDev.ps1 v------
function push-FunctionDev {
    <#
    .SYNOPSIS
    push-FunctionDev.ps1 - Stage a given c:\sc\[repo]\Public\function.ps1 file to prod editing dir as function_func.ps1
    .NOTES
    Version     : 1.2.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2023-10-02
    FileName    : push-FunctionDev.ps1
    License     : (None Asserted)
    Copyright   : (None Asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell, development, html, markdown, conversion
    AddedCredit : Øyvind Kallstad @okallstad
    AddedWebsite: https://communary.net/
    AddedTwitter: @okallstad / https://twitter.com/okallstad
    REVISIONS
    * 3:09 PM 11/29/2023 added missing test on $sMod - gcm comes back with empty mod, when the item has been iflv'd in console, so prompt for a dest mod
    * 8:27 AM 11/28/2023 updated CBH; tested, works; add: a few echo details, confirmed -ea stop on all cmds
    * 12:30 PM 11/22/2023 init
    .DESCRIPTION
    push-FunctionDev.ps1 - Stage a given c:\sc\[repo]\Public\function.ps1 file to prod editing dir as function_func.ps1

    Concept is to use this to quickly 'push' a module source .ps1 into the dev dir, suffixed as _func.ps1, so that it can be ipmo -fo -verb'd and debugged/edited for updates. 
    On completion the matching function pop-FunctionDev.ps1 would be used to pull the updated file back into place, overwriting the original source.
    .PARAMETER Path
    Source module funciton .ps1 file to be staged for editing (to uwps\Name_func.ps1)[-path 'C:\sc\verb-dev\Public\export-ISEBreakPoints.ps1']
    .PARAMETER Destination
    Directoy into which 'genericly-named output files should be written, or the full path to a specified output file[-Destination c:\pathto\MyModuleHelp.html]
    .PARAMETER SkipDependencyCheck
    Skip dependency check[-SkipDependencyCheck] 
    .PARAMETER Script
    Switch for processing target Script files (vs Modules, overrides natural blocks on processing scripts)[-Script]
    .PARAMETER MarkdownHelp
    Switch to use PlatyPS to output markdown help variants[-MarkdownHelp]
    .PARAMETER NoPreview
    Switch to suppress trailing preview of html in default browser[-NoPreview]
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Does not return output to pipeline.
    .EXAMPLE
    PS> push-functiondev -Path 'C:\sc\verb-dev\Public\export-ISEBreakPoints.ps1' -verbose -whatif ;
    Typical run
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    #[Alias('Invoke-CreateModuleHelpFile')]
    PARAM(
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipeline = $True, HelpMessage = 'File paths[-path c:\pathto\file.ext]')]
            [Alias('PsPath')]
            #[ValidateScript({Test-Path $_ -PathType 'Container'})]
            #[System.IO.DirectoryInfo[]]$Path,
            [ValidateScript({Test-Path $_})]
            [system.io.fileinfo[]]$Path,
            #[string[]]$Path,
        [Parameter(Mandatory = $false,HelpMessage="Path the destination 'editing' directory (defaults to uwps)[-Path c:\pathto\]")]
            [ValidateScript({Test-Path $_ -PathType 'Container'})]
            [System.IO.DirectoryInfo]$Destination = 'C:\sc\powershell\PSScripts\',
        [Parameter(HelpMessage="Force (overwrite conflict)[-force]")]
            [switch] $force, 
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
            [switch] $whatIf=$true       
    ) ; 
    BEGIN { 
        # for scripts wo support, can use regions to fake BEGIN;PROCESS;END:
        # ps1 faked:#region BEGIN ; #*------v BEGIN v------
            #region CONSTANTS-AND-ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
    # Debugger:proxy automatic variables that aren't directly accessible when debugging (must be assigned and read back from another vari) ; 
    $rPSCmdlet = $PSCmdlet ; 
    $rPSScriptRoot = $PSScriptRoot ; 
    $rPSCommandPath = $PSCommandPath ; 
    $rMyInvocation = $MyInvocation ; 
    $rPSBoundParameters = $PSBoundParameters ; 
    [array]$score = @() ; 
    if($rPSCmdlet.MyInvocation.InvocationName -match '\.ps1$'){$score+= 'ExternalScript' } else {$score+= 'Function' }
    if($rPSCmdlet.CommandRuntime.tostring() -match '\.ps1$'){$score+= 'ExternalScript' } else {$score+= 'Function' }
    $score+= $rMyInvocation.MyCommand.commandtype.tostring() ; 
    $grpSrc = $score | group-object -NoElement | sort count ;
    if( ($grpSrc |  measure | select -expand count) -gt 1){
        write-warning  "$score mixed results:$(($grpSrc| ft -a count,name | out-string).trim())" ;
        if($grpSrc[-1].count -eq $grpSrc[-2].count){
            write-warning "Deadlocked non-majority results!" ;
        } else {
            $runSource = $grpSrc | select -last 1 | select -expand name ;
        } ;
    } else {
        write-verbose "consistent results" ;
        $runSource = $grpSrc | select -last 1 | select -expand name ;
    };
    write-host "Calculated `$runSource:$($runSource)" ;
    'score','grpSrc' | get-variable | remove-variable ; # cleanup temp varis

    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
    ${CmdletName} = $rPSCmdlet.MyInvocation.MyCommand.Name ;
    $PSParameters = New-Object -TypeName PSObject -Property $rPSBoundParameters ;
    write-verbose "`$rPSBoundParameters:`n$(($rPSBoundParameters|out-string).trim())" ;
    $Verbose = ($VerbosePreference -eq 'Continue') ; 
    # pre psv2, no $rPSBoundParameters autovari to check, so back them out:
    write-verbose 'Collect all non-default Params (works back to psv2 w CmdletBinding)'
    $ParamsNonDefault = (Get-Command $rPSCmdlet.MyInvocation.InvocationName).parameters | Select-Object -expand keys | Where-Object{$_ -notmatch '(Verbose|Debug|ErrorAction|WarningAction|ErrorVariable|WarningVariable|OutVariable|OutBuffer)'} ;
    #region ENVIRO_DISCOVER ; #*------v ENVIRO_DISCOVER v------
    <#
    # Debugger:proxy automatic variables that aren't directly accessible when debugging ; 
    $rPSScriptRoot = $PSScriptRoot ; 
    $rPSCommandPath = $PSCommandPath ; 
    $rMyInvocation = $MyInvocation ; 
    $rPSBoundParameters = $PSBoundParameters ; 
    #>
    $ScriptDir = $scriptName = '' ;     
    if($ScriptDir -eq '' -AND ( (get-variable -name rPSScriptRoot -ea 0) -AND (get-variable -name rPSScriptRoot).value.length)){
        $ScriptDir = $rPSScriptRoot
    } ; # populated rPSScriptRoot
    if( (get-variable -name rPSCommandPath -ea 0) -AND (get-variable -name rPSCommandPath).value.length){
        $ScriptName = $rPSCommandPath
    } ; # populated rPSCommandPath
    if($ScriptDir -eq '' -AND $runSource -eq 'ExternalScript'){$ScriptDir = (Split-Path -Path $rMyInvocation.MyCommand.Source -Parent)} # Running from File
    # when $runSource:'Function', $rMyInvocation.MyCommand.Source is empty,but on functions also tends to pre-hit from the rPSCommandPath entFile.FullPath ;
    if( $scriptname -match '\.psm1$' -AND $runSource -eq 'Function'){
        write-host "MODULE-HOMED FUNCTION:Use `$CmdletName to reference the running function name for transcripts etc (under a .psm1 `$ScriptName will reflect the .psm1 file  fullname)"
        if(-not $CmdletName){write-warning "MODULE-HOMED FUNCTION with BLANK `$CmdletNam:$($CmdletNam)" } ;
    } # Running from .psm1 module
    if($ScriptDir -eq '' -AND (Test-Path variable:psEditor)) {
        write-verbose "Running from VSCode|VS" ; 
        $ScriptDir = (Split-Path -Path $psEditor.GetEditorContext().CurrentFile.Path -Parent) ; 
            if($ScriptName -eq ''){$ScriptName = $psEditor.GetEditorContext().CurrentFile.Path }; 
    } ;
    if ($ScriptDir -eq '' -AND $host.version.major -lt 3 -AND $rMyInvocation.MyCommand.Path.length -gt 0){
        $ScriptDir = $rMyInvocation.MyCommand.Path ; 
        write-verbose "(backrev emulating `$rPSScriptRoot, `$rPSCommandPath)"
        $ScriptName = split-path $rMyInvocation.MyCommand.Path -leaf ;
        $rPSScriptRoot = Split-Path $ScriptName -Parent ;
        $rPSCommandPath = $ScriptName ;
    } ;
    if ($ScriptDir -eq '' -AND $rMyInvocation.MyCommand.Path.length){
        if($ScriptName -eq ''){$ScriptName = $rMyInvocation.MyCommand.Path} ;
        $ScriptDir = $rPSScriptRoot = Split-Path $rMyInvocation.MyCommand.Path -Parent ;
    }
    if ($ScriptDir -eq ''){throw "UNABLE TO POPULATE SCRIPT PATH, EVEN `$rMyInvocation IS BLANK!" } ;
    if($ScriptName){
        if(-not $ScriptDir ){$ScriptDir = Split-Path -Parent $ScriptName} ; 
        $ScriptBaseName = split-path -leaf $ScriptName ;
        $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($ScriptName) ;
    } ; 
    # last ditch patch the values in if you've got a $ScriptName
    if($rPSScriptRoot.Length -ne 0){}else{ 
        if($ScriptName){$rPSScriptRoot = Split-Path $ScriptName -Parent }
        else{ throw "Unpopulated, `$rPSScriptRoot, and no populated `$ScriptName from which to emulate the value!" } ; 
    } ; 
    if($rPSCommandPath.Length -ne 0){}else{ 
        if($ScriptName){$rPSCommandPath = $ScriptName }
        else{ throw "Unpopulated, `$rPSCommandPath, and no populated `$ScriptName from which to emulate the value!" } ; 
    } ; 
    if(-not ($ScriptDir -AND $ScriptBaseName -AND $ScriptNameNoExt  -AND $rPSScriptRoot  -AND $rPSCommandPath )){ 
        throw "Invalid Invocation. Blank `$ScriptDir/`$ScriptBaseName/`ScriptNameNoExt" ; 
        BREAK ; 
    } ; 
    # echo results dyn aligned:
    $tv = 'runSource','CmdletName','ScriptName','ScriptBaseName','ScriptNameNoExt','ScriptDir','PSScriptRoot','PSCommandPath','rPSScriptRoot','rPSCommandPath' ; 
    $tvmx = ($tv| Measure-Object -Maximum -Property Length).Maximum * -1 ; 
    $tv | get-variable | %{  write-verbose  ("`${0,$tvmx} : {1}" -f $_.name,$_.value) } ; 
    'tv','tvmx'|get-variable | remove-variable ; # cleanup temp varis
    
    #endregion ENVIRO_DISCOVER ; #*------^ END ENVIRO_DISCOVER ^------
        
        # check if using Pipeline input or explicit params:
        if ($rPSCmdlet.MyInvocation.ExpectingInput) {
            $smsg = "Data received from pipeline input: '$($InputObject)'" ;
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } else {
            # doesn't actually return an obj in the echo
            #$smsg = "Data received from parameter input: '$($InputObject)'" ;
            #if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            #else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ;

        # tempfile for cap'ing git output
        #$fn = "$env:temp\gitStat.txt" ; # temp file
        
    }  ;  # BEG-E
    PROCESS {
        $Error.Clear() ; 
        $pwd0 = get-location ; 
        pushd ; 
        foreach($funcfile in $Path) {
            $smsg = $sBnrS="`n#*------v PROCESSING : $($funcfile) v------" ; 
            TRY{
                get-childitem -path $funcfile -ea STOP |foreach-object {
                    $sfile = $_ ; 
                    $error.clear() ;
                    
                    if($sMod = get-module ((get-command  (split-path $sfile  -leaf).replace('.ps1','') -ErrorAction STOP) | select -expand source) -ListAvailable){
                        $smsg =  "==:$($sfile):discovered module:$($sMod.name)" ; 
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;  
                    } ELSE { 
                        # gcm comes back with empty mod, when the item has been iflv'd in console, so prompt for a solution
                        $smsg = "Unable to locate a matching Module for:`n$($sfile)!" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        #Continue
                        # recover with manual prompt
                        if($sMod =get-module -name (Read-Host "Enter the proper locally-installed Module name to contuine:") -ListAvailable -ErrorAction STOP){
                            $smsg = "Resolve input to: $($sMod.Name)" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                        } else { 
                            $smsg = "Unable to locate a matching Module for:`n$($sfile)!" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            Continue
                        } ;
                    } ;
                    if($sModDir = get-item -path "c:\sc\$($sMod.name)" -ea STOP){
                        #Set-Location $sModDir.fullname ; 
                        
                        $pltCI=[ordered]@{
                            path  = $sfile.fullname ;
                            destination  = (join-path -path $Destination -childpath $sfile.name.replace('.ps1','_func.ps1') -ea STOP) ;
                            force = $($force) ; 
                            verbose  = $($VerbosePreference -eq 'Continue') ;
                            erroraction = 'STOP' ;
                            whatif = $($whatif) ;
                        } ;
                        $smsg = "Staging for Editing:copy-item w`n$(($pltCI|out-string).trim())" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        copy-item @pltCI ; 

                        $hsMsg = @"

# To stage a branch for new work:
cd $($smoddir.fullname) ; 
# echo the curr branch
git branch

# a. create the new branch if it doesn't pre-exist
git checkout -b tostka/BRANCHNAME
# or b. switch to the existing branch
git checkout tostka/EXISTINGBRANCHNAME

# make changes, when ready
git status

# commit current branch
git commit

# push branch back to the origin remote repo
# first list all branches in local & remote repos:
git branch -a ; 

# then do push
git push -u origin tostka/BRANCHNAME

# trailing status
git status

# switch back to master:
git checkout master

# FINALLY: if done with the branch debugging, merge the branch back to master:

git merge tostka/BRANCHNAME

# cleanup, if done with it, delete a local branch:

git branch -d tostka/BRANCHNAME

# and then del the remote branch by simply pushing the chg
git push -u origin tostka/BRANCHNAME

"@ ; 
                        #---
                        $smsg = $hsMsg  ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    } ELSE { 
                        $smsg = "Unable to locate a local c:\sc directory Module tree for:`n$($sfile)!" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        Continue
                    } ;
                    
                } ;  # loop-E
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                CONTINUE;
            } ; 
            $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
        } ;  # loop-E
    } ;  # PROC-E
}

#*------^ push-FunctionDev.ps1 ^------


#*------v restore-ISEConsoleColors.ps1 v------
Function restore-ISEConsoleColors {
    <#
    .SYNOPSIS
    restore-ISEConsoleColors - Restore default $psise.options from "`$(split-path $profile)\IseColorsDefault.csv" file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-03-17
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Copyright   : 
    Github      : https://github.com/tostka
    Tags        : Powershell,ExchangeOnline,Exchange,RemotePowershell,Connection,MFA
    REVISIONS   :
    * 12:46 PM 6/2/2022 typo: remove spurious }
    * 7:29 AM 3/17/2021 init
    .DESCRIPTION
    restore-ISEConsoleColors - Restore default $psise.options from "`$(split-path $profile)\IseColorsDefault.csv" file
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    restore-ISEConsoleColors;
    .LINK
    https://github.com/tostka/verb-IO
    #>
    
    [CmdletBinding()]
    Param() 
    $verbose = ($VerbosePreference -eq "Continue") ; 
    switch($host.name){
        "Windows PowerShell ISE Host" {
            ##$psISE.Options.RestoreDefaultTokenColors()
            <#$sFileTag=Read-Host "Enter 'Name' for saved color scheme" ;
            $ofile = "$(split-path $profile)\IseColors-$($sFileTag).csv" ; 
            write-host -fore green "Saving current Colors & Fonts to file: $($ofile)" ; 
            $psise.options | Select ConsolePane*,Font* | Export-CSV "$($ofile)" ;
            #>
            $ifile = "$(split-path $profile)\IseColorsDefault.csv" ; 
            if(test-path $ifile){
                (import-csv $ifile ).psobject.properties | foreach { $psise.options.$($_.name) = $_.Value} ; 
            } else { 
                throw "Missing $($ifile), skipping restore-ISEConsoleColors.ps1`nCan be created via:`n`$psise.options | Select ConsolePane*,Font* | Export-CSV '`$(split-path $profile)\IseColorsDefault.csv'"
            } ;
        } 
        "ConsoleHost" {
            #[console]::ResetColor()  # reset console colorscheme to default
            throw "This command is intended to backup ISE (`$psie.options object). PS `$host is not supported" ; 
        }
        default {
            write-warning "Unrecognized `$Host.name:$($Host.name), skipping $($MyInvocation.MyCommand.Name)" ; 
        } ; 
    } ; 
}

#*------^ restore-ISEConsoleColors.ps1 ^------


#*------v restore-ModuleBuild.ps1 v------
function restore-ModuleBuild {
    <#
    .SYNOPSIS
    restore-ModuleBuild - Restore fingerprint, Manifest (.psd1) & Module (.psm1) files from deep (c:\scBlind\[modulename]) backup, as specified by inbound .xml file or array of files
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : restore-ModuleBuild
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 10:12 AM 5/26/2022 init; got through full debugged pass.
    .DESCRIPTION
    restore-ModuleBuild - Restore fingerprint, Manifest (.psd1) & Module (.psm1) files from deep (c:\scBlind\[modulename]) backup, as specified by inbound .xml file or array of files

    ```text
    C:\SC\VERB-IO
    ├───Internal
    │       [Internal 'non'-exported cmdlet files].ps1 
    ├───Package
    │       verb-io.2.0.3.nupkg # RequiredRevision nupkg file location and name-structure
    ├───Public
    │       [Public exported cmdlet files].ps1
    └───verb-IO
        │   verb-IO.psd1 # module Manifest psd1
        │   verb-IO.psm1 # module .psm1 file
    ```
    .PARAMETER Name
    Module Name to have revised Public source directory import-module'd[-PARAM SAMPLEINPUT]
    PARAMETER RequiredVersion
    Required module .pkg file version to be used as filter date  for determining 'revised' public cmdlets[-RequiredVersion '2.0.3']
    PARAMETER ExplicitTime
    Explicit timestamp to be used for 'Revised' Public .ps1 cmdlet filtering[-ExplicitTime (get-date).adddays(-14)]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .OUTPUT
    System.Object[] array reflecting full path to exch backed up module build file
    .EXAMPLE
    PS> $bRet = restore-modulebuild -path 'C:\scblind\verb-io\bufiles-20220525-1528PM.xml' -verbose -whatif 
    Restage the specified .xml of backup files, from deep extra-git backup loc, to git repo source dir, and then leverage restore-fileTDO to restore production filename to the files. 
    .EXAMPLE
    PS> $bRet = restore-modulebuild -path 'C:\scblind\verb-io\fingerprint._20220525-1527PM','C:\scblind\verb-io\verb-IO\verb-IO.psm1_20220525-1527PM','C:\scblind\verb-io\verb-IO\verb-IO.psd1_20220525-1527PM' -verbose -whatif 
    Restage an array of backed up files, from deep extra-git backup loc, to git repo source dir, and then leverage restore-fileTDO to restore production filename to the files. 
    .LINK
    https://github.com/tostka/verb-dev
    #>
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    [CmdletBinding()]
    #[Alias('iIseBpAll')]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Path to .xml backup file, or leaf backed up files to be restored[-Path C:\scblind\verb-io\bufiles-20220525-1528PM.xml]")]
        [ValidateScript( { Test-Path $_ })]
        [system.io.fileinfo[]]$Path,
        [Parameter(HelpMessage="Destination for restores (defaults below c:\scp\)[-backupRoot c:\path-to\source-root\]")]
        [system.io.fileinfo]$scRoot = 'C:\sc', 
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue") ;
        $sBnr="#*======v $($CmdletName): v======" ; 
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;

        $templateFiles= 'fingerprint','MOD.psm1','MOD.psd1' ; 
        #$backupRoot = 'C:\scblind'

        TRY{
            [string]$ModuleName = (split-path $Path[0].fullname).split('\')[-1] ; 
            [system.io.fileinfo]$modroot = "$($scroot.fullname)\$($modulename)" ; 
            [system.io.fileinfo]$BuRoot = (split-path $Path[0].fullname).split('\')[0..2] -join '\'
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-warning "$($smsg)" } ;
            Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
        } ;
        if( (($Path|  measure).count -eq 1) -AND $Path.extension -eq '.xml'){
            write-host '.xml file detected: Attempting to retrieve and restore backup files defined within' ; 
            $pltXXML=[ordered]@{Path = $path ;verbose=$verbose ;erroraction = 'STOP'} ; 
            write-host "ixml w`n$(($pltXXML |out-string).trim())" ; 
            TRY{
                $xfiles = import-clixml @pltXXML ; 
                <#[string]$ModuleName = (split-path $Path).split('\')[-1] ; 
                [system.io.fileinfo]$modroot = "$($scroot.fullname)\$($modulename)" ; 
                [system.io.fileinfo]$BuRoot = (split-path $Path).split('\')[0..2] -join '\'
                #>
                # .replace('C:\sc',$backupRoot)
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-warning "$($smsg)" } ;
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;
        } else {
            $xfiles = $path.fullname ; 
            
        } ; 
        $smsg = "`$ModuleName:$($ModuleName)" ; 
        $smsg += "`n`$modroot:$($modroot)" ; 
        $smsg += "`n`$BuRoot:$($BuRoot)" ; 
        write-verbose $smsg ;
        $smsg = "`$xfiles:`n$(($xfiles|out-string).trim())" ; 
        write-verbose $smsg ;
        #[string]$ModRoot = gi c:\sc\$item ;
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ; 
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ; 
            write-verbose "(non-pipeline - param - input)" ; 
        } ; 

        $oReport = @() ; 
    }
    PROCESS {
        foreach ($item in $xfiles){
            $sBnrS="`n#*------v PROCESSING: $($item) v------" ; 
            write-host -foregroundcolor green $sBnrS ;

            $error.clear() ;
            TRY{
                [system.io.fileinfo]$sfile = (resolve-path $item -ErrorAction 'STOP' -verbose:$($verbose) ).path ; 
                $pltCI=[ordered]@{
                    path=$sfile.fullname ;
                    Destination=$sfile.tostring().replace($buroot,$modroot) ;
                    ErrorAction='STOP' ;
                    verbose=$($verbose);
                    whatif=$($whatif) ;
                } ; 
                $smsg = "Staging Deep Backup back to git repo directory:copy-item w`n$(($pltCI|out-string).trim())" ; 
                write-host $smsg ;
                copy-item @pltCI ; 

                $pltRF=[ordered]@{
                    Source = $pltCI.Destination
                    #Destination=$sfile.tostring().replace($buroot,$modroot) ;
                    ErrorAction='STOP' ;
                    verbose=$($verbose);
                    whatif=$($whatif) ;
                } ; 
                $smsg = "restore-FileTDO w`n$(($pltRF|out-string).trim())" ; 
                write-host $smsg ;
                if(-not $whatif){
                    $bRet = restore-FileTDO @pltRF ;
                    if (!$bRet -and -not $whatif) {throw "FAILURE" } else {
                        $oReport += $bRet ; 
                    } ; 
                } else { 
                    write-host "(-whatif: skipping restore-fileTDO)" ; 
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-warning "$($smsg)" } ;
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;

            write-host -foregroundcolor green $sBnrS.replace('-v','-^').replace('v-','^-') ;
        } ;  # loop-E $items in $item
    } # PROC-E
    END{
        if(-not $whatif){
            $smsg = "(returning `$oReport restored filenames to pipeline:`n$(($oReport|out-string).trim()))" ; 
            write-verbose $smsg ;
        } ; 
        $oReport | write-output ; 
        write-host -foregroundcolor green $sBnr.replace('=v','=^').replace('v=','^=') ; 
    } ;
}

#*------^ restore-ModuleBuild.ps1 ^------


#*------v save-ISEConsoleColors.ps1 v------
Function save-ISEConsoleColors {
    <#
    .SYNOPSIS
    save-ISEConsoleColors - Save $psise.options | Select ConsolePane*,Font* to prompted csv file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-03-17
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Copyright   : 
    Github      : https://github.com/tostka
    Tags        : Powershell,ExchangeOnline,Exchange,RemotePowershell,Connection,MFA
    REVISIONS   :
    * 12:46 PM 6/2/2022 typo: remove spurious }
    * 1:25 PM 3/5/2021 init ; added support for both ISE & powershell console
    .DESCRIPTION
    save-ISEConsoleColors - Save $psise.options | Select ConsolePane*,Font* to prompted csv file
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    save-ISEConsoleColors;
    .LINK
    https://github.com/tostka/verb-IO
    #>
    [CmdletBinding()]
    #[Alias('dxo')]
    Param() 
    $verbose = ($VerbosePreference -eq "Continue") ; 
    switch($host.name){
        "Windows PowerShell ISE Host" {
            ##$psISE.Options.RestoreDefaultTokenColors()
            $sFileTag=Read-Host "Enter 'Name' for saved color scheme" ;
            $ofile = "$(split-path $profile)\IseColors-$($sFileTag).csv" ; 
            write-host -fore green "Saving current Colors & Fonts to file: $($ofile)" ; 
            $psise.options | Select ConsolePane*,Font* | Export-CSV "$($ofile)" ;
        } 
        "ConsoleHost" {
            #[console]::ResetColor()  # reset console colorscheme to default
            throw "This command is intended to backup ISE (`$psie.options object). PS `$host is not supported" ; 
        }
        default {
            write-warning "Unrecognized `$Host.name:$($Host.name), skipping save-ISEConsoleColors" ; 
        } ; 
    } ; 
}

#*------^ save-ISEConsoleColors.ps1 ^------


#*------v show-ISEOpenTab.ps1 v------
function show-ISEOpenTab {
    <#
    .SYNOPSIS
    show-ISEOpenTab - Display a list of all currently open ISE tab files, prompt for selection, and then foreground selected tab file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : show-ISEOpenTab
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 10:09 AM 5/14/2024 init
    .DESCRIPTION
    show-ISEOpenTab - Display a list of all currently open ISE tab files, prompt for selection, and then foreground selected tab file
    Alternately supports a -Path param, that permits ISE Console use to direct switch active Tab File. 

    This is really only useful when you run a massive number of open file tabs, and visually scanning them unsorted is too much work. 
    Opens them in a sortable grid view, with both Displayname & fullpath, and you can rapidly zoom in on the target tab file you're seeking. 

    .PARAMETER Path
    Optional Path to filter against the ISE .files Fullname string (for direct ISE console use)[-Path ' D:\scripts\show-ISEOpenTab_func.ps1']
    .EXAMPLE
    PS> show-ISEOpenTab -verbose -whatif
    Intereactive pass, uses out-grid as a picker select a prompted target file tab, from full list. 
    .EXAMPLE
    PS> show-ISEOpenTab -Path 'D:\scripts\get-MailHeaderSenderIDKeys.ps1' -verbose ;
    ISE Console direct switch open files in ISE to the file tab with the specified path as it's FullName
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('shIseTab')]
    PARAM(
        [Parameter(Position=0,HelpMessage="Optional Path to filter against the ISE .files Fullname string (for direct ISE console use)[-Path ' D:\scripts\show-ISEOpenTab_func.ps1']")]
        [string]$Path
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
    }
    PROCESS {
        if ($psise){
            #$AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;
            #$CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
            $allISEFiles = $psise.powershelltabs.files #.fullpath ;

            if($Path){
                $tFile = $allISEFiles | ?{$_.Fullpath -eq $Path} 
            } else{$tFile = $allISEFiles | select DisplayName,FullPath | out-gridview -Title "Pick Tab to focus:" -passthru};
            If($tFile){
                $Name = $tFile.DisplayName ; 
                write-verbose "Searching for $($tFile.DisplayName)" ; 
                #loop tabs for target displayname
                # Get the tab using the name
                # Finds the tab, but there's version bug in the SelectedPowerShellTab, doesn't like setting to the discovered $tab…
                if( $Name )  {
                    $found = 0 ;
                    if($host.version.major -lt 3){
                        for( $i = 0; $i -lt $psise.PowerShellTabs.Count; $i++){
                            write-verbose $psise.PowerShellTabs[$i].DisplayName ;
                            if( $psise.PowerShellTabs[$i].DisplayName -eq $Name ){
                                $tab = $psise.PowerShellTabs[$i] ;
                                $found++ ;
                            } ;
                        } ;
                        if($found -eq 0) {Throw ("Could not find a tab named " + $Name) } else {
                            $psISE.PowerShellTabs.SelectedPowerShellTab = $tab | select -first 1 ;
                        } ;
                    } else {
                        for( $i = 0; $i -lt $psise.PowerShellTabs.files.Count; $i++){
                            write-verbose $psise.PowerShellTabs.files[$i].DisplayName ;
                            if( $psise.PowerShellTabs.files[$i].DisplayName -eq $Name ){
                                $tab = $psise.PowerShellTabs.files[$i] ;
                                # it's doubtful you really need to cycle the 'files', vs postfilter; but postfilter works fine for $psISE.CurrentPowerShellTab.Files.SetSelectedFile
                                # (and SelectedPowerShellTab explicitly *doesnt* work anymore under ps5 at least, as written above in the ms learn exampls)
                                $targetFileTab =  $psise.PowerShellTabs.files | ?{$_.displayname -eq $Name} ;
                                $found++ ;
                            } ;
                        } ;
                        if($found -eq 0) {Throw ("Could not find a tab named " + $Name) } else {
                            #$psISE.PowerShellTabs.files.SelectedPowerShellTab = $tab | select -first 1 ;
                            $psISE.CurrentPowerShellTab.Files.SetSelectedFile(($targetFileTab | select -first 1))
                        } ;
                    } ;
                } ;
            } else {
                write-warning "No matching file in existing Tabs Files list found" ; 
            } ; 
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}

#*------^ show-ISEOpenTab.ps1 ^------


#*------v show-ISEOpenTabPaths.ps1 v------
function show-ISEOpenTabPaths {
    <#
    .SYNOPSIS
    show-ISEOpenTabPaths - Display a list fullname/paths of all currently open ISE tab files
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : show-ISEOpenTabPaths
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 10:09 AM 5/14/2024 init
    .DESCRIPTION
    show-ISEOpenTabPaths - Display a list fullname/paths of all currently open ISE tab files

    This is really only useful when you run a massive number of open file tabs, and visually scanning them unsorted is too much work. 
    When you want to see the paths of everything open, this outputs it to pipeline/console

    Nothing more than a canned up call of:
    PS> $psise.powershelltabs.files.fullpath
    .EXAMPLE
    PS> show-ISEOpenTabPaths
    simple exec
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('shIseTab')]
    PARAM() ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
    }
    PROCESS {
        if ($psise){
            $psise.powershelltabs.files.fullpath | write-output  ; 
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}

#*------^ show-ISEOpenTabPaths.ps1 ^------


#*------v show-Verbs.ps1 v------
Function show-Verbs {
    <#
    .SYNOPSIS
    show-Verbs.ps1 - Test specified verb for presense in the PS get-verb list.
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-01-20
    FileName    : show-Verbs.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,verbs
    AddedCredit : arsscriptum
    AddedWebsite: https://github.com/arsscriptum/PowerShell.Module.Core/blob/master/src/Miscellaneous.ps1
    AddedTwitter: 
    REVISION
    * 4:35 PM 7/20/2022 init; cached & subbed out redundant calls to get-verb; ; explict write-out v return ; fixed fails on single object counts; added pipeline support; 
        flipped DarkRed outputs to foreground/background combos (visibility on any given bg color)
    * 5/13/22 arsscriptum's posted copy (found in google search)
    .DESCRIPTION
    show-Verbs.ps1 - Test specified verb for presense in the PS get-verb list.
    .PARAMETER Verb
    Verb string to be tested[-verb report]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    Boolean
    .EXAMPLE
    'New' | show-Verbs ;
    Test the string as a standard verb
    .EXAMPLE
    show-verbs ; 
    Output formatted display of all standard verbs (as per get-verb)
    .EXAMPLE
    'show','new','delete','invoke' | show-verbs -verbose  ; 
    Show specs on an array of verbs with verbose output and pipeline input
    .EXAMPLE
    gcm -mod verb-io | ? commandType -eq 'Function' | select -expand verb -unique | show-Verbs -verbo
    Collect all unique verbs for functions in the verb-io module, and test against MS verb standard with verbose output
    .LINK
    https://github.com/tostka/verb-IO
    #>
    [CmdletBinding()]
    #[Alias('test-verb')]
    #[OutputType([boolean])]
    PARAM(
        [Parameter(Mandatory=$false,ValueFromPipeline = $true,HelpMessage="Verb string to be tested[-verb report]") ]
        [Alias('Name' ,'v', 'n','like', 'match')]
        [String[]]$Verb
    )   
    BEGIN {
        $verbose = ($VerbosePreference -eq "Continue") ; 
        $verbs = (get-verb) ; 
        $Groups = ($verbs | Select Group -Unique).Group ; 
    } ;
    PROCESS {
        foreach($item in $verb){
            write-verbose "(checking: $($item))" ; 
            #if ($PSBoundParameters.ContainsKey('Verb')) {
            $Formatted = ($verbs | where Verb -match $item| sort -Property Verb)
            if($Formatted){
                $FormattedCount = $Formatted |  measure | select -expand count ;
                Write-Host "Found $FormattedCount verbs" -f Black -b Gray -n ; 
                $Formatted | write-output ;  
            }else{
                Write-Host "No verb found" -f DarkGray -b White; 
            } ; 
            return ; 
        } ; 
        $Groups.ForEach({
                $g = $_
                $VerbsCount = $verbs | where group -eq $g |  measure | select -expand count ; 
                $Formatted = (($verbs | where Group -match $g | sort -Property Verb | Format-Wide  -Autosize | Out-String).trim()) ; 
                Write-Host "Verbs in category " -f Black -b Gray -n ; 
                Write-Host "$g ($VerbsCount) : " -f Yellow -b Gray  -n ; 
                Write-Host "`n$Formatted" -f DarkYellow -b Black ; 
            })
    } ;  # PROC-E
    END {} ; # END-E
}

#*------^ show-Verbs.ps1 ^------


#*------v split-CommandLine.ps1 v------
function Split-CommandLine {
    <#
    .SYNOPSIS
    Split-CommandLine - Parse command-line arguments using Win32 API CommandLineToArgvW function.
    .NOTES
    Version     : 1.6.2
    Author      : beatcracker
    Website     :	http://beatcracker.wordpress.com
    Twitter     :	@beatcracker / http://twitter.com/beatcracker
    CreatedDate : 2014-11-22
    FileName    : Split-CommandLine
    License     :
    Copyright   :
    Github      : https://github.com/beatcracker
    AddedCredit : Todd Kadrie
    AddedWebsite:	http://www.toddomation.com
    AddedTwitter:	@tostka / http://twitter.com/tostka
    REVISIONS
    * 8:21 AM 8/3/2020 shifted into verb-dev module
    * 1:17 PM 12/14/2019 TSK:Split-CommandLine():  minor reformatting & commenting
    * 11/22/2014 posted version
    .DESCRIPTION
    This is the Cmdlet version of the code from the article http://edgylogic.com/blog/powershell-and-external-commands-done-right. It can parse command-line arguments using Win32 API function CommandLineToArgvW .
    .PARAMETER  CommandLine
    This parameter is optional.
    A string representing the command-line to parse. If not specified, the command-line of the current PowerShell host is used.
    .EXAMPLE
    Split-CommandLine
    Description
    -----------
    Get the command-line of the current PowerShell host, parse it and return arguments.
    .EXAMPLE
    Split-CommandLine -CommandLine '"c:\windows\notepad.exe" test.txt'
    Description
    -----------
    Parse user-specified command-line and return arguments.
    .EXAMPLE
    '"c:\windows\notepad.exe" test.txt',  '%SystemRoot%\system32\svchost.exe -k LocalServiceNetworkRestricted' | Split-CommandLine
    Description
    -----------
    Parse user-specified command-line from pipeline input and return arguments.
    .EXAMPLE
    Get-WmiObject Win32_Process -Filter "Name='notepad.exe'" | Split-CommandLine
    Description
    -----------
    Parse user-specified command-line from property name of the pipeline object and return arguments.
    .LINK
    https://github.com/beatcracker/Powershell-Misc/blob/master/Split-CommandLine
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandLine
    ) ;
    Begin {
        $Kernel32Definition = @'
            [DllImport("kernel32")]
            public static extern IntPtr GetCommandLineW();
            [DllImport("kernel32")]
            public static extern IntPtr LocalFree(IntPtr hMem);
'@ ;
        $Kernel32 = Add-Type -MemberDefinition $Kernel32Definition -Name 'Kernel32' -Namespace 'Win32' -PassThru ;
        $Shell32Definition = @'
            [DllImport("shell32.dll", SetLastError = true)]
            public static extern IntPtr CommandLineToArgvW(
                [MarshalAs(UnmanagedType.LPWStr)] string lpCmdLine,
                out int pNumArgs);
'@ ;
        $Shell32 = Add-Type -MemberDefinition $Shell32Definition -Name 'Shell32' -Namespace 'Win32' -PassThru ;
        if (!$CommandLine) {
            $CommandLine = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Kernel32::GetCommandLineW());
        } ;
    } ;

    Process {
        $ParsedArgCount = 0 ;
        $ParsedArgsPtr = $Shell32::CommandLineToArgvW($CommandLine, [ref]$ParsedArgCount) ;

        Try {
            $ParsedArgs = @();

            0..$ParsedArgCount | ForEach-Object {
                $ParsedArgs += [System.Runtime.InteropServices.Marshal]::PtrToStringUni(
                    [System.Runtime.InteropServices.Marshal]::ReadIntPtr($ParsedArgsPtr, $_ * [IntPtr]::Size)
                )
            }
        }
        Finally {
            $Kernel32::LocalFree($ParsedArgsPtr) | Out-Null
        } ;

        $ret = @() ;

        # -lt to skip the last item, which is a NULL ptr
        for ($i = 0; $i -lt $ParsedArgCount; $i += 1) {
            $ret += $ParsedArgs[$i]
        } ;

        return $ret ;
    } ;
}

#*------^ split-CommandLine.ps1 ^------


#*------v Step-ModuleVersionCalculated.ps1 v------
function Step-ModuleVersionCalculated {
    <#
    .SYNOPSIS
    Step-ModuleVersionCalculated.ps1 - Increment a fresh revision of specified module via profiled changes compared to prior semantic-version 'fingerprint' (or Percentage change).
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-10-09
    FileName    : 
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell
    AddedCredit : Kevin Marquette
    AddedWebsite: https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/
    AddedTwitter: 
    AddedCredit : Martin Pugh (revision code on file change percent)
    AddedWebsite: www.thesurlyadmin.com
    AddedTwitter: @thesurlyadm1n
    REVISIONS
    * 8:16 AM 1/16/2024 added gcm commands return shortage comment in re: in-line internal funcs throwing off the count (as raw goes after those as full blown funcs, while gcm doesn't return/count them)
    * 3:32 PM 11/29/2023 add test-modulemanifest error testing (cap -errorvariable and eval), it doesn't actually returna $false test, just the parsed xml, where there's an unresolvable FileList entry. 
    * 8:02 AM 6/23/2023 fix: #433: # 2:20 PM 6/22/2023 if you're going to use a param with boolean, they have to be colon'd: -PassThru:$true (built into v1.5.26)
    * 2:18 PM 6/2/2023 added: Try/Catch around all critical items; added test for .psm1 diverge <<<<<< HEAD tags; expanded ipmo -fo -verb tests to include ErrorVariable and Passthru, capture into variable, for info tracking down compile fails.
    * 11:20 AM 12/12/2022 completely purged verb-* require stmts too risky w recursive load triggers:,verb-IO, verb-logging, verb-Mods, verb-Text
    * 3:57 PM 5/26/2022 backstop profile rgxs ; implment pre-cache & post-reload of installed modules ; 
        found can rmo the temp module ipmo, by targeting gmo | path, rather than common name (like verb-io). ; 
        fixed asset of $bumpVersionType = $MinVersionIncrementBump (was dropping 'Patch' through, rather than 'build')
    * 10:56 AM 5/20/2022 WIP: add: validator for ... ; -MinVersionIncrementBump (coerce Min fail through rev to Build; or use as explicit step driver, constant, rather than hard-coded in code) ; 
        address gcm bug where failing to return any but 3 old renamed funcs from verb-io.psm1: 
        add $ASTMatchThreshold (reps min percentage match gcm to sls -pattern parse of function lines in .psm1), along with a raft of new eval testing code. 
        tried running AST profiling to pull functions & aliases, but takes _3Mins_ to run. Simpler, and 90% effective to do an sls parse.
    * 2:29 PM 5/16/2022 add: backup-fileTDO of the fingerprintfile
    * 9:42 AM 1/18/2022 added test for recursed nested #requires -module [modname] 
        strings - this one's a brute to recover from, just like the version clash, both 
        hard-break build and require reverting installed rev of module to get past. 
        Everything works, bbuild, publish, install, except the trailing ipmo dies 
        *hard* ; updated $rgxRequreVersionLine prefix (\s|^) to suppress returns of double-#'d rem'd requires lines.
    * 2:09 PM 10/26/2021 requires vers code: only run if $PsFilesWVers populated ; shifted 'good' exit to within bumpvers test, and output $false otherwise ; updated mult #requires code to profile -version variants, and look for -gt 1; added verbose dump of Minor/Major changes in trailing outputs. 
    * 3:46 PM 10/25/2021 fingerprint code was dropping matches into pipeline, and blowing up returned bumprev string (ingested the outputs) ; added .psm1 test for multi '#requires -version' (crashes all ipmos) ; add verbose support into all the splats
    * 2:19 PM 10/16/2021 actually implemented the new -Silent param ; updated ModuleName locater; 
    * 6:11 PM 10/15/2021 rem'd # raa, replaced psd1/psm1-location code with Get-PSModuleFile(), which is a variant of BuildHelpers get-psModuleManifest. 
    * 2:51 PM 10/13/2021 subbed pswls's for wv's ; added else block to catch mods with inconsistent names between root dir, and .psm1 file, (or even .psm1 location); added path to sBnr
    * 3:55 PM 10/10/2021 added output of final psd1 info on applychange ; recoded to use buildhelper; added -applyChange to exec step-moduleversion, and -NoBuildInfo to bypass reliance on BuildHelpers mod (where acting up for a module). 
    * 9:08 PM 10/9/2021 init version
    .DESCRIPTION
    Step-ModuleVersionCalculated.ps1 - Profile a fresh revision of specified module for changes compared to prior semantic-version 'fingerprint'.
    
    ## relies on BuildHelpers module, and it's Set-BuildEnvironment profiling tool, and Step-ModuleVersion manifest .psd1-file revision-incrementing tool. 

    - step-ModuleVersion() supports -By: "Major", "Minor", "Build","Patch"

    ## -Method: Default via 'Fingerprint': 
        
        'Fingerprint' assumes a prior pass of the Initialize-ModuleFingerpring function:
        
        ```powershell
        Initialize-ModuleFingerprint -path 'C:\sc\Get-MediaInfo' -whatif -verbose ;
        ```

        ... which creates & populates a 'fingerprint' file in the root of the module, summarizing the commands and parameters within the module. 

        When Step-ModuleVersionCalculated is run, with default Method:Fingerprint, 
        the prior fingerprint file contents are compared to the current module content, 
        and the choice between Major|Module|Patch revision step level is made on the following basis:
            - Major reflets breaking changes - removed commands and parameters that previously existed
            - Minor reflects enhancements - new commands and parameters that did not previously exist
            - Patch lesser modifications that neither add functions/commands or parameters, nor remove same. 
            
            Semantic versioning (aka SemVer), supports an optional pre-release tag and optional build meta tag (1.2.0-a.1)
            [Semantic Versioning 2.0.0 | Semantic Versioning - semver.org/](https://semver.org/)

    ## Optional Method is via 'Percentage'

        'Percentage' profiles all files in the Module, for changes after the LastWriteDate after the existing .psd1 file. 
        Changes as a percentage of all of the files, are caldulated on the following basis:

            - Major, 50% or more changes to files 
            - Minor, 10 - 25% changes to files 
            - Patch, 10% or less % or more changes to files 
            Semantic Variable standard also supports Builds, and logic is in place in this 
            function (sub 5%), but BuildHelper:Step-ModuleVersion() does not currently 
            support Build level revisions.  
    
    .PARAMETER Path
    Path to root directory of the Module[-path 'C:\sc\PowerShell-Statistics\']
    .PARAMETER Method
    Version level calculation basis (Fingerprint[default]|Percentage)[-Method Percentage]
    .PARAMETER MinVersionIncrement
    Switch to force-increment ModuleVersion by minimum step (Patch), regardless of calculated changes[-MinVersionIncrement]
    .PARAMETER MinVersionIncrementBump
    Step increment level used with -MinVersionIncrementBump parameter (Major|Minor|Build|Patch, defaults to 'Build')[-MinVersionIncrementBump 'Patch']
    .PARAMETER applyChange
    switch to apply the Version Update (execute step-moduleversion cmd)[-applyChange]
    .PARAMETER Silent
    Suppress all but error-related outputs[-Silent]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    System.Boolean
    .EXAMPLE
    PS> Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo' -whatif -verbose ;
    Fingerprint the specified module path, with whatif and verbose specified
    .EXAMPLE
    PS> Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo'  -verbose -NoBuildInfo ;
    Using option to exclude leveaging BuildHelper module (where it fails to properly process a given module, and 'hangs' with normal processing). 
    .EXAMPLE
    PS> Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo'  -verbose -NoBuildInfo -applyChange ;
    Demo -applyChange option to apply Step-ModuleVersion immediately.
    .EXAMPLE
    PS> Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo'  -verbose -Method Percentage -applyChange ;
    Demo use of the optional 'Percentage' -Method (vs default 'Fingerprint' basis). 
    .EXAMPLE
    PS> $newRevBump = Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo' ;
    PS> Step-ModuleVersion -path 'C:\sc\Get-MediaInfo\MediaInfo.psd1' -By $newRevBump ;
    Analyze the specified module, calculate a revision BumpVersionType, and return the calculated value tp the pipeline
    Then run Step-ModuleVersion -By `$bumpVersionType to increment the ModuleVersion (independantly, rather than within this function using -ApplyChange)
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/
    #>
    #Requires -Version 3
    #Requires -Modules BuildHelpers
    ##Requires -RunasAdministrator    
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to root directory of the Module[-path 'C:\sc\PowerShell-Statistics\']")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$Path,
        [Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Version level calculation basis (Fingerprint[default]|Percentage)[-Method Percentage]")]
        [ValidateSet("Fingerprint","Percentage")]
        [string]$Method='Fingerprint',
        [Parameter(HelpMessage="Switch to force-increment ModuleVersion by minimum step (as per `$MinVersionIncrementBump), regardless of calculated changes[-MinVersionIncrement]")]
        [switch] $MinVersionIncrement,
        [Parameter(HelpMessage="Step increment level used with -MinVersionIncrementBump parameter (Major|Minor|Build|Patch, defaults to 'Build')[-MinVersionIncrementBump 'Patch']")]
        [ValidateSet('Major','Minor','Build','Patch')]
        $MinVersionIncrementBump = 'Build',
        [Parameter(HelpMessage="switch to apply the Version Update (execute step-moduleversion cmd)[-applyChange]")]
        [switch] $applyChange,
        [Parameter(HelpMessage="Suppress all but error-related outputs[-Silent]")]
        [switch] $Silent,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN { 
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;

        $sBnr="#*======v RUNNING :$($CmdletName):$($Path) v======" ; 
        $smsg = "$($sBnr)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        
        # Get parameters this function was invoked with
        #$PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
        
        # backstop profile rgxs
        if(-not $rgxModsSystemScope){$rgxModsSystemScope = "^[A-Za-z]:\\Windows\\system32\\WindowsPowerShell\\v1\.0\\Modules\\" } ;
        if(-not $rgxPSAllUsersScopeDyn){$rgxPSAllUsersScopeDyn = "^C:\\Program\ Files\\((Windows)*)PowerShell\\(Scripts|Modules)\\.*\.(ps(((d|m))*)1|dll)$" ; } ;
        if(-not $rgxPSCurrUserScope ) {$rgxPSCurrUserScope = "^[A-Za-z]:\\Users\\\w*\\((OneDrive\s-\s.*\\)*)Documents\\((Windows)*)PowerShell\\(Scripts|Modules)\\.*\.(ps((d|m)*)1|dll)$" } ; 
        $rgxRequireVersionLine = '(\s|^)#requires\s+-version\s' ;
        $rgxRequireModNested = "(\s|^)#Requires\s+-Modules\s+.*,((\s)*)$($ModName)" ;  # added: either BOL or after a space
        $rgxFuncDeclare = '(^|((\s)*))Function\s+[\w-_]+\s+((\(.*)*)\{' ;  # supports opt inline param syntax as well; and func names made from [A-Za-z0-9-_]chars

        if($whatif -AND -not $applyChange){
            $smsg = "You have specified -whatif, but have not also specified -applyChange" ; 
            $smsg += "`nThere is no reason to use -whatif without -applyChange."  ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            elseif(-not $Silent){ write-host -foregroundcolor yellow "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ; 
        
        # add filter for BOL or \s lead, drop the ##-rem'd lines
        #$rgxRequireVersionLine = '(\s|^)#requires\s+-version\s' ;
        # also should check for nested recursion - ensure the Module isn't in any #requires\s-module
        # '((\s)*)#Requires\s+-Modules\s+.*,((\s)*)verb-exo' ; # module name
        # $Path will be c:\sc\verb-exo ; split-path c:\sc\verb-exo -leaf gets you the modulename back
        $ModName = split-path -Path $path -leaf ; 
        #$rgxRequireModNested = "(\s|^)#Requires\s+-Modules\s+.*,((\s)*)$($ModName)" ;  # added: either BOL or after a space
        $ASTMatchThreshold = .8 ; # gcm must be w/in 80% of AST functions count, or this forces a 'Build' revision, to patch bugs in get-command -module xxx, where it fails to return full func/alias list from the module
        # increment bump used with -MinVersionIncrementBump
        #$MinVersionIncrementBump = 'Build' # moved to a full param, to permit explicit build spec, using step-ModuleVersionCalculated - adds the followup testing etc this provides, wo the fingerprinting

    } ;  # BEGIN-E
    PROCESS {
        $error.clear() ;
        $smsg = "profiling existing content..."
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

        $error.clear() ;
        TRY {
            $Path = $moddir = (Resolve-Path $Path).Path ; 
            $moddirfiles = get-childitem -path $path -recur 
            #-=-=-=-=-=-=-=-=
                                                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                        
            if(-not (get-command Get-PSModuleFile -ea 0)){
                function Get-PSModuleFile {
                    [CmdletBinding()]
                    PARAM(
                        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to project root. Defaults to the current working path [-path 'C:\sc\PowerShell-Statistics\']")]
                        [ValidateScript({Test-Path $_ -PathType 'Container'})]
                        [string]$Path = $PWD.Path,
                        [Parameter(HelpMessage="Specify Module file type: Module .psm1 file or Manifest .psd1 file (psd1|psm1 - defaults psd1)[-Extension .psm1]")]
                        [ValidateSet('.psd1','.psm1','both')]
                        [string] $Extension='.psd1'
                    ) ;

                    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
                    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
                    $sBnr="#*======v RUNNING :$($CmdletName):$($Extension):$($Path) v======" ; 
                    $smsg = "$($sBnr)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                    if($Extension -eq 'Both'){
                        [array]$Exts = '.psd1','.psm1'
                        write-verbose "(-extension Both specified: Running both:$($Exts -join ','))" ; 
                    } else {
                        $Exts = $Extension ; 
                    } ; 
                    $Path = ( Resolve-Path $Path ).Path ; 
                    $CurrentFolder = Split-Path $Path -Leaf ;
                    $ExpectedPath = Join-Path -Path $Path -ChildPath $CurrentFolder ;
        
                    foreach($ext in $Exts){
                        $ExpectedFile = Join-Path -Path $ExpectedPath -ChildPath "$CurrentFolder$($ext)" ;
                        if(Test-Path $ExpectedFile){$ExpectedFile  } 
                        else {
                            # Look for properly organized modules (name\name.ps(d|m)1)
                            $ProjectPaths = Get-ChildItem $Path -Directory |
                                ForEach-Object {
                                    $ThisFolder = $_ ;
                                    write-verbose "checking:$($ThisFolder)" ; 
                                    $ExpectedFile = Join-Path -path $ThisFolder.FullName -child "$($ThisFolder.Name)$($ext)" ;
                                    If( Test-Path $ExpectedFile) {$ExpectedFile  } ;
                                } ;
                            if( @($ProjectPaths).Count -gt 1 ){
                                Write-Warning "Found more than one project path via subfolders with psd1 files" ;
                                $ProjectPaths  ;
                            } elseif( @($ProjectPaths).Count -eq 1 )  {$ProjectPaths  } 
                            elseif( Test-Path "$ExpectedPath$($ext)" ) {
                                write-verbose "`$ExpectedPath:$($ExpectedPath)" ; 
                                #PSD1 in root of project - ick, but happens.
                                "$ExpectedPath$($ext)"  ;
                            } elseif( Get-Item "$Path\S*rc*\*$($ext)" -OutVariable SourceFiles)  {
                                # PSD1 in Source or Src folder
                                If ( $SourceFiles.Count -gt 1 ) {
                                    Write-Warning "Found more than one project $($ext) file in the Source folder" ;
                                } ;
                                $SourceFiles.FullName ;
                            } else {
                                Write-Warning "Could not find a PowerShell module $($ext) file from $($Path)" ;
                            } ;
                        } ;
                    } ; 
                    $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                }
                ##-=-=-=-=-=-=-=-=
            }

            $psd1M = Get-PSModuleFile -path $Path -ext .psd1 -verbose:$($VerbosePreference -eq 'Continue');
            $psm1 = Get-PSModuleFile -path $Path -ext .psm1 -verbose:$($VerbosePreference -eq 'Continue' ); 

            if($diverged = get-childitem -path $psm1 | select-string -pattern '<<<<<<<\sHEAD'){
                $smsg = "PSM1:$($PSM1)`nFOUND TO HAVE *DIVERGE* DAMAGE IN THE FILE!" ; 
                $smsg += "`n$(($diverged | ft -a linenumber,line|out-string).trim())" ; 
                $SMSG += "(if the diff has passed the source, restore the prior build's clean .psm1|psd1 & _TMPs, then reprocess)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                BREAK ; 
            } 

            if ((split-path (split-path $psd1m) -leaf) -eq (get-childitem $psd1m).basename){
                $ModuleName = split-path -leaf (split-path $psd1m) 
            } else {throw "`$ModuleName:Unable to match psd1.Basename $((get-childitem $psd1m).basename) to psd1.parentfolder.name $(split-path (split-path $psd1m) -leaf)" }  ;
        
            # check for incidental ipmo crasher: multiple #require -versions, pretest (everything to that point is fine, just won't ipmo, and catch returns zippo)
            # no, revise, it's multi-versions of -vers, not mult instances. Has to be a single version spec across entire .psm1 (and $moddir of source files)
            if($PsFilesWVers = get-childitem $moddir -include *.ps*1 -recur | sls -Pattern $rgxRequireVersionLine){
                # only run if $PsFilesWVers populated
                $profilePsFilesVersions = $PsFilesWVers.line | %{$_.trim()} | group ;
                if($profilePsFilesVersions.count -gt 1){
                    # $PsFilesWVers| ft -auto file*,line*
                    $smsg =  "MULTIPLE #requires -version strings matched in:`n$($psm1)`n(not-permited, wrecks ipmo) - psm1 and constitutent .ps1 files:`n$(($PsFilesWVers| ft -auto file*,line*|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $bRet=Read-Host "Enter YYY to continue *anyway*. Anything else will exit" 
                    if ($bRet.ToUpper() -eq "YYY") {
                            Write-host "Moving on"
                    } else {
                            Throw $smsg ; 
                    } ;
                } 
            } ; 
            <#if ((get-content $psm1 | sls -Pattern $rgxRequireVersionLine | measure).count -gt 1){
                $MultReqVers = (get-content $pltXMO.name | sls -Pattern $rgxRequireVersionLine) ; 
                $smsg =  "MULTIPLE #requires -version strings in:`n$($psm1)`n(not-permited, wrecks ipmo)`n$(($multreqvers | ft -auto Pattern,LineNumber,Line|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Warn } #Error|Warn|Debug 
                elseif(-not $Silent){ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Throw $smsg ; 
            } ; 
            #>
            # check for recursion call of the hosting module in subs: $rgxRequireModNested
            if($PsFilesWNestedMod = get-childitem $moddir -include *.ps*1 -recur | sls -Pattern $rgxRequireModNested){
                # only run if $PsFilesWNestedMod populated, and unique single entry of matches, trimmed
                $profilePsFilesRecursive = $PsFilesWNestedMod.line | %{$_.trim()} | group ;
                if($profilePsFilesRecursive.count -gt 0){
                    # $PsFilesWNestedMod| ft -auto file*,line*
                    $smsg =  "RECURSIVE #requires strings matched in:"
                    $smsg += "`n$($psm1)`n(not-permited, wrecks ipmo) - psm1 and constitutent .ps1 files:"
                    $smsg += "`nEDIT OUT any #requires -Modules line spec'ing '$($ModName) !'"
                    $smsg += "`nOR THIS MODULE BUILD WILL CRASH AND REQUIRE REVISION ROLLBACK!" 
                    $smsg += "`n$(($PsFilesWNestedMod| ft -auto file*,line*|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $bRet=Read-Host "Enter YYY to continue *anyway*. Anything else will exit" 
                    if ($bRet.ToUpper() -eq "YYY") {
                            Write-host "Moving on"
                    } else {
                            Throw $smsg ; 
                    } ;
                } 
            } ; 

        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
            $smsg += "`n$($ErrTrapd.Exception.Message)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #-=-record a STATUSWARN=-=-=-=-=-=-=
            $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
            if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
            if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
            #-=-=-=-=-=-=-=-=
            BREAK ;
        } ; 
        $error.clear() ;
        TRY { 
            $pltXMO=@{Name=$null ; force=$true ; ErrorAction='STOP'; Verbose = $($VerbosePreference -eq 'Continue') } ;
            $pltXpsd1M=[ordered]@{path=$psd1M ; ErrorAction='STOP'; Verbose = $($VerbosePreference -eq 'Continue') } ; 

            $smsg = "Import-PowerShellDataFile w`n$(($pltXpsd1M|out-string).trim())" ;                         
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $PsdInfoPre = Import-PowerShellDataFile @pltXpsd1M ;
            # add error testing
            $smsg = "test-ModuleManifest w`n$(($pltXpsd1M|out-string).trim())" ;                         
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            if($TestReport = test-modulemanifest @pltXpsd1M -errorVariable ttmm_Err -WarningVariable ttmm_Wrn -InformationVariable ttmm_Inf){
                if($ttmm_Err){
                    $smsg = "`nFOUND `$ttmm_Err: test-ModuleManifest HAD ERRORS!" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    foreach($errExcpt in $ttmm_Err.Exception){
                        switch -regex ($errExcpt){
                            "The\sspecified\sFileList\sentry\s'.*'\sin\sthe\smodule\smanifest\s'.*.psd1'\sis\sinvalid\." {
                                $smsg = "`nPSD1 Manifest has FileList specification, with no matching file found in $($modroot)\$($ModuleName)\!" ;
                                $smsg += "`nThe PSD MUST be edited or rolled back to # FileList = @()  spec, to properly build"
                                $smsg += "`n(build update-NewModule will detect and re-add the FileList from scratch, fr files in \\(Docs|Licenses|Resource)\ or named (Resource|Licenses) (extensionless)" ;
                                $smsg += "`n`n to find the last psd1/.psd1_ with the empty spec:" ; 
                                $smsg += "`ngci C:\sc\$($ModuleName)\$($ModuleName)\*.psd1* | sort LastWriteTime |  sls -pattern `"#\sFileList\s=\s@\(\)`" | select -last 1; `n" ;  
                                $smsg += "`n$($errExcpt)" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            }
                            default {
                                $smsg = "`nPSD1 MANIFEST UNDEFINED TESTING ERROR!" ;
                                $smsg += "`nThe PSD MUST be edited or rolled back to a functional revision to properly build!"
                                $smsg += "`n(build update-NewModule will detect and re-add the FileList from scratch, fr files in \\(Docs|Licenses|Resource)\ or named (Resource|Licenses) (extensionless)" ;
                                $smsg += "`n$($errExcpt)" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            }
                        } ;
                    } ;
                    # abort build here broken psd1 manifest isn't going to build into any type of pkg
                    BREAK ; 
                } else {
                    $smsg = "(no `$ttmm_Err: test-ModuleManifest had no errors)" ;
                    if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                } ; 
                # ...
            } else { write-warning "$((get-date).ToString('HH:mm:ss')):Unable to locate psd1:$($pltXpsd1.path)" } ;
            if($? ){ 
                $smsg= "(Test-ModuleManifest:PASSED)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $ModuleName = $TestReport.Name ; 
            } 
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
            $smsg += "`n$($ErrTrapd.Exception.Message)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #-=-record a STATUSWARN=-=-=-=-=-=-=
            $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
            if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
            if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
            #-=-=-=-=-=-=-=-=
            BREAK ;
        } ; 
        $error.clear() ;
        TRY{
            # we need to precache the modules loaded - as rmo verb-io takes out both the build module and the installed, so we need a mechanism to put back the installed after testing
            $loadedMods = get-module ;
            $loadedInstalledMods = $loadedMods |?{ $_.path -match $rgxPSAllUsersScopeDyn -OR $_.path -match $rgxPSCurrUserScope -OR $_.path -match $rgxModsSystemScope}  ; 
            $loadedRevisedMods = $loadedMods |?{ $_.path -notmatch $rgxPSAllUsersScopeDyn -AND $_.path -notmatch $rgxPSCurrUserScope -ANd $_.path -notmatch $rgxModsSystemScope}  ; 
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
            $smsg += "`n$($ErrTrapd.Exception.Message)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #-=-record a STATUSWARN=-=-=-=-=-=-=
            $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
            if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
            if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
            #-=-=-=-=-=-=-=-=
            BREAK ;
        } ; 

        switch ($Method) {
            'Fingerprint' {

                $smsg = "Module:psd1M:calculating *FINGERPRINT* change Version Step" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                if($fingerprintfile = ($moddirfiles|?{$_.name -eq "fingerprint"}).FullName){
                    TRY{
                        $oldfingerprint = Get-Content $fingerprintfile ; 
                    } CATCH {
                        $ErrTrapd=$Error[0] ;
                        $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                        $smsg += "`n$($ErrTrapd.Exception.Message)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #-=-record a STATUSWARN=-=-=-=-=-=-=
                        $statusdelta = ";ERROR"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                        if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                        if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
                        BREAK ;
                    } ; 
                    if($psm1){
                        $pltXMO.Name = $psm1 # ipmo via full path to .psm1
                            
                        $smsg = "import-module w`n$(($pltXMO|out-string).trim())" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 

                        TRY{
                            #import-module @pltXMO ;
                            # add passthru/capture, and errovari, to try to capture something on fails
                            # 2:20 PM 6/22/2023 if you're going to use a param with boolean, they have to be colon'd
                            $ModResult = import-module @pltXMO -ErrorVariable 'vIpMoErr' -PassThru:$true ; 
                            if($vIpMoErr){
                                $smsg = "Force throwing ipmo error into catch" ;
                                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                                throw $vIpMoErr ;
                            } else {
                                $smsg = "Ipmo: PASSED" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            } ; 
                        }CATCH{
                            $ErrTrapd=$Error[0] ;
                            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $smsg = $ErrTrapd.Exception.Message ;
                            write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                            $smsg = "Test-ModuleTMPFiles:Unable to copy/ipmo/remove:$($pltIpmo.Name)" ;
                            write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                            #-=-record a STATUSWARN=-=-=-=-=-=-=
                            $statusdelta = ";ERROR"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                            if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                            if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;

                            if(-not $ErrTrapd -AND $vIpMoErr){
                                $smsg = "blank `$ErrTrapd, but populated `$vIpMoErr, recycling as reportable error..." ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                                $ErrTrapd = $vIpMoErr ; 
                                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $smsg = $ErrTrapd.Exception.Message ;
                                write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                                $smsg = "Test-ModuleTMPFiles:Unable to copy/ipmo/remove:$($pltIpmo.Name)" ;
                                write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                                #-=-record a STATUSWARN=-=-=-=-=-=-=
                                $statusdelta = ";ERROR"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                                if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                                if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
                            } ; 
                            Break ; 
                        } ; # TRY-E

                        TRY{
                            $commandList = Get-Command -Module $ModuleName # gcm doesn't support full path to module .psm1 
                            #$rgxFuncDeclare = '(^|((\s)*))Function\s+[\w-_]+\s+((\(.*)*)\{' ;  # supports opt inline param syntax as well; and func names made from [A-Za-z0-9-_]chars
                            $rawfunccount = get-childitem -path $psm1 | select-string -pattern $rgxFuncDeclare |  measure | select -expand count  ; 
                            <# 8:52 AM 5/18/2022 issue:
                                get-command -module verb-io is only returning the 3 renamed funcs 
                                gcm invoke-com*

                                CommandType     Name                                               Version    Source                                                                                                                                                                                                      
                                -----------     ----                                               -------    ------                                                                                                                                                                                                      
                                Function        Invoke-CommandAs                                   2.2        Invoke-CommandAs                                                                                                                                                                                            
                                Cmdlet          Invoke-Command                                     3.0.0.0    Microsoft.PowerShell.Core                                                                                                                                                                                   
                                Cmdlet          Invoke-CommandInDesktopPackage                     2.0.0.0    Appx    

                                    detect and redir the build process into step:BUILD, as the above completely breaks the fingerprint-based step process
                                    Otherwise it under revs the build.
                            #>
                            # use Select-String regex parse to prxy count # of funcs that roughly should come back from gcm w/in $ASTMatchThreshold
                            if( ($commandList.count / $rawfunccount) -lt $ASTMatchThreshold ){
                                $smsg = "get-command failed to return a complete Func/Alias list from $($ModuleName) -lt AST $($ASTMatchThreshold * 100)% match:" ; 
                                $smsg += "`n(or has significant BUILD-block etc _internal_ funcs, throwing count off)" ; 
                                $smsg += "`nAST profile (get-FunctionBlocks+get-AliasAssignsAST) returned:$($ASTCmds.count)"
                                $smsg += "`nFORCING STEP EVAL INTO '$($MinVersionIncrementBump)' TO WORK AROUND BUG" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                $MinVersionIncrement = $true ; 
                            } else { 
                                $smsg = "get-command $($ModuleName) -gt AST $($ASTMatchThreshold * 100)% match:" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            } ;
                        } CATCH {
                            $ErrTrapd=$Error[0] ;
                            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                            $smsg += "`n$($ErrTrapd.Exception.Message)" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            #-=-record a STATUSWARN=-=-=-=-=-=-=
                            $statusdelta = ";ERROR"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                            if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                            if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
                            BREAK ;
                        } ; 
                        <# AST based approach - dirt slow, adds 3min wait to the build process for 126 function .psm1:  better to regex sls out the functions and use that as a guage ^
                        # -----------
                        #if(( ($commandList.count / $rawfunccount) -lt $ASTMatchThreshold ) -AND (get-command get-FunctionBlocks) -AND (get-command get-AliasAssignsAST)){
                            $smsg = "(ASTprofile: get-FunctionBlocks $($ModuleName)..." ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            #$ASTfuncs = get-FunctionBlocks $ModuleName ; 
                            $ASTcmds = @() ; 
                            $ASTProfile = get-codeprofileast -path 'C:\sc\verb-IO\verb-IO\verb-IO.psm1' -Functions -aliases -verbose:$($VerbosePreference -eq "Continue")  ;
                            $ASTCmds = $ASTProfile.Functions.name ; 
                            $ASTCmds += $ASTProfile.Aliases.extent.text ; 
                            $diffCount = $ASTCmds.count - $commandList.name.count ;
                            $diffPerc = $commandList.name.count / $ASTCmds.count ; ;
                            if($diffPerc -lt $ASTMatchThreshold ){
                                $smsg = "get-command failed to return a complete Func/Alias list from $($ModuleName) -lt AST $($ASTMatchThreshold * 100)% match:" ; 
                                $smsg += "`nAST profile (get-FunctionBlocks+get-AliasAssignsAST) returned:$($ASTCmds.count)"
                                $smsg += "`nFORCING STEP EVAL INTO 'PATCH' TO WORK AROUND BUG" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                $MinVersionIncrement = $true ; 
                            } else { 
                                $smsg = "get-command $($ModuleName) -gt AST $($ASTMatchThreshold * 100)% match:" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            } ;

                        } else { 
                            $smsg = "Unable to gcm get-FunctionBlocks & get-AliasAssignsAST!" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Warn } #Error|Warn|Debug 
                            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            throw $smsg ;
                        } ;
                        # -----------
                        #>

                        #$pltXMO.Name = $ModuleName; # have to rmo using *basename*
                        <# revised: you can target specific like-named mods, using the path, which will vary:
                        gmo |?{$_.path -eq $psm1} | remove-module -WhatIf -verbose 
                        #>
                        $pltXMO.remove('Name') # 
                        #$smsg = "remove-module w`n$(($pltXMO|out-string).trim())" ; 
                        # get-module |where-object{$_.path -eq $psm1} | remove-module @pltXMO
                        $smsg = "get-module |where-object{`$_.path -eq '$($psm1)'} |remove-module w`n$(($pltXMO|out-string).trim())" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        #remove-module @pltXMO ;
                        TRY{
                            $tmpmodtarget = get-module |where-object{$_.path -eq $psm1} 
                            if($tmpmodtarget){ $tmpmodtarget | remove-module @pltXMO }
                            else {
                                $smsg = "Unable to isolate:" ; 
                                $smsg += "`nget-module |where-object{$_.path -eq $($psm1)}!" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level  WARN } #Error|Warn|Debug 
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            } ; 
                        } CATCH {
                            $ErrTrapd=$Error[0] ;
                            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                            $smsg += "`n$($ErrTrapd.Exception.Message)" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            #-=-record a STATUSWARN=-=-=-=-=-=-=
                            $statusdelta = ";ERROR"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                            if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                            if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
                            BREAK ;
                        } ; 

                        # here's where we should restore any missing $loadedInstalledMods, taken out with the build module by above rmo...
                        # post confirm instlmods still loaded:
                        $postpaths = (get-module |where-object {
                             $_.path -match $rgxPSAllUsersScopeDyn -OR $_.path -match $rgxPSCurrUserScope -OR $_.path -match $rgxModsSystemScope
                        }).path ; 
                        $loadedInstalledMods.path |foreach-object{
                            if($postpaths -contains  $_){
                                $smsg = "($($_):still loaded)" 
                                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                            }else{
                                $smsg = "ipmo missing installedmod:$($_)" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } 
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                #import-module $_ -fo -verb ;
                                TRY{
                                    $pltXMO.name = $_ ; 
                                    $ModResult = import-module @pltXMO -ErrorVariable 'vIpMoErr' -PassThru $true ;
                                    if($vIpMoErr){
                                        $smsg = "Force throwing ipmo error into catch" ;
                                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
                                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                                        throw $vIpMoErr ;
                                    } else {
                                        $smsg = "Ipmo: PASSED" ;
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                    } ;
                                }CATCH{
                                    $ErrTrapd=$Error[0] ;
                                    $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                    $smsg = $ErrTrapd.Exception.Message ;
                                    write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                                    $smsg = "Test-ModuleTMPFiles:Unable to copy/ipmo/remove:$($pltIpmo.Name)" ;
                                    write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                                    #-=-record a STATUSWARN=-=-=-=-=-=-=
                                    $statusdelta = ";ERROR"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                                    if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                                    if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
                                    if(-not $ErrTrapd -AND $vIpMoErr){
                                        $smsg = "blank `$ErrTrapd, but populated `$vIpMoErr, recycling as reportable error..." ;
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                        #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                                        $ErrTrapd = $vIpMoErr ;
                                        $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                        $smsg = $ErrTrapd.Exception.Message ;
                                        write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                                        $smsg = "Test-ModuleTMPFiles:Unable to copy/ipmo/remove:$($pltIpmo.Name)" ;
                                        write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                                        #-=-record a STATUSWARN=-=-=-=-=-=-=
                                        $statusdelta = ";ERROR"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                                        if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                                        if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
                                    } ;
                                    Break ;
                                } ; # TRY-E

                            } ;
                        } ; 


                        if(-not $MinVersionIncrement){
                            $smsg = "Calculating fingerprint"
                            # KM's core logic code:
                            $fingerprint = foreach ( $command in $commandList ){
                                $smsg = "(=cmd:$($command)...)" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                foreach ( $parameter in $command.parameters.keys ){
                                    $smsg = "(---param:$($parameter)...)" ;
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                    '{0}:{1}' -f $command.name, $command.parameters[$parameter].Name
                                    $command.parameters[$parameter].aliases | 
                                        Foreach-Object { '{0}:{1}' -f $command.name, $_}
                                };  
                            } ;   
                        } else { 
                            $smsg = "(-MinVersionIncrement: skipped fingerprint calculation)" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        } ; 
                        # step-ModuleVersion supports -By: "Major", "Minor", "Build","Patch"
                        # SemVers uses 3-digits, a prerelease tag and a build meta tag (only 3 are used in pkg builds etc)
                        $bumpVersionType = 'Patch' ; 
                        if($MinVersionIncrement){
                            $smsg = "-MinVersionIncrement override specified: incrementing by min .$($MinVersionIncrementBump)" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            #$Version.Build ++ ;
                            #$Version.Revision = 0 ; 
                            # drop through min patch rev above - no, it now uses $MinVersionIncrementBump
                            $bumpVersionType = $MinVersionIncrementBump ; 
                        } else { 
                            # KM's core logic code:
                            $smsg = "Detecting new features" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            # yank out the pipeline drops (or accumulate them)
                            $NewChgs = $BreakChgs =@() ; 
                            $fingerprint | Where {$_ -notin $oldFingerprint } | 
                                ForEach-Object {$bumpVersionType = 'Minor'; $NewChgs += "`n  $_"} ; 
                            $smsg = "Detecting breaking changes" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $oldFingerprint | Where {$_ -notin $fingerprint } | 
                                ForEach-Object {$bumpVersionType = 'Major'; $BreakChgs += "`n  $_"} ; 
                        } ;

                    } else {
                        $smsg = "No module .psm1 file found in tree of `$path:`n$($moddir)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Warn } #Error|Warn|Debug 
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        throw $smsg ;
                    } ;
                    
                } else {
                    $smsg =  "No fingerprint file found in `$path:`n$(join-path -path $moddir -child "$ModuleName.psm1")" ;
                    $smsg += "`nTo configure a fingerprint for this module, plese run:`n"
                    $smsg += "`nInitialize-ModuleFingerprint -path $($moddir) ;"
                    $smsg += "`n... and then re-run the Step-ModuleVersionCalculated cmdlet" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Warn } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    throw $smsg ;
                } ;  

                if ( $fingerprint ){

                    if($fingerprintfile){
                        write-verbose "(backup-FileTDO -path $($fingerprintfile))" ;
                        $fingerprintBU = backup-FileTDO -path $fingerprintfile -showdebug:$($showdebug) -whatif:$($whatif) ;
                        if(-not $FingerprintBU -AND -not $whatif){throw "backup-FileTDO -Source $($fingerprintfile)!" }
                    } else { 
                        write-verbose "(no fingerprint file to backup)" ;  
                    } ; 

                    $pltOFile=[ordered]@{
                        Encoding='utf8' ;
                        FilePath=(join-path -path $moddir -childpath 'fingerprint') ;
                        whatif=$($whatif) ;
                        Verbose = $($VerbosePreference -eq 'Continue')                     
                    } ;
                    $smsg = "Writing fingerprint: Out-File w`n$(($pltOFile|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    TRY{
                        $fingerprint | out-file @pltOFile ; 
                    } CATCH {
                        # or just do idiotproof: Write-Warning -Message $_.Exception.Message ;
                        $ErrTrapd=$Error[0] ;
                        $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $smsg = $ErrTrapd.Exception.Message ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #-=-record a STATUSWARN=-=-=-=-=-=-=
                        $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                        if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                        if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
                        #-=-=-=-=-=-=-=-=
                        $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
                    } ; 
                } else {
                    $smsg = "No funtional Module `$fingerprint generated for path specified`n$($Path)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ; 
            } 
            'Percentage' {
                # implement's Martin Pugh's revision step code on percentage of files changed after psd1.LastWriteTime
                $smsg = "Module:psd1M:calculating *PERCENTAGE* change Version Step" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                TRY{
                    $LastChange = (Get-ChildItem $psd1M).LastWriteTime ; 
                    $ChangedFiles = ($moddirfiles | Where LastWriteTime -gt $LastChange).Count ; 
                    $PercentChange = 100 - ((($moddirfiles.Count - $ChangedFiles) / $moddirfiles.Count) * 100) ; 
                } CATCH {
                    # or just do idiotproof: Write-Warning -Message $_.Exception.Message ;
                    $ErrTrapd=$Error[0] ;
                    $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $smsg = $ErrTrapd.Exception.Message ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #-=-record a STATUSWARN=-=-=-=-=-=-=
                    $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                    if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                    if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
                    #-=-=-=-=-=-=-=-=
                    $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
                } ; 
                $smsg = "PercentChange:$($PercentChange)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                #$Version = ([version]$Psd1PriorData.ModuleVersion) | Select Major,Minor,Build,Revision ; 
                # coerce Build & Revision:-1 to 0, handling; doesn't like it when rev is -1
                #$Version = ([version]$Psd1PriorData.ModuleVersion) | select Major,Minor,Build,@{name='Revision';Expression={[System.Math]::Max($_.revision,0)} }
                <#$Version = ([version]$Psd1PriorData.ModuleVersion) | select Major,Minor,
                    @{name='Build';Expression={[System.Math]::Max($_.Build,0)} },
                    @{name='Revision';Expression={[System.Math]::Max($_.revision,0)} }
                $PriorVers =  $Version | Select Major,Minor,Build,Revision
                #>
                if($MinVersionIncrement){
                    write-host -foregroundcolor green "-MinVersionIncrement override specified: incrementing by min:$($MinVersionIncrementBump)" ; 
                    #$Version.Build ++ ;
                    #$Version.Revision = 0 ; 
                    $bumpVersionType = $MinVersionIncrementBump  ; 
                } else { 
                    If ($PercentChange -ge 50){
                        #$Version.Major ++ ; # MAJOR (breaking change)
                        #$Version.Minor = 0 ; 
                        #$Version.Build = 0 ; 
                        #$Version.Revision = 0 ; 
                        $bumpVersionType = 'Major';
                    }ElseIf ($PercentChange -ge 25){
                        #$Version.Minor ++ ; # .MINOR (new feature - backward compatible)
                        #$Version.Build = 0 ; 
                        #$Version.Revision = 0 ; 
                        $bumpVersionType = 'Minor' ; 
                    }ElseIf ($PercentChagne -ge 10){
                        #$Version.Build ++ ; # NORMALLY .PATCH (bug fix)
                        #$Version.Revision = 0 ; 
                        $bumpVersionType = 'Patch'
                    }ElseIf ($PercentChange -gt 0){
                        #$Version.Revision ++ ; # NORMALLY +BUILD (pre-release and build metadata) # doesn't look like buildhelper  does 4-digit Build variants
                        $bumpVersionType = 'Patch' 
                    } ; 
                } ; 
            } ;
        } # switch-E

        if($TestReport -AND $applyChange ){ 
            $pltStepMV=[ordered]@{Path=$psd1M ; By=$bumpVersionType ; ErrorAction='STOP';} ; 

            $smsg = "Step-ModuleVersion w`n$(($pltStepMV|out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            if(!$whatif){
                # Step-ModuleVersion -Path $env:BHPSModuleManifest -By $bumpVersionType ; 
                Step-ModuleVersion @pltStepMV ; 
                $PsdInfo = Import-PowerShellDataFile -path $env:BHPSModuleManifest ;
                $smsg = "----PsdVers incremented from $($PsdInfoPre.ModuleVersion) to $((Import-PowerShellDataFile -path $env:BHPSModuleManifest).ModuleVersion)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            } else {
                $smsg = "(-whatif, skipping exec:`nStep-ModuleVersion -Path $($env:BHPSModuleManifest) -By $($bumpVersionType)) ;" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $PsdInfo.ModuleVersion | write-output ; 
            } ;
        } ; 
  
        
    } ;  # PROC-E
    END {
    
        if ( $bumpVersionType ){
            
            if(-not $applyChange){
                $hMsg =@"

$($Method) analysis recommends ModuleVersion Step:$($bumpVersionType). 

This can be implemented with the following command:

Step-ModuleVersion -Path $($psd1M) -By $($bumpVersionType)

(the above will use the BuildHelpers module to update the revision stored in the Manifest .psd1 file for the module).

"@ ; 
            } else {
                $hmsg = @"
$($Method) analysis recommended ModuleVersion Step:$($bumpVersionType). 

which was applied via the BuildHelper:Step-ModulerVersion cmdlet (above)

"@ ; 
            }; 

            $smsg = "`n$($hmsg)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            $smsg = "Minor/New-Feature Chgs:`n$(($NewChgs |out-string).trim())`n`nMajor/Removal/Breaking Chgs:`n$(($BreakChgs |out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 

            if($PsdInfo -AND $applyChange ){ 
                $smsg = "(returning updated ManifestPsd1 Content to pipeline)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $PsdInfo | write-output 
            } else {
                $smsg = "-applyChange *not* specified, returning 'bumpVersionType' specification to pipeline:" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #$PsdInfo.ModuleVersion | write-output 
                 $bumpVersionType | write-output  ; 
            } ; 

        } else {
            $smsg = "Unable to generate a 'bumpVersionType' for path specified`n$($Path)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $false | write-output  ; 
        } ; 

        $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;  # END-E
}

#*------^ Step-ModuleVersionCalculated.ps1 ^------


#*------v Test-ModuleTMPFiles.ps1 v------
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
    * 2:08 PM 3/22/2023 expanded catch's they were coming up blank; fixed spurious 'Unable to Add-ContentFixEncoding' error (completely offbase)
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
                $ErrTrapd=$Error[0] ;
                $PassStatus += ";ERROR";
                write-warning  "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                $smsg = $ErrTrapd.Exception.Message ;
                write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
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
                $smsg = $ErrTrapd.Exception.Message ;
                write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                $smsg = "Test-ModuleTMPFiles:Unable to copy/ipmo/remove:$($pltIpmo.Name)" ;
                write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                #-=-record a STATUSWARN=-=-=-=-=-=-=
                $statusdelta = ";ERROR"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ;
                
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
}

#*------^ Test-ModuleTMPFiles.ps1 ^------


#*------v test-VerbStandard.ps1 v------
Function test-VerbStandard {
    <#
    .SYNOPSIS
    test-VerbStandard.ps1 - Test specified verb for presense in the PS get-verb list.
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-01-20
    FileName    : test-VerbStandard.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,verbs
    REVISION
    * 3:00 PM 7/20/2022 init
    .DESCRIPTION
    test-VerbStandard.ps1 - Test specified verb for presense in the PS get-verb list.
    .PARAMETER Verb
    Verb string to be tested[-verb report]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    Boolean
    .EXAMPLE
    'New' | test-VerbStandard ;
    Test the string as a standard verb
    .EXAMPLE
    gcm -mod verb-io | ? commandType -eq 'Function' | select -expand verb -unique | test-verbstandard -verbo
    Collect all unique verbs for functions in the verb-io module, and test against MS verb standard
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('test-verb')]
    [OutputType([boolean])]
    PARAM (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Verb string to be tested[-verb report]")]
        [string] $Verb
    ) ;
    BEGIN {
        $verbose = ($VerbosePreference -eq "Continue") ; 
    } ;
    PROCESS {
        foreach($item in $verb){
            write-verbose "(checking: $($item))" ; 
            [boolean]((Get-Verb).Verb -match $item) | write-output ;
        } ; 
    } ;  # PROC-E
    END {} ; # END-E
}

#*------^ test-VerbStandard.ps1 ^------


#*------v Uninstall-ModuleForce.ps1 v------
Function Uninstall-ModuleForce {
    <#
    .SYNOPSIS
    Uninstall-ModuleForce.ps1 - Uninstalls a module (via Uninstall-Module -force), and then searches through all PSModulePath directories, and deletes any unregistered copies as well.
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-10
    FileName    : Uninstall-ModuleForce.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Module,Management,Lifecycle
    REVISIONS
    # 4:06 PM 8/21/2024 #135:empty PSModulePath entry causes this to crash out, post filter only populated!
    * 12:33 PM 1/17/2024 added RunAA pretest, and folder perms seize code
    * 10:10 AM 5/17/2022 updated post test, also don't want it to abort/break, on any single failure.
    * 11:11 AM 5/10/2022 init, split out process-NewModule #773: $smsg= "Removing existing profile $($ModuleName) content..."  block, to have a single maintainable shared func
    .DESCRIPTION
    Uninstall-ModuleForce.ps1 - Uninstalls a module (via Uninstall-Module -force), and then searches through all PSModulePath directories, and deletes any unregistered copies as well.
    Note: *installed* mods have PSGetModuleInfo.xml files
    .PARAMETER  ModuleName
    Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    PS> $pltUMF=[ordered]@{ ModuleName = $ModuleName ; Verbose = $($VerbosePreference -eq 'Continue') ; whatif=$($whatif); } ;
    PS> $smsg= "Uninstall-ModuleForce w`n$(($pltUMF|out-string).trim())" ;
    PS> if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
    PS> else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS> $bRet = Uninstall-ModuleForce @pltUMF ;
    PS> # check return for semi-colon-delimited specific error string
    PS> if($sRet){
    PS>     if([array]$sRet.split(';').trim() -contains 'uninstall-module:ERROR'){
    PS>         # or, work with raw ;-delim'd string: if($sret.indexof('uninstall-module:ERROR')){
    PS>         $smsg = "Uninstall-ModuleForce:uninstall-module:ERRO!"  ;
    PS>         write-warning $smsg ;
    PS>         throw $smsg ;
    PS>         # spec optional Break|Continue etc recovery cmd
    PS>     } ;
    PS> } else {
    PS>     $smsg = "(no `$sRet returned on call)" ;
    PS>     if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    PS>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    PS> } ; 
    Demo that displays running with a splat, and parsing the return'd PassStatus for Error entries in the array
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]")]
        [string[]] $ModuleName,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    )
    BEGIN {
        #region CONSTANTS-AND-ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        write-verbose -verbose:$verbose "`$PSBoundParameters:`n$(($PSBoundParameters|out-string).trim())" ;
        $Verbose = ($VerbosePreference -eq 'Continue') ;

        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ;
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ;
            write-verbose "(non-pipeline - param - input)" ;
        } ;
        
        if(-not(get-variable -Name whoamiAll -ea 0)){$whoamiAll = (whoami /all)} ;
        if([bool](($whoamiAll |Where-Object{$_ -match 'BUILTIN\\Administrators'}) -AND ($whoamiAll |
            Where-Object{$_ -match 'S-1-16-12288'}))){} else { 
                throw "Must be RunAsAdmin!" ; 
                BREAK ;
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

        foreach($Mod in $ModuleName){
            if($PsGInstalled=Get-InstalledModule -name $($Mod) -AllVersions -ea 0 ){
                foreach($PsGMod in $PsGInstalled){
                    $sBnrS="`n#*------v Uninstall PSGet Mod:$($PsGMod.name):v$($PsGMod.version) v------" ;
                    $smsg= $sBnrS ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $pltRmv = [ordered]@{
                        Force=$true ;
                        Whatif=$($whatif) ;
                        Verbose = $($VerbosePreference -eq 'Continue') ;
                    } ;
                    $sMsg = "Uninstall-Script w`n$(($pltRmv|out-string).trim())" ;
                    if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;} ;
                    $error.clear() ;
                    TRY {
                        get-module $PsGMod.installedlocation -listavailable |uninstall-module @pltRmv
                    } CATCH {
                        $ErrorTrapped = $Error[0] ;
                        $PassStatus += ";uninstall-module:ERROR";
                        $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #Exit #Opts: STOP(debug)|EXIT(close)|Continue(move on in loop cycle)
                    } ;
                    $smsg="$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
            } else {
                $smsg="(No:Get-InstalledModule -name $($Mod))" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ;
        

            # surviving conflicts locking install-module: need to check everywhere, loop the entire $env:psprofilepath list
            $smsg="(Processing `$env:PSModulePath paths, for surviving locked copies of $($Mod) to *manually* purge...)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            #$modpaths = $env:PSModulePath.split(';') ;
            # 4:06 PM 8/21/2024 empty PSModulePath entry causes this to crash out, post filter only populated!
            $modpaths = $env:PSModulePath.split(';') |?{$_} ;
            foreach($modpath in $modpaths){
                $smsg= "Checking: $($Mod) below: $($modpath)..." ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $searchPath = join-path -path $modpath -ChildPath "$($Mod)\*.*" ;
                # adding ownership seize before removal:
                if($mPath = get-item -path (join-path -path $modpath -ChildPath $Mod) -ea 0){
                    write-host "Seizing ownership:$($mPath.fullname)..." ;
                    takeown /F $mPath.fullname /A /R ;
                    icacls $mPath.fullname /reset ;
                    icacls $mPath.fullname /grant Administrators:'F' /inheritance:d /T ;
                } ; 
                # adding -GracefulFail to get past locked verb-dev cmdlets
                $bRet = remove-ItemRetry -Path $searchPath -Recurse -showdebug:$($showdebug) -whatif:$($whatif) -GracefulFail ;
                #if (-not$bRet) {throw "FAILURE" ; Break ; } ;
                if(-not $bRet -AND -not $whatif){throw "remove-ItemRetry -Path $($searchPath)!" } else {
                    $PassStatus += ";UPDATED:remove-ItemRetry ";
                }  ;
            } ;
        } ;  # loop-E

    } ;  # PROC-E
    END {
        #$stopResults = try {Stop-transcript -ErrorAction stop} catch {} ;
        #write-host $stopResults ;
        # the $PassStatus updates should have been global, but if not, return what we have and post-test for ";new-item:ERROR"; V ";new-item:UPDATED";
        $PassStatus | write-output ;
    } ;  # END-E
}

#*------^ Uninstall-ModuleForce.ps1 ^------


#*------v update-NewModule.ps1 v------
function update-NewModule {
    <#
    .SYNOPSIS
    update-NewModule - Hybrid Monolithic/Dynam vers post-module conversion or component update: sign, publish to repo, and install back script
    .NOTES
    Version     : 1.1.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twittegbpgcm gbp
r.com/tostka
    CreatedDate : 2020-02-24
    FileName    : update-NewModule.ps1
    License     : MIT License
    Copyright   : (c) 2021 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Module,Build,Development
    REVISIONS
    * 11:55 AM 4/11/2025 shifted pscore install test from wt hardcode to test $isCoreCLR; fixed missing semis ; trailing lines to properly unwrap the install block herestrings (wt doesn't paste cleanly multiline blocks)
    * 4:17 PM 1/21/2025 I *think* I've tracked down the .help.txt mis-includes in build to #748: updated $rgxPsd1FileListExcl to properly cover buildBlind, in addition to other dirs and file substrings
    * *3:58 PM 1/20/2025 added another $killfiles block just before trailing log cleanup ;  address new .\Help\*.help.txt ref files (not part of build): mkdir verb-x\buildBlind, moved Help to below it, add:$gciExcludes = @(...,'*.help.txt','buildBlind'); & to $excludeMatch; 
         ren $exclude -> $gciExcludes, and add $gciExcludes = @(...,'*.help.txt') ; 
    * 3:30 PM 9/17/2024 added ps7 test & warning;  retooled trailing process (new WinTerm install eating into ps7 by default -> confusion)  added gmo -name `$tmod | ? version -ne `$tVer | rmo -Force -Verbose  to update procedure output (ensure old in-mem obso copies are out of memory)
    * 2:59 PM 8/29/2024 recoded post install report output, found on LYN-9C5CTV3 an 
        obsolete copy of verb-io 11.x that didn't show from uninstall-module, but did 
        for gcm xxx ; added code to force delete the whole \Modules\[verb-xxx] tree 
        recursive before installing repo copy. Also added dyn repo discovery (from 
        $pslocalRepo in profile) and autosteering on scope. It's same SB on both 
        scopes, w differnt scop input. 
    * 5:10 PM 8/28/2024 still throwing oddball param errs calling set-AuthenticodeSignatureTDO (says showedebug doesn't exist, though I added it and have iflv'd the update); rem the splat showdebug.
    * 5:00 PM 8/26/2024 also rplc sign-file -> set-AuthenticodeSignatureTDO, that should keep it from pulling obsolete sign-file out of the built mod, mid pass ; swapped out all existing catch blocks with the -force block, to try to get usable errors out (and avoid need to step dbg issues)
    * 10:19 AM 8/19/2024 updated w-h to use full export-clixml, where was referring to custom local alias
    * 4:12 PM 7/12/2024 fixed bad path in recovery copy for following too; missing file bug/recoverable down in 'Move/Flatten Resource etc files into root of temp Build dir...', added broad recovery instructions (reinstall from repo, latest vers, buffer in the .psd1/.psm1 from repo copy, rerun)
    * 8:52 AM 12/12/2023 fixed typo trailing log echo #2771 (and added ref to both currlog & perm copy stored at uwps\logs)
    * 3:14 PM 12/11/2023 added expl for reset-ModuleBuildFail.ps1 cleanup pass ; 
        vazure bombed on build, missing LICENSE.TXT, so used leaf 
        dest spec on the re-copy - actually fix may be to premptively run 
        reset-ModuleBuildFail.ps1 ahead of any rebuild - could be the issue was 
        deadwood inapprop in the sc\modname\modname\ dir;   (prior was all built into 
        vdev v1.5.42, didn't error out, but didn't fire the new re-copy-item code 
        either) ; ammended fail of test, to re-copy missing file into 
        cumods\modname\modname, prior to pbmo run (testing w vdev rebuild) ;confirmed, 
        vnet finally built, with the pass pre-conffirming the CUMods\modname\modname 
        contained all files cited in the psd1.filelist (not sure what diff that makes, 
        it didn't actually copy them if missing...);  
    * 3:40 PM 12/8/2023 WIP: dbging #2017, just fixed typo, intent is to loop out and preverif the modname\modname has the files in the cu mods modname.psd1, before the next step test-modulemanifest, and the followon pbmod, that has been bombing for verb-network.
        - added code pre pbmod, & test-mani, to pull the cached CUMods\modname\modname\psd1, loop the scModNameModname psd1.filelist, and verify that the CUMods copy has each filelist entry present.
    * 4:34 PM 12/6/2023
        ADD:
        - finding $Modroot blank, so coercing it from the inbound $sModDirPath
        - $rgxModExtIncl: added trailing '$' to test to end of ext, as wo it was matching on extensions that *start* with the above, even if named .xml_TMP.
        - $iSkipAutomaticTagsThreshold = 2000 ; # number of chars of comma-quote-delim'd public function names, as a string array, to establish a threshold to use SkipAutomaticTags with publish-module (NugGet bug workaround)
            # issue is: powershellget automatic tags all exported function and hangs when u go over 4000 characters can be avoided by SkipAutomaticTags on publish-module
        - code to guestimate function-array as tags, and dyn add -SkipAutomaticTags  to publish-module, to suppress bug above, for mods with large # of functions.
        - echo Discovered mod-copy files
        - capture the mkdir output (pipeline spam)
        - as Publish-Module returns a garbage string-array -errorvariable, even when it passes and doesn't trigger CATCH, I just flipped the post errorvariable test to echo it's content, with no action. Insuff info returned to have the result acted upon. (garbage)
        added CBH demo of code to review repo's below c:\sc\verb-* root, for errantly includable files (you'd want to remove to avoid publishing).
    * 4:44 PM 12/5/2023 psd1.Filelist: select uniques, showing mults in the resulting array in psd1.filelist; added -errorvariable to all ipmo's w validation; added -errvari & validation to the Publish-module as well (blows through, wo killing build otherwise)
    * 3:20 PM 12/4/2023 
        removed all [#]requires stmts (main, and populate-ModulePublishingDirectory(), had runasadmin, blocking install as UID)
        Prior:
        - expanded CBH, added dir structure
        - add -errorvariable & analysis to ipmo post-build test
        - genericize strings
        - prepop missing modname\modname dir
        - add errorvari to ipmo & ismo 
        - * rplc !$whatif -> -not($whatif)
        Prior:         Last pass on curr fixes, with inline debugging fixes, ran to completion, first time since October 12 2023. 
        It now properly supports psd1 manifest FileList and (Docs|Licenses|Resource) dir build-in components through that setting.
        cleanup, typo fix, splice over final updates:
        - add: $rgxInclOutLicFileName = '^LICENSE' ; # id's local extensionless vdev\vdev lic files that *should* remain
        - flip ww to wl on non-impacting obsolete test
        - update bannedfiles logic to pass/permit non-extension LICENSE files in modname\modname build/output dir
        - add verbose output to the file cleanup removals, to record what went when
        - NOPE:block rem newly redundant flatten resources to modname\modname code (already complete further up the function) (necessary to ensure populated, when no preexisting dir)
    * 5:12 PM 12/1/2023: major fixes, tracked down source of issues: you need to 
        build vdev\vdev as intact _flat_ files complete mludle; then COPY IT to the 
        CU\Docs\Modules\verb-dev\verb-dev, and test-manifest the result. From there if 
        it's fully purged all CU and other installs of the tmod, publish-module will only find the flat file complete (even psd1.filelist array content is resolvable if they're in the vdev\vdev\ root, and the CU dupe). 
        d Reset-*(), and added populate-*(), handling the purge out of all res\lic\docs content from vdev\vdev, and then copying back fresh source copes of same from the res\lic\docs storage dirs.
        ing [fingerscrossed] with the new wacky psd1.FileList support (which though it "isn't used" by modules per MS, fails hard on test-modulemanifest passes, if the cited files aren't in same dir as you .psd1/psm1.
    * 4:19 PM 11/29/2023 still debugging through, works all the way to the publish- command, and dies, can't resolve the FileList entries against the temp build dir... those errors ccause pkg repo pub to fail, and the subsequent install-module can't find the missing unpub'd -requiredversion
    * 9:59 AM 11/28/2023 add: test-ModuleManifest error capture and analysis, and abort on errors (stock test just returns the parsed xml content, even if errors thrown)
    * 11:03 AM 10/13/2023:  expanded gci's;  code to  buffer to verb-mod\verb-mod on the source as well as the temp build loc (gets it through prebuild test-modulemanifest; verb-mod\verb-mod needs to be complete self-contained copy, just like final installed); also needed to pre-remove any conflicts on the move & copy's.
    # 2:59 PM 10/12/2023 add:$rgxTargExcl, code to exclude verb-mod\verb-mod from flatten, and code to copy-flatten source verb-mod dir to it's verb-mod\verb-mod (which must be a fully fleshed working copy to pass initial test-modulemanifest())
    add: block to buffer res/lics to verb-mod\verb-mod - initial test-modulemanifest against existing psd1 won't pass if they're not there in source as well as temp build mod loc; 
    cleaned out old block comment'd regions ; updated cached copy of get-foldertmpty, to latest; subst update to accomodate included non-psm1/psd1 
    resource files (in new Resource subdir); *12:29 PM 10/12/2023 add: 
    get-folderempty(), and code to loop out and remove empty folders in the module 
    tree; code to flatten move resources to the verb-MOD\verb-MOD root from 
    Resource & Licenses etc (won't pass test-modulemanifest or build if can't be 
    validated in root). ; add: moved $rgxModExtIncl out to a param, to permit on 
    the fly tweaking/override; moved swath of constants to top/central loc; add: 
    $rgxSrcFilesPostExcl (rgx to exclude exported temp breakpoint files from 
    inclusion in module build); $rgxPsd1FileListDirs = 
    "\\(Docs|Licenses|Resource)\\" ;  # dirs of files to be included in the 
    manifest FileList key     $rgxPsd1FileListExcl = 
    "\\(\.vscode|ScriptAnalyzer-Results-|logs\\)|-LOG-BATCH-EXEC-" ; # file filter 
    to exclude from mani FilList key     $rgxLicFileFilter = 
    '\\(Resource|Licenses)\\' ; # exempt extensionless license files from removal 
    in temp profile copy     # # post filter excludes regex, dir names in fullname 
    path that should never be included in build, logs, and temp versions of 
    .ps[md]1 files.     $rgxSrcFilesPostExcl = 
    "\\(Package|Tests|logs)\\|(\.ps[dm]1_(\d+-\d+[AP]M|TMP)|-LOG-BATCH-EXEC-\d+-\d+[AP]M-log\.txt|\\(fingerprint|Psd1filelist))$" 
    ;      # rgx to exclude exported temp breakpoint files from inclusion in module 
    build     $rgxPsd1BPExcl = "\\(Public|Internal|Private)\\.*-ps1-BP\.xml$" ;     
     $MergeBuildExcl = "\\(Public|Internal|External|Private)\\.*.ps1$" ;  expand 
    $rgxIncludeDirs to cover External & Private variant names as well - this is 
    used solely to exclude signing of component files that will be signed as a 
    monolithic .psm1 ;  add: code to manully calc & update the .psd1 FileList 
    key/value;  
    # 3:03 PM 6/22/2023 #361: splice in better error-handling fail through code from psb-psparamt ($budrv covers for empty referrals)
    * 1:46 PM 3/22/2023 #1212:Publish-Module throws error if repo.SourceLocation isn't testable (when vpn is down), test and throw prescriptive error (otherwise is obtuse); expanded catch's they were coming up blank
    * 11:20 AM 12/12/2022 completely purged rem'd require stmts, confusing, when they echo in build..., ,verb-IO, verb-logging, verb-Mods, verb-Text
    * 3:10 PM 9/7/2022 ren & alias orig name (verb compliance): process-NewModule -> update-NewModule
    * 11:55 AM 6/2/2022 finally got through full build on verb-io; typo: pltCMPV -> pltCMBS; 
    * 3:42 PM 6/1/2022 add: -RequiredVersion picked up from psd1 post step ; defer into confirm-ModuleBuildSync ; echo update-NewModule splt before running; typo in $psd1vers ; cleaned old rems; 
    * 9:00 AM 5/31/2022 recoding for version enforcement (seeing final un-incremented): added -Version; cbh example tweaks ; subbed all Exit->Break; subbed write-warnings to 7pswlw ; twinned $psd1UpdatedVers into the nobuildversion section.
    * 4:34 PM 5/27/2022: update all Set-ContentFixEncoding & Add-ContentFixEncoding -values to pre |out-string to collapse arrays into single writes
    * 2:38 PM 5/24/2022: Time to resave update-NewModuleHybrid.ps1 => C:\sc\verb-dev\Public\update-NewModule.ps1
    * 2:54 PM 5/23/2022 add: verbose to pltUMD splat for update-metadata (psd1 enforce curr modvers); added missing testscript-targeting remove-UnneededFileVariants @pltRGens ;  
        got through full dbg/publish/install pass on vio merged, wo issues. Appears functional. 
    * 4:01 PM 5/20/2022 WIP, left off, got through the psdUpdatedVers reset - works, just before the uninstall-moduleforce(), need to complete debugging on that balance of material. 
    still debugging: add: buffer and post build compare/restore the $psd1UpdatedVers, to the psd1Version (fix odd bug that's causing rebuild to have the pre-update moduleversion); 
        $rgxOldFingerprint (for identifying backup-fileTDO fingerprint files); revert|backup-file -> restore|backup-fileTDO; add restore-fileTDO fingerprint, and psm1/psd1 (using the new func)
    * 4:00 PM 5/13/2022 ren merge-module() refs -> ConvertTo-ModuleDynamicTDO() ; ren unmerge-module() refs -> ConvertTo-ModuleDynamicTDO
    * 4:10 PM 5/12/2022 got through a full non -Dyn pass, to publish and ipmo -for. Need to dbg unmerged-module.psm1 interaction yet, but this *looks* like it could be ready to be the update-NewModule().
    * 8:45 AM 5/10/2022 attempt to merge over dotsource updates and logic, create a single hosting both flows
    * 2:59 PM 5/9/2022 back-reved update-NewModuleHybridDotsourced updates in
    * 8:47 PM 10/16/2021 rem'd out ReqMods code, was breaking exec from home
    * 1:17 PM 10/12/2021 revised post publish code, find-module was returning an array (bombming nupkg gci), so sort on version and take highest single.
    * 3:43 PM 10/7/2021 revised .nupkg caching code to use the returned (find-module).version string to find the repo .nupkg file, for caching (works around behavior where 4-digit semvars, with 4th digit(rev) 0, get only a 3-digit version string in the .nupkg file name)
    * 3:43 PM 9/27/2021 spliced in updated start-log pre-proc code ; fixed $Repo escape in update herestring block
    * 2:14 PM 9/21/2021 functionalized & added to verb-dev ; updated $FinalReport to leverage varis, simpler to port install cmds between mods; added #requires (left in loadmod support against dependancy breaks); cleaned up rems
    * 11:25 AM 9/21/2021 added code to remove obsolete gens of .nupkgs & build log files (calls to new verb-io:remove-UnneededFileVariants());
    * 12:40 PM 6/2/2021 example used verb-trans, swapped in verb-logging
    * 12:07 PM 4/21/2021 expanded ss aliases
    * 10:17 AM 3/16/2021 added -ea 0 to the install BP output, suppress remove-module error when not already loaded
    * 10:35 AM 6/29/2020 added new -NoBuildInfo param, to skip reliance on BuildHelpers module (get/Set-BuildEnvironment hang when run at join-object module)
    * 1:19 PM 4/10/2020 swapped in 7psmodhybrid mods
    * 3:38 PM 4/7/2020 added Remove-Module to the trailing demo install command - pulls down the upgraded mod from the session (otherwise, old & new remain in session); added AllUser demo trailing code too, less likely to misupgrade jumpbox
    * 9:21 AM 4/1/2020 added -RunTest to trigger pester test exec, also wrapped test-modulemanifest in try/catch to capture fails (a broken psd1 isn't going to work on install), fail immed exits processing, also added detection of invalid test script guids and force match to psd1
    * 8:44 AM 3/17/2020 added new rebuild-module.ps1 to excludes on install/publish
    * 10:11 AM 3/16/2020 swapped verb-IO to mod code, added AllowClobber to the demo reinstall end text
    * 3:46 PM 3/15/2020 reworked module copy process - went back to original 'copy all w isolated exclusions' and dropped the attempt at -include control of final extensions. Did a post-copy purge of undesired file types instead.
    * 9:59 AM 3/9/2020 fixed bug in module copy process, needed to sort dirs first, to ensure they pre-exist before files are attempted (supresses error)
    * 4:32 PM 3/7/2020 revised the module copy process to only target common module components by type (instead of all but .git & .vscode)
    * 7:05 PM 3/3/2020 added code to detect and echo psd1 guid match, updated export modules code, added buffering of proc log
    * 8:39 AM 3/2/2020 still trying to get things to smoothly fail through missing installed mod, to dev .psm1, and finally into uwes copy of the mod, to ensure the commands are mounted, under any circ, working, still not happy when updating a module that the script itself is dependant on. Updated Final Report to sort other machine update sample
    * 7:31 AM 3/2/2020 spliced over Set-ModuleFunction FunctionsToExport maint code from converTo-Module.ps1
    * 4:03 PM 3/1/2020 excluded module load block from verbose output
    * 4:32 PM 2/27/2020: ammended test import-module force (hard reload curr version) & verbose output ; added trailing FinalReport with post install guidence & testing
    * 7:21 PM 2/26/2020 sorted a typo/dupe in the nupkg copy echo ; updated psm1 version code, fixd bug, replic'd it to the convert script. shifted FunctionsToExport into buildhelpers mod (added #requires), added -DisableNameChecking to mod imports
    * 6:30 PM 2/25/2020 added code to update the guid from the psd1 into the pester test scrpit
    * 2:00 PM 2/24/2020 added material re: uninstall in description/example
    * 4:00 PM 2/18/2020 added new descriptive -Tag $ModuleName  spec to the start-Log call
    * 7:36 PM 1/15/2020 added code to create 'Package' subdir, and copy in post-publish .nupkg file (easier to buffer into other repos, than publish-module) had to splice in broken installed module backfill for verb-dev
    * 7:58 PM 1/14/2020 converted dev-verb call into #requires Module call ; #459 flipped to using .net to pull the mydocs specfolder out of the OS (in case of fut redir) ; ren parm (to match convertto-module.ps1): DemoRepo -> Repository, added manual removal of old version from all $env:psmodulepath entries, shifted $psd1vers code to always, and used it with the install-module -requiredversion, to work around the cmds lack of auto-priority, if it finds multiples, it doesn't install latest, just throws up. (could have used -minrev too and it *should* have done this, or any later). Ran full publish & validate on verb-dev (work)
    * 10:49 AM 1/13/2020 updated echos for Republish/non-republish output (enum specific steps each will cover), was throwing deep acc error on copy to local prof for md file, added retry, which 2x's and fails past it. Doesn't seem mpactful, the md wasn't even one id' pop'd, just a defaupt template file
    * 7:35 AM 12/30/2019 got through a full pass to import-module on verb-dev. *appears* functional
    * 12:03 PM 12/29/2019 added else wh on pswls entries
    * 1:53 PM 12/28/2019 shifted to verb-* loads for all local functions, added pre-publish check for existing conflicting verison. Still throwing exec code in sig block
    * 12:28 PM 12/27/2019 subbed write-warning for write-error throughout
    * 1:38 PM 12/26/2019 #251 filter public|internal|classes include subdirs - don't sign them (if including/dyn-including causes 'Executable script code found in signature block.' errors ; 12/26/2019 flipped #399 from Error to Info in write-log, ran a full clean pass on verb-dev. ; ADD #342 -AllowClobber, to permit install command overlap (otherwise it aborts the install-module attempt), updated SID test to leverage regx
    * 9:29 AM 12/20/2019 fixed quote/dbl-quote issue in the profile copy code (was suppressing vari expansion)
    * 7:05 PM 12/19/2019 subbed in write-log support ; init, ran through Republish pass on verb-AAD
    .DESCRIPTION
    update-NewModule - dyanmic include/dot-stourced post-module conversion or component update: sign - all files (this vers), publish to repo, and install back script
    Note: -Merge drivese logic to build Monolithic .psm1 (-Merge), vs Dynamic-include .psm1 (-not -Merge)

    v1.5.33+, it now properly supports psd1 manifest FileList and 
    (Docs|Licenses|Resource) dir build-in components through that setting 
    (place  relevent 3rd party non-executing files/data sources, you don't want to put into 
    a data psd1 hash, into these dirs, and they'll be autoadded as psd1.FileList 
    array members, and will be autocopied to the output modname\modname\dir on build).
    
    I've hit an insurmoutable bug in psv2, when using psGet to install psv3+ modules into older legacy machines. Verb-IO *won't* properly parse and load my ConvertFrom-SourceTable function at all. So we need the ability to conditionally load module functions, skipping psv2-incompatibles when running that rev
    
    Preqeq Installs:
    Install-Module BuildHelpers -scope currentuser # buildhelpers metadata handling https://github.com/RamblingCookieMonster/BuildHelpers

    See example with code to remove all but latest rev of a given module
    
    This is intended to work against the following module dev/git folder struction: (git repo for the c:\sc\ModName root)
        C:\sc\MODNAME\
        |-- CHANGELOG.md
        |-- Classes
        |-- Docs
        |   |-- Cab
        |   |-- Markdown
        |   |-- Quick-Start-Installation-and-Example.md
        |   `-- en-US
        |-- Internal
        |-- Libs
        |-- Licenses
        |   |-- LICENSE.txt [License terms]
        |-- Package
        |   |-- module.1.2.3.nupkg [buffered back copies of published .nupkg files for recording at git]
        |-- Psd1filelist
        |-- Public
        |   |-- function.ps1 [one for each leaf module function to be exported, stored as separate .ps1 files, which are merged into a monolithic .psm1 using the -Merge param]
        |-- README.md
        |-- Resource
        |   |-- resource.ext [non-executable resource/data files that you want published with the module, but you don't want to bother with storing in a hash in a psd1 datafile; these are auto-added to the psd1.FileList array, and are moved, flattened dir, into the modulename\modulename output build dir]
        |-- Tests
        |   |-- PPoShScriptingStyle.psd1 [Pester testing preferences]
        |   |-- ToddomationScriptingStyle-medium.psd1 [Pester testing preferences]
        |   `-- MODNAME.tests.ps1 [pester tests]
        |-- MODNAME
        |   |-- CHANGELOG.md
        |   |-- LICENSE.txt
        |   |-- Quick-Start-Installation-and-Example.md
        |   |-- README.md
        |   |-- logs
        |   |   |-- MODNAME-verb-Desktop-LOG-BATCH-EXEC-20220908-1541PM-log.txt [temp logs storage, ignored for module builds]
        |   |-- MODNAME.psd1
        |   `-- MODNAME.psm1
        |-- convertto-Module-LOG-BATCH-EXEC-20200114-1155AM-log.txt
        |-- fingerprint [semversion comparision tracking file]
        |-- rebuild-module.ps1 [module rebuild script]
        `-- requirements.psd1 [psdep module specification file]

    Where builds fail, you may want to leverage my uwps\.\reset-ModuleBuildFail.ps1 -Name verb-io script:

    ... to reset a given failed dir & profile back to rebuildable state (locates and reinstalls the most recent publsiehd module vers from the pslocalRepo, clears modname\modname dir, reports on last vpublsiehd vers#, and echo's the current psm1 & psd1 version specs (for hand editing to reroll build).
    (leaving it out of verb-dev, as I want it to recover and function even when verb-dev is borked).

    .PARAMETER  ModuleName
    ModuleName[-ModuleName verb-AAD]
    .PARAMETER  ModDirPath
    ModDirPath[-ModDirPath C:\sc\verb-ADMS]
    .PARAMETER  Repository
    Target local Repo[-Repository someRepoName]
    .PARAMETER Merge
    Flag that indicates Module should be Merged into a monoolithic .psm1 (otherwise, a Dynamic-Include version is built)[-Merge]
    .PARAMETER RunTest
    Flag that indicates Pester test script should be run, at end of processing [-RunTest]
    .PARAMETER NoBuildInfo
    Skip BuildInfo use (workaround for hangs in that module)[-NoBuildInfo]
    .PARAMETER RequiredVersion
    Optional Explicit RequiredVersion specification (as contrasts with using current Manifest .psd1 ModuleVersion value)
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Republish
    Flag that indicates Module should be republished into local Repo (skips ConvertTo-ModuleDynamicTDO & set-AuthenticodeSignatureTDO steps) [-Republish]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    PS> processbulk-NewModule.ps1 -mod verb-text,verb-io -verbose
    Example using the separate processbulk-NewModule.ps1 pre-procesesor to feed an array of mods through bulk processing, uses BuildEnvironment Step-ModuleVersion to increment the psd1 version, and specs -merge & -RunTest processing
    .EXAMPLE
    PS> processbulk-NewModule.ps1 -mod -Dynamic verb-io -verbose
    Example using the separate processbulk-NewModule.ps1 pre-procesesor to drive a Dyanmic include .psm1 build to feed one mod through bulk processing, uses BuildEnvironment Step-ModuleVersion to increment the psd1 version, and specs -merge & -RunTest processing
    .EXAMPLE
    PS> update-NewModule -ModuleName "verb-AAD" -ModDirPath "C:\sc\verb-AAD" -Repository $localPSRepo  -Merge -showdebug -whatif ;
    Full Merge Build/Rebuild from components & Publish/Install/Test specified module, with debug messages, and whatif pass.
    .EXAMPLE
    PS> update-NewModule -ModuleName "verb-AAD" -ModDirPath "C:\sc\verb-AAD" -Repository $localPSRepo  -showdebug -whatif ;
    Non-Merge pass: Re-sign specified module & Publish/Install/Test specified module, with debug messages, and whatif pass.
    .EXAMPLE
    PS> write-verbose "pre-remove installed module" ; 
    PS> write-verbose "re-increment the psd1 file ModuleVersion (unique new val req'd to publish)" ; 
    PS> update-NewModule -ModuleName "verb-AAD" -ModDirPath "C:\sc\verb-AAD" -Repository $localPSRepo -Merge -Republish -showdebug -whatif ;
    Merge & Republish pass: Only Publish/Install/Test specified module, with debug messages, and whatif pass.
    .EXAMPLE
    PS> write-verbose "Module, uninstall all but latest"
    PS> $modules = Get-Module -ListAvailable ModuleName* | Select-Object -ExpandProperty Name -Unique ;
    PS> foreach ($module in $modules) {$Latest = Get-InstalledModule $module; Get-InstalledModule $module -AllVersions | ? {$_.Version -ne $Latest.Version} | Uninstall-Module ;} ;
    Util code to uninstall all but latest version of a given module.
    .EXAMPLE
    PS> $rgxModExtIncl='\.(cab|cat|cmd|config|cscfg|csdef|css|dll|dylib|gif|html|ico|jpg|js|json|map|Materialize|MaterialUI|md|pdb|php|png|ps1|ps1xml|psd1|psm1|rcs|reg|snippet|so|txt|vscode|wixproj|wxi|xaml|xml|yml|zip)$' ;
    PS> $rgxPsd1FileListDirs = "\\(Docs|Licenses|Resource)\\" ;
    PS> foreach($pth in (resolve-path c:\sc\verb-* )){
    PS>   write-host -fore yellow "`n===$($pth.path)" ;
    PS>   $tpth = (join-path $pth.path ($pth.path.tostring().replace('C:\sc\',''))) ;
    PS>   write-host "`$tpth:$($tpth)" ;
    PS>   if($mfiles = gci -path $tpth -recur | ?{$_.extension -match $rgxModExtIncl -AND $_.fullname -notmatch $rgxPsd1FileListDirs}) {
    PS>       write-warning "Found following potential errant includes in dir:`n$(($mfiles.fullname|out-string).trim())" ;
    PS>   } ;
    PS> } ; 
    Code for weeding a stack of repo's for inappropriate files in the heirarchy that could wind up unexpectedly published, with newly-functional psd1.FileList support (publishable extensions, *not* in Resource\Docs\License subdirs that explicitly source FileList includes). Review the output, and remove any files you don't want published.
    PS> .\reset-ModuleBuildFail.ps1 -Name verb-Azure -verbose ;
    Separate uwps script that resets the local Repo c:\sc\[modulename]\[modulename\ dir, and reinstalls the most recent published vers of a given module that failed a build attempt (via processbulk-newmodule.ps1 & update-NewModule()). Worth running on a build fail - it looks like some psd1.FileList publish-module errors are a product of deadwood already pre-populated in the sc\modname\modname dir
    .LINK
    https://github.com/tostka/verb-dev
    #>
    #Requires -Modules BuildHelpers
    [CmdletBinding()]
    [Alias('process-NewModule')]
    PARAM(
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,HelpMessage="ModuleName[-ModuleName verb-AAD]")]
            [ValidateNotNullOrEmpty()]
            [string]$ModuleName,
        [Parameter(Mandatory=$True,HelpMessage="ModDirPath[-ModDirPath C:\sc\verb-ADMS]")]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [system.io.fileinfo]$ModDirPath,
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Target local Repo[-Repository someRepoName]")]
            [ValidateNotNullOrEmpty()]
            [string]$Repository,
        [Parameter(HelpMessage="Flag that indicates Module should be Merged into a monoolithic .psm1 [-Merge]")]
            [switch] $Merge,
        [Parameter(HelpMessage="Flag that indicates Module should be republished into local Repo (skips ConvertTo-ModuleDynamicTDO & set-AuthenticodeSignatureTDO steps) [-Republish]")]
            [switch] $Republish,
        [Parameter(HelpMessage="Flag that indicates Pester test script should be run, at end of processing [-RunTest]")]
            [switch] $RunTest,
        [Parameter(HelpMessage="Skip BuildInfo use (workaround for hangs in that module)[-NoBuildInfo]")]
            [switch] $NoBuildInfo,
        [Parameter(HelpMessage="Optional Explicit 3-digit RequiredVersion specification (as contrasts with using current Manifest .psd1 ModuleVersion value)[-Version 2.0.3]")]
            [version]$RequiredVersion,
        [Parameter(HelpMessage="regex reflecting an array of file extension strings to identify 'external' dependancy files in the module directory structure that are to be included in the distributed module(provided to provide run-time override)")]
            [string[]]$rgxModExtIncl='\.(cab|cat|cmd|config|cscfg|csdef|css|dll|dylib|gif|html|ico|jpg|js|json|map|Materialize|MaterialUI|md|pdb|php|png|ps1|ps1xml|psd1|psm1|rcs|reg|snippet|so|txt|vscode|wixproj|wxi|xaml|xml|yml|zip)$',
            # added trailing '$' to test to end of ext, as wo it was matching on extensions that *start* with the above, even if named .xml_TMP.
        [Parameter(HelpMessage="Debugging Flag [-showDebug]")]
            [switch] $showDebug,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
            [switch] $whatIf
    ) ;
    #region CONSTANTS-AND-ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
    # Debugger:proxy automatic variables that aren't directly accessible when debugging (must be assigned and read back from another vari) ; 
    $rPSCmdlet = $PSCmdlet ; 
    $rPSScriptRoot = $PSScriptRoot ; 
    $rPSCommandPath = $PSCommandPath ; 
    $rMyInvocation = $MyInvocation ; 
    $rPSBoundParameters = $PSBoundParameters ; 
    [array]$score = @() ; 
    if($rPSCmdlet.MyInvocation.InvocationName -match '\.ps1$'){$score+= 'ExternalScript' } else {$score+= 'Function' }
    if($rPSCmdlet.CommandRuntime.tostring() -match '\.ps1$'){$score+= 'ExternalScript' } else {$score+= 'Function' }
    $score+= $rMyInvocation.MyCommand.commandtype.tostring() ; 
    $grpSrc = $score | group-object -NoElement | sort count ;
    if( ($grpSrc |  measure | select -expand count) -gt 1){
        write-warning  "$score mixed results:$(($grpSrc| ft -a count,name | out-string).trim())" ;
        if($grpSrc[-1].count -eq $grpSrc[-2].count){
            write-warning "Deadlocked non-majority results!" ;
        } else {
            $runSource = $grpSrc | select -last 1 | select -expand name ;
        } ;
    } else {
        write-verbose "consistent results" ;
        $runSource = $grpSrc | select -last 1 | select -expand name ;
    };
    write-host "Calculated `$runSource:$($runSource)" ;
    'score','grpSrc' | get-variable | remove-variable ; # cleanup temp varis

    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
    ${CmdletName} = $rPSCmdlet.MyInvocation.MyCommand.Name ;
    $PSParameters = New-Object -TypeName PSObject -Property $rPSBoundParameters ;
    write-verbose "`$rPSBoundParameters:`n$(($rPSBoundParameters|out-string).trim())" ;
    $Verbose = ($VerbosePreference -eq 'Continue') ; 
    # pre psv2, no $rPSBoundParameters autovari to check, so back them out:
    write-verbose 'Collect all non-default Params (works back to psv2 w CmdletBinding)'
    $ParamsNonDefault = (Get-Command $rPSCmdlet.MyInvocation.InvocationName).parameters | Select-Object -expand keys | Where-Object{$_ -notmatch '(Verbose|Debug|ErrorAction|WarningAction|ErrorVariable|WarningVariable|OutVariable|OutBuffer)'} ;
    #region ENVIRO_DISCOVER ; #*------v ENVIRO_DISCOVER v------
    <#
    # Debugger:proxy automatic variables that aren't directly accessible when debugging ; 
    $rPSScriptRoot = $PSScriptRoot ; 
    $rPSCommandPath = $PSCommandPath ; 
    $rMyInvocation = $MyInvocation ; 
    $rPSBoundParameters = $PSBoundParameters ; 
    #>
    $ScriptDir = $scriptName = '' ;     
    if($ScriptDir -eq '' -AND ( (get-variable -name rPSScriptRoot -ea 0) -AND (get-variable -name rPSScriptRoot).value.length)){
        $ScriptDir = $rPSScriptRoot
    } ; # populated rPSScriptRoot
    if( (get-variable -name rPSCommandPath -ea 0) -AND (get-variable -name rPSCommandPath).value.length){
        $ScriptName = $rPSCommandPath
    } ; # populated rPSCommandPath
    if($ScriptDir -eq '' -AND $runSource -eq 'ExternalScript'){$ScriptDir = (Split-Path -Path $rMyInvocation.MyCommand.Source -Parent)} # Running from File
    # when $runSource:'Function', $rMyInvocation.MyCommand.Source is empty,but on functions also tends to pre-hit from the rPSCommandPath entFile.FullPath ;
    if( $scriptname -match '\.psm1$' -AND $runSource -eq 'Function'){
        write-host "MODULE-HOMED FUNCTION:Use `$CmdletName to reference the running function name for transcripts etc (under a .psm1 `$ScriptName will reflect the .psm1 file  fullname)"
        if(-not $CmdletName){write-warning "MODULE-HOMED FUNCTION with BLANK `$CmdletNam:$($CmdletNam)" } ;
    } # Running from .psm1 module
    if($ScriptDir -eq '' -AND (Test-Path variable:psEditor)) {
        write-verbose "Running from VSCode|VS" ; 
        $ScriptDir = (Split-Path -Path $psEditor.GetEditorContext().CurrentFile.Path -Parent) ; 
            if($ScriptName -eq ''){$ScriptName = $psEditor.GetEditorContext().CurrentFile.Path }; 
    } ;
    if ($ScriptDir -eq '' -AND $host.version.major -lt 3 -AND $rMyInvocation.MyCommand.Path.length -gt 0){
        $ScriptDir = $rMyInvocation.MyCommand.Path ; 
        write-verbose "(backrev emulating `$rPSScriptRoot, `$rPSCommandPath)"
        $ScriptName = split-path $rMyInvocation.MyCommand.Path -leaf ;
        $rPSScriptRoot = Split-Path $ScriptName -Parent ;
        $rPSCommandPath = $ScriptName ;
    } ;
    if ($ScriptDir -eq '' -AND $rMyInvocation.MyCommand.Path.length){
        if($ScriptName -eq ''){$ScriptName = $rMyInvocation.MyCommand.Path} ;
        $ScriptDir = $rPSScriptRoot = Split-Path $rMyInvocation.MyCommand.Path -Parent ;
    }
    if ($ScriptDir -eq ''){throw "UNABLE TO POPULATE SCRIPT PATH, EVEN `$rMyInvocation IS BLANK!" } ;
    if($ScriptName){
        if(-not $ScriptDir ){$ScriptDir = Split-Path -Parent $ScriptName} ; 
        $ScriptBaseName = split-path -leaf $ScriptName ;
        $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($ScriptName) ;
    } ; 
    # last ditch patch the values in if you've got a $ScriptName
    if($rPSScriptRoot.Length -ne 0){}else{ 
        if($ScriptName){$rPSScriptRoot = Split-Path $ScriptName -Parent }
        else{ throw "Unpopulated, `$rPSScriptRoot, and no populated `$ScriptName from which to emulate the value!" } ; 
    } ; 
    if($rPSCommandPath.Length -ne 0){}else{ 
        if($ScriptName){$rPSCommandPath = $ScriptName }
        else{ throw "Unpopulated, `$rPSCommandPath, and no populated `$ScriptName from which to emulate the value!" } ; 
    } ; 
    if(-not ($ScriptDir -AND $ScriptBaseName -AND $ScriptNameNoExt  -AND $rPSScriptRoot  -AND $rPSCommandPath )){ 
        throw "Invalid Invocation. Blank `$ScriptDir/`$ScriptBaseName/`ScriptNameNoExt" ; 
        BREAK ; 
    } ; 
    # echo results dyn aligned:
    $tv = 'runSource','CmdletName','ScriptName','ScriptBaseName','ScriptNameNoExt','ScriptDir','PSScriptRoot','PSCommandPath','rPSScriptRoot','rPSCommandPath' ; 
    $tvmx = ($tv| Measure-Object -Maximum -Property Length).Maximum * -1 ; 
    $tv | get-variable | %{  write-host -fore yellow ("`${0,$tvmx} : {1}" -f $_.name,$_.value) } ; 
    'tv','tvmx'|get-variable | remove-variable ; # cleanup temp varis
    
    #endregion ENVIRO_DISCOVER ; #*------^ END ENVIRO_DISCOVER ^------

    #region COMMON_CONSTANTS ; #*------v COMMON_CONSTANTS v------

    if(-not $DoRetries){$DoRetries = 4 } ;    # # times to repeat retry attempts
    if(-not $RetrySleep){$RetrySleep = 10 } ; # wait time between retries
    if(-not $RetrySleep){$DawdleWait = 30 } ; # wait time (secs) between dawdle checks
    if(-not $DirSyncInterval){$DirSyncInterval = 30 } ; # AADConnect dirsync interval
    if(-not $ThrottleMs){$ThrottleMs = 50 ;}
    if(-not $rgxDriveBanChars){$rgxDriveBanChars = '[;~/\\\.:]' ; } ; # ;~/\.:,
    if(-not $rgxCertThumbprint){$rgxCertThumbprint = '[0-9a-fA-F]{40}' } ; # if it's a 40char hex string -> cert thumbprint  
    if(-not $rgxSmtpAddr){$rgxSmtpAddr = "^([0-9a-zA-Z]+[-._+&'])*[0-9a-zA-Z]+@([-0-9a-zA-Z]+[.])+[a-zA-Z]{2,63}$" ; } ; # email addr/UPN
    if(-not $rgxDomainLogon){$rgxDomainLogon = '^[a-zA-Z][a-zA-Z0-9\-\.]{0,61}[a-zA-Z]\\\w[\w\.\- ]+$' } ; # DOMAIN\samaccountname 
    if(-not $exoMbxGraceDays){$exoMbxGraceDays = 30} ; 

    #$ComputerName = $env:COMPUTERNAME ;
    #$NoProf = [bool]([Environment]::GetCommandLineArgs() -like '-noprofile'); # if($NoProf){# do this};
    # XXXMeta derived constants:
    # - AADU Licensing group checks
    # calc the rgxLicGrpName fr the existing $xxxmeta.rgxLicGrpDN: (get-variable tormeta).value.rgxLicGrpDN.split(',')[0].replace('^','').replace('CN=','')
    #$rgxLicGrpName = (get-variable -name "$($tenorg)meta").value.rgxLicGrpDN.split(',')[0].replace('^','').replace('CN=','')
    # use the dn vers LicGrouppDN = $null ; # | ?{$_ -match $tormeta.rgxLicGrpDN}
    #$rgxLicGrpDN = (get-variable -name "$($tenorg)meta").value.rgxLicGrpDN

    # email trigger vari, it will be semi-delimd list of mail-triggering events
    $script:PassStatus = $null ;
    [array]$SmtpAttachment = $null ;

    #endregion COMMON_CONSTANTS ; #*------^ END COMMON_CONSTANTS ^-

    #region LOCAL_CONSTANTS ; #*------v LOCAL_CONSTANTS v------

    $DomainWork = $tormeta.legacydomain ;
    #$ProgInterval= 500 ; # write-progress wait interval in ms

    $backInclDir = "c:\usr\work\exch\scripts\" ;
    $Retries = 4 ;
    $RetrySleep = 5 ;

    # constants relocated centrally
    # exts for files that are bundled into final build pkg (and get copied to profile)
    $ModExtIncl='*.cab','*.cat','*.cmd','*.config','*.cscfg','*.csdef','*.css','*.dll','*.dylib','*.gif','*.html','*.ico','*.jpg','*.js','*.json','*.map','*.Materialize','*.MaterialUI','*.md','*.pdb','*.php','*.png','*.ps1','*.ps1xml','*.psd1','*.psm1','*.rcs','*.reg','*.snippet','*.so','*.txt','*.vscode','*.wixproj','*.wxi','*.xaml','*.xml','*.yml','*.zip' ;
    # rgx equiv of above
    if(-not $rgxModExtIncl){
        # should come down from parameter
        $rgxModExtIncl='\.(cab|cat|cmd|config|cscfg|csdef|css|dll|dylib|gif|html|ico|jpg|js|json|map|Materialize|MaterialUI|md|pdb|php|png|ps1|ps1xml|psd1|psm1|rcs|reg|snippet|so|txt|vscode|wixproj|wxi|xaml|xml|yml|zip)' ;
    } ; 
    # trim down above into the manifest.psd1 FileList - non native module exec code files from the rgxModExtIncl
    $rgxPsd1FileList = $rgxModExtIncl.replace('ps1|','').replace('psm1|','').replace('psd1|','') ; 
    # files that are explicitly excluded from build/pkg/filelist by name
    # gci -exclude spec:
    # add exclude of pester .md module creation info to both
    #$exclude = @('main.js','rebuild-module.ps1','New-Module-Create.md') ; 
    # add exclude on the .\Help\ .help.txt exported ref CBH copy files
    $gciExcludes = @('main.js','rebuild-module.ps1','New-Module-Create.md') ; 
    # gci post-filtered excludes from build/pkg
    #$excludeMatch = @('.git','.vscode','New-Module-Create.md') ;
    # * 3:07 PM 1/20/2025 added buildblind and the x.help.txts as well
    $excludeMatch = @('.git','.vscode','New-Module-Create.md') ;
    [regex] $excludeMatchRegEx = '(?i)' + (($excludeMatch |ForEach-Object {[regex]::escape($_)}) -join "|") + '' ;
    $rgxPsd1FileListDirs = "\\(Docs|Licenses|Resource)\\" ;  # dirs of files to be included in the manifest FileList key
    #$rgxPsd1FileListExcl = "\\(\.vscode|ScriptAnalyzer-Results-|logs\\)|-LOG-BATCH-EXEC-" ; # file filter to exclude from mani FilList key
    # \\xxx|yyy\\ block is dir excludes; the (-LOG-BATCH-EXEC-|...) block is filename match excludes. 
    # 4:25 PM 1/21/2025 updated to cover psd1 FileList excludes of \buildBlind\
    $rgxPsd1FileListExcl = "\\(\.vscode|logs|buildBlind\\)|(-LOG-BATCH-EXEC-|ScriptAnalyzer-Results-)" ; # file filter to exclude from mani FilList key
    $rgxLicFileFilter = '\\(Resource|Licenses)\\' ; # exempt extensionless license files from removal in temp profile copy
    $rgxRootFilesBuild = "(CHANGELOG|README)\.md$" ;
    # # post filter excludes regex, dir names in fullname path that should never be included in build, logs, and temp versions of .ps[md]1 files.
    $rgxSrcFilesPostExcl = "\\(Package|Tests|logs)\\|(\.ps[dm]1_(\d+-\d+[AP]M|TMP)|-LOG-BATCH-EXEC-\d+-\d+[AP]M-log\.txt|\\(fingerprint|Psd1filelist))$" ; 
    # rgx to exclude exported temp breakpoint files from inclusion in module build
    $rgxPsd1BPExcl = "\\(Public|Internal|Private)\\.*-ps1-BP\.xml$" ; 
    # no, it's still building with this, so move it up to the $excludeMatch array; prior: rgx to exclude exporte .\Help\*.help.txt files (created for offline ref, not as a module compoonent)
    #$rgxHelpExportedExcl = "\\Help\\.*\.help\.txt$" ;
    $MergeBuildExcl = "\\(Public|Internal|External|Private)\\.*.ps1$" ; 
    # rgx to exclude target verb-mod\verb-mod from efforts to flatten (it's the dest, shouldn't be a source)
    $rgxTargExcl = [regex]::escape("\$($ModuleName)\$($ModuleName)") ; 
    $rgxGuidModFiles = "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\.ps(d|m)1" ; # identifies temp psd|m1 files named for guids
    $rgxInclOutLicFileName = '^LICENSE' ; # id's local extensionless vdev\vdev lic files that *should* remain
    $iSkipAutomaticTagsThreshold = 2000 ; # number of chars of comma-quote-delim'd public function names, as a string array, to establish a threshold to use SkipAutomaticTags with publish-module (NugGet bug workaround)
    # issue is: powershellget automatic tags all exported function and hangs when u go over 4000 characters can be avoided by SkipAutomaticTags on publish-module
    $rgxModModPurges = "(main\.js|rebuild-module\.ps1$|New-Module-Create\.md$|buildBlind|\.help\.txt$|-ps1-BP\.xml$)" ; 

    #endregion LOCAL_CONSTANTS ; #*------^ END LOCAL_CONSTANTS ^------        
    
    #region ENCODED_CONTANTS ; #*------v ENCODED_CONTANTS v------
    #endregion ENCODED_CONTANTS ; #*------^ END ENCODED_CONTANTS ^------
    
    

    #endregion CONSTANTS-AND-ENVIRO #*======^ END CONSTANTS-AND-ENVIRO ^======

    
    #*======v FUNCTIONS v======

    # suppress VerbosePreference:Continue, if set, during mod loads (VERY NOISEY)
    if($VerbosePreference -eq "Continue"){
        $VerbosePrefPrior = $VerbosePreference ;
        $VerbosePreference = "SilentlyContinue" ;
        $verbose = ($VerbosePreference -eq "Continue") ;
    } ;

    $PassStatus = $null ;
    $PassStatus = @() ;


    # strings are: "[tModName];[tModFile];tModCmdlet"
    $tMods = @() ;
    #$tMods+="verb-Auth;C:\sc\verb-Auth\verb-Auth\verb-Auth.psm1;get-password" ;
    $tMods+="verb-logging;C:\sc\verb-logging\verb-logging\verb-logging.psm1;write-log";
    $tMods+="verb-IO;C:\sc\verb-IO\verb-IO\verb-IO.psm1;Add-PSTitleBar" ;
    $tMods+="verb-Mods;C:\sc\verb-Mods\verb-Mods\verb-Mods.psm1;check-ReqMods" ;
    $tMods+="verb-Text;C:\sc\verb-Text\verb-Text\verb-Text.psm1;Remove-StringDiacritic" ;
    #$tMods+="verb-Desktop;C:\sc\verb-Desktop\verb-Desktop\verb-Desktop.psm1;Speak-words" ;
    #$tMods+="verb-dev;C:\sc\verb-dev\verb-dev\verb-dev.psm1;Get-CommentBlocks" ;
    #$tMods+="verb-Text;C:\sc\verb-Text\verb-Text\verb-Text.psm1;Remove-StringDiacritic" ;
    #$tMods+="verb-Automation.ps1;C:\sc\verb-Automation.ps1\verb-Automation.ps1\verb-Automation.ps1.psm1;Retry-Command" ;
    #$tMods+="verb-AAD;C:\sc\verb-AAD\verb-AAD\verb-AAD.psm1;Build-AADSignErrorsHash";
    #$tMods+="verb-ADMS;C:\sc\verb-ADMS\verb-ADMS\verb-ADMS.psm1;load-ADMS";
    #$tMods+="verb-Ex2010;C:\sc\verb-Ex2010\verb-Ex2010\verb-Ex2010.psm1;Connect-Ex2010";
    #$tMods+="verb-EXO;C:\sc\verb-EXO\verb-EXO\verb-EXO.psm1;Connect-Exo";
    #$tMods+="verb-L13;C:\sc\verb-L13\verb-L13\verb-L13.psm1;Connect-L13";
    #$tMods+="verb-Network;C:\sc\verb-Network\verb-Network\verb-Network.psm1;Send-EmailNotif";
    #$tMods+="verb-Teams;C:\sc\verb-Teams\verb-Teams\verb-Teams.psm1;Connect-Teams";
    #$tMods+="verb-SOL;C:\sc\verb-SOL\verb-SOL\verb-SOL.psm1;Connect-SOL" ;
    #$tMods+="verb-Azure;C:\sc\verb-Azure\verb-Azure\verb-Azure.psm1;get-AADBearToken" ;
    # 9:33 AM 12/5/2023 this is still doing archaic loadmod...
    foreach($tMod in $tMods){
        $tModName = $tMod.split(';')[0] ;
        $tModFile = $tMod.split(';')[1] ;
        $tModCmdlet = $tMod.split(';')[2] ;
        $smsg = "( processing `$tModName:$($tModName)`t`$tModFile:$($tModFile)`t`$tModCmdlet:$($tModCmdlet) )" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        if($tModName -eq 'verb-Network' -OR $tModName -eq 'verb-Azure'){
            write-host "GOTCHA!" ;
        } ;
        $lVers = get-module -name $tModName -ListAvailable -ea 0 ;
        if($lVers){
            $lVers=($lVers | sort version)[-1];
            try {
                # add errvari:
                import-module -name $tModName -RequiredVersion $lVers.Version.tostring() -force -DisableNameChecking -errorVariable 'ipmo_Err' ;
                    if($ipmo_Err){
                        $smsg = "`nFOUND `$ipmo_Err: import-module HAD ERRORS!" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        foreach($errExcpt in $ipmo_Err.Exception){
                            switch -regex ($errExcpt){
                                default {
                                    $smsg = "`nInstall-Module ISMO .PSM1  UNDEFINED ERROR!" ;
                                    $smsg += "`n$($errExcpt)" ;
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                }
                            } ;
                        } ;
                        #BREAK ; # should we break, or let it backload in the catch?
                        throw $smsg ; # force into catch instead
                    } else {
                        $smsg = "(no `$ipmo_Err: test-ModuleManifest had no errors)" ;
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                    } ;
            }   catch {
                write-warning "*BROKEN INSTALLED MODULE*:$($tModName)`nBACK-LOADING DCOPY@ $($tModDFile)" ;
                import-module -name $tModDFile -force -DisableNameChecking
            } ;
        } elseif (test-path $tModFile) {
            write-warning "*NO* INSTALLED MODULE*:$($tModName)`nBACK-LOADING DCOPY@ $($tModDFile)" ;
            TRY {
                # add errovari tests
                import-module -name $tModDFile -force -DisableNameChecking -errorVariable 'ipmo_Err' ;
                if($ipmo_Err){
                    $smsg = "`nFOUND `$ipmo_Err: import-module HAD ERRORS!" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    foreach($errExcpt in $ipmo_Err.Exception){
                        switch -regex ($errExcpt){
                            default {
                                $smsg = "`nInstall-Module ISMO .PSM1  UNDEFINED ERROR!" ;
                                $smsg += "`n$($errExcpt)" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            }
                        } ;
                    } ;
                    #BREAK ; # should we break, or let it backload in the catch?
                    throw $smsg ; # force into catch instead
                } else {
                    $smsg = "(no `$ipmo_Err: test-ModuleManifest had no errors)" ;
                    if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                } ;
            }CATCH {
                write-error "*FAILED* TO LOAD MODULE*:$($tModName) VIA $(tModFile) !" ;
                $tModFile = "$($tModName).ps1" ;
                $sLoad = (join-path -path $LocalInclDir -childpath $tModFile) ;
                if (Test-Path $sLoad) {
                    Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;
                    . $sLoad ;
                    if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };
                } else {
                    $sLoad = (join-path -path $backInclDir -childpath $tModFile) ;
                    if (Test-Path $sLoad) {
                        Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;
                        . $sLoad ;
                        if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };
                    } else {
                        Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ;
                        Break;
                    } ;
                } ;
            } ;
        } ;
        # validate loaded, test for cmdlet avail
        if(!(test-path function:$tModCmdlet)){
            write-warning -verbose:$true  "UNABLE TO VALIDATE PRESENCE OF $tModCmdlet`nfailing through to `$backInclDir .ps1 version" ;
            $sLoad = (join-path -path $backInclDir -childpath "$($tModName).ps1") ;
            if (Test-Path $sLoad) {
                Write-Verbose -verbose:$true ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;
                . $sLoad ;
                if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };
                if(!(test-path function:$tModCmdlet)){
                    write-warning "$((get-date).ToString('HH:mm:ss')):FAILED TO CONFIRM `$tModCmdlet:$($tModCmdlet) FOR $($tModName)" ;
                } else {
                    write-verbose -verbose:$true  "(confirmed $tModName loaded: $tModCmdlet present)"
                }
            } else {
                Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ;
                Break;
            } ;
        } else {
            write-verbose -verbose:$true  "(confirmed $tModName loaded: $tModCmdlet present)"
        } ;
    } ;  # loop-E
    #*------^ END MOD LOADS ^------

    # reenable VerbosePreference:Continue, if set, during mod loads
    if($VerbosePrefPrior -eq "Continue"){
        $VerbosePreference = $VerbosePrefPrior ;
        $verbose = ($VerbosePreference -eq "Continue") ;
    } ;

    #*------v get-FolderEmpty.ps1 v------
    if(-not (get-command get-FolderEmpty -ea 0)){
        Function get-FolderEmpty {
            <#
            .SYNOPSIS
            get-FolderEmpty.ps1 - Returns empty subfolders below specified folder (has Recusive param as well).
            .NOTES
            Version     : 1.0.0
            Author      : Todd Kadrie
            Website     : http://www.toddomation.com
            Twitter     : @tostka / http://twitter.com/tostka
            CreatedDate : 2021-06-21
            FileName    : get-FolderEmpty.ps1
            License     : MIT License
            Copyright   : (c) 2020 Todd Kadrie
            Github      : https://github.com/tostka/verb-io
            Tags        : Powershell,Markdown,Input,Conversion
            REVISION
            * 1:02 PM 10/12/2023 fix typo in proc: $folder -> $item
            * 3:22 PM 10/11/2023 init
            .DESCRIPTION
            get-FolderEmpty.ps1 - Returns empty subfolders below specified folder (has Recusive param as well)
    
            .PARAMETER Folder
	        Directory from which to find empty subdirectories[-Folder c:\tmp\]
	        PARAMETER Recurse
	        Recurse directory switch[-Recurse]
            .INPUTS
            Accepts piped input.
            .OUTPUTS
            System.IO.DirectoryInfo[] Array of folder objects
            .EXAMPLE
            PS> get-FolderEmpty -folder $folder -recurse -verbose ' 
            Locate and remove empty subdirs, recursively below the specified directory (single pass, doesn't remove parent folders, see below for looping recursive).
           .EXAMPLE
	        PS > $folder = 'C:\tmp\test' ;
	        PS > Do {
	        PS > 	write-host -nonewline "." ;
	        PS > 	if($mtdirs = get-FolderEmpty -folder $folder -recurse -verbose){
	        PS > 		$mtdirs | remove-item -ea 0 -verbose;
	        PS > 	} ;
	        PS > } Until (-not(get-FolderEmpty -folder $folder -recurse  -verbose)) ;
	        Locate and remove empty subdirs, recursively below the specified directory, repeat pass until all empty subdirs are removed.
            .LINK
            https://github.com/tostka/verb-IO
            #>
            [CmdletBinding()]
            PARAM(
                [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,HelpMessage="Directory from which to find empty subdirectories[-Folder c:\tmp\]")]
                    [System.IO.DirectoryInfo[]]$Folder,
                [Parameter(HelpMessage="Recurse directory switch[-Recurse]")]
                    [switch]$Recurse
            )  ; 
            PROCESS {
                foreach($item in $folder){
			        $sBnrS="`n#*------v PROCESSING : v------" ; 
			        write-verbose $sBnrS ;
			        $pltGCI=[ordered]@{
				        Path = $item ; 
				        Directory = $true ;
				        Recurse=$($Recurse) ; 
				        erroraction = 'STOP' ;
			        } ;
			        $smsg = "get-childitem w`n$(($pltGCI|out-string).trim())" ; 
			        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
			        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
			        Get-ChildItem @pltGCI | Where-Object { $_.GetFileSystemInfos().Count -eq 0 } | write-output ; 
			        write-verbose $sBnrS.replace('-v','-^').replace('v-','^-') ;
                } ; 
            } ;  
        } ; 
    } ; 
    #*------^ get-FolderEmpty.ps1 ^------

    #*------v Function reset-ModulePublishingDirectory v------
    #if(-not(get-command reset-ModulePublishingDirectory -ea 0)){
        function reset-ModulePublishingDirectory {
            <#
            .SYNOPSIS
            reset-ModulePublishingDirectory.ps1 - To fully ensure only current resources are in the modulename\modulename dir (the "Module Publishing Dir" that is built into the published module), this code removes any Resource or License subdir files from the dir. Intent is to ensure the combo of processbulk-NewModule.ps1 & update-NewModule fully stock the dir each pass
            .NOTES
            Version     : 0.0.1
            Author      : Todd Kadrie
            Website     : http://www.toddomation.com
            Twitter     : @tostka / http://twitter.com/tostka
            CreatedDate : 2023-10-27
            FileName    : reset-ModulePublishingDirectory.ps1
            License     : MIT License
            Copyright   : (c) 2023 Todd Kadrie
            Github      : https://github.com/tostka/verb-XXX
            Tags        : Powershell,Module,Development
            AddedCredit : REFERENCE
            AddedWebsite: URL
            AddedTwitter: URL
            REVISIONS
            * 4:37 PM 12/1/2023 add try/catches, wlt support
            * 3:08 PM 10/27/2023 refactor into func():works, adding it to update-NewModule.ps1 ; init
            .DESCRIPTION
            reset-ModulePublishingDirectory.ps1 - To fully ensure only current resources are in the modulename\modulename dir (the "Module Publishing Dir" that is built into the published module), this code removes any Resource files from the dir. Intent is to ensure the combo of processbulk-NewModule.ps1 & update-NewModule fully stock the dir each pass
            .PARAMETER  ModuleName
            The name of the module to be processed
            .PARAMETER whatIf
            Whatif Flag  [-whatIf]
            .INPUTS
            None. Does not accepted piped input.(.NET types, can add description)
            .OUTPUTS
            None. Returns no objects or output (.NET types)
            System.Boolean
            [| get-member the output to see what .NET obj TypeName is returned, to use here]
            .EXAMPLE
            PS> cls ; eisebp ; .\reset-ModulePublishingDirectory.ps1 -ModuleName verb-dev -whatif -verbose 
            EXSAMPLEOUTPUT
            Run with whatif & verbose
            .LINK
            https://github.com/tostka/verb-dev
            .LINK
            https://bitbucket.org/tostka/powershell/
            .LINK
            [ name related topic(one keyword per topic), or http://|https:// to help, or add the name of 'paired' funcs in the same niche (enable/disable-xxx)]
            #>
            # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][AllowEmptyString()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")]#existFolder:[ValidateScript({Test-Path $_ -PathType 'Container'})]#existFile:[ValidateScript({Test-Path $_})]#matchExt:[ValidateScript({$_ -match '\.EXT$'})]#matchExt:[ValidateScript({ if([IO.Path]::GetExtension($_) -ne ".psd1") { throw "Path must point to a .psd1 file" } $true })]#IsDate:[ValidateScript({(($_ -as [DateTime]) -ne $null)})]#isDateInFuture:[ValidateScript({$_ -gt (Get-Date)})][ValidateRange(21,65)]#wholeNum:[ValidateScript({(!($($_) -eq 0)) -and ($($_) -eq $($_ -as [int]))})] $number="1")#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
            ## PULL REGEX VALIDATOR FROM GLOBAL VARI, w friendly errs: [ValidateScript({if(-not $rgxPermittedUserRoles){$rgxPermittedUserRoles = '(SID|CSID|UID|B2BI|CSVC|ESVC|LSVC|ESvcCBA|CSvcCBA|SIDCBA)'} ; if(-not ($_ -match $rgxPermittedUserRoles)){throw "UserRole: '$($_)' doesn't match `$rgxPermittedUserRoles:`n$($rgxPermittedUserRoles.tostring())" ; } ; return $true ; })]
            ## FANCY MULTI CLAUS VALIDATESCRIPT W BETTER ERRS: [ValidateScript({ if(-Not ($_ | Test-Path) ){throw "File or folder does not exist"} ; if(-Not ($_ | Test-Path -PathType Leaf) ){ throw "The Path argument must be a file. Folder paths are not allowed."} ; if($_ -notmatch "(\.msi|\.exe)"){throw "The file specified in the path argument must be either of type msi or exe"} ; return $true ; })]
            ## [OutputType('bool')] # optional specified output type
            [CmdletBinding()]
            ## PSV3+ whatif support:[CmdletBinding(SupportsShouldProcess)]
            ###[Alias('Alias','Alias2')]
            PARAM(
                [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="The name of the module to be processed[-ModuleName verb-dev]")]
                    [ValidateNotNullOrEmpty()]
                    $ModuleName,
                # don't use explicit param v, if using [CmdletBinding(SupportsShouldProcess)] + -WhatIf:$($WhatIfPreference)
                [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
                    [switch] $whatIf=$true
            ) ;
            BEGIN { 
                #region CONSTANTS-AND-ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
                # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
                ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
                $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
                write-verbose "`$PSBoundParameters:`n$(($PSBoundParameters|out-string).trim())" ;
                $Verbose = ($VerbosePreference -eq 'Continue') ; 
                $PurgeSources = 'Resource','Licenses','Docs' ;
                $rgxRootFilesBuild = "(CHANGELOG|README)\.md$" ;
            } ;  # BEGIN-E
            PROCESS {
                $Error.Clear() ; 
    
                foreach($item in $ModuleName) {
                    $smsg = $sBnrS="`n#*------v PROCESSING : $($item) v------" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level H2 } else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
       
                    TRY{
                        $ModPubPath = (get-item "c:\sc\$($item)\$($item)\" -ea STOP).FullName ; 
                    } CATCH {
                        $ErrTrapd=$Error[0] ;
                        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ; 
                    # aggreg targets incrementally
                    [array]$ModPurgeFiles = @() ; 

                    $smsg = "Pre-purge $($rgxRootFilesBuild) Root dir matches from :" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    TRY{
                        if($rootPurgeable = get-childitem -path "c:\sc\$($item)\*" -ea STOP | ? {$_.name -match $rgxRootFilesBuild } | select -expand fullname){
                            $ModPurgeFiles += $rootPurgeable  ; 
                        } ;
                    } CATCH {
                        $ErrTrapd=$Error[0] ;
                        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ; 

                    #purge dirs directly below c:\sc\modname\, with files that should be removed from c:\sc\modname\modname\
                    #$PurgeSources = 'Resource','Licenses','Docs' ;
                    
                    foreach($ModSourceDir in $PurgeSources){ 
                        write-host "processing:$($ModSourceDir)..." ; 
                        TRY{
                            IF($ModResPath = (get-item "c:\sc\$($item)\$($ModSourceDir)\" -ea 0).FullName){
                                $smsg = "$($item) resolved `$ModPubPath:$($ModPubPath)`n`$ModResPath:$($ModResPath)" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                                $smsg = "Reset module $($ModSourceDir) files (purge from $($ModPubPath))" ; 
                                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                                if($SubPurgeFiles = get-childitem -recurse -path $ModResPath -file -EA stop| select -expand fullname){
                                    $ModPurgeFiles += $SubPurgeFiles ; 
                                } ; 
                            } else { 
                                $smsg = "(no matching 'c:\sc\$($item)\$($ModSourceDir)\' content found" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                            } ; 
                        } CATCH {
                            $ErrTrapd=$Error[0] ;
                            $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        } ; 
                    } ; 

                    # cycle purge the targets
                    foreach( $file in $ModPurgeFiles){
                        TRY{
                            $smsg = "==$($file):" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                            if($tf = get-childitem -path $file -ea STOP){
                                if($rf = get-childitem $(join-path $ModPubPath $tf.name ) -ea 0 ){
                                    write-warning "removing matched $($rf.fullname)..."
                                    remove-item $rf.fullname -whatif:$($whatif) -verbose -ea STOP;
                                }else{write-host "no conflicting $($ModPubPath)\$($tf.name) found" }
                            } ; 
                        } CATCH {
                            $ErrTrapd=$Error[0] ;
                            $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            CONTINUE ; 
                        } ; 
                    } ;

                    $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level H2 } else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;  # loop-E
    
            } ;  # PROC-E
        } ; 
    #} ; 
    #*------^ END Function reset-ModulePublishingDirectory ^------

    #*------v Function populate-ModulePublishingDirectory v------
    #if(-not(get-command populate-ModulePublishingDirectory -ea 0)){
        function populate-ModulePublishingDirectory {
            <#
            .SYNOPSIS
            populate-ModulePublishingDirectory.ps1 - after reset-*, this repopulates the REsource/License/root files back into a modules c:\sc\[modulename]\[modulename]\ to create an intact complete flattened source copy for duplication into CU\Docs\Modules, as the target of the Publish-Module command (under the combo of processbulk-NewModule.ps1 & update-NewModule)
            .NOTES
            Version     : 0.0.1
            Author      : Todd Kadrie
            Website     : http://www.toddomation.com
            Twitter     : @tostka / http://twitter.com/tostka
            CreatedDate : 2023-12-01
            FileName    : populate-ModulePublishingDirectory.ps1
            License     : MIT License
            Copyright   : (c) 2023 Todd Kadrie
            Github      : https://github.com/tostka/verb-dev
            Tags        : Powershell,Module,Development
            AddedCredit : REFERENCE
            AddedWebsite: URL
            AddedTwitter: URL
            REVISIONS
            * 3:19 PM 12/4/2023 removed all [#]requires stmts, had runasadmin, blocking install as UID
            * 4:24 PM 12/1/2023 convert reset-, to it's populate equv init
            .DESCRIPTION
            populate-ModulePublishingDirectory.ps1 - after reset-*, this repopulates the REsource/License/root files back into a modules c:\sc\[modulename]\[modulename]\ to create an intact complete flattened source copy for duplication into CU\Docs\Modules, as the target of the Publish-Module command (under the combo of processbulk-NewModule.ps1 & update-NewModule)
            .PARAMETER  ModuleName
            The name of the module to be processed
            .PARAMETER whatIf
            Whatif Flag  [-whatIf]
            .INPUTS
            None. Does not accepted piped input.(.NET types, can add description)
            .OUTPUTS
            None. Returns no objects or output (.NET types)
            System.Boolean
            [| get-member the output to see what .NET obj TypeName is returned, to use here]
            .EXAMPLE
            PS> cls ; eisebp ; .\populate-ModulePublishingDirectory.ps1 -ModuleName verb-dev -whatif -verbose 
            EXSAMPLEOUTPUT
            Run with whatif & verbose
            .LINK
            https://github.com/tostka/verb-dev
            .LINK
            https://bitbucket.org/tostka/powershell/
            .LINK
            [ name related topic(one keyword per topic), or http://|https:// to help, or add the name of 'paired' funcs in the same niche (enable/disable-xxx)]
            #>
            # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][AllowEmptyString()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")]#existFolder:[ValidateScript({Test-Path $_ -PathType 'Container'})]#existFile:[ValidateScript({Test-Path $_})]#matchExt:[ValidateScript({$_ -match '\.EXT$'})]#matchExt:[ValidateScript({ if([IO.Path]::GetExtension($_) -ne ".psd1") { throw "Path must point to a .psd1 file" } $true })]#IsDate:[ValidateScript({(($_ -as [DateTime]) -ne $null)})]#isDateInFuture:[ValidateScript({$_ -gt (Get-Date)})][ValidateRange(21,65)]#wholeNum:[ValidateScript({(!($($_) -eq 0)) -and ($($_) -eq $($_ -as [int]))})] $number="1")#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
            ## PULL REGEX VALIDATOR FROM GLOBAL VARI, w friendly errs: [ValidateScript({if(-not $rgxPermittedUserRoles){$rgxPermittedUserRoles = '(SID|CSID|UID|B2BI|CSVC|ESVC|LSVC|ESvcCBA|CSvcCBA|SIDCBA)'} ; if(-not ($_ -match $rgxPermittedUserRoles)){throw "UserRole: '$($_)' doesn't match `$rgxPermittedUserRoles:`n$($rgxPermittedUserRoles.tostring())" ; } ; return $true ; })]
            ## FANCY MULTI CLAUS VALIDATESCRIPT W BETTER ERRS: [ValidateScript({ if(-Not ($_ | Test-Path) ){throw "File or folder does not exist"} ; if(-Not ($_ | Test-Path -PathType Leaf) ){ throw "The Path argument must be a file. Folder paths are not allowed."} ; if($_ -notmatch "(\.msi|\.exe)"){throw "The file specified in the path argument must be either of type msi or exe"} ; return $true ; })]
            ## [OutputType('bool')] # optional specified output type
            [CmdletBinding()]
            ## PSV3+ whatif support:[CmdletBinding(SupportsShouldProcess)]
            ###[Alias('Alias','Alias2')]
            PARAM(

                [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="The name of the module to be processed[-ModuleName verb-dev]")]
                    [ValidateNotNullOrEmpty()]
                    $ModuleName,
                # don't use explicit param v, if using [CmdletBinding(SupportsShouldProcess)] + -WhatIf:$($WhatIfPreference)
                [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
                    [switch] $whatIf=$true

            ) ;
            BEGIN { 
                #region CONSTANTS-AND-ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
                # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
                ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
                $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
                write-verbose "`$PSBoundParameters:`n$(($PSBoundParameters|out-string).trim())" ;
                $Verbose = ($VerbosePreference -eq 'Continue') ; 
                $PurgeSources = 'Resource','Licenses','Docs' ;
                $rgxRootFilesBuild = "(CHANGELOG|README)\.md$" ;
            } ;  # BEGIN-E
            PROCESS {
                $Error.Clear() ; 
    
                foreach($item in $ModuleName) {
                    $smsg = $sBnrS="`n#*------v PROCESSING : $($item) v------" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level H2 } else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
       
                    $ModPubPath = (get-item "c:\sc\$($item)\$($item)\" -ea 0).FullName ; 
                    # aggreg targets incrementally
                    [array]$ModSourceFiles = @() ; 

                    $smsg = "Locating $($rgxRootFilesBuild) Root dir matches from :" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    if($rootPurgeable = get-childitem -path "c:\sc\$($item)\*" | ? {$_.name -match $rgxRootFilesBuild } | select -expand fullname){
                        $ModSourceFiles += $rootPurgeable  ; 
                    } ;

                    #copy dirs directly below c:\sc\modname\, with files that should be removed from c:\sc\modname\modname\
                    #$PurgeSources = 'Resource','Licenses','Docs' ;

                    foreach($ModSourceDir in $PurgeSources){ 
                        write-host "processing:$($ModSourceDir)..." ; 
                        if($ModResPath = (get-item "c:\sc\$($item)\$($ModSourceDir)\" -ea 0).FullName){
                            $smsg = "$($item) resolved `$ModPubPath:$($ModPubPath)`n`$ModResPath:$($ModResPath)" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                            $smsg = "Recopy module $($ModSourceDir) files (copy from $($ModPubPath))" ; 
                            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                            if($SubcopyFiles = get-childitem -recurse -path $ModResPath -file | select -expand fullname){
                                $ModSourceFiles += $SubcopyFiles ; 
                            } ; 
                        } else { 
                            $smsg = "(no matching 'c:\sc\$($item)\$($ModSourceDir)\' content found" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                        } ; 
                   } ;  # loop-E

                   $pltCI=[ordered]@{
                        #path = $null ;
                        path = $ModSourceFiles ;
                        destination = $ModPubPath ; 
                        force = $true ; 
                        erroraction = 'STOP' ;
                        verbose = $($VerbosePreference -eq "Continue") ; 
                        whatif = $($whatif) ;
                    } ;
                    #$smsg = "copy-item w`n$(($pltCI|out-string).trim())" ; 
                    #if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                   <# cycle copy the targets
                   foreach( $file in $ModSourceFiles){
                        write-host "==$($file):" ;
                        if($tf = get-childitem -path $file -ea STOP){
                            #write-warning "removing matched $($rf.fullname)..."
                            #remove-item $rf.fullname -whatif:$($whatif) -verbose -ea STOP;
                            $pltCI.path = $tf.fullname ; 
                            $smsg = "copy-item w`n$(($pltCI|out-string).trim())" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            copy-item @pltCI ; 
                        } ; 
                    } ;
                    #>
                    $smsg = "copy-item w`n$(($pltCI|out-string).trim())" ; 
                    $smsg += "`n--`$pltCI.path:`n$(($pltCI.path|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    # it's flat file coying, just single-line it verbose
                    TRY{
                        copy-item @pltCI ;
                    } CATCH {
                        $ErrTrapd=$Error[0] ;
                        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ; 

                    $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level H2 } else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;  # loop-E
    
            } ;  # PROC-E
        } ; 
    #} ; 
    #*------^ END Function populate-ModulePublishingDirectory ^------

    #*======^ END FUNCTIONS ^======


    #*======v SUB MAIN v======

    # Clear error variable
    $Error.Clear() ;

    # ensure running SID *not* UID
    if("$env:userdomain\$env:username" -match $rgxAcctWAdmn){
        # proper SID acct (shouldn't be exec'd SID)
    } elseif("$env:userdomain\$env:username" -match $rgxAcctWUID){
        $smsg = "RUNNING AS *UID* - $($env:userdomain)\$($env:username) - MUST BE RUN *SID*! EXITING!" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        Break ;
    } ;


    if($Merge -AND $Republish){
        $smsg = "*WARNING!*:-Merge *AND* -Republish specified! Please use one or the other, but *not* BOTH!" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        Break ;
    } ;

    if($env:USERDOMAIN -EQ $DomainWork){
        if("$($env:USERDOMAIN)\$($env:USERNAME)" -notmatch $rgxAcctWAdmn ){
            write-host -foregroundcolor RED "$((get-date).ToString('HH:mm:ss')):*WARNING*! THIS SCRIPT MUST BE RUN AS SID AT WORK`nREQUIRES *ADMIN* REPO PUBLISHING PERMS, `nWHICH UID LACKS ($($env:USERDOMAIN)\$($env:USERNAME))" ;
            #popd ;
            Break ;
        } ;
    } ;

    # 2:32 PM 9/27/2021 updated start-log code
    if(!(get-variable LogPathDrives -ea 0)){$LogPathDrives = 'd','c' };
    foreach($budrv in $LogPathDrives){if(test-path -path "$($budrv):\scripts" -ea 0 ){break} } ;
    if(!(get-variable rgxPSAllUsersScope -ea 0)){
        $rgxPSAllUsersScope="^$([regex]::escape([environment]::getfolderpath('ProgramFiles')))\\((Windows)*)PowerShell\\(Scripts|Modules)\\.*\.(ps(((d|m))*)1|dll)$" ;
    } ;
    if(!(get-variable rgxPSCurrUserScope -ea 0)){
        $rgxPSCurrUserScope="^$([regex]::escape([Environment]::GetFolderPath('MyDocuments')))\\((Windows)*)PowerShell\\(Scripts|Modules)\\.*\.(ps((d|m)*)1|dll)$" ;
    } ;
    $pltSL=[ordered]@{Path=$null ;NoTimeStamp=$false ;Tag=$null ;showdebug=$($showdebug) ; Verbose=$($VerbosePreference -eq 'Continue') ; whatif=$($whatif) ;} ;
    $pltSL.Tag = $ModuleName ;
    # 3:03 PM 6/22/2023 #361: splice in better error-handling fail through code from psb-psparamt ($budrv covers for empty referrals)
    if($script:PSCommandPath){
        if(($script:PSCommandPath -match $rgxPSAllUsersScope) -OR ($script:PSCommandPath -match $rgxPSCurrUserScope)){
            $bDivertLog = $true ; 
            switch -regex ($script:PSCommandPath){
                $rgxPSAllUsersScope{$smsg = "AllUsers"} 
                $rgxPSCurrUserScope{$smsg = "CurrentUser"}
            } ;
            $smsg += " context script/module, divert logging into [$budrv]:\scripts" 
            write-verbose $smsg  ;
            if($bDivertLog){
                if((split-path $script:PSCommandPath -leaf) -ne $cmdletname){
                    # function in a module/script installed to allusers|cu - defer name to Cmdlet/Function name
                    $pltSL.Path = (join-path -Path "$($budrv):\scripts" -ChildPath "$($cmdletname).ps1") ;
                } else {
                    # installed allusers|CU script, use the hosting script name
                    $pltSL.Path = (join-path -Path "$($budrv):\scripts" -ChildPath (split-path $script:PSCommandPath -leaf)) ;
                }
            } ;
        } else {
            $pltSL.Path = $script:PSCommandPath ;
        } ;
    } else {
        if(($MyInvocation.MyCommand.Definition -match $rgxPSAllUsersScope) -OR ($MyInvocation.MyCommand.Definition -match $rgxPSCurrUserScope) ){
             $pltSL.Path = (join-path -Path "$($budrv):\scripts" -ChildPath (split-path $script:PSCommandPath -leaf)) ;
        } elseif(test-path $MyInvocation.MyCommand.Definition) {
            $pltSL.Path = $MyInvocation.MyCommand.Definition ;
        } elseif($cmdletname){
            $pltSL.Path = (join-path -Path "$($budrv):\scripts" -ChildPath "$($cmdletname).ps1") ;
        } else {
            $smsg = "UNABLE TO RESOLVE A FUNCTIONAL `$CMDLETNAME, FROM WHICH TO BUILD A START-LOG.PATH!" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Warn } #Error|Warn|Debug 
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            BREAK ;
        } ; 
    } ;
    write-verbose "start-Log w`n$(($pltSL|out-string).trim())" ; 
    $logspec = start-Log @pltSL ;
    $error.clear() ;
    TRY {
        if($logspec){
            $logging=$logspec.logging ;
            $logfile=$logspec.logfile ;
            $transcript=$logspec.transcript ;
            $stopResults = try {Stop-transcript -ErrorAction stop} catch {} ;
            start-Transcript -path $transcript ;
        } else {throw "Unable to configure logging!" } ;
    } CATCH {
        $ErrTrapd=$Error[0] ;
        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $PassStatus += ";ERROR";
        Break ; 
    } ; 
    
    $sBnr="#*======v $($ScriptBaseName):$($ModuleName) v======" ;
    $smsg= "$($sBnr)" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

    # code further in deps on $modRoot which is undefined, so coerce it from the mandetory $ModDirPath 
    if(-not $modRoot -AND $ModDirPath){
        $smsg = "`$modRoot is blank, assigning from mandetory param:`$ModDirPath" ; 
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        $modRoot = $ModDirPath ; 
    } ; 

    $ModPsmName = "$($ModuleName).psm1" ;
    # C:\sc\verb-AAD\verb-AAD\verb-AAD.psd1
    # default to Public, but support External, if it pre-exists:
    if(test-path "$($ModDirPath)\External" ){
        $smsg = "Pre-existing variant found, and put into use:$($ModDirPath)\External" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $PublicDirPath = "$($ModDirPath)\External" ;
    } else {
        $PublicDirPath = "$($ModDirPath)\Public" ;
    } ;
    # default to Internal, but support Private, if it pre-exists:
    if(test-path "$($ModDirPath)\Private" ){
        $smsg = "Pre-existing variant found, and put into use:$($ModDirPath)\Private" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $InternalDirPath = "$($ModDirPath)\Private" ;
    } else {
        $InternalDirPath = "$($ModDirPath)\Internal" ;
    } ;
    # provide a fall back to 'stock' location in case it's unresolved below
    $ModPsdPath = "$(join-path -path (join-path -path $Moddirpath -ChildPath $modulename) -ChildPath $modulename).psd1"
    # "C:\sc\verb-AAD" ; C:\sc\verb-AAD\Tests\verb-AAD.tests.ps1
    $TestScriptPath = "$($ModDirPath)\Tests\$($ModuleName).tests.ps1" ;
    $rgxSignFiles='\.(CAT|MSI|JAR,OCX|PS1|PSM1|PSD1|PS1XML|PSC1|MSP|CMD|BAT|VBS)$' ;
    # expand to cover External & Private variant names as well - this is used solely to exclude signing of component files that will be signed as a monolithic .psm1
    $rgxIncludeDirs='\\(Public|Internal|External|Private|Classes)\\' ;
    $rgxOldFingerprint = 'fingerprint\._\d{8}-\d{4}(A|P)M' ; 

    $editor = "notepad2.exe" ;

    $error.clear() ;

    if($NoBuildInfo){
        # 9:34 AM 6/29/2020 for some reason, on join-object mod, Set-BuildEnvironment is going into the abyss, running git.exe log --format=%B -n 1
        # so use psd1version and manually increment, skipping BuildHelper mod use entirely
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):(-NoBuildInfo specified:Skipping use of buggy BuildHelpers module)" ;
        TRY {
            if($ModPsdPath = (get-childitem "$($modroot)\$($ModuleName)\$($ModuleName).psd1" -ea 0).FullName){

            } elseif ($ModPsdPath = Get-PSModuleFile -path $ModRoot -Extension .psd1){

            } else {
                $smsg = "Unable to resolve manifest .psd1 path for module dir:$($modroot)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                throw $smsg
                break ;
            } ;
            $smsg = "Resolved `$ModPsdPath:`n$($ModPsdPath)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            # $ModPsdPath
            if($psd1Profile = Test-ModuleManifest -path $ModPsdPath -errorVariable ttmm_Err -WarningVariable ttmm_Wrn -InformationVariable ttmm_Inf){
                if($ttmm_Err){
                    $smsg = "`nFOUND `$ttmm_Err: test-ModuleManifest HAD ERRORS!" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    foreach($errExcpt in $ttmm_Err.Exception){
                        switch -regex ($errExcpt){
                            "The\sspecified\sFileList\sentry\s'.*'\sin\sthe\smodule\smanifest\s'.*.psd1'\sis\sinvalid\." {
                                $smsg = "`nPSD1 Manifest has FileList specification, with no matching file found in $($modroot)\$($ModuleName)\!" ;
                                $smsg += "`nThe PSD MUST be edited or rolled back to # FileList = @()  spec, to properly build"
                                $smsg += "`n(build update-NewModule will detect and re-add the FileList from scratch, fr files in \\(Docs|Licenses|Resource)\ or named (Resource|Licenses) (extensionless)" ;
                                $smsg += "`n`n to find the last psd1/.psd1_ with the empty spec:" ; 
                                $smsg += "`ngci C:\sc\$($ModuleName)\$($ModuleName)\*.psd1* | sort LastWriteTime |  sls -pattern `"#\sFileList\s=\s@\(\)`" | select -last 1; `n" ;  
                                $smsg += "`n$($errExcpt)" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            }
                            default {
                                $smsg = "`nPSD1 MANIFEST UNDEFINED TESTING ERROR!" ;
                                $smsg += "`nThe PSD MUST be edited or rolled back to a functional revision to properly build!"
                                $smsg += "`n(build update-NewModule will detect and re-add the FileList from scratch, fr files in \\(Docs|Licenses|Resource)\ or named (Resource|Licenses) (extensionless)" ;
                                $smsg += "`n$($errExcpt)" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            }
                        } ;
                    } ;
                    # abort build here
                    BREAK ; 
                } else {
                    $smsg = "(no `$ttmm_Err: test-ModuleManifest had no errors)" ;
                    if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                } ; 
                # ...
            } else { write-warning "$((get-date).ToString('HH:mm:ss')):Unable to locate psd1:$($ModPsdPath)" } ;


            # check for failure of last command
            if($? ){
                $smsg= "(Test-ModuleManifest:PASSED)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            }

        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $PassStatus += ";ERROR";
            Break ; 
        } ; 
        if($RequiredVersion.tostring() -AND  $psd1Profile){
            if($psd1Profile.Version.tostring() -eq $RequiredVersion.tostring()){
                $psd1UpdatedVers = $psd1Vers = $psd1Profile.Version.tostring() ;
            } else {
                $PassStatus += ";ERROR";
                $smsg= "Version mismatch between PSD1:$($ModPsdPath):$($psd1Profile.Version.tostring())`nand explicit `$RequiredVersion specified:$($RequiredVersion.tostring())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Break ;
            } ; 
        } else {
            $smsg = "(no explicit -Version:deferring to psd1.version)" ; 
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            $psd1UpdatedVers = $psd1Vers = $psd1Profile.Version.tostring() ;
        } ;

    } else {
        # stock buildhelper e-varis - I don't even see it in *use*
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):(executing:Get-BuildEnvironment -Path $($ModDirPath) `n(use -NoBuildInfo if hangs))" ;
        $BuildVariable = Get-BuildVariable -path $ModDirPath
        <# *not* equiv to Set-BuildEnvironment -Path $ModRoot -Force! only returns a tiny subset of the evaris set by sbe
            $BuildVariable | fl *
            BuildSystem   : Unknown
            ProjectPath   : C:\sc\verb-io
            BranchName    : master
            CommitMessage : Update Set-ContentFixEncoding.ps1
                            3:40 PM 5/6/2022 added echo top 2 lines of passed Value, and added pswlt
            CommitHash    : 454b1f8e4b5afb76ac1038d723089ac802db6f1a
            BuildNumber   : 0
        #>
        if(test-path $env:BHPSModuleManifest){        
            $ModPsdPath = $env:BHPSModuleManifest ;
        } ;

    } ;
    <# 	Get-Item ENV:BH* ;
        returned as an object when run above:
        #-=-=-=-=-=-=-=-=
        BuildSystem   : Unknown
        ProjectPath   : C:\sc\verb-AAD
        BranchName    : master
        CommitMessage : 3a372b0324af6761bcd7aa492a89ee87ef34ef45
        CommitHash    :
        BuildNumber   : 0
        #-=-=-=-=-=-=-=-=
        Evaris config'd if run on cmdline:
	    Name                           Value
	    ----                           -----
	    BHProjectName                  verb-AAD
	    BHModulePath                   C:\sc\verb-AAD\verb-AAD
	    BHPSModulePath                 C:\sc\verb-AAD\verb-AAD
	    BHProjectPath                  C:\sc\verb-AAD
	    BHBuildOutput                  C:\sc\verb-AAD\BuildOutput
	    BHPSModuleManifest             C:\sc\verb-AAD\verb-AAD\verb-AAD.psd1
	    BHBuildSystem                  Unknown
	    BHCommitMessage                3a372b0324af6761bcd7aa492a89ee87ef34ef45
	    BHBranchName                   master
	    BHBuildNumber                  0
    #>

    # we're losing the psdversion post rebuild, store the value just set by Step-ModuleVersion
    TRY{
        $psd1UpdatedVers = (Import-PowerShellDataFile -Path $ModPsdPath).ModuleVersion.tostring() ;
    } CATCH {
        $ErrTrapd=$Error[0] ;
        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $smsg = "Import-PowerShellDataFile:Failed processing ^ " ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
        $PassStatus += ";ERROR";
        Break ; 
    } ; 
    if($RequiredVersion.tostring() -AND $psd1UpdatedVers){
        if($psd1UpdatedVers.tostring() -eq $RequiredVersion.tostring()){
            $psd1Vers = $psd1UpdatedVers.tostring() ;
        } else {
            $PassStatus += ";ERROR";
            $smsg= "Version mismatch between PSD1:$($ModPsdPath):$($psd1UpdatedVers.tostring())`nand explicit `$RequiredVersion specified:$($RequiredVersion.tostring())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            Break ;
        } ; 
    } else {
        $smsg = "(no explicit -Version:deferring to psd1.version)" ; 
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        $psd1Vers = $psd1UpdatedVers.tostring() ;
    } ;

    $smsg = "Run: reset-ModulePublishingDirectory -ModuleName $($ModuleName)" ; 
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
    reset-ModulePublishingDirectory -ModuleName $ModuleName -whatif:$($whatif) -verbose:$($VerbosePreference -eq "Continue") ; 
    
    $smsg = "Run: populate-ModulePublishingDirectory -ModuleName $($ModuleName)" ; 
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
    #reset-ModulePublishingDirectory -ModuleName $ModuleName -whatif:$($whatif) -verbose:$($VerbosePreference -eq "Continue") ; 
    populate-ModulePublishingDirectory -ModuleName $ModuleName -whatif:$($whatif) -verbose:$($VerbosePreference -eq "Continue") ; 

    # this is probably where we should purge out any garbage brought in - nope this never gets triggered, try splcing into exit, we just want these purged as deadwood, they aren't making it into the build anyway
    $smsg = "Run: Remove any non-pub garbage cp'd into c:\sc\$($ModuleName)\$($ModuleName) -ModuleName $($ModuleName)" ; 
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
    if($killfiles = gci -path "c:\sc\$($ModuleName)\$($ModuleName)" | ?{$_.fullname -match $rgxModModPurges}){
        $killfiles | remove-item -force -verbose -whatif:$($whatif) ; 
    } ; 

    $smsg = "Validate updated $($ModuleName)\$($ModuleName) dir contents against Manifest:`nRun: test-modulemanifest -Path $($ModPsdPath)" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
    if($TestReport = test-modulemanifest -Path $ModPsdPath -errorVariable ttmm_Err -WarningVariable ttmm_Wrn -InformationVariable ttmm_Inf){
        if($ttmm_Err){
            $smsg = "`nFOUND `$ttmm_Err: test-ModuleManifest HAD ERRORS!" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            foreach($errExcpt in $ttmm_Err.Exception){
                switch -regex ($errExcpt){
                    "The\sspecified\sFileList\sentry\s'.*'\sin\sthe\smodule\smanifest\s'.*.psd1'\sis\sinvalid\." {
                        $smsg = "`nPSD1 Manifest has FileList specification, with no matching file found in $($modroot)\$($ModuleName)\!" ;
                        $smsg += "`nThe PSD MUST be edited or rolled back to # FileList = @()  spec, to properly build"
                        $smsg += "`n(build update-NewModule will detect and re-add the FileList from scratch, fr files in \\(Docs|Licenses|Resource)\ or named (Resource|Licenses) (extensionless)" ;
                        $smsg += "`n`n to find the last psd1/.psd1_ with the empty spec:" ; 
                        $smsg += "`ngci C:\sc\$($ModuleName)\$($ModuleName)\*.psd1* | sort LastWriteTime |  sls -pattern `"#\sFileList\s=\s@\(\)`" | select -last 1; `n" ;  
                        $smsg += "`n$($errExcpt)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    }
                    default {
                        $smsg = "`nPSD1 MANIFEST UNDEFINED TESTING ERROR!" ;
                        $smsg += "`nThe PSD MUST be edited or rolled back to a functional revision to properly build!"
                        $smsg += "`n(build update-NewModule will detect and re-add the FileList from scratch, fr files in \\(Docs|Licenses|Resource)\ or named (Resource|Licenses) (extensionless)" ;
                        $smsg += "`n$($errExcpt)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    }
                } ;
            } ;
            # abort build here
            BREAK ; 
        } else {
            $smsg = "(no `$ttmm_Err: test-ModuleManifest had no errors)" ;
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
        } ; 
    } ;

    if(!$Republish){
        $sHS=@"
NON-Republish pass detected:
$(if($Merge){'MERGE parm specified as well:`n-Merge Public|Internal|Classes include subdirs module content into updated .psm1'} else {'(no -merge specified)'})
-Sign updated files.
-Uninstall/Remove existing profile module
-Copy new module to profile
-Confirm: Get-Module -ListAvailable
-Check/Update existing Psd1 Version
-Publish-Module
-Remove existing installed profile module
-Test Install-Module
-Test Import-Module
"@ ;
        $smsg= $sHS;  ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

        if($Merge){
            $smsg= "-Merge specified..." ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $pltmergeModule=[ordered]@{
              ModuleName=$($ModuleName) ;
              ModuleSourcePath="$($PublicDirPath)","$($InternalDirPath)" ;
              ModuleDestinationPath="$($ModDirPath)\$($ModuleName)" ;
              RequiredVersion = $RequiredVersion 
              LogSpec = $logspec ;
              NoAliasExport=$($NoAliasExport) ;
              ErrorAction="Stop" ;
              showdebug=$($showdebug);
              whatif=$($whatif);
            } ;
            $smsg= "ConvertTo-ModuleMergedTDO w`n$(($pltmergeModule|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            $ReportObj = ConvertTo-ModuleMergedTDO @pltmergeModule ;
            
            <#  $ReportObj=[ordered]@{
                    Status=$true ;
                    PsmNameBU = $PsmNameBU ;
                    PassStatus = $PassStatus ;
                } ;
            #>
            $PsmNameBu=$ReportObj.PsmNameBU ;
            if($ReportObj.Status){

            } else {
                $smsg= "ConvertTo-ModuleMergedTDO failure.`nPassStatus:$($reportobj.PassStatus)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if($PsmNameBu){
                    $smsg= "Restoring PSM1 from backup:" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    
                    $bRet = restore-FileTDO -Source $PsmNameBu -Destination $ModPsmPath -showdebug:$($showdebug) -whatif:$($whatif)
                    if(-not $bRet -AND -not $whatif){throw "restore-FileTDO -Source $($PsmNameBu) -Destination $($ModPsmPath)!" } else {
                        $PassStatus += ";UPDATED:restore-FileTDO PsmNameBu";
                    }  ;
                    
                } else {
                    $smsg= "(no backup .psm1 to revert from)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;                    
                } ;
                if($PsdNameBu){
                    $smsg= "Restoring PSD1 from backup:" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    
                    $bRet = restore-FileTDO -Source $PsdNameBu -Destination $ModPsdPath -showdebug:$($showdebug) -whatif:$($whatif)
                    if(-not $bRet -AND -not $whatif){throw "restore-FileTDO -Source $($PsdNameBu) -Destination $($ModPsdPath)!" } else {
                        $PassStatus += ";UPDATED:restore-FileTDO PsdNameBu";
                    }  ;
                } else {
                    $smsg= "(no backup .psm1 to revert from)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                    else{ write-WARNING $smsg } ;
                } ;

                # should restore fingerprint as well
                #$rgxOldFingerprint = 'fingerprint\._\d{8}-\d{4}(A|P)M' ; 
                if($oldfingerprint = get-childitem -path "$($ModDirPath)\fingerprint*" | ?{$_.name -match $rgxOldFingerprint } | sort LastWriteTime | select -last 1 | select -expand fullname){
                   $smsg= "Restoring`n$($oldfingerprint)`nfrom backup:" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    
                    $bRet = restore-FileTDO -Source $oldfingerprint -Destination "$($ModDirPath)\fingerprint" -showdebug:$($showdebug) -whatif:$($whatif)
                    if(-not $bRet -AND -not $whatif){throw "restore-FileTDO -Source $($oldfingerprint) -Destination $($ModDirPath)\fingerprint!" } else {
                        $PassStatus += ";UPDATED:restore-FileTDO oldfingerprint";
                    }  ;
                } else {
                    $smsg= "(no backup fingerprint._yyyymmdd-hhmmtt to revert from)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                    else{ write-WARNING $smsg } ;
                } ;
            } ;
        } else {
            $smsg= "-Merge *not* specified: UNMERGE implied (dynamic include .psm1 build)..." ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $pltmergeModule=[ordered]@{
                ModuleName=$($ModuleName) ;
                ModuleSourcePath="$($PublicDirPath)","$($InternalDirPath)" ;
                ModuleDestinationPath="$($ModDirPath)\$($ModuleName)" ;
                LogSpec = $logspec ;
                NoAliasExport=$($NoAliasExport) ;
                ErrorAction="Stop" ;
                showdebug=$($showdebug);
                whatif=$($whatif);
            } ;
            $smsg= "ConvertTo-ModuleDynamicTDO w`n$(($pltmergeModule|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            $ReportObj = ConvertTo-ModuleDynamicTDO @pltmergeModule ;
           
            <#  $ReportObj=[ordered]@{
                    Status=$true ;
                    PsmNameBU = $PsmNameBU ;
                    PassStatus = $PassStatus ;
                } ;
            #>
            $PsmNameBu=$ReportObj.PsmNameBU ;
            # get the psd as well: 
            $PsdNameBU = $ReportObj.sdNameBU ;
            if($ReportObj.Status){

            } else {
                $smsg= "ConvertTo-ModuleDynamicTDO failure.`nPassStatus:$($reportobj.PassStatus)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if($PsmNameBu){
                    $smsg= "Restoring PSM1 from backup:" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    
                    $bRet = restore-FileTDO -Source $PsmNameBu -Destination $ModPsmPath -showdebug:$($showdebug) -whatif:$($whatif)
                    if(-not $bRet -AND -not $whatif){throw "restore-FileTDO -Source $($PsmNameBu) -Destination $($ModPsmPath)!" } else {
                        $PassStatus += ";UPDATED:restore-FileTDO PsmNameBu";
                    }  ;
                    
                } else {
                    $smsg= "(no backup .psm1 to revert from)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                    else{ write-WARNING $smsg } ;
                } ;
                if($PsdNameBu){
                    $smsg= "Restoring PSD1 from backup:" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    
                    $bRet = restore-FileTDO -Source $PsdNameBu -Destination $ModPsdPath -showdebug:$($showdebug) -whatif:$($whatif)
                    if(-not $bRet -AND -not $whatif){throw "restore-FileTDO -Source $($PsdNameBu) -Destination $($ModPsdPath)!" } else {
                        $PassStatus += ";UPDATED:restore-FileTDO PsdNameBu";
                    }  ;
                } else {
                    $smsg= "(no backup .psm1 to revert from)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                    else{ write-WARNING $smsg } ;
                } ;

                # should restore fingerprint as well
                #$rgxOldFingerprint = 'fingerprint\._\d{8}-\d{4}(A|P)M' ; 
                if($oldfingerprint = get-childitem -path "$($ModDirPath)\fingerprint*" | ?{$_.name -match $rgxOldFingerprint } | sort LastWriteTime | select -last 1 | select -expand fullname){
                   $smsg= "Restoring`n$($oldfingerprint)`nfrom backup:" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    
                    $bRet = restore-FileTDO -Source $oldfingerprint -Destination "$($ModDirPath)\fingerprint" -showdebug:$($showdebug) -whatif:$($whatif)
                    if(-not $bRet -AND -not $whatif){throw "restore-FileTDO -Source $($oldfingerprint) -Destination $($ModDirPath)\fingerprint!" } else {
                        $PassStatus += ";UPDATED:restore-FileTDO oldfingerprint";
                    }  ;
                } else {
                    $smsg= "(no backup fingerprint._yyyymmdd-hhmmtt to revert from)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                    else{ write-WARNING $smsg } ;
                } ;
            } ;
        }

    } else {
        $sHS=@"
*REPUBLISH* param detected, performing solely *republish* steps:`
-Uninstall-Module/Remove any existing profile module
-Copy new module to profile
-Confirm: Get-Module -ListAvailable
-Check/Update existing Psd1 Version
-Publish-Module
-Remove existing installed profile module
-Test Install-Module
-Test Import-Module
"@ ;
        $smsg= $sHS;  ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ; # non-republish block above

    $error.clear() ;
    TRY {
        # $ModPsdPath
        if($psd1Profile = Test-ModuleManifest -path $ModPsdPath -errorVariable ttmm_Err -WarningVariable ttmm_Wrn -InformationVariable ttmm_Inf){
            if($ttmm_Err){
                $smsg = "`nFOUND `$ttmm_Err: test-ModuleManifest HAD ERRORS!" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                foreach($errExcpt in $ttmm_Err.Exception){
                    switch -regex ($errExcpt){
                        "The\sspecified\sFileList\sentry\s'.*'\sin\sthe\smodule\smanifest\s'.*.psd1'\sis\sinvalid\." {
                            $smsg = "`nPSD1 Manifest has FileList specification, with no matching file found in $($modroot)\$($ModuleName)\!" ;
                            $smsg += "`nThe PSD MUST be edited or rolled back to # FileList = @()  spec, to properly build"
                            $smsg += "`n(build update-NewModule will detect and re-add the FileList from scratch, fr files in \\(Docs|Licenses|Resource)\ or named (Resource|Licenses) (extensionless)" ;
                            $smsg += "`n`n to find the last psd1/.psd1_ with the empty spec:" ; 
                            $smsg += "`ngci C:\sc\$($ModuleName)\$($ModuleName)\*.psd1* | sort LastWriteTime |  sls -pattern `"#\sFileList\s=\s@\(\)`" | select -last 1; `n" ;  
                            $smsg += "`n$($errExcpt)" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        }
                        default {
                            $smsg = "`nPSD1 MANIFEST UNDEFINED TESTING ERROR!" ;
                            $smsg += "`nThe PSD MUST be edited or rolled back to a functional revision to properly build!"
                            $smsg += "`n(build update-NewModule will detect and re-add the FileList from scratch, fr files in \\(Docs|Licenses|Resource)\ or named (Resource|Licenses) (extensionless)" ;
                            $smsg += "`n$($errExcpt)" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        }
                    } ;
                } ;
                # abort build here
                BREAK ; 
            } else {
                $smsg = "(no `$ttmm_Err: test-ModuleManifest had no errors)" ;
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            } ; 
            # ...
        } else { write-warning "$((get-date).ToString('HH:mm:ss')):Unable to locate psd1:$($ModPsdPath)" } ;
        # check for failure of last command
        if($? ){
            $smsg= "(Test-ModuleManifest:PASSED)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        }
    } CATCH {
        $ErrTrapd=$Error[0] ;
        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $PassStatus += ";ERROR";
        Break ; 
    } ; 
    
    $psd1Vers = $psd1Profile.Version.tostring() ;
    $psd1guid = $psd1Profile.Guid.tostring() ;
    if(test-path $TestScriptPath){
        # update the pester test script with guid: C:\sc\verb-AAD\Tests ; C:\sc\verb-AAD\Tests\verb-AAD.tests.ps1
        $smsg= "Checking sync of Psd1 module guid to the Pester Test Script: $($TestScriptPath)" ; ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

        # 2:36 PM 6/1/2022 defer into confirm-ModuleBuildSync, further down)

    } else {
        $smsg = "Unable to locate `$TestScriptPath:$($TestScriptPath)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level INfo } #Error|Warn|Debug
        else{ write-verbose -verbose:$true "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;

    # ----------- defer psd1/psm1/pester-ps1 sync confirm into: confirm-ModuleBuildSync
    # Verify and re-sync psd version to the input newbuild incremented version (in case it got lost in the rebuild)
    # could use new confirm-ModulePsd1Version (rgx based, for .psd1_TMP file work), but below is safer/more-holistic solution - although update-modulemanifest would also write a new ModuleVersion into the psd1 as well
    
    # shift to wrapper confirm-ModuleBuildSync() -NoTest, as only update-NewModule needs that step
    # $bRet = confirm-ModuleBuildSync -ModPsdPath 'C:\sc\verb-IO\verb-IO\verb-IO.psd1_TMP' -RequiredVersion '2.0.3' -whatif -verbose
    $pltCMBS=[ordered]@{
        ModPsdPath = $ModPsdPath ;
        RequiredVersion = $RequiredVersion ;
        #NoTest = $true ;  # run it on final prod pre-build pass
        whatif = $($whatif) ;
        verbose = $($verbose) ;
    } ;
    $smsg = "confirm-ModuleBuildSync w`n$(($pltCMBS|out-string).trim())" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    $bRet = confirm-ModuleBuildSync @pltCMBS ;
    if($bRet.Manifest -AND $bRet.Module -AND $bRet.Pester -AND $bRet.Guid -AND $bRet.Version -AND $bRet.Valid){
        $smsg = "(confirm-ModuleBuildSync:Success)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } else { 
        $smsg = "confirm-ModuleBuildSync:FAIL! Aborting!" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        Break ;
    } ;    

    # ==Update the psd1 FunctionsToExport : (moved to ConvertTo-ModuleDynamicTDO, after the export-modulemember code)

    <# ==Update the psd1 FileList (external non-code files resources (normally in Resources) that need to be bundled in pkg: 
        - only included in pkg/installed, if in the psd1.filelist key:value 
        - have to resolve and access dynamically them using gmo
        # this approach stocks an indexed hash with the associated path of each
        $myModule = Get-Module YourModule ;
        $ResFiles = @{} ;
        foreach ($file in $myModule.FileList){
            $path = Join-Path $myModule.ModuleBase $file ;
            $ResFiles[$file] = $path ;
        } ;
        $myCsspath = $resfiles['bootstrap.min.css'] ; 
        # they'll all be tossed into the module root dir/$myModule.ModuleBase dir unorganized when installed
    #>
    # 1) assemble the list of non-code/class module resourcs:
    # $moddirpath: C:\sc\verb-dev
    $pltGci=[ordered]@{Path=$moddirpath ;Recurse=$true ;File = $true ; Exclude=$gciExcludes; ErrorAction="Stop" ; } ;
    # add: postfilter breakpoint filters
    $Psd1filelist = Get-ChildItem @pltGci | ?{($_.extension -match $rgxPsd1FileList -and $_.fullname -notmatch $rgxPsd1FileListExcl) -OR $_.fullname -match $rgxPsd1FileListDirs} | 
        ?{$_.fullname -notmatch $rgxPsd1BPExcl} ;
    # add: postfilter exclude exported help ref files
    #$Psd1filelist = Get-ChildItem @pltGci | ?{($_.extension -match $rgxPsd1FileList -and $_.fullname -notmatch $rgxPsd1FileListExcl) -OR $_.fullname -match $rgxPsd1FileListDirs} | 
    #    ?{ $_.fullname -notmatch $rgxPsd1BPExcl -OR $_.fullname -notmatch $rgxHelpExportedExcl } ;
    # add fullname variant for flatten copying resources
    $Psd1filelistFull =  $Psd1filelist | select -expand fullname ; 
    # and name only for the manifest FileList key
    # 4:44 PM 12/5/2023 select uniques, showing mults in the resulting array in psd1.filelist
    $Psd1filelist  = $Psd1filelist | select -expand name | select -unique ; 
    # export the list extensionless xml, to let it drop off of the Psd1filelist 
    $rgxPsd1FileListLine = '((#\s)*)FileList((\s)*)=((\s)*).*' ;
    if($Psd1filelist){
        $smsg = "`$Psd1filelist populated: export-cliXML:$($ModDirPath)\Psd1filelist" ; 
        # 10:18 AM 8/19/2024 xxml isn't either a stock alias, or a proper verb-alias (export == ep, not x); use the stock expanded call to avoid long term issues
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; $smsg = "" ; 
        $Psd1filelist | sort | export-clixml -path "$($ModDirPath)\Psd1filelist" ;
    
        # 2) then update the psd1.filelist prop into an array of the unpathed name's of each file found
        # looks like by #906, we're using $ModPsdPath - finished, rather than the temp file? 
        $smsg = "Updating the Psd1 FileList to with populated `$Psd1filelist..." ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;

        #$tf = $PsdNameTmp ;
        $tf = $ModPsdPath ; 
        # switch back to manual local updates
        $pltSCFE=[ordered]@{Path = $tf ; PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; }
        $psd1ExpMatch = $null ; 
        if($psd1ExpMatch = Get-ChildItem $tf | select-string -Pattern $rgxPsd1FileListLine ){
            # 2-step it, we're getting only $value[-1] through the pipeline
            # add | out-string to collapse object arrays
            $newContent = (Get-Content $tf) | Foreach-Object {
                $_ -replace $rgxPsd1FileListLine , ("FileList = " + "@('" + $($Psd1filelist -join "','") + "')")
            } | out-string ;
            # this writes to $PsdNameTmp
            $bRet = Set-ContentFixEncoding @pltSCFE -Value $newContent ;
            if(-not $bRet -AND -not $whatif){throw "Set-ContentFixEncoding $($tf)!" } ;
            $PassStatus += ";Set-Content:UPDATED";
        } else {
            $smsg = "UNABLE TO Regex out $($rgxPsd1FileListLine) from $($tf)`nFileList CAN'T BE UPDATED!" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
        } ;
    } else {
        # unpopulated, default it rem'd: # FileList = @()
        $smsg = "Updating the Psd1 FileList to with populated `$Psd1filelist..." ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;

        #$tf = $PsdNameTmp ;
        $tf = $ModPsdPath ; 
        # switch back to manual local updates
        $pltSCFE=[ordered]@{Path = $tf ; PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; }
        $psd1ExpMatch = $null ; 
        if($psd1ExpMatch = Get-ChildItem $tf | select-string -Pattern $rgxPsd1FileListLine ){
            # 2-step it, we're getting only $value[-1] through the pipeline
            # add | out-string to collapse object arrays
            $newContent = (Get-Content $tf) | Foreach-Object {
                $_ -replace $rgxPsd1FileListLine , ("# FileList = @()")
            } | out-string ;
            # this writes to $PsdNameTmp
            $bRet = Set-ContentFixEncoding @pltSCFE -Value $newContent ;
            if(-not $bRet -AND -not $whatif){throw "Set-ContentFixEncoding $($tf)!" } ;
            $PassStatus += ";Set-Content:UPDATED";
        } else {
            $smsg = "UNABLE TO Regex out $($rgxPsd1FileListLine) from $($tf)`nFileList CAN'T BE UPDATED!" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
        } ;
    }; 
    
    write-verbose "Get-ChildItem $($ModDirPath)\* -recur | where-object {$_.name -match `$rgxGuidModFiles}"
    #$rgxGuidModFiles = "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\.ps(d|m)1"
    $testfiles = Get-ChildItem "$($ModDirPath)\*" -recur | where-object {$_.name -match $rgxGuidModFiles} ; 
    if($testfiles){
        $smsg= "(Purging left-over test files...)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $bRet = remove-ItemRetry -Path $testfiles.fullname -showdebug:$($showdebug) -whatif:$($whatif) -GracefulFail  ;
        if (!$bRet) {
            #throw "FAILURE" ; EXIT ; 
            $smsg = "(failed to remove testfiles:`n$($testfiles.fullname)`nNON-IMPACTFUL)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ;  
    } ; 

    $smsg= "Signing appropriate files..." ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

    if($Merge){
        # 1:38 PM 12/26/2019#251 filter public|internal|classes include subdirs - don't sign them (if including/dyn-including causes 'Executable script code found in signature block.' errors
        write-verbose "(MONOLITH module:collecting non-include sign files)" ;
        $files = Get-ChildItem "$($ModDirPath)\*" -recur |Where-Object{$_.extension -match $rgxSignFiles} | ?{$_.fullname -notmatch $rgxIncludeDirs} ;
    } else {
        write-verbose "(DYN module: collecting *all* sign files)" ;
        $files = Get-ChildItem "$($ModDirPath)\*" -recur |Where-Object{$_.extension -match $rgxSignFiles}  ;
    } ;
    if($files){
        $pltSignFile=[ordered]@{
            file=$files.fullname ;
            ErrorAction="Stop" ;
            #showdebug=$($showdebug);
            whatif=$($whatif);
        } ;
        $smsg= "set-AuthenticodeSignatureTDO w`n$(($pltSignFile|out-string).trim())" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        # dbg, temp, forceup the proper _func for signing
        if( ((get-date ).Date -match '8/28/2024') -AND (-not (gcm set-AuthenticodeSignatureTDO |?{$_.module -eq $null -AND $Source -eq $null } ) ) ){
            write-warning "DBG:Invalid source found for set-AuthenticodeSignatureTDO, forcing fresh ipmo -fo -verb" ;  
            C:\usr\work\ps\Scripts\set-AuthenticodeSignatureTDO_func.ps1 | ipmo -fo -verb ; 
        } ; 
        TRY {
            set-AuthenticodeSignatureTDO @pltSignFile ;
        # 4:34 PM 8/26/2024 catch isn't catching anything, upgrade the block
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $PassStatus += ";ERROR";
            Break ; 
        } ; 
    } else {
        $smsg= "(no matching signable files)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;

    $smsg= "Removing existing profile $($ModuleName) content..." ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    
    $pltUMF=[ordered]@{
        ModuleName = $ModuleName ;
        #ErrorAction="Stop" ;
        Verbose = $($VerbosePreference -eq 'Continue') ; 
        whatif=$($whatif);
    } ;
    $smsg= "Uninstall-ModuleForce w`n$(($pltUMF|out-string).trim())" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    $bRet = Uninstall-ModuleForce @pltUMF ;
    #$passtatus string returned, check it        
    #if($sRet.split(';') -contains "uninstall-module:ERRO"){
    # ;uninstall-module:ERROR
    if($sRet){
        if([array]$sRet.split(';').trim() -contains 'uninstall-module:ERROR'){
         # or, work with raw ;-delim'd string:
        #if($sret.indexof('uninstall-module:ERROR')){
            $smsg = "Uninstall-ModuleForce:uninstall-module:ERRO!"  ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            throw $smsg ;
        } ; 
    } else { 
        $smsg = "(no `$sRet returned on call)" ; 
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    } ; 

    $smsg= "Copying module to profile (net of .git & .vscode dirs, and backed up content)..." ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    
    # move the constants up top, they're used for psd1.FileList population discovery as well (up around #965)
    
    #$from="$($ModDirPath)" ;
    $from = "$(join-path -path $moddirpath.fullname -childpath $ModuleName)\" ; 
    #$to = "$([Environment]::GetFolderPath("MyDocuments"))\WindowsPowerShell\Modules\$($ModuleName)" ;
    $to = "$([Environment]::GetFolderPath("MyDocuments"))\WindowsPowerShell\Modules\$($ModuleName)\$($ModuleName)" ;

    # below is original copy-all gci
    #$pltGci=[ordered]@{Path=$from ;Recurse=$true ;Exclude=$gciExcludes; ErrorAction="Stop" ; } ;
    $pltGci=[ordered]@{Path=$from ;Recurse=$false ;Exclude=$gciExcludes; ErrorAction="Stop" ; } ;
    # explicitly only go after the common module component, by type, via -include -
    #issue is -include causes it to collect only leaf files, doesn't include dir
    #creation, and if no pre-exist on the dir, causes a hard error on copy attempt.
    # 2:34 PM 3/15/2020 reset to copy all, and then post-purge non-$ModExtIncl

    # use a retry
    $Exit = 0 ;
    Do {
        Try {
            # below is original copy-all gci
            #Get-ChildItem @pltGci | Where-Object { $excludeMatch -eq $null -or $_.FullName.Replace($from, '') -notmatch $excludeMatchRegEx} | Copy-Item -Destination {  if ($_.PSIsContainer) { Join-Path $to $_.Parent.FullName.Substring($from.length) }   else { Join-Path $to $_.FullName.Substring($from.length) }    } -Force -Exclude $gciExcludes -whatif:$($whatif) ;
            # two stage it anyway
            $srcFiles = Get-ChildItem @pltGci | Where-Object { $excludeMatch -eq $null -OR $_.FullName.Replace($from, '') -notmatch $excludeMatchRegEx} ;
            $smsg = "`$srcFiles:post-filter out:`n$($rgxSrcFilesPostExcl)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
            #$srcFiles = $srcFiles | ?{$_.fullname -notmatch $rgxSrcFilesPostExcl} ; 
            $srcFiles = $srcFiles | ?{$_.fullname -notmatch $rgxSrcFilesPostExcl -AND -not($_.PsIsContainer)} ; 

            $smsg = "Discovered mod-copy files (`$srcFiles.fullname):w`n$(($srcFiles.fullname|out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success

            if(-not(test-path $to)){  
                $smsg = "Non-Pre-existing:`$to:$($to)" ; 
                $smsg +="`nPre-creating before copy..." ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                # capture the output, keep it from spamming the pipeline
                if($omsg = mkdir -path $to -whatif:$($whatif) -verbose){
                    $smsg = "$(($omsg | ft -a Mode,LastWriteTime,Length,Name|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ; 
            } else { 
                $smsg = "(`$to build output dir is confirmed pre-existing)" ;
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            } ; 

            if($Merge){
                $smsg = "-Merge:exclude `$MergeBuildExcl $($MergeBuildExcl) files from temp build copy" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                $srcFiles = $srcFiles | ?{$_.fullname -notmatch $MergeBuildExcl} ; 
            } ; 
            $srcFiles | Copy-Item -Destination {
                    if ($_.PSIsContainer) {
                        Join-Path $to $_.Parent.FullName.Substring($from.length)
                    }   else {
                        Join-Path $to $_.FullName.Substring($from.length)
                    }
                } -Force -Exclude $gciExcludes -whatif:$($whatif) ;
            <# leaf copies fail hard, when gci -include, due to returns being solely leaf files, no dirs, so the dirs don't get pre-created, and cause 'not found' copy fails
            # 2-stage and pull out non-target ext's
            $srcFiles = Get-ChildItem @pltGci | Where-Object { $excludeMatch -eq $null -or $_.FullName.Replace($from, '') -notmatch $excludeMatchRegEx}
            # need the dirs before the files, to ensure they're pre-created (avoids errors)
            $srcFiles = $srcFiles | sort PSIsContainer,Parent -desc
            $srcFiles | Copy-Item -Destination {  if ($_.PSIsContainer) { Join-Path $to $_.Parent.FullName.Substring($from.length) }   else { Join-Path $to $_.FullName.Substring($from.length) }    } -Force -Exclude $gciExcludes -whatif:$($whatif) ;
            #>
            $Exit = $Retries ;
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $PassStatus += ";ERROR";
            Break ; 
        } ; 
    } Until ($Exit -eq $Retries) ;

    # if we've run a copy all, we need to loop back and pull the items that *arent* ext -match $rgxModExtIncl
    # $to = "$([Environment]::GetFolderPath("MyDocuments"))\WindowsPowerShell\Modules\$($ModuleName)" ;
    #$bannedFiles = get-childitem -path $to -recurse |?{$_.extension -notmatch $rgxModExtIncl -AND !$_.PSIsContainer} ;
    # post filter the new licenses dir out (they're req extensionless files)
    #$bannedFiles = get-childitem -path $to -recurse |?{$_.extension -notmatch $rgxModExtIncl -AND !$_.PSIsContainer} | ?{$_.fullname -notmatch $rgxLicFileFilter}
    #$rgxInclOutLicFileName = '^LICENSE' ; 
    $bannedFiles = get-childitem -path $to -recurse |?{$_.extension -notmatch $rgxModExtIncl -AND !$_.PSIsContainer} | 
        ?{$_.fullname -notmatch $rgxLicFileFilter} |?{$_.name -notmatch $rgxInclOutLicFileName} ; 
    # Remove-Item -Path -Filter -Include -Exclude -Recurse -Force -Credential -WhatIf
    $pltRItm = [ordered]@{
        path=$bannedFiles.fullname ;
        erroraction = 'STOP' ; 
        verbose = $true ;  # add verbose
        whatif=$($whatif) ;
    } ;
    if($bannedFiles){
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Creating Remove-Item w `n$(($pltRItm|out-string).trim())" ;
        $error.clear() ;
        TRY {
            Remove-Item @pltRItm ;
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $PassStatus += ";ERROR";
            Break ; 
        } ; 
    } ;

    # 3:51 PM 10/11/2023 remove empty sub folders
    $smsg = "Recursively remove empty subdirs below $($to)..." ; 
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
    Do {
        write-host -nonewline "." ; 
        if($mtdirs = get-FolderEmpty -folder $to -recurse ){
            $mtdirs | remove-item -ea 0 -verbose; 
        } ; 
    } Until (-not(get-FolderEmpty -folder $to -recurse )) ;

    # 10:58 AM 10/11/2023: issue $Psd1filelistFull is pathed into the source $moddirpath, not the $to path.
    # so we need to loop the ($Psd1filelist  = $Psd1filelist | select -expand name) ; 
    # locate each file in the local $to tree, store it's current path and move the set to root
    <# VERBOSE: Loading module from path 'C:\sc\verb-dev\verb-dev\VERB-dev.psm1'.
    WARNING: 13:52:18:*****
    Failed processing . 
    Error Message: The specified FileList entry 'Quick-Start-Installation-and-Example.md' in the module manifest 'C:\sc\verb-dev\verb-dev\verb-dev.psd1' is invalid. Try again after updating this entry with valid values.
    Error Details: 
    test-modulemanifest : The specified FileList entry 'Quick-Start-Installation-and-Example.md' in the module manifest 'C:\sc\verb-dev\verb-dev\verb-dev.psd1' is invalid. Try again after updating this entry with valid values.
    At C:\sc\verb-dev\public\Step-ModuleVersionCalculated.ps1:361 char:27
    +             $TestReport = test-modulemanifest @pltXpsd1M ;
    +                           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : ObjectNotFound: (C:\sc\verb-dev\verb-dev\verb-dev.psd1:String) [Test-ModuleManifest], DirectoryNotFoundException
        + FullyQualifiedErrorId : Modules_InvalidFilePathinModuleManifest,Microsoft.PowerShell.Commands.TestModuleManifestCommand
    -----
    The specified FileList entry 'Quick-Start-Installation-and-Example.md' in the module manifest 'C:\sc\verb-dev\verb-dev\verb-dev.psd1' is invalid. Try again after updating this entry with valid values.
    #>
    # 1:55 PM 10/12/2023 clearly, not only do the res files need to be in the verb-MOD\verb-MOD dir for build, but even for initial build. 
    # need to have the below do the flatten/copy not only into the temp $to dir, but to the source c:\sc\verb-MOD\verb-MOD dir, at the same time. But for the source dir, it's a copy vs move.
    # bottomline, the verb-mod\verb-mod needs to be a _fully functional_ version of the installed mod, at this stage.
    $smsg = "Move/Flatten Resource etc files into root of temp Build dir..." ; 
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
    #$rgxTargExcl = [regex]::escape("\$($ModuleName)\$($ModuleName)") ; 
    foreach($fl in $Psd1filelist){
        #if($ffile = gci -path "$($to)\$($fl)" -recurse){
        # there's now one in dev .\docs|resource|licenses dir, and one in the verb-mod\verb-mod, which can't be moved (it's the dest, should be overwritten by the other), exclude the existing
        if($ffile = get-childitem -path "$($to)\$($fl)" -recurse | ?{$_.fullname -notmatch $rgxTargExcl } ){
            TRY{
                # should be in the verb-dev\verb-dev, .psd1|.psm1 dir
                # have to pretest & pre-remove conflicts, or it throws an error (w -ea0 non-impactful, but fugly output)
                if(test-path (join-path -path (join-path -path $to -childpath $ModuleName) -ChildPath $ffile.name)){
                    $smsg = "pre-remove existing$((join-path -path (join-path -path $to -childpath $ModuleName) -ChildPath $ffile.name))" ;
                    if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    get-childitem -path (join-path -path (join-path -path $to -childpath $ModuleName) -ChildPath $ffile.name) | remove-item -force -verbose -ea CONTINUE ; 
                } ; 
                move-item -Path $ffile -Destination (join-path -path $to -childpath $ModuleName) -verbose:$($VerbosePreference -eq "Continue") ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $PassStatus += ";ERROR";
                CONTINUE ; 
            } ; 
        } else {
            $smsg = "Unable to locate a problematic temp mod dir $($to) COPY of $($fl)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
        } ;  
    } ; 
    # 12:06 PM 12/4/2023 this is now redundant; already completed during prior buffer from res/lic etc files to vdev\vdev
    # 1:23 PM 12/4/2023 put it back, CU\modname\modname is unpopulated now!

    # buffer to verb-mod\verb-mod on the source as well - psd1.filelist entries won't pass a test-modulemanifest if still in .\RESOURCE|LICENSES
    $smsg = "copy/Flatten Resource etc files into source root $($ModDirPath)\$($ModuleName) dir..." ; 
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
    # need to prefilter out verb-mod\verb-mod items from $Psd1filelistFull
    foreach($fl in ($Psd1filelistFull | ?{$_ -notmatch $rgxTargExcl })){
        TRY{
            # should be in the verb-dev\verb-dev, .psd1|.psm1 dir $($ModDirPath)\$($ModuleName)
            if($rfile = get-childitem -path (join-path -path (join-path -path $to -childpath $ModuleName) -ChildPath (split-path $fl -leaf)) -ea 0){
                $smsg = "(pre-remove existing$($rfile.fullname))" ; 
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                $rfile | remove-item -force -verbose -ea CONTINUE ; 
            } ; 
            COPY-item -Path $fl -Destination (join-path -path $ModDirPath -childpath $ModuleName) -force -verbose:$($VerbosePreference -eq "Continue") ;
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $PassStatus += ";ERROR";
            CONTINUE ; 
        } ; 
    } ; 
    #

    if(-not($whatif)){
        if($localMod=Get-Module -ListAvailable -Name $($ModPsmName.replace('.psm1',''))){

            # 2:04 PM 10/27/2023 splice in a test-modulemanifest *before* running publish module
            TRY {
                if($ModPsdPath = (get-childitem "$($modroot)\$($ModuleName)\$($ModuleName).psd1" -ea 0).FullName){
                } elseif ($ModPsdPath = Get-PSModuleFile -path $ModRoot -Extension .psd1){
                } else {
                    $smsg = "Unable to resolve manifest .psd1 path for module dir:$($modroot)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    throw $smsg
                    break ;
                } ;
                $smsg = "Resolved `$ModPsdPath:`n$($ModPsdPath)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                # $ModPsdPath

                # 2:42 PM 12/8/2023 do wone more confirm on the psd1.filelist to files copied into the target: as the publish-module is failing for verb-network on a missing filelist entry.
                # $ModPsdPath: C:\sc\verb-network\verb-network\verb-network.psd1
                if($psd1 = Import-PowerShellDataFile -Path $modpsdpath -ErrorAction STOP){
                    $smsg = "resolve-path the CUMods $($modulename).psd1 location" ; 
                    if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    $CUpsd1 = "$([Environment]::GetFolderPath("MyDocuments"))\WindowsPowerShell\Modules\$($ModuleName)\$($ModuleName)\$($modulename).psd1" ; 
                    $CUModTestPath = (split-path $CUpsd1) ;
                    foreach($fl in $psd1.filelist){
                        $smsg = "`n==Verifying CU:Mods\$($modulename)\$($modulename)\$($fl):" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                        if(test-path -path (join-path $CUModTestPath $fl )){
                            write-host -fore green "validated $($fl) is found in $((join-path $CUModTestPath $fl ))" ; 
                        } else {
                            $smsg = "FAILED TO LOCATE $($fl) AT EXPECTED:$((join-path $CUModTestPath $fl ))" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            #throw $smsg ;
                            # mebbe remediate instead of crashing?
                            #$f1 is a path string, build it from the sc\modname\modname\ dir orig, and copy it to the CUModTestPath
                            <#$ModPsdPath
                            C:\sc\verb-network\verb-network\verb-network.psd1
                            #>
                            # 4:12 PM 7/12/2024 fix path source typo (need path of, not the psd1.fullname)
                            $pltCI=[ordered]@{
                                path = (join-path -path (split-path $ModPsdPath) -childpath $fl -ea STOP) ;
                                destination = (join-path -path $CUModTestPath -childpath $fl -ea STOP) ; ; # fully leaf the dest
                                force = $true ;
                                erroraction = 'STOP' ;
                                verbose = $true ; # $($VerbosePreference -eq "Continue") ;
                                whatif = $($whatif) ;
                            } ;
                            $smsg = "RE-copy-item w`n$(($pltCI|out-string).trim())" ; 
                            $smsg += "`n--`$pltCI.path:`n$(($pltCI.path|out-string).trim())" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            # it's flat file coying, just single-line it verbose
                            
                            TRY{
                                copy-item @pltCI ;
                            } CATCH {
                                $ErrTrapd=$Error[0] ;
                                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            } ; 

                            $shMissingFileWarning = @"

# NOTE!: 

AN ERROR WAS THROWN ON A MISSING FILE FROM THE `$psd1.filelist, SPECIFICALLY:

$($pltCI.destination)

... and a RECOVERY RECOPY from source was undertaken. 

=> IF THE BUILD CONTINUES TO FAIL PUBLISH/INSTALL, DO THE FOLLOWING:

1. Reinstall _latest repo version_ of $($ModuleName) to -scope:CurrentUser
2. Explorer the installed version at:

    C:\Users\LOGON\Documents\WindowsPowerShell\Modules\$($ModuleName)\n.n.n

    ... and locate the $($ModuleName).psd1 & $($ModuleName).psm1, buffer to clipboard, 

3. Explorer:
    $(split-path $ModPsdPath)

    ... and paste the buffered .psd1 & .psm1 from the installed copy, into the dev version (resets the build set)

4. And then run a fresh pass at your:

      .\processbulk-NewModule.ps1 -Modules $($ModuleName)

The above *may* sort the error without further debugging (could reflect missing/incomplete/damaged content from prior build).

"@ ;       
                            $smsg = $shMissingFileWarning ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 

                        } ; 
                    } ; 
                } else { 
                    $smsg = "Unable to:Import-PowerShellDataFile -Path $($modpsdpath)!'" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    throw $smsg ;
                } ; 


                $smsg = "Running pre-Publish-Module .psd1 test:`nTest-ModuleManifest -path $($ModPsdPath)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if($psd1Profile = Test-ModuleManifest -path $ModPsdPath  -errorVariable ttmm_Err -WarningVariable ttmm_Wrn -InformationVariable ttmm_Inf){
                    if($ttmm_Err){
                        $smsg = "`nFOUND `$ttmm_Err: test-ModuleManifest HAD ERRORS!" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        foreach($errExcpt in $ttmm_Err.Exception){
                            switch -regex ($errExcpt){
                                "The\sspecified\sFileList\sentry\s'.*'\sin\sthe\smodule\smanifest\s'.*.psd1'\sis\sinvalid\." {
                                    $smsg = "`nPSD1 Manifest has FileList specification, with no matching file found in $($modroot)\$($ModuleName)\!" ;
                                    $smsg += "`nThe PSD MUST be edited or rolled back to # FileList = @()  spec, to properly build"
                                    $smsg += "`n(build update-NewModule will detect and re-add the FileList from scratch, fr files in \\(Docs|Licenses|Resource)\ or named (Resource|Licenses) (extensionless)" ;
                                    $smsg += "`n`n to find the last psd1/.psd1_ with the empty spec:" ; 
                                    $smsg += "`ngci C:\sc\$($ModuleName)\$($ModuleName)\*.psd1* | sort LastWriteTime |  sls -pattern `"#\sFileList\s=\s@\(\)`" | select -last 1; `n" ;  
                                    $smsg += "`n$($errExcpt)" ;
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                }
                                default {
                                    $smsg = "`nPSD1 MANIFEST UNDEFINED TESTING ERROR!" ;
                                    $smsg += "`nThe PSD MUST be edited or rolled back to a functional revision to properly build!"
                                    $smsg += "`n(build update-NewModule will detect and re-add the FileList from scratch, fr files in \\(Docs|Licenses|Resource)\ or named (Resource|Licenses) (extensionless)" ;
                                    $smsg += "`n$($errExcpt)" ;
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                }
                            } ;
                        } ;
                        # abort build here
                        BREAK ; 
                    } else {
                        $smsg = "(no `$ttmm_Err: test-ModuleManifest had no errors)" ;
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                    } ; 
                    # ...
                } else { write-warning "$((get-date).ToString('HH:mm:ss')):Unable to locate psd1:$($ModPsdPath)" } ;

                # check for failure of last command
                if($? ){
                    $smsg= "(Test-ModuleManifest:PASSED)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $PassStatus += ";ERROR";
                Break ; 
            } ; 

            <# check for an existing repo pkg that will conflict with the version of the local copy
            $localMod.version : 1.2.0
            $trepo.PublishLocation
            \\REPOSERVER\lync_fs\scripts\sc
            $tRepo.ScriptPublishLocation
            \\REPOSERVER\lync_fs\scripts\sc

            get-childitem "$($tRepo.ScriptPublishLocation)\verb-dev.1.2.0.nupkg"
                Directory: \\REPOSERVER\lync_fs\scripts\sc
            Mode                LastWriteTime         Length Name
            ----                -------------         ------ ----
            -a----       12/28/2019   9:27 AM         121100 verb-dev.1.2.0.nupkg
            #>
            # profile $localPsRepo
            $smsg= "(Profiling Repo: get-PSRepository -name $($localPSRepo)...)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            TRY {
                $tRepo = get-PSRepository -name $localPSRepo ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $PassStatus += ";ERROR";
                Break ; 
            } ; 

            if($tRepo){

                # #1212:throws error if repo.SourceLocation isn't testable (when vpn is down), test and throw prescriptive error
                if(-not (test-path -path $tRepo.PublishLocation)){
                    $smsg= "Failed: test-path -path `$tRepo.PublishLocation: $($tRepo.PublishLocation)" ;
                    $smsg += "Is Repo share accesisble (VPN online?)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    Break ; 
                } else {
                    $smsg = "(confirmed:`$tRepo.PublishLocation accessible)" ; 
                    if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                } ;  

                $rgxPsd1Version="ModuleVersion\s=\s'\d*\.\d*\.\d*((\.\d*)*)'" ;
                # move the psdv1Vers detect code to always - need it for installs, as install-module doesn't prioritize, just throws up.
                # another way to pull version & guid is with get-module command, -name [path-to.psd1]
                # moved $psd1Vers & $psd1guid upstream , need the material *before* signing files
                if($tExistingPkg=get-childitem "$($tRepo.ScriptPublishLocation)\$($ModuleName).$($localMod.version).nupkg" -ea 0){
                    if($psd1Vers -eq $localmod.Version.tostring().trim()){

                        $blkMsg=@"

CONFLICTING EXISTING PUBLISHED VERSION FOUND!:
$($tExistingPkg.fullname)!
"@ ;
                        $smsg= $blkMsg ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $smsg= "**DO YOU WANT TO *PRE-PURGE* THE ABOVE FILE,`nTO PERMIT PUBLICATION OF THE UPDATE?" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $bRet=Read-Host "Enter YYY to continue. Anything else will exit"
                        if ($bRet.ToUpper() -eq "YYY") {
                            $bRet = remove-ItemRetry -Path $tExistingPkg.fullname -showdebug:$($showdebug) -whatif:$($whatif) -GracefulFail  ;
                            if (!$bRet) {throw "FAILURE" ; Break ; } ;
                        } else {
                            $blkMsg=@"
"Alternatively, you need to specify a *new* .psd1 file version...
    -- currently: $($psd1Vers) --
...in the source psd1:
$($ModPsdPath)

And then re-run update-NewModule.
* NOW EXITING *
"@ ;
                            $smsg= $blkMsg ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $smsg = "Opening a copy of Psd1:`n$($ModPsdPath)`nfor editing" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                            #$editor = "notepad2.exe" ;
                            $editorArgs = "$($ModPsdPath)" ;
                            Invoke-Command -ScriptBlock { & $editor $editorArgs } ;
                            Break ;
                        } ;

                    } ;

                } ;
            } ;

            # added errvari - clearly doesn't Catch on publish fails, so post test; required version, to permit mult versions pre-reinstall
            $pltPublishModule=[ordered]@{
                Name=$($ModuleName) ;
                Repository=$($Repository) ;
                RequiredVersion=$($psd1Vers) ;
                Verbose=$true ;
                ErrorAction="Stop" ;
                errorVariable = 'pbmo_Err' ;
                whatif=$($whatif);
            } ;
            <# 12:20 PM 12/6/2023 vio: it echo'd: VERBOSE: Calling New-NuspecFile
                WARNING: Tag list exceeded 4000 characters and may not be accepted by some Nuget feeds.
                VERBOSE: Calling New-NugetPackage
            ... which per here:
            "Publish-Module creates an invalid nuspec file when a large number of functions 
                are exported in a powershell module. The problem is that down in 
                Publish-PSArtifactUtility, it brute forces all of the exported function names 
                into the tags. My particular case resulted in a tag field around 11000 
                characters, way over the 4000 limit. I am publishing to a self-hosted nuget 
                gallery, but it is based upon the current production branch." 

            -- PowerShell/PowerShellGetv2 on Mar 22, 2019 Add SkipAutomaticTags Parameter to Publish-Module #452 When using a generic NuGet Server there is a hard coded 4000 character limit. Publish… 
            -- edyoung commented May 22, 2019 Pass -SkipAutomaticTags as introduced in PowerShellGet 2.1.4
            #>
            # so we now need to chekk the function names as an array and if they're sizable, add -SkipAutomaticTags to the publish-module params:
            # guestimate by creating a dummy array of comma-quote delimited function names: 
            #$tagdemo = "'$((gci C:\sc\verb-io\public\*.ps1 | select -expand name ).replace('.ps1','') -join "','")'"
            # on vio that's only 2846chars, so clearly the tag add process is adding a lot of wrapper tags (html-style?). So we need to target a much lower threshold. 
            #$from = "$(join-path -path $moddirpath.fullname -childpath $ModuleName)\" ;
            #$pltGci=[ordered]@{Path=$from ;Recurse=$false ;Exclude=$gciExcludes; ErrorAction="Stop" ; } ;
            #$srcFiles = Get-ChildItem @pltGci | Where-Object { $excludeMatch -eq $null -OR $_.FullName.Replace($from, '') -notmatch $excludeMatchRegEx} ;
            #$srcFiles = $srcFiles | ?{$_.fullname -notmatch $rgxSrcFilesPostExcl -AND -not($_.PsIsContainer)} ; 

            # number of chars of raw function names as a comma-quote-delim'd string, beyond which publish-module gets the -SkipAutomaticTags param added (to suppress bug from nuget's attempt to force all func names in a module into the 4k char-limited tag array)J.
            #$iSkipAutomaticTagsThreshold = 2000 ;
            $tagdemo = "'$((get-childitem "$(join-path -path $moddirpath.fullname -childpath 'Public')\*.ps1" -ea 0 | select -expand name).replace('.ps1','') -join "','")'" ; 
            if($tagdemo.length -gt $iSkipAutomaticTagsThreshold){
                $smsg = "Large # of funcitons: array of function names char length ($$tagdemo.length) -gt `$iSkipAutomaticTagsThreshold:$($iSkipAutomaticTagsThreshold)" ; 
                $smsg += "`nAdding -SkipAutomaticTags param to Publish-Module call, to work around NuGit bug #344" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level PROMPT } 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success

                $pltPublishModule.add('SkipAutomaticTags',$true) ; 
            } ;
            #
            <# 1:43 PM 12/6/2023 publish-module produces a *garbage* errorvariable:
                $pbmo_Err
                    System error.
                 $pbmo_Err | fl *
                    System error.
                 $PBMO_ERR.gettype().fullname
                    System.Collections.ArrayList
                 $PBMO_ERR.gettype()
                    IsPublic IsSerial Name                                     BaseType
                    -------- -------- ----                                     --------
                    True     True     ArrayList                                System.Object
                 $pbmo_Err.Exception
                 [blank, no property]
                #-=-=-=-=-=-=-=-=
            => it doesn't even have an Exception, it's an array of strings
            So testing it doesn't do squat. Publish-Module gets through without TRY/Catch triggering, 
                There's aNuGet warning in the output:
                VERBOSE: Calling New-NuspecFile
                WARNING: Tag list exceeded 4000 characters and may not be accepted by some Nuget feeds.
                VERBOSE: Calling New-NugetPackage            
            which is *whining* and a product of a bug in NuGet. System error isn't enough info to decide to crash an entire build, esp where it's an innocuous whine from NuGet. 
            #>
            $smsg= "`nPublish-Module w`n$(($pltPublishModule|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            TRY {
                Publish-Module @pltPublishModule ;
                    if($pbmo_Err){
                        $smsg = "`nFOUND `$pbmo_Err: import-module HAD ERRORS! (no action, could be non-impacting)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        <# 
                        note: publish-module doesn't return a proper Error object, just a string array. So there's no normal .Exception to process or analyze.
                         and it appears on the tag bug warning, the error returned is nothing more than 'System error.'
                         you can't even -eq compare it, have to use -match: 
                        $pbmo_Err -match 'System error.'
                            System error.
                        #>
                        foreach($errExcpt in $pbmo_Err){
                            write-warning "===:$($errExcpt)" ; 
                            switch -regex ($errExcpt){
                                default {
                                    $smsg = "`nPublish-Module PBMO UNDEFINED ERROR!" ;
                                    $smsg += "`n$($errExcpt)" ;
                                    $smsg += "`n(But PublishModule doesn't bother to return a functional Error object with an Exception, so we can't trust/parse or act on it. Just echo)" ; 
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                }
                            } ;
                        } ;
                        # can't trust to interpret the return: 'System Error.' WTF is that? Just echo, don't break or throw 
                        # esp in context of this possibly being a procut of newget pushing all function names into the Tag array, and generating spurious errors if the list is -gt 4k!
                        #BREAK ;
                        #throw $smsg ;
                    } else {
                        $smsg = "(no `$pbmo_Err: Publish-Module had no errors)" ;
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                    } ;   
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $PassStatus += ";ERROR";
                Break ; 
            } ;              

            $smsg= "Waiting for:find-module -name $($ModuleName) -Repository $Repository ..." ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $1F=$false ;Do {if($1F){Sleep -s 5} ;  write-host "." -NoNewLine ; $1F=$true ; } Until ($tMod = find-module -name $($ModuleName) -Repository $Repository -EA 0) ;

            if($tMod){
                # issue with $tMod is it can come back with multiple versions. Sort Version take last
                if($tMod -is [system.array]){
                    $smsg = "find-module returned Array, taking highest Version..." ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $tMod = ($tMod | sort version)[-1] ;
                } ;
                TRY {
                    $tfiles = Get-ChildItem -Recurse -Path "$($env:userprofile)\Documents\WindowsPowerShell\Modules\$($ModuleName)\*.*" |Where-Object{ ! $_.PSIsContainer } ;
                    #$tfiles | remove-item @pltRemoveItem ;
                } CATCH {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $PassStatus += ";ERROR";
                    Break ; 
                } ; 

                $bRet = remove-ItemRetry -Path $tFiles -Recurse -showdebug:$($showdebug) -whatif:$($whatif) -GracefulFail ;
                if (!$bRet) {throw "FAILURE" ; Break ; } ;

                # ADD -AllowClobber, to permit install command overlap (otherwise it aborts the install-module attempt)
                # add RequiredVersion to fix: Unable to install, multiple modules matched 'VERB-dev'. Please specify an exact -Name and -RequiredVersion.
                # add errorvariable & eval:
                $pltInstallModule=[ordered]@{
                    Name=$($ModuleName) ;
                    Repository=$($Repository) ;
                    RequiredVersion=$($psd1Vers) ;
                    scope="CurrentUser" ;
                    force=$true ;
                    AllowClobber=$true ;
                    errorVariable = 'ismo_Err' ; 
                    ErrorAction="Stop" ;
                    whatif=$($whatif) ;
                } ;
                $smsg= "Install-Module w`n$(($pltInstallModule|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                TRY {
                    Install-Module @pltInstallModule;
                    if($ismo_Err){
                        $smsg = "`nFOUND `$ismo_Err: Install-Module HAD ERRORS!" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        foreach($errExcpt in $ismo_Err.Exception){
                            switch -regex ($errExcpt){
                                default {
                                    $smsg = "`ninstalled IPMO .PSM1  UNDEFINED ERROR!" ;
                                    $smsg += "`n$($errExcpt)" ;
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                }
                            } ;
                        } ;
                        # abort here
                        BREAK ; 
                    } else {
                        $smsg = "(no `$ismo_Err: Install-Module had no errors)" ;
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                    } ; 
                } CATCH {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $PassStatus += ";ERROR";
                    Break ; 
                } ; 

                # test import-module with ea, force (hard reload curr version) & verbose output
                # 11:45 am 12/4/2023:should update ipmo w -errorvariable
                $pltImportMod=[ordered]@{
                    Name=$pltInstallModule.Name ;
                    ErrorAction="Stop" ;
                    errorVariable = 'ipmo_Err' ; 
                    force = $true ;
                    verbose = $true ;
                } ;
                $smsg= "Testing Module:Import-Module w`n$(($pltImportMod|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                TRY {
                    Import-Module @pltImportMod ;
                    if($ipmo_Err){
                        $smsg = "`nFOUND `$ipmo_Err: import-module HAD ERRORS!" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        foreach($errExcpt in $ipmo_Err.Exception){
                            switch -regex ($errExcpt){
                                default {
                                    $smsg = "`nInstall-Module ISMO .PSM1  UNDEFINED ERROR!" ;
                                    $smsg += "`n$($errExcpt)" ;
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                }
                            } ;
                        } ;
                        # abort here
                        BREAK ; 
                    } else {
                        $smsg = "(no `$ipmo_Err: test-ModuleManifest had no errors)" ;
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                    } ; 
                } CATCH {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $PassStatus += ";ERROR";
                    Break ; 
                } ; 

                # finally, lets grab the .nukpg that was created on the repo, and cached it in the sc dir (for direct copying to stock other repos, home etc)
                #if($tNewPkg = get-childitem "$($tRepo.ScriptPublishLocation)\$($ModuleName).$($psd1Vers).nupkg" -ea 0){
                # revise: use $tMod.version instead of $psd1Vers
                # when publishing 4-digit n.n.n.n semvers, if revision (4th digit) is 0, the .nupkg gets only a 3-digit semvar string in the filename.
                # The returned $tMod.version reflects the string actually used in the .nupkg, and is what you use to find the .nupkg for caching, from the repo.
                $smsg = "Retrieving matching Repo .nupkg file:`ngci $($tRepo.ScriptPublishLocation)\$($ModuleName).$($tMod.version).nupkgl.." ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                if($tNewPkg = get-childitem "$($tRepo.ScriptPublishLocation)\$($ModuleName).$($tMod.version).nupkg" -ea 0){
                    $smsg= "Proper updated .nupkg file found:$($tNewPkg.name), copying to local Pkg directory." ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $pkgdir = join-path -path $ModDirPath -childpath "Package" ;
                    $pltNItm = [ordered]@{
                        path=$pkgdir ;
                        type="directory" ;
                        whatif=$($whatif) ;
                    } ;
                    $pltCItm = [ordered]@{
                        path=$tNewPkg.fullname ;
                        destination=$pkgdir ;
                        whatif=$($whatif) ;
                    } ;
                    if(!(test-path -path $pkgdir -ea 0)){
                        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Creating missing dir:New-Item w `n$(($pltNItm|out-string).trim())" ;
                        $error.clear() ;
                        TRY {
                            New-Item @pltNItm ;
                        } CATCH {
                            $ErrTrapd=$Error[0] ;
                            $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $PassStatus += ";ERROR";
                            Break ; 
                        } ; 
                    } ;
                    write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Copy-Item w`n$(($pltCItm|out-string).trim())" ;
                    $error.clear() ;
                    TRY {
                        copy-Item @pltCItm ;
                    } CATCH {
                        $ErrTrapd=$Error[0] ;
                        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $PassStatus += ";ERROR";
                        Break ; 
                    } ; 

                } else {
                    $smsg = "No Nupkg File Found To Cache Locally!" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                } ;

                # cleanout old pkg files prior to today and 2 gens old
                $pltRGens =[ordered]@{
                    Path = $pltCItm.destination ;
                    #Include =(($tNewPkg.split('.') | ?{$_ -notmatch '[0-9]+'} ) -join '*.') ;
                    Include = (( (split-path $tNewPkg.fullname -leaf).split('.') | ?{$_ -notmatch '[0-9]+'}) -join '*.') ;
                    Pattern = $null ; #'verb-\w*\.ps(m|d)1_\d{8}-\d{3,4}(A|P)M' ;
                    FilterOn = 'CreationTime' ;
                    Keep = 2 ;
                    KeepToday = $true ;
                    verbose=$true ;
                    whatif=$($whatif) ;
                } ;
                $smsg = "remove-UnneededFileVariants w`n$(($pltRGens|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                remove-UnneededFileVariants @pltRGens ; # fr verb-IO

                # should cleanup old test logs as well: C:\sc\verb-IO\Tests\ScriptAnalyzer-Results-20220314-1137AM.xml $pkgdir = join-path -path $ModDirPath -childpath "Package" ;
                # 2:35 PM 5/23/2022 still there: # get the Pester log accum's as well: C:\sc\verb-IO\Tests\ScriptAnalyzer-Results-20220512-1512PM.xml
                $pltRGens =[ordered]@{
                    # "$(join-path -path 'C:\sc\verb-IO\' -childpath "Tests")\*"
                    #Path = "$(join-path -path $ModDirPath -childpath 'Tests')\*" ;
                    # 2:47 PM 5/23/2022 r-ufv no now has an Iscontainer test on the param, drop the wildcard
                    Path = $(join-path -path $ModDirPath -childpath 'Tests') ;
                    #Include =(($tNewPkg.split('.') | ?{$_ -notmatch '[0-9]+'} ) -join '*.') ;
                    #Include = (( (split-path $tNewPkg.fullname -leaf).split('.') | ?{$_ -notmatch '[0-9]+'}) -join '*.') ;
                    Include = 'ScriptAnalyzer-Results-*.xml' ; 
                    Pattern = $null ; #'verb-\w*\.ps(m|d)1_\d{8}-\d{3,4}(A|P)M' ;
                    FilterOn = 'CreationTime' ;
                    Keep = 4 ;
                    KeepToday = $true ;
                    verbose=$true ;
                    whatif=$($whatif) ;
                } ;
                $smsg = "remove-UnneededFileVariants w`n$(($pltRGens|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                # 2:43 PM 5/23/2022 heh, seems I never put in the fire command. [facepalm]
                remove-UnneededFileVariants @pltRGens ; 

                # RUNTEST
                if($RunTest -AND (test-path $TestScriptPath)){
                    $smsg = "`-RunTest specified: Running Pester Test script:`n$($TestScriptPath)`n" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                    # suppress VerbosePreference:Continue, if set, during mod loads (VERY NOISEY)
                    if($VerbosePreference -eq "Continue"){
                        $VerbosePrefPrior = $VerbosePreference ;
                        $VerbosePreference = "SilentlyContinue" ;
                        $verbose = ($VerbosePreference -eq "Continue") ;
                    } ;

                    $sBnrS="`n#*------v RUNNING $($TestScriptPath): v------`n" ;
                    write-host -foregroundcolor white "$((get-date).ToString('HH:mm:ss')):$($sBnrS)" ;
                    pushd ;
                    cd $ModDirPath ;
                    $pltRunTest = [ordered]@{
                        Command=".\Tests\$(split-path $TestScriptPath -leaf)" ;verbose=$($verbosepreference -eq 'Continue') ;
                    } ;
                    #invoke-expression @pltRunTest;
                    .(".\Tests\$(split-path $TestScriptPath -leaf)")
                    popd ;
                    write-host -foregroundcolor white "$((get-date).ToString('HH:mm:ss')):$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;

                    # reenable VerbosePreference:Continue, if set, during mod loads
                    if($VerbosePrefPrior -eq "Continue"){
                        $VerbosePreference = $VerbosePrefPrior ;
                        $verbose = ($VerbosePreference -eq "Continue") ;
                    } ;

                } ;

                # 12:26 PM 8/29/2024 FOR cu, ON LYN-9C5CTV3 found module that doesn't gmo -list, but ipmos as a module, post unisntall, blow away entire CU\Modules\verb-XXX tree
                # POST REPORT
                $FinalReport=@"

---------------------------------------------------------------------------------
Processing completed: $($ModuleName) :: $($ModDirPath)
- Script is currently installed (from PsRep:$($localRepo) with scope:CurrentUser, under $($env:userdomain)\$($env:username) profile

- To update other scopes/accounts on same machine, or install on other machines:
    1. Uninstall current module copies:

        Uninstall-Module -Name $($ModuleName)) -AllVersion -whatif ;

    2. Install the current version (or higher) from the Repo:$($Repository):

        install-Module -name $($ModuleName) -Repository $($Repository) -RequiredVersion $($psd1Vers) -scope currentuser -whatif ;

    3. Reimport the module with -force, to ensure the current installed verison is loaded:

        import-Module -name $($ModuleName) -force -verbose ;

#-=-=-Stacked list for the above: CURRENTUSER=-=-=-=-=-=
`$whatif=`$false ;  `$tScop = 'CurrentUser' ; `$tMod = '$($ModuleName)' ; `$tVer = '$($psd1Vers)' ;
if(`$IsCoreCLR){
    write-warning "WARNING YOU'RE INSTALLING INTO POWERSHELLCORE (7+)!`nTHE MODULE WILL GO INTO \DOCS\POWERSHELL\MODULES`n(vs \DOCS\WINDOWSPOWERSHELL\MODULES)!" ; 
    `$bRet=Read-Host "Enter YYY to continue. Anything else will exit"  ; 
    if (`$bRet.ToUpper() -eq "YYY") {} else {WRITE-WARNING "HALTING!" ; BREAK} ; 
} ; 
TRY {
    switch(`$tScop){
        'CurrentUser'{`$ModPath = "`$(split-path `$profile)\Modules\`$(`$tmod)" }
        'AllUsers' {`$ModPath = "`$(`$env:ProgramFiles)\WindowsPowerShell\Modules)\`$(`$tmod)"} 
    } ;
    if(`$Repository = (Get-PSRepository -Name `$localPSRepo -ea 'STOP').name){
        rmo -Name `$tmod -ea 0 ;
        Uninstall-Module -Name `$tmod -AllVersion -force -ea 0 -whatif:`$(`$whatif);
        gi -path `$ModPath -ea 0 |ri -Recurse -force -verbose  -whatif:`$(`$whatif) ;
        if(`$thisVers = find-module -name `$tmod -Repository `$Repository -RequiredVersion `$tVer){
            `$thisvers  | ft -a Name,Version,Repository ; 
            `$thisVers | install-Module -scope `$tScop -Force -AllowClobber -ea 'STOP' -whatif:`$(`$whatif) ;
        }else {
            throw "Unable to:find-module -name `$(`$tmod) -Repository `$(`$Repository) -RequiredVersion `$(`$tVer)" ; 
            break ; 
        } ; 
        rmo -Name `$tmod -force -ea 0 ;
        ipmo -name `$tmod -force -verbose -ea 'STOP'  ;
        gmo -name `$tmod | ? version -ne `$tVer | rmo -Force -Verbose ; 
        gmo -name `$tmod -list ;
    } else {
        throw "Unable to resolve ``$localPSRepo to a configured local PSRepository" ;
    } ;
} CATCH {
    `$ErrTrapd=`$Error[0] ;
    `$smsg = "`n`$((`$ErrTrapd | fl * -Force|out-string).trim())" ;
    write-warning "`$((get-date).ToString('HH:mm:ss')):`$(`$smsg)" ;
} ;
#-=-=-=-=-=-=-=-=
#-=-=-Stacked list for the above: ALLUSERS=-=-=-=-=-=
`$whatif=`$false ; `$tScop = 'AllUsers' ; `$tMod = '$($ModuleName)' ; `$tVer = '$($psd1Vers)' ;  
if(`$IsCoreCLR){
    write-warning "WARNING YOU'RE INSTALLING INTO POWERSHELLCORE (7+)!`nTHE MODULE WILL GO INTO \DOCS\POWERSHELL\MODULES`n(vs \DOCS\WINDOWSPOWERSHELL\MODULES)!" ; 
    `$bRet=Read-Host "Enter YYY to continue. Anything else will exit"  ; 
    if (`$bRet.ToUpper() -eq "YYY") {} else {WRITE-WARNING "HALTING!" ; BREAK} ; 
} ; 
TRY {
    switch(`$tScop){
        'CurrentUser'{`$ModPath = "`$(split-path `$profile)\Modules\`$(`$tmod)" }
        'AllUsers' {`$ModPath = "`$(`$env:ProgramFiles)\WindowsPowerShell\Modules)\`$(`$tmod)"} 
    } ;
    if(`$Repository = (Get-PSRepository -Name `$localPSRepo -ea 'STOP').name){
        rmo -Name `$tmod -ea 0 ;
        Uninstall-Module -Name `$tmod -AllVersion -force -ea 0 -whatif:`$(`$whatif);
        gi -path `$ModPath -ea 0 |ri -Recurse -force -verbose  -whatif:`$(`$whatif) ;
        if(`$thisVers = find-module -name `$tmod -Repository `$Repository -RequiredVersion `$tVer){
            `$thisvers  | ft -a Name,Version,Repository ; 
            `$thisVers | install-Module -scope `$tScop -Force -AllowClobber -ea 'STOP' -whatif:`$(`$whatif) ;
        }else {
            throw "Unable to:find-module -name `$(`$tmod) -Repository `$(`$Repository) -RequiredVersion `$(`$tVer)" ; 
            break ; 
        } ; 
        rmo -Name `$tmod -force -ea 0 ;
        ipmo -name `$tmod -force -verbose -ea 'STOP'  ;
        gmo -name `$tmod | ? version -ne `$tVer | rmo -Force -Verbose ; 
        gmo -name `$tmod -list ;
    } else {
        throw "Unable to resolve ``$localPSRepo to a configured local PSRepository" ;
    } ;
} CATCH {
    `$ErrTrapd=`$Error[0] ;
    `$smsg = "`n`$((`$ErrTrapd | fl * -Force|out-string).trim())" ;
    write-warning "`$((get-date).ToString('HH:mm:ss')):`$(`$smsg)" ;
} ;
#-=-=-=-=-=-=-=-=

- You may also want to run the configured Pester Tests of the new script:

        . $($ModDirPath)\Tests\$($ModuleName).tests.ps1

Full Processing Details can be found in:

$($logfile)

---------------------------------------------------------------------------------

"@ ;
                $smsg = $FinalReport ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            } else {
                $sMsg = "FAILED:Get-Module -ListAvailable -Name $($ModPsmName.replace('.psm1',''))"
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ;

        } else {
              $sMsg="FAILED:Get-Module -ListAvailable -Name $($ModPsmName.replace('.psm1',''))"
              if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ;
    } else {
        $smsg= "(-whatif: Skipping balance)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;

    #$smsg = "`n(Processing log can be found at:$(join-path -path $ModDirPath -childpath $logfile))" ;
    # fix typo
    $smsg = "`n(Most recent processing log can be found at:$(join-path -path $ModDirPath -childpath (split-path -leaf $logfile)))`n(perm copy stored at:$($logfile)" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    # copy the conversion log into the dev dir $ModDirPath
    if ($logging) {
        copy-item -path $logfile -dest $ModDirPath -whatif:$($whatif) ;
    } ;

    # this is probably where we should purge out any garbage brought in - splicing into exit, we just want these purged as deadwood, they aren't making it into the build anyway
    $smsg = "Run: Remove any non-pub garbage cp'd into c:\sc\$($ModuleName)\$($ModuleName) -ModuleName $($ModuleName)" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
    #$rgxModModPurges = "(main\.js|rebuild-module\.ps1$|New-Module-Create\.md$|buildBlind|\.help\.txt$|-ps1-BP\.xml$)" ; 
    if($killfiles = gci -path "c:\sc\$($ModuleName)\$($ModuleName)" | ?{$_.fullname -match $rgxModModPurges}){
        $killfiles | remove-item -force -verbose -whatif:$($whatif) ; 
    } ; 

    # this is where we should maintain accumulated old logs, post log close
    # $logfile =  'C:\sc\verb-Auth\update-NewModule-verb-auth-LOG-BATCH-EXEC-20210917-1504PM-log.txt'

    $pltRGens =[ordered]@{
        Path = $ModDirPath ;
        Include =(((split-path $logfile -leaf) -split '-LOG-BATCH-')[0],'-LOG-BATCH-','*','-log.txt' -join '') ;
        Pattern = $null ; #'verb-\w*\.ps(m|d)1_\d{8}-\d{3,4}(A|P)M' ;
        FilterOn = 'CreationTime' ;
        Keep = 2 ;
        KeepToday = $true ;
        verbose=$true ;
        whatif=$($whatif) ;
    } ;
    $smsg= "remove-UnneededFileVariants w`n$(($pltRGens|out-string).trim())" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    remove-UnneededFileVariants @pltRGens ;

    $smsg= "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

    #*======^ END SUB MAIN ^======
}

#*------^ update-NewModule.ps1 ^------


#*======^ END FUNCTIONS ^======

Export-ModuleMember -Function backup-ModuleBuild,check-PsLocalRepoRegistration,confirm-ModuleBuildSync,confirm-ModulePsd1Version,confirm-ModulePsm1Version,confirm-ModuleTestPs1Guid,convert-CommandLine2VSCDebugJson,convertFrom-EscapedPSText,Convert-HelpToHtmlFile,convert-ISEOpenSession,converto-VSCConfig,ConvertTo-Breakpoint,_extractBreakpoint,convertTo-EscapedPSText,ConvertTo-ModuleDynamicTDO,ConvertTo-ModuleMergedTDO,convertTo-UnwrappedPS,convertTo-WrappedPS,copy-ISELocalSourceToTab,copy-ISETabFileToLocal,export-CommentBasedHelpToFileTDO,export-FunctionsToFilesTDO,export-ISEBreakPoints,export-ISEBreakPointsALL,export-ISEOpenFiles,export-OpenNotepads,find-NounAliasesTDO,get-AliasAssignsAST,get-CodeProfileAST,get-CodeRiskProfileAST,Get-CommentBlocks,get-FunctionBlock,get-FunctionBlocks,get-HelpParsed,get-ISEBreakPoints,get-ISEOpenFilesExported,get-ModuleRevisedCommands,get-NounAliasTDO,get-OpenNotepadsExported,get-ProjectNameTDO,Get-PSBreakpointSorted,Get-PSModuleFile,get-StrictMode,Version,ToString,get-VariableAssignsAST,get-VerbAliasTDO,Get-VerbSynonymTDO,get-VersionInfo,import-ISEBreakPoints,import-ISEBreakPointsALL,import-ISEConsoleColors,import-ISEOpenFiles,import-OpenNotepads,Initialize-ModuleFingerprint,Get-PSModuleFile,Initialize-PSModuleDirectories,move-ISEBreakPoints,new-CBH,New-GitHubGist,pop-FunctionDev,push-FunctionDev,restore-ISEConsoleColors,restore-ModuleBuild,save-ISEConsoleColors,show-ISEOpenTab,show-ISEOpenTabPaths,show-Verbs,Split-CommandLine,Step-ModuleVersionCalculated,Get-PSModuleFile,Test-ModuleTMPFiles,test-VerbStandard,Uninstall-ModuleForce,update-NewModule,get-FolderEmpty,reset-ModulePublishingDirectory,populate-ModulePublishingDirectory -Alias *




# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUHfxqqx0e1zx1wsgvXbcaoPCA
# xwmgggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNDEyMjkxNzA3MzNaFw0zOTEyMzEyMzU5NTlaMBUxEzARBgNVBAMTClRvZGRT
# ZWxmSUkwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALqRVt7uNweTkZZ+16QG
# a+NnFYNRPPa8Bnm071ohGe27jNWKPVUbDfd0OY2sqCBQCEFVb5pqcIECRRnlhN5H
# +EEJmm2x9AU0uS7IHxHeUo8fkW4vm49adkat5gAoOZOwbuNntBOAJy9LCyNs4F1I
# KKphP3TyDwe8XqsEVwB2m9FPAgMBAAGjdjB0MBMGA1UdJQQMMAoGCCsGAQUFBwMD
# MF0GA1UdAQRWMFSAEL95r+Rh65kgqZl+tgchMuKhLjAsMSowKAYDVQQDEyFQb3dl
# clNoZWxsIExvY2FsIENlcnRpZmljYXRlIFJvb3SCEGwiXbeZNci7Rxiz/r43gVsw
# CQYFKw4DAh0FAAOBgQB6ECSnXHUs7/bCr6Z556K6IDJNWsccjcV89fHA/zKMX0w0
# 6NefCtxas/QHUA9mS87HRHLzKjFqweA3BnQ5lr5mPDlho8U90Nvtpj58G9I5SPUg
# CspNr5jEHOL5EdJFBIv3zI2jQ8TPbFGC0Cz72+4oYzSxWpftNX41MmEsZkMaADGC
# AWAwggFcAgEBMEAwLDEqMCgGA1UEAxMhUG93ZXJTaGVsbCBMb2NhbCBDZXJ0aWZp
# Y2F0ZSBSb290AhBaydK0VS5IhU1Hy6E1KUTpMAkGBSsOAwIaBQCgeDAYBgorBgEE
# AYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBToPkdO
# mp7uRFkmEN/6rt1LQFfxADANBgkqhkiG9w0BAQEFAASBgA8m9rPj3CNPc0aQneIA
# h4Wlx6blqjJJYoIywG3H8NAwH0R1OTi3xbijG70r0UPjnt5/JPqsx/aWfX3CnfOj
# BcYB+4I++j4R92IICYtwxdKfobZxpWYqeT4Q0E9/4KWeaRywUI6thLivC44cN6T5
# asUxppGibynyTt+57F52NoOr
# SIG # End signature block
