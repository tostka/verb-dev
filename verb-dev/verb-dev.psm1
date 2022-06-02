﻿# verb-dev.psm1


<#
.SYNOPSIS
VERB-dev - Development PS Module-related generic functions
.NOTES
Version     : 1.5.10
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
    $Psv2PublicExcl = @() ;
    $Psv2PrivateExcl = @() ;

#*======v FUNCTIONS v======




#*------v backup-ModuleBuild.ps1 v------
function backup-ModuleBuild {
    <#
    .SYNOPSIS
    backup-ModuleBuild - Backup current Module source fingerprint, Manifest (.psd1) & Module (.psm1) files to deep (c:\scBlind\[modulename]) backup, then creates a summary bufiles-yyyyMMdd-HHmmtt.xml file for the backup, in the deep backup directory.
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-25
    FileName    : backup-ModuleBuild
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 10:35 AM 5/26/2022 minor cleanup
    * 12:11 PM 5/25/2022 init
    .DESCRIPTION
    backup-ModuleBuild - Backup current Module source fingerprint, Manifest (.psd1) & Module (.psm1) files to deep (c:\scBlind\[modulename]) backup, then creates a summary bufiles-yyyyMMdd-HHmmtt.xml file for the backup, in the deep backup directory.

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


#*------v build-VSCConfig.ps1 v------
function build-VSCConfig {
    <#
    .SYNOPSIS
    build-VSCConfig - Process a sample ISE debugging command line, and convert it to a VSC launch.json 'configurations' entry
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
    * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:14 AM 12/30/2019 added CBH .INPUTS & .OUTPUTS, including specific material returned.
    * 5:51 PM 12/16/2019 added OneArgument param
    * 2:58 PM 12/15/2019 INIT
    .DESCRIPTION
    build-VSCConfig - Process a sample ISE debugging command line, and convert it to a VSC launch.json 'configurations' entry
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
    $bRet = build-VSCConfig -CommandLine $updatedContent -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
    if (!$bRet) {Continue } ;
    .LINK
    #>
    [CmdletBinding()]
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

#*------^ build-VSCConfig.ps1 ^------


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
    $(
    if($psv2PubLine){
        "$($psv2PubLine)"
    } else {
        "`$Psv2PublicExcl = @() ;"
    })
    $(if($psv2PrivLine){
        "$($psv2PrivLine)"
    } else {
        "`$Psv2PrivateExcl = @() ;"
    })

"@ ;

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
        $dynIncludeOpen = ($rawsourcelines | select-string -Pattern $rgxPurgeblockStart).linenumber ;
        $dynIncludeClose = ($rawsourcelines | select-string -Pattern $rgxPurgeBlockEnd).linenumber ;
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
    $(
    if($psv2PubLine){
        "$($psv2PubLine)"
    } else {
        "`$Psv2PublicExcl = @() ;"
    })
    $(if($psv2PrivLine){
        "$($psv2PrivLine)"
    } else {
        "`$Psv2PrivateExcl = @() ;"
    })

#*======v FUNCTIONS v======

"@ ;
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

    $tf = $PsdNameTmp ;
    # switch back to manual local updates
    $pltSCFE=[ordered]@{Path = $tf ; PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; } 
    if($psd1ExpMatch = Get-ChildItem $tf | select-string -Pattern $rgxFuncs2Export ){
        # 2-step it, we're getting only $value[-1] through the pipeline
        # add | out-string to collapse object arrays
        $newContent = (Get-Content $tf) | Foreach-Object {
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
    [Alias('eIseBp')]
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
            } else {
                write-warning "$($tScript): has *no* Breakpoints set!" ; 
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
    [Alias('eIseBpAll')]
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
    * 9:19 AM 5/20/2022 add: eIseOpen alias (using these a lot lately; w freq crashouts of ise, and need to recover all files open & BPs to quickly get back to function)
    * 12:12 PM 5/11/2022 init
    .DESCRIPTION
    export-ISEOpenFiles - Export a list of all currently open ISE tab files, to CU \WindowsPowershell\Scripts\ISESavedSession.psXML file
    Quick bulk dump, when ISE ineveitbly stops properly echo'ing variable values to terminal (and need to close and re-open all open files)
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    export-ISEOpenFiles -verbose -whatif
    Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('eIseOpen')]
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
            #$AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;
            $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
            $txmlf = join-path -path $CUScripts -ChildPath 'ISESavedSession.psXML' ;
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
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit :
    AddedWebsite:
    AddedTwitter:
    REVISIONS
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
    $ASTProfile = get-CodeProfileAST -File c:\pathto\script.ps1 -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
    Return the raw $ASTProfile object to the piepline (default behavior)
    .EXAMPLE
    $FunctionNames = (get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -Functions).functions.name ;
    Return the Functions within the specified script, and select the name properties of the functions object returned.
    .EXAMPLE
    $AliasAssignments = (get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -Aliases).Aliases.extent.text;
    Return the set/new-Alias commands from the specified script, selecting the full syntax of the command
    .EXAMPLE
    $WhatifLines = ((get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -GenericCommands).GenericCommands | ?{$_.extent -like '*whatif*' } | select -expand extent).text
    Return any GenericCommands from the specified script, that have whatif within the line
    .EXAMPLE
    $bRet = (get-CodeProfileAST -File c:\usr\work\exch\scripts\verb-dev.ps1 -All) ;
    $bRet.functions.name ;
    $bret.variables.extent.text
    $bret.aliases.extent.text

    Return ALL variant objects - Functions, Parameters, Variables, aliases, GenericCommands - from the specified script, and output the function names, variable names, and alias assignement commands
    .LINK
    #>
    [CmdletBinding()]
    [Alias('get-ScriptProfileAST')]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to script[-File path-to\script.ps1]")]
        [ValidateScript( {Test-Path $_})][ValidatePattern( "\.(ps1|psm1|txt)$")]
        [Alias('PSPath','File')]
        [system.io.fileinfo]$Path,
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
        $Verbose = ($VerbosePreference -eq "Continue") ;
        write-verbose "(convert path to gci)" ; 
        if ($Path.GetType().FullName -ne 'System.IO.FileInfo') {
            $Path = get-childitem -path $Path ;
        } ;
    } ;
    PROCESS {
        $sw = [Diagnostics.Stopwatch]::StartNew();

        write-verbose "$((get-date).ToString('HH:mm:ss')):(running AST parse...)" ; 
        New-Variable astTokens -Force ; New-Variable astErr -Force ; 
        #$AST = [System.Management.Automation.Language.Parser]::ParseFile($Path.fullname, [ref]$null, [ref]$Null ) ;
        $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$astTokens, [ref]$astErr)

        $objReturn = [ordered]@{ } ;

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
    } ;
    END {
        $sw.Stop() ;
        write-verbose ("Elapsed Time: {0:dd}d {0:hh}h {0:mm}m {0:ss}s {0:fff}ms" -f $sw.Elapsed) ; 
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
    ##Requires -Modules BuildHelpers,verb-IO, verb-logging, verb-Mods, verb-Text
    ##Requires -RunasAdministrator    
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


#*------v Get-PSModuleFile.ps1 v------
function Get-PSModuleFile {
    <#
    .SYNOPSIS
    Get-PSModuleFile.ps1 - Locate a module's manifest .psd1 file, given the root path of the moodule (direct lift from BuildHelpers:Get-PSModuleManifest, but I want a sep copy wo BH as a dependancy)
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
    * 10:48 AM 3/14/2022 updated CBH for missing extension param
    * 11:38 AM 10/15/2021 init version, added support for locating both .psd1 & .psm1, a new -Extension param to drive the choice, and a 'both' optional extension spec to retrieve both file type paths.
    * 1/1/2019 BuildHelpers most recent rev of the get-PsModuleManifest function.
    .DESCRIPTION
    Get-PSModuleFile.ps1 - Locate a module's Manifest (.psd1) or Module (.psm1) file, given the root path of the moodule (direct lift from BuildHelpers:Get-PSModuleManifest, but extended to do either psd1 or psm1)
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
    None. Returns no objects or output (.NET types)
    System.Boolean
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
    ##Requires -Modules BuildHelpers,verb-IO, verb-logging, verb-Mods, verb-Text
    ##Requires -RunasAdministrator    
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
    [Alias('iIseBp')]

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
    [Alias('iIseBpAll')]
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
    * 9:19 AM 5/20/2022 add: iIseOpen alias (using these a lot lately; w freq crashouts of ise, and need to recover all files open & BPs to quickly get back to function)
    * 12:12 PM 5/11/2022 init
    .DESCRIPTION
    import-ISEOpenFiles - Import/Re-Open a list of all ISE tab files, from CU Documents\WindowsPowershell\Scripts\ISESavedSession.psXML file
    Quick bulk dump, when ISE ineveitbly stops properly echo'ing variable values to terminal (and need to close and re-open all open files)
    .EXAMPLE
    import-ISEOpenFiles -verbose
    Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('iIseOpen')]
    PARAM() ;
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
            $txmlf = join-path -path $CUScripts -ChildPath 'ISESavedSession.psXML' ;
            #$allISEScripts = $psise.powershelltabs.files.fullpath ;
            $error.clear() ;
            TRY {
                $allISEScripts = import-Clixml -Path $txmlf ;
                $smsg = "Opening $($allISEScripts| measure | select -expand count) files" ; 
                write-verbose $smsg ; 
                if($allISEScripts){
                    foreach($ISES in $allISEScripts){
                        if($psise.powershelltabs.files.fullpath -contains $ISES){
                            write-host "($ISES) is already OPEN in Current ISE tab list (skipping)" ;
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
                }
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                write-warning $smsg ;
                Continue ; #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}

#*------^ import-ISEOpenFiles.ps1 ^------


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

            $pltXMO=@{Name=$null ; force=$true ; ErrorAction='STOP'} ;
            
            $pltGCI=[ordered]@{path=$moddir.FullName ;recurse=$true ; ErrorAction='STOP'} ;
            $smsg =  "gci w`n$(($pltGCI|out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            
            $moddirfiles = gci @pltGCI ;
            
            $Path = (Resolve-Path $Path).Path ; 
            $moddirfiles = gci -path $path -recur 
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

            if($psd1M){
                if($psd1M -is [system.array]){
                    throw "`$psd1M resolved to multiple .psm1 files in the module tree!" ; 
                } ; 
                # regardless of root dir name, the .psm1 name *is* the name of the module, use it for ipmo/rmo's
                $psd1MBasename = ((split-path $psd1M.fullname -leaf).replace('.psm1','')) ; 
                if($modname -ne $psd1MBasename){
                    $smsg = "Module has non-standard root-dir name`n$($moddir.fullname)"
                    $smsg += "`ncorrecting `$modname variable to use *actual* .psm1 basename:$($psd1MBasename)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    $modname = $psd1MBasename ; 
                } ; 
                $pltXMO.Name = $psd1M.fullname # load via full path to .psm1
                $smsg =  "import-module w`n$(($pltXMO|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                import-module @pltXMO ;
                $commandList = Get-Command -Module $modname ;
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
                throw "No module .psm1 file found in `$path:`n$(join-path -path $moddir.fullname -child "$modname.psm1")" ;
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
            else{ write-warning -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
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

            $pltOFile=[ordered]@{Encoding='utf8' ;FilePath=(join-path -path $moddir.fullname -childpath 'fingerprint') ;whatif=$($whatif) ;} ; 

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
    Author      : Jeff Hicks
    Website     : https://www.powershellgallery.com/packages/ISEScriptingGeek/3.4.1
    Twitter     : 
    CreatedDate : 2022-04-26
    FileName    : Initialize-PSModuleDirectories.ps1
    License     : 
    Copyright   : 
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Parser,Risk
    REVISIONS
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
        [ValidateScript( {Test-Path $_})]
        [string[]]$DefaultModDirs = @('Public','Internal','Classes','Tests','Docs','Docs\Cab','Docs\en-US','Docs\Markdown'),
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
        <#
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipeline = $True, HelpMessage = 'Path [-path c:\path-to\]')]
        [Alias('PsPath')]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [system.io.fileinfo[]]$Path,
        
        [Parameter(Position = 0, HelpMessage = "Enter the path of a PowerShell script")]
        [ValidateScript( {Test-Path $_})][ValidatePattern( "\.(ps1|psm1|txt)$")]
        [string]$Path = $(Read-Host "Enter the filename and path to a PowerShell script"),
        [Parameter(HelpMessage = "Report output directory")]
        [ValidateScript( {Test-Path $_})][Alias("fp", "out")]
        [string]$FilePath = "$env:userprofile\Documents\WindowsPowerShell"
        #>
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


#*------v parseHelp.ps1 v------
function parseHelp {
    <#
    .SYNOPSIS
    parseHelp - Parse Script CBH with get-help -full, return parseHelp obj & $hasExistingCBH boolean
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
    * 3:45 PM 4/14/2020 added pretest of $path extension, get-help only works with .ps1/.psm1 script files (misnamed temp files fail to parse)
    * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:11 AM 12/30/2019 parseHelp(): added CBH .INPUTS & .OUTPUTS, specifying returns hash of get-help parsed output, and presence of CBH in the file
    * 10:03 PM 12/2/201919 INIT
    .DESCRIPTION
    parseHelp - Parse Script and prepend new Comment-based-Help keyed to existing contents
    Note, if using temp files, you *can't* pull get-help on anything but script/module files, with the proper extension
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
    .EXAMPLE
    $bRet = parseHelp -Path $oSrc.fullname -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
    if($bRet.parseHelp){
        $parseHelp = $bRet.parseHelp
    } ;
    if($bRet.hasExistingCBH){
        $hasExistingCBH = $bRet.hasExistingCBH
    } ;
    .LINK
    #>
    # [ValidateScript({Test-Path $_})], [ValidateScript({Test-Path $_})]
    [CmdletBinding()]
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
    $notes = $null ; $notes = @{ } ;
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
                    #Continue ;
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
        } ;
        $objReturn.NotesHash = $notes ;
        $objReturn.RevisionsText = $revText ; 
    } ; 

    $objReturn | Write-Output ;
}

#*------^ parseHelp.ps1 ^------


#*------v process-NewModule.ps1 v------
function process-NewModule {
    <#
    .SYNOPSIS
    process-NewModule - Hybrid Monolithic/Dynam vers post-module conversion or component update: sign, publish to repo, and install back script
    .NOTES
    Version     : 1.1.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-02-24
    FileName    : process-NewModule.ps1
    License     : MIT License
    Copyright   : (c) 2021 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Module,Build,Development
    REVISIONS
    * 11:55 AM 6/2/2022 finally got through full build on verb-io; typo: pltCMPV -> pltCMBS; 
    * 3:42 PM 6/1/2022 add: -RequiredVersion picked up from psd1 post step ; defer into confirm-ModuleBuildSync ; echo process-newmodule splt before running; typo in $psd1vers ; cleaned old rems; 
    * 9:00 AM 5/31/2022 recoding for version enforcement (seeing final un-incremented): added -Version; cbh example tweaks ; subbed all Exit->Break; subbed write-warnings to 7pswlw ; twinned $psd1UpdatedVers into the nobuildversion section.
    * 4:34 PM 5/27/2022: update all Set-ContentFixEncoding & Add-ContentFixEncoding -values to pre |out-string to collapse arrays into single writes
    * 2:38 PM 5/24/2022: Time to resave process-NewModuleHybrid.ps1 => C:\sc\verb-dev\Public\process-NewModule.ps1
    * 2:54 PM 5/23/2022 add: verbose to pltUMD splat for update-metadata (psd1 enforce curr modvers); added missing testscript-targeting remove-UnneededFileVariants @pltRGens ;  
        got through full dbg/publish/install pass on vio merged, wo issues. Appears functional. 
    * 4:01 PM 5/20/2022 WIP, left off, got through the psdUpdatedVers reset - works, just before the uninstall-moduleforce(), need to complete debugging on that balance of material. 
    still debugging: add: buffer and post build compare/restore the $psd1UpdatedVers, to the psd1Version (fix odd bug that's causing rebuild to have the pre-update moduleversion); 
        $rgxOldFingerprint (for identifying backup-fileTDO fingerprint files); revert|backup-file -> restore|backup-fileTDO; add restore-fileTDO fingerprint, and psm1/psd1 (using the new func)
    * 4:00 PM 5/13/2022 ren merge-module() refs -> ConvertTo-ModuleDynamicTDO() ; ren unmerge-module() refs -> ConvertTo-ModuleDynamicTDO
    * 4:10 PM 5/12/2022 got through a full non -Dyn pass, to publish and ipmo -for. Need to dbg unmerged-module.psm1 interaction yet, but this *looks* like it could be ready to be the process-NewModule().
    * 8:45 AM 5/10/2022 attempt to merge over dotsource updates and logic, create a single hosting both flows
    * 2:59 PM 5/9/2022 back-reved process-NewModuleHybridDotsourced updates in
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
    process-NewModule - dyanmic include/dot-stourced post-module conversion or component update: sign - all files (this vers), publish to repo, and install back script
    Note: -Merge drivese logic to build Monolithic .psm1 (-Merge), vs Dynamic-include .psm1 (-not -Merge)
    I've hit an insurmoutable bug in psv2, when using psGet to install psv3+ modules into older legacy machines. Verb-IO *won't* properly parse and load my ConvertFrom-SourceTable function at all. So we need the ability to conditionally load module functions, skipping psv2-incompatibles when running that rev
    Preqeq Installs:
    Install-Module BuildHelpers -scope currentuser # buildhelpers metadata handling https://github.com/RamblingCookieMonster/BuildHelpers
    * To uninstall all but latest:
    #-=-=-=-=-=-=-=-=
    $modules = Get-Module -ListAvailable AzureRm* | Select-Object -ExpandProperty Name -Unique ;
    foreach ($module in $modules) {$Latest = Get-InstalledModule $module; Get-InstalledModule $module -AllVersions | ? {$_.Version -ne $Latest.Version} | Uninstall-Module ;} ;
    #-=-=-=-=-=-=-=-=
    .PARAMETER  ModuleName
    ModuleName[-ModuleName verb-AAD]
    .PARAMETER  ModDirPath
    ModDirPath[-ModDirPath C:\sc\verb-ADMS]
    .PARAMETER  Repository
    Target local Repo[-Repository lyncRepo
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
    Flag that indicates Module should be republished into local Repo (skips ConvertTo-ModuleDynamicTDO & Sign-file steps) [-Republish]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    PS> processbulk-NewModule.ps1 -mod verb-text,verb-io -verbose
    Example using the separate processbulk-NewModule.ps1 pre-procesesor to feed an array of mods through bulk processing, uses BuildEnvironment Step-ModuleVersion to increment the psd1 version, and specs -merge & -RunTest processing
    .EXAMPLE
    PS> processbulk-NewModule.ps1 -mod -Dynamic verb-io -verbose
    Example using the separate processbulk-NewModule.ps1 pre-procesesor to drive a Dyanmic include .psm1 build to feed one mod through bulk processing, uses BuildEnvironment Step-ModuleVersion to increment the psd1 version, and specs -merge & -RunTest processing
    .EXAMPLE
    PS> process-NewModule.ps1 -ModuleName "verb-AAD" -ModDirPath "C:\sc\verb-AAD" -Repository $localPSRepo  -Merge -showdebug -whatif ;
    Full Merge Build/Rebuild from components & Publish/Install/Test specified module, with debug messages, and whatif pass.
    .EXAMPLE
    PS> process-NewModule.ps1 -ModuleName "verb-AAD" -ModDirPath "C:\sc\verb-AAD" -Repository $localPSRepo  -showdebug -whatif ;
    Non-Merge pass: Re-sign specified module & Publish/Install/Test specified module, with debug messages, and whatif pass.
    .EXAMPLE
    # pre-remove installed module
    # re-increment the psd1 file ModuleVersion (unique new val req'd to publish)
    PS> process-NewModule.ps1 -ModuleName "verb-AAD" -ModDirPath "C:\sc\verb-AAD" -Repository $localPSRepo -Merge -Republish -showdebug -whatif ;
    Merge & Republish pass: Only Publish/Install/Test specified module, with debug messages, and whatif pass.
    .LINK
    #>

    ##Requires -Module verb-dev # added to verb-dev (recursive if present)
    #Requires -Modules BuildHelpers,verb-IO, verb-logging, verb-Mods, verb-Text
    [CmdletBinding()]
    PARAM(
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,HelpMessage="ModuleName[-ModuleName verb-AAD]")]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,
        [Parameter(Mandatory=$True,HelpMessage="ModDirPath[-ModDirPath C:\sc\verb-ADMS]")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [system.io.fileinfo]$ModDirPath,
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Target local Repo[-Repository lyncRepo]")]
        [ValidateNotNullOrEmpty()]
        [string]$Repository,
        [Parameter(HelpMessage="Flag that indicates Module should be Merged into a monoolithic .psm1 [-Merge]")]
        [switch] $Merge,
        [Parameter(HelpMessage="Flag that indicates Module should be republished into local Repo (skips ConvertTo-ModuleDynamicTDO & Sign-file steps) [-Republish]")]
        [switch] $Republish,
        [Parameter(HelpMessage="Flag that indicates Pester test script should be run, at end of processing [-RunTest]")]
        [switch] $RunTest,
        [Parameter(HelpMessage="Skip BuildInfo use (workaround for hangs in that module)[-NoBuildInfo]")]
        [switch] $NoBuildInfo,
        [Parameter(HelpMessage="Optional Explicit 3-digit RequiredVersion specification (as contrasts with using current Manifest .psd1 ModuleVersion value)[-Version 2.0.3]")]
        [version]$RequiredVersion,
        [Parameter(HelpMessage="Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
    # Get parameters this function was invoked with
    # Get parameters this function was invoked with
    $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
    write-verbose  "`$PSBoundParameters:`n$(($PSBoundParameters|out-string).trim())" ;
    $verbose = ($VerbosePreference -eq "Continue") ;

    if ($psISE){
            $ScriptDir = Split-Path -Path $psISE.CurrentFile.FullPath ;
            $ScriptBaseName = split-path -leaf $psise.currentfile.fullpath ;
            $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($psise.currentfile.fullpath) ;
            $PSScriptRoot = $ScriptDir ;
            if($PSScriptRoot -ne $ScriptDir){ write-warning "UNABLE TO UPDATE BLANK `$PSScriptRoot TO CURRENT `$ScriptDir!"} ;
            $PSCommandPath = $psise.currentfile.fullpath ;
            if($PSCommandPath -ne $psise.currentfile.fullpath){ write-warning "UNABLE TO UPDATE BLANK `$PSCommandPath TO CURRENT `$psise.currentfile.fullpath!"} ;
    } else {
        if($host.version.major -lt 3){
            $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent ;
            $PSCommandPath = $myInvocation.ScriptName ;
            $ScriptBaseName = (Split-Path -Leaf ((&{$myInvocation}).ScriptName))  ;
            $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($MyInvocation.InvocationName) ;
        } elseif($PSScriptRoot) {
            $ScriptDir = $PSScriptRoot ;
            if($PSCommandPath){
                $ScriptBaseName = split-path -leaf $PSCommandPath ;
                $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($PSCommandPath) ;
            } else {
                $PSCommandPath = $myInvocation.ScriptName ;
                $ScriptBaseName = (Split-Path -Leaf ((&{$myInvocation}).ScriptName))  ;
                $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($MyInvocation.InvocationName) ;
            } ;
        } else {
            if($MyInvocation.MyCommand.Path) {
                $PSCommandPath = $myInvocation.ScriptName ;
                $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent ;
                $ScriptBaseName = (Split-Path -Leaf ((&{$myInvocation}).ScriptName))  ;
                $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($MyInvocation.InvocationName) ;
            } else {throw "UNABLE TO POPULATE SCRIPT PATH, EVEN `$MyInvocation IS BLANK!" } ;
        } ;
    } ;
    if($showDebug){write-verbose -verbose:$true "`$ScriptDir:$($ScriptDir)`n`$ScriptBaseName:$($ScriptBaseName)`n`$ScriptNameNoExt:$($ScriptNameNoExt)`n`$PSScriptRoot:$($PSScriptRoot)`n`$PSCommandPath:$($PSCommandPath)" ; } ;


    $DomainWork = $tormeta.legacydomain ;
    #$ProgInterval= 500 ; # write-progress wait interval in ms

    $backInclDir = "c:\usr\work\exch\scripts\" ;
    $Retries = 4 ;
    $RetrySleep = 5 ;

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
                import-module -name $tModName -RequiredVersion $lVers.Version.tostring() -force -DisableNameChecking
            }   catch {
                 write-warning "*BROKEN INSTALLED MODULE*:$($tModName)`nBACK-LOADING DCOPY@ $($tModDFile)" ;import-module -name $tModDFile -force -DisableNameChecking
            } ;
        } elseif (test-path $tModFile) {
            write-warning "*NO* INSTALLED MODULE*:$($tModName)`nBACK-LOADING DCOPY@ $($tModDFile)" ;
            try {import-module -name $tModDFile -force -DisableNameChecking}
            catch {
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

    <# breaking runs
    [array]$reqMods = $null ; # force array, otherwise single first makes it a [string]
    $reqMods += "Test-TranscriptionSupported;Test-Transcribing;Stop-TranscriptLog;Start-IseTranscript;Start-TranscriptLog;get-ArchivePath;Archive-Log;Start-TranscriptLog;Write-Log;Start-Log".split(";") ;
    $reqMods+="Get-CommentBlocks;parseHelp;get-ScriptProfileAST;build-VSCConfig;ConvertTo-ModuleDynamicTDO;get-VersionInfo".split(";") ;
    # verb-IO reqMods
    $reqMods+="Set-FileContent;backup-File;Set-FileContent;backup-File;remove-ItemRetry".split(";") ;
    $reqMods = $reqMods | Select-Object -Unique ;

    if ( !(check-ReqMods $reqMods) ) { write-error "$((get-date).ToString("yyyyMMdd HH:mm:ss")):Missing function. EXITING." ; throw "FAILURE" ; }  ;
    #>
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
        } else {
            $pltSL.Path = $MyInvocation.MyCommand.Definition ;
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
        $smsg = "Failed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: $($ErrTrapd)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;
    
    $sBnr="#*======v $($ScriptBaseName):$($ModuleName) v======" ;
    $smsg= "$($sBnr)" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

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
    # expand to cover External & Private variant names as well
    $rgxIncludeDirs='\\(Public|Internal|External|Private|Classes)\\' ;
    $rgxOldFingerprint = 'fingerprint\._\d{8}-\d{4}(A|P)M' ; 

    $editor = "notepad2.exe" ;

    $error.clear() ;

    if($NoBuildInfo){
        # 9:34 AM 6/29/2020 for some reason, on join-object mod, Set-BuildEnvironment is going into the abyss, running git.exe log --format=%B -n 1
        # so use psd1version and manually increment, skipping BuildHelper mod use entirely
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):(-NoBuildInfo specified:Skipping use of buggy BuildHelpers module)" ;
        TRY {
            if($ModPsdPath = (gci "$($modroot)\$($ModuleName)\$($ModuleName).psd1" -ea 0).FullName){

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
            $psd1Profile = Test-ModuleManifest -path $ModPsdPath  ;
            # check for failure of last command
            if($? ){
                $smsg= "(Test-ModuleManifest:PASSED)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            }
        } CATCH {
            $PassStatus += ";ERROR";
            $smsg= "Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
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
        $PassStatus += ";ERROR";
        $smsg = "Import-PowerShellDataFile:Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
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
        $psd1Profile = Test-ModuleManifest -path $ModPsdPath  ;
        # check for failure of last command
        if($? ){
            $smsg= "(Test-ModuleManifest:PASSED)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        }
    } CATCH {
        $PassStatus += ";ERROR";
        $smsg = "Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        Break ;
    } ;


    $psd1Vers = $psd1Profile.Version.tostring() ;
    $psd1guid = $psd1Profile.Guid.tostring() ;
    if(test-path $TestScriptPath){
        # update the pester test script with guid: C:\sc\verb-AAD\Tests ; C:\sc\verb-AAD\Tests\verb-AAD.tests.ps1
        $smsg= "Checking sync of Psd1 module guid to the Pester Test Script: $($TestScriptPath)" ; ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

        <#
        $rgxTestScriptNOGuid = "Please\sPaste\shere\syour\smodule\sGuid\s-\sTest-ModuleManifest\s'<ModulePath>'\s\|\sSelect-Object\s-ExpandProperty\sGuid"
        #$rgxTestScriptGuid = '\.Guid((\s)*)\|((\s)*)Should((\s)*)-Be((\s)*)"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"'
        # cap grp
        $rgxTestScriptGuid = '\.Guid((\s)*)\|((\s)*)Should((\s)*)-Be((\s)*)"([0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12})"'
        $rgxGuid = "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}" ;
        # also maintain encoding (set-content defaults ascii)
        $tf = $TestScriptPath;
        $pltSCFE=[ordered]@{Path=$tf ; PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; }
        if($psd1ExpMatch = gci $tf |select-string -Pattern $rgxTestScriptNOGuid ){
            $newContent = (Get-Content $tf) | Foreach-Object {
                $_ -replace $rgxTestScriptNOGuid, "$($psd1guid)"
            } | out-string ;
            $bRet = Set-ContentFixEncoding @pltSCFE -Value $newContent ; 
            if(-not $bRet -AND -not $whatif){throw "Set-ContentFixEncoding $($tf)!" } ;
        } elseif($psd1ExpMatch = gci $tf |select-string -Pattern $rgxTestScriptGuid ){
            $testGuid = $psd1ExpMatch.matches[0].Groups[9].value.tostring() ;  ;
            if($testGuid -eq $psd1guid){
                $smsg = "(Guid  already updated to match)" ;
                if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level INFO } #Error|Warn|Debug
                else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            } else {
                $smsg = "In:$($tf)`nGuid present:($testGuid)`n*does not* properly match:$($psd1guid)`nFORCING MATCHING UPDATE!" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $newContent = (Get-Content $tf) | Foreach-Object {
                    $_ -replace $testGuid, "$($psd1guid)"
                } | out-string ;
                $bRet = Set-ContentFixEncoding @pltSCFE -Value $newContent ; 
                if(-not $bRet -AND -not $whatif){throw "Set-ContentFixEncoding $($tf)!" } ;
            } ;
        } else {
            $smsg = "UNABLE TO Regex out...`n$($rgxTestScriptNOGuid)`n...from $($tf)`nTestScript hasn't been UPDATED!" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ;
        #>
        <# 2:36 PM 6/1/2022 defer into confirm-ModuleBuildSync, further down)
        $pltCMTPG=[ordered]@{
            Path = $TestScriptPath ;
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
        } else {
            $smsg = "confirm-ModuleTestPs1Guid:FAIL! Aborting!" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            Break ;
        } ;
        #>

    } else {
        $smsg = "Unable to locate `$TestScriptPath:$($TestScriptPath)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level INfo } #Error|Warn|Debug
        else{ write-verbose -verbose:$true "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;

    <# ----------- defer psd1/psm1/pester-ps1 sync confirm into: confirm-ModuleBuildSync
    # Verify and re-sync psd version to the input newbuild incremented version (in case it got lost in the rebuild)
    # could use new confirm-ModulePsd1Version (rgx based, for .psd1_TMP file work), but below is safer/more-holistic solution - although update-modulemanifest would also write a new ModuleVersion into the psd1 as well
    # $psd1Vers came out of the test-modulemanifest above, use it here.
    if($psd1Vers -ne $psd1UpdatedVers){
        $smsg = "$($ModPsdPath):ModuleVersion`n*does not* properly match the Step-ModuleVersion modified ModuleVersion:$($psd1UpdatedVers)`nFORCING MATCHING UPDATE!" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $pltUMD=[ordered]@{
            Path = $ModPsdPath ;
            Value = $psd1UpdatedVers 
            whatif = $($whatif);    
            verbose = ($VerbosePreference -eq "Continue") ;
        } ; 
        $smsg = "Update-Metadata w`n$(($pltUMD|out-string).trim())" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        Update-Metadata @pltUMD ; 
        # pull back the updated psd1.ModuleVersion
        $smsg = "Pull back the updated Psd1.ModuleVersion..." ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        TRY{
            $psd1Vers = (Import-PowerShellDataFile -path $ModPsdPath).ModuleVersion.tostring() ;
        } CATCH {
            $PassStatus += ";ERROR";
            $smsg = "Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            bREAK ;
        } ;
    } ; 

    # sync Psd Version to psm1
    # regex approach - necc for psm1 version updates (lacks a ps cmdlet to parse)
    $rgxPsM1Version='Version((\s*)*):((\s*)*)(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?' ;
    $ModPsmPath = $ModPsdPath.replace('.psd1','.psm1')
    $psm1Profile = gci $ModPsmPath |select-string -Pattern $rgxPsM1Version ;
    $psm1Vers = $psm1Profile.matches[0].captures.groups[0].value.split(':')[1].trim() ;
    if($psm1Vers -ne $psd1Vers){
        $smsg = "Psd1<>Psm1 version mis-match ($($psd1Vers)<>$($Psm1Vers)):`nUpdating $($ModPsmPath) to *match*`n$($ModPsdPath)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $tf = $ModPsmPath;
        $pltSCFE=[ordered]@{Path=$tf ; PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; }
        $newContent =  (Get-Content $tf) | Foreach-Object {
            $_ -replace $psm1Profile.matches[0].captures.groups[0].value.tostring(), "Version     : $($psd1Vers)"
        } | out-string  ;
        $bRet = Set-ContentFixEncoding @pltSCFE -Value $newContent ; 
        if(-not $bRet -AND -not $whatif){throw "Set-ContentFixEncoding $($tf)!" } ;
    } else {
        $smsg = "(Psd1:Psm1 versions match)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;
    # -----------
    #>
    # shift to wrapper confirm-ModuleBuildSync() -NoTest, as only process-NewModule needs that step
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

    # Update the psd1 FunctionsToExport : (moved to ConvertTo-ModuleDynamicTDO, after the export-modulemember code)
    write-verbose "Get-ChildItem $($ModDirPath)\* -recur | where-object {$_.name -match `$rgxGuidModFiles}"
    $rgxGuidModFiles = "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\.ps(d|m)1"
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
            showdebug=$($showdebug);
            whatif=$($whatif);
        } ;
        $smsg= "Sign-file w`n$(($pltSignFile|out-string).trim())" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        TRY {
            sign-file @pltSignFile ;
        } CATCH {
            $PassStatus += ";ERROR";
            $smsg = "Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
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
    <# rem defer to new Uninstall-ModuleForce()
    if($PsGInstalled=Get-InstalledModule -name $($ModuleName) -AllVersions -ea 0 ){
        foreach($PsGMod in $PsGInstalled){
            $sBnrS="`n#*------v Uninstall PSGet Mod:$($PsGMod.name):v$($PsGMod.version) v------" ;
            $smsg= $sBnrS ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $pltRmv = [ordered]@{
                force=$true ;
                whatif=$($whatif) ;
            } ;
            $error.clear() ;
            TRY {
                if($showDebug){
                    $sMsg = "Uninstall-Script w`n$(($pltRmv|out-string).trim())" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
                get-module $PsGMod.installedlocation -listavailable |uninstall-module @pltRmv
            } CATCH {
                $ErrorTrapped = $Error[0] ;
                $PassStatus += ";ERROR";
                $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #Exit #Opts: STOP(debug)|EXIT(close)|Continue(move on in loop cycle)
            } ;
            $smsg="$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ;
    } ;
    # installed mods have PSGetModuleInfo.xml files
    
    # 12:20 PM 1/14/2020 #438: surviving conflicts locking install-module: need to check everywhere, loop the entire $env:psprofilepath list
    $modpaths = $env:PSModulePath.split(';') ;
    foreach($modpath in $modpaths){
        #"==$($modpath):"
        $smsg= "Checking: $($ModuleName) below: $($modpath)..." ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #$bRet = remove-ItemRetry -Path "$($env:userprofile)\Documents\WindowsPowerShell\Modules\$($ModuleName)\*.*" -Recurse -showdebug:$($showdebug) -whatif:$($whatif) ;
        $searchPath = join-path -path $modpath -ChildPath "$($ModuleName)\*.*" ;
        # 2:25 PM 4/21/2021 adding -GracefulFail to get past locked verb-dev cmdlets
        $bRet = remove-ItemRetry -Path $searchPath -Recurse -showdebug:$($showdebug) -whatif:$($whatif) -GracefulFail ;
        if (!$bRet) {throw "FAILURE" ; Break ; } ;
    } ;
    #>
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
    $ModExtIncl='*.cab','*.cat','*.cmd','*.config','*.cscfg','*.csdef','*.css','*.dll','*.dylib','*.gif','*.html','*.ico','*.jpg','*.js','*.json','*.map','*.Materialize','*.MaterialUI','*.md','*.pdb','*.php','*.png','*.ps1','*.ps1xml','*.psd1','*.psm1','*.rcs','*.reg','*.snippet','*.so','*.txt','*.vscode','*.wixproj','*.wxi','*.xaml','*.xml','*.yml','*.zip' ;
    $rgxModExtIncl='\.(cab|cat|cmd|config|cscfg|csdef|css|dll|dylib|gif|html|ico|jpg|js|json|map|Materialize|MaterialUI|md|pdb|php|png|ps1|ps1xml|psd1|psm1|rcs|reg|snippet|so|txt|vscode|wixproj|wxi|xaml|xml|yml|zip)' ;
    $from="$($ModDirPath)" ;
    $to = "$([Environment]::GetFolderPath("MyDocuments"))\WindowsPowerShell\Modules\$($ModuleName)" ;
    $exclude = @('main.js','rebuild-module.ps1') ; $excludeMatch = @('.git','.vscode') ;

    [regex] $excludeMatchRegEx = '(?i)' + (($excludeMatch |ForEach-Object {[regex]::escape($_)}) -join "|") + '' ;
    # below is original copy-all gci
    $pltGci=[ordered]@{Path=$from ;Recurse=$true ;Exclude=$exclude; ErrorAction="Stop" ; } ;
    # explicitly only go after the common module component, by type, via -include -
    #issue is -include causes it to collect only leaf files, doesn't include dir
    #creation, and if no pre-exist on the dir, causes a hard error on copy attempt.
    #$pltGci=[ordered]@{Path=$from ;Recurse=$true ;Exclude=$exclude; include =$ModExtIncl ; ErrorAction="Stop" ; } ;
    # 2:34 PM 3/15/2020 reset to copy all, and then post-purge non-$ModExtIncl

    # use a retry
    $Exit = 0 ;
    Do {
        Try {
            # below is original copy-all gci
            #Get-ChildItem @pltGci | Where-Object { $excludeMatch -eq $null -or $_.FullName.Replace($from, '') -notmatch $excludeMatchRegEx} | Copy-Item -Destination {  if ($_.PSIsContainer) { Join-Path $to $_.Parent.FullName.Substring($from.length) }   else { Join-Path $to $_.FullName.Substring($from.length) }    } -Force -Exclude $exclude -whatif:$($whatif) ;
            # two stage it anyway
            $srcFiles = Get-ChildItem @pltGci | Where-Object { $excludeMatch -eq $null -or $_.FullName.Replace($from, '') -notmatch $excludeMatchRegEx} ;
            $srcFiles | Copy-Item -Destination {
                    if ($_.PSIsContainer) {
                        Join-Path $to $_.Parent.FullName.Substring($from.length)
                    }   else {
                        Join-Path $to $_.FullName.Substring($from.length)
                    }
                } -Force -Exclude $exclude -whatif:$($whatif) ;
            <# leaf copies fail hard, when gci -include, due to returns being solely leaf files, no dirs, so the dirs don't get pre-created, and cause 'not found' copy fails
            # 2-stage and pull out non-target ext's
            $srcFiles = Get-ChildItem @pltGci | Where-Object { $excludeMatch -eq $null -or $_.FullName.Replace($from, '') -notmatch $excludeMatchRegEx}
            # need the dirs before the files, to ensure they're pre-created (avoids errors)
            $srcFiles = $srcFiles | sort PSIsContainer,Parent -desc
            $srcFiles | Copy-Item -Destination {  if ($_.PSIsContainer) { Join-Path $to $_.Parent.FullName.Substring($from.length) }   else { Join-Path $to $_.FullName.Substring($from.length) }    } -Force -Exclude $exclude -whatif:$($whatif) ;
            #>
            $Exit = $Retries ;
        } Catch {
            $ErrorTrapped=$Error[0] ;
            $PassStatus += ";ERROR";
            Start-Sleep -Seconds $RetrySleep ;
            # reconnect-exo/reconnect-ex2010
            $Exit ++ ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $smsg= "Failed to exec cmd because: $($Error[0])" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $smsg= "Try #: $($Exit)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            If ($Exit -eq $Retries) {
                $smsg= "Unable to exec cmd!" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Break ;
            } ;
        }  ;
    } Until ($Exit -eq $Retries) ;

    # if we've run a copy all, we need to loop back and pull the items that *arent* ext -match $rgxModExtIncl
    # $to = "$([Environment]::GetFolderPath("MyDocuments"))\WindowsPowerShell\Modules\$($ModuleName)" ;
    $bannedFiles = get-childitem -path $to -recurse |?{$_.extension -notmatch $rgxModExtIncl -AND !$_.PSIsContainer} ;
    # Remove-Item -Path -Filter -Include -Exclude -Recurse -Force -Credential -WhatIf
    $pltRItm = [ordered]@{
        path=$bannedFiles.fullname ;
        whatif=$($whatif) ;
    } ;
    if($bannedFiles){
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Creating Remove-Item w `n$(($pltRItm|out-string).trim())" ;
        $error.clear() ;
        TRY {
            Remove-Item @pltRItm ;
        } CATCH {
            $smsg = "Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $PassStatus += ";ERROR";
            Break #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
        } ;
    } ;


    if(!$whatif){
        if($localMod=Get-Module -ListAvailable -Name $($ModPsmName.replace('.psm1',''))){

            <# 9:59 AM 12/28/2019 check for an existing repo pkg that will conflict with the version of the local copy
            $localMod.version : 1.2.0
            $trepo.PublishLocation
            \\REPOSERVER\lync_fs\scripts\sc
            $tRepo.ScriptPublishLocation
            \\REPOSERVER\lync_fs\scripts\sc

            gci "$($tRepo.ScriptPublishLocation)\verb-dev.1.2.0.nupkg"
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
                $tRepo = get-PSRepository -name $localPSRepo
            } CATCH {
                $ErrorTrapped = $Error[0] ;
                $PassStatus += ";ERROR";
                $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Break ;
            } ;

            if($tRepo){
                $rgxPsd1Version="ModuleVersion\s=\s'\d*\.\d*\.\d*((\.\d*)*)'" ;
                # 12:47 PM 1/14/2020 move the psdv1Vers detect code to always - need it for installs, as install-module doesn't prioritize, just throws up.
                <# regx
                $psd1Profile = gci $ModPsdPath |select-string -Pattern $rgxPsd1Version ;
                $psd1Vers = $psd1Profile.matches.captures.groups[0].value.split('=').replace("'","")[1].trim() ;
                #$psd1Vers = $psd1Vers.split('=').replace("'","")[1].trim() ;
                #>
                # another way to pull version & guid is with get-module command, -name [path-to.psd1]
                # moved $psd1Vers & $psd1guid upstream , need the material *before* signing files
                if($tExistingPkg=gci "$($tRepo.ScriptPublishLocation)\$($ModuleName).$($localMod.version).nupkg" -ea 0){
                    # pull the source psd1 ModuleVersion line
                    #(gci C:\sc\verb-dev\verb-dev\verb-dev.psd1 |select-string -Pattern $rgxPsd1Version).matches.captures.groups[0].value ;
                    # "$($ModDirPath)\$($ModuleName)"
                    # if localvers being publ matches the $tExistingPkg version, twig
                    #if($psd1Vers.split('=').replace("'","")[1].trim() -eq $localmod.Version.tostring().trim()){
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

And then re-run process-NewModule.
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

            # added required version, to permit mult versions pre-reinstall
            $pltPublishModule=[ordered]@{
                Name=$($ModuleName) ;
                Repository=$($Repository) ;
                RequiredVersion=$($psd1Vers) ;
                Verbose=$true ;
                ErrorAction="Stop" ;
                whatif=$($whatif);
            } ;
            $smsg= "`nPublish-Module w`n$(($pltPublishModule|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            TRY {
                Publish-Module @pltPublishModule ;
            } CATCH {
                $ErrorTrapped = $Error[0] ;
                $PassStatus += ";ERROR";
                $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if($ErrorTrapped.Exception.Message -match 'The\sversion\smust\sexceed\sthe\scurrent\sversion'){
                    $smsg= "NOTE: If the psdVers ($($psd1Vers)) *is* > prior rev ($($localmod)) (e.g. publish-Module has bad SemanticVersion code),`nbump the rev a minor level`nStep-ModuleVersion -Path $($ModPsdPath) -by minor" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
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
                    $ErrorTrapped = $Error[0] ;
                    $PassStatus += ";ERROR";
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $bRetry=$true ;
                } ;

                $bRet = remove-ItemRetry -Path $tFiles -Recurse -showdebug:$($showdebug) -whatif:$($whatif) -GracefulFail ;
                if (!$bRet) {throw "FAILURE" ; Break ; } ;

                # ADD -AllowClobber, to permit install command overlap (otherwise it aborts the install-module attempt)
                # add RequiredVersion to fix: Unable to install, multiple modules matched 'VERB-dev'. Please specify an exact -Name and -RequiredVersion.
                $pltInstallModule=[ordered]@{
                    Name=$($ModuleName) ;
                    Repository=$($Repository) ;
                    RequiredVersion=$($psd1Vers) ;
                    scope="CurrentUser" ;
                    force=$true ;
                    AllowClobber=$true ;
                    ErrorAction="Stop" ;
                    whatif=$($whatif) ;
                } ;
                $smsg= "Install-Module w`n$(($pltInstallModule|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                TRY {
                    Install-Module @pltInstallModule;
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $PassStatus += ";ERROR";
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    Break ;
                } ;

                # test import-module with ea, force (hard reload curr version) & verbose output
                $pltImportMod=[ordered]@{
                    Name=$pltInstallModule.Name ;
                    ErrorAction="Stop" ;
                    force = $true ;
                    verbose = $true ;
                } ;
                $smsg= "Testing Module:Import-Module w`n$(($pltImportMod|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                TRY {
                    Import-Module @pltImportMod ;

                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $PassStatus += ";ERROR";
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    Break ;
                } ;

                # finally, lets grab the .nukpg that was created on the repo, and cached it in the sc dir (for direct copying to stock other repos, home etc)
                #if($tNewPkg = gci "$($tRepo.ScriptPublishLocation)\$($ModuleName).$($psd1Vers).nupkg" -ea 0){
                # revise: use $tMod.version instead of $psd1Vers
                # when publishing 4-digit n.n.n.n semvers, if revision (4th digit) is 0, the .nupkg gets only a 3-digit semvar string in the filename.
                # The returned $tMod.version reflects the string actually used in the .nupkg, and is what you use to find the .nupkg for caching, from the repo.
                $smsg = "Retrieving matching Repo .nupkg file:`ngci $($tRepo.ScriptPublishLocation)\$($ModuleName).$($tMod.version).nupkgl.." ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                if($tNewPkg = gci "$($tRepo.ScriptPublishLocation)\$($ModuleName).$($tMod.version).nupkg" -ea 0){
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
                            $smsg = "Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
                            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $PassStatus += ";ERROR";
                            Break #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
                        } ;
                    } ;
                    write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Copy-Item w`n$(($pltCItm|out-string).trim())" ;
                    $error.clear() ;
                    TRY {
                        copy-Item @pltCItm ;
                    } CATCH {
                        $smsg = "Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $PassStatus += ";ERROR";
                        Break #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
                    } ;

                } else {
                    # no nupkg file found to cache locally
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

                # POST REPORT
                $FinalReport=@"

---------------------------------------------------------------------------------
Processing completed: $($ModuleName) :: $($ModDirPath)
- Script is currently installed (from PsRep:$($localRepo) with scope:CurrentUser, under $($env:userdomain)\$($env:username) profile

- To update other scopes/accounts on same machine, or install on other machines:
    1. Uninstall current module copies:

        Uninstall-Module -Name $($ModuleName)) -AllVersion -whatif ;

    2. Install the current version (or higher) from the Repo:$($Repository):

        install-Module -name $($ModuleName) -Repository $($Repository) -MinimumVersion $($psd1Vers) -scope currentuser -whatif ;

    3. Reimport the module with -force, to ensure the current installed verison is loaded:

        import-Module -name $($ModuleName) -force -verbose ;

#-=-Stacked list: Unwrap to create a 1-liner for the above: CURRENTUSER =-=-=-=-=-=-=
`$whatif=`$false ; `$tMod = '$($ModuleName)' ; `$tVer = '$($psd1Vers)' ;  `$tScop = 'CurrentUser' ;
TRY {
Remove-Module -Name `$tmod -ea 0 ;
Uninstall-Module -Name `$tmod -AllVersion -whatif:`$(`$whatif) ;
install-Module -name `$tmod -Repository '$($Repository)' -MinimumVersion `$tVer -scope `$tScop -AllowClobber -whatif:`$(`$whatif) ;
import-Module -name `$tmod -force -verbose ;
} CATCH {
Write-Warning "Failed processing `$(`$_.Exception.ItemName). `nError Message: `$(`$_.Exception.Message)`nError Details: `$(`$_)" ; Break ;
} ;
#-=-=-=-=-=-=-=-=
#-=-Stacked list: Unwrap to create a 1-liner for the above: ALLUSERS =-=-=-=-=-=-=
`$whatif=`$false ; `$tMod = '$($ModuleName)' ; `$tVer = '$($psd1Vers)' ;  `$tScop = 'AllUsers' ;
TRY {
Remove-Module -Name `$tmod -ea 0 ;
Uninstall-Module -Name `$tmod -AllVersion -whatif:`$(`$whatif) ;
install-Module -name `$tmod -Repository '$($Repository)' -MinimumVersion `$tVer -scope `$tScop -AllowClobber -whatif:`$(`$whatif) ;
import-Module -name `$tmod -force -verbose ;
} CATCH {
Write-Warning "Failed processing `$(`$_.Exception.ItemName). `nError Message: `$(`$_.Exception.Message)`nError Details: `$(`$_)" ; Break ;
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

    $smsg = "`n(Processing log can be found at:$(join-path -path $ModDirPath -childpath $logfile))" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    # copy the conversion log into the dev dir $ModDirPath
    if ($logging) {
        copy-item -path $logfile -dest $ModDirPath -whatif:$($whatif) ;
    } ;

    # this is where we should maintain accumulated old logs, post log close
    # $logfile =  'C:\sc\verb-Auth\process-NewModule-verb-auth-LOG-BATCH-EXEC-20210917-1504PM-log.txt'

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

#*------^ process-NewModule.ps1 ^------


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


#*------v shift-ISEBreakPoints.ps1 v------
function shift-ISEBreakPoints {
    <#
    .SYNOPSIS
    shift-ISEBreakPoints - Offset current ISE tab's existing breakpoints by lines specified
    .NOTES
    Version     : 1.0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2020-08-25
    FileName    : shift-ISEBreakPoints
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 10:49 AM 8/25/2020 init, added to verb-dev module
    .DESCRIPTION
    shift-ISEBreakPoints - Offset current ISE tab's existing breakpoints by lines specified
    .PARAMETER PathDefault
    Default Path for export (when `$Script directory is unavailable)[-PathDefault c:\path-to\]
    .EXAMPLE
    shift-ISEBreakPoints -lines -4
    Shift all existing PSBreakpoints UP 4 lines
    .EXAMPLE
    shift-ISEBreakPoints -lines 5
    Shift all existing PSBreakpoints DOWN 5 lines
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('sIseBp')]
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

#*------^ shift-ISEBreakPoints.ps1 ^------


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
    #Requires -Modules BuildHelpers,verb-IO, verb-logging, verb-Mods, verb-Text
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

        if($whatif -AND -not $applyChange){
            $smsg = "You have specified -whatif, but have not also specified -applyChange" ; 
            $smsg += "`nThere is no reason to use -whatif without -applyChange."  ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            elseif(-not $Silent){ write-host -foregroundcolor yellow "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ; 
        
        # add filter for BOL or \s lead, drop the ##-rem'd lines
        $rgxRequireVersionLine = '(\s|^)#requires\s+-version\s' ;
        # also should check for nested recursion - ensure the Module isn't in any #requires\s-module
        # '((\s)*)#Requires\s+-Modules\s+.*,((\s)*)verb-exo' ; # module name
        # $Path will be c:\sc\verb-exo ; split-path c:\sc\verb-exo -leaf gets you the modulename back
        $ModName = split-path -Path $path -leaf ; 
        $rgxRequireModNested = "(\s|^)#Requires\s+-Modules\s+.*,((\s)*)$($ModName)" ;  # added: either BOL or after a space
        $ASTMatchThreshold = .8 ; # gcm must be w/in 80% of AST functions count, or this forces a 'Build' revision, to patch bugs in get-command -module xxx, where it fails to return full func/alias list from the module
        # increment bump used with -MinVersionIncrementBump
        #$MinVersionIncrementBump = 'Build' # moved to a full param, to permit explicit build spec, using step-ModuleVersionCalculated - adds the followup testing etc this provides, wo the fingerprinting

    } ;  # BEGIN-E
    PROCESS {
        $error.clear() ;
        TRY {
            $smsg = "profiling existing content..."
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            $Path = $moddir = (Resolve-Path $Path).Path ; 
            $moddirfiles = gci -path $path -recur 
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
            if ((split-path (split-path $psd1m) -leaf) -eq (gci $psd1m).basename){
                $ModuleName = split-path -leaf (split-path $psd1m) 
            } else {throw "`$ModuleName:Unable to match psd1.Basename $((gci $psd1m).basename) to psd1.parentfolder.name $(split-path (split-path $psd1m) -leaf)" }  ;
        
            # check for incidental ipmo crasher: multiple #require -versions, pretest (everything to that point is fine, just won't ipmo, and catch returns zippo)
            # no, revise, it's multi-versions of -vers, not mult instances. Has to be a single version spec across entire .psm1 (and $moddir of source files)
            if($PsFilesWVers = gci $moddir -include *.ps*1 -recur | sls -Pattern $rgxRequireVersionLine){
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
            if($PsFilesWNestedMod = gci $moddir -include *.ps*1 -recur | sls -Pattern $rgxRequireModNested){
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


            $pltXMO=@{Name=$null ; force=$true ; ErrorAction='STOP'; Verbose = $($VerbosePreference -eq 'Continue') } ;
            $pltXpsd1M=[ordered]@{path=$psd1M ; ErrorAction='STOP'; Verbose = $($VerbosePreference -eq 'Continue') } ; 

            $smsg = "Import-PowerShellDataFile w`n$(($pltXpsd1M|out-string).trim())" ;                         
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $PsdInfoPre = Import-PowerShellDataFile @pltXpsd1M ;
            $smsg = "test-ModuleManifest w`n$(($pltXpsd1M|out-string).trim())" ;                         
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $TestReport = test-modulemanifest @pltXpsd1M ;
            if($? ){ 
                $smsg= "(Test-ModuleManifest:PASSED)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $ModuleName = $TestReport.Name ; 
            } 
            
            # we need to precache the modules loaded - as rmo verb-io takes out both the build module and the installed, so we need a mechanism to put back the installed after testing
            $loadedMods = get-module ;
            $loadedInstalledMods = $loadedMods |?{ $_.path -match $rgxPSAllUsersScopeDyn -OR $_.path -match $rgxPSCurrUserScope -OR $_.path -match $rgxModsSystemScope}  ; 
            $loadedRevisedMods = $loadedMods |?{ $_.path -notmatch $rgxPSAllUsersScopeDyn -AND $_.path -notmatch $rgxPSCurrUserScope -ANd $_.path -notmatch $rgxModsSystemScope}  ; 

            switch ($Method) {

                'Fingerprint' {

                    $smsg = "Module:psd1M:calculating *FINGERPRINT* change Version Step" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                    #$fingerprintfile = get-childitem -path "$($ModDirPath)\fingerprint*" -ea 0 | select -expand fullname ; 
                    if($fingerprintfile = ($moddirfiles|?{$_.name -eq "fingerprint"}).FullName){
                        $oldfingerprint = Get-Content $fingerprintfile ; 
                
                        if($psm1){
                            $pltXMO.Name = $psm1 # ipmo via full path to .psm1
                            
                            $smsg = "import-module w`n$(($pltXMO|out-string).trim())" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            import-module @pltXMO ;

                            $commandList = Get-Command -Module $ModuleName # gcm doesn't support full path to module .psm1 
                            $rgxFuncDeclare = '(^|((\s)*))Function\s+[\w-_]+\s+((\(.*)*)\{' ;  # supports opt inline param syntax as well; and func names made from [A-Za-z0-9-_]chars
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
                            $tmpmodtarget = get-module |where-object{$_.path -eq $psm1} 
                            if($tmpmodtarget){ $tmpmodtarget | remove-module @pltXMO }
                            else {
                                $smsg = "Unable to isolate:" ; 
                                $smsg += "`nget-module |where-object{$_.path -eq $($psm1)}!" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level  WARN } #Error|Warn|Debug 
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 

                            } ; 

                            # here's where we should restore any missing $loadedInstalledMods, taken out with the build module by above rmo...
                            # post confirm instlmods still loaded:
                            $postpaths = (get-module |where-object { $_.path -match $rgxPSAllUsersScopeDyn -OR $_.path -match $rgxPSCurrUserScope -OR $_.path -match $rgxModsSystemScope}).path ; 
                            $loadedInstalledMods.path |foreach-object{
                                if($postpaths -contains  $_){
                                    $smsg = "($($_):still loaded)" 
                                    if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                                }else{
                                    $smsg = "ipmo missing installedmod:$($_)" ; 
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } 
                                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                    import-module $_ -fo -verb ;
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

                        $pltOFile=[ordered]@{Encoding='utf8' ;FilePath=(join-path -path $moddir -childpath 'fingerprint') ;whatif=$($whatif) ; Verbose = $($VerbosePreference -eq 'Continue') } ;
                        $smsg = "Writing fingerprint: Out-File w`n$(($pltOFile|out-string).trim())" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $fingerprint | out-file @pltOFile ; 
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

                    $LastChange = (Get-ChildItem $psd1M).LastWriteTime ; 
                    $ChangedFiles = ($moddirfiles | Where LastWriteTime -gt $LastChange).Count ; 
                    $PercentChange = 100 - ((($moddirfiles.Count - $ChangedFiles) / $moddirfiles.Count) * 100) ; 
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
  
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #-=-record a STATUSWARN=-=-=-=-=-=-=
            $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
            if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
            if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
            #-=-=-=-=-=-=-=-=
            Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
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
}

#*------^ Test-ModuleTMPFiles.ps1 ^------


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

            $modpaths = $env:PSModulePath.split(';') ;
            foreach($modpath in $modpaths){
                #"==$($modpath):"
                $smsg= "Checking: $($Mod) below: $($modpath)..." ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $searchPath = join-path -path $modpath -ChildPath "$($Mod)\*.*" ;
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


#*======^ END FUNCTIONS ^======

Export-ModuleMember -Function backup-ModuleBuild,build-VSCConfig,check-PsLocalRepoRegistration,confirm-ModuleBuildSync,confirm-ModulePsd1Version,confirm-ModulePsm1Version,confirm-ModuleTestPs1Guid,convert-CommandLine2VSCDebugJson,ConvertTo-ModuleDynamicTDO,ConvertTo-ModuleMergedTDO,export-ISEBreakPoints,export-ISEBreakPointsALL,export-ISEOpenFiles,get-AliasAssignsAST,get-CodeProfileAST,get-CodeRiskProfileAST,Get-CommentBlocks,get-FunctionBlock,get-FunctionBlocks,get-ModuleRevisedCommands,get-ProjectNameTDO,Get-PSModuleFile,get-VariableAssignsAST,get-VersionInfo,import-ISEBreakPoints,import-ISEBreakPointsALL,import-ISEConsoleColors,import-ISEOpenFiles,Initialize-ModuleFingerprint,Get-PSModuleFile,Initialize-PSModuleDirectories,new-CBH,New-GitHubGist,parseHelp,process-NewModule,restore-ISEConsoleColors,restore-ModuleBuild,save-ISEConsoleColors,shift-ISEBreakPoints,Split-CommandLine,Step-ModuleVersionCalculated,Get-PSModuleFile,Test-ModuleTMPFiles,Uninstall-ModuleForce -Alias *




# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVGjcBFcObo/8AZ+Yr5mgi1cz
# JuOgggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
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
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQbPV+Q
# g9KR8YO3nCG+pJIbduYtKTANBgkqhkiG9w0BAQEFAASBgJkpifubTih65xdutF39
# Qv1vQLaE1N+GnoZ/wmRjNNwYtb+G+bTgOvAxCNxj/oYv+ys2jzosTjvdunyfh46l
# caCwQC8rPlhgs78Ooou8lxcyvbRkbRuphwp3oxrDIfZed3ArFQHaKRP/XEuplNg2
# VqAPrcnpOgiXf8R9IeLIjdW+
# SIG # End signature block
