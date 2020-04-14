# verb-dev.psm1


<#
.SYNOPSIS
VERB-dev - Development PS Module-related generic functions
.NOTES
Version     : 1.4.20
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

#*======v FUNCTIONS v======



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
    #Requires -Version 3
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

    #Requires -Version 3
    Param(
        [Parameter(Position=0,MandaTory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Script to be parsed [path-to\script.ps1]")][ValidateNotNullOrEmpty()]
        $ParseFile
        ,[Parameter(Position=1,MandaTory=$True,HelpMessage="Function name to be found and displayed from ParseFile")]
        $functionName
    )  ;


    # 2:07 PM 8/31/2016 alt code:
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($ParseFile,[ref]$null,[ref]$Null ) ;
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

    $sPre="$("=" * 50)`n#*------v Function $($matchfunc.name) from Script:$($ParseFile) v------" ;
    $sPost="#*------^ END Function $($matchfunc.name) from Script:$($ParseFile) ^------ ;`n$("=" * 50)" ;

    # here string seems to make it crap out, just append together
    $sOut = $null ;
    $sOut += "$($sPre)`nFunction $($matchfunc.name) " ;
    $sOut += "$($matchfunc.Body) $($sPost)" ;

    write-verbose -verbose:$true "Script:$($ParseFile): Matched Function:$($functionName) " ;
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

    #Requires -Version 3
    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Script to be parsed [path-to\script.ps1]")][ValidateNotNullOrEmpty()]
        $ParseFile
    )  ;

    # 2:07 PM 8/31/2016 alt code:
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($ParseFile, [ref]$null, [ref]$Null ) ;
    $funcsInFile = $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
    # this variant pulls commands v functions
    #$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)

    foreach ($func in $funcsInFile) {
        $func | write-output ;
    } ;
}

#*------^ get-FunctionBlocks.ps1 ^------

