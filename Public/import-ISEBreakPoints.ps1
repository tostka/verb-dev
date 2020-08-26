#*------v import-ISEBreakPoints.ps1 v------
function import-ISEBreakPoints {
    <#
    .SYNOPSIS
    import-ISEBreakPoints - Import the 'Line' ise breakpoints previously cached to an XML file
    .NOTES
    Version     : 1.0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2020-08-25
    FileName    : import-ISEBreakPoints
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 8:43 AM 8/26/2020 fixed typo $ibp[0]->$ibps[0]
    * 1:45 PM 8/25/2020 fix bug in import code ; init, added to verb-dev module
    .DESCRIPTION
    import-ISEBreakPoints - Import the 'Line' ise breakpoints previously cached to an XML file
    By default, attempts to save to the same directory as the script, but if the directory specified doesn't exist, it redirects the save to the c:\scripts dir.
    .PARAMETER PathDefault
    Default Path for export (when `$Script directory is unavailable)[-PathDefault c:\path-to\]
    .EXAMPLE
    import-ISEBreakPoints
    Import all 'line'-type breakpoints into the current open ISE tab, from matching xml file
    .EXAMPLE
    Import-ISEBreakPoints -Script c:\path-to\script.ps1
    Import all 'line'-type breakpoints into the specified script, from matching xml file
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('iIseBp')]

    #[ValidateScript({Test-Path $_})]
    PARAM(
        [Parameter(HelpMessage="Default Path for Import (when `$Script directory is unavailable)[-PathDefault c:\path-to\]")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$PathDefault = 'c:\scripts',
        [Parameter(HelpMessage="(debugging):Path to target Script file (defaults to Current ISE Tab fullpath)[-Script c:\path-to\file.ext]")]
        [string]$Script
    ) ;
    BEGIN {} ;
    PROCESS {
        # for debugging, -Script permits targeting another script *not* being currently debugged
        if ($psise){
            if($Script){
                if( ($tScript = (gci $Script).fullname) -AND ($psise.powershelltabs.files.fullpath -contains $tScript)){
                    write-host "-Script specified diverting target to:`n$($Script)" ;
                    $iFname = "$($Script.replace('.ps1','-ps1.xml').replace('.psm1','-psm1.xml').replace('.','-BP.'))" ;
                } else {
                    throw "-Script specified is not a valid path!`n$($Script)`n(or is not currently open in ISE)" ;
                } ;
            } elseif($psise.CurrentFile.FullPath){
                $tScript = $psise.CurrentFile.FullPath
                # array of paths to be preferred (in order)
                # - script's current path (with either -[ext]-BP or -BP suffix)
                #
                $tfiles = "$($tScript.replace('.ps1','-ps1.xml').replace('.psm1','-psm1.xml').replace('.','-BP.'))",
                    # ^current path name variant 1
                    "$($tScript.replace('ps1','xml').replace('.','-BP.'))",
                    # ^current path name variant 2
                    "$((join-path -path "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" -childpath (split-path $tScript -leaf)).replace('.ps1','-ps1.xml').replace('.psm1','-psm1.xml').replace('.','-BP.'))" ,
                    # ^CU scripts dir
                    "$((join-path -path $PathDefault -childpath (split-path $tScript -leaf)).replace('.ps1','-ps1.xml').replace('.psm1','-psm1.xml').replace('.','-BP.'))" ;
                    # ^ PathDefault dir
                foreach($tf in $tfiles){if($iFname = gci $tf -ea 0 | select -exp fullname ){break } } ;
            } else { throw "ISE has no current file open. Open a file before using this script" } ;

            if($iFname){
                write-host "*Importing BP file:$($iFname) and setting specified BP's for open file`n$($tScript)" ;
                # clear all existing bps
                if($eBP=Get-PSBreakpoint |?{$_.line -AND $_.Script -eq $tScript}){$eBP | remove-PsBreakpoint } ;

                # set bps in found .xml file
                $iBPs = Import-Clixml -path $iFname ;

                <# fundemental issue importing cross-machines, the xml stores the full path to the script at runtime
                    $iBP.script
                C:\Users\UID\Documents\WindowsPowerShell\Scripts\maintain-AzTenantGuests.ps1
                    $tscript
                C:\usr\work\o365\scripts\maintain-AzTenantGuests.ps1
                #>
                # so if they mismatch, we need to patch over the script used in the set-psbreakpoint command
                if(  ( (split-path $iBPs[0].script) -ne (split-path $tscript) ) -AND ($psise.powershelltabs.files.fullpath -contains $tScript) ) {
                    write-verbose "Target script is pathed to different location than .XML exported`n(patching BPs to accomodate)" ; 
                    $setPs1 = $tScript ; 
                } else {
                    # use script on 1st bp in xml
                    $setPs1 = $iBPs[0].Script ; 
                }; 

                #$iBPs | %{set-PSBreakpoint -script $_.script -line $_.line } | out-null ;
                foreach($iBP in $iBPs){
                    $null = set-PSBreakpoint -script $setPs1 -line $iBP.line ;
                } ; 
                write-host "$(($iBP|measure).count) Breakpoints imported and set as per $($iFname)`n$(($iBPs|sort line|ft -a Line,Script|out-string).trim())" ;
             } else { "Missing .xml BP file for open file $($tScript)" } ;
        } else {  write-warning 'This script only functions within PS ISE, with a script file open for editing' };
    } # PROC-E
}

#*------^ import-ISEBreakPoints.ps1 ^------