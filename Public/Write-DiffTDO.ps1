# Write-DiffTDO.ps1

#region WRITE_DIFFTDO ; #*------v Write-DiffTDO v------
function Write-DiffTDO {
    <#
    .SYNOPSIS
    Write-DiffTDO() - Outputs the results of Compare-FilesTDO as formatted console text
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : Write-DiffTDO.ps1
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
    Write-DiffTDO() - Outputs the results of Compare-FilesTDO as formatted console text
    
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
    PS> $oldFile = Get-Content -Path $OldFilePath ; 
    PS> $newFile = Get-Content -Path $NewFilePath ; 
    PS> $diffs = Compare-FilesTDO -Ref $OldFilePath -Diff $NewFilePath -ContextLines $ContextLines ; 
    PS> Write-DiffTDO -Diffs $diffs -OldFile $oldFile -NewFile $newFile -ContextLines 3 ; 
    .LINK
    AddedWebsite: https://dfinke.github.io/powershell,%20ai,%20chatgpt,%20codegen/2024/09/03/git-diff-tool-in-powershell.html
    .LINK
    https://github.com/tostka/verb-dev
    #>
    #[CmdletBinding(DefaultParameterSetName="NoExpectation")]
    [CmdletBinding()]
    [Alias('Write-Diff')]
    PARAM (        
        [Parameter(Mandatory=$true,HelpMessage="Diffs result of a Compare-FilesTDO() pass on a pair of files")]
            [psobject[]]$Diffs,
        [Parameter(Mandatory=$true,HelpMessage="The first file to compare")]
            [string[]]$Ref,
            #[string[]]$OldFile,
        [Parameter(Mandatory=$true,HelpMessage="The second file to compare")]
            ## The second file to compare
            [string[]]$Diff,
            #[string[]]$NewFile,
        [Parameter(HelpMessage="Lines of context to compare")]
            [int]$ContextLines = 3
    ) ;  
    Process {
        foreach ($diff in $Diffs) {
            if ($diff.ChangeType -eq 'Modified') {
                Write-Host "Line $($diff.OldLineNumber),$($diff.NewLineNumber) Modified:" -ForegroundColor Yellow
                for ($i = [Math]::Max(0, $diff.OldLineNumber - $ContextLines - 1); $i -lt [Math]::Min($Ref.Count, $diff.OldLineNumber + $ContextLines); $i++) {
                    Write-Host "  $($Ref[$i])"
                }
                Write-Host "- $($diff.OldLine)" -ForegroundColor Red
                Write-Host "+ $($diff.NewLine)" -ForegroundColor Green
            }
            elseif ($diff.ChangeType -eq 'Added') {
                Write-Host "Line $($diff.NewLineNumber) Added:" -ForegroundColor Green
                Write-Host "+ $($diff.NewLine)" -ForegroundColor Green
            }
            elseif ($diff.ChangeType -eq 'Deleted') {
                Write-Host "Line $($diff.OldLineNumber) Deleted:" -ForegroundColor Red
                Write-Host "- $($diff.OldLine)" -ForegroundColor Red
            }
        }
    } # PROC-E 
}
#endregion WRITE_DIFFTDO ; #*------^ END Write-DiffTDO ^------
