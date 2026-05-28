# Show-DiffTDO.ps1

#region SHOW_DIFFTDO ; #*------v Show-DiffTDO v------
function Show-DiffTDO {
    <#
    .SYNOPSIS
    Show-DiffTDO() - Produces a git-diff-like output for file comparison (wraps CompareFilesTDO, & Writed-DiffTDO)
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : Show-DiffTDO.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Git,SourceControl,Diff,format
    AddedCredit : Doug Finke
    AddedWebsite: https://dfinke.github.io/powershell,%20ai,%20chatgpt,%20codegen/2024/09/03/git-diff-tool-in-powershell.html
    AddedTwitter: URL
    REVISIONS
    * 9:09 AM 5/28/2026 init, minor formatting tweaks, updated CBH, added proc{}; added -DiffStyle, to flip from added/deleted -> +/-; added == support which prefixes \s.
    * 9/3/2024 Doug Finke's blog post example (code generated via ChatGPT)
    .DESCRIPTION
    Show-DiffTDO() - Produces a git-diff-like output for file comparison (wraps CompareFilesTDO, & Writed-DiffTDO)
    
    .PARAMETER Diffs
    Diffs result of a Compare-FilesTDO() pass on a pair of files
    .PARAMETER Ref
    The first file to compare
    .PARAMETER Diff
    The second file to compare
    .PARAMETER ContextLines
    Lines of context to compare
    .INPUTS
    Accepts pipeline input.
    .OUTPUTS
    System.Array returns array of matched file properties ('Name','FullName','Extension','Length','LastWriteTime','LinkType','PSParentPath','PSPath','Directory')
    .EXAMPLE
    PS> Show-DiffTDO -Ref C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_catapult_20221019vers.ps1 -Diff C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_KADRITS.ps1
    .LINK
    AddedWebsite: https://dfinke.github.io/powershell,%20ai,%20chatgpt,%20codegen/2024/09/03/git-diff-tool-in-powershell.html
    .LINK
    https://github.com/tostka/verb-dev
    #>
    #[CmdletBinding(DefaultParameterSetName="NoExpectation")]
    [CmdletBinding()]
    [Alias('Show-Diff')]
    PARAM (        
         [Parameter(Position=0,Mandatory=$true,HelpMessage="The first file to compare")]
            [ValidateScript({Test-Path $_})]
            [system.io.fileinfo[]]$Ref, 
        [Parameter(Position=1,Mandatory=$true,HelpMessage="The second file to compare")]
            ## The second file to compare
            [ValidateScript({Test-Path $_})]
            [system.io.fileinfo[]]$Diff,
        [Parameter(HelpMessage="Lines of context to compare")]
            [int]$ContextLines = 3
    ) ;  
    Process {
        $oldFile = Get-Content -Path $Ref.fullname
        $newFile = Get-Content -Path $Diff.fullname
        $diffs = Compare-FilesTDO -Ref $Ref.fullname -Diff $Diff.fullname -ContextLines $ContextLines
        Write-DiffTDO -Diffs $diffs -OldFile $oldFile -NewFile $newFile -ContextLines $ContextLines

    } # PROC-E 
}
#endregion SHOW_DIFFTDO ; #*------^ END Show-DiffTDO ^------
