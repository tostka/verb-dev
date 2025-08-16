# export-ISEBreakPoints.ps1 

#*------v export-ISEBreakPoints.ps1 v------
function export-ISEBreakPoints {
    <#
    .SYNOPSIS
    export-ISEBreakPoints - Export all 'Line' ise breakpoints to XML file 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2020-08-25
    FileName    : export-ISEBreakPoints
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 9:06 PM 8/12/2025 added code to create CUScripts if missing
    * 8:27 AM 3/26/2024 chg eIseBp -> epIseBp
    * 2:35 PM 5/24/2023 add: prompt for force deletion of existing .xml if no psbreakpoints defined in loaded ISE copy for script.
    * 10:20 AM 5/11/2022 added whatif support; updated CBH ; expanded echos; cleanedup
    * 8:58 AM 5/9/2022 add: test for bps before exporting
    * 12:56 PM 8/25/2020 fixed typo in 1.0.0 ; init, added to verb-dev module
    .DESCRIPTION
    export-ISEBreakPoints - Export all 'Line' ise breakpoints to XML file
    By default, attempts to save to the same directory as the script, but if the directory specified doesn't exist, it redirects the save to the c:\scripts dir.
    .PARAMETER PathDefault
    Default Path for export (when `$Script directory is unavailable)[-PathDefault c:\path-to\]
    .PARAMETER Script
    Path to target Script file (defaults to Current ISE Tab fullpath)[-Script c:\path-to\file.ext]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    export-ISEBreakPoints
    Export all 'line'-type breakpoints on the current open ISE tab, to a matching xml file
    .EXAMPLE
    export-ISEBreakPoints -Script c:\path-to\script.ps1
    Export all 'line'-type breakpoints from the specified script, to a matching xml file
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('epIseBp','epBP')]
    PARAM(
        [Parameter(HelpMessage="Default Path for export (when `$Script directory is unavailable)[-PathDefault c:\path-to\]")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$PathDefault = 'c:\scripts',
        [Parameter(HelpMessage="(debugging):Path to target Script file (defaults to Current ISE Tab fullpath)[-Script c:\path-to\file.ext]")]
        #[ValidateScript({Test-Path $_})]
        [string]$Script,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")} ;
        
    PROCESS {
        if ($psise){
            if($Script){
                write-verbose "`$Script:$($Script)" ; 
                if( ($tScript = (gci $Script).FullName) -AND ($psise.powershelltabs.files.fullpath -contains $tScript)){
                    write-host "-Script specified diverting target to:`n$($Script)" ; 
                    $tScript = $Script ; 
                    $xFname=$tScript.replace(".ps1","-ps1.xml").replace(".psm1","-psm1.xml").replace(".","-BP.") ;
                } else { 
                    throw "-Script specified is not a valid path!`n$($Script)`n(or is not currently open in ISE)" ; 
                } ; 
            } elseif($psise.CurrentFile.FullPath){
                write-verbose "(processing `$psise.CurrentFile.FullPath:$($psise.CurrentFile.FullPath)...)"
                $tScript = $psise.CurrentFile.FullPath ;
                # default to same loc, variant name of script in currenttab of ise
                $xFname=$tScript.replace(".ps1","-ps1.xml").replace(".psm1","-psm1.xml").replace(".","-BP.") ;
                $AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ;                 
                if(-not (test-path $AllUsrsScripts )){mkdir $AllUsrsScripts  -verbose } ; 
                if( ( (split-path $xFname) -eq $AllUsrsScripts) -OR (-not(test-path (split-path $xFname))) ){
                    # if in the AllUsers profile, or the ISE script dir is invalid
                    if($tdir = get-item "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts"){
                        write-verbose "(`$tDir:CUser has a profile Scripts dir: using it for xml output:`n$($tdir))" ;
                    } elseif($tdir = get-item $PathDefault){
                        write-verbose "(`$tDir:Using `$PathDefault:$($PathDefault))" ; 
                    } else {
                        throw "Unable to resolve a suitable destination for the current script`n$($tScript)" ; 
                        break ; 
                    } ; 
                    $smsg = "broken path, defaulting to: $($tdir.fullname)" ; 
                    $xFname = $xFname.replace( (split-path $xFname), $tdir.fullname) ;
                } ;
            } else { throw "ISE has no current file open. Open a file before using this script" } ; 
        
            write-host "Creating BP file:$($xFname)" ;
            $xBPs= get-psbreakpoint |?{ ($_.Script -eq $tScript) -AND ($_.line)} ;
            if($xBPs){
                $xBPs | Export-Clixml -Path $xFname -whatif:$($whatif);
                $smsg = "$(($xBPs|measure).count) Breakpoints exported to $xFname`n$(($xBPs|sort line|ft -a Line,Script|out-string).trim())" ;
                if($whatif){$smsg = "-whatif:$($smsg)" };
                write-host $smsg ; 
            }elseif(test-path $xfname){
                $smsg = "$($tScript): has *no* Breakpoints set," 
                $smsg += "`n`tbut PREVIOUS file EXISTS!" ; 
                $smsg += "`nDo you want to DELETE/OVERWRITE the existing file? " ; 
                write-host -foregroundcolor YELLOW "$((get-date).ToString('HH:mm:ss')):$($smsg)"  ;
                $bRet=Read-Host "Enter YYY to continue. Anything else will exit"  ; 
                if ($bRet.ToUpper() -eq "YYY") {
                    remove-item -path $xFname -verbose -whatif:$($whatif); 
                } else { 
                    write-host "(invalid response, skipping .xml file purge)" ; 
                } ; 
            } else {
                write-warning "$($tScript): has *no* Breakpoints set!`n(an no existing .xml exists: No Action)" ; 
            }
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
}

#*------^ export-ISEBreakPoints.ps1 ^------
