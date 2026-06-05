
# show-Verbs

## SYNOPSIS
show-Verbs.ps1 - Display standard Verbs grouped into Categories

## SYNTAX

```
show-Verbs [[-Verb] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
show-Verbs.ps1 - Display standard Verbs grouped into Categories
If -verb is used, only the specified verb's info and group/category is output.

## EXAMPLES

### EXAMPLE 1
```
'New' | show-Verbs ;
```

Found 1 verbs
  Verb Group
  ---- -----
  New  Common

Show the info on the new standard verb

### EXAMPLE 2
```
show-verbs ;
```

Verbs in category Common (34) :
    Add       Clear     Close     Copy     Enter    Exit     Find     Format   Get      Hide     Join     Lock     Move     New      Open
    Optimize  Pop       Push      Redo     Remove   Rename   Reset    Resize   Search   Select   Set      Show     Skip     Split    Step
    Switch    Undo      Unlock    Watch
    Verbs in category Data (24) :
    Backup       Checkpoint   Compare      Compress     Convert      ConvertFrom  ConvertTo   Dismount    Edit        Expand      Export
    Group        Import       Initialize   Limit        Merge        Mount        Out         Publish     Restore     Save        Sync
    Unpublish    Update
    Verbs in category Lifecycle (20) :
    Approve     Assert      Complete    Confirm     Deny        Disable     Enable     Install    Invoke     Register   Request    Restart
    Resume      Start       Stop        Submit      Suspend     Uninstall   Unregister Wait
    Verbs in category Diagnostic (7) :
    Debug    Measure  Ping    Repair  Resolve Test    Trace
    Verbs in category Communications (6) :
    Connect     Disconnect  Read        Receive     Send        Write
    Verbs in category Security (6) :
    Block      Grant      Protect    Revoke     Unblock    Unprotect
    Verbs in category Other (1) :
    Use    

Output formatted display of all standard verbs (as per get-verb)

### EXAMPLE 3
```
'show','new','delete','invoke' | show-verbs -verbose  ;
```

Verb   Group
    ----   -----
    Show   Common
    New    Common
    Invoke Lifecycle    

Show specs on an array of verbs with verbose output and pipeline input

### EXAMPLE 4
```
gcm -mod verb-io | ? commandType -eq 'Function' | select -expand verb -unique | show-Verbs -verbo
```

Collect all unique verbs for functions in the verb-io module, and test against MS verb standard with verbose output

## PARAMETERS

### -Verb
Verb string to be tested\[-verb report\]

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Name, v, n, like, match

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Accepts piped input.
## OUTPUTS

### Boolean
## NOTES
Version     : 1.0.0
Author      : Todd Kadrie
Website     : http://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : 2021-01-20
FileName    : show-Verbs.ps1
License     : MIT License
Copyright   : (c) 2022 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,development,verbs
AddedCredit : arsscriptum
AddedWebsite: https://github.com/arsscriptum/PowerShell.Module.Core/blob/master/src/Miscellaneous.ps1
AddedTwitter: 
REVISION
* 8:48 AM 5/18/2026 corrected CBH syn & desc; revised demo's added echos
* 4:35 PM 7/20/2022 init; cached & subbed out redundant calls to get-verb; ; explict write-out v return ; fixed fails on single object counts; added pipeline support; 
    flipped DarkRed outputs to foreground/background combos (visibility on any given bg color)
* 5/13/22 arsscriptum's posted copy (found in google search)

## RELATED LINKS

[https://github.com/tostka/verb-IO](https://github.com/tostka/verb-IO)

