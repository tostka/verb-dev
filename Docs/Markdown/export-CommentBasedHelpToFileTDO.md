
# export-CommentBasedHelpToFileTDO

## SYNOPSIS
export-CommentBasedHelpToFileTDO - Exports comment-based help for a specified command to a text file.

## SYNTAX

```
export-CommentBasedHelpToFileTDO [-Command] <String> [-Destination] <DirectoryInfo[]> [-noReview]
 [-LengthThreshold <Int32>] [<CommonParameters>]
```

## DESCRIPTION
export-CommentBasedHelpToFileTDO - This function retrieves the full help content for a specified command and exports it to a text file.
If the help content is populated, it saves the content to a file (named \[cmdlet.name\].help.txt) and opens it in a text editor if available.

## EXAMPLES

### EXAMPLE 1
```
export-CommentBasedHelpToFileTDO -Command "Get-Process" ;
```

Demos export of the get-process command full help to a Get-Process.help.txt file (the destionation directory will be interactively prompted for)

### EXAMPLE 2
```
$tmod = 'verb-dev' ;
```

PS\> if($GIT_REPOSROOT -AND ($modroot = (join-path -path $GIT_REPOSROOT -child $tmod))){
PS\>     if(-not (test-path "$modroot\Help")){ mkdir "$modroot\Help" -verbose } ;
PS\>     $hlpRoot = (Resolve-Path -Path "$modroot\Help" -ea STOP).path ;
PS\>     gcm -mod verb-dev | select -expand name | select -first 5 | export-CommentBasedHelpToFileTDO -destination $hlpRoot -NoReview -verbose ;
PS\> } ; 
PS\> 
Demo that runs a module and exports each get-command-discovered command within the module, to a \[name\].help.txt file output to the Module's Help directory 
(which is discovered as a subdir of the \`$GIT_REPOSROOT autovariable).
Creates the Help directory if not pre-existing.
Suppresses notepad post open, via -NoReview param.

(creates the directory, if not found)

## PARAMETERS

### -Command
The name of the command for which to export the help content.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Destination
Destination path for output xxx.help.txt file \[-path c:\path-to\\\]"

```yaml
Type: DirectoryInfo[]
Parameter Sets: (All)
Aliases: PsPath

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -noReview
switch to suppress post-open in Editor\[-noReview\]

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

### -LengthThreshold
Minimum Length threshold (to recognize populated CBH)(defaults 200)\[-LengthThreshold 1000\]

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 200
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String. The function accepts pipeline input.
## OUTPUTS

### None. The function writes the help content to a file.
## NOTES
Version     : 0.0.1
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2025-01-16
FileName    : export-CommentBasedHelpToFileTDO.ps1
License     : MIT License
Copyright   : (c) 2024 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,Help,CommentBasedHelp,CBH,Documentation
AddedCredit : REFERENCE
AddedWebsite: URL
AddedTwitter: URL
REVISIONS
* 2:44 PM 1/16/2025 init

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

