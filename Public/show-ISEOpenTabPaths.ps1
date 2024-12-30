#*------v show-ISEOpenTabPaths.ps1 v------
function show-ISEOpenTabPaths {
    <#
    .SYNOPSIS
    show-ISEOpenTabPaths - Display a list fullname/paths of all currently open ISE tab files
    .NOTES
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
    .DESCRIPTION
    show-ISEOpenTabPaths - Display a list fullname/paths of all currently open ISE tab files

    This is really only useful when you run a massive number of open file tabs, and visually scanning them unsorted is too much work. 
    When you want to see the paths of everything open, this outputs it to pipeline/console

    Nothing more than a canned up call of:
    PS> $psise.powershelltabs.files.fullpath
    .EXAMPLE
    PS> show-ISEOpenTabPaths
    simple exec
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('shIseTab')]
    PARAM() ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
    }
    PROCESS {
        if ($psise){
            $psise.powershelltabs.files.fullpath | write-output  ; 
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}; 
#*------^ show-ISEOpenTabPaths.ps1 ^------
