# Compare-FilesTDO.ps1

#region COMPARE_FILESTDO ; #*------v Compare-FilesTDO v------
function Compare-FilesTDO {
    <#
    .SYNOPSIS
    Compare-FilesTDO() - Compares two files, displaying differences in a manner similar to traditional console-based diff utilities (like the difflib tool for python).
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : Compare-FilesTDO.ps1
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
    Compare-FilesTDO() - Compares two files, displaying differences in a manner similar to traditional console-based diff utilities (like the difflib tool for python).
    
    .PARAMETER Ref
    The first file to compare
    .PARAMETER Diff
    The second file to compare
    .PARAMETER pattern
    The regex pattern (if any) to use as a -match filter for file
    .PARAMETER DiffStyle
    Switch to specify traditional Diff +/-/\s prefix (over add/remove)
    .INPUTS
    Accepts pipeline input.
    .OUTPUTS
    System.Array returns array of matched file properties ('Name','FullName','Extension','Length','LastWriteTime','LinkType','PSParentPath','PSPath','Directory')
    .EXAMPLE
    PS> Compare-Filestdo -Ref C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_catapult_20221019vers.ps1 -Diff C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_KADRITS.ps1
    .LINK
    https://dfinke.github.io/powershell,%20ai,%20chatgpt,%20codegen/2024/09/03/git-diff-tool-in-powershell.html
    .LINK
    https://github.com/tostka/verb-dev
    #>
    #[CmdletBinding(DefaultParameterSetName="NoExpectation")]
    [CmdletBinding()]
    [Alias('Compare-Files')]
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
        $RefFile = Get-Content -Path $Ref
        $DiffFile = Get-Content -Path $Diff
        $diffs = [System.Collections.Generic.List[PSObject]]::new()
        $oldIndex = 0
        $newIndex = 0
        while ($oldIndex -lt $RefFile.Count -or $newIndex -lt $DiffFile.Count) {
            $oldLine = if ($oldIndex -lt $RefFile.Count) { $RefFile[$oldIndex] } else { $null }
            $newLine = if ($newIndex -lt $DiffFile.Count) { $DiffFile[$newIndex] } else { $null }
            if ($oldLine -eq $newLine) {
                $oldIndex++
                $newIndex++
            }
            else {
                $diffs.Add([pscustomobject]@{
                        ChangeType    = if ($null -eq $oldLine) { 'Added' } elseif ($newLine -eq $null) { 'Deleted' } else { 'Modified' }
                        OldLineNumber = if ($null -ne $oldLine) { $oldIndex + 1 } else { $null }
                        NewLineNumber = if ($null -ne $newLine) { $newIndex + 1 } else { $null }
                        OldLine       = $oldLine
                        NewLine       = $newLine
                    })
                if ($null -ne $oldLine) { $oldIndex++ }
                if ($null -ne $newLine) { $newIndex++ }
            }
        }
        return $diffs
    } # PROC-E 
}
#endregion COMPARE_FILESTDO ; #*------^ END Compare-FilesTDO ^------
