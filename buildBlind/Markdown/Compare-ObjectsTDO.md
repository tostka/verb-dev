
# Compare-ObjectsTDO

## SYNOPSIS
Compare-ObjectsTDO() - Used to Compare two powershell objects

## SYNTAX

```
Compare-ObjectsTDO [-Ref] <Object> [-Diff] <Object> [[-Avoid] <Object[]>] [[-Parent] <String>]
 [[-NullAndBlankSame] <String>] [[-ReportNodes] <Int32>] [[-Depth] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Compare-ObjectsTDO() - Used to Compare two powershell objects
This compares two powershell objects by determining their shared 
keys or array sizes and comparing the values of each.
It uses the 
show-Object cmdlet for the heavy lifting

## EXAMPLES

### EXAMPLE 1
```
write-verbose "We have the reference version of what the data should be in #ref" ;
```

PS\> $Ref=@'
#TYPE System.Management.Automation.PSCustomObject
"Path","Value"
"$.Ham.Downtime",
"$.Ham.Location","Floor two rack"
"$.Ham.Users\[0\]","Fred"
"$.Ham.Users\[1\]","Jane"
"$.Ham.Users\[2\]","Mo"
"$.Ham.Users\[3\]","Phil"
"$.Ham.Users\[4\]","Tony"
"$.Ham.version","2019"
"$.Japeth.Location","basement rack"
"$.Japeth.Users\[0\]","Karen"
"$.Japeth.Users\[1\]","Wyonna"
"$.Japeth.Users\[2\]","Henry"
"$.Japeth.version","2008"
"$.Shem.Location","Server room"
"$.Shem.Users\[0\]","Fred"
"$.Shem.Users\[1\]","Jane"
"$.Shem.Users\[2\]","Mo"
"$.Shem.version","2017"
'@ |ConvertFrom-Csv ; 
PS\> write-verbose "We now have the reference result.
we now create the test input" ; 
PS\> $ServersAndUsers = @{
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
PS\> write-verbose "run the 'show-Object' ; "
PS\> $Diff= show-Object $ServersAndUsers ; 
PS\> write-verbose "we now have a #Ref object with what the output should be, and we have the $diff object of what is produced by the current version "
PS\> write-verbose "We test to see if the $Ref and $Diff match."
PS\> $TestResult=Compare-ObjectsTDO -Ref $ref -Diff $diff -NullAndBlankSame $True | where {$_.Match -ne '=='} ; 
PS\> if ($TestResult) {
PS\>     Write-warning 'Test for show-Object with  ServersAndUsers failed' ; 
PS\>     $TestResult|format-table
PS\> } ;

### EXAMPLE 2
```
$process=(get-process pwsh) ;
```

PS\> #\<some time later\>
PS\> Compare-ObjectsTDO  $process (get-process pwsh) -Depth 3 -Avoid @('Modules','Threads','StartInfo') -NullAndBlankSame $true ;     
Demo eval of object status changes over time

## PARAMETERS

### -Ref
The source object

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Diff
The target object

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Avoid
a list of any object you wish to avoid comparing

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: @('Metadata', '#comment')
Accept pipeline input: False
Accept wildcard characters: False
```

### -Parent
Only used for recursion

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: $
Accept pipeline input: False
Accept wildcard characters: False
```

### -NullAndBlankSame
Do we regard null and Blank the same for the purpose of comparisons.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReportNodes
Do you wish to report on nodes containing objects as well as values?

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Depth
The depth to which you wish to recurse

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 10
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Does not accept pipeline input.
## OUTPUTS

## NOTES
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
* 12:43 PM 5/28/2026 init, ren Diff-Objects -\> Compare-Objects (use std verb) ; minor formatting tweaks, updated CBH, added proc{}; added -DiffStyle, to flip from added/deleted -\> +/-; added == support which prefixes \s.
* 7/7/21 Phil-Factor blog post example

## RELATED LINKS

[https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/Diff-Objects/Diff-Objects.ps1](https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/Diff-Objects/Diff-Objects.ps1)

[https://github.com/tostka/verb-dev

[CmdletBinding(DefaultParameterSetName="NoExpectation")]]()

