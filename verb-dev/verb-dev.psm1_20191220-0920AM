# verb-dev.psm1


  <#
  .SYNOPSIS
  verb-dev - Development-related generic functions
  .NOTES
  Version     : 1.0.0
  Author      : Todd Kadrie
  Website     :	https://www.toddomation.com
  Twitter     :	@tostka
  CreatedDate : 12/18/2019
  FileName    : verb-dev.psm1
  License     : MIT
  Copyright   : (c) 12/18/2019 Todd Kadrie
  Github      : https://github.com/tostka
  AddedCredit : REFERENCE
  AddedWebsite:	REFERENCEURL
  AddedTwitter:	@HANDLE / http://twitter.com/HANDLE
  REVISIONS
  * 12/18/2019 - 1.0.0
  * 5:22 PM 12/15/2019initial vers includes Get-CommentBlocks, parseHelp, profile-FileAST, build-VSCConfig, Merge-Module
  .DESCRIPTION
  verb-dev - Development-related generic functions
  .PARAMETER  PARAMNAME
  PARAMDESC
  .PARAMETER  Mbx
  Mailbox identifier [samaccountname,name,emailaddr,alias]
  .PARAMETER  Computer
  Computer Name [-ComputerName server]
  .PARAMETER  ServerFqdn
  Server Fqdn (24-25char) [-serverFqdn lynms650.global.ad.toro.com)] 
  .PARAMETER  Server
  Server NBname (8-9chars) [-server lynms650)]
  .PARAMETER  SiteName
  Specify Site to analyze [-SiteName (USEA|GBMK|AUSYD]
  .PARAMETER  Ticket
  Ticket # [-Ticket nnnnn]
  .PARAMETER  Path
  Path [-path c:\path-to\]
  .PARAMETER  File
  File [-file c:\path-to\file.ext]
  .PARAMETER  String
  2-30 char string [-string 'word']
  .PARAMETER  Credential
  Credential (PSCredential obj) [-credential ]
  .PARAMETER  Logonly
  Run a Test no-change pass, and log results [-Logonly]
  .PARAMETER  FORCEALLPINS
  Reset All PINs (boolean) [-FORCEALLPINS:True]
  .PARAMETER Whatif
  Parameter to run a Test no-change pass, and log results [-Whatif switch]
  .PARAMETER ShowProgress
  Parameter to display progress meter [-ShowProgress switch]
  .PARAMETER ShowDebug
  Parameter to display Debugging messages [-ShowDebug switch]
  .INPUTS
  None
  .OUTPUTS
  None
  .EXAMPLE
  .EXAMPLE
  .LINK
  https://github.com/tostka/verb-dev
  #>


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
    * 8:28 PM 11/17/2019 INIT
    .DESCRIPTION
    Get-CommentBlocks - Write output string to specified File
    .PARAMETER  Text
    RawSourceLines from the target script file (as gathered with get-content
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
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
                    $smsg = "Existing CBH block located and tagged" ;
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
function Merge-Module {

    <#
    .SYNOPSIS
    Merge-Module.ps1 - Merge function .ps1 files into a monolisthic module.psm1 module file
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
    *8:50 PM 12/18/2019 sorted hard-coded verb-aad typo 
    2:54 PM 12/11/2019 rewrote, added backup of psm1, parsing out the stock dyn-include code from the orig psm1, leverages fault-tolerant set-fileContent(), switched sourcepaths to array type, and looped, detecting public/internal by path and prepping for the export list.
    * 2018/11/06 Przemyslaw Klys posted version
    .DESCRIPTION
    .PARAMETER  ModuleName
    Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]
    .PARAMETER  ModuleSourcePaths
    Directory containing .ps1 function files to be combined [-ModuleSourcePaths c:\path-to\module\Public]
    .PARAMETER ModuleDestinationPath
    Final monolithic module .psm1 file name to be populated [-ModuleDestinationPath c:\path-to\module\module.psm1]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    .\merge-Module.ps1 -ModuleName verb-AAD -ModuleSourcePaths C:\sc\verb-AAD\Public -ModuleDestinationPath C:\sc\verb-AAD\verb-AAD -showdebug -whatif ;
    .LINK
    https://www.toddomation.com
    #>
    param (
        [Parameter(Mandatory = $True, HelpMessage = "Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]")]
        [string] $ModuleName,
        [Parameter(Mandatory = $True, HelpMessage = "Array of directory paths containing .ps1 function files to be combined [-ModuleSourcePaths c:\path-to\module\Public]")]
        [array] $ModuleSourcePaths,
        [Parameter(Mandatory = $True, HelpMessage = "Directory path in which the final .psm1 file should be constructed [-ModuleDestinationPath c:\path-to\module\module.psm1]")]
        [string] $ModuleDestinationPath,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;


    if ($ModuleDestinationPath.GetType().FullName -ne 'System.IO.DirectoryInfo') {
        $ModuleDestinationPath = get-item -path $ModuleDestinationPath ;
    } ;

    $ttl = ($ModuleSourcePaths | measure).count ;
    $iProcd = 0 ;

    $ExportFunctions = @() ;
    $PrivateFunctions = @() ;

    $PsmName="$ModuleDestinationPath\$ModuleName.psm1" ;

    # backup existing & purge the dyn-include block
    if(test-path -path $PsmName){
        $rawSourceLines = get-content $PsmName  ;
        $SrcLineTtl = ($rawSourceLines | Measure-Object).count ;
        $bRet = backup-File -path $PsmName -showdebug:$($showdebug) -whatif:$($whatif) ;
        if (!$bRet) {throw "FAILURE" } ;

        # this script *appends* to the existing .psm1 file.
        # which by default includes a dynamic include block:
        <#
        #Get public and private function definition files.
        $functionFolders = @('Public', 'Internal', 'Classes') ;
        ForEach ($folder in $functionFolders) {
            $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder ;
            If (Test-Path -Path $folderPath) {
                Write-Verbose -Message "Importing from $folder" ;
                $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1'  ;
                ForEach ($function in $functions) {
                    Write-Verbose -Message "  Importing $($function.BaseName)" ;
                    . $($function.FullName) ;
                } ;
            } ;
        } ;
        $publicFunctions = (Get-ChildItem -Path "$PSScriptRoot\Public" -Filter '*.ps1').BaseName ;
        Export-ModuleMember -Function $publicFunctions ;
        #>
        # detect and drop out the above, for the monolithic version
        $rgxPurgeblockStart = '#Get\spublic\sand\sprivate\sfunction\sdefinition\sfiles\.' ;
        $rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s;';
        $dynIncludeOpen = (ss -Path  $PsmName -Pattern $rgxPurgeblockStart).linenumber ;
        $dynIncludeClose = (ss -Path  $PsmName -Pattern $rgxPurgeBlockEnd).linenumber ;
        if(!$dynIncludeOpen){$dynIncludeClose = 0 } ;
        $updatedContent = @() ; $DropContent=@() ;
        $updatedContent = $rawSourceLines[0..($dynIncludeOpen-2)] ;
        $updatedContent += $rawSourceLines[($dynIncludeClose)..$Srclinettl] ;
        $DropContent = $rawsourcelines[$dynIncludeOpen..$dynIncludeClose] ;
        if($showdebug){
            $smsg= "`$DropContent:`n$($DropContent|out-string)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug } ; #Error|Warn|Debug
        } ;
        $bRet = Set-FileContent -Text $updatedContent -Path $PsmName -showdebug:$($showdebug) -whatif:$($whatif) ;
        if (!$bRet) {throw "FAILURE" } ;
    } ;

    foreach ($ModuleSourcePath in $ModuleSourcePaths) {

        $iProcd++ ;

        if ($ModuleSourcePath.GetType().FullName -ne 'System.IO.DirectoryInfo') {
            $ModuleSourcePath = get-item -path $ModuleSourcePath ;
        } ;
        $sBnrS = "`n#*------v ($($iProcd)/$($ttl)):$($ModuleSourcePath) v------" ;
        $smsg = "$($sBnrS)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug **
        $error.clear() ;
        TRY {


            [array]$ComponentScripts = Get-ChildItem -Path $ModuleSourcePath\*.ps1 -Recurse -ErrorAction SilentlyContinue   ;
            [array]$ComponentModules = Get-ChildItem -Path $ModuleSourcePath\*.psm1 -Recurse -ErrorAction SilentlyContinue  ;

            $pltAdd = @{
                Path=$PsmName ;
                whatif=$whatif;
            } ;
            foreach ($ScriptFile in $ComponentScripts) {
                $ParsedContent = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$null) ;
                # above is literally the entire AST, unfiltered. Should be ALL parsed entities.
                #$Functions = $ParsedContent.EndBlock.Extent.Text  ;
                #$Functions | Add-Content @pltAdd ;
                $ParsedContent.EndBlock.Extent.Text | Add-Content @pltAdd ;

                # public & functions = public ; private & internal = private
                if($ModuleSourcePath -match '(Public|Functions)'){
                    $AST = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$Null ) ; 
                    $ASTFunctions =  $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
                    $ExportFunctions += $ASTFunctions.name ;
                } elseif($ModuleSourcePath -match '(Private|Internal)'){
                    $smsg= "PRIV FUNC:`n$(($ASTFunctions) -join ',' |out-string)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug } ; #Error|Warn|Debug
                } ;
            } ; # loop-E

            foreach ($ModFile in $ComponentModules) {
                $Content = Get-Content $ModFile ;
                $Content | Add-Content @pltAdd ;
            } ;
            # append the Export-ModuleMember -Function $publicFunctions  ? 
            #"Export-ModuleMember -Function $(($ExportFunctions) -join ',')" | Add-Content @pltAdd ;

            $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug

            # this is copying the manifest (assumes public & psd1 are in same dir) - Plaster is doing that separately, not needed
            #Copy-Item -Path "$ModuleSourcePath\$ModuleName.psd1" "$ModuleDestinationPath\$ModuleName.psd1" ;

            $true | write-output ;

        } CATCH {
            Write-Error "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            $false | write-output ;
            #Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            Continue ;
        } ;
    } ; # loop-E
}
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
    * 10:03 PM 12/2/201919 INIT
    .DESCRIPTION
    parseHelp - Parse Script and prepend new Comment-based-Help keyed to existing contents
    .PARAMETER  Path
    Path to script
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
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
    * 3:56 PM 12/8/2019 INIT
    .DESCRIPTION
    profile-FileAST - Parse specified Script/Module using Language.FunctionDefinitionAst
    .PARAMETER  File
    Path to script/module file
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
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

# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUowVHTni3OaVbZX9l7RfHYGg5
# 4XugggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
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
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBS7bKvR
# Ul/9HbFLVKGKqxV8KG3H8zANBgkqhkiG9w0BAQEFAASBgB7YMMl332K5UTuH3SLw
# icmCr2YqvCxsAmDExDst56So3UulkmY408JSDTrGj4o3LdgqoWeQgK2XtnTq3553
# EU/03jJDjAPYy0rW1FcXp64nlhAG1hhAukN3rKnOpA7rUO8kiOsTz8LD0UbGcd/M
# u36dGAkSk9Z2TO+ByUyrRRVy
# SIG # End signature block
