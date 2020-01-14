# VERB-dev.psm1


<#
.SYNOPSIS
VERB-dev - Development PS Module-related generic functions
.NOTES
Version     : 1.2.3
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
* 1/14/2020 - 1.2.3, mod build
# * 10:33 AM 12/30/2019 Merge-Module():951,952 assert sorts into alpha order (make easier to find in the psm1)
# * 10:20 AM 12/30/2019 Merge-Module(): fixed/debugged monolithic build options, now works. Could use some code to autoupdate all .NOTES:Version fields, but that's for future. ;Added code to update against monolithic/non-dyn-incl psm1s. Parses CBH & meta blocks out & constructs a new psm1 from the content. ; dbgd merge-module.ps1 w/in process-NewModule.ps1, functional so far.
# * 9:11 AM 12/30/2019 parseHelp(): added CBH .INPUTS & .OUTPUTS, specifying returns hash of get-help parsed output, and presence of CBH in the file
# * 9:04 AM 12/30/2019 profile-FileAST: updated CBH: added INPUTS & OUTPUTS, including hash properties returned
# * 8:36 AM 12/30/2019 Get-CommentBlocks:updated cbh and added .INPUTS/.OUTPUTS cbh entries, detailing the subcompontents of the hashtable returned
# * 12:03 PM 12/29/2019 added else wh on pswls entries
# * 1:54 PM 12/28/2019 added merge-module to verb-dev
# * 9:51 AM 12/28/2019 Merge-Module fixed $sBnrSStart/End typo
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


