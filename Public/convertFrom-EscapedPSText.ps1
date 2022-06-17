#*------v convertFrom-EscapedPSText.ps1 v------
Function convertFrom-EscapedPSText {
    <#
    .SYNOPSIS
    convertFrom-EscapedPSText - convert a previously backtick-escaped scriptblock of Powershell code text, to an un-escaped equivelent - specifically removing backtick-escape found on all special characters [$*\~;(%?.:@/]. 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-11-08
    FileName    : convertFrom-EscapedPSText.ps1
    License     : MIT License
    Copyright   : (c) 2021 Todd Kadrie
    Github      : https://github.com/tostka/verb-text
    Tags        : Powershell,Text
    AddedCredit : REFERENCE
    AddedWebsite:	URL
    AddedTwitter:	URL
    REVISIONS
    * 12:44 PM 6/17/2022 update CBH; move verb-text -> verb-dev
    * 2:10 PM 3/1/2022 updated the ScriptBlock param to string-array [string[]], preserves the multi-line nature of original text (otherwise, ps coerces arrays into single-element strings)
    * 11:09 AM 11/8/2021 init
    .DESCRIPTION
    convertFrom-EscapedPSText - convert a previously backtick-escaped scriptblock of Powershell code text, to an un-escaped equivelent - specifically removing backtick-escape found on all special characters [$*\~;(%?.:@/]. 
    Intent is to run this *after* to running a -replace pass on a given piece of pre-escaped Powershell code as text (parsing & editing scripts with powershell itself), to ensure the special characters in the block are no longer treated as literal text. Prior to doing search and replace, one would typically have escaped the special characters by running convertTo-EscapedPSText() on the block. 
    .PARAMETER  ScriptBlock
    Semi-colon-delimited ScriptBlock of powershell to be wrapped at 
    .EXAMPLE
    PS>  # pre-escape PS special chars
    PS>  $ScriptBlock = get-content c:\path-to\script.ps1 ; 
    PS>  $ScriptBlock=convertTo-EscapedPSText -ScriptBlock $ScriptBlock ; 
    PS>  $splitAt = ";" ; 
    PS>  $replaceWith = ";$([Environment]::NewLine)" ; 
    PS>  # ";`r`n"  ; 
    PS>  $ScriptBlock = $ScriptBlock | Foreach-Object {$_ -replace $splitAt, $replaceWith } ; 
    PS>  $ScriptBlock=convertFrom-EscapedPSText -ScriptBlock $ScriptBlock ; 
    PS>  
    Load a script file into a $ScriptBlock vari, escape special characters in the $Scriptblock, run a wrap on the text at semicolons (replace ';' with ';`n), then unescape the specialcharacters in the scriptblock, back to original functional state. 
    .LINK
    https://github.com/tostka/verb-Text
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$false,HelpMessage="ScriptBlock
    Semi-colon-delimited ScriptBlock of powershell to be wrapped at [-ScriptBlock 'c:\path-to\script.ps1']")]
        [Alias('Code')]
        [string[]]$ScriptBlock
    )  ; 
    if(-not $ScriptBlock){
        $ScriptBlock= (get-clipboard) # .trim().replace("'",'').replace('"','') ;
        if($ScriptBlock){
            write-verbose "No -ScriptBlock specified, detected text on clipboard:`n$($ScriptBlock)" ;
        } else {
            write-warning "No -path specified, nothing suitable found on clipboard. EXITING!" ;
            Break ;
        } ;
    } else {
        write-verbose "ScriptBlock:$($ScriptBlock)" ;
    } ;
    # issue specific to PS, -replace isn't literal, see's $ as variable etc control char
    # to escape them, have to dbl: $password.Replace('$', $$')
    #$ScriptBlock = $ScriptBlock.Replace('$', '$$');
    # rgx replace all special chars, to make them literals, before doing the replace (graveaccent escape ea matched char in the [$*\~;(%?.:@/] range)
    $ScriptBlock = $scriptblock -replace "``([$*\~;(%?.:@/]+)",'$1'; 
    $ScriptBlock | write-output ; 
}

#*------^ convertFrom-EscapedPSText.ps1 ^------