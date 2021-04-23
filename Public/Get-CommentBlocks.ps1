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