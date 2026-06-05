
# Convert-CommandToSplatTDO

## SYNOPSIS
Convert-CommandToSplatTDO - Convert the named parameter part of a command into a splat (hash table oif parameters): In the ISE works from current selected text; pastes result over the selection (otherwise copies to CB and echoes to pipeline)

## SYNTAX

```
Convert-CommandToSplatTDO [[-Text] <String>] [<CommonParameters>]
```

## DESCRIPTION
Convert-CommandToSplatTDO - Convert the named parameter part of a command into a splat (hash table oif parameters): In the ISE works from current selected text; pastes result over the selection (otherwise copies to CB and echoes to pipeline)

## EXAMPLES

### EXAMPLE 1
```
convert-commandtoSplatTDO -Text "gci -path d:\scripts\* -include @('*.ps1','*.psm1','*.xml') -recurse" ;
```

$plt = @{
        path = 'd:\scripts\*'
        include = '@('''*.ps1'',''*.psm1'',''*.xml''')'
    }
    Get-ChildItem @plt


Convert command line text specification to splat \[hashtable\]

## PARAMETERS

### -Text
\[ValidateNotNullOrEmpty()\]
= $psISE.CurrentFile.editor.SelectedText

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
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
CreatedDate : 2024-07-11
FileName    : Convert-CommandToSplatTDO.ps1
License     : (non asserted)
Copyright   : (non asserted)
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging
REVISIONS
* 8:46 AM 4/16/2026 init; works on cmdline as well as JH's intent as menu item in ISE; 
    added testing for positional params (won't have -parametername), explicit error for correction. 
    Also patched over internal functions and other cmdlets that won't gcm resolve (forces $cmd to $AstTokens\[0\].text)
    -\> resolves what it finds into a splat whether all the components are resolvable or not.
- Adapted from Jeff Hicks posted Convert-CommandToSplat: jdhitsolutions/ISEScriptingGeek

## RELATED LINKS

[https://github.com/jdhitsolutions/ISEScriptingGeek/tree/master/functions](https://github.com/jdhitsolutions/ISEScriptingGeek/tree/master/functions)

[Github      : https://github.com/tostka/verb-dev]()

