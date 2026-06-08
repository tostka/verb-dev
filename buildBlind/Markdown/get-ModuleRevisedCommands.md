schema: 2.0.0
---

# get-ModuleRevisedCommands

## SYNOPSIS
get-ModuleRevisedCommands - Dynamically located any revised module 'Public' source .ps1, as identified as (LastWriteTime -gt RequiredVersion.pkg.LastWriteTime), and return array of fullname paths to .ps1's for ipmo during revision debugging.

## SYNTAX

### Version (Default)
```
get-ModuleRevisedCommands [-Name] <String[]> [-RequiredVersion <Version>] [-Internal] [<CommonParameters>]
```

### Date
```
get-ModuleRevisedCommands [-Name] <String[]> [-ExplicitTime <DateTime>] [-Internal] [<CommonParameters>]
```

## DESCRIPTION
get-ModuleRevisedCommands - Dynamically located any revised module 'Public' source .ps1, as identified as (LastWriteTime -gt RequiredVersion.pkg.LastWriteTime), and return array of fullname paths to .ps1's for ipmo during revision debugging.
Quick, 'reload my current efforts for testing', that isolates most recent revised .\Public folder .ps1's, for the specified module, and returns an array, to be ipmo -force -verbose, for debugging. 
Assumes that module source files are in following tree structure (example for the Verb-IO module):

\`\`\`text
C:\SC\VERB-IO
├───Internal
│       \[Internal 'non'-exported cmdlet files\].ps1 
├───Package
│       verb-io.2.0.3.nupkg # RequiredRevision nupkg file location and name-structure
├───Public
│       \[Public exported cmdlet files\].ps1
└───verb-IO
    │   verb-IO.psd1 # module Manifest psd1
    │   verb-IO.psm1 # module .psm1 file
\`\`\`

Notes: 
    - Supports specifying name as a semicolon-delimted string: "\[moduleName\];\[requiredversion\]", to pass an array of name/requiredversion combos for processing. 
    - ipmo -fo -verb 'C:\sc\verb-dev\public\get-ModuleRevisedCommands.ps1' ; 

    - In general this seems to work more effectively run with single-modules and -RequiredVersion, rather than feeding an array through with a common -ExplicitTime.

## EXAMPLES

### EXAMPLE 1
```
get-ModuleRevisedCommands -Name verb-io -RequiredVersion '2.0.3' -verbose
```

Retrieve any Public cmdlet .ps1 for the source directory of verb-io, dated after the locally stored nupkg file for Version 2.0.3

### EXAMPLE 2
```
get-ModuleRevisedCommands -Name verb-io -ExplicitTime (get-date).adddays(-14) -verbose
```

Retrieve any Public cmdlet .ps1 for the source directory of verb-io, dated in the last 14 days (as specified via -ExplicitTime parameter).

### EXAMPLE 3
```
get-ModuleRevisedCommands -Name 'verb-io','verb-dev' -ExplicitTime (get-date).adddays(-14) -verbose ;
```

Retrieve both verb-io and verb-dev, against revisions -ExplicitTime'd 14days prior.

### EXAMPLE 4
```
[array]$lmod = get-ModuleRevisedCommands -Name verb-dev -verbose -RequiredVersion 1.5.9 -ReturnList ;
```

PS\> $lmod += get-ModuleRevisedCommands -Name verb-io -verbose -RequiredVersion 2.0.0 -ReturnList;
PS\> ipmo -fo -verb $lmod ;    
Demo use of external ipmo of resulting list.

### EXAMPLE 5
```
$lmod= get-ModuleRevisedCommands -Name "verb-dev;1.5.9","verb-io;2.0.0" ;
```

PS\> ipmo -fo -verb $lmod ;    
Demo use of semicolon-delimited -Name with both ModuleName and RequiredVersion, in an array, with external ipmo of resulting list.

## PARAMETERS

### -Name
Module Name to have revised Public source directory import-module'd.
Optionally can specify as semicolon-delimited hybrid value: -Name \[ModuleName\];\[RequiredVersion\] \[-Name verb-io\]

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -RequiredVersion
Required module .pkg file version to be used as filter date  for determining 'revised' public cmdlets\[-RequiredVersion '2.0.3'\]

```yaml
Type: Version
Parameter Sets: Version
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExplicitTime
Explicit timestamp to be used for 'Revised' Public .ps1 cmdlet filtering\[-ExplicitTime (get-date).adddays(-14)\]

```yaml
Type: DateTime
Parameter Sets: Date
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Internal
Switch to load Internal commands (along with 'Public' commands)\[-whatIf\]

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Version     : 1.0.0
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2022-05-11
FileName    : get-ModuleRevisedCommands
License     : MIT License
Copyright   : (c) 2022 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging
REVISIONS
* 12:17 PM 6/2/2022 #171 corrected typo in 'no matches' output ; as ipmo w/in a module doesn't export the results to the 
    environement, post-exec, ren import-ModuleRevised -\> get-ModuleRevisedCommands, 
    and hard-code export list as sole function; set catch to continue; added 
    -ReturnList for external ipmo;  flipped pipeline array detect to test name 
    count, and not isArray (it's hard typed array, so it's always array)
* 12:11 PM 5/25/2022 init

## RELATED LINKS

[https://github.com/tostka/verb-dev

VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]](https://github.com/tostka/verb-dev

VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)])

[https://github.com/tostka/verb-dev

VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]]()

