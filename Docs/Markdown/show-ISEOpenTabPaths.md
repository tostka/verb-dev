
# show-ISEOpenTabPaths

## SYNOPSIS
show-ISEOpenTabPaths - Display a list fullname/paths of all currently open ISE tab files

## SYNTAX

```
show-ISEOpenTabPaths [<CommonParameters>]
```

## DESCRIPTION
show-ISEOpenTabPaths - Display a list fullname/paths of all currently open ISE tab files

This is really only useful when you run a massive number of open file tabs, and visually scanning them unsorted is too much work. 
When you want to see the paths of everything open, this outputs it to pipeline/console

Nothing more than a canned up call of:
PS\> $psise.powershelltabs.files.fullpath

## EXAMPLES

### EXAMPLE 1
```
show-ISEOpenTabPaths
```

simple exec

## PARAMETERS

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
FileName    : show-ISEOpenTabPaths
License     : MIT License
Copyright   : (c) 2024 Todd Kadrie
Github      : https://github.com/tostka/verb-dev
Tags        : Powershell,ISE,development,debugging
REVISIONS
* 10:09 AM 5/14/2024 init

## RELATED LINKS

[https://github.com/tostka/verb-dev](https://github.com/tostka/verb-dev)