#*------v build-VSCConfig.ps1 v------
function build-VSCConfig {
    <#
    .SYNOPSIS
    build-VSCConfig - Process a sample ISE debugging command line, and convert it to a VSC launch.json 'configurations' entry
    .NOTES
    Version     : 1.0.0
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
    $bRet = build-VSCConfig -CommandLine $updatedContent -showdebug:$($showdebug) -whatif:$($whatif) ;
    if (!$bRet) {Continue } ;
    .LINK
    #>
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

    $verbosePreference = "Continue" # opts: Stop(&Error)|Inquire(&Prompt)|Continue(Display)|SilentlyContinue(Suppress);

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

#*------v Get-CommentBlocks.ps1 v------
function Get-CommentBlocks {
    <#
    .SYNOPSIS
    Get-CommentBlocks - Write output string to specified File
    .NOTES
    Version     : 1.0.0
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
    * 8:36 AM 12/30/2019 Get-CommentBlocks:updated cbh and added .INPUTS/.OUTPUTS cbh entries, detailing the subcompontents of the hashtable returned
    * 8:28 PM 11/17/2019 INIT
    .DESCRIPTION
    Get-CommentBlocks - Write output string to specified File
    .PARAMETER  Text
    RawSourceLines from the target script file (as gathered with get-content
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

    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "RawSourceLines from the target script file (as gathered with get-content) [-TextLines TextArrayObj]")]
        [ValidateNotNullOrEmpty()]$TextLines,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;

    $AllBlkCommentCloses = $TextLines | Select-string -Pattern '\s*#>' | Select-Object -ExpandProperty LineNumber ;
    $AllBlkCommentOpens = $TextLines | Select-string -Pattern '\s*<#' | Select-Object  -ExpandProperty LineNumber ;

    $MetaStart = $TextLines | Select-string -Pattern '\<\#PSScriptInfo' | Select-Object -First 1 -ExpandProperty LineNumber ;

    # cycle the comment-block combos till you find the CBH comment block
    $metaBlock = $null ; $metaBlock = @()
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
        write-verbose -verbose:$true  "$((get-date).ToString('HH:mm:ss')):(doesn't appear to be an inter meta-CBH block)" ;
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

#*------v get-VersionInfo.ps1 v------
function get-VersionInfo {
    <#
    .SYNOPSIS
    get-VersionInfo.ps1 - get-VersionInfo.ps1 - Extract comment-help .NOTES block into a hashtable, key-value split on colons, to provide portable metadata (for New/Update-ScriptFileInfo inputs).
    .NOTES
    Version     : 0.1.0
    Author      : Todd Kadrie
    Website     :	https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
    CreatedDate : 02/07/2019
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    AddedCredit : Based on code & concept by Alek Davis
    AddedWebsite:	https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
    AddedTwitter:
    REVISIONS
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
    .\get-VersionInfo -Path .\path-to\script.ps1
    Explicit file via -Path
    .LINK
    https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
    #>
    PARAM(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to target script (defaults to `$PSCommandPath) [-Path -Path .\path-to\script.ps1]")]
        [ValidateScript( { Test-Path $_ })]$Path,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    $notes = $null ; $notes = @{ } ;
    # Get the .NOTES section of the script header comment.
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

#*------v Merge-Module.ps1 v------
function Merge-Module {

    <#
    .SYNOPSIS
    Merge-Module.ps1 - Merge function .ps1 files into a monolisthic module.psm1 module file, returns a hash with status:$true/$false, and PsmNameBU:The name of a backup of the original .psm1 file (for restoring on failures)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2019-12-10
    FileName    : Merge-Module.ps1
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit : Przemyslaw Klys
    AddedWebsite: https://evotec.xyz/powershell-single-psm1-file-versus-multi-file-modules/
    AddedTwitter:
    REVISIONS
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
    .PARAMETER  ModuleName
    Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]
    .PARAMETER  ModuleSourcePath
    Directory containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]
    .PARAMETER ModuleDestinationPath
    Final monolithic module .psm1 file name to be populated [-ModuleDestinationPath c:\path-to\module\module.psm1]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Outputs a hashtable object containing: Status[$true/$false], PsmNameBU [the name of the backup of the original psm1 file]
    .EXAMPLE
    .\merge-Module.ps1 -ModuleName verb-AAD -ModuleSourcePath C:\sc\verb-AAD\Public -ModuleDestinationPath C:\sc\verb-AAD\verb-AAD -showdebug -whatif ;
    Command line process
    .EXAMPLE
    $pltmergeModule=[ordered]@{
        ModuleName="verb-AAD" ;
        ModuleSourcePath="C:\sc\verb-AAD\Public","C:\sc\verb-AAD\Internal" ;
        ModuleDestinationPath="C:\sc\verb-AAD\verb-AAD" ;
        showdebug=$true ;
        whatif=$($whatif);
    } ;
    Merge-Module @pltmergeModule ;
    Splatted example (from process-NewModule.ps1)
    .LINK
    https://www.toddomation.com
    #>
    param (
        [Parameter(Mandatory = $True, HelpMessage = "Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]")]
        [string] $ModuleName,
        [Parameter(Mandatory = $True, HelpMessage = "Array of directory paths containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]")]
        [array] $ModuleSourcePath,
        [Parameter(Mandatory = $True, HelpMessage = "Directory path in which the final .psm1 file should be constructed [-ModuleDestinationPath c:\path-to\module\module.psm1]")]
        [string] $ModuleDestinationPath,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;

    $rgxSigStart='#\sSIG\s#\sBegin\ssignature\sblock' ; 
    $rgxSigEnd='#\sSIG\s#\sEnd\ssignature\sblock' ; 

    if ($ModuleDestinationPath.GetType().FullName -ne 'System.IO.DirectoryInfo') {
        $ModuleDestinationPath = get-item -path $ModuleDestinationPath ;
    } ;

    $ModuleRootPath = split-path $ModuleDestinationPath -Parent ; 

    $ttl = ($ModuleSourcePath | measure).count ;
    $iProcd = 0 ;

    $ExportFunctions = @() ;
    $PrivateFunctions = @() ;

    $PsmName="$ModuleDestinationPath\$ModuleName.psm1" ;

    $PassStatus = $null ;

    # backup existing & purge the dyn-include block
    if(test-path -path $PsmName){
        $rawSourceLines = get-content -path $PsmName  ;
        $SrcLineTtl = ($rawSourceLines | Measure-Object).count ;
        $PsmNameBU = backup-File -path $PsmName -showdebug:$($showdebug) -whatif:$($whatif) ;
        if (!$PsmNameBU) {throw "FAILURE" } ;

        # this script *appends* to the existing .psm1 file.
        # which by default includes a dynamic include block:
        # detect and drop out the above, for the monolithic version
        $rgxPurgeblockStart = '#Get\spublic\sand\sprivate\sfunction\sdefinition\sfiles\.' ;
        $rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s;';
        $dynIncludeOpen = (ss -Path  $PsmName -Pattern $rgxPurgeblockStart).linenumber ;
        $dynIncludeClose = (ss -Path  $PsmName -Pattern $rgxPurgeBlockEnd).linenumber ;
        if(!$dynIncludeOpen){$dynIncludeClose = 0 } ;
        $updatedContent = @() ; $DropContent=@() ;

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
            and then add the includes to the file
            #>
<#
            $updatedContent=@"
# $($PsmName)

$($oBlkComments.metaBlock)
$($oBlkComments.interText)
$($oBlkComments.cbhBlock)

"@; 
#>
            # doing a herestring assigned to $updatedContent *unwraps* everything!
            # do them in separately
            #"$($oBlkComments.metaBlock)`n$($oBlkComments.interText)`n$($oBlkComments.cbhBlock)" | Add-Content @pltAdd ;
            $updatedContent += "# $(split-path -path $PsmName -leaf)`n"
            if($oBlkComments.metaBlock){$updatedContent += $oBlkComments.metaBlock  |out-string ; } ;
            if($oBlkComments.interText ){$updatedContent += $oBlkComments.interText  |out-string ; } ; 
            $updatedContent += $oBlkComments.cbhBlock |out-string ; 
        } ; 

        if($updatedContent){
            $bRet = Set-FileContent -Text $updatedContent -Path $PsmName -showdebug:$($showdebug) -whatif:$($whatif) ;
            if (!$bRet) {throw "FAILURE" } ;
        } else { 
            $PassStatus += ";ERROR"; 
            $smsg= "NO PARSEABLE METADATA/CBH CONTENT IN EXISTING FILE, TO BUILD UPDATED PSM1 FROM!`n$($PsmName)" ;        
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #$false | write-output ;
            $ReportObj=[ordered]@{
                Status=$false ; 
                PsmNameBU = $PsmNameBU ; 
                PassStatus = $PassStatus ;
            } ; 
            $ReportObj | write-output ;
            Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
        } ; 
    } ;

    # 12:55 PM 12/24/2019default - dirs creation - git doesn't reproduce empty dirs, create if empty (avoids errors later)
    #$DefaultModDirs = "Public","Internal","Classes",".gitignore","Tests",".vscode","Docs","Docs\Cab","Docs\en-US","Docs\Markdown" ; 
    # drop the .git & .vscode dirs, we don't publish those to modules dir
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
            } CATCH {
                $ErrorTrapped = $Error[0] ;
                #write-warning "$(get-date -format 'HH:mm:ss'): Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                $PassStatus += ";ERROR";        
                $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;        
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } 
                $bRetry=$true ; 
                #Continue #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            } ;
            if($bRetry){
                $pltDir.add('force',$true) ; 
                $smsg = "Retry:FORCE:Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $error.clear() ;
                TRY {
                    new-item @pltDir | out-null ;
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    #write-warning "$(get-date -format 'HH:mm:ss'): Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                    $PassStatus += ";ERROR";        
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;        
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $bRetry=$false ; 
                    EXIT #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
                } ;
            } ; 
        } ; 
    } ;  # loop-E

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
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $bRetry=$true ; 
                    $PassStatus += ";ERROR"; 
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
                    } CATCH {
                        $ErrorTrapped = $Error[0] ;
                        $PassStatus += ";ERROR"; 
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
        $sBnrS = "`n#*------v ($($iProcd)/$($ttl)):$($ModuleSource) v------" ;
        $smsg = "$($sBnrS)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $error.clear() ;
        TRY {
            [array]$ComponentScripts = $null ; [array]$ComponentModules = $null ; 
            if($ModuleSource.count){
                $ComponentScripts = Get-ChildItem -Path $ModuleSource\*.ps1 -Recurse -ErrorAction SilentlyContinue | sort name  ;
                $ComponentModules = Get-ChildItem -Path $ModuleSource\*.psm1 -Recurse -ErrorAction SilentlyContinue | sort name;
            } ; 
            $pltAdd = @{
                Path=$PsmName ;
                whatif=$whatif;
            } ;
            foreach ($ScriptFile in $ComponentScripts) {
                $smsg= "Processing:$($ScriptFile)..." ;  
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $ParsedContent = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$null) ;
                # 9:49 AM 12/27/2019 hard strip sigs
                #$ParsedContent = $ParsedContent -replace "#\sSIG\s#\sBegin\ssignature\sblock(.|\n)*(.|\n)*#\sSIG\s#\sEnd\ssignature\sblock","# SIGNATURE REMOVED #"   ; 
                # 1:01 PM 12/27/2019 nope, above doesn't cleanly get all of it, leaves trailing curlies
                # better to detect and throw up
                if($ParsedContent| ?{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                    $smsg= "*WARNING*:SUBFILE`n$($scriptfile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;  
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    exit
                } ; 

                # above is literally the entire AST, unfiltered. Should be ALL parsed entities.
                #$ParsedContent.EndBlock.Extent.Text | Add-Content @pltAdd ;
                #"`n$($ParsedContent.EndBlock.Extent.Text)" | Add-Content @pltAdd ;
                # 7:30 AM 12/27/2019 add demarc comments - this is AST parsed, so it prob doesn't include delimiters
                $sBnrSStart = "`n#*------v $($ScriptFile.name) v------" ;
                $sBnrSEnd = "$($sBnrSStart.replace('-v','-^').replace('v-','^-'))" ;
                "$($sBnrSStart)`n$($ParsedContent.EndBlock.Extent.Text)`n$($sBnrSEnd)" | Add-Content @pltAdd ;

                $AST = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$Null ) ;
                $ASTFunctions =  $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;

                # public & functions = public ; private & internal = private
                if($ModuleSource -match '(Public|Functions)'){
                    $smsg= "$($ScriptFile.name):PUB FUNC:`n$(($ASTFunctions) -join ',' |out-string)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug }  #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $ExportFunctions += $ASTFunctions.name ;
                } elseif($ModuleSource -match '(Private|Internal)'){
                    $smsg= "$($ScriptFile.name):PRIV FUNC:`n$(($ASTFunctions) -join ',' |out-string)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug }  #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $PrivateFunctions += $ASTFunctions.name ;
                } ;
            } ; # loop-E

            foreach ($ModFile in $ComponentModules) {
                $smsg= "Adding:$($ModFile)..." ;  
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $Content = Get-Content $ModFile ;
                # 9:49 AM 12/27/2019 hard strip sigs - nope, doesn't clean, detect and warn instead
                #$Content  = $Content  -replace "#\sSIG\s#\sBegin\ssignature\sblock(.|\n)*(.|\n)*#\sSIG\s#\sEnd\ssignature\sblock","# SIGNATURE REMOVED #"   ; 
                if($Content| ?{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                    $smsg= "*WARNING*:SUBFILE`n$($ModFile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;  
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    exit ; 
                } ; 
                $Content | Add-Content @pltAdd ;
                # by contras, this is NON-AST parsed - it's appending the entire raw file content. Shouldn't need delimiters - they'd already be in source .psm1
                <# $sBnrSStart = "`n#*------v $($ModFile.basename) v------" ;
                $sBnrSEnd = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
                "$($sBnrSStart)`n$($Content)`n$($sBnrSEnd)" | Add-Content @pltAdd ;
                #>
            } ;
            # append the Export-ModuleMember -Function $publicFunctions  ? 
            #"Export-ModuleMember -Function $(($ExportFunctions) -join ',')" | Add-Content @pltAdd ;

            $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            # this is copying the manifest (assumes public & psd1 are in same dir) - Plaster is doing that separately, not needed
            #Copy-Item -Path "$ModuleSource\$ModuleName.psd1" "$ModuleDestinationPath\$ModuleName.psd1" ;

            #$true | write-output ;
            $ReportObj=[ordered]@{
                Status=$true ; 
                PsmNameBU = $PsmNameBU ; 
                PassStatus = $PassStatus ;
            } ; 
            $ReportObj | write-output ;

        } CATCH {
            $ErrorTrapped = $Error[0] ;
            $PassStatus += ";ERROR"; 
            $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;        
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #$false | write-output ;
            $ReportObj=[ordered]@{
                Status=$false ; 
                PsmNameBU = $PsmNameBU ; 
                PassStatus = $PassStatus ;
            } ; 
            $ReportObj | write-output ;
            #Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            Continue ;
        } ;
    } ; # loop-E
}

