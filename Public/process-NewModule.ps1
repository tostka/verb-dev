#*------v process-NewModule.ps1 v------
function process-NewModule {
    <#
    .SYNOPSIS
    process-NewModule - post-module conversion or component update: sign, publish to repo, and install back script
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
    process-NewModule - post-module conversion or component update: sign, publish to repo, and install back script
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
    Flag that indicates Module should be Merged into a monoolithic .psm1 [-Merge]
    .PARAMETER RunTest
    Flag that indicates Pester test script should be run, at end of processing [-RunTest]
    .PARAMETER NoBuildInfo
    Skip BuildInfo use (workaround for hangs in that module)[-NoBuildInfo]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Republish
    Flag that indicates Module should be republished into local Repo (skips Merge-Module & Sign-file steps) [-Republish]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    processbulk-NewModule.ps1 -mod verb-text,verb-io -verbose
    Example using the separate processbulk-NewModule.ps1 pre-procesesor to feed an array of mods through bulk processing, uses BuildEnvironment Step-ModuleVersion to increment the psd1 version, and specs -merge & -RunTest processing
    .EXAMPLE
    process-NewModule.ps1 -ModuleName "verb-AAD" -ModDirPath "C:\sc\verb-AAD" -Repository $localPSRepo  -Merge -showdebug -whatif ;
    Full Merge Build/Rebuild from components & Publish/Install/Test specified module, with debug messages, and whatif pass.
    .EXAMPLE
    process-NewModule.ps1 -ModuleName "verb-AAD" -ModDirPath "C:\sc\verb-AAD" -Repository $localPSRepo  -showdebug -whatif ;
    Non-Merge pass: Re-sign specified module & Publish/Install/Test specified module, with debug messages, and whatif pass.
    .EXAMPLE
    # pre-remove installed module
    # re-increment the psd1 file ModuleVersion (unique new val req'd to publish)
    process-NewModule.ps1 -ModuleName "verb-AAD" -ModDirPath "C:\sc\verb-AAD" -Repository $localPSRepo -Merge -Republish -showdebug -whatif ;
    Merge & Republish pass: Only Publish/Install/Test specified module, with debug messages, and whatif pass.
    .LINK
    #>

    ##Requires -Version 3 # rem'd already in module
    ##Requires -Module verb-dev # added to verb-dev (recursive if present)
    #Requires -Modules BuildHelpers,verb-IO, verb-logging, verb-Mods, verb-Text
    [CmdletBinding()]
    PARAM(
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="ModuleName[-ModuleName verb-AAD]")]
        [ValidateNotNullOrEmpty()]$ModuleName,
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="ModDirPath[-ModDirPath C:\sc\verb-ADMS]")]
        [ValidateNotNullOrEmpty()]$ModDirPath,
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Target local Repo[-Repository lyncRepo]")]
        [ValidateNotNullOrEmpty()]$Repository,
        [Parameter(HelpMessage="Flag that indicates Module should be Merged into a monoolithic .psm1 [-Merge]")]
        [switch] $Merge,
        [Parameter(HelpMessage="Flag that indicates Module should be republished into local Repo (skips Merge-Module & Sign-file steps) [-Republish]")]
        [switch] $Republish,
        [Parameter(HelpMessage="Flag that indicates Pester test script should be run, at end of processing [-RunTest]")]
        [switch] $RunTest,
        [Parameter(HelpMessage="Skip BuildInfo use (workaround for hangs in that module)[-NoBuildInfo]")]
        [switch] $NoBuildInfo,
        [Parameter(HelpMessage="Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
    # Get parameters this function was invoked with
    #$PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
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
                        exit;
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
                exit;
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
        write-warning "$((get-date).ToString('HH:mm:ss')):RUNNING AS *UID* - $($env:userdomain)\$($env:username) - MUST BE RUN *SID*! EXITING!" ;
        EXIT ; 
    } ; 


    if($Merge -AND $Republish){
        write-host -foregroundcolor RED "$((get-date).ToString('HH:mm:ss')):*WARNING!*:-Merge *AND* -Republish specified! Please use one or the other, but *not* BOTH!" ; 
        Exit ; 
    } ; 

    if($env:USERDOMAIN -EQ $DomainWork){
        if("$($env:USERDOMAIN)\$($env:USERNAME)" -notmatch $rgxAcctWAdmn ){
            write-host -foregroundcolor RED "$((get-date).ToString('HH:mm:ss')):*WARNING*! THIS SCRIPT MUST BE RUN AS SID AT WORK`nREQUIRES *ADMIN* REPO PUBLISHING PERMS, `nWHICH UID LACKS ($($env:USERDOMAIN)\$($env:USERNAME))" ; 
            #popd ; 
            EXIT ; 
        } ; 
    } ; 

    <# breaking runs
    [array]$reqMods = $null ; # force array, otherwise single first makes it a [string]
    $reqMods += "Test-TranscriptionSupported;Test-Transcribing;Stop-TranscriptLog;Start-IseTranscript;Start-TranscriptLog;get-ArchivePath;Archive-Log;Start-TranscriptLog;Write-Log;Start-Log".split(";") ;
    $reqMods+="Get-CommentBlocks;parseHelp;get-ScriptProfileAST;build-VSCConfig;Merge-Module;get-VersionInfo".split(";") ; 
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
    <# prior code
    $logspec = start-Log -Path ($MyInvocation.MyCommand.Definition) -Tag $ModuleName -showdebug:$($showdebug) -whatif:$($whatif) ;
    if($logspec){
        $logging=$logspec.logging ;
        $logfile=$logspec.logfile ;
        $transcript=$logspec.transcript ;
    } else {throw "Unable to configure logging!" } ;
    #>
    $sBnr="#*======v $($ScriptBaseName):$($ModuleName) v======" ; 
    $smsg= "$($sBnr)" ;  
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

    $ModPsmName = "$($ModuleName).psm1" ;
    # C:\sc\verb-AAD\verb-AAD\verb-AAD.psd1
    $ModPsdPath = (gci "$($ModDirPath)\$($ModuleName)\$($ModuleName).psd1").FullName
    $PublicDirPath = "$($ModDirPath)\Public" ;
    $InternalDirPath = "$($ModDirPath)\Internal" ;
    # "C:\sc\verb-AAD" ; C:\sc\verb-AAD\Tests\verb-AAD.tests.ps1
    $TestScriptPath = "$($ModDirPath)\Tests\$($ModuleName).tests.ps1" ;
    $rgxSignFiles='\.(CAT|MSI|JAR,OCX|PS1|PSM1|PSD1|PS1XML|PSC1|MSP|CMD|BAT|VBS)$' ; 
    $rgxIncludeDirs='\\(Public|Internal|Classes)\\' ;

    $editor = "notepad2.exe" ;

    $error.clear() ;

    if($NoBuildInfo){
        # 9:34 AM 6/29/2020 for some reason, on join-object mod, Set-BuildEnvironment is going into the abyss, running git.exe log --format=%B -n 1
        # so use psd1version and manually increment, skipping BuildHelper mod use entirely
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):(-NoBuildInfo specified:Skipping use of buggy BuildHelpers module)" ; 
        TRY {
            #$ModPsdPath = (gci "$($modroot)\$($ModuleName)\$($ModuleName).psd1").FullName
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
            write-warning  "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            Exit ;
        } ;
        $psd1Vers = $psd1Profile.Version.tostring() ; 
    } else { 
        # stock buildhelper e-varis - I don't even see it in *use*
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):(executing:Get-BuildEnvironment -Path $($ModDirPath) `n(use -NoBuildInfo if hangs))" ; 
        $BuildVariable = Get-BuildVariable -path $ModDirPath 
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
              LogSpec = $logspec ; 
              NoAliasExport=$($NoAliasExport) ; 
              ErrorAction="Stop" ; 
              showdebug=$($showdebug);
              whatif=$($whatif);
            } ;
            $smsg= "Merge-Module w`n$(($pltmergeModule|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            TRY {
                $ReportObj = Merge-Module @pltmergeModule ;
            } CATCH {
                $PassStatus += ";ERROR"; 
                write-warning  "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                Exit ;
            } ;
            <#  $ReportObj=[ordered]@{
                    Status=$true ; 
                    PsmNameBU = $PsmNameBU ; 
                    PassStatus = $PassStatus ;
                } ; 
            #>
            $PsmNameBu=$ReportObj.PsmNameBU ; 
            if($ReportObj.Status){
            
            } else {
                $smsg= "Merge-Module failure.`nPassStatus:$($reportobj.PassStatus)" ;  
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if($PsmNameBu){
                    $smsg= "Reverting PSM1 from backup:" ;  
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $error.clear() ;
                    TRY {
                        $bRet = revert-File -Source $PsmNameBu -Destination "$($ModDirPath)\$($ModuleName)\$($ModuleName).psm1" -showdebug:$($showdebug) -whatif:$($whatif)
                    } CATCH {
                        $PassStatus += ";ERROR"; 
                        Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                        Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
                    } ; 
                } else { 
                    $smsg= "(no backup .psm1 to revert from)" ;  
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ; 
            } ; 
        } ;

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
        write-warning  "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        Exit ;
    } ;

    $psd1Vers = $psd1Profile.Version.tostring() ; 
    $psd1guid = $psd1Profile.Guid.tostring() ; 
    if(test-path $TestScriptPath){
        # update the pester test script with guid: C:\sc\verb-AAD\Tests ; C:\sc\verb-AAD\Tests\verb-AAD.tests.ps1
        $smsg= "Checking sync of Psd1 module guid to the Pester Test Script: $($TestScriptPath)" ; ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $rgxTestScriptNOGuid = "Please\sPaste\shere\syour\smodule\sGuid\s-\sTest-ModuleManifest\s'<ModulePath>'\s\|\sSelect-Object\s-ExpandProperty\sGuid"
        #$rgxTestScriptGuid = '\.Guid((\s)*)\|((\s)*)Should((\s)*)-Be((\s)*)"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"'
        # cap grp
        $rgxTestScriptGuid = '\.Guid((\s)*)\|((\s)*)Should((\s)*)-Be((\s)*)"([0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12})"'
        $rgxGuid = "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}" ; 
        # also maintain encoding (set-content defaults ascii)
        $tf = $TestScriptPath; 
        $enc=$null ; $enc=get-FileEncoding -path $tf ;
        if($enc -eq 'ASCII') { 
            $enc = 'UTF8' ; 
            $smsg = "(ASCI encoding detected, converting to UTF8)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ; # force damaged/ascii to UTF8
        $pltSetCon=[ordered]@{ Path=$tf ; whatif=$($whatif) ;  } ;
        if($enc){$pltSetCon.add('encoding',$enc) } ;
        if($psd1ExpMatch = gci $tf |select-string -Pattern $rgxTestScriptNOGuid ){
            (Get-Content $tf) | Foreach-Object {
                $_ -replace $rgxTestScriptNOGuid, "$($psd1guid)"
            } | Set-Content @pltSetCon ; 
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
                # generic guid replace: $_ -replace $rgxGuid, "$($psd1guid)"
                (Get-Content $tf) | Foreach-Object {
                    $_ -replace $testGuid, "$($psd1guid)"
                } | Set-Content @pltSetCon ; 
            } ; 
        } else { 
            $smsg = "UNABLE TO Regex out...`n$($rgxTestScriptNOGuid)`n...from $($tf)`nTestScript hasn't been UPDATED!" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        } ; 

    } else { 
        $smsg = "Unable to locate `$TestScriptPath:$($TestScriptPath)" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level INfo } #Error|Warn|Debug 
        else{ write-verbose -verbose:$true "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
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
        $enc=$null ; $enc=get-FileEncoding -path $tf ;
        if($enc -eq 'ASCII') { 
            $enc = 'UTF8' ; 
            $smsg = "(ASCI encoding detected, converting to UTF8)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ; # force damaged/ascii to UTF8
        $pltSetCon=[ordered]@{ Path=$tf ; whatif=$($whatif) ;  } ;
        if($enc){$pltSetCon.add('encoding',$enc) } ;
        (Get-Content $tf) | Foreach-Object {
            $_ -replace $psm1Profile.matches[0].captures.groups[0].value.tostring(), "Version     : $($psd1Vers)"
        } | Set-Content @pltSetCon ; 
    } else { 
        $smsg = "(Psd1:Psm1 versions match)" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
    } ; 

    # Update the psd1 FunctionsToExport : (moved to merge-module, after the export-modulemember code)


    $smsg= "Signing appropriate files..." ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

    #$files = Get-ChildItem "$($ModDirPath)\*" -recur |Where-Object{$_.extension -match $rgxSignFiles} ;
    # 1:38 PM 12/26/2019#251 filter public|internal|classes include subdirs - don't sign them (if including/dyn-including causes 'Executable script code found in signature block.' errors
    $files = Get-ChildItem "$($ModDirPath)\*" -recur |Where-Object{$_.extension -match $rgxSignFiles} | ?{$_.fullname -notmatch $rgxIncludeDirs} ; 
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
            write-warning  "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            Exit ;
        } ;
    } else {
        $smsg= "(no matching signable files)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;

    $smsg= "Removing existing profile $($ModuleName) content..." ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    
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
    <# installed mods have PSGetModuleInfo.xml files
    #>

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
        if (!$bRet) {throw "FAILURE" ; EXIT ; } ;
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
                Exit ; 
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
            Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            $PassStatus += ";ERROR"; 
            Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
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
                Exit ;
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
                            if (!$bRet) {throw "FAILURE" ; EXIT ; } ;
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
                            Exit ; 
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
                Exit ;
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
                if (!$bRet) {throw "FAILURE" ; EXIT ; } ;

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
                    Exit ;
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
                    Exit ;
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
                            Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                            $PassStatus += ";ERROR"; 
                            Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
                        } ; 
                    } ; 
                    write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Copy-Item w`n$(($pltCItm|out-string).trim())" ; 
                    $error.clear() ;
                    TRY {
                        copy-Item @pltCItm ;
                    } CATCH {
                        Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                        $PassStatus += ";ERROR"; 
                        Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
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