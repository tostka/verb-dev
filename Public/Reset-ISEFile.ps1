# Reset-ISEFile.ps1

Function Reset-ISEFile {
    <#
    .SYNOPSIS
    Reset-ISEFile - Close & Reopen current tab file
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : Reset-ISEFile.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : jdhitsolutions
    AddedWebsite: https://github.com/jdhitsolutions/ISEScriptingGeek/
    AddedTwitter: URL
    REVISIONS
    * 12:15 PM 4/9/2026 added -force; init, added check for breakpoints, and pre-exported status prompt.
    * Jul 3, 2023 jdh posted vers
    .DESCRIPTION
    Reset-ISEFile.ps1 - Close & Reopen current tab file
    .PARAMETER Force
    Bypasses prompt
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    System.Boolean
    .EXAMPLE
    PS> Reset-ISEFile
    EXSAMPLEOUTPUT
    Run with whatif & verbose
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://github.com/jdhitsolutions/ISEScriptingGeek/
    #>
    [cmdletbinding()]
    Param(
        [Parameter(HelpMessage="Force (Confirm-override switch[-force]")]
            [switch]$Force
    )
    if ($psISE) {
    #save the current file path
    #$path = $psISE.CurrentFile.FullPath
    $tScript = $psise.CurrentFile.FullPath ;
    $xBPs= get-psbreakpoint |?{ ($_.Script -eq $tScript) -AND ($_.line)} ;
    if($xBPs){        
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
        $smsg = "PSBreakpoints are defined, reloading will reset to PRIOR last saved breakpoints!" ;
        if(test-path $xFname){
            $smsg += "`n... and existing Breakpoint file exists at:`n$((gci $xFname | ft -a |out-string).trim())" ; 
        } else{
            $smsg += "`n... but they are *UNEXPORTED* - *NO* existing Breakpoint file exists" ; 
        }; 
        write-warning $smsg ;
        if(-not $Force){
            $bRet=Read-Host "Enter YYY to continue. Anything else will exit"  ;
            if ($bRet.ToUpper() -eq "YYY") {
                $smsg = "(Moving on)" ;
                write-host -foregroundcolor green $smsg  ;
            } else {
                $smsg = "(*skip* use of -NoFunc)" ;
                write-host -foregroundcolor yellow $smsg  ;
                return; # return (exits script or function); break (exits loop/switch) ; exit 1 (terms context,can close ps)
            } ; 
        }
    }
    #get current index
    $i = $psISE.CurrentPowerShellTab.files.IndexOf($psISE.CurrentFile)
    #remove the file
    [void]$psISE.CurrentPowerShellTab.Files.Remove($psISE.CurrentFile)
    [void]$psISE.CurrentPowerShellTab.Files.Add($tScript)
    #file always added to the end
    [void]$psISE.CurrentPowerShellTab.files.Move(($psISE.CurrentPowerShellTab.files.count - 1), $i)
    } else {
        Write-Warning 'This function requires the Windows PowerShell ISE.'
    }
}
