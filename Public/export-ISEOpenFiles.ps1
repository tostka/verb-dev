﻿#*------v export-ISEOpenFiles.ps1 v------
function export-ISEOpenFiles {
    <#
    .SYNOPSIS
    export-ISEOpenFiles - Export a list of all currently open ISE tab files, to CU \WindowsPowershell\Scripts\ISESavedSession.psXML file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : export-ISEOpenFiles
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 8:31 AM 3/26/2024 chg eIseOpen -> epIseOpen
    * 3:28 PM 6/23/2022 add -Tag param to permit running interger-suffixed variants (ie. mult ise sessions open & stored from same desktop). 
    * 9:19 AM 5/20/2022 add: eIseOpen alias (using these a lot lately; w freq crashouts of ise, and need to recover all files open & BPs to quickly get back to function)
    * 12:12 PM 5/11/2022 init
    .DESCRIPTION
    export-ISEOpenFiles - Export a list of all currently open ISE tab files, to CU \WindowsPowershell\Scripts\ISESavedSession.psXML file
    Quick bulk dump, when ISE ineveitbly stops properly echo'ing variable values to terminal (and need to close and re-open all open files)
    .PARAMETER Tag
    Optional Tag to apply to as filename suffix[-tag 'label']
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    PS> export-ISEOpenFiles -verbose -whatif
    Export all 'line'-type breakpoints on all current open ISE tabs, to a matching xml file, with verbose output, and whatif
    .EXAMPLE
    PS> export-ISEOpenFiles -Tag 'mfa' -verbose -whatif
    Export with Tag 'mfa' applied to filename (e.g. "ISESavedSession-MFA.psXML")
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('epIseOpen')]
    PARAM(
        [Parameter(Position=0,HelpMessage="Optional Tag to apply to filename[-Tag MFA]")]
        [string]$Tag,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
    }
    PROCESS {
        if ($psise){
            #$AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;
            $CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
            if($Tag){
                $txmlf = join-path -path $CUScripts -ChildPath "ISESavedSession-$($Tag).psXML" ;
            } else { 
                $txmlf = join-path -path $CUScripts -ChildPath 'ISESavedSession.psXML' ;
            } ; 
            $allISEScripts = $psise.powershelltabs.files.fullpath ;
            $smsg = "Exporting $(($allISEScripts|measure).count) Open Files list for ALL TABS of currently open ISE, to:`n"
            $smsg += "`n$($txmlf)" ;
            write-host -foregroundcolor green $smsg ;
            if($allISEScripts){
                $allISEScripts | Export-Clixml -Path $txmlf -whatif:$($whatif);
            } else {write-warning "ISE has no detectable tabs open" }
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}
#*------^ export-ISEOpenFiles.ps1 ^------
