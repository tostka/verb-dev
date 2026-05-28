# Compare-ObjectsTDO.ps1

#region COMPARE_OBJECTSTDO ; #*------v Compare-ObjectsTDO v------
function Compare-ObjectsTDO {
    <#
    .SYNOPSIS
    Compare-ObjectsTDO() - Used to Compare two powershell objects
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : Compare-ObjectsTDO.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Git,SourceControl,Diff,format
    AddedCredit : Phil-Factor
    AddedWebsite: https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/Diff-Objects/Diff-Objects.ps1
    AddedTwitter: URL
    REVISIONS
    * 12:43 PM 5/28/2026 init, ren Diff-Objects -> Compare-Objects (use std verb) ; minor formatting tweaks, updated CBH, added proc{}; added -DiffStyle, to flip from added/deleted -> +/-; added == support which prefixes \s.
    * 7/7/21 Phil-Factor blog post example
    .DESCRIPTION
    Compare-ObjectsTDO() - Used to Compare two powershell objects
    This compares two powershell objects by determining their shared 
    keys or array sizes and comparing the values of each. It uses the 
    show-Object cmdlet for the heavy lifting
    
    .PARAMETER Ref
    The source object
    .PARAMETER diff
    The target object
    .PARAMETER Avoid
    a list of any object you wish to avoid comparing
    .PARAMETER Parent
    Only used for recursion
    .PARAMETER Depth
    The depth to which you wish to recurse
    .PARAMETER NullAndBlankSame
    Do we regard null and Blank the same for the purpose of comparisons.
    .PARAMETER ReportNodes
    Do you wish to report on nodes containing objects as well as values?
    .INPUTS
    Does not accept pipeline input.
    .EXAMPLE
    PS> write-verbose "We have the reference version of what the data should be in #ref" ; 
    PS> $Ref=@'
#TYPE System.Management.Automation.PSCustomObject
"Path","Value"
"$.Ham.Downtime",
"$.Ham.Location","Floor two rack"
"$.Ham.Users[0]","Fred"
"$.Ham.Users[1]","Jane"
"$.Ham.Users[2]","Mo"
"$.Ham.Users[3]","Phil"
"$.Ham.Users[4]","Tony"
"$.Ham.version","2019"
"$.Japeth.Location","basement rack"
"$.Japeth.Users[0]","Karen"
"$.Japeth.Users[1]","Wyonna"
"$.Japeth.Users[2]","Henry"
"$.Japeth.version","2008"
"$.Shem.Location","Server room"
"$.Shem.Users[0]","Fred"
"$.Shem.Users[1]","Jane"
"$.Shem.Users[2]","Mo"
"$.Shem.version","2017"
'@ |ConvertFrom-Csv ; 
    PS> write-verbose "We now have the reference result. we now create the test input" ; 
    PS> $ServersAndUsers = @{
      'Shem' = @{
          'version' = '2017'; 'Location' = 'Server room';
              'Users'=@('Fred','Jane','Mo') ; 
           }; 
      'Ham' =@{
          'version' = '2019'; 
          'Location' = 'Floor two rack';
          'Downtime'=$null
          'Users'=@('Fred','Jane','Mo','Phil','Tony')
      }; 
      'Japeth' =@{
          'version' = '2008'; 
          'Location' = 'basement rack';
          'Users'=@('Karen','Wyonna','Henry') ; 
      } ; 
    } ; 
    PS> write-verbose "run the 'show-Object' ; "
    PS> $Diff= show-Object $ServersAndUsers ; 
    PS> write-verbose "we now have a #Ref object with what the output should be, and we have the $diff object of what is produced by the current version "
    PS> write-verbose "We test to see if the $Ref and $Diff match."
    PS> $TestResult=Compare-ObjectsTDO -Ref $ref -Diff $diff -NullAndBlankSame $True | where {$_.Match -ne '=='} ; 
    PS> if ($TestResult) {
    PS>     Write-warning 'Test for show-Object with  ServersAndUsers failed' ; 
    PS>     $TestResult|format-table
    PS> } ; 
    .EXAMPLE
    PS> $process=(get-process pwsh) ; 
    PS> #<some time later>
    PS> Compare-ObjectsTDO  $process (get-process pwsh) -Depth 3 -Avoid @('Modules','Threads','StartInfo') -NullAndBlankSame $true ;     
    Demo eval of object status changes over time
    .LINK
    https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/Diff-Objects/Diff-Objects.ps1
    .LINK
    https://github.com/tostka/verb-dev
    #>
    #[CmdletBinding(DefaultParameterSetName="NoExpectation")]
    [CmdletBinding()]
    [Alias('Compare-Objects','Diff-Objects')]
    PARAM (
        [Parameter(Mandatory = $true,Position = 1,HelpMessage="The first file to compare")]
            [object]$Ref,
        [Parameter(Mandatory = $true,Position = 2,HelpMessage="The first file to compare")]
            [object]$Diff,
        [Parameter(Mandatory = $false,Position = 3,HelpMessage="The first file to compare")]
            [object[]]$Avoid = @('Metadata', '#comment'),
        [Parameter(Mandatory = $false,Position = 4,HelpMessage="The first file to compare")]
            [string]$Parent = '$',
        [Parameter(Mandatory = $false,Position = 5,HelpMessage="The first file to compare")]
            [string]$NullAndBlankSame = $true,
        [Parameter(Mandatory = $false,Position = 6,HelpMessage="The first file to compare")]
            [int]$ReportNodes = $true,
        [Parameter(Mandatory = $false,Position = 7)]
            [int]$Depth =10
    ) ;  
    PROCESS {
        $Left = show-ObjectTDO $Ref -Avoid $Avoid -Parent $Parent -Depth $Depth -reportNodes $ReportNodes
        $right = show-ObjectTDO $Diff -Avoid $Avoid -Parent $Parent -depth $Depth -reportNodes $ReportNodes
        $Paths = $Left + $Right | Select path -Unique
        $Paths | foreach{
          $ThePath = $_.Path;
          $Lvalue = $Left | where { $_.Path -eq $ThePath } | Foreach{ $_.Value };
          $Rvalue = $Right | where { $_.Path -eq $ThePath } | Foreach{ $_.Value };
          if ($RValue -eq $Lvalue)
          { $equality = '==' }
              elseif ([string]::IsNullOrEmpty($Lvalue) -and 
                     [string]::IsNullOrEmpty($rvalue) -and 
                     $NullAndBlankSame)
                     {$equality = '=='}
       
          else
          {
            $equality = "$(if ($lvalue -eq $null) { '-' }
              else { '<' })$(if ($Rvalue -eq $null) { '-' }
              else { '>' })"
          }
          [pscustomobject]@{ 'Ref' = $ThePath; 'Source' = $Lvalue; 'Target' = $Rvalue; 'Match' = $Equality }
          
        }
    } # PROC-E 
}
#endregion COMPARE_OBJECTSTDO ; #*------^ END Compare-ObjectsTDO ^------
