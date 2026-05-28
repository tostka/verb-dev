# Compare-FileTDO.ps1

#region COMPARE_FILETDO ; #*------v Compare-FileTDO v------
function Compare-FileTDO {
    <#
    .SYNOPSIS
    Compare-FileTDO() - Compares two files, displaying differences in a manner similar to traditional console-based diff utilities.
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : Compare-FileTDO.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Git,SourceControl,Diff,format
    AddedCredit : Lee Holmes
    AddedWebsite: https://www.leeholmes.com/using-powershell-to-compare-diff-files/
    AddedTwitter: URL
    REVISIONS
    * 9:09 AM 5/28/2026 init, minor formatting tweaks, updated CBH, added proc{}; added -DiffStyle, to flip from added/deleted -> +/-; added == support which prefixes \s.
    * Nov 30, 2013 Lee Holmes blog post example
    .DESCRIPTION
    Compare-FileTDO() - Compares two files, displaying differences in a manner similar to traditional console-based diff utilities.
    
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
    PS> compare-filetdo -Ref C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_catapult_20221019vers.ps1 -Diff C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_KADRITS.ps1
    .LINK
    https://www.leeholmes.com/using-powershell-to-compare-diff-files/
    .LINK
    https://github.com/tostka/verb-dev
    #>
    #[CmdletBinding(DefaultParameterSetName="NoExpectation")]
    [CmdletBinding()]
    [Alias('Compare-File')]
    PARAM (
        [Parameter(Position=0,Mandatory=$true,HelpMessage="The first file to compare")]
            [ValidateScript({Test-Path $_})]
            [system.io.fileinfo[]]$Ref,
        [Parameter(Position=0,Mandatory=$true,HelpMessage="The second file to compare")]
            ## The second file to compare
            [ValidateScript({Test-Path $_})]
            [system.io.fileinfo[]]$Diff,
        [Parameter(HelpMessage="The regex pattern (if any) to use as a -match filter for file")]
            [string]$pattern = ".*",
        [Parameter(HelpMessage="Switch to specify traditional Diff +/-/\s prefix (over add/remove)")]
            [switch]$DiffStyle = $true 
    ) ;  
    Process {
        ## Get the content from each file
        $content1 = Get-Content $Ref
        $content2 = Get-Content $Diff
        ## Compare the two files. Get-Content annotates output objects with
        ## a 'ReadCount' property that represents the line number in the file
        ## that the text came from.
        $comparedLines = Compare-Object $content1 $content2 -IncludeEqual |
            Sort-Object { $_.InputObject.ReadCount }
        $lineNumber = 0
        $comparedLines | foreach {
            ## Keep track of the current line number, using the line
            ## numbers in the "after" file for reference.
            if($_.SideIndicator -eq "==" -or $_.SideIndicator -eq "=>"){
                $lineNumber = $_.InputObject.ReadCount
            }
            ## If the text matches the pattern, output a custom object
            ## that displays text like this:
            ##
            ## Line Operation Text
            ## ---- --------- ----
            ## 59 added New text added
            ##
            if($_.InputObject -match $pattern){
                if($_.SideIndicator -ne "=="){
                    if($_.SideIndicator -eq "=>"){
                        if($DiffStyle){$lineOperation = "+"
                        }else{$lineOperation = "added"} ; 
                    }elseif($_.SideIndicator -eq "<="){
                        if($DiffStyle){$lineOperation = "-"
                        }else{$lineOperation = "deleted"} ; 
                    }elseif($_.SideIndicator -eq "=="){
                       if($DiffStyle){$lineOperation = " "
                        }else{$lineOperation = " "} ; 
                    }                    
                    [PSCustomObject] @{
                        Line = $lineNumber
                        #Operation =< span style="color: "> $lineOperation
                        #Operation ="< span style=`"color: `"> $($lineOperation)"
                        Operation =" $($lineOperation)"
                        Text = $_.InputObject
                    }
                }
            }
        } # loop-E
    } # PROC-E 
}
#endregion COMPARE_FILETDO ; #*------^ END Compare-FileTDO ^------
