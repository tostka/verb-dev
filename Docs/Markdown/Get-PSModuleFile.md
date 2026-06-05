
# Get-PSModuleFile

## SYNOPSIS
Get-PSModuleFile.ps1 - Locate & return the string path to a module's manifest .psd1 file, given the root path of the moodule (direct lift from BuildHelpers:Get-PSModuleManifest, but I want a sep copy wo BH as a dependancy)

## SYNTAX

```
Get-PSModuleFile [-Path] <String> [[-Extension] <String>] [<CommonParameters>]
```

## DESCRIPTION
Get-PSModuleFile.ps1 - Locate & return the string path to a module's manifest .psd1 file, given the root path of the moodule (direct lift from BuildHelpers:Get-PSModuleManifest, but I want a sep copy wo BH as a dependancy)
Get the PowerShell key psd1|psm1 for a project ;
    Evaluates based on the following scenarios: ;
        * Subfolder with the same name as the current folder with a psd1|psm1 file in it ;
        * Subfolder with a \<subfolder-name\>.psd1|psm1 file in it ;
        * Current folder with a \<currentfolder-name\>.psd1|psm1 file in it ;
        + Subfolder called "Source" or "src" (not case-sensitive) with a psd1|psm1 file in it ;
    Note: This does not handle paths in the format Folder\ModuleName\Version\ ;

## EXAMPLES

### EXAMPLE 1
```
$psd1M = Get-PSModuleFile -path c:\sc\someproj\
```

Retrieve the defualt .psd1 Manifest from the specified project, and assign the fullpath to the $psd1M variable

### EXAMPLE 2
```
Get-PSModuleFile -path c:\sc\someproj\ -extension 'psm1'
```

Use the -Extension 'Both' option to find and return the path to the .psm1 Module file for the specified project,

### EXAMPLE 3
```
$modulefiles = Get-PSModuleFile -path c:\sc\someproj\ -extension both
```

Use the -Extension 'Both' option to find and return the paths of both the .psd1 Manifest and the .psm1 Module for the specified project, and assign the fullpath to the $modulefiles variable

## PARAMETERS

### -Path
Path to project root.
Defaults to the current working path \[-path 'C:\sc\PowerShell-Statistics\'\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: $PWD.Path
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Extension
Specify Module file type: Module .psm1 file or Manifest .psd1 file (psd1|psm1 - defaults psd1)\[-Extension .psm1\]

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: .psd1
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Does not accepted piped input.(.NET types, can add description)
## OUTPUTS

### System.String
## NOTES
Version     : 1.0.0
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2021-10-15
FileName    : Get-PSModuleFile.ps1
License     : MIT License 
Copyright   : (none asserted)
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell
AddedCredit :  RamblingCookieMonster (Warren Frame)
AddedWebsite: https://github.com/RamblingCookieMonster
AddedTwitter: @pscookiemonster
AddedWebsite: https://github.com/RamblingCookieMonster/BuildHelpers
REVISIONS
* 11:20 AM 12/12/2022 completely purged rem'd require stmts, confusing, when they echo in build...
* 9:31 AM 9/27/2022 CBH update, clearly indic it returns a \[string\] and not a file obj 
* 10:48 AM 3/14/2022 updated CBH for missing extension param
* 11:38 AM 10/15/2021 init version, added support for locating both .psd1 & .psm1, a new -Extension param to drive the choice, and a 'both' optional extension spec to retrieve both file type paths.
* 1/1/2019 BuildHelpers most recent rev of the get-PsModuleManifest function.

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

[https://github.com/RamblingCookieMonster/BuildHelpers](https://github.com/RamblingCookieMonster/BuildHelpers)

