# Show-ObjectTDO.ps1

#region SHOW_OBJECTTDO ; #*------v Show-ObjectTDO v------
function Show-ObjectTDO {
    <#
    .SYNOPSIS
    Show-ObjectTDO() - Displays an object's values and the 'dot' paths to them
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : Show-ObjectTDO.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Git,SourceControl,Diff,format
    AddedCredit : Phil-Factor
    AddedWebsite: https://www.leeholmes.com/using-powershell-to-compare-diff-files/
    AddedTwitter: URL
    REVISIONS
    * 9:24 AM 5/28/2026 init, ren Diff-Objects -> Show-Object (use std verb) ; minor formatting tweaks, updated CBH, added proc{}; added -DiffStyle, to flip from added/deleted -> +/-; added == support which prefixes \s.
    * 7/7/21 Phil-Factor blog post example
    .DESCRIPTION
    Show-ObjectTDO() - Displays an object's values and the 'dot' paths to them
    A detailed description of the Display-Object function.
    
    .PARAMETER TheObject
    The object that you wish to display
    .PARAMETER depth
    the depth of recursion (keep it low!)
    .PARAMETER Avoid
    an array of names of pbjects or arrays you wish to avoid.
    .PARAMETER Parent
    For internal use, but you can specify the name of the variable
    .PARAMETER CurrentDepth
    For internal use
    .PARAMETER RerportNodes
    Do you wish to report on nodes containing objects as well as values?

    .INPUTS
    Accepts pipeline input.
    .OUTPUTS
    System.Array returns array of matched file properties ('Name','FullName','Extension','Length','LastWriteTime','LinkType','PSParentPath','PSPath','Directory')
    .EXAMPLE
    PS> Show-objectTDO (get-date);
    
        Path                Value
        ----                -----
        $.Date              5/28/2026 12:00:00 AM
        $.Day               28
        $.DayOfWeek.value__ 4
        $.DayOfYear         148
        $.Hour              12
        $.Kind.value__      2
        $.Millisecond       58
        $.Minute            21
        $.Month             5
        $.Second            46
        $.Ticks             639155677060581841
        $.TimeOfDay         12:21:46.0581841
        $.Year              2026    
    
    Demo 
    PS> get-date| Show-ObjectTDO ; 
    Pipeline Demo (output matches above)
    PS> $current=Dir $pwd; Show-ObjectTDO $current ; 
    Demo using a variable
    .LINK
    https://www.red-gate.com/simple-talk/blogs/display-object-a-powershell-utility-cmdlet/
    .LINK
    https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/Display-Object/Display-Object.ps1
    .LINK
    https://github.com/tostka/verb-io
    #>
    #[CmdletBinding(DefaultParameterSetName="NoExpectation")]
    [CmdletBinding()]
    [Alias('Display-Object','Show-Object')]
    PARAM (
        [Parameter(Mandatory = $true,ValueFromPipeline = $true,HelpMessage="The object that you wish to display")]
            $TheObject,
        [Parameter(HelpMessage="the depth of recursion (keep it low!)")]
            [int]$depth = 5,
        [Parameter(HelpMessage="an array of names of pbjects or arrays you wish to avoid.")]
            [Object[]]$Avoid = @('#comment'),
        [Parameter(HelpMessage="For internal use, but you can specify the name of the variable")]
            [string]$Parent = '$',
        [Parameter(HelpMessage="For internal use")]
            [int]$CurrentDepth = 0,
        [Parameter(HelpMessage="Do you wish to report on nodes containing objects as well as values?")]
            [int]$reportNodes = 0,
        [Parameter(HelpMessage="(doesn't appear to be used in the function??)")]
            [int]$ordered = $True
    ) ;  
    PROCESS {
        if (($CurrentDepth -ge $Depth) -or ($TheObject -eq $Null)) { return; } #prevent runaway recursion
          $ObjectTypeName = $TheObject.GetType().Name #find out what type it is
          if ($ObjectTypeName -in 'HashTable', 'OrderedDictionary'){
              #If you can, force it to be a PSCustomObject
              $TheObject = [pscustomObject]$TheObject;
              $ObjectTypeName = 'PSCustomObject'
          }elseif ($ObjectTypeName -eq 'Collection`1') {
              #and anything else it spits on 
              $TheOldObject = $TheObject
              $TheObject = $TheOldObject | foreach{
                  [pscustomobject]$_
              };
          }
          #first do objects that cannot be treated as an array.
          if ($TheObject.Count -le 1 -and $ObjectTypeName -ne 'object[]') {
              #not something that behaves like an array
              # figure out where you get the names from
              if ($ObjectTypeName -in @('PSCustomObject')){ 
                  # Name-Value pair properties created by Powershell 
                  $MemberType = 'NoteProperty' 
              }else{ $MemberType = 'Property' }
              #now go through the property names, fetching them via GM
              if ($ordered){ 
                  $TheMembers = $TheObject | gm -MemberType $MemberType | where { $_.Name -notin $Avoid } 
              }else{
                  $TheMembers = $TheObject.PSObject.Properties | Select-Object Name | where { $_.Name -notin $Avoid } 
              }
              $TheMembers | Foreach{
                  Try{
                      $child = $TheObject.($_.Name);
                      $ChildType = $child.GetType().Name; #what is this value
                  }Catch { $Child = $null; } # avoid crashing on write-only objects
                  $brackets = ''; 
                  if ($_.Name -like '*.*') { $brackets = "'" }
                  #is the current child a value or a null?
                  if ($child -eq $null -or $child.GetType().BaseType.Name -eq 'ValueType' -or $ChildType -in @('String', 'String[]')){
                      [pscustomobject]@{ 
                          'Path' = "$Parent.$brackets$($_.Name)$brackets";
                          'Value' = $Child;                      
                      } 
                  }elseif (($CurrentDepth + 1) -eq $Depth){
                      [pscustomobject]@{
                          'Path' = "$Parent.$brackets$($_.Name)$brackets";
                          'Value' = $Child;
                      }
                  }else {
                      #not a value but an object of some sort
                      if ($ReportNodes -and $childType -ne 'Object[]'){
                          [pscustomobject]@{
                              'Path' = "$Parent.$brackets$($_.Name)$brackets";
                              'Value' = "($ChildType)"                        
                          } 
                      }
                      Show-ObjectTDO -TheObject $child -depth $Depth -Avoid $Avoid -Parent "$Parent.$brackets$($_.Name)$brackets" -CurrentDepth ($currentDepth + 1) -ReportNodes $reportNodes
                  }                
              } # loop-E
          }else {
              #it is an array
              if ($TheObject.Count -gt 0){
                  0..($TheObject.Count - 1) | Foreach{
                      $child = $TheObject[$_];
                      #is the current child a value or a null?
                      if (($child -eq $null) -or ($child.GetType().BaseType.Name -eq 'ValueType') -or ($child.GetType().Name -in @('String', 'String[]'))) 
                      {
                          #if so display it 
                          [pscustomobject]@{ 'Path' = "$Parent[$_]"; 'Value' = "$($child)"; } 
                      }elseif (($CurrentDepth + 1) -eq $Depth){
                          [pscustomobject]@{ 'Path' = "$Parent[$_]"; 'Value' = "$($child)"; }
                      }else {
                          #not a value but an object of some sort so do a recursive call
                          Show-ObjectTDO -TheObject $child -depth $Depth -Avoid $Avoid -parent "$Parent[$_]" -CurrentDepth ($currentDepth + 1) -ReportNodes $reportNodes
                      }
                  }
              }else { [pscustomobject]@{ 'Path' = "$Parent"; 'Value' = $Null } }
          }
    } # PROC-E 
}
#endregion SHOW_OBJECTTDO ; #*------^ END Show-ObjectTDO ^------
