
# show-ISEOpenTab

## SYNOPSIS
show-ISEOpenTab - Display a list of all currently open ISE tab files, prompt for selection, and then foreground selected tab file

## SYNTAX

```
show-ISEOpenTab [[-Path] <String>] [<CommonParameters>]
```

## DESCRIPTION
show-ISEOpenTab - Display a list of all currently open ISE tab files, prompt for selection, and then foreground selected tab file
Alternately supports a -Path param, that permits ISE Console use to direct switch active Tab File. 

This is really only useful when you run a massive number of open file tabs, and visually scanning them unsorted is too much work. 
Opens them in a sortable grid view, with both Displayname & fullpath, and you can rapidly zoom in on the target tab file you're seeking.

## EXAMPLES

### EXAMPLE 1
```
show-ISEOpenTab -verbose -whatif
```

Intereactive pass, uses out-grid as a picker select a prompted target file tab, from full list.

### EXAMPLE 2
```
show-ISEOpenTab -Path 'D:\scripts\get-MailHeaderSenderIDKeys.ps1' -verbose ;
```

ISE Console direct switch open files in ISE to the file tab with the specified path as it's FullName

## PARAMETERS

### -Path
Optional Path to filter against the ISE .files Fullname string (for direct ISE console use)\[-Path ' D:\scripts\show-ISEOpenTab_func.ps1'\]

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
CreatedDate : 2022-05-11
FileName    : show-ISEOpenTab
License     : MIT License
Copyright   : (c) 2024 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging
REVISIONS
* 10:09 AM 5/14/2024 init

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

