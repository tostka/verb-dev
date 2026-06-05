# Generate-ScriptMarkdownHelp.ps1

function Generate-ScriptMarkdownHelp {    
    <#
    .SYNOPSIS
    The function that generated the Markdown help in this repository. (see Example for usage).
    Generates markdown help for each function containing comment based help in the module (Description not empty) within a folder recursively and a summary table for the main README.md
    WRITES OUTPUT TO THE CURRENT _INSTALLED_ COPY OF THE MODULE, IN A NEW .\DOCS Directory.
    On completion moves the generated files back to C:\sc\xxx\Docs\Markdown
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : VERB-NOUN.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : DBremen 
    AddedWebsite: https://github.com/DBremen/PSDiff/blob/master/PSDiff/docs/ConvertFrom-DiffToText.md
    AddedTwitter: URL
    REVISIONS
    * 06/05/2026 08:54:37 init, added param meta
    * Oct 7, 2019 DBremen posted git .ps1 (w/in their psdiff repo)
    .DESCRIPTION
    platyPS is used to generate the function level help + the README.md is generated "manually".    
    .PARAMETER
    Module
    Name of the Module to generate help for.
    .PARAMETER RepoUrl
    Url for the Git repository homepage
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    .EXAMPLE
    PS> Generate-ScriptMarkdownHelp -Module SearchLucene  -RepoUrl https://github.com/DBremen/SearchLucene
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,HelpMessage="Module name to be processed[-module VERB-MODNAME]")]
            $Module,
        [Parameter(Mandatory=$True,HelpMessage="HELPMSG[-RepoUrl https://github.com/USER/verb-NAME]")]
            $RepoUrl
    )
    $ModPath = 'C:\sc\verb-dev\VERB-dev\verb-dev.psm1' ;
    $MDDocPath = "$(split-path (split-path $modpath))\Docs\Markdown" ;
    $summaryTable = @"
# Verb-Dev
Developoment utility functions module

For usage check the documentation and the tests.
The Verb-Dev module exports the following functions:


| Function | Synopsis | Documentation |
| --- | --- | --- |
"@
    $dcLen = 80 ; $dcInterv = 5 ;
    if(-not $whPASS){$whPASS = @{ Object = "$([Char]8730) PASS`n" ; ForegroundColor = 'Green' ; NoNewLine = $true  } }
    if(-not (gcm get-remainder -ea 0)){function get-Remainder{ [Alias('grmdr')] Param( [Parameter(Position=0)][int]$number, [Parameter(Position=1)]$divisor) [math]::ieeeremainder($number,$divisor) | write-output} } ;

    Import-Module platyps
    $htCheck = @{ }
    Import-Module $ModPath
    $functions = Get-Command -Module $Module
    write-host "Processing functions for configured CBH[" ; $xdots = 0 ; 
    foreach ($function in $functions) {
        try {
            if($help = Get-Help $function.Name | Where-Object { $_.Name -eq $function.Name } -ErrorAction Stop){
                $dchar = '+' ; 
            }else{
                $dchar = '-' ; 
            }
        }catch {
            $dchar = 'x' ; 
            continue
        }
        $xdots++ ; if((grmdr $xdots $dcLen) -eq 0){write-host -fo yel $dchar}elseif((grmdr $xdots $dcInterv) -eq 0){write-host -fo yel $xdots -nonewline}else{write-host -nonewline -fo yel $dchar} ;
        if ($help.description -ne $null) {
            $htCheck[$function.Name] += 1
            $link = $help.relatedLinks 
            if ($link) {
                $link = $link.navigationLink.uri | Where-Object { $_ -like '*powershellone*' }
            }
            $mdFile = $function.Name + '.md'
            $summaryTable += "`n| $($function.Name) | $($help.Synopsis) | $("[Link]($($RepoUrl)/blob/master/$Module/docs/$mdFile)") |"
        }
    }
    write-host "]" ; 
    $docFolder = "$(Split-Path (Get-Module $Module)[0].Path)\docs"
    $summaryTable | Set-Content "$(Split-Path(Split-Path $docFolder -Parent)-Parent)/README.md" -Force
    $documenation = New-MarkdownHelp -Module $Module -OutputFolder $docFolder -Force
    $xdots = 0 ; $dchar = "." ; 
    write-host -fore white "(Triming file headers):[";
    foreach ($file in (get-childitem $docFolder)) {
        $text = (Get-Content -Path $file.FullName | Select-Object -Skip 6) | Set-Content $file.FullName -Force
        $xdots++ ; if((grmdr $xdots $dcLen) -eq 0){write-host -fo yel $dchar}elseif((grmdr $xdots $dcInterv) -eq 0){write-host -fo yel $xdots -nonewline}else{write-host -nonewline -fo yel $dchar} ;
    }
    write-host -fore white -nonewline "]"; write-host @whpass
    #sanity check if help file were generated for each script
    [PSCustomObject]$htCheck
    write-host -foregroundcolor yellow "Moving the generated .md files back to the repo dir`n:$($MDDocPath)..." ; 
    get-childitem -path $docfolder -recurse -include @('*.md') | move-item -Destination "$($MDDocPath)\" -verbose -force ; 
}
#region SUB_MAIN ; #*======v SUB MAIN v======
Generate-ScriptMarkdownHelp -Module Verb-Dev -RepoUrl https://github.com/tostka/verb-dev
#endregion SUB_MAIN ; #*======^ END SUB MAIN ^======