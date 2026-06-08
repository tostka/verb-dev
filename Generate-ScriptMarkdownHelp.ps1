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
# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmkECWQ2oP3cPZ15Ojzr6jYPR
# fDugggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
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
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSW52BG
# XdeJy8imfPMXwsuUF84Q2DANBgkqhkiG9w0BAQEFAASBgD7B7w7UAGZ9hHkKu2eW
# rLseVWluwkLCYKwzXX17IkwduLpUMAYFrohTXESsTY58inyR4pZl0PtLLRtfz2Sv
# hG+NQL33g1SXMdkye5iEKQ7EpYT/pj8bYMO3L/0y3i7JpZlhxG/gi350fynZPuXa
# x3UK9nNn0dwpFQV8gErI/Cxa
# SIG # End signature block
