#*------v Function convertTo-UnwrappedPS v------
Function convertTo-UnwrappedPS {
    <#
    .SYNOPSIS
    convertTo-UnwrappedPS - Unwrap a a Powershell ScriptBlock at _preexisting_ semi-colon (;) delimiters (does not add semicolons or otherwise attempt to parse the scriptblock into definited lines; just adds CrLF's following the semicolons).
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-11-08
    FileName    : convertTo-UnwrappedPS.ps1
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-text
    Tags        : Powershell,Text
    AddedCredit : REFERENCE
    AddedWebsite:	URL
    AddedTwitter:	URL
    REVISIONS
    * 12:44 PM 6/17/2022 update CBH; move verb-text -> verb-dev
    * 9:38 AM 11/22/2021 ren unwrap-ps -> convertTo-UnwrappedPS 
    * 11:09 AM 11/8/2021 init
    .DESCRIPTION
    convertTo-UnwrappedPS - Unwrap a a Powershell ScriptBlock at _preexisting_ semi-colon (;) delimiters (does not add semicolons or otherwise attempt to parse the scriptblock into definited lines; just adds CrLF's following the semicolons).
    .PARAMETER  ScriptBlock
    Semi-colon-delimited ScriptBlock of powershell to be wrapped at 
    .EXAMPLE
    PS>  $text=convertTo-UnwrappedPS -ScriptBlock "write-host 'yea';`ngci 'c:\somefile.txt';" ;
    Unwrap the specified scriptblock at the semicolons. 
    .LINK
    https://github.com/tostka/verb-Text
    #>
    [CmdletBinding()]
    [Alias('unwrap-PS')]
    param(
        [Parameter(Position=0,Mandatory=$false,HelpMessage="ScriptBlock
    Semi-colon-delimited ScriptBlock of powershell to be unwrapped (sub-out ;`n with ;) [-ScriptBlock 'c:\path-to\script.ps1']")]
        [Alias('Code')]
        [string]$ScriptBlock
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
    # rgx replace all special chars, to make them literals, before doing any -replace (graveaccent escape ea)
    #$ScriptBlock = $scriptblock -replace '([$*\~;(%?.:@/]+)','`$1' ;
    $ScriptBlock=convertTo-EscapedPSText -ScriptBlock $ScriptBlock -Verbose:($PSBoundParameters['Verbose'] -eq $true) ; 
    # functional AHK: StringReplace clipboard, clipboard, `;, `;`r`n, All
    $splitAt = ";$([Environment]::NewLine)" ; 
    
    $replaceWith = ";" ; 
    # ";`r`n"  ; 
    $ScriptBlock = $ScriptBlock | Foreach-Object {
            $_ -replace $splitAt, $replaceWith ;
    } ; 
    # then put the $'s back (stays dbld):
    #$ScriptBlock = $ScriptBlock.Replace('$$', '$')
    # reverse escapes - have to use dbl-quotes around escaped backtick (dbld), or it doesn't become a literal
    #$ScriptBlock = $scriptblock -replace "``([$*\~;(%?.:@/]+)",'$1'; 
    $ScriptBlock=convertFrom-EscapedPSText -ScriptBlock $ScriptBlock  -Verbose:($PSBoundParameters['Verbose'] -eq $true) ;  
    $ScriptBlock | write-output ; 
} ; #*------^ END Function convertTo-UnwrappedPS ^------