#*------^ Merge-Module.ps1 ^------

#*------v parseHelp.ps1 v------
function parseHelp {
    <#
    .SYNOPSIS
    parseHelp - Parse Script CBH with get-help -full, return parseHelp obj & $hasExistingCBH boolean
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
    AddedCredit :
    AddedWebsite:
    AddedTwitter:
    REVISIONS
    * 9:11 AM 12/30/2019 parseHelp(): added CBH .INPUTS & .OUTPUTS, specifying returns hash of get-help parsed output, and presence of CBH in the file
    * 10:03 PM 12/2/201919 INIT
    .DESCRIPTION
    parseHelp - Parse Script and prepend new Comment-based-Help keyed to existing contents
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
    $bRet = parseHelp -Path $oSrc.fullname -showdebug:$($showdebug) -whatif:$($whatif) ;
    if($bRet.parseHelp){
        $parseHelp = $bRet.parseHelp
    } ;
    if($bRet.hasExistingCBH){
        $hasExistingCBH = $bRet.hasExistingCBH
    } ;
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
    # Collect existing HelpParsed
    $error.clear() ;
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
        $smsg = "$(($helpparsed | select Category,Name,Synopsis, param*,alertset,details,examples |out-string).trim())" ;
        #$smsg = "CMDLET w`n$((|out-string).trim())" ;
        $smsg = "`$Path.FullName:$($Path.FullName)" ;
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


    }  ;
    $objReturn | Write-Output ;
}