#*------v get-ScriptProfileAST.ps1 v------
function get-ScriptProfileAST {
    <#
    .SYNOPSIS
    get-ScriptProfileAST - Parse specified Script/Module using Language.FunctionDefinitionAst
    .NOTES
    Version     : 1.1.0
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
    # 5:25 PM 2/29/2020 ren profile-FileASt -> get-ScriptProfileAST (aliased orig name)
    # * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:04 AM 12/30/2019 profile-FileAST: updated CBH: added .INPUTS & OUTPUTS, including hash properties returned
    * 3:56 PM 12/8/2019 INIT
    .DESCRIPTION
    profile-FileAST - Parse specified Script/Module using Language.FunctionDefinitionAst
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
    Outputs a hashtable object containing:
    * Parameters : Details on all Parameters in the file
    * Functions : Details on all Functions in the file
    * VariableAssignments : Details on all Variables assigned in the file
    .EXAMPLE
    $ASTProfile = profile-FileAST -File c:\pathto\script.ps1 -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
    Return the raw $ASTProfile object to the piepline (default behavior)
    .EXAMPLE
    $FunctionNames = (get-scriptprofileast -File c:\usr\work\exch\scripts\verb-dev.ps1 -Functions).functions.name ;
    Return the Functions within the specified script, and select the name properties of the functions object returned.
    .EXAMPLE
    $AliasAssignments = (get-scriptprofileast -File c:\usr\work\exch\scripts\verb-dev.ps1 -Aliases).Aliases.extent.text;
    Return the set/new-Alias commands from the specified script, selecting the full syntax of the command
    .EXAMPLE
    $WhatifLines = ((get-scriptprofileast -File c:\usr\work\exch\scripts\verb-dev.ps1 -GenericCommands).GenericCommands | ?{$_.extent -like '*whatif*' } | select -expand extent).text
    Return any GenericCommands from the specified script, that have whatif within the line
    .EXAMPLE
    $bRet = ((get-scriptprofileast -File c:\usr\work\exch\scripts\verb-dev.ps1 -All) ;
    $bRet.functions.name ;
    $bret.variables.extent.text
    $bret.aliases.extent.text

    Return ALL variant objects - Functions, Parameters, Variables, aliases, GenericCommands - from the specified script, and output the function names, variable names, and alias assignement commands
    .LINK
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to script[-File path-to\script.ps1]")]
        [ValidateScript( { Test-Path $_ })]$File,
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
        if ($File.GetType().FullName -ne 'System.IO.FileInfo') {
            $File = get-childitem -path $File ;
        } ;
    } ;
    PROCESS {
        $AST = [System.Management.Automation.Language.Parser]::ParseFile($File.fullname, [ref]$null, [ref]$Null ) ;

        $objReturn = [ordered]@{ } ;

        if ($Functions -OR $All) {
            $ASTFunctions = $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
            $objReturn.add('Functions', $ASTFunctions) ;
        } ;
        if ($Parameters -OR $All) {
            $ASTParameters = $ast.ParamBlock.Parameters.Name.variablepath.userpath ;
            $objReturn.add('Parameters', $ASTParameters) ;
        } ;
        if ($Variables -OR $All) {
            $AstVariableAssignments = $ast.FindAll( { $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true) ;
            $objReturn.add('Variables', $AstVariableAssignments) ;
        } ;
        if ($($Aliases -OR $GenericCommands) -OR $All) {
            $ASTGenericCommands = $ast.FindAll( { $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) ;
            if ($Aliases -OR $All) {
                $ASTAliasAssigns = ($ASTGenericCommands | ? { $_.extent.text -match '(set|new)-alias' }) ;
                $objReturn.add('Aliases', $ASTAliasAssigns) ;
            } ;
            if ($GenericCommands -OR $All) {
                $objReturn.add('GenericCommands', $ASTGenericCommands) ;
            } ;
        } ;
        $objReturn | Write-Output ;
    } ;
    END { } ;
} ; #*------^ END Function get-ScriptProfileAST ^------
if (!(get-alias -name "profile-FileAST" -ea 0 )) { Set-Alias -Name 'profile-FileAST' -Value 'get-ScriptProfileAST' ; }

#*------^ get-ScriptProfileAST.ps1 ^------

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

#*------v load-Module.ps1 v------
function load-Module {
    <#
    .SYNOPSIS
    load-Module - Import-Module, with Find- & Install-, when not available to load.
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2019-8-28
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit : REFERENCE
    AddedWebsite:	URL
    AddedTwitter:	URL
    REVISIONS
    * 7:29 AM 1/29/2020 added pshelp, version etc (copying into verb-dev)
    * 8/28/2019 init
    .DESCRIPTION
    load-Module - Import-Module, with Find- & Install-, when not available to load.
    .PARAMETER  Module
    Module name to be loaded or installed [ -Module Azure]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    .\load-Module Azure
    .LINK
    https://github.com/tostka
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Module name to be loaded or installed [ -Module Azure]")]
        [ValidateNotNullOrEmpty()][string]$Module,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    $Verbose = ($VerbosePreference -eq "Continue") ; 
    if!(Get-Module -Name $Module){
        if (Get-Module -Name $Module -ListAvailable) {
            Import-Module $Module ;
        } else {
            write-host -foregroundcolor RED "$((get-date).ToString('HH:mm:ss')):ERROR!:The $($Module) module is *NOT* INSTALLED!.`n Checking for available copy..." ;
            if(find-module $Module){
                write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Would you *LIKE* to install the $Module module *NOW*?" ;
                $bRet = Read-Host "Enter YYY to continue. Anything else will exit"
                if ($bRet.ToUpper() -eq "YYY") {
                    Write-host "Installing Module:$($Module)`nInstall-Module -Name $($Module) -AllowClobber -Scope CurrentUser..."
                    Install-Module -Name $Module -AllowClobber -Scope CurrentUser
                } else {
                    write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Install declined. Aborting script pass.`nThe required $($Module) module can be installed via the`nInstall-Module -Name $($Module) -AllowClobber -Scope CurrentUser`ncommand.`nEXITING"
                    # exit <asserted exit error #>
                    exit 1
                } # if-block end
            } else {
                write-host -foregroundcolor RED "$((get-date).ToString('HH:mm:ss')):ERROR!:The $($Module) module was not found at the routine Repositories. `nPlease locate a copy and install it before attempting to use this script" ;
            } ;
        } ;
    } ;
}

#*------^ load-Module.ps1 ^------

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

    if ($ModuleDestinationPath.GetType().FullName -ne 'System.IO.DirectoryInfo') {
        $ModuleDestinationPath = get-item -path $ModuleDestinationPath ;
    } ;

    $ModuleRootPath = split-path $ModuleDestinationPath -Parent ; 

    $ttl = ($ModuleSourcePath | measure).count ;
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
        $PsmNameBU = backup-File -path $PsmName -showdebug:$($showdebug) -whatif:$($whatif) ;
        if (!$PsmNameBU) {throw "FAILURE" } ;

        # this script *appends* to the existing .psm1 file.
        # which by default includes a dynamic include block:
        # detect and drop out the above, for the monolithic version
        $rgxPurgeblockStart = '#Get\spublic\sand\sprivate\sfunction\sdefinition\sfiles\.' ;
        # stock dyanmic export of collected functions
        #$rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s;';
        # updated version of dyn end, that also explicitly exports -alias *
        $rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s-Alias\s\*\s;\s'
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

            # Post CBH always add the helper/alias-export command (functions are covered in the psd1 manifest, dyn's have in the template)
            $PostCBHBlock=@"

`$script:ModuleRoot = `$PSScriptRoot ;
`$script:ModuleVersion = (Import-PowerShellDataFile -Path (get-childitem `$script:moduleroot\*.psd1).fullname).moduleversion ;

#*======v FUNCTIONS v======

