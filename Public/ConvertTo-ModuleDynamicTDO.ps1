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
