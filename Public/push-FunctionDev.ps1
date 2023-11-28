#*------v Function push-FunctionDev v------
function push-FunctionDev {
    <#
    .SYNOPSIS
    push-FunctionDev.ps1 - Stage a given c:\sc\[repo]\Public\function.ps1 file to prod editing dir
    .NOTES
    Version     : 1.2.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2023-10-02
    FileName    : push-FunctionDev.ps1
    License     : (None Asserted)
    Copyright   : (None Asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell, development, html, markdown, conversion
    AddedCredit : Øyvind Kallstad @okallstad
    AddedWebsite: https://communary.net/
    AddedTwitter: @okallstad / https://twitter.com/okallstad
    REVISIONS
    * 8:19 AM 11/28/2023 tested, works; add: a few echo details, confirmed -ea stop on all cmds
    * 12:30 PM 11/22/2023 init
    .DESCRIPTION
    push-FunctionDev.ps1 - Stage a given c:\sc\[repo]\Public\function.ps1 file to prod editing dir

    Concept is to use this to quickly 'push' a module source .ps1 into the dev dir, suffixed as _func.ps1, so that it can be ipmo -fo -verb'd and debugged/edited for updates. 
    On completion the matching function pop-FunctionDev.ps1 would be used to pull the updated file back into place, overwriting the original source.
    .PARAMETER Path
    Source module funciton .ps1 file to be staged for editing (to uwps\Name_func.ps1)[-path 'C:\sc\verb-dev\Public\export-ISEBreakPoints.ps1']
    .PARAMETER Destination
    Directoy into which 'genericly-named output files should be written, or the full path to a specified output file[-Destination c:\pathto\MyModuleHelp.html]
    .PARAMETER SkipDependencyCheck
    Skip dependency check[-SkipDependencyCheck] 
    .PARAMETER Script
    Switch for processing target Script files (vs Modules, overrides natural blocks on processing scripts)[-Script]
    .PARAMETER MarkdownHelp
    Switch to use PlatyPS to output markdown help variants[-MarkdownHelp]
    .PARAMETER NoPreview
    Switch to suppress trailing preview of html in default browser[-NoPreview]
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    System.Object.string converted file path(s) returned to pipeline
    System.Boolean
    [| get-member the output to see what .NET obj TypeName is returned, to use here]
    .EXAMPLE
    PS> push-functiondev -Path 'C:\sc\verb-dev\Public\export-ISEBreakPoints.ps1' -verbose -whatif ;
    Typical run
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    #[Alias('Invoke-CreateModuleHelpFile')]
    PARAM(
        [Parameter(Mandatory = $False,Position = 0,ValueFromPipeline = $True, HelpMessage = 'File paths[-path c:\pathto\file.ext]')]
            [Alias('PsPath')]
            #[ValidateScript({Test-Path $_ -PathType 'Container'})]
            #[System.IO.DirectoryInfo[]]$Path,
            [ValidateScript({Test-Path $_})]
            [system.io.fileinfo[]]$Path,
            #[string[]]$Path,
        [Parameter(Mandatory = $false,HelpMessage="Path the destination 'editing' directory (defaults to uwps)[-Path c:\pathto\]")]
            [ValidateScript({Test-Path $_ -PathType 'Container'})]
            [System.IO.DirectoryInfo]$Destination = 'C:\sc\powershell\PSScripts\',
        [Parameter(HelpMessage="Force (overwrite conflict)[-force]")]
            [switch] $force, 
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
            [switch] $whatIf=$true       
    ) ; 
    BEGIN { 
        # for scripts wo support, can use regions to fake BEGIN;PROCESS;END:
        # ps1 faked:#region BEGIN ; #*------v BEGIN v------
            #region CONSTANTS-AND-ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
    # Debugger:proxy automatic variables that aren't directly accessible when debugging (must be assigned and read back from another vari) ; 
    $rPSCmdlet = $PSCmdlet ; 
    $rPSScriptRoot = $PSScriptRoot ; 
    $rPSCommandPath = $PSCommandPath ; 
    $rMyInvocation = $MyInvocation ; 
    $rPSBoundParameters = $PSBoundParameters ; 
    [array]$score = @() ; 
    if($rPSCmdlet.MyInvocation.InvocationName -match '\.ps1$'){$score+= 'ExternalScript' } else {$score+= 'Function' }
    if($rPSCmdlet.CommandRuntime.tostring() -match '\.ps1$'){$score+= 'ExternalScript' } else {$score+= 'Function' }
    $score+= $rMyInvocation.MyCommand.commandtype.tostring() ; 
    $grpSrc = $score | group-object -NoElement | sort count ;
    if( ($grpSrc |  measure | select -expand count) -gt 1){
        write-warning  "$score mixed results:$(($grpSrc| ft -a count,name | out-string).trim())" ;
        if($grpSrc[-1].count -eq $grpSrc[-2].count){
            write-warning "Deadlocked non-majority results!" ;
        } else {
            $runSource = $grpSrc | select -last 1 | select -expand name ;
        } ;
    } else {
        write-verbose "consistent results" ;
        $runSource = $grpSrc | select -last 1 | select -expand name ;
    };
    write-host "Calculated `$runSource:$($runSource)" ;
    'score','grpSrc' | get-variable | remove-variable ; # cleanup temp varis

    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
    ${CmdletName} = $rPSCmdlet.MyInvocation.MyCommand.Name ;
    $PSParameters = New-Object -TypeName PSObject -Property $rPSBoundParameters ;
    write-verbose "`$rPSBoundParameters:`n$(($rPSBoundParameters|out-string).trim())" ;
    $Verbose = ($VerbosePreference -eq 'Continue') ; 
    # pre psv2, no $rPSBoundParameters autovari to check, so back them out:
    write-verbose 'Collect all non-default Params (works back to psv2 w CmdletBinding)'
    $ParamsNonDefault = (Get-Command $rPSCmdlet.MyInvocation.InvocationName).parameters | Select-Object -expand keys | Where-Object{$_ -notmatch '(Verbose|Debug|ErrorAction|WarningAction|ErrorVariable|WarningVariable|OutVariable|OutBuffer)'} ;
    #region ENVIRO_DISCOVER ; #*------v ENVIRO_DISCOVER v------
    <#
    # Debugger:proxy automatic variables that aren't directly accessible when debugging ; 
    $rPSScriptRoot = $PSScriptRoot ; 
    $rPSCommandPath = $PSCommandPath ; 
    $rMyInvocation = $MyInvocation ; 
    $rPSBoundParameters = $PSBoundParameters ; 
    #>
    $ScriptDir = $scriptName = '' ;     
    if($ScriptDir -eq '' -AND ( (get-variable -name rPSScriptRoot -ea 0) -AND (get-variable -name rPSScriptRoot).value.length)){
        $ScriptDir = $rPSScriptRoot
    } ; # populated rPSScriptRoot
    if( (get-variable -name rPSCommandPath -ea 0) -AND (get-variable -name rPSCommandPath).value.length){
        $ScriptName = $rPSCommandPath
    } ; # populated rPSCommandPath
    if($ScriptDir -eq '' -AND $runSource -eq 'ExternalScript'){$ScriptDir = (Split-Path -Path $rMyInvocation.MyCommand.Source -Parent)} # Running from File
    # when $runSource:'Function', $rMyInvocation.MyCommand.Source is empty,but on functions also tends to pre-hit from the rPSCommandPath entFile.FullPath ;
    if( $scriptname -match '\.psm1$' -AND $runSource -eq 'Function'){
        write-host "MODULE-HOMED FUNCTION:Use `$CmdletName to reference the running function name for transcripts etc (under a .psm1 `$ScriptName will reflect the .psm1 file  fullname)"
        if(-not $CmdletName){write-warning "MODULE-HOMED FUNCTION with BLANK `$CmdletNam:$($CmdletNam)" } ;
    } # Running from .psm1 module
    if($ScriptDir -eq '' -AND (Test-Path variable:psEditor)) {
        write-verbose "Running from VSCode|VS" ; 
        $ScriptDir = (Split-Path -Path $psEditor.GetEditorContext().CurrentFile.Path -Parent) ; 
            if($ScriptName -eq ''){$ScriptName = $psEditor.GetEditorContext().CurrentFile.Path }; 
    } ;
    if ($ScriptDir -eq '' -AND $host.version.major -lt 3 -AND $rMyInvocation.MyCommand.Path.length -gt 0){
        $ScriptDir = $rMyInvocation.MyCommand.Path ; 
        write-verbose "(backrev emulating `$rPSScriptRoot, `$rPSCommandPath)"
        $ScriptName = split-path $rMyInvocation.MyCommand.Path -leaf ;
        $rPSScriptRoot = Split-Path $ScriptName -Parent ;
        $rPSCommandPath = $ScriptName ;
    } ;
    if ($ScriptDir -eq '' -AND $rMyInvocation.MyCommand.Path.length){
        if($ScriptName -eq ''){$ScriptName = $rMyInvocation.MyCommand.Path} ;
        $ScriptDir = $rPSScriptRoot = Split-Path $rMyInvocation.MyCommand.Path -Parent ;
    }
    if ($ScriptDir -eq ''){throw "UNABLE TO POPULATE SCRIPT PATH, EVEN `$rMyInvocation IS BLANK!" } ;
    if($ScriptName){
        if(-not $ScriptDir ){$ScriptDir = Split-Path -Parent $ScriptName} ; 
        $ScriptBaseName = split-path -leaf $ScriptName ;
        $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($ScriptName) ;
    } ; 
    # last ditch patch the values in if you've got a $ScriptName
    if($rPSScriptRoot.Length -ne 0){}else{ 
        if($ScriptName){$rPSScriptRoot = Split-Path $ScriptName -Parent }
        else{ throw "Unpopulated, `$rPSScriptRoot, and no populated `$ScriptName from which to emulate the value!" } ; 
    } ; 
    if($rPSCommandPath.Length -ne 0){}else{ 
        if($ScriptName){$rPSCommandPath = $ScriptName }
        else{ throw "Unpopulated, `$rPSCommandPath, and no populated `$ScriptName from which to emulate the value!" } ; 
    } ; 
    if(-not ($ScriptDir -AND $ScriptBaseName -AND $ScriptNameNoExt  -AND $rPSScriptRoot  -AND $rPSCommandPath )){ 
        throw "Invalid Invocation. Blank `$ScriptDir/`$ScriptBaseName/`ScriptNameNoExt" ; 
        BREAK ; 
    } ; 
    # echo results dyn aligned:
    $tv = 'runSource','CmdletName','ScriptName','ScriptBaseName','ScriptNameNoExt','ScriptDir','PSScriptRoot','PSCommandPath','rPSScriptRoot','rPSCommandPath' ; 
    $tvmx = ($tv| Measure-Object -Maximum -Property Length).Maximum * -1 ; 
    $tv | get-variable | %{  write-verbose  ("`${0,$tvmx} : {1}" -f $_.name,$_.value) } ; 
    'tv','tvmx'|get-variable | remove-variable ; # cleanup temp varis
    
    #endregion ENVIRO_DISCOVER ; #*------^ END ENVIRO_DISCOVER ^------
        
        # check if using Pipeline input or explicit params:
        if ($rPSCmdlet.MyInvocation.ExpectingInput) {
            $smsg = "Data received from pipeline input: '$($InputObject)'" ;
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } else {
            # doesn't actually return an obj in the echo
            #$smsg = "Data received from parameter input: '$($InputObject)'" ;
            #if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            #else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ;

        # tempfile for cap'ing git output
        #$fn = "$env:temp\gitStat.txt" ; # temp file
        
    }  ;  # BEG-E
    PROCESS {
        $Error.Clear() ; 
        $pwd0 = get-location ; 
        pushd ; 
        foreach($funcfile in $Path) {
            $smsg = $sBnrS="`n#*------v PROCESSING : $($funcfile) v------" ; 
            TRY{
                get-childitem -path $funcfile -ea STOP |foreach-object {
                    $sfile = $_ ; 
                    $error.clear() ;
                    
                    if($sMod = get-module ((get-command  (split-path $sfile  -leaf).replace('.ps1','') -ErrorAction STOP) | select -expand source) -ListAvailable){
                        $smsg =  "==:$($sfile):discovered module:$($sMod.name)" ; 
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;  

                        if($sModDir = get-item -path "c:\sc\$($sMod.name)" -ea STOP){
                            #Set-Location $sModDir.fullname ; 
                        
                            $pltCI=[ordered]@{
                                path  = $sfile.fullname ;
                                destination  = (join-path -path $Destination -childpath $sfile.name.replace('.ps1','_func.ps1') -ea STOP) ;
                                force = $($force) ; 
                                verbose  = $($VerbosePreference -eq 'Continue') ;
                                erroraction = 'STOP' ;
                                whatif = $($whatif) ;
                            } ;
                            $smsg = "Staging for Editing:copy-item w`n$(($pltCI|out-string).trim())" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            copy-item @pltCI ; 

                            $hsMsg = @"

# To stage a branch for new work:
cd $($smoddir.fullname) ; 
# echo the curr branch
git branch

# a. create the new branch if it doesn't pre-exist
git checkout -b tostka/BRANCHNAME
# or b. switch to the existing branch
git checkout tostka/EXISTINGBRANCHNAME

# make changes, when ready
git status

# commit current branch
git commit

# push branch back to the origin remote repo
# first list all branches in local & remote repos:
git branch -a ; 

# then do push
git push -u origin tostka/BRANCHNAME

# trailing status
git status

# switch back to master:
git checkout master

# FINALLY: if done with the branch debugging, merge the branch back to master:

git merge tostka/BRANCHNAME

# cleanup, if done with it, delete a local branch:

git branch -d tostka/BRANCHNAME

# and then del the remote branch by simply pushing the chg
git push -u origin tostka/BRANCHNAME

"@ ; 
                            #---
                            $smsg = $hsMsg  ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                        } ELSE { 
                            $smsg = "Unable to locate a local c:\sc directory Module tree for:`n$($sfile)!" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            Continue
                        } ;
                    } ELSE { 
                        $smsg = "Unable to locate a matching Module for:`n$($sfile)!" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        Continue
                    } ;
                    
                } ;  # loop-E
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                CONTINUE;
            } ; 
            $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
        } ;  # loop-E
    } ;  # PROC-E
} ; 
#*------^ END Function push-FunctionDev ^------