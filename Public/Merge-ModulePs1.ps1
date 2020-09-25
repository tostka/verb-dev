#*------v Merge-ModulePs1.ps1 v------
function Merge-ModulePs1 {
    <#
    .SYNOPSIS
    Merge-ModulePs1.ps1 - Merge function .ps1 files into a monolisthic uwes\[module].ps1 backload file, returns a hash with status:$true/$false, and PsmNameBU:The name of a backup of the original .psm1 file (for restoring on failures)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2019-12-10
    FileName    : Merge-ModulePs1.ps1
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit : Przemyslaw Klys
    AddedWebsite: https://evotec.xyz/powershell-single-psm1-file-versus-multi-file-modules/
    AddedTwitter:
    REVISIONS
    * 10:50 AM 9/25/2020 debugged, looks functional, resulting .ps1 will dot-source load wo issues ; port over from merg-module.ps1 -> merge-moduleps1.ps1
    * 11:42 AM 6/30/2020 fixed Public\_CommonCode.ps1, -ea 0 when not present
    * 1:13 PM 6/29/2020 add support for .Public\_CommonCode.ps1 - module-spanning code that should follow the Function block in the .psm1
    * 3:27 PM 3/15/2020 load-Module: added $PsmNameTmp, $PsdNameTmp and shifted updating to a _TMP file of each, which at end, if error free, overwrites the current functional copy (correcting prior issue with corruption of existing copy, when there were processing errors). 
    * failing to load verb-io content, added a forceload if get-fileencoding isn't present, added new PassStatus tests and passed back in output, also now does the build in a .psm1_TMP file, to avoid damaging last functional copy
    * 12:42 PM 3/3/2020 fixed missing trailing sbnr (Internal)
    * 10:36 AM 3/3/2020 added pre-check & echo when unable to locate the psd1 FunctionsToExport value
    * 1:58 PM 3/2/2020 as Set-ModuleFunction isn't properly setting *all* exported, go back to collecting and updating the psm1 & psd1 *both* via regx
    * 9:12 AM 2/29/2020 shift export-modulemember/FooterBlock to bottom, added FUNCTIONS delimiter lines
    * 9:17 AM 2/27/2020 added new -NoAliasExport param, and added the missing 
    * 3:44 PM 2/26/2020 Merge-ModulePs1: added -LogSpec param (feed it the object returned by a Start-Log() pass). 
    * 11:27 AM Merge-ModulePs1 2/24/2020 suppress block dumps to console, unless -showdebug or -verbose in use
    * 7:24 AM 1/3/2020 #936: trimmed errant trailing ;- byproduct of fix-encoding pass
    * 10:33 AM 12/30/2019 Merge-ModulePs1():951,952 assert sorts into alpha order (make easier to find in the psm1)
    * 10:20 AM 12/30/2019 Merge-ModulePs1(): fixed/debugged monolithic build options, now works. Could use some code to autoupdate all .NOTES:Version fields, but that's for future.
    * 8:59 AM 12/30/2019 Merge-ModulePs1(): Added code to update against monolithic/non-dyn-incl psm1s. Parses CBH & meta blocks out & constructs a new psm1 from the content.
    * 9:51 AM 12/28/2019 Merge-ModulePs1 fixed $sBnrSStart/End typo
    * 1:23 PM 12/27/2019 pulled regex sig replace with simple start/end detect and throw error (was leaving dangling curlies in psm1)
    * 12:11 PM 12/27/2019 swapped write-error in catch blocks with write-warning - we seems to be failing to exec the bal of the catch
    * 7:46 AM 12/27/2019 Merge-ModulePs1(): added included file demarc comments to improve merged file visual parsing, accumulating $PrivateFunctions now as well, explicit echos
    * 8:51 AM 12/20/2019 removed plural from ModuleSourcePaths -> ModuleSourcePath (matches all the calls etc)
    *8:50 PM 12/18/2019 sorted hard-coded verb-aad typo 
    2:54 PM 12/11/2019 rewrote, added backup of psm1, parsing out the stock dyn-include code from the orig psm1, leverages fault-tolerant set-fileContent(), switched sourcepaths to array type, and looped, detecting public/internal by path and prepping for the export list.
    * 2018/11/06 Przemyslaw Klys posted version
    .DESCRIPTION
    Merge-ModulePs1.ps1 - Merge function .ps1 files into a monolisthic uwes\[module].ps1 backload file, returns a hash with status:$true/$false, and PsmNameBU:The name of a backup of the original .psm1 file (for restoring on failures)
    Essentially once a module is validated functional, migrate the updated component functions into the uwes\[module].ps1 backload file
    .PARAMETER  ModuleName
    Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]
    .PARAMETER  ModuleSourcePath
    Directory containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]
    .PARAMETER ModuleDestinationPs1File
    Final monolithic module .psm1 file name to be populated [-ModuleDestinationPs1File c:\path-to\module\module.psm1]
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
    cls ; Merge-ModulePs1 -ModuleName verb-AAD -ModuleSourcePath C:\sc\verb-AAD\Public -ModuleDestinationPs1File c:\usr\work\exch\scripts\verb-AAD.ps1 -showdebug -whatif ;
    Command line process
    .LINK
    https://www.toddomation.com
    #>
    param (
        [Parameter(Mandatory = $True, HelpMessage = "Module Name (used to name the ModuleName.ps1 file)[-ModuleName verb-XXX]")]
        [string] $ModuleName,
        [Parameter(Mandatory = $True, HelpMessage = "Array of directory paths containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]")]
        [array] $ModuleSourcePath,
        [Parameter(Mandatory = $True, HelpMessage = "Full path to the final [modle].ps1 file should be constructed [-ModuleDestinationPs1File c:\path-to\scripts\module.ps1]")]
        [string] $ModuleDestinationPs1File,
        [Parameter(Mandatory = $False, HelpMessage = "Logging spec object (output from start-log())[-LogSpec `$LogSpec]")]
        $LogSpec, 
        [Parameter(HelpMessage = "Flag that skips auto-inclusion of 'Export-ModuleMember -Alias * ' in merged file [-NoAliasExport]")]
        [switch] $NoAliasExport,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    $verbose = ($VerbosePreference -eq "Continue") ; 

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

    # expects an existing target file (may want to rem this test out)
    if ($ModuleDestinationPs1File.GetType().FullName -ne 'System.IO.FileInfo') {
        $ModuleDestinationPs1File = get-childitem -path $ModuleDestinationPs1File ;
    } ;

    $ModuleRootPath = split-path $ModuleDestinationPs1File -Parent ; 

    $ttl = ($ModuleSourcePath | measure).count ;
    $iProcd = 0 ;

    $ExportFunctions = @() ;
    $PrivateFunctions = @() ;

    <#$PsmName="$ModuleDestinationPath\$ModuleName.psm1" ;
    $PsdName="$ModuleDestinationPath\$ModuleName.psd1" ;
    $PsmNameTmp="$ModuleDestinationPath\$ModuleName.psm1_TMP" ;
    $PsdNameTmp="$ModuleDestinationPath\$ModuleName.psd1_TMP" ;
    #>
    $ModuleDestinationPs1FileTmp = $ModuleDestinationPs1File.replace('.ps1','.ps1_TMP') ;

    # backup existing & purge the dyn-include block
    if(test-path -path $ModuleDestinationPs1File){
        $rawSourceLines = get-content -path $ModuleDestinationPs1File  ;
        $SrcLineTtl = ($rawSourceLines | Measure-Object).count ;
        $ModuleDestinationPs1FileBU = backup-File -path $ModuleDestinationPs1File -showdebug:$($showdebug) -whatif:$($whatif) ;
        if (!$ModuleDestinationPs1FileBU) {throw "FAILURE" } ;

        # this script *appends* to the existing .ps1 file.
        # which by default includes a dynamic include block:
        # detect and drop out the above, for the monolithic version
        $rgxPurgeblockStart = '#Get\spublic\sand\sprivate\sfunction\sdefinition\sfiles\.' ;
        #$rgxPurgeblockStart = "#\*======v\sFUNCTIONS\sv======"
        # stock dyanmic export of collected functions
        #$rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s;';
        # updated version of dyn end, that also explicitly exports -alias *
        $rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s-Alias\s\*\s;\s'
        #$rgxPurgeBlockEnd  = "#\*======\^\sEND\sFUNCTIONS\s\^======" ; 
        $dynIncludeOpen = (ss -Path  $ModuleDestinationPs1File -Pattern $rgxPurgeblockStart).linenumber ;
        if($dynIncludeOpen -is [system.array]){
            $dynIncludeOpen = $dynIncludeOpen[-1] ; 
        } ; 
        $dynIncludeClose = (ss -Path  $ModuleDestinationPs1File -Pattern $rgxPurgeBlockEnd).linenumber ;
        if($dynIncludeClose -is [system.array]){
            $dynIncludeClose = $dynIncludeClose[-1] ; 
        } ; 
        if(!$dynIncludeOpen){$dynIncludeClose = 0 } ;
        $updatedContent = @() ; $DropContent=@() ;

        # 11:31 AM 9/25/2020 this shouldn't be done dyn, it should be monolithic
        if($dynIncludeOpen -AND $dynIncludeClose){
            # dyn psm1
            $smsg= "(dyn-include psm1 detected - purging content...)" ;  
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
            $updatedContent += "# $(split-path -path $ModuleDestinationPs1File -leaf)`n"
            if($oBlkComments.metaBlock){$updatedContent += $oBlkComments.metaBlock  |out-string ; } ;
            if($oBlkComments.interText ){$updatedContent += $oBlkComments.interText  |out-string ; } ; 
            $updatedContent += $oBlkComments.cbhBlock |out-string ; 

            # Post CBH always add the helper/alias-export command (functions are covered in the psd1 manifest, dyn's have in the template)
            <# .psm1 block
            $PostCBHBlock=@"

`$script:ModuleRoot = `$PSScriptRoot ;
`$script:ModuleVersion = (Import-PowerShellDataFile -Path (get-childitem `$script:moduleroot\*.psd1).fullname).moduleversion ;

#*======v FUNCTIONS v======

"@ ; 
#>
            # ps1 block
            $PostCBHBlock=@"

#*======v FUNCTIONS v======

"@ ; 

            $updatedContent += $PostCBHBlock |out-string ; 
            
        } ;  # if-E dyn/monolithic source psm1


        if($updatedContent){
            $bRet = Set-FileContent -Text $updatedContent -Path $ModuleDestinationPs1FileTmp -showdebug:$($showdebug) -whatif:$($whatif) ;
            if (!$bRet) {throw "FAILURE" } else {
                $PassStatus += ";UPDATED:Set-FileContent "; 
            }  ;
        } else { 
            $PassStatus += ";ERROR:Set-FileContent"; 
            $smsg= "NO PARSEABLE METADATA/CBH CONTENT IN EXISTING FILE, TO BUILD UPDATED PSM1 FROM!`n$($ModuleDestinationPs1File)" ;        
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #$false | write-output ;
            $ReportObj=[ordered]@{
                Status=$false ; 
                PsmNameBU = $ModuleDestinationPs1FileBU ; 
                PassStatus = $PassStatus ;
            } ; 
            $ReportObj | write-output ;
            Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
        } ; 
    } ;

    # don't need this on monolithic .ps1 backload file
    # DEFAULT - DIRS CREATION - git doesn't reproduce empty dirs, create if empty (avoids errors later)
    # exempt the .git & .vscode dirs, we don't publish those to modules dir
    $DefaultModDirs = "Public","Internal","Classes","Tests","Docs","Docs\Cab","Docs\en-US","Docs\Markdown" ; 
    foreach($Dir in $DefaultModDirs){
        $tPath = join-path -path $ModuleRootPath -ChildPath $Dir ; 
        if(!(test-path -path $tPath)){
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
    
    # $MODULESOURCEPATH - DIRS CREATION 
    foreach ($ModuleSource in $ModuleSourcePath) {
        $iProcd++ ;
        if ($ModuleSource.GetType().FullName -ne 'System.IO.DirectoryInfo') {
            <#
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
            #>
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
                # excl -Exclude _CommonCode.ps1 (gets added to .ps1 at end of all processing)
                $ComponentScripts = Get-ChildItem -Path $ModuleSource\*.ps1 -Exclude _CommonCode.ps1 -Recurse -ErrorAction SilentlyContinue | sort name  ;
                $ComponentModules = Get-ChildItem -Path $ModuleSource\*.ps1 -Recurse -ErrorAction SilentlyContinue | sort name;
            } ; 
            $pltAdd = @{
                Path=$ModuleDestinationPs1FileTmp ;
                whatif=$whatif;
            } ;
            foreach ($ScriptFile in $ComponentScripts) {
                $smsg= "Processing:$($ScriptFile)..." ;  
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $ParsedContent = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$null) ;
                # detect and throw up on sigs
                if($ParsedContent| ?{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                    $smsg= "*WARNING*:SUBFILE`n$($scriptfile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;  
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    exit
                } ; 

                # above is literally the entire AST, unfiltered. Should be ALL parsed entities.
                # add demarc comments - this is AST parsed, so it prob doesn't include delimiters
                $sBnrSStart = "`n#*------v $($ScriptFile.name) v------" ;
                $sBnrSEnd = "$($sBnrSStart.replace('-v','-^').replace('v-','^-'))" ;
                "$($sBnrSStart)`n$($ParsedContent.EndBlock.Extent.Text)`n$($sBnrSEnd)" | Add-Content @pltAdd ;

                $AST = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$Null ) ;
                $ASTFunctions =  $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;

                # public & functions = public ; private & internal = private - flip output to -showdebug or -verbose, only
                if($ModuleSource -match '(Public|Functions)'){
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
            foreach ($ModFile in $ComponentModules) {
                $smsg= "Adding:$($ModFile)..." ;  
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $Content = Get-Content $ModFile ;
                
                if($Content| ?{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                    $smsg= "*WARNING*:SUBFILE`n$($ModFile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;  
                    if($showDebug) {
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ; 
                    exit ; 
                } ; 
                $Content | Add-Content @pltAdd ;
                $PassStatus += ";Add-Content:UPDATED"; 
                # by contrast, this is NON-AST parsed - it's appending the entire raw file content. Shouldn't need delimiters - they'd already be in source .ps1
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
                PsmNameBU = $ModuleDestinationPs1FileBU ; 
                PassStatus = $PassStatus ;
            } ; 
            $ReportObj | write-output ;
            #Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            Continue ;
        } ;

        $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 


    } ; # loop-E

    # add support for Public\_CommonCode.ps1 (module-spanning code that trails the functions block in the .ps1)
    if($PublicPath = $ModuleSourcePath |?{$_ -match 'Public'}){
        if($ModFile = Get-ChildItem -Path $PublicPath\_CommonCode.ps1 -ea 0 ){
            $smsg= "Adding:$($ModFile)..." ;  
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            "#*======v _CommonCode v======" | Add-Content @pltAdd ;
            $Content = Get-Content $ModFile ;
            if($Content| ?{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                $smsg= "*WARNING*:SUBFILE`n$($ModFile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;  
                if($showDebug) {
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ; 
                exit ; 
            } ; 
            $Content | Add-Content @pltAdd ;
            "#*======^ END _CommonCode ^======" | Add-Content @pltAdd ;
            $PassStatus += ";Add-Content:UPDATED"; 
        } else {
            write-verbose "(no Public\_CommonCode.ps1)" ;
        } ; 
    } ; 

    <# psm1 code
    # append the Export-ModuleMember -Function $publicFunctions  (psd1 functionstoexport is functional instead),
    $smsg= "(Updating Psm1 Export-ModuleMember -Function to reflect Public modules)" ;  
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #"Export-ModuleMember -Function $(($ExportFunctions) -join ',')" | Add-Content @pltAdd ;
    # Collect & set explicitly in the psm1, the psd1 Set-ModuleFunctoin buildhelper isn't doing the full set, only above. 
    # stick the Alias * in there too, force it as the psd1 spec's simply override the explicits in the psm1
    
    #"`nExport-ModuleMember -Function $(($ExportFunctions) -join ',') -Alias *" | Add-Content @pltAdd ;
    #>

    # tack in footerblock to the merged psm1 (primarily export-modulemember -alias * ; can also be any function-trailing content you want in the psm1)
    <# psm1 block
    $FooterBlock=@"

#*======^ END FUNCTIONS ^======

Export-ModuleMember -Function $(($ExportFunctions) -join ',') -Alias *

"@ ; 
#>
    # ps1 block
    $FooterBlock=@"

#*======^ END FUNCTIONS ^======

"@ ; 

    if(-not($NoAliasExport)){
        $smsg= "Adding:FooterBlock..." ;  
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #$updatedContent += $FooterBlock |out-string ; 
        $pltAdd = @{
            Path=$ModuleDestinationPs1FileTmp ;
            whatif=$whatif;
        } ;
        $FooterBlock | Add-Content @pltAdd ;
        $PassStatus += ";Add-Content:UPDATED"; 
    } else {
        $smsg= "NoAliasExport specified:Skipping FooterBlock add" ;  
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        "#*======^ END FUNCTIONS ^======" | Add-Content @pltAdd ;
        $PassStatus += ";Add-Content:UPDATED"; 
    } ; 

    
    <# psm1/psd1 block
    # update the manifest too: # should be forced array: FunctionsToExport = @('build-VSCConfig','Get-CommentBlocks','get-VersionInfo','Merge-ModulePs1','parseHelp')
    $smsg = "Updating the Psd1 FunctionsToExport to match" ; 
    if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    $rgxFuncs2Export = 'FunctionsToExport((\s)*)=((\s)*).*' ; 
    $tf = $PsdName ; 
    # switch back to manual local updates
    if($psd1ExpMatch = gci $tf | ss -Pattern $rgxFuncs2Export ){
        $enc=$null ; $enc=get-FileEncoding -path $tf ;
        if($enc -eq 'ASCII') { 
            $enc = 'UTF8' ; 
            $smsg = "(ASCI encoding detected, converting to UTF8)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ; # force damaged/ascii to UTF8
        $pltSetCon=[ordered]@{ Path=$PsdNameTmp ; whatif=$($whatif) ;  } ;
        if($enc){$pltSetCon.add('encoding',$enc) } ;
        (Get-Content $tf) | Foreach-Object {
            $_ -replace $rgxFuncs2Export , ("FunctionsToExport = " + "@('" + $($ExportFunctions -join "','") + "')") 
        } | Set-Content @pltSetCon ; 
        $PassStatus += ";Set-Content:UPDATED"; 
    } else { 
        $smsg = "UNABLE TO Regex out $($rgxFuncs2Export) from $($tf)`nFunctionsToExport CAN'T BE UPDATED!" ; 
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    } ; 
    #>

    if($PassStatus.tolower() | select-string '.*error.*'){
        $smsg = "ERRORS LOGGED, ABORTING UPDATE OF ORIGINAL .ps1!:`n$($pltCpy.Destination)" ; 
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug 
        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    } elseif(!$whatif) { 
        if(test-path $ModuleDestinationPs1FileTmp){
            $pltCpy = @{
                Path=$ModuleDestinationPs1FileTmp ;
                Destination=$ModuleDestinationPs1File ; 
                whatif=$whatif;
                ErrorAction="STOP" ; 
            } ;
            $smsg = "Processing error free: Overwriting temp .ps1 with temp copy`ncopy-item w`n$(($pltCpy|out-string).trim())" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;     
            $error.clear() ;
            TRY {
                copy-Item @pltCpy ;
                $PassStatus += ";copy-Item:UPDATED"; 
            } CATCH {
                Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                $PassStatus += ";copy-Item:ERROR"; 
                Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
            } ; 
        } else {
            $smsg = "UNABLE TO LOCATE temp .ps1!:`n$($pltCpy.path)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug 
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            $PassStatus += ";test-path $ModuleDestinationPs1FileTmp:ERROR"; 
        } ;  
        
        <# psm1/psd1 block
        # $PsdNameTmp/$PsdName
        if(test-path $PsdNameTmp){
            $pltCpy = @{
                Path=$PsdNameTmp ;
                Destination=$PsdName ; 
                whatif=$whatif;
                ErrorAction="STOP" ; 
            } ;
            $smsg = "Processing error free: Overwriting temp .psd1 with temp copy`ncopy-item w`n$(($pltCpy|out-string).trim())" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;     
            $error.clear() ;
            TRY {
                copy-Item @pltCpy ;
                $PassStatus += ";copy-Item:UPDATE"; 
            } CATCH {
                Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                $PassStatus += ";copy-Item:ERROR"; 
                Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
            } ; 
        } else {
            $smsg = "UNABLE TO LOCATE temp .ps1!:`n$($pltCpy.path)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug 
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            $PassStatus += ";test-path $PsdNameTmp:ERROR"; 
        } ;  
        #>

    } else {
        $smsg = "(whatif:skipping updates)" ; 
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    }; 
    $ReportObj=[ordered]@{
        Status=$true ; 
        PsmNameBU = $ModuleDestinationPs1FileBU ; 
        PassStatus = $PassStatus ;
    } ; 
    if($PassStatus.tolower() | select-string '.*error.*'){
        $ReportObj.Status=$false ; 
    } ; 
    $ReportObj | write-output ;
}

#*------^ Merge-ModulePs1.ps1 ^------
