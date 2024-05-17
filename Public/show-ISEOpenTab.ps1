#*------v show-ISEOpenTab.ps1 v------
function show-ISEOpenTab {
    <#
    .SYNOPSIS
    show-ISEOpenTab - Display a list of all currently open ISE tab files, prompt for selection, and then foreground selected tab file
    .NOTES
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
    .DESCRIPTION
    show-ISEOpenTab - Display a list of all currently open ISE tab files, prompt for selection, and then foreground selected tab file
    Alternately supports a -Path param, that permits ISE Console use to direct switch active Tab File. 

    This is really only useful when you run a massive number of open file tabs, and visually scanning them unsorted is too much work. 
    Opens them in a sortable grid view, with both Displayname & fullpath, and you can rapidly zoom in on the target tab file you're seeking. 

    .PARAMETER Path
    Optional Path to filter against the ISE .files Fullname string (for direct ISE console use)[-Path ' D:\scripts\show-ISEOpenTab_func.ps1']
    .EXAMPLE
    PS> show-ISEOpenTab -verbose -whatif
    Intereactive pass, uses out-grid as a picker select a prompted target file tab, from full list. 
    .EXAMPLE
    PS> show-ISEOpenTab -Path 'D:\scripts\get-MailHeaderSenderIDKeys.ps1' -verbose ;
    ISE Console direct switch open files in ISE to the file tab with the specified path as it's FullName
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('shIseTab')]
    PARAM(
        [Parameter(Position=0,HelpMessage="Optional Path to filter against the ISE .files Fullname string (for direct ISE console use)[-Path ' D:\scripts\show-ISEOpenTab_func.ps1']")]
        [string]$Path
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
    }
    PROCESS {
        if ($psise){
            #$AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;
            #$CUScripts = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" ;
            $allISEFiles = $psise.powershelltabs.files #.fullpath ;

            if($Path){
                $tFile = $allISEFiles | ?{$_.Fullpath -eq $Path} 
            } else{$tFile = $allISEFiles | select DisplayName,FullPath | out-gridview -Title "Pick Tab to focus:" -passthru};
            If($tFile){
                $Name = $tFile.DisplayName ; 
                write-verbose "Searching for $($tFile.DisplayName)" ; 
                #loop tabs for target displayname
                # Get the tab using the name
                # Finds the tab, but there's version bug in the SelectedPowerShellTab, doesn't like setting to the discovered $tab…
                if( $Name )  {
                    $found = 0 ;
                    if($host.version.major -lt 3){
                        for( $i = 0; $i -lt $psise.PowerShellTabs.Count; $i++){
                            write-verbose $psise.PowerShellTabs[$i].DisplayName ;
                            if( $psise.PowerShellTabs[$i].DisplayName -eq $Name ){
                                $tab = $psise.PowerShellTabs[$i] ;
                                $found++ ;
                            } ;
                        } ;
                        if($found -eq 0) {Throw ("Could not find a tab named " + $Name) } else {
                            $psISE.PowerShellTabs.SelectedPowerShellTab = $tab | select -first 1 ;
                        } ;
                    } else {
                        for( $i = 0; $i -lt $psise.PowerShellTabs.files.Count; $i++){
                            write-verbose $psise.PowerShellTabs.files[$i].DisplayName ;
                            if( $psise.PowerShellTabs.files[$i].DisplayName -eq $Name ){
                                $tab = $psise.PowerShellTabs.files[$i] ;
                                # it's doubtful you really need to cycle the 'files', vs postfilter; but postfilter works fine for $psISE.CurrentPowerShellTab.Files.SetSelectedFile
                                # (and SelectedPowerShellTab explicitly *doesnt* work anymore under ps5 at least, as written above in the ms learn exampls)
                                $targetFileTab =  $psise.PowerShellTabs.files | ?{$_.displayname -eq $Name} ;
                                $found++ ;
                            } ;
                        } ;
                        if($found -eq 0) {Throw ("Could not find a tab named " + $Name) } else {
                            #$psISE.PowerShellTabs.files.SelectedPowerShellTab = $tab | select -first 1 ;
                            $psISE.CurrentPowerShellTab.Files.SetSelectedFile(($targetFileTab | select -first 1))
                        } ;
                    } ;
                } ;
            } else {
                write-warning "No matching file in existing Tabs Files list found" ; 
            } ; 
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}; 
#*------^ show-ISEOpenTab.ps1 ^------