"@ ; 
            $updatedContent += $PostCBHBlock |out-string ; 
            
        } ;  # if-E dyn/monolithic source psm1


        if($updatedContent){
            $bRet = Set-FileContent -Text $updatedContent -Path $PsmNameTmp -showdebug:$($showdebug) -whatif:$($whatif) ;
            if (!$bRet) {throw "FAILURE" } else {
                $PassStatus += ";UPDATED:Set-FileContent "; 
            }  ;
        } else { 
            $PassStatus += ";ERROR:Set-FileContent"; 
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
                $ComponentScripts = Get-ChildItem -Path $ModuleSource\*.ps1 -Recurse -ErrorAction SilentlyContinue | sort name  ;
                $ComponentModules = Get-ChildItem -Path $ModuleSource\*.psm1 -Recurse -ErrorAction SilentlyContinue | sort name;
            } ; 
            $pltAdd = @{
                Path=$PsmNameTmp ;
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

    # append the Export-ModuleMember -Function $publicFunctions  (psd1 functionstoexport is functional instead),
    $smsg= "(Updating Psm1 Export-ModuleMember -Function to reflect Public modules)" ;  
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #"Export-ModuleMember -Function $(($ExportFunctions) -join ',')" | Add-Content @pltAdd ;
    # Collect & set explicitly in the psm1, the psd1 Set-ModuleFunctoin buildhelper isn't doing the full set, only above. 
    # stick the Alias * in there too, force it as the psd1 spec's simply override the explicits in the psm1
    
    #"`nExport-ModuleMember -Function $(($ExportFunctions) -join ',') -Alias *" | Add-Content @pltAdd ;
    
    # tack in footerblock to the merged psm1 (primarily export-modulemember -alias * ; can also be any function-trailing content you want in the psm1)
    $FooterBlock=@"

#*======^ END FUNCTIONS ^======

Export-ModuleMember -Function $(($ExportFunctions) -join ',') -Alias *

"@ ; 

    if(-not($NoAliasExport)){
        $smsg= "Adding:FooterBlock..." ;  
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #$updatedContent += $FooterBlock |out-string ; 
        $pltAdd = @{
            Path=$PsmNameTmp ;
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

    # update the manifest too: # should be forced array: FunctionsToExport = @('build-VSCConfig','Get-CommentBlocks','get-VersionInfo','Merge-Module','parseHelp')
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

    #if($PassStatus.tolower().contains('error')){ # not properly matching, switch to ss regex, the appends are line per append, multiline seems to break contains.
    if($PassStatus.tolower() | select-string '.*error.*'){
        $smsg = "ERRORS LOGGED, ABORTING UPDATE OF ORIGINAL .PSM1!:`n$($pltCpy.Destination)" ; 
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug 
        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    } elseif(!$whatif) { 
        if(test-path $PsmNameTmp){
            $pltCpy = @{
                Path=$PsmNameTmp ;
                Destination=$PsmName ; 
                whatif=$whatif;
                ErrorAction="STOP" ; 
            } ;
            $smsg = "Processing error free: Overwriting temp .psm1 with temp copy`ncopy-item w`n$(($pltCpy|out-string).trim())" ; 
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
            $smsg = "UNABLE TO LOCATE temp .psm1!:`n$($pltCpy.path)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug 
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            $PassStatus += ";test-path $PsmNameTmp:ERROR"; 
        } ;  
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
            $smsg = "UNABLE TO LOCATE temp .psm1!:`n$($pltCpy.path)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug 
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            $PassStatus += ";test-path $PsdNameTmp:ERROR"; 
        } ;  
    } else {
        $smsg = "(whatif:skipping updates)" ; 
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    }; 
    $ReportObj=[ordered]@{
        Status=$true ; 
        PsmNameBU = $PsmNameBU ; 
        PassStatus = $PassStatus ;
    } ; 
    if($PassStatus.tolower() | select-string '.*error.*'){
        $ReportObj.Status=$false ; 
    } ; 
    $ReportObj | write-output ;
}

#*------^ Merge-Module.ps1 ^------

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

#*======^ END FUNCTIONS ^======

Export-ModuleMember -Function build-VSCConfig,check-PsLocalRepoRegistration,Get-CommentBlocks,get-FunctionBlock,get-FunctionBlocks,get-ScriptProfileAST,get-VersionInfo,load-Module,Merge-Module,new-CBH,New-GitHubGist,parseHelp -Alias *


# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU16uH9s9NWafzsAHCG3/XvxGq
# eCagggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
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
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTEK6Pa
# JjVJRvUz7GeK3bbJI1nnFzANBgkqhkiG9w0BAQEFAASBgIMoIkPMUMY5gBX8q09B
# HIXE+HfT1315OQfp1GPc4Rd/dWoX6iH1TmofKC/4+IdnBHKyalujnkSS1zThGXgB
# 4GbRA3O+mRJsZxNWySXP+V0ZVmHO5XbfGo6QQCAjjOIxAJ7I806dZ01rGTrH+0hV
# ibc6VYOYwRtaWzqHSxUWE0I3
# SIG # End signature block
