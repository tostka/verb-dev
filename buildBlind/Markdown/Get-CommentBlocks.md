
# Get-CommentBlocks

## SYNOPSIS
Get-CommentBlocks - Parse specified Path (or inbound Textcontent) for Comment-BasedHelp, and surrounding structures.

## SYNTAX

### Text
```
Get-CommentBlocks [-TextLines] <Object> [-showDebug] [-whatIf] [<CommonParameters>]
```

### File
```
Get-CommentBlocks [-Path] <Object> [-showDebug] [-whatIf] [<CommonParameters>]
```

## DESCRIPTION
Get-CommentBlocks - Parse specified Path (or inbound Textcontent) for Comment-BasedHelp, and surrounding structures.
Returns following parsed content: metaBlock (\`\<#PSScriptInfo..#\`\>), metaOpen (Line# of start of metaBlock), metaClose (Line# of end of metaBlock), cbhBlock (Comment-Based-Help block), cbhOpen (Line# of start of CBH), cbhClose (Line# of end of CBH), interText (Block of text *between* any metaBlock metaClose line, and any CBH cbhOpen line), metaCBlockIndex ( Of the collection of all block comments - \`\<#..#\`\> - the index of the one corresponding to the metaBlock), CbhCBlockIndex  (Of the collection of all block comments - \`\<#..#\`\> - the index of the one corresponding to the cbhBlock)

## EXAMPLES

### EXAMPLE 1
```
$rawSourceLines = get-content c:\path-to\script.ps*1  ;
```

$oBlkComments = Get-CommentBlocks -TextLines $rawSourceLines -showdebug:$($showdebug) -whatif:$($whatif) ;
$metaBlock = $oBlkComments.metaBlock ;
if ($metaBlock) {
    $smsg = "Existing MetaData located and tagged" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug
} ;
$cbhBlock = $oBlkComments.cbhBlock ;
$preCBHBlock = $oBlkComments.interText ;

## PARAMETERS

### -TextLines
Raw source lines from the target script file (as gathered with get-content) \[-TextLines TextArrayObj\]

```yaml
Type: Object
Parameter Sets: Text
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Path
Path to a powershell ps1/psm1 file to be parsed for CBH \[-Path c:\path-to\script.ps1\]

```yaml
Type: Object
Parameter Sets: File
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -showDebug
Parameter to display Debugging messages \[-ShowDebug switch\]

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

### -whatIf
Parameter to run a Test no-change pass \[-Whatif switch\]

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

### None
## OUTPUTS

### Returns a hashtable containing the following parsed content/objects, from the Text specified:
### * metaBlock : `<#PSScriptInfo..#`> published script metadata block (added via New|Update-ScriptFileInfo, at top of file)
### * metaOpen : Line# of start of metaBlock
### * metaClose : Line# of end of metaBlock
### * cbhBlock : Comment-Based-Help block
### * cbhOpen : Line# of start of CBH
### * cbhClose : Line# of end of CBH
### * interText : Block of text *between* any metaBlock metaClose line, and any CBH cbhOpen line.
### * metaCBlockIndex : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the metaBlock
### * CbhCBlockIndex  : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the cbhBlock
## NOTES
Version     : 1.1.0
Author      : Todd Kadrie
Website     : https://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 8:07 PM 11/18/2019
FileName    :
License     : MIT License
Copyright   : (c) 2019 Todd Kadrie
Github      : https://github.com/tostka
AddedCredit :
AddedWebsite:
AddedTwitter:
REVISIONS
* 3:49 PM 4/14/2020 minor change
* 5:19 PM 4/11/2020 added Path variable, and ParameterSet/exlus support
* 8:36 AM 12/30/2019 Get-CommentBlocks:updated cbh and added .INPUTS/.OUTPUTS cbh entries, detailing the subcompontents of the hashtable returned
* 8:28 PM 11/17/2019 INIT

## RELATED LINKS

[Requires -RunasAdministrator]()

