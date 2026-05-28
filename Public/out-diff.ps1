# out-diff.ps1


function out-diffTDO {
    <#
    .SYNOPSIS
    out-diffTDO() - Redirects a Universal DIFF encoded text from the pipeline to the host using colors to highlight the differences.
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : out-diffTDO.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Git,SourceControl,Diff,format
    AddedCredit : Enrico Campidoglio
    AddedWebsite: https://megakemp.com/2012/01/19/better-diffs-with-powershell/
    AddedTwitter: URL
    REVISIONS
    * 9:09 AM 5/28/2026 init
    * January 19, 2012 Enrico Campidoglio's blog post example
    .DESCRIPTION
    out-diffTDO() - Redirects a Universal DIFF encoded text from the pipeline to the host using colors to highlight the differences.
    Helper function to highlight the differences in a Universal DIFF text using color coding.
    
    [Better Diffs with PowerShell - megakemp.com/](https://megakemp.com/2012/01/19/better-diffs-with-powershell/)

    ### Unified DIFFs

    One of the most basic features of any source control system is the ability to compare two versions of the same file to see what’s changed. The output of such comparison, or [DIFF](http://en.wikipedia.org/wiki/Diff), is commonly represented in text using the [Unified DIFF format](http://en.wikipedia.org/wiki/Diff#Unified_format), which looks something like this:

    @@ -6,12 +6,10 @@
    -#import <SenTestingKit/SenTestingKit.h>
    -#import <UIKit/UIKit.h>
    -
    @interface QuoteTest : SenTestCase {
    }

    - (void)testQuoteForInsert_ReturnsNotNull;
    +- (void)testQuoteForInsert_ReturnsPersistedQuote;

    @end


    In the Unified DIFF format changes are displayed at the line level through a set of well-known prefixes. The rule is simple:

    A line can either be **added**, in which case it will be preceded by a `+` sign, or **removed**, in which case it will be preceded by a `-` sign. **Unchanged** lines are preceded by a whitespace.

    In addition to that, each modified section, referred to as _hunk_, is preceded by a header that indicates the position and size of the section in the original and modified file respectively. For example this _hunk header_:

    @@ -6,12 +6,10 @@


    means that in **the original file** the modified lines start at `line 6` and continue for `12 lines`. In **the new file**, instead, that same change starts at `line 6` and includes a total of `10 lines`.    
    .PARAMETER InputObject
    The text to display as Universal DIFF.
    .INPUTS
    Accepts pipeline input.
    .OUTPUTS
    System.Array returns array of matched file properties ('Name','FullName','Extension','Length','LastWriteTime','LinkType','PSParentPath','PSPath','Directory')
    .EXAMPLE
    PS> . .\Out-Diff.ps1
    PS> git diff | Out-Diff
    .LINK
    https://megakemp.com/2012/01/19/better-diffs-with-powershell/
    .LINK
    https://github.com/tostka/verb-dev
    #>
    #[CmdletBinding(DefaultParameterSetName="NoExpectation")]
    [CmdletBinding()]
    [Alias('out-diff')]
    PARAM (
        [Parameter(Position=0,Mandatory=$true, ValueFromPipeline=$true)]
            [PSObject]$InputObject        
    ) ;  
    Process {
        $contentLine = $InputObject | Out-String
        if ($contentLine -match "^Index:") {
            Write-Host $contentLine -ForegroundColor Cyan -NoNewline
        } elseif ($contentLine -match "^(\+|\-|\=){3}") {
            Write-Host $contentLine -ForegroundColor Gray -NoNewline
        } elseif ($contentLine -match "^\@{2}") {
            Write-Host $contentLine -ForegroundColor Gray -NoNewline
        } elseif ($contentLine -match "^\+") {
            Write-Host $contentLine -ForegroundColor Green -NoNewline
        } elseif ($contentLine -match "^\-") {
            Write-Host $contentLine -ForegroundColor Red -NoNewline
        } else {
            Write-Host $contentLine -NoNewline
        }
    }
} 

