#*------v Initialize-ModuleFingerprint.ps1 v------
function Initialize-ModuleFingerprint {
    <#
    .SYNOPSIS
    Initialize-ModuleFingerprint.ps1 - Profile a specified module and summarize commands into a semantic-version 'fingerprint'.
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-10-09
    FileName    : 
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : Kevin Marquette
    AddedWebsite: https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/
    AddedTwitter: 
    REVISIONS
    * 2:29 PM 5/16/2022 add: backup-fileTDO of the fingerprintfile
    * 9:58 AM 10/26/2021 updated all echos, wh, ww, wv's with wlts's, updated KM logic to match step-ModuleVersionCalculated's latest
    * 6:11 PM 10/15/2021 rem'd # raa, replaced psd1/psm1-location code with Get-PSModuleFile(), which is a variant of BuildHelpers get-psModuleManifest. 
    * 12:36 PM 10/13/2021 added else block to catch mods with inconsistent names between root dir, and .psm1 file, (or even .psm1 location); upgraded catchblock to curr std; added splats and verbose echos for debugging outlier processing errors
    * 7:41 PM 10/11/2021 cleaned up rem'd requires
    * 9:08 PM 10/9/2021 init version
    .DESCRIPTION
    Initialize-ModuleFingerprint.ps1 - Profile a specified module and summarize commands into a semantic-version 'fingerprint'.
    Rounded out the sample logic KM posted on the above site, along with matching processing function: Step-ModuleVersionCalculated
    .PARAMETER Path
    Path to .psm1-hosting directory of the Module[-path 'C:\sc\PowerShell-Statistics\Statistics' ]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    .EXAMPLE
    PS> Initialize-ModuleFingerprint -path 'C:\sc\Get-MediaInfo' -whatif -verbose ;
    Fingerprint the specified module path, with whatif and verbose specified
    .EXAMPLE
    $whatif = $true ;
    foreach($mod in $mods){
        if(test-path "$($mod)\fingerprint"){write-host -fore green "---`nPRESENT:$($mod)\fingerprint`n```" }
        else {Initialize-ModuleFingerprint -path $mod -whatif:$($whatif) -verbose} ;
    } ;
    Sample code to process list of module root directory paths and initialize fingerprints in the dirs currently lacking the files.
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/
    #>
    ##Requires -RunasAdministrator
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("USEA","GBMK","AUSYD")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)][ValidateCount(1,3)]
    [CmdletBinding()]
    ###[Alias('Alias','Alias2')]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to .psd1-hosting directory of the Module[-path 'C:\sc\PowerShell-Statistics\Statistics' ]")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$Path,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN { 
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;

        $sBnr="#*======v RUNNING :$($CmdletName):$($Path) v======" ; 
        $smsg = "$($sBnr)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

        # Get parameters this function was invoked with
        #$PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
        
    } ;  # BEGIN-E
    PROCESS {
        $error.clear() ;
        TRY {
            $smsg = "profiling existing content..."
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        
            if( ($path -like 'BounShell') -OR ($path -like 'VERB-transcript')){
                write-verbose "GOTCHA!" ;
            } ; 

            <# 9:58 AM 1/15/2024 below is using undefined locally $moddir.FullName; clearly it should be $path, which is a string, if we're calling it from publish-ModuleLocalFork, should use that funcs inputs resolution:
                $ModRoot = $path ; 
                $moddir = (gi -Path $path).FullName;
                $moddirfiles = gci -path $moddir -recur ;
                But it's a core piece of verb-dev\Public\Step-ModuleVersionCalculated.ps1
                No it's not, the func has internalized the logic from this:
                #695: # KM's core logic code:
                    $fingerprint = foreach ( $command in $commandList ){

                but sc\powershell\PSScripts\processbulk-NewModule.ps1 *does* run it, at line 
                #391: $pltInitModFngr=[ordered]@{Path=$ModRoot ;Verbose = ($VerbosePreference -eq 'Continue');} ;
                            $smsg = "Initialize-ModuleFingerprint w`n$(($pltInitModFngr|out-string).trim())" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                            Initialize-ModuleFingerprint @pltInitModFngr ;
                            $hasFingerprint = [boolean](test-path (join-path -path $ModRoot -childpath 'fingerprint'))

                    it's underlying 
                    #185: $scRoot = 'c:\sc\' ; 
                    #260: $modroot= join-path -path $scRoot -child $ModuleName ;

                    below is also stocking $moddirfiles TWICE
                    $moddirfiles = gci @pltGCI ;
                    $moddirfiles = gci -path $path -recur 
                    # 1st block must be roughed in not completed, rem it out
                #>
                # test and force
                if(-not $moddir -AND $path){
                    $moddir = (gi -Path $path).FullName;
                    if(-not $modroot){$modroot= $path} ; 

                }

            $pltXMO=@{Name=$null ; force=$true ; ErrorAction='STOP'} ;
            <#
            $pltGCI=[ordered]@{path=$moddir ;recurse=$true ; ErrorAction='STOP'} ;
            $smsg =  "gci w`n$(($pltGCI|out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            
            $moddirfiles = gci @pltGCI ;
            #>

            $Path = (Resolve-Path $Path).Path ; 
            $moddirfiles = gci -path $path -recur 
            # using an undefined $modname below as well, resolve it from split path
            if(-not $modname){
                $modname = split-path $Path -leaf ;
            } ;
            #-=-=-=-=-=-=-=-=
            if(-not (gcm Get-PSModuleFile -ea 0)){
                function Get-PSModuleFile {
                    [CmdletBinding()]
                    PARAM(
                        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to project root. Defaults to the current working path [-path 'C:\sc\PowerShell-Statistics\']")]
                        [ValidateScript({Test-Path $_ -PathType 'Container'})]
                        [string]$Path = $PWD.Path,
                        [Parameter(HelpMessage="Specify Module file type: Module .psm1 file or Manifest .psd1 file (psd1|psm1 - defaults psd1)[-Extension .psm1]")]
                        [ValidateSet('.psd1','.psm1','both')]
                        [string] $Extension='.psd1'
                    ) ;

                    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
                    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
                    $sBnr="#*======v RUNNING :$($CmdletName):$($Extension):$($Path) v======" ; 
                    $smsg = "$($sBnr)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                    if($Extension -eq 'Both'){
                        [array]$Exts = '.psd1','.psm1'
                        $smsg =  "(-extension Both specified: Running both:$($Exts -join ','))" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    } else {
                        $Exts = $Extension ; 
                    } ; 
                    $Path = ( Resolve-Path $Path ).Path ; 
                    $CurrentFolder = Split-Path $Path -Leaf ;
                    $ExpectedPath = Join-Path -Path $Path -ChildPath $CurrentFolder ;
        
                    foreach($ext in $Exts){
                        $ExpectedFile = Join-Path -Path $ExpectedPath -ChildPath "$CurrentFolder$($ext)" ;
                        if(Test-Path $ExpectedFile){$ExpectedFile  } 
                        else {
                            # Look for properly organized modules (name\name.ps(d|m)1)
                            $ProjectPaths = Get-ChildItem $Path -Directory |
                                ForEach-Object {
                                    $ThisFolder = $_ ;
                                    $smsg =  "checking:$($ThisFolder)" ; 
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                    $ExpectedFile = Join-Path -path $ThisFolder.FullName -child "$($ThisFolder.Name)$($ext)" ;
                                    If( Test-Path $ExpectedFile) {$ExpectedFile  } ;
                                } ;
                            if( @($ProjectPaths).Count -gt 1 ){
                                $smsg = "Found more than one project path via subfolders with psd1 files" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $ProjectPaths  ;
                            } elseif( @($ProjectPaths).Count -eq 1 )  {$ProjectPaths  } 
                            elseif( Test-Path "$ExpectedPath$($ext)" ) {
                                $smsg =  "`$ExpectedPath:$($ExpectedPath)" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                #PSD1 in root of project - ick, but happens.
                                "$ExpectedPath$($ext)"  ;
                            } elseif( Get-Item "$Path\S*rc*\*$($ext)" -OutVariable SourceFiles)  {
                                # PSD1 in Source or Src folder
                                If ( $SourceFiles.Count -gt 1 ) {
                                    $smsg = "Found more than one project $($ext) file in the Source folder" ;
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                } ;
                                $SourceFiles.FullName ;
                            } else {
                                $smsg = "Could not find a PowerShell module $($ext) file from $($Path)" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            } ;
                        } ;
                    } ; 
                    $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                }
                ##-=-=-=-=-=-=-=-=
            }

            $psd1M = Get-PSModuleFile -path $Path -ext .psd1 -verbose:$($VerbosePreference -eq 'Continue');
            $psm1 = Get-PSModuleFile -path $Path -ext .psm1 -verbose:$($VerbosePreference -eq 'Continue' ); 
            # 10:31 AM 1/15/2024 got some fullname refs, above are coming back as strings, no fullname property: fix

            if($psd1M){
                if($psd1M -is [system.array]){
                    throw "`$psd1M resolved to multiple .psm1 files in the module tree!" ; 
                } ; 
                # regardless of root dir name, the .psm1 name *is* the name of the module, use it for ipmo/rmo's
                #$psd1MBasename = ((split-path $psd1M -leaf).replace('.psm1','')) ; # this isn't going to work, it's a .psd1 path, and we're rplacing .psm1!
                $psd1MBasename = ((split-path $psd1M -leaf).replace('.psd1','')) ; # this isn't going to work, it's a .psd1 path, and we're rplacing .psm1!
                if($modname -ne $psd1MBasename){
                    $smsg = "Module has non-standard root-dir name`n$($moddir)"
                    $smsg += "`ncorrecting `$modname variable to use *actual* .psm1 basename:$($psd1MBasename)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    $modname = $psd1MBasename ; 
                } ; 
                $pltXMO.Name = $psd1M # load via full path to .psm1
                $smsg =  "import-module w`n$(($pltXMO|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                import-module @pltXMO ;
                # ipmo works on full .psd1 name, but gcm doesn't, so if then the results
                if(-not ($commandList = Get-Command -Module $modname)){
                    $smsg = "get-command -module $($modname.replace('.psd1','')) FAILED to return a list of commands!"
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; ]
                    throw $smsg ;
                    BREAK ; 
                } ;
                $pltXMO.Name = $psd1MBasename ; # have to rmo using *basename*
                $smsg =  "remove-module w`n$(($pltXMO|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                remove-module @pltXMO ;

                $smsg = "Calculating fingerprint"
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                # KM's core logic code:
                $fingerprint = foreach ( $command in $commandList ){
                    $smsg = "(=cmd:$($command)...)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    foreach ( $parameter in $command.parameters.keys ){
                        $smsg = "(---param:$($parameter)...)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        '{0}:{1}' -f $command.name, $command.parameters[$parameter].Name
                        $command.parameters[$parameter].aliases | 
                            Foreach-Object { '{0}:{1}' -f $command.name, $_}
                    };  
                } ;   

            } else {
                throw "No module .psm1 file found in `$path:`n$(join-path -path $moddir -child "$modname.psm1")" ;
            } ;  
  
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #-=-record a STATUSWARN=-=-=-=-=-=-=
            $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
            if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
            if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
            #-=-=-=-=-=-=-=-=
            $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
            else{ write-warning  "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
        } ; 
    } ;  # PROC-E
    END {
        if ( $fingerprint ){
            
            <# fingerprint is the diff, not the $oldfingprint file (which is used in step-moduleversioncalculated())
            write-verbose "(backup-FileTDO -path $($fingerprint))" ;
            $fingerprintBU = backup-FileTDO -path $fingerprint -showdebug:$($showdebug) -whatif:$($whatif) ;
            if (!$fingerprintBU) {throw "FAILURE" } ;
            #> 

            $pltOFile=[ordered]@{Encoding='utf8' ;FilePath=(join-path -path $moddir -childpath 'fingerprint') ;whatif=$($whatif) ;} ; 

            if(test-path $pltOFile.FilePath){
                write-verbose "(backup-FileTDO -path $($pltOFile.FilePath))" ;
                $fingerprintBU = backup-FileTDO -path $pltOFile.FilePath -showdebug:$($showdebug) -whatif:$($whatif) ;
                if(-not $FingerprintBU -AND -not $whatif){throw "backup-FileTDO -Source $($pltOFile.FilePath)!" }
            } else { 
                write-verbose "(no old fingerprint file to backup)" ;  
            } ;  

            write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Out-File w`n$(($pltOFile|out-string).trim())" ; 
            $fingerprint | out-file @pltOFile ; 
        } else {
            $smsg = "No funtional Module `$fingerprint generated for path specified`n$($Path)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ; 
        $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;  # END-E
}

#*------^ Initialize-ModuleFingerprint.ps1 ^------
