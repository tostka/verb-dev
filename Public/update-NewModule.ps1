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
        [Parameter(HelpMessage="Flag that indicates Module should be republished into local Repo (skips ConvertTo-ModuleDynamicTDO & Sign-file steps) [-Republish]")]
            [switch] $Republish,
        [Parameter(HelpMessage="Flag that indicates Pester test script should be run, at end of processing [-RunTest]")]
            [switch] $RunTest,
        [Parameter(HelpMessage="Skip BuildInfo use (workaround for hangs in that module)[-NoBuildInfo]")]
            [switch] $NoBuildInfo,
        [Parameter(HelpMessage="Optional Explicit 3-digit RequiredVersion specification (as contrasts with using current Manifest .psd1 ModuleVersion value)[-Version 2.0.3]")]
            [version]$RequiredVersion,
        [Parameter(HelpMessage="regex reflecting an array of file extension strings to identify 'external' dependancy files in the module directory structure that are to be included in the distributed module(provided to provide run-time override)")]
            [string[]]$rgxModExtIncl='\.(cab|cat|cmd|config|cscfg|csdef|css|dll|dylib|gif|html|ico|jpg|js|json|map|Materialize|MaterialUI|md|pdb|php|png|ps1|ps1xml|psd1|psm1|rcs|reg|snippet|so|txt|vscode|wixproj|wxi|xaml|xml|yml|zip)',
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
    $exclude = @('main.js','rebuild-module.ps1','New-Module-Create.md') ; 
    # gci post-filtered excludes from build/pkg
    $excludeMatch = @('.git','.vscode','New-Module-Create.md') ;
    [regex] $excludeMatchRegEx = '(?i)' + (($excludeMatch |ForEach-Object {[regex]::escape($_)}) -join "|") + '' ;
    $rgxPsd1FileListDirs = "\\(Docs|Licenses|Resource)\\" ;  # dirs of files to be included in the manifest FileList key
    $rgxPsd1FileListExcl = "\\(\.vscode|ScriptAnalyzer-Results-|logs\\)|-LOG-BATCH-EXEC-" ; # file filter to exclude from mani FilList key
    $rgxLicFileFilter = '\\(Resource|Licenses)\\' ; # exempt extensionless license files from removal in temp profile copy
    $rgxRootFilesBuild = "(CHANGELOG|README)\.md$" ;
    # # post filter excludes regex, dir names in fullname path that should never be included in build, logs, and temp versions of .ps[md]1 files.
    $rgxSrcFilesPostExcl = "\\(Package|Tests|logs)\\|(\.ps[dm]1_(\d+-\d+[AP]M|TMP)|-LOG-BATCH-EXEC-\d+-\d+[AP]M-log\.txt|\\(fingerprint|Psd1filelist))$" ; 
    # rgx to exclude exported temp breakpoint files from inclusion in module build
    $rgxPsd1BPExcl = "\\(Public|Internal|Private)\\.*-ps1-BP\.xml$" ; 
    $MergeBuildExcl = "\\(Public|Internal|External|Private)\\.*.ps1$" ; 
    # rgx to exclude target verb-mod\verb-mod from efforts to flatten (it's the dest, shouldn't be a source)
    $rgxTargExcl = [regex]::escape("\$($ModuleName)\$($ModuleName)") ; 
    $rgxGuidModFiles = "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\.ps(d|m)1" ; # identifies temp psd|m1 files named for guids
    $rgxInclOutLicFileName = '^LICENSE' ; # id's local extensionless vdev\vdev lic files that *should* remain
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
        $smsg = "Failed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: $($ErrTrapd)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $smsg = $ErrTrapd.Exception.Message ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }
        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
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
            $PassStatus += ";ERROR";
            $smsg= "Failed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: $($ErrTrapd)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $smsg = $ErrTrapd.Exception.Message ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
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
        $PassStatus += ";ERROR";
        $smsg = "Import-PowerShellDataFile:Failed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: $($ErrTrapd)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $smsg = $ErrTrapd.Exception.Message ;
        write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
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
        $PassStatus += ";ERROR";
        $smsg = "Failed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: $($ErrTrapd)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $smsg = $ErrTrapd.Exception.Message ;
        write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
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
    $pltGci=[ordered]@{Path=$moddirpath ;Recurse=$true ;File = $true ; Exclude=$exclude; ErrorAction="Stop" ; } ;
    #$Psd1filelist = Get-ChildItem @pltGci | ?{($_.extension -match $rgxPsd1FileList -and $_.fullname -notmatch $rgxPsd1FileListExcl) -OR $_.fullname -match $rgxPsd1FileListDirs} | select -expand name ; 
    # add: postfilter breakpoint filters
    $Psd1filelist = Get-ChildItem @pltGci | ?{($_.extension -match $rgxPsd1FileList -and $_.fullname -notmatch $rgxPsd1FileListExcl) -OR $_.fullname -match $rgxPsd1FileListDirs} | 
        ?{$_.fullname -notmatch $rgxPsd1BPExcl} ;
    # add fullname variant for flatten copying resources
    $Psd1filelistFull =  $Psd1filelist | select -expand fullname ; 
    # and name only for the manifest FileList key
    # 4:44 PM 12/5/2023 select uniques, showing mults in the resulting array in psd1.filelist
    $Psd1filelist  = $Psd1filelist | select -expand name | select -unique ; 
    # export the list extensionless xml, to let it drop off of the Psd1filelist 
    $rgxPsd1FileListLine = '((#\s)*)FileList((\s)*)=((\s)*).*' ;
    if($Psd1filelist){
        $smsg = "`$Psd1filelist populated: xXML:$($ModDirPath)\Psd1filelist" ; 
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
            showdebug=$($showdebug);
            whatif=$($whatif);
        } ;
        $smsg= "Sign-file w`n$(($pltSignFile|out-string).trim())" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        TRY {
            sign-file @pltSignFile ;
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $PassStatus += ";ERROR";
            $smsg = "Failed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: $($ErrTrapd)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $smsg = $ErrTrapd.Exception.Message ;
            write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
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
    #$pltGci=[ordered]@{Path=$from ;Recurse=$true ;Exclude=$exclude; ErrorAction="Stop" ; } ;
    $pltGci=[ordered]@{Path=$from ;Recurse=$false ;Exclude=$exclude; ErrorAction="Stop" ; } ;
    # explicitly only go after the common module component, by type, via -include -
    #issue is -include causes it to collect only leaf files, doesn't include dir
    #creation, and if no pre-exist on the dir, causes a hard error on copy attempt.
    # 2:34 PM 3/15/2020 reset to copy all, and then post-purge non-$ModExtIncl

    # use a retry
    $Exit = 0 ;
    Do {
        Try {
            # below is original copy-all gci
            #Get-ChildItem @pltGci | Where-Object { $excludeMatch -eq $null -or $_.FullName.Replace($from, '') -notmatch $excludeMatchRegEx} | Copy-Item -Destination {  if ($_.PSIsContainer) { Join-Path $to $_.Parent.FullName.Substring($from.length) }   else { Join-Path $to $_.FullName.Substring($from.length) }    } -Force -Exclude $exclude -whatif:$($whatif) ;
            # two stage it anyway
            $srcFiles = Get-ChildItem @pltGci | Where-Object { $excludeMatch -eq $null -OR $_.FullName.Replace($from, '') -notmatch $excludeMatchRegEx} ;
            $smsg = "`$srcFiles:post-filter out:`n$($rgxSrcFilesPostExcl)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
            #$srcFiles = $srcFiles | ?{$_.fullname -notmatch $rgxSrcFilesPostExcl} ; 
            $srcFiles = $srcFiles | ?{$_.fullname -notmatch $rgxSrcFilesPostExcl -AND -not($_.PsIsContainer)} ; 

            if(-not(test-path $to)){  
                $smsg = "Non-Pre-existing:`$to:$($to)" ; 
                $smsg +="`nPre-creating before copy..." ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                mkdir -path $to -whatif:$($whatif) -verbose 
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
                } -Force -Exclude $exclude -whatif:$($whatif) ;
            <# leaf copies fail hard, when gci -include, due to returns being solely leaf files, no dirs, so the dirs don't get pre-created, and cause 'not found' copy fails
            # 2-stage and pull out non-target ext's
            $srcFiles = Get-ChildItem @pltGci | Where-Object { $excludeMatch -eq $null -or $_.FullName.Replace($from, '') -notmatch $excludeMatchRegEx}
            # need the dirs before the files, to ensure they're pre-created (avoids errors)
            $srcFiles = $srcFiles | sort PSIsContainer,Parent -desc
            $srcFiles | Copy-Item -Destination {  if ($_.PSIsContainer) { Join-Path $to $_.Parent.FullName.Substring($from.length) }   else { Join-Path $to $_.FullName.Substring($from.length) }    } -Force -Exclude $exclude -whatif:$($whatif) ;
            #>
            $Exit = $Retries ;
        } CATCH {
            $smsg = $_.Exception.Message ;
            Start-Sleep -Seconds $RetrySleep ;
            # reconnect-exo/reconnect-ex2010
            $Exit ++ ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $smsg= "Try #: $($Exit)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            If ($Exit -eq $Retries) {
                $smsg= "Unable to exec cmd!" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                BREAK ; 
            } ;
        }  ;
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
            $smsg = "Failed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: $($ErrTrapd)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $smsg = $ErrTrapd.Exception.Message ;
            write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
            $PassStatus += ";ERROR";
            Break #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
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
                $ErrTrapd = $Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } 
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
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
            $ErrTrapd = $Error[0] ;
            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } 
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
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
                $PassStatus += ";ERROR";
                $smsg= "Failed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: $($ErrTrapd)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $smsg = $ErrTrapd.Exception.Message ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
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
                $ErrorTrapped = $Error[0] ;
                $PassStatus += ";ERROR";
                $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
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
            $smsg= "`nPublish-Module w`n$(($pltPublishModule|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            TRY {
                Publish-Module @pltPublishModule ;
                if($pbmo_Err){
                    $smsg = "`nFOUND `$pbmo_Err: import-module HAD ERRORS!" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    foreach($errExcpt in $pbmo_Err.Exception){
                        switch -regex ($errExcpt){
                            default {
                                $smsg = "`nPublish-Module PBMO UNDEFINED ERROR!" ;
                                $smsg += "`n$($errExcpt)" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            }
                        } ;
                    } ;
                    #BREAK ;
                    throw $smsg ;
                } else {
                    $smsg = "(no `$pbmo_Err: Publish-Module had no errors)" ;
                    if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                } ;
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
                } CATCH {$smsg = $_.Exception.Message ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    BREAK ;
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
                    $ErrorTrapped = $Error[0] ;
                    $PassStatus += ";ERROR";
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
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
                            $smsg = "Failed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: $($ErrTrapd)" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
                            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $PassStatus += ";ERROR";
                            $smsg = $ErrTrapd.Exception.Message ;
                            write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                            Break #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
                        } ;
                    } ;
                    write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Copy-Item w`n$(($pltCItm|out-string).trim())" ;
                    $error.clear() ;
                    TRY {
                        copy-Item @pltCItm ;
                    } CATCH {
                        $ErrTrapd=$Error[0] ;
                        $smsg = "Failed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: $($ErrTrapd)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $smsg = $ErrTrapd.Exception.Message ;
                        write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
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