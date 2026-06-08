
# New-GitHubGist

## SYNOPSIS
New-GitHubGist.ps1 - Create GitHub Gist from passed param or file contents

## SYNTAX

### Content (Default)
```
New-GitHubGist [-Name] <String> -Content <String[]> [-Description <String>] [-UserToken <String>] [-Private]
 [-Passthru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### path
```
New-GitHubGist [-Name] <String> -Path <String> [-Description <String>] [-UserToken <String>] [-Private]
 [-Passthru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
New-GitHubGist -Name "BoxPrompt.ps1" -Description "a fancy PowerShell prompt function" -Path S:\boxprompt.ps1
```

## PARAMETERS

### -Name
What is the name for your gist?
PARAMETER Path
Path to file of content to be converted
PARAMETER Content,
Content to be converted
PARAMETER Description,
Description for new Gist
PARAMETER UserToken
Github Access Token
PARAMETER Private
Switch parameter that specifies creation of a Private Gist
PARAMETER Passthru
Passes the new Gist through into pipeline, as a new object

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Path
{{ Fill Path Description }}

```yaml
Type: String
Parameter Sets: path
Aliases: pspath

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Content
{{ Fill Content Description }}

```yaml
Type: String[]
Parameter Sets: Content
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
{{ Fill Description Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserToken
{{ Fill UserToken Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases: token

Required: False
Position: Named
Default value: $gitToken
Accept pipeline input: False
Accept wildcard characters: False
```

### -Private
{{ Fill Private Description }}

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

### -Passthru
{{ Fill Passthru Description }}

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Author: Jeffery Hicks
Website:	https://jdhitsolutions.com/blog/powershell/5410/creating-a-github-gist-with-powershell/
Twitter:	@tostka, http://twitter.com/tostka
Additional Credits: REFERENCE
Website:	URL
Twitter:	URL
REVISIONS   :
* 1/26/17 - posted version

## RELATED LINKS

[https://jdhitsolutions.com/blog/powershell/5410/creating-a-github-gist-with-powershell/](https://jdhitsolutions.com/blog/powershell/5410/creating-a-github-gist-with-powershell/)

