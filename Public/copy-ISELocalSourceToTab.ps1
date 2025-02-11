#*------v copy-ISELocalSourceToTab.ps1 v------
function copy-ISELocalSourceToTab {
    <#
    .SYNOPSIS
    copy-ISELocalSourceToTab - From a remote RDP session running ISE, copy a file (and any matching -PS-BP.XML) from specified admin client machine to remote ISE host (renaming function sources to _func.ps1) and open the copied file in the remot ISE.
    .NOTES
    Version     : 1.0.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2024-05-22
    FileName    : copy-ISELocalSourceToTab
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging,backup
    REVISIONS
    * 9:20 AM 2/10/2025 tweaked to permit non-tsclient-spanning use: supports copying from local repo to a separate generic debugging copy; fixed swapped error msgs at bottom of PROC{}
    * 3:30 PM 10/25/2024 appears to work for bp, non-func as well;  inital non-BP.xml func copy working ; port from copy-ISETabFileToLocal(), to do the reverse
    * 2:15 PM 5/29/2024 add: c:\sc dev repo dest test, prompt for optional -nofunc use (avoid mistakes copying into repo with _func.ps1 source name intact)
    * 1:22 PM 5/22/2024init
    .DESCRIPTION
    copy-ISELocalSourceToTab - From a remote RDP session running ISE, copy a file (and any matching -PS-BP.XML) from specified admin client machine to remote ISE host (renaming function sources to _func.ps1) and open the copied file in the remot ISE.

    This also checks for a matching exported breakpoint file (name matches target script .ps1, with trailing name ...-ps1-BP.xml), and prompts to also COPY that file along with the .ps1. 

    .PARAMETER Path
    Path to source file (defaults to `$psise.CurrentFile.FullPath)[-Path 'D:\scripts\copy-ISELocalSourceToTab_func.ps1']
    .PARAMETER LocalSource
    Localized destination directory path[-path c:\pathto\]
    .PARAMETER Func
    Switch to append '_func' substring to the original file name, while copying (used for copying module functions from .\Public directory to ensure no local name clash for debugging[-Func]
    .PARAMETER whatIf
    Whatif switch [-whatIf]
    .EXAMPLE
    PS> copy-ISELocalSourceToTab -LocalSource C:\sc\verb-Exo\public\Connect-EXO.ps1 -func  -Verbose -whatif ;
    Copy the specified local path on the RDP session, to the default destination path, whatif, with verbose output
    .EXAMPLE
    PS> copy-ISELocalSourceToTab -LocalSource C:\usr\work\o365\scripts\New-CMWTempMailContact.ps1 -Verbose -whatif ; 
    Copy the current tab file to explicit specified -LocalDesetination, replacing any _func substring from filename, with whatif, with verbose output
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    #[Alias('')]
    PARAM(
        #[Parameter(Mandatory = $false,Position=0,HelpMessage="Path to source file (defaults to `$psise.CurrentFile.FullPath)[-Path 'D:\scripts\copy-ISELocalSourceToTab_func.ps1']")]
        [Parameter(Mandatory = $false,Position=0,HelpMessage="Path to local machine destination (defaults to d:\scripts\)[-Path 'D:\scripts\copy-ISELocalSourceToTab_func.ps1']")]
            [ValidateScript({Test-Path $_ -PathType 'Container'})]
            #[string]
            #[system.io.fileinfo]$Path=$psise.CurrentFile.FullPath,
            [system.io.fileinfo]$Path,
        [Parameter(Mandatory = $true,Position = 1,HelpMessage = 'Localized destination directory path[-path c:\pathto\]')]
            #[Alias('PsPath')]
            #[ValidateScript({Test-Path $_ -PathType 'Container'})]
            <#[ValidateScript({
                if([uri]$_ |?{ $_.IsUNC}){
                    throw "UNC Path specified: Please specify a 'localized' path!" ; 
                }elseif([uri]$_ |?{$_.AbsolutePath -AND $_.LocalPath -AND $_.IsFile -AND -not $_.IsUNC}){
                    $true ;
                }else{
                    throw "Invalid path!" ; 
                }
            })]
            #>
            [System.IO.DirectoryInfo]$LocalSource,
            #[string]$LocalSource,
        [Parameter(HelpMessage="Switch to append '_func' substring to the original file name, while copying (used for copying module functions from .\Public directory to ensure no local name clash for debugging[-Func])")]
            [switch]$Func,
        [Parameter(HelpMessage="Whatif switch [-whatIf]")]
            [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $nonRDPDefaultPath = 'c:\usr\work\ps\scripts\' ; 
        $sBnr="#*======v $($CmdletName): v======" ;
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
        $moveBP = $false ; 
        if($env:SESSIONNAME  -match 'RDP-Tcp#\d+'){
            $defaultPath = 'd:\scripts\' ; 
        } elseif(-not $Path -AND (test-path $nonRDPDefaultPath )){
            $defaultPath = $nonRDPDefaultPath ; 
            write-host -foregroundcolor yellow "(no -Path specified, defaulting to $($defaultPath))" ; 

        } else {
            write-warning "Neither -Path, nor pre-existing $($nonRDPDefaultPath):Please rerun specifying a -Path destination for new copy" ; 
        } ;
    }
    PROCESS {
        if ($psise){
            #if($env:SESSIONNAME  -match 'RDP-Tcp#\d+'){
                TRY{
                    if($path){
                        [system.io.fileinfo[]]$Destination = @($path) ;
                    } else { 
                        [system.io.fileinfo[]]$Destination = @($defaultPath)
                    } ;  
                    [array]$RDPSource=@() ; 
                    [system.io.fileinfo[]]$CopiedFiles= $null ; 
                        if(-not $Func -AND $LocalSource -match '^C:\\sc\\'){
                            $smsg = "Note: Copying from `$LocalSource prefixed with C:\sc\ (dev repo)" ; 
                            $smsg += "`nWITHOUT specifying -Func!" ; 
                            $smsg += "`nDO YOU WANT TO USE -Func (assert _func.ps1 on copy)?" ; 
                            write-warning $smsg ; 
                            $bRet=Read-Host "Enter YYY to continue. Anything else will exit"  ; 
                            if ($bRet.ToUpper() -eq "YYY") {
                                $smsg = "(specifying -Func)" ; 
                                write-host -foregroundcolor green $smsg  ;
                                $Func = $true ; 
                            } else {
                                $smsg = "(*skip* use of -Func)" ; 
                                write-host -foregroundcolor yellow $smsg  ;
                            } ; 
                        } ; 
                        if($env:SESSIONNAME  -match 'RDP-Tcp#\d+'){
                            if($LocalSource.fullname.substring(0,1) -ne 'c'){
                                $tmpPath = $LocalSource.fullname.replace(':','$') ; 
                                $tmpPath = (join-path -path "\\$($mybox[0])\" -childpath $tmpPath) ; 
                            }else{
                                $tmpPath = $LocalSource.fullname.replace(':','') ; 
                                $tmpPath = (join-path -path "\\tsclient\" -childpath $tmpPath) ; 
                            } ; 
                            $LocalSource = $tmpPath ; 
                        } else {
                            write-host "(local non-RDP session: coppying without tsclient translation)" 
                        } ; 
                        
                        write-verbose "resolved `$LocalSource:$($LocalSource)" ; 
                        if(-not (test-path -path $LocalSource)){
                            $smsg = "Missing/invalid converted `$LocalSource:"
                            $smsg += "`n$($LocalSource)" ; 
                            write-warning $smsg ; 
                            throw $smsg ; 
                            break ; 
                        } else{
                            write-verbose "Adding confirmed `$LocalSource:$($LocalSource) to `$RDPSource:" 
                            $RDPSource += $LocalSource ; 
                        } ;
                        
                        # check for matching local ps1-BP.xml file to also copy
                        if($bpp = get-childitem -path ($LocalSource.fullname.replace('.ps1','-ps1-BP.xml')) -ea 0){
                            $smsg = "Matching Breakpoint export file found:`n$(($bpp |out-string).trim())" ; 
                            $smsg += "`nDo you want to move this file with the .ps1?" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Prompt } 
                            else{ write-host -foregroundcolor YELLOW "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $bRet=Read-Host "Enter Y to continue. Anything else will exit"  ; 
                            if ($bRet.ToUpper() -eq "Y") {
                                $smsg = "(copying -BP.xml file)" ; 
                                write-host -foregroundcolor green $smsg  ;
                                $moveBP = $true ; 
                                $RDPSource += @($bpp)
                            } else {
                                $smsg = "(*skip* copying -BP.xml file)" ; 
                                write-host -foregroundcolor yellow $smsg  ;
                            } ; 
                        } ; 
                        $pltCI=[ordered]@{
                            path = $null ; 
                            destination = $null ; 
                            erroraction = 'STOP' ;
                            verbose = $true ; 
                            whatif = $($whatif) ;
                        } ;
                        foreach($src in $RDPSource){
                            $pltCI.path = $src.fullname ; 
                            if($Func){
                                #$pltCI.destination = (join-path -path $RDPSource -childpath $src.name.replace('_func','') -EA stop)
                                #$Destination
                                $pltCI.destination = (join-path -path $Destination -childpath $src.name.replace('.ps1','_func.ps1') -EA stop)
                            } else { 
                                #$pltCI.destination = (join-path -path $RDPSource -childpath $src.name  -EA stop); 
                                $pltCI.destination = (join-path -path $Destination -childpath $src.name  -EA stop); 
                            } ; 
                            $smsg = "copy-item w`n$(($pltCI|out-string).trim())" ; 
                            write-host -foregroundcolor green $smsg  ;
                            copy-item @pltCI ; 
                            $CopiedFiles += $pltCI.destination
                        } ; 
                        if(-not $whatif){
                            # then open the copied non -ps1-bp.xml files
                            foreach($cfile in ($CopiedFiles | ?{$_.fullname -notmatch '-ps1-BP.xml$'} ) ){
                                if($psise.powershelltabs.files.fullpath -contains $cfile){
                                    # preclose the existing tab
                                    If($closefile = $psISE.CurrentPowerShellTab.Files | ?{$_.fullpath -eq $cfile.fullname}){
                                        write-verbose "Closing tab file:`n$(($closefile| ft -a |out-string).trim())" ;
                                        #$result = $psISE.CurrentPowerShellTab.Files.remove($closefile) ;
                                        #$targetFileTab =  $psise.PowerShellTabs.files | ?{$_.fullpath -eq $cfile.fullname} ;
                                        $refreshIsFocused = $true ; 
                                        if(get-command export-ISEBreakPoints){
                                            write-host -foregroundcolor yellow "Tab refresh:Pre-running epbp!" ; 
                                            export-ISEBreakPoints
                                        } else { 
                                            write-warning "UNABLE:get-command export-ISEBreakPoints!" ; 
                                        } ; 
                                        $psISE.CurrentPowerShellTab.Files.Remove($closefile) ; 
                                    } ; 

                                    <#
                                    # preclose the existing tab
                                    #write-host "($cfile) is already OPEN in Current ISE tab list (skipping)" ;
                                    # have to loop locate the open file
                                    #-=-=-=-=-=-=-=-=
                                    $allISEFiles = $psise.powershelltabs.files #.fullpath ;
                                    if($cfile){
                                        $tFile = $allISEFiles | ?{$_.Fullpath -eq $cfile.fullname}
                                    } else{$tFile = $allISEFiles | select DisplayName,FullPath | out-gridview -Title "Pick Tab to focus:" -passthru};
                                    If($tFile){
                                        $Name = $tFile.DisplayName ;
                                        write-verbose "Searching for $($tFile.DisplayName)" ;
                                        #loop tabs for target displayname
                                        # Get the tab using the name
                                        # Finds the tab, but there's version bug in the SelectedPowerShellTab, doesn't like setting to the discovered $tab…
                                        if( $Name )  {
                                            $found = 0 ;
                                            $refreshIsFocused = $false ; 
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
                                                if($found -eq 0) {
                                                    $refreshIsFocused = $false ; 
                                                    Throw ("Could not find a tab named " + $Name) 
                                                
                                                } else {
                                                    #$psISE.PowerShellTabs.files.SelectedPowerShellTab = $tab | select -first 1 ;
                                                    $psISE.CurrentPowerShellTab.Files.SetSelectedFile(($targetFileTab | select -first 1))
                                                    $refreshIsFocused = $true ; 
                                                } ;
                                            } ;
                                        } ;
                                    }
                                    #-=-=-=-=-=-=-=-=
                                    if($refreshIsFocused -AND ($targetFileTab | select -first 1)){
                                        # first run export-ISEBreakPoints 
                                        if(get-command export-ISEBreakPoints){
                                            write-host -foregroundcolor yellow "Tab refresh:Pre-running epbp!" ; 
                                            export-ISEBreakPoints
                                        } else { 
                                            write-warning "$((get-date).ToString('HH:mm:ss')):MSG" ; 
                                        } ; 
                                        $psISE.PowerShellTabs.Remove(($targetFileTab | select -first 1)) ; 
                                    } ; 
                                    #>
                                }    
                                # add the tab 
                                if(test-path $cfile.fullname){
                                    <# #New tab & open in new tab: - no we want them all in one tab
                                    write-verbose "(adding tab, opening:$($cfile))"
                                    $tab = $psISE.PowerShellTabs.Add() ;
                                    $tab.Files.Add($cfile) ;
                                    #>
                                    #open in current tab
                                    write-verbose "(opening:$($cfile))"
                                    $newtabfile = $psISE.CurrentPowerShellTab.Files.Add($cfile) ;  ;
                                    write-verbose "Reload:import-ISEBreakPoints" 
                                    if(get-command import-ISEBreakPoints){
                                        write-host -foregroundcolor yellow "Tab refresh:Pre-running epbp!" ; 
                                        write-verbose "focusing `$newTab" ; 
                                        $psISE.CurrentPowerShellTab.Files.SetSelectedFile($newtabfile) ; 
                                        import-ISEBreakPoints
                                    } else { 
                                        write-warning "UNABLE:get-command import-ISEBreakPoints!" ; 
                                    } ; 
                                } else {  write-warning "Unable to Open missing orig file:`n$($cfile)" };
                            }; # loop-E
                        } else { 
                            write-host "(-whatif: Skipping balance)" ; 
                        } ; 
                    <#} else { 
                        throw "NO POPULATED `$psise.CurrentFile.FullPath!`n(PSISE-only, with a target file tab selected)" ; 
                    } ; 
                    #>
                } CATCH {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                    write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                } ;             
            #} else {  write-warning "This script only functions within an RDP remote session (non-local)" };
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
    END{
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}; 
#*------^ copy-ISELocalSourceToTab.ps1 ^------
