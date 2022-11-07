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
