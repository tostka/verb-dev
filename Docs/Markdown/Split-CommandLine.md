
# Split-CommandLine

## SYNOPSIS
Split-CommandLine - Parse command-line arguments using Win32 API CommandLineToArgvW function.

## SYNTAX

```
Split-CommandLine [-CommandLine] <String> [<CommonParameters>]
```

## DESCRIPTION
This is the Cmdlet version of the code from the article http://edgylogic.com/blog/powershell-and-external-commands-done-right.
It can parse command-line arguments using Win32 API function CommandLineToArgvW .

## EXAMPLES

### EXAMPLE 1
```
Split-CommandLine
```

Description
-----------
Get the command-line of the current PowerShell host, parse it and return arguments.

### EXAMPLE 2
```
Split-CommandLine -CommandLine '"c:\windows\notepad.exe" test.txt'
```

Description
-----------
Parse user-specified command-line and return arguments.

### EXAMPLE 3
```
'"c:\windows\notepad.exe" test.txt',  '%SystemRoot%\system32\svchost.exe -k LocalServiceNetworkRestricted' | Split-CommandLine
```

Description
-----------
Parse user-specified command-line from pipeline input and return arguments.

### EXAMPLE 4
```
Get-WmiObject Win32_Process -Filter "Name='notepad.exe'" | Split-CommandLine
```

Description
-----------
Parse user-specified command-line from property name of the pipeline object and return arguments.

## PARAMETERS

### -CommandLine
This parameter is optional.
A string representing the command-line to parse.
If not specified, the command-line of the current PowerShell host is used.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Version     : 1.6.2
Author      : beatcracker
Website     :	http://beatcracker.wordpress.com
Twitter     :	@beatcracker / http://twitter.com/beatcracker
CreatedDate : 2014-11-22
FileName    : Split-CommandLine
License     :
Copyright   :
Github      : https://github.com/beatcracker
AddedCredit : Todd Kadrie
AddedWebsite:	http://www.toddomation.com
AddedTwitter:	@tostka / http://twitter.com/tostka
REVISIONS
* 8:21 AM 8/3/2020 shifted into verb-dev module
* 1:17 PM 12/14/2019 TSK:Split-CommandLine():  minor reformatting & commenting
* 11/22/2014 posted version

## RELATED LINKS

[https://github.com/beatcracker/Powershell-Misc/blob/master/Split-CommandLine](https://github.com/beatcracker/Powershell-Misc/blob/master/Split-CommandLine)

