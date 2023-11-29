#*------v Function pop-FunctionDev v------
function pop-FunctionDev {
    <#
    .SYNOPSIS
    pop-FunctionDev.ps1 - Copy a given c:\sc\[repo]\Public\function.ps1 file from prod editing dir (as function_func.ps1) back to source function .ps1 file
    .NOTES
    Version     : 1.2.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2023-10-02
    FileName    : pop-FunctionDev.ps1
    License     : (None Asserted)
    Copyright   : (None Asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell, development, html, markdown, conversion
    AddedCredit : Øyvind Kallstad @okallstad
    AddedWebsite: https://communary.net/
    AddedTwitter: @okallstad / https://twitter.com/okallstad
    REVISIONS
    * 3:09 PM 11/29/2023 added missing test on $sMod - gcm comes back with empty mod, when the item has been iflv'd in console, so prompt for a dest mod
    * 8:27 AM 11/28/2023 updated CBH; tested, works; add: fixed mod discovery typo; a few echo details, confirmed -ea stop on all cmds
    * 12:30 PM 11/22/2023 init
    .DESCRIPTION
    pop-FunctionDev.ps1 - Copy a given c:\sc\[repo]\Public\function.ps1 file from prod editing dir (as function_func.ps1) back to source function .ps1 file

    Concept is to use this to quickly 'pop' a debugging module source _func.ps1 back to the dev dir, de-suffixed from _func.ps1, so that it can be commited & rebuilt into the module. 
    
    On iniital debugging the matching function push-FunctionDev() would be used to push the .\public\function.ps1 file to the c:\usr\work\ps\scripts\ default dev destnation (or wherever it's -destination param specifies on run).
    
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
    None. Does not return output to pipeline.
    .EXAMPLE
    PS> pop-FunctionDev -Path "C:\sc\powershell\PSScripts\export-ISEBreakPoints_func.ps1" -Verbose -whatIf ;
    Demo duping uwps\xxx_func.ps1 debugging code back to source discovered module \public dir
    .EXAMPLE
    PS> $psise.powershelltabs.files.fullpath |?{$_ -match '_func\.ps1$'} | %{pop-FunctionDev -path $_ -whatif:$true -verbose } ; 
    Push back *all* _func.ps1 tabs currently open in ISE
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
        #[Parameter(Mandatory = $true,HelpMessage="Path the destination 'editing' directory (defaults to uwps)[-Path c:\pathto\]")]
        #    [ValidateScript({Test-Path $_ -PathType 'Container'})]
        #    [System.IO.DirectoryInfo]$Destination = 'C:\sc\powershell\PSScripts\',
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
        $tv | get-variable | %{  write-verbose ("`${0,$tvmx} : {1}" -f $_.name,$_.value) } ; 
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
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success

            TRY{
                get-childitem -path $funcfile -ea STOP |foreach-object {
                    $sfile = $_ ; 
                    $error.clear() ;
  
                    if($sMod = get-command (split-path $sfile -leaf).replace('_func.ps1','') -ea STOP | select -expand module){
                        $smsg =  "==:$($sfile):discovered hosted in module:$($sMod.name)" ; 
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;  
                    } ELSE { 
                        # gcm comes back with empty mod, when the item has been iflv'd in console, so prompt for a solution
                        $smsg = "Unable to locate a matching Module for:`n$($sfile)!" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        #Continue
                        # recover with manual prompt
                        if($sMod =get-module -name (Read-Host "Enter the proper locally-installed Module name to contuine:") -ListAvailable -ErrorAction STOP){
                            $smsg = "Resolve input to: $($sMod.Name)" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                        } else { 
                            $smsg = "Unable to locate a matching Module for:`n$($sfile)!" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            Continue
                        } ;
                    } ;

                    if($sModDir = get-item -path "c:\sc\$($sMod.name)" -ea STOP){
                        
                        if($target = get-childitem -path (join-path -path $sModDir.fullname -ChildPath "\Public\$($sfile.name.replace('_func.ps1','.ps1'))") ){
                            
                            $smsg = "Existing file:$($target.fullname) is the destation" ; 
                            $smsg += "`nAre you SURE you want to overwrite your edited updates to the source file?" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Prompt } 
                            else{ write-host -foregroundcolor YELLOW "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $bRet=Read-Host "Enter YYY to continue. Anything else will exit"  ; 
                            if ($bRet.ToUpper() -eq "YYY") {
                                $smsg = "(Moving on)" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            } else {
                                    $smsg = "Invalid response. Exiting" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } 
                                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                #exit 1
                                break ; 
                            }  ; 
                            
                        } else { 
                            # no existing file to conflict
                            $smsg = "(no conflicting pre-existing '$((join-path -path $sModDir.fullname -ChildPath "\Public\$($sfile.name.replace('_func.ps1','.ps1'))"))' found)" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                        } ; 

                        $pltCI=[ordered]@{
                            path  = $sfile.fullname ;
                            destination  = $target ;
                            force = $($force) ; 
                            verbose  = $($VerbosePreference -eq 'Continue') ;
                            erroraction = 'STOP' ;
                            whatif = $($whatif) ;
                        } ;
                        $smsg = "Copying *back* from Editing:copy-item w`n$(($pltCI|out-string).trim())" ; 
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
                        $smsg = $hsMsg ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    } ELSE { 
                        $smsg = "Unable to locate a local c:\sc directory Module tree for:`n$($sfile)!" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        Continue
                    } ;
                    
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                CONTINUE;
            } ; 
            $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
        } ;  # loop-E
    } ;  # PROC-E
} ; 
#*------^ END Function pop-FunctionDev ^------