#*------^ parseHelp.ps1 ^------

#*------v profile-FileAST.ps1 v------
function profile-FileAST {
    <#
    .SYNOPSIS
    profile-FileAST - Parse specified Script/Module using Language.FunctionDefinitionAst
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 3:56 PM 12/8/2019
    FileName    :
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit :
    AddedWebsite:
    AddedTwitter:
    REVISIONS
    * 9:04 AM 12/30/2019 profile-FileAST: updated CBH: added .INPUTS & OUTPUTS, including hash properties returned
    * 3:56 PM 12/8/2019 INIT
    .DESCRIPTION
    profile-FileAST - Parse specified Script/Module using Language.FunctionDefinitionAst
    .PARAMETER  File
    Path to script/module file
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Outputs a hashtable object containing: 
    * Parameters : Details on all Parameters in the file
    * Functions : Details on all Functions in the file
    * VariableAssignments : Details on all Variables assigned in the file
    .EXAMPLE
    $ASTProfile = profile-FileAST -File $oSrc.fullname -showdebug:$($showdebug) -whatif:$($whatif) ;
    .LINK
    #>
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to script[-File path-to\script.ps1]")]
        [ValidateScript( { Test-Path $_ })]$File,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    if ($File.GetType().FullName -ne 'System.IO.FileInfo') {
        $File = get-childitem -path $File ;
    } ;

    $sQot = [char]34 ; $sQotS = [char]39 ;
    $NewCBH = $null ; $NewCBH = @() ;

    $AST = [System.Management.Automation.Language.Parser]::ParseFile($File.fullname, [ref]$null, [ref]$Null ) ;

    # parameters declared in the AST PARAM() Block
    $ASTParameters = $ast.ParamBlock.Parameters.Name.variablepath.userpath ;
    $ASTFunctions =  $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
    $AstVariableAssignments = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.VariableExpressionAst]},$true) ;

    $objReturn = [ordered]@{
        Parameters       = $ASTParameters  ;
        Functions        = $ASTFunctions ;
        VariableAssignments       = $AstVariableAssignments ;
    } ;
    $objReturn | Write-Output

}

#*------^ profile-FileAST.ps1 ^------

# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJnu4z3zmOtEu05yVNJT8RJJq
# 76CgggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
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
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRvKC9M
# 5+S+HHSVBNg9lMy9l6FdMTANBgkqhkiG9w0BAQEFAASBgKOfTfmFiEmOu2kcY/il
# pOMzC0/fwPea+NZPg8VboPdzkpqIFxpICDTiwbVtlbAdG1f6DCJ/AmuasefKhuYv
# O65iMyfRK6PHzVOsXBR/T9CvSZoff5FFHajFH0lJVKB0N4eZpxqxdmBGj4voDBfm
# gU4AQolvI5ocHKllOCW9OYnn
# SIG # End signature block
