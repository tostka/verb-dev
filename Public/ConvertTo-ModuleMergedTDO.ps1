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